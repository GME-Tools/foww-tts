local Registry = require("foww.registry")
local Products = require("foww.products")
local State = require("foww.state")

local App = {}


function App.onLoad(saved_data)

    print("[FOWW] Starting...")

    State.load(saved_data)

    Registry.load(function(success, catalog)

        if not success then
            print(
                "[FOWW] Startup aborted: "
                .. "catalog unavailable"
            )
            return
        end

        print("[FOWW] Registry ready")

        Products.reconcile(
            catalog,

            function(product)
                return State.isProductOpen(product)
            end
        )
    end)
end


function App.onSave()
    return State.save()
end


function App.setProductState(
    object,
    player_color,
    opened
)

    local product =
        Products.getProductForObject(object)

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


    local label =
        opened and "OPEN" or "CLOSED"


    broadcastToColor(
        product.name
        .. " : "
        .. label,

        player_color,

        opened
            and {0.5, 1.0, 0.5}
            or {1.0, 0.6, 0.4}
    )
end


return App