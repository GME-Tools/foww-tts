local Registry = {}

local CATALOG_URL =
    "https://raw.githubusercontent.com/GME-Tools/foww-tts/refs/heads/main/data/catalog.json"
    local catalog = nil


local function validateCatalog(data)

    if type(data) ~= "table" then
        return false, "Catalog root is not an object"
    end

    if data.schemaVersion ~= 1 then
        return false,
            "Unsupported schemaVersion: "
            .. tostring(data.schemaVersion)
    end

    if type(data.products) ~= "table" then
        return false, "Missing products array"
    end

    local ids = {}

    for index, product in ipairs(data.products) do

        if type(product.id) ~= "string"
            or product.id == "" then

            return false,
                "Product #" .. tostring(index)
                .. " has no valid id"
        end

        if ids[product.id] then
            return false,
                "Duplicate product id: "
                .. product.id
        end

        ids[product.id] = true

        if type(product.name) ~= "string"
            or product.name == "" then

            return false,
                "Product " .. product.id
                .. " has no name"
        end

        if type(product.box) ~= "table" then
            return false,
                "Product " .. product.id
                .. " has no box definition"
        end

        if product.box.kind ~= "tile" then
            return false,
                "Product " .. product.id
                .. " has unsupported box kind: "
                .. tostring(product.box.kind)
        end

        if type(product.box.imageOpen) ~= "string"
            or product.box.imageOpen == "" then

            return false,
                "Product " .. product.id
                .. " has no imageOpen"
        end

        if type(product.box.imageClosed) ~= "string"
            or product.box.imageClosed == "" then

            return false,
                "Product " .. product.id
                .. " has no imageClosed"
        end
    end

    return true, nil
end


function Registry.load(callback)

    print("[FOWW] Loading catalog...")

    WebRequest.get(CATALOG_URL, function(request)

        if request.is_error then
            print("[FOWW] Catalog request failed:")
            print(request.error)

            if callback then
                callback(false, nil)
            end

            return
        end

        if request.response_code ~= 200 then
            print(
                "[FOWW] Catalog returned HTTP "
                .. tostring(request.response_code)
            )

            if callback then
                callback(false, nil)
            end

            return
        end

        local ok, data = pcall(JSON.decode, request.text)

        if not ok or data == nil then
            print("[FOWW] Could not decode catalog JSON")

            if callback then
                callback(false, nil)
            end

            return
        end

        local valid, validationError = validateCatalog(data)

        if not valid then

            print(
                "[FOWW] Invalid catalog: "
                .. validationError
            )

            if callback then
                callback(false, nil)
            end

            return
        end

        catalog = data

        print(
            "[FOWW] Catalog loaded: version "
            .. tostring(catalog.catalogVersion)
        )

        print(
            "[FOWW] Products: "
            .. tostring(#catalog.products)
        )

        if callback then
            callback(true, catalog)
        end
    end)
end


function Registry.getCatalog()
    return catalog
end

return Registry