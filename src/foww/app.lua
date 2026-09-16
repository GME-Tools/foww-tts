local Registry =
    require("foww.registry")

local Products =
    require("foww.products")

local State =
    require("foww.state")

local Pool =
    require("foww.pool")

local Armory =
    require("foww.armory")

local ArmoryUI =
    require("foww.armory_ui")

local DeckBuilder =
    require("foww.deck_builder")


local App = {}

local currentRegistry =
    nil

local currentPool =
    nil


--------------------------------------------------
-- Helpers
--------------------------------------------------

local function getArmoryLayout()

    if currentRegistry == nil
        or currentRegistry.layout == nil then

        return nil
    end


    return
        currentRegistry.layout.armory
end


local function getCardsSpawnPosition()

    if currentRegistry ~= nil
        and currentRegistry.layout ~= nil
        and currentRegistry.layout.cards ~= nil
        and currentRegistry.layout.cards.spawn ~= nil then

        local position =
            currentRegistry.layout.cards.spawn


        return {
            x = position.x,
            y = position.y,
            z = position.z
        }
    end


    return {
        x = 0,
        y = 3,
        z = 0
    }
end


--------------------------------------------------
-- Pool
--------------------------------------------------

local function rebuildPool()

    if currentRegistry == nil then

        print(
            "[FOWW] Cannot rebuild pool: "
            .. "registry not ready"
        )

        return
    end


    currentPool =
        Pool.build(
            currentRegistry.catalog,
            currentRegistry.modelsById,
            currentRegistry.cardsById,

            function(product)

                return
                    State.isProductOpen(
                        product
                    )
            end
        )


    --------------------------------------------------
    -- Logging
    --------------------------------------------------

    print(
        "[FOWW] Available models: "
        .. tostring(
            Pool.countModels(
                currentPool
            )
        )
    )


    print(
        "[FOWW] Available cards: "
        .. tostring(
            Pool.countCards(
                currentPool
            )
        )
    )


    --------------------------------------------------
    -- Refresh UI
    --------------------------------------------------

    ArmoryUI.refresh(
        currentPool
    )
end


--------------------------------------------------
-- Lifecycle
--------------------------------------------------

function App.onLoad(saved_data)

    print(
        "[FOWW] Starting..."
    )


    --------------------------------------------------
    -- UI initially displays loading/empty pool.
    --------------------------------------------------

    ArmoryUI.mount(
        nil
    )


    --------------------------------------------------
    -- Restore collection state
    --------------------------------------------------

    State.load(
        saved_data
    )


    --------------------------------------------------
    -- Load registry
    --------------------------------------------------

    Registry.load(
        function(
            success,
            registry
        )

            if not success then

                print(
                    "[FOWW] Startup aborted: "
                    .. "registry unavailable"
                )

                return
            end


            currentRegistry =
                registry


            print(
                "[FOWW] Registry ready"
            )


            --------------------------------------------------
            -- Physical product boxes
            --------------------------------------------------

            Products.reconcile(
                currentRegistry.catalog,

                function(product)

                    return
                        State.isProductOpen(
                            product
                        )
                end
            )


            --------------------------------------------------
            -- Logical content
            --------------------------------------------------

            rebuildPool()


            print(
                "[FOWW] Startup complete"
            )
        end
    )
end


function App.onSave()

    return State.save()
end


--------------------------------------------------
-- Product state
--------------------------------------------------

function App.setProductState(
    object,
    player_color,
    opened
)

    local product =
        Products.getProductForObject(
            object
        )


    if product == nil then

        print(
            "[FOWW] Could not identify product"
        )

        return
    end


    State.setProductOpen(
        product.id,
        opened
    )


    Products.refreshVisual(
        object,
        product,
        opened
    )


    --------------------------------------------------
    -- Product contents changed logically.
    --------------------------------------------------

    rebuildPool()


    local label =
        opened
        and "OPEN"
        or "CLOSED"


    broadcastToColor(
        product.name
        .. " : "
        .. label,

        player_color,

        opened
            and {0.5, 1.0, 0.5}
            or  {1.0, 0.6, 0.4}
    )
end


--------------------------------------------------
-- Armory : filters
--------------------------------------------------

function App.setArmorySearch(
    value
)

    ArmoryUI.setSearch(
        value,
        currentPool
    )
end


function App.setArmoryFaction(
    value
)

    ArmoryUI.setFaction(
        value,
        currentPool
    )
end


function App.resetArmoryFilters()

    ArmoryUI.resetFilters(
        currentPool
    )
end


function App.toggleArmoryCollapsed()

    ArmoryUI.toggleCollapsed(
        currentPool
    )
end


--------------------------------------------------
-- Armory : spawn one model
--------------------------------------------------

function App.spawnArmoryModel(
    modelId,
    playerColor
)

    if currentPool == nil then

        print(
            "[FOWW] Cannot spawn model: "
            .. "pool not ready"
        )

        return nil
    end


    local model =
        currentPool.models[
            modelId
        ]


    if model == nil then

        print(
            "[FOWW] Model is not available: "
            .. tostring(
                modelId
            )
        )

        return nil
    end


    local object =
        Armory.spawnModel(
            model,
            getArmoryLayout()
        )


    if object ~= nil
        and playerColor ~= nil then

        broadcastToColor(
            "Spawned "
            .. model.name,

            playerColor,

            {0.6, 1.0, 0.6}
        )
    end


    return object
end


--------------------------------------------------
-- Armory : spawn filtered models
--------------------------------------------------

function App.spawnArmoryFiltered(
    playerColor
)

    if currentPool == nil then

        return 0
    end


    local models =
        ArmoryUI.getFilteredModels(
            currentPool
        )


    local spawned =
        Armory.spawnModels(
            models,
            getArmoryLayout()
        )


    if playerColor ~= nil then

        broadcastToColor(
            "Armory: "
            .. tostring(
                spawned
            )
            .. " model(s) spawned",

            playerColor,

            {0.6, 1.0, 0.6}
        )
    end


    return spawned
end


--------------------------------------------------
-- Cards : spawn all currently available cards
--------------------------------------------------

function App.spawnAvailableCards(
    playerColor
)

    if currentRegistry == nil
        or currentPool == nil then

        print(
            "[FOWW] Cannot spawn cards: "
            .. "registry/pool not ready"
        )

        return nil
    end


    local cards = {}


    for _, card
        in pairs(
            currentPool.cards
            or {}
        ) do

        table.insert(
            cards,
            card
        )
    end


    if #cards == 0 then

        if playerColor ~= nil then

            broadcastToColor(
                "No cards currently available",

                playerColor,

                {1.0, 0.7, 0.4}
            )
        end


        return nil
    end


    --------------------------------------------------
    -- Build and spawn deck
    --------------------------------------------------

    local object,
        spawnError =
        DeckBuilder.spawn(
            cards,
            currentRegistry.atlasesById,

            {
                name =
                    "FOWW Available Cards",

                position =
                    getCardsSpawnPosition()
            }
        )


    if object == nil then

        print(
            "[FOWW] Could not spawn cards: "
            .. tostring(
                spawnError
            )
        )


        if playerColor ~= nil then

            broadcastToColor(
                "Could not spawn cards: "
                .. tostring(
                    spawnError
                ),

                playerColor,

                {1.0, 0.4, 0.4}
            )
        end


        return nil
    end


    print(
        "[FOWW] Spawned card deck: "
        .. tostring(
            #cards
        )
        .. " card(s)"
    )


    if playerColor ~= nil then

        broadcastToColor(
            "Spawned "
            .. tostring(
                #cards
            )
            .. " available card(s)",

            playerColor,

            {0.6, 1.0, 0.6}
        )
    end


    return object
end


--------------------------------------------------
-- Public accessors
--------------------------------------------------

function App.getRegistry()

    return currentRegistry
end


function App.getPool()

    return currentPool
end


function App.rebuildPool()

    rebuildPool()
end


return App