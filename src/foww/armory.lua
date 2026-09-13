local ModelSpawner =
    require("foww.model_spawner")


local Armory = {}


local DISPLAY_TAG =
    "foww-model-display"


--------------------------------------------------
-- Helpers
--------------------------------------------------

local function getOrigin(layout)

    local origin =
        layout
        and layout.origin
        or {}

    return {
        x = origin.x or -20,
        y = origin.y or 2,
        z = origin.z or 15
    }
end


local function getFactionName(model)

    if model.faction == nil
        or model.faction == "" then

        return "unassigned"
    end

    return model.faction
end


--------------------------------------------------
-- Build faction groups
--------------------------------------------------

local function groupModelsByFaction(pool)

    local groups = {}


    for _, model
        in pairs(pool.models or {}) do

        local faction =
            getFactionName(model)


        if groups[faction] == nil then
            groups[faction] = {}
        end


        table.insert(
            groups[faction],
            model
        )
    end


    --------------------------------------------------
    -- Sort models inside each faction
    --------------------------------------------------

    for _, models
        in pairs(groups) do

        table.sort(
            models,

            function(a, b)

                local nameA =
                    a.name or a.id

                local nameB =
                    b.name or b.id

                return nameA < nameB
            end
        )
    end


    return groups
end


local function sortedFactionNames(groups)

    local names = {}


    for faction, _
        in pairs(groups) do

        table.insert(
            names,
            faction
        )
    end


    table.sort(names)


    return names
end


--------------------------------------------------
-- Clear current display
--------------------------------------------------

function Armory.clear()

    local count = 0


    for _, object
        in ipairs(getAllObjects()) do

        if object.hasTag(DISPLAY_TAG) then

            destroyObject(object)

            count =
                count + 1
        end
    end


    print(
        "[FOWW] Cleared model display: "
        .. tostring(count)
    )


    return count
end


--------------------------------------------------
-- Build current model display
--------------------------------------------------

function Armory.show(
    pool,
    layout
)

    --------------------------------------------------
    -- Remove previous temporary display
    --------------------------------------------------

    Armory.clear()


    if pool == nil
        or pool.models == nil then

        print(
            "[FOWW] Cannot show models: "
            .. "pool unavailable"
        )

        return 0
    end


    --------------------------------------------------
    -- Layout
    --------------------------------------------------

    layout =
        layout or {}


    local origin =
        getOrigin(layout)


    local xSpacing =
        layout.xSpacing or 2.5


    local zSpacing =
        layout.zSpacing or 5.0


    --------------------------------------------------
    -- Group + sort
    --------------------------------------------------

    local groups =
        groupModelsByFaction(pool)


    local factions =
        sortedFactionNames(groups)


    --------------------------------------------------
    -- Spawn
    --------------------------------------------------

    local spawnedCount = 0


    for factionIndex, faction
        in ipairs(factions) do

        local models =
            groups[faction]


        local z =
            origin.z
            + (
                (factionIndex - 1)
                * zSpacing
            )


        print(
            "[FOWW] Display faction: "
            .. faction
            .. " ("
            .. tostring(#models)
            .. " models)"
        )


        for modelIndex, model
            in ipairs(models) do

            local x =
                origin.x
                + (
                    (modelIndex - 1)
                    * xSpacing
                )


            local object =
                ModelSpawner.spawn(
                    model,

                    {
                        x = x,
                        y = origin.y,
                        z = z
                    }
                )


            if object ~= nil then

                object.addTag(
                    DISPLAY_TAG
                )

                spawnedCount =
                    spawnedCount + 1
            end
        end
    end


    print(
        "[FOWW] Model display ready: "
        .. tostring(spawnedCount)
        .. " models"
    )


    return spawnedCount
end


return Armory