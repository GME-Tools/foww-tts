local Pool = {}


--------------------------------------------------
-- Build available content
--------------------------------------------------

function Pool.build(
    catalog,
    modelsById,
    cardsById,
    isProductOpen
)

    local availableModels = {}
    local availableCards = {}


    for _, product
        in ipairs(
            catalog.products
            or {}
        ) do

        if isProductOpen(
            product
        ) then

            local contents =
                product.contents
                or {}


            --------------------------------------------------
            -- Models
            --------------------------------------------------

            for _, modelId
                in ipairs(
                    contents.models
                    or {}
                ) do

                local model =
                    modelsById[
                        modelId
                    ]


                if model ~= nil then

                    availableModels[
                        modelId
                    ] = model
                end
            end


            --------------------------------------------------
            -- Cards
            --------------------------------------------------

            for _, cardId
                in ipairs(
                    contents.cards
                    or {}
                ) do

                local card =
                    cardsById[
                        cardId
                    ]


                if card ~= nil then

                    availableCards[
                        cardId
                    ] = card
                end
            end
        end
    end


    return {
        models =
            availableModels,

        cards =
            availableCards
    }
end


--------------------------------------------------
-- Generic counter
--------------------------------------------------

local function countEntries(values)

    local count = 0


    for _, _
        in pairs(
            values
            or {}
        ) do

        count =
            count + 1
    end


    return count
end


--------------------------------------------------
-- Public counters
--------------------------------------------------

function Pool.countModels(pool)

    if pool == nil then
        return 0
    end


    return countEntries(
        pool.models
    )
end


function Pool.countCards(pool)

    if pool == nil then
        return 0
    end


    return countEntries(
        pool.cards
    )
end


return Pool