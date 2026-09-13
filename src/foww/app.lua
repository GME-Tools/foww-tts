local Registry = require("foww.registry")
local Products = require("foww.products")
local State = require("foww.state")
local Pool = require("foww.pool")


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