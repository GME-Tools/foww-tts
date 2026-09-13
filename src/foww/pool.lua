local Pool = {}


function Pool.build(
    catalog,
    modelsById,
    isProductOpen
)

    local availableModels = {}


    for _, product
        in ipairs(catalog.products or {}) do

        if isProductOpen(product) then

            local contents =
                product.contents or {}

            for _, modelId
                in ipairs(contents.models or {}) do

                availableModels[modelId] =
                    modelsById[modelId]
            end
        end
    end


    return {
        models = availableModels
    }
end


function Pool.countModels(pool)

    local count = 0

    for _, _ in pairs(pool.models) do
        count = count + 1
    end

    return count
end


return Pool