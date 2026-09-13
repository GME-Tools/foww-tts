local Registry = require("foww.registry")
local Products = require("foww.products")
local State = require("foww.state")
local Pool = require("foww.pool")
local ModelSpawner = require("foww.model_spawner")
local Armory = require("foww.armory")
local DebugUI = require("foww.debug_ui")


local App = {}

local currentRegistry = nil
local currentPool = nil


--------------------------------------------------
-- Pool
--------------------------------------------------

local function rebuildPool()

    if currentRegistry == nil then
        print("[FOWW] Cannot rebuild pool: registry not ready")
        return
    end


    currentPool =
        Pool.build(
            currentRegistry.catalog,
            currentRegistry.modelsById,

            function(product)
                return State.isProductOpen(product)
            end
        )


    print(
        "[FOWW] Available models: "
        .. tostring(
            Pool.countModels(currentPool)
        )
    )
end


--------------------------------------------------
-- Lifecycle
--------------------------------------------------

function App.onLoad(saved_data)

    print("[FOWW] Starting...")
    DebugUI.mount()

    --------------------------------------------------
    -- Restore persistent collection state
    --------------------------------------------------

    State.load(saved_data)


    --------------------------------------------------
    -- Load remote registries
    --------------------------------------------------

    Registry.load(function(success, registry)

        if not success then

            print(
                "[FOWW] Startup aborted: "
                .. "registry unavailable"
            )

            return
        end


        currentRegistry = registry

        print("[FOWW] Registry ready")


        --------------------------------------------------
        -- Reconcile physical product boxes
        --------------------------------------------------

        Products.reconcile(
            currentRegistry.catalog,

            function(product)
                return State.isProductOpen(product)
            end
        )


        --------------------------------------------------
        -- Build logical available-content pool
        --------------------------------------------------

        rebuildPool()


        print("[FOWW] Startup complete")
    end)
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

    --------------------------------------------------
    -- Resolve TTS object -> catalog product
    --------------------------------------------------

    local product =
        Products.getProductForObject(object)


    if product == nil then

        print(
            "[FOWW] Could not identify product"
        )

        return
    end


    --------------------------------------------------
    -- Update persistent logical state
    --------------------------------------------------

    State.setProductOpen(
        product.id,
        opened
    )


    --------------------------------------------------
    -- Update visual representation
    --------------------------------------------------

    Products.refreshVisual(
        object,
        product,
        opened
    )


    --------------------------------------------------
    -- Recalculate available content
    --------------------------------------------------

    rebuildPool()


    --------------------------------------------------
    -- User feedback
    --------------------------------------------------

    local label =
        opened and "OPEN" or "CLOSED"


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
-- Model display / Armory
--------------------------------------------------

function App.spawnModel(
    modelId,
    position
)

    if currentPool == nil then

        print(
            "[FOWW] Cannot spawn model: "
            .. "pool not ready"
        )

        return nil
    end


    local model =
        currentPool.models[modelId]


    if model == nil then

        print(
            "[FOWW] Model not available: "
            .. tostring(modelId)
        )

        return nil
    end


    return ModelSpawner.spawn(
        model,
        position
    )
end


function App.showAvailableModels()

    if currentRegistry == nil then

        print(
            "[FOWW] Cannot show models: "
            .. "registry not ready"
        )

        return 0
    end


    if currentPool == nil then

        print(
            "[FOWW] Cannot show models: "
            .. "pool not ready"
        )

        return 0
    end


    local layout = nil


    if currentRegistry.catalog.layout
        ~= nil then

        layout =
            currentRegistry
            .catalog
            .layout
            .modelDisplay
    end


    return Armory.show(
        currentPool,
        layout
    )
end


function App.clearModelDisplay()

    return Armory.clear()
end


--------------------------------------------------
-- Public accessors
-- Useful for future UI / Armory / spawning
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