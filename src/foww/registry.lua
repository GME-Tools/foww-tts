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
local layout = nil
local models = nil
local cards = nil
local cardFormats = nil

local modelsById = {}
local cardsById = {}
local atlasesById = {}


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


local function countEntries(values)

    local count = 0


    for _, _
        in pairs(values or {}) do

        count =
            count + 1
    end


    return count
end


local function isPositiveNumber(value)

    return
        type(value) == "number"
        and value > 0
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


    local supportedKinds = {
        layout = true,
        products = true,
        models = true,
        cards = true,
        card_formats = true
    }


    for index, resource
        in ipairs(data.resources) do

        if type(resource.kind) ~= "string"
            or resource.kind == "" then

            return false,
                "Resource #"
                .. tostring(index)
                .. " has no kind"
        end


        if not supportedKinds[
            resource.kind
        ] then

            return false,
                "Resource #"
                .. tostring(index)
                .. " has unsupported kind: "
                .. tostring(
                    resource.kind
                )
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
-- Cards validation
--------------------------------------------------

local function validateCards(data)

    if type(data) ~= "table" then

        return false,
            "Cards root is not an object"
    end


    if type(data.atlases) ~= "table" then

        return false,
            "Missing atlases array"
    end


    if type(data.cards) ~= "table" then

        return false,
            "Missing cards array"
    end


    --------------------------------------------------
    -- Atlases
    --------------------------------------------------

    local atlasIds = {}


    for index, atlas
        in ipairs(data.atlases) do

        if type(atlas.id) ~= "string"
            or atlas.id == "" then

            return false,
                "Atlas #"
                .. tostring(index)
                .. " has no valid id"
        end


        if atlasIds[atlas.id] then

            return false,
                "Duplicate atlas id: "
                .. atlas.id
        end


        if type(atlas.face) ~= "string"
            or atlas.face == "" then

            return false,
                "Atlas "
                .. atlas.id
                .. " has no face URL"
        end


        if type(atlas.back) ~= "string"
            or atlas.back == "" then

            return false,
                "Atlas "
                .. atlas.id
                .. " has no back URL"
        end


        if type(atlas.width) ~= "number"
            or atlas.width < 1
            or atlas.width
                ~= math.floor(
                    atlas.width
                ) then

            return false,
                "Atlas "
                .. atlas.id
                .. " has invalid width"
        end


        if type(atlas.height) ~= "number"
            or atlas.height < 1
            or atlas.height
                ~= math.floor(
                    atlas.height
                ) then

            return false,
                "Atlas "
                .. atlas.id
                .. " has invalid height"
        end


        local capacity =
            atlas.width
            * atlas.height


        if capacity > 100 then

            return false,
                "Atlas "
                .. atlas.id
                .. " contains more than 100 slots"
        end


        atlasIds[
            atlas.id
        ] = atlas
    end


    --------------------------------------------------
    -- Cards
    --------------------------------------------------

    local cardIds = {}
    local occupiedSlots = {}


    for index, card
        in ipairs(data.cards) do

        if type(card.id) ~= "string"
            or card.id == "" then

            return false,
                "Card #"
                .. tostring(index)
                .. " has no valid id"
        end


        if cardIds[card.id] then

            return false,
                "Duplicate card id: "
                .. card.id
        end


        if type(card.name) ~= "string"
            or card.name == "" then

            return false,
                "Card "
                .. card.id
                .. " has no name"
        end


        if type(card.type) ~= "string"
            or card.type == "" then

            return false,
                "Card "
                .. card.id
                .. " has no type"
        end


        if type(card.atlas) ~= "string"
            or card.atlas == "" then

            return false,
                "Card "
                .. card.id
                .. " has no atlas"
        end


        local atlas =
            atlasIds[
                card.atlas
            ]


        if atlas == nil then

            return false,
                "Card "
                .. card.id
                .. " references unknown atlas: "
                .. tostring(
                    card.atlas
                )
        end


        if type(card.slot) ~= "number"
            or card.slot < 0
            or card.slot
                ~= math.floor(
                    card.slot
                ) then

            return false,
                "Card "
                .. card.id
                .. " has invalid slot"
        end


        local capacity =
            atlas.width
            * atlas.height


        if card.slot >= capacity
            or card.slot > 99 then

            return false,
                "Card "
                .. card.id
                .. " has slot outside atlas: "
                .. tostring(
                    card.slot
                )
        end


        local slotKey =
            card.atlas
            .. ":"
            .. tostring(
                card.slot
            )


        if occupiedSlots[
            slotKey
        ] then

            return false,
                "Atlas slot used twice: "
                .. slotKey
        end


        occupiedSlots[
            slotKey
        ] = true


        cardIds[
            card.id
        ] = true
    end


    return true, nil
end


--------------------------------------------------
-- Card formats validation
--------------------------------------------------

local function validateCardFormats(data)

    if type(data) ~= "table" then

        return false,
            "Card formats root is not an object"
    end


    if type(data.formats) ~= "table" then

        return false,
            "Missing card formats map"
    end


    if type(data.typeFormats) ~= "table" then

        return false,
            "Missing card typeFormats map"
    end


    --------------------------------------------------
    -- Physical formats
    --------------------------------------------------

    local formatCount = 0


    for formatId, format
        in pairs(data.formats) do

        formatCount =
            formatCount + 1


        if type(formatId) ~= "string"
            or formatId == "" then

            return false,
                "Invalid card format id"
        end


        if type(format) ~= "table" then

            return false,
                "Card format "
                .. formatId
                .. " is not an object"
        end


        if type(format.scale) ~= "table" then

            return false,
                "Card format "
                .. formatId
                .. " has no scale"
        end


        if not isPositiveNumber(
            format.scale.x
        ) then

            return false,
                "Card format "
                .. formatId
                .. " has invalid scale.x"
        end


        if not isPositiveNumber(
            format.scale.y
        ) then

            return false,
                "Card format "
                .. formatId
                .. " has invalid scale.y"
        end


        if not isPositiveNumber(
            format.scale.z
        ) then

            return false,
                "Card format "
                .. formatId
                .. " has invalid scale.z"
        end
    end


    if formatCount == 0 then

        return false,
            "No card formats defined"
    end


    --------------------------------------------------
    -- Card type -> physical format
    --------------------------------------------------

    for cardType, formatId
        in pairs(
            data.typeFormats
        ) do

        if type(cardType) ~= "string"
            or cardType == "" then

            return false,
                "Invalid card type in typeFormats"
        end


        if type(formatId) ~= "string"
            or formatId == "" then

            return false,
                "Card type "
                .. cardType
                .. " has invalid format id"
        end


        if data.formats[
            formatId
        ] == nil then

            return false,
                "Card type "
                .. cardType
                .. " references unknown format: "
                .. formatId
        end
    end


    return true, nil
end


--------------------------------------------------
-- Cards / physical formats cross-validation
--------------------------------------------------

local function validateCardPhysicalFormats(
    cardsData,
    cardFormatsData
)

    local atlasFormats = {}


    for _, card
        in ipairs(
            cardsData.cards
            or {}
        ) do

        local formatId =
            cardFormatsData.typeFormats[
                card.type
            ]


        if formatId == nil then

            return false,
                "Card "
                .. card.id
                .. " uses unmapped type: "
                .. tostring(
                    card.type
                )
        end


        local format =
            cardFormatsData.formats[
                formatId
            ]


        if format == nil then

            return false,
                "Card "
                .. card.id
                .. " resolves to unknown format: "
                .. tostring(
                    formatId
                )
        end


        --------------------------------------------------
        -- One atlas must represent one physical format.
        --------------------------------------------------

        local previousFormat =
            atlasFormats[
                card.atlas
            ]


        if previousFormat ~= nil
            and previousFormat
                ~= formatId then

            return false,
                "Atlas "
                .. card.atlas
                .. " mixes physical formats "
                .. previousFormat
                .. " and "
                .. formatId
        end


        atlasFormats[
            card.atlas
        ] =
            formatId
    end


    return true, nil
end


--------------------------------------------------
-- Product content cross-validation
--------------------------------------------------

local function validateProductContents(
    catalogData,
    modelIndex,
    cardIndex
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


        for _, cardId
            in ipairs(
                contents.cards
                or {}
            ) do

            if cardIndex[
                cardId
            ] == nil then

                return false,
                    "Product "
                    .. product.id
                    .. " references unknown card: "
                    .. cardId
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


        layout = {},


        models = {
            schemaVersion = 1,

            modelsVersion =
                manifest
                and manifest.manifestVersion
                or "unknown",

            models = {}
        },


        cards = {
            schemaVersion = 1,

            cardsVersion =
                manifest
                and manifest.manifestVersion
                or "unknown",

            atlases = {},
            cards = {}
        },


        cardFormats = {
            schemaVersion = 1,

            cardFormatsVersion =
                manifest
                and manifest.manifestVersion
                or "unknown",

            formats = {},
            typeFormats = {}
        }
    }
end


--------------------------------------------------
-- Merge resources
--------------------------------------------------

local function mergeLayoutResource(
    aggregate,
    data
)

    for key, value
        in pairs(
            data.layout
            or {}
        ) do

        aggregate.layout[
            key
        ] = value
    end


    return true
end


local function mergeProductsResource(
    aggregate,
    data
)

    appendAll(
        aggregate.catalog.products,
        data.products
    )


    return true
end


local function mergeModelsResource(
    aggregate,
    data
)

    appendAll(
        aggregate.models.models,
        data.models
    )


    return true
end


local function mergeCardsResource(
    aggregate,
    data
)

    appendAll(
        aggregate.cards.atlases,
        data.atlases
    )


    appendAll(
        aggregate.cards.cards,
        data.cards
    )


    return true
end


local function mergeCardFormatsResource(
    aggregate,
    data
)

    for formatId, format
        in pairs(
            data.formats
            or {}
        ) do

        if aggregate.cardFormats.formats[
            formatId
        ] ~= nil then

            print(
                "[FOWW] Duplicate card format: "
                .. tostring(
                    formatId
                )
            )

            return false
        end


        aggregate.cardFormats.formats[
            formatId
        ] = format
    end


    for cardType, formatId
        in pairs(
            data.typeFormats
            or {}
        ) do

        if aggregate.cardFormats.typeFormats[
            cardType
        ] ~= nil then

            print(
                "[FOWW] Duplicate card type format: "
                .. tostring(
                    cardType
                )
            )

            return false
        end


        aggregate.cardFormats.typeFormats[
            cardType
        ] = formatId
    end


    return true
end


--------------------------------------------------
-- Merge one resource
--------------------------------------------------

local function mergeResource(
    aggregate,
    resource,
    data
)

    if resource.kind
        == "layout" then

        return
            mergeLayoutResource(
                aggregate,
                data
            )
    end


    if resource.kind
        == "products" then

        return
            mergeProductsResource(
                aggregate,
                data
            )
    end


    if resource.kind
        == "models" then

        return
            mergeModelsResource(
                aggregate,
                data
            )
    end


    if resource.kind
        == "cards" then

        return
            mergeCardsResource(
                aggregate,
                data
            )
    end


    if resource.kind
        == "card_formats" then

        return
            mergeCardFormatsResource(
                aggregate,
                data
            )
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
    -- Cards
    --------------------------------------------------

    local cardsValid,
        cardsError =
        validateCards(
            aggregate.cards
        )


    if not cardsValid then

        print(
            "[FOWW] Invalid cards registry: "
            .. cardsError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Card formats
    --------------------------------------------------

    local formatsValid,
        formatsError =
        validateCardFormats(
            aggregate.cardFormats
        )


    if not formatsValid then

        print(
            "[FOWW] Invalid card formats: "
            .. formatsError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Cards -> formats
    --------------------------------------------------

    local physicalValid,
        physicalError =
        validateCardPhysicalFormats(
            aggregate.cards,
            aggregate.cardFormats
        )


    if not physicalValid then

        print(
            "[FOWW] Invalid card physical formats: "
            .. physicalError
        )

        callback(
            false,
            nil
        )

        return
    end


    --------------------------------------------------
    -- Build model index
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
    -- Build atlas index
    --------------------------------------------------

    atlasesById = {}


    for _, atlas
        in ipairs(
            aggregate.cards.atlases
        ) do

        atlasesById[
            atlas.id
        ] = atlas
    end


    --------------------------------------------------
    -- Build card index
    --------------------------------------------------

    cardsById = {}


    for _, card
        in ipairs(
            aggregate.cards.cards
        ) do

        cardsById[
            card.id
        ] = card
    end


    --------------------------------------------------
    -- Validate product references
    --------------------------------------------------

    local contentsValid,
        contentsError =
        validateProductContents(
            aggregate.catalog,
            modelsById,
            cardsById
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

    layout =
        aggregate.layout

    models =
        aggregate.models

    cards =
        aggregate.cards

    cardFormats =
        aggregate.cardFormats


    --------------------------------------------------
    -- Logging
    --------------------------------------------------

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


    print(
        "[FOWW] Atlases loaded: "
        .. tostring(
            #cards.atlases
        )
    )


    print(
        "[FOWW] Cards loaded: "
        .. tostring(
            #cards.cards
        )
    )


    print(
        "[FOWW] Card formats loaded: "
        .. tostring(
            countEntries(
                cardFormats.formats
            )
        )
    )


    --------------------------------------------------
    -- Runtime registry object
    --------------------------------------------------

    callback(
        true,
        {
            catalog =
                catalog,

            layout =
                layout,

            models =
                models,

            modelsById =
                modelsById,

            cards =
                cards,

            cardsById =
                cardsById,

            atlasesById =
                atlasesById,

            cardFormats =
                cardFormats
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

    if index > #resources then

        finalize(
            aggregate,
            callback
        )

        return
    end


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


function Registry.getLayout()

    return layout
end


function Registry.getModel(
    modelId
)

    return modelsById[
        modelId
    ]
end


function Registry.getCard(
    cardId
)

    return cardsById[
        cardId
    ]
end


function Registry.getAtlas(
    atlasId
)

    return atlasesById[
        atlasId
    ]
end


function Registry.getCardFormats()

    return cardFormats
end


return Registry