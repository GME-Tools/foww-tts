local ModelSpawner = {}

local MATERIALS = {
    plastic = 0,
    wood = 1,
    metal = 2,
    cardboard = 3
}


--------------------------------------------------
-- Helpers
--------------------------------------------------

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


local function materialId(material)

    if type(material) == "number" then
        return material
    end

    if type(material) == "string" then

        local id =
            MATERIALS[string.lower(material)]

        if id ~= nil then
            return id
        end
    end

    return 0
end


local function addVectors(a, b)

    return {
        x = (a.x or 0) + (b.x or 0),
        y = (a.y or 0) + (b.y or 0),
        z = (a.z or 0) + (b.z or 0)
    }
end


--------------------------------------------------
-- Spawn one Custom Model
--------------------------------------------------

local function spawnCustomModel(
    asset,
    position,
    rotation
)

    local object = spawnObject({
        type = "Custom_Model",

        position =
            position
            or {x = 0, y = 2, z = 0},

        rotation =
            rotation
            or {x = 0, y = 0, z = 0},

        sound = false
    })


    object.setCustomObject({
        mesh = asset.mesh,
        diffuse = asset.diffuse,

        normal = asset.normal,
        collider = asset.collider,

        convex =
            asset.convex == true,

        type =
            asset.type or 1,

        material =
            materialId(asset.material),

        specular_intensity =
            asset.specularIntensity or 0.1,

        specular_sharpness =
            asset.specularSharpness or 3,

        fresnel_strength =
            asset.fresnelStrength or 0.1,

        cast_shadows =
            asset.castShadows ~= false
    })


    object.setScale(
        vector(
            asset.scale,
            {x = 1, y = 1, z = 1}
        )
    )


    return object
end


--------------------------------------------------
-- Final model metadata
--------------------------------------------------

local function configureModelObject(
    object,
    model
)

    object.setName(model.name)

    object.setDescription(
        "FOWW model\n"
        .. "ID: " .. model.id
        .. "\nFaction: "
        .. tostring(model.faction)
    )


    object.addTag("foww-model")
    object.addTag("foww-spawned")


    object.setGMNotes(JSON.encode({
        generated = true,
        kind = "model",
        modelId = model.id
    }))
end


--------------------------------------------------
-- Simple model
--------------------------------------------------

local function spawnSimple(
    model,
    position
)

    local object =
        spawnCustomModel(
            model.asset,
            position,
            {x = 0, y = 0, z = 0}
        )


    configureModelObject(
        object,
        model
    )


    return object
end


--------------------------------------------------
-- Composite model
--------------------------------------------------

local function spawnComposite(
    model,
    position
)

    local asset =
        model.asset


    if asset.root == nil then

        print(
            "[FOWW] Composite model has no root: "
            .. model.id
        )

        return nil
    end


    --------------------------------------------------
    -- Spawn physical root
    --------------------------------------------------

    local root =
        spawnCustomModel(
            asset.root,
            position,
            {x = 0, y = 0, z = 0}
        )


    configureModelObject(
        root,
        model
    )


    --------------------------------------------------
    -- Spawn and attach parts
    --------------------------------------------------

    for _, part
        in ipairs(asset.parts or {}) do

        local offset =
            vector(
                part.offset,
                {x = 0, y = 0, z = 0}
            )


        -- Offset is expressed in root-local coordinates.
        local worldPosition =
            root.positionToWorld(offset)


        local rootRotation =
            root.getRotation()


        local partRotation =
            addVectors(
                rootRotation,

                vector(
                    part.rotation,
                    {x = 0, y = 0, z = 0}
                )
            )


        local child =
            spawnCustomModel(
                part,
                worldPosition,
                partRotation
            )


        --------------------------------------------------
        -- Convert spawned object into child attachment
        --------------------------------------------------

        root.addAttachment(child)
    end


    return root
end


--------------------------------------------------
-- Public spawn
--------------------------------------------------

function ModelSpawner.spawn(
    model,
    position
)

    if model == nil then

        print("[FOWW] Cannot spawn nil model")

        return nil
    end


    if model.asset == nil then

        print(
            "[FOWW] Model has no asset: "
            .. model.id
        )

        return nil
    end


    local kind =
        model.asset.kind


    local object = nil


    if kind == "custom_model" then

        object =
            spawnSimple(
                model,
                position
            )


    elseif kind == "composite_model" then

        object =
            spawnComposite(
                model,
                position
            )


    else

        print(
            "[FOWW] Unsupported model asset kind: "
            .. tostring(kind)
        )

        return nil
    end


    if object ~= nil then

        print(
            "[FOWW] Spawned model: "
            .. model.name
        )
    end


    return object
end


return ModelSpawner