local Registry = {}


--------------------------------------------------
-- Remote data location
--------------------------------------------------

local DATA_BASE_URL =
    "https://raw.githubusercontent.com/"
    .. "GME-Tools/foww-tts/"
    .. "refs/heads/main/data/"


local MANIFEST_URL =
    DATA_BASE_URL
    .. "manifest.json"


--------------------------------------------------
-- Runtime registry
--------------------------------------------------

local manifest = nil

local catalog = nil
local models = nil

local modelsById = {}


--------------------------------------------------
-- Helpers
--------------------------------------------------

local function resourceUrl(resource)

    return
        DATA_BASE_URL
        .. resource.src
end


local function appendAll(
    target,
    source
)

    for _, value
        in ipairs(source or {}) do

        table.insert(
            target,
            value
        )
    end
end


--------------------------------------------------
-- Manifest validation
--------------------------------------------------

local function validateManifest(data)

    if type(data) ~= "table" then

        return false,
            "Manifest root is not an object"
    end


    if data.schemaVersion ~= 1 then

        return false,
            "Unsupported manifest schemaVersion: "
            .. tostring(
                data.schemaVersion
            )
    end


    if type(data.resources) ~= "table" then

        return false,
            "Manifest has no resources array"
    end


    for index, resource
        in ipairs(data.resources) do

        if type(resource.kind) ~= "string"
            or resource.kind == "" then

            return false,
                "Resource #"
                .. tostring(index)
                .. " has no kind"
        end


        if type(resource.src) ~= "string"
            or resource.src == "" then

            return false,
                "Resource #"
                .. tostring(index)
                .. " has no src"
        end
    end


    return true, nil
end


--------------------------------------------------
-- Products validation
--------------------------------------------------

local function validateCatalog(data)

    if type(data) ~= "table" then

        return false,
            "Catalog root is not an object"
    end


    if type(data.products) ~= "table" then

        return false,
            "Missing products array"
    end


    local ids = {}


    for index, product
        in ipairs(data.products) do

        if type(product.id) ~= "string"
            or product.id == "" then

            return false,
                "Product #"
                .. tostring(index)
                .. " has no valid id"
        end


        if ids[product.id] then

            return false,
                "Duplicate product id: "
                .. product.id
        end


        ids[product.id] =
            true


        if type(product.name) ~= "string"
            or product.name == "" then

            return false,
                "Product "
                .. product.id
                .. " has no name"
        end


        if type(product.box) ~= "table" then

            return false,
                "Product "
                .. product.id
                .. " has no box definition"
        end


        if product.box.kind ~= "tile" then

            return false,
                "Product "
                .. product.id
                .. " has unsupported box kind: "
                .. tostring(
                    product.box.kind
                )
        end


        if type(
                product.box.imageOpen
            ) ~= "string"
            or product.box.imageOpen
                == "" then

            return false,
                "Product "
                .. product.id
                .. " has no imageOpen"
        end


        if type(
                product.box.imageClosed
            ) ~= "string"
            or product.box.imageClosed
                == "" then

            return false,
                "Product "
                .. product.id
                .. " has no imageClosed"
        end
    end


    return true, nil
end


--------------------------------------------------
-- Models validation
--------------------------------------------------

local function validateModels(data)

    if type(data) ~= "table" then

        return false,
            "Models root is not an object"
    end


    if type(data.models) ~= "table" then

        return false,
            "Missing models array"
    end


    local ids = {}


    for index, model
        in ipairs(data.models) do

        if type(model.id) ~= "string"
            or model.id == "" then

            return false,
                "Model #"
                .. tostring(index)
                .. " has no valid id"
        end


        if ids[model.id] then

            return false,
                "Duplicate model id: "
                .. model.id
        end


        ids[model.id] =
            true


        if type(model.name) ~= "string"
            or model.name == "" then

            return false,
                "Model "
                .. model.id
                .. " has no name"
        end
    end


    return true, nil
end


--------------------------------------------------
-- Cross-validation
--------------------------------------------------

local function validateProductContents(
    catalogData,
    modelIndex
)

    for _, product
        in ipairs(
            catalogData.products
            or {}
        ) do

        local contents =
            product.contents
            or {}


        for _, modelId
            in ipairs(
                contents.models
                or {}
            ) do

            if modelIndex[
                modelId
            ] == nil then

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


--------------------------------------------------
-- Empty aggregate registry
--------------------------------------------------

local function createAggregate()

    return {

        catalog = {
            schemaVersion = 1,
            catalogVersion =
                manifest
                and manifest.manifestVersion
                or "unknown",

            products = {}
        },

        layout = {}


        models = {
            schemaVersion = 1,

            modelsVersion =
                manifest
                and manifest.manifestVersion
                or "unknown",

            models = {}
        }
    }
end


--------------------------------------------------
-- Merge one resource
--------------------------------------------------

local function mergeProductsResource(
    aggregate,
    data
)

    appendAll(
        aggregate.catalog.products,
        data.products
    )
end


local function mergeModelsResource(
    aggregate,
    data
)

    appendAll(
        aggregate.models.models,
        data.models
    )
end


local function mergeResource(
    aggregate,
    resource,
    data
)
    if resource.kind
        == "layout" then

        mergeLayoutResource(
            aggregate,
            data
        )

        return true
    end

    if resource.kind
        == "products" then

        mergeProductsResource(
            aggregate,
            data
        )

        return true
    end


    if resource.kind
        == "models" then

        mergeModelsResource(
            aggregate,
            data
        )

        return true
    end


    print(
        "[FOWW] Unsupported resource kind: "
        .. tostring(
            resource.kind
        )
    )


    return false
end


--------------------------------------------------
-- Finalize registry
--------------------------------------------------

local function finalize(
    aggregate,
    callback
)

    --------------------------------------------------
    -- Products
    --------------------------------------------------

    local catalogValid,
        catalogError =
        validateCatalog(
            aggregate.catalog
        )


    if not catalogValid then

        print(
            "[FOWW] Invalid products registry: "
            .. catalogError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Models
    --------------------------------------------------

    local modelsValid,
        modelsError =
        validateModels(
            aggregate.models
        )


    if not modelsValid then

        print(
            "[FOWW] Invalid models registry: "
            .. modelsError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Build indexes
    --------------------------------------------------

    modelsById = {}


    for _, model
        in ipairs(
            aggregate.models.models
        ) do

        modelsById[
            model.id
        ] = model
    end


    --------------------------------------------------
    -- Validate product references
    --------------------------------------------------

    local contentsValid,
        contentsError =
        validateProductContents(
            aggregate.catalog,
            modelsById
        )


    if not contentsValid then

        print(
            "[FOWW] Invalid product contents: "
            .. contentsError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Publish registry
    --------------------------------------------------

    catalog =
        aggregate.catalog

    models =
        aggregate.models


    print(
        "[FOWW] Products loaded: "
        .. tostring(
            #catalog.products
        )
    )


    print(
        "[FOWW] Models loaded: "
        .. tostring(
            #models.models
        )
    )


    callback(
        true,
        {
            catalog =
                catalog,

            layout =
                aggregate.layout,

            models =
                models,

            modelsById =
                modelsById
        }
    )
end


--------------------------------------------------
-- Load resources sequentially
--------------------------------------------------

local function loadResources(
    resources,
    index,
    aggregate,
    callback
)

    --------------------------------------------------
    -- Finished
    --------------------------------------------------

    if index > #resources then

        finalize(
            aggregate,
            callback
        )

        return
    end


    --------------------------------------------------
    -- Current resource
    --------------------------------------------------

    local resource =
        resources[index]


    local url =
        resourceUrl(
            resource
        )


    print(
        "[FOWW] Loading "
        .. resource.kind
        .. ": "
        .. resource.src
    )


    WebRequest.get(
        url,

        function(request)

            if request.is_error
                or request.response_code
                    ~= 200 then

                print(
                    "[FOWW] Resource request failed: "
                    .. resource.src
                    .. " : "
                    .. tostring(
                        request.error
                    )
                )


                callback(
                    false,
                    nil
                )

                return
            end


            local ok, data =
                pcall(
                    JSON.decode,
                    request.text
                )


            if not ok
                or data == nil then

                print(
                    "[FOWW] Could not decode resource: "
                    .. resource.src
                )


                callback(
                    false,
                    nil
                )

                return
            end


            if not mergeResource(
                aggregate,
                resource,
                data
            ) then

                callback(
                    false,
                    nil
                )

                return
            end


            loadResources(
                resources,
                index + 1,
                aggregate,
                callback
            )
        end
    )
end


--------------------------------------------------
-- Public load
--------------------------------------------------

function Registry.load(callback)

    print(
        "[FOWW] Loading manifest..."
    )


    WebRequest.get(
        MANIFEST_URL,

        function(request)

            if request.is_error
                or request.response_code
                    ~= 200 then

                print(
                    "[FOWW] Manifest request failed: "
                    .. tostring(
                        request.error
                    )
                )

                callback(
                    false,
                    nil
                )

                return
            end


            local ok, data =
                pcall(
                    JSON.decode,
                    request.text
                )


            if not ok
                or data == nil then

                print(
                    "[FOWW] Could not decode manifest JSON"
                )

                callback(
                    false,
                    nil
                )

                return
            end


            local valid,
                validationError =
                validateManifest(
                    data
                )


            if not valid then

                print(
                    "[FOWW] Invalid manifest: "
                    .. validationError
                )

                callback(
                    false,
                    nil
                )

                return
            end


            manifest =
                data


            print(
                "[FOWW] Manifest loaded: "
                .. tostring(
                    manifest.manifestVersion
                )
            )


            local aggregate =
                createAggregate()


            loadResources(
                manifest.resources,
                1,
                aggregate,
                callback
            )
        end
    )
end


--------------------------------------------------
-- Public accessors
--------------------------------------------------

function Registry.getCatalog()

    return catalog
end


function Registry.getModel(
    modelId
)

    return modelsById[
        modelId
    ]
end


return Registry