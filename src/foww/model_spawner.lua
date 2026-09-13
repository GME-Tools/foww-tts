local ModelSpawner = {}

local MATERIALS = {
    plastic = 0,
    wood = 1,
    metal = 2,
    cardboard = 3
}


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


    local asset = model.asset


    if asset.kind ~= "custom_model" then
        print(
            "[FOWW] Unsupported model asset kind: "
            .. tostring(asset.kind)
        )
        return nil
    end


    if asset.mesh == nil
        or asset.diffuse == nil then

        print(
            "[FOWW] Incomplete asset for model: "
            .. model.id
        )

        return nil
    end


    local object = spawnObject({
        type = "Custom_Model",

        position =
            position
            or {x = 0, y = 2, z = 0},

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


    print(
        "[FOWW] Spawned model: "
        .. model.name
    )


    return object
end


return ModelSpawner