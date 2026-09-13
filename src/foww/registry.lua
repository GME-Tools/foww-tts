local Registry = {}

local CATALOG_URL =
    "https://raw.githubusercontent.com/GME-Tools/foww-tts/refs/heads/main/data/catalog.json"
local MODELS_URL =
    "https://raw.githubusercontent.com/GME-Tools/foww-tts/refs/heads/main/data/models.json"

local catalog = nil
local models = nil
local modelsById = {}


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


local function validateModels(data)

    if type(data) ~= "table" then
        return false, "Models root is not an object"
    end

    if data.schemaVersion ~= 1 then
        return false,
            "Unsupported models schemaVersion: "
            .. tostring(data.schemaVersion)
    end

    if type(data.models) ~= "table" then
        return false, "Missing models array"
    end

    local ids = {}

    for index, model in ipairs(data.models) do

        if type(model.id) ~= "string"
            or model.id == "" then

            return false,
                "Model #" .. tostring(index)
                .. " has no valid id"
        end

        if ids[model.id] then
            return false,
                "Duplicate model id: "
                .. model.id
        end

        ids[model.id] = true

        if type(model.name) ~= "string"
            or model.name == "" then

            return false,
                "Model " .. model.id
                .. " has no name"
        end
    end

    return true, nil
end


local function validateProductContents(
    catalogData,
    modelIndex
)

    for _, product
        in ipairs(catalogData.products or {}) do

        local contents =
            product.contents or {}

        for _, modelId
            in ipairs(contents.models or {}) do

            if modelIndex[modelId] == nil then

                return false,
                    "Product "
                    .. product.id
                    .. " references unknown model: "
                    .. modelId
            end
        end
    end

    return true, nil
end


function Registry.load(callback)

    print("[FOWW] Loading catalog...")

    WebRequest.get(CATALOG_URL, function(request)

        if request.is_error
            or request.response_code ~= 200 then

            print(
                "[FOWW] Catalog request failed: "
                .. tostring(request.error)
            )

            callback(false, nil)
            return
        end

        local ok, data =
            pcall(JSON.decode, request.text)

        if not ok or data == nil then
            print("[FOWW] Could not decode catalog JSON")
            callback(false, nil)
            return
        end

        local valid, validationError =
            validateCatalog(data)

        if not valid then
            print(
                "[FOWW] Invalid catalog: "
                .. validationError
            )

            callback(false, nil)
            return
        end

        catalog = data

        print(
            "[FOWW] Catalog loaded: "
            .. tostring(catalog.catalogVersion)
        )


        ------------------------------------------------
        -- Models
        ------------------------------------------------

        print("[FOWW] Loading models...")

        WebRequest.get(MODELS_URL, function(modelRequest)

            if modelRequest.is_error
                or modelRequest.response_code ~= 200 then

                print(
                    "[FOWW] Models request failed: "
                    .. tostring(modelRequest.error)
                )

                callback(false, nil)
                return
            end

            local modelOk, modelData =
                pcall(
                    JSON.decode,
                    modelRequest.text
                )

            if not modelOk or modelData == nil then
                print(
                    "[FOWW] Could not decode models JSON"
                )

                callback(false, nil)
                return
            end

            local modelsValid, modelsError =
                validateModels(modelData)

            if not modelsValid then
                print(
                    "[FOWW] Invalid models registry: "
                    .. modelsError
                )

                callback(false, nil)
                return
            end

            models = modelData
            modelsById = {}

            for _, model
                in ipairs(models.models) do

                modelsById[model.id] = model
            end

            local contentsValid, contentsError =
                validateProductContents(
                    catalog,
                    modelsById
                )

            if not contentsValid then

                print(
                    "[FOWW] Invalid product contents: "
                    .. contentsError
                )

                callback(false, nil)
                return
            end

            print(
                "[FOWW] Models loaded: "
                .. tostring(#models.models)
            )

            callback(true, {
                catalog = catalog,
                models = models,
                modelsById = modelsById
            })
        end)
    end)
end


function Registry.getCatalog()
    return catalog
end


function Registry.getModel(modelId)
    return modelsById[modelId]
end

return Registry