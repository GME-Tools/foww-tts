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


local function defaultTransform()

    return {
        posX = 0,
        posY = 0,
        posZ = 0,

        rotX = 0,
        rotY = 180,
        rotZ = 180,

        scaleX = 1,
        scaleY = 1,
        scaleZ = 1
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


        --------------------------------------------------
        -- One TTS deck should keep a common orientation.
        --------------------------------------------------

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


        --------------------------------------------------
        -- Assign one CustomDeck key per atlas.
        --------------------------------------------------

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
    atlasKey
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
            defaultTransform()
    }
end


--------------------------------------------------
-- Standalone card data
--------------------------------------------------

local function buildSingleCardData(
    card,
    atlas,
    atlasKey
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
            defaultTransform()
    }
end


--------------------------------------------------
-- Build TTS object data
--------------------------------------------------

function DeckBuilder.buildData(
    cards,
    atlasesById,
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
                atlasKey
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
                atlasKey
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
            defaultTransform(),

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
-- Spawn
--------------------------------------------------

function DeckBuilder.spawn(
    cards,
    atlasesById,
    options
)

    options =
        options or {}


    local data,
        buildError =
        DeckBuilder.buildData(
            cards,
            atlasesById,
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


    return object,
        nil
end


return DeckBuilder