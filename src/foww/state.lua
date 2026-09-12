local State = {}

local openedProducts = {}


function State.load(saved_data)

    openedProducts = {}

    if saved_data == nil or saved_data == "" then
        print("[FOWW] No saved collection state")
        return
    end

    local ok, root = pcall(JSON.decode, saved_data)

    if not ok or root == nil then
        print("[FOWW] Warning: could not decode saved state")
        return
    end

    if root.foww ~= nil
        and root.foww.openedProducts ~= nil then

        openedProducts = root.foww.openedProducts
    end

    print("[FOWW] Collection state loaded")
end


function State.isProductOpen(product)

    local explicit = openedProducts[product.id]

    if explicit ~= nil then
        return explicit
    end

    return product.defaultOpen == true
end


function State.setProductOpen(product_id, opened)
    openedProducts[product_id] = opened
end


function State.save()

    return JSON.encode({
        foww = {
            schemaVersion = 1,
            openedProducts = openedProducts
        }
    })
end


return State