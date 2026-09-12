local Products = {}

local GENERATED_TAG = "foww-generated"
local PRODUCT_TAG   = "foww-product"

local catalogById = {}


local function vector(data, default)

    if data == nil then
        return default
    end

    return {
        x = data.x or default.x,
        y = data.y or default.y,
        z = data.z or default.z
    }
end


local function decodeGMNotes(object)

    local notes = object.getGMNotes()

    if notes == nil or notes == "" then
        return nil
    end

    local ok, data = pcall(JSON.decode, notes)

    if not ok then
        return nil
    end

    return data
end


function Products.getProductId(object)

    local data = decodeGMNotes(object)

    if data == nil then
        return nil
    end

    if data.kind ~= "product" then
        return nil
    end

    return data.productId
end


function Products.getProductForObject(object)

    local productId = Products.getProductId(object)

    if productId == nil then
        return nil
    end

    return catalogById[productId]
end


local function setMetadata(object, product)

    object.setName(product.name)

    object.setDescription(
        "FOWW product\n"
        .. "ID: " .. product.id
        .. "\nWave: " .. tostring(product.wave)
    )

    if not object.hasTag(GENERATED_TAG) then
        object.addTag(GENERATED_TAG)
    end

    if not object.hasTag(PRODUCT_TAG) then
        object.addTag(PRODUCT_TAG)
    end

    object.setGMNotes(JSON.encode({
        generated = true,
        kind = "product",
        productId = product.id
    }))
end


local function applyLayout(object, product)

    local box = product.box

    object.setPosition(
        vector(
            box.position,
            {x = 0, y = 2, z = 0}
        )
    )

    object.setRotation(
        vector(
            box.rotation,
            {x = 0, y = 0, z = 0}
        )
    )

    object.setScale(
        vector(
            box.scale,
            {x = 1, y = 1, z = 1}
        )
    )

    object.setLock(box.locked ~= false)
end


local function tileNeedsRebuild(object, product)

    local current = object.getCustomObject()
    local box = product.box

    if current == nil then
        return true
    end

    local expectedThickness =
        box.thickness or 0.5

    local currentThickness =
        current.thickness or 0.5

    if math.abs(
        currentThickness - expectedThickness
    ) > 0.0001 then
        return true
    end

    local expectedType =
        box.type or 0

    local currentType =
        current.type or 0

    if currentType ~= expectedType then
        return true
    end

    return false
end


local function spawnTile(product, opened)

    local box = product.box

    local image =
        opened
        and box.imageOpen
        or box.imageClosed

    local object = spawnObject({
        type = "Custom_Tile",

        position = vector(
            box.position,
            {x = 0, y = 2, z = 0}
        ),

        rotation = vector(
            box.rotation,
            {x = 0, y = 0, z = 0}
        ),

        sound = false
    })

    object.setCustomObject({
        image = image,
        image_bottom = box.imageBottom,
        type = box.type or 0,
        thickness = box.thickness or 0.5,
        stackable = false
    })

    setMetadata(object, product)
    applyLayout(object, product)

    return object
end


local function spawnProduct(product, opened)

    if product.box == nil then
        return nil
    end

    if product.box.kind == "tile" then
        return spawnTile(product, opened)
    end

    print(
        "[FOWW] Unsupported box kind: "
        .. tostring(product.box.kind)
    )

    return nil
end


function Products.refreshVisual(
    object,
    product,
    opened
)

    local box = product.box

    local desiredImage =
        opened
        and box.imageOpen
        or box.imageClosed


    --------------------------------------------------
    -- Update tile image if required
    --------------------------------------------------

    local custom = object.getCustomObject()

    if custom.image ~= desiredImage then

        object.setCustomObject({
            image = desiredImage,
            image_bottom = box.imageBottom,
            type = box.type or 0,
            thickness = box.thickness or 0.5,
            stackable = false
        })

        -- reload destroys/resurrects the object,
        -- so the previous reference becomes invalid.
        object = object.reload()

        setMetadata(object, product)
        applyLayout(object, product)
    end


    --------------------------------------------------
    -- Rebuild interaction
    --------------------------------------------------

    object.clearButtons()
    object.clearContextMenu()


    if opened then

        ------------------------------------------------
        -- OPEN
        -- No button, only right-click Close box
        ------------------------------------------------

        object.addContextMenuItem(
            "Close box",

            function(
                player_color,
                position,
                clicked_object
            )

                fowwSetProductState(
                    clicked_object,
                    player_color,
                    false
                )
            end
        )


    else

        ------------------------------------------------
        -- CLOSED
        -- Invisible button covering the box
        ------------------------------------------------

        local button =
            box.openButton or {}

        object.createButton({

            click_function =
                "fowwOpenProduct",

            function_owner =
                Global,

            label = "",

            position =
                vector(
                    button.position,
                    {x = 0, y = 0.35, z = 0}
                ),

            rotation =
                vector(
                    button.rotation,
                    {x = 0, y = 0, z = 0}
                ),

            width =
                button.width or 1400,

            height =
                button.height or 900,

            font_size = 1,

            -- Fully transparent
            color = {
                0,
                0,
                0,
                0
            },

            font_color = {
                0,
                0,
                0,
                0
            },

            tooltip = "Open box"
        })


        object.addContextMenuItem(
            "Open box",

            function(
                player_color,
                position,
                clicked_object
            )

                fowwSetProductState(
                    clicked_object,
                    player_color,
                    true
                )
            end
        )
    end


    return object
end


function Products.reconcile(
    catalog,
    isOpenFunction
)

    catalogById = {}

    for _, product
        in ipairs(catalog.products or {}) do

        catalogById[product.id] = product
    end


    local existing = {}


    for _, object in ipairs(getAllObjects()) do

        if object.hasTag(PRODUCT_TAG) then

            local productId =
                Products.getProductId(object)

            local product =
                catalogById[productId]


            if product == nil then

                print(
                    "[FOWW] Removing obsolete product: "
                    .. tostring(productId)
                )

                destroyObject(object)


            elseif existing[productId] ~= nil then

                print(
                    "[FOWW] Removing duplicate product: "
                    .. productId
                )

                destroyObject(object)


            else
                existing[productId] = object
            end
        end
    end


    for _, product
        in ipairs(catalog.products or {}) do

        local object = existing[product.id]
        local opened = isOpenFunction(product)


        if object ~= nil
            and product.box.kind == "tile"
            and tileNeedsRebuild(
                object,
                product
            ) then

            print(
                "[FOWW] Rebuilding changed product: "
                .. product.name
            )

            destroyObject(object)
            object = nil
        end


        if object == nil then

            object = spawnProduct(product, opened)

            print(
                "[FOWW] Created product: "
                .. product.name
            )

        else

            setMetadata(object, product)
            applyLayout(object, product)

            print(
                "[FOWW] Reused product: "
                .. product.name
            )
        end


        if object ~= nil then

            Products.refreshVisual(
                object,
                product,
                opened
            )
        end
    end


    print("[FOWW] Product reconciliation complete")
end


return Products