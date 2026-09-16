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

            function(product)

                return
                    State.isProductOpen(
                        product
                    )
            end
        )


    print(
        "[FOWW] Available models: "
        .. tostring(
            Pool.countModels(
                currentPool
            )
        )
    )


    --------------------------------------------------
    -- Pool changed -> Armory UI changes immediately.
    --------------------------------------------------

    ArmoryUI.refresh(
        currentPool
    )
end


--------------------------------------------------
-- Lifecycle
--------------------------------------------------

function App.onLoad(saved_data)

    print("[FOWW] Starting...")


    --------------------------------------------------
    -- UI initially displays an empty/loading pool.
    --------------------------------------------------

    ArmoryUI.mount(nil)


    --------------------------------------------------
    -- Restore collection state
    --------------------------------------------------

    State.load(
        saved_data
    )


    --------------------------------------------------
    -- Load registries
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
    -- This also refreshes the Armory UI.
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
            .. tostring(modelId)
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
-- Armory : spawn current filtered selection
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
            .. tostring(spawned)
            .. " model(s) spawned",

            playerColor,

            {0.6, 1.0, 0.6}
        )
    end


    return spawned
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