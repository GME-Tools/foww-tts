local ModelSpawner =
    require("foww.model_spawner")


local Armory = {}


local ARMORY_TAG =
    "foww-armory-spawned"


--------------------------------------------------
-- Layout
--------------------------------------------------

local function normalizeLayout(layout)

    layout =
        layout or {}

    local origin =
        layout.origin or {}

    return {
        origin = {
            x = origin.x or -20,
            y = origin.y or 2,
            z = origin.z or 15
        },

        columns =
            layout.columns or 6,

        xSpacing =
            layout.xSpacing or 2.5,

        zSpacing =
            layout.zSpacing or 3.0,

        occupancyRadius =
            layout.occupancyRadius or 0.8
    }
end


local function getSlotPosition(
    slotIndex,
    layout
)

    local column =
        slotIndex % layout.columns

    local row =
        math.floor(
            slotIndex
            / layout.columns
        )

    return {
        x =
            layout.origin.x
            + column
            * layout.xSpacing,

        y =
            layout.origin.y,

        z =
            layout.origin.z
            + row
            * layout.zSpacing
    }
end


--------------------------------------------------
-- Slot occupancy
--------------------------------------------------

local function isSlotOccupied(
    position,
    layout
)

    local radius =
        layout.occupancyRadius

    local radiusSquared =
        radius * radius


    for _, object
        in ipairs(getAllObjects()) do

        if object.hasTag(ARMORY_TAG) then

            local objectPosition =
                object.getPosition()

            local dx =
                objectPosition.x
                - position.x

            local dz =
                objectPosition.z
                - position.z

            local distanceSquared =
                dx * dx
                + dz * dz


            if distanceSquared
                <= radiusSquared then

                return true
            end
        end
    end


    return false
end


local function findFreePosition(layout)

    --------------------------------------------------
    -- 200 staging slots is an arbitrary safety limit.
    --------------------------------------------------

    for slotIndex = 0, 199 do

        local position =
            getSlotPosition(
                slotIndex,
                layout
            )

        if not isSlotOccupied(
            position,
            layout
        ) then

            return position
        end
    end


    return nil
end


--------------------------------------------------
-- Spawn one playable model
--------------------------------------------------

function Armory.spawnModel(
    model,
    layoutData
)

    if model == nil then
        return nil
    end


    if model.asset == nil then

        print(
            "[FOWW] Cannot spawn "
            .. model.id
            .. ": no asset"
        )

        return nil
    end


    local layout =
        normalizeLayout(
            layoutData
        )


    local position =
        findFreePosition(layout)


    if position == nil then

        print(
            "[FOWW] Armory staging area is full"
        )

        return nil
    end


    local object =
        ModelSpawner.spawn(
            model,
            position
        )


    if object ~= nil then

        --------------------------------------------------
        -- Metadata only.
        --
        -- This does NOT make the object temporary.
        -- It remains a real playable model.
        --------------------------------------------------

        object.addTag(
            ARMORY_TAG
        )

        print(
            "[FOWW] Armory spawned: "
            .. model.name
        )
    end


    return object
end


--------------------------------------------------
-- Spawn a set of models
--------------------------------------------------

function Armory.spawnModels(
    models,
    layoutData
)

    local spawned =
        0

    local unavailable =
        0


    for _, model
        in ipairs(models or {}) do

        if model.asset == nil then

            unavailable =
                unavailable + 1

        else

            local object =
                Armory.spawnModel(
                    model,
                    layoutData
                )

            if object ~= nil then
                spawned =
                    spawned + 1
            end
        end
    end


    print(
        "[FOWW] Armory batch: "
        .. tostring(spawned)
        .. " spawned, "
        .. tostring(unavailable)
        .. " unavailable"
    )


    return spawned
end


return Armory