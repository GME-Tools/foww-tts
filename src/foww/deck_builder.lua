local DeckBuilder = {}


--------------------------------------------------
-- Helpers
--------------------------------------------------

local function copyCards(cards)

    local result = {}


    for _, card
        in ipairs(cards or {}) do

        table.insert(
            result,
            card
        )
    end


    return result
end


local function sortCards(cards)

    table.sort(
        cards,

        function(a, b)

            if a.atlas ~= b.atlas then
                return a.atlas < b.atlas
            end


            if a.slot ~= b.slot then
                return a.slot < b.slot
            end


            return
                (a.id or "")
                <
                (b.id or "")
        end
    )
end


local function buildScale(format)

    return {
        x = format.scale.x,
        y = format.scale.y,
        z = format.scale.z
    }
end


local function defaultTransform(scale)

    scale =
        scale
        or {
            x = 1,
            y = 1,
            z = 1
        }


    return {
        posX = 0,
        posY = 0,
        posZ = 0,

        rotX = 0,
        rotY = 180,
        rotZ = 180,

        scaleX = scale.x,
        scaleY = scale.y,
        scaleZ = scale.z
    }
end


local function buildAtlasState(atlas)

    return {
        FaceURL =
            atlas.face,

        BackURL =
            atlas.back,

        NumWidth =
            atlas.width,

        NumHeight =
            atlas.height,

        BackIsHidden =
            atlas.backIsHidden
            == true,

        UniqueBack =
            atlas.uniqueBack
            == true
    }
end


--------------------------------------------------
-- Resolve card physical format
--------------------------------------------------

local function getCardFormatId(
    card,
    cardFormats
)

    return
        cardFormats.typeFormats[
            card.type
        ]
end


local function getCardFormat(
    card,
    cardFormats
)

    local formatId =
        getCardFormatId(
            card,
            cardFormats
        )


    if formatId == nil then

        return nil,
            nil,
            "Card type has no physical format: "
            .. tostring(
                card.type
            )
    end


    local format =
        cardFormats.formats[
            formatId
        ]


    if format == nil then

        return nil,
            nil,
            "Unknown physical card format: "
            .. tostring(
                formatId
            )
    end


    return
        formatId,
        format,
        nil
end


--------------------------------------------------
-- Group cards by physical format
--------------------------------------------------

local function groupCardsByFormat(
    cards,
    cardFormats
)

    local groups = {}


    for _, card
        in ipairs(cards) do

        local formatId,
            format,
            formatError =
            getCardFormat(
                card,
                cardFormats
            )


        if formatError ~= nil then

            return nil,
                formatError
        end


        if groups[
            formatId
        ] == nil then

            groups[
                formatId
            ] = {
                id = formatId,
                format = format,
                cards = {}
            }
        end


        table.insert(
            groups[
                formatId
            ].cards,

            card
        )
    end


    return groups,
        nil
end


--------------------------------------------------
-- Runtime atlas keys
--------------------------------------------------

local function buildAtlasMap(
    cards,
    atlasesById
)

    local atlasKeys = {}
    local customDeck = {}

    local nextKey = 1
    local sideways = nil


    for _, card
        in ipairs(cards) do

        local atlas =
            atlasesById[
                card.atlas
            ]


        if atlas == nil then

            return nil,
                nil,
                nil,
                "Unknown atlas: "
                .. tostring(
                    card.atlas
                )
        end


        local atlasSideways =
            atlas.sideways
            == true


        if sideways == nil then

            sideways =
                atlasSideways

        elseif sideways
            ~= atlasSideways then

            return nil,
                nil,
                nil,
                "Cannot mix normal and sideways cards "
                .. "in the same deck"
        end


        if atlasKeys[
            card.atlas
        ] == nil then

            if nextKey > 99 then

                return nil,
                    nil,
                    nil,
                    "Too many atlases in one deck"
            end


            atlasKeys[
                card.atlas
            ] = nextKey


            customDeck[
                nextKey
            ] =
                buildAtlasState(
                    atlas
                )


            nextKey =
                nextKey + 1
        end
    end


    return
        atlasKeys,
        customDeck,
        sideways or false,
        nil
end


--------------------------------------------------
-- CardID
--------------------------------------------------

local function getCardId(
    card,
    atlasKey
)

    return
        atlasKey * 100
        + card.slot
end


--------------------------------------------------
-- Contained card data
--------------------------------------------------

local function buildContainedCardData(
    card,
    atlasKey,
    scale
)

    return {
        Name =
            "Card",

        Nickname =
            card.name
            or card.id,

        Description =
            "FOWW card"
            .. "\nID: "
            .. tostring(
                card.id
            )
            .. "\nType: "
            .. tostring(
                card.type
            ),

        CardID =
            getCardId(
                card,
                atlasKey
            ),

        Transform =
            defaultTransform(
                scale
            )
    }
end


--------------------------------------------------
-- Standalone card data
--------------------------------------------------

local function buildSingleCardData(
    card,
    atlas,
    atlasKey,
    scale
)

    return {
        Name =
            "Card",

        Nickname =
            card.name
            or card.id,

        Description =
            "FOWW card"
            .. "\nID: "
            .. tostring(
                card.id
            )
            .. "\nType: "
            .. tostring(
                card.type
            ),

        CardID =
            getCardId(
                card,
                atlasKey
            ),

        SidewaysCard =
            atlas.sideways
            == true,

        CustomDeck = {
            [atlasKey] =
                buildAtlasState(
                    atlas
                )
        },

        Transform =
            defaultTransform(
                scale
            )
    }
end


--------------------------------------------------
-- Build TTS object data
--------------------------------------------------

function DeckBuilder.buildData(
    cards,
    atlasesById,
    format,
    name
)

    local orderedCards =
        copyCards(
            cards
        )


    if #orderedCards == 0 then

        return nil,
            "No cards to spawn"
    end


    sortCards(
        orderedCards
    )


    local scale =
        buildScale(
            format
        )


    local atlasKeys,
        customDeck,
        sideways,
        atlasError =
        buildAtlasMap(
            orderedCards,
            atlasesById
        )


    if atlasError ~= nil then

        return nil,
            atlasError
    end


    --------------------------------------------------
    -- Single card
    --------------------------------------------------

    if #orderedCards == 1 then

        local card =
            orderedCards[1]

        local atlas =
            atlasesById[
                card.atlas
            ]

        local atlasKey =
            atlasKeys[
                card.atlas
            ]


        return
            buildSingleCardData(
                card,
                atlas,
                atlasKey,
                scale
            ),
            nil
    end


    --------------------------------------------------
    -- Deck
    --------------------------------------------------

    local deckIds = {}
    local containedObjects = {}


    for _, card
        in ipairs(
            orderedCards
        ) do

        local atlasKey =
            atlasKeys[
                card.atlas
            ]


        local cardData =
            buildContainedCardData(
                card,
                atlasKey,
                scale
            )


        table.insert(
            deckIds,
            cardData.CardID
        )


        table.insert(
            containedObjects,
            cardData
        )
    end


    return {
        Name =
            "DeckCustom",

        Nickname =
            name
            or "FOWW Cards",

        Description =
            "Dynamically generated FOWW deck",

        Transform =
            defaultTransform(
                scale
            ),

        SidewaysCard =
            sideways,

        DeckIDs =
            deckIds,

        CustomDeck =
            customDeck,

        ContainedObjects =
            containedObjects
    },
    nil
end


--------------------------------------------------
-- Spawn one physical-format group
--------------------------------------------------

function DeckBuilder.spawn(
    cards,
    atlasesById,
    format,
    options
)

    options =
        options
        or {}


    local data,
        buildError =
        DeckBuilder.buildData(
            cards,
            atlasesById,
            format,
            options.name
        )


    if data == nil then

        return nil,
            buildError
    end


    local position =
        options.position
        or {
            x = 0,
            y = 3,
            z = 0
        }


    local rotation =
        options.rotation
        or {
            x = 0,
            y = 180,
            z = 180
        }


    local ok,
        object =
        pcall(
            spawnObjectData,

            {
                data =
                    data,

                position =
                    position,

                rotation =
                    rotation
            }
        )


    if not ok then

        return nil,
            tostring(
                object
            )
    end


    if object == nil then

        return nil,
            "spawnObjectData returned nil"
    end


    --------------------------------------------------
    -- Explicitly apply the physical scale as well.
    --------------------------------------------------

    local scale =
        buildScale(
            format
        )


    object.setScale(
        scale
    )


    return object,
        nil
end


--------------------------------------------------
-- Spawn cards grouped by physical format
--------------------------------------------------

function DeckBuilder.spawnGrouped(
    cards,
    atlasesById,
    cardFormats,
    options
)

    options =
        options
        or {}


    local groups,
        groupError =
        groupCardsByFormat(
            cards,
            cardFormats
        )


    if groups == nil then

        return nil,
            groupError
    end


    --------------------------------------------------
    -- Deterministic format ordering
    --------------------------------------------------

    local formatIds = {}


    for formatId, _
        in pairs(groups) do

        table.insert(
            formatIds,
            formatId
        )
    end


    table.sort(
        formatIds
    )


    --------------------------------------------------
    -- Layout
    --------------------------------------------------

    local origin =
        options.position
        or {
            x = 0,
            y = 3,
            z = 0
        }


    local xSpacing =
        options.xSpacing
        or 5


    local spawnedObjects = {}


    --------------------------------------------------
    -- One deck per physical format
    --------------------------------------------------

    for index, formatId
        in ipairs(
            formatIds
        ) do

        local group =
            groups[
                formatId
            ]


        local position = {
            x =
                origin.x
                + (
                    index - 1
                )
                * xSpacing,

            y =
                origin.y,

            z =
                origin.z
        }


        local baseName =
            options.name
            or "FOWW Available Cards"


        local object,
            spawnError =
            DeckBuilder.spawn(
                group.cards,
                atlasesById,
                group.format,

                {
                    name =
                        baseName
                        .. " - "
                        .. formatId,

                    position =
                        position,

                    rotation =
                        options.rotation
                }
            )


        if object == nil then

            return nil,
                "Could not spawn format "
                .. formatId
                .. ": "
                .. tostring(
                    spawnError
                )
        end


        table.insert(
            spawnedObjects,
            object
        )
    end


    return spawnedObjects,
        nil
end


return DeckBuilder