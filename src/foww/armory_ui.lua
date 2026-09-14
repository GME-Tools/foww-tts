local ArmoryUI = {}


local ALL_FACTIONS =
    "All factions"


local filters = {
    search = "",
    faction = ALL_FACTIONS
}

local collapsed = true

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function lower(value)

    return string.lower(
        tostring(value or "")
    )
end


local function modelFaction(model)

    if model.faction == nil
        or model.faction == "" then

        return "unassigned"
    end

    return model.faction
end


local function matchesSearch(
    model,
    search
)

    if search == "" then
        return true
    end


    local needle =
        lower(search)


    local name =
        lower(model.name)

    local id =
        lower(model.id)


    return string.find(
        name,
        needle,
        1,
        true
    ) ~= nil

        or

        string.find(
            id,
            needle,
            1,
            true
        ) ~= nil
end


local function matchesFaction(
    model,
    faction
)

    if faction == ALL_FACTIONS then
        return true
    end


    return modelFaction(model)
        == faction
end


--------------------------------------------------
-- Public filtering
--------------------------------------------------

function ArmoryUI.getFilteredModels(pool)

    local result = {}


    if pool == nil
        or pool.models == nil then

        return result
    end


    for _, model
        in pairs(pool.models) do

        if matchesSearch(
                model,
                filters.search
            )

            and matchesFaction(
                model,
                filters.faction
            ) then

            table.insert(
                result,
                model
            )
        end
    end


    table.sort(
        result,

        function(a, b)

            local factionA =
                modelFaction(a)

            local factionB =
                modelFaction(b)

            if factionA ~= factionB then
                return factionA < factionB
            end


            return
                (a.name or a.id)
                <
                (b.name or b.id)
        end
    )


    return result
end


local function getFactions(pool)

    local seen = {}
    local result = {}


    if pool ~= nil
        and pool.models ~= nil then

        for _, model
            in pairs(pool.models) do

            local faction =
                modelFaction(model)

            if not seen[faction] then

                seen[faction] =
                    true

                table.insert(
                    result,
                    faction
                )
            end
        end
    end


    table.sort(result)


    return result
end


--------------------------------------------------
-- UI construction
--------------------------------------------------

local function buildFactionOptions(pool)

    local children = {}


    local allSelected =
        filters.faction
        == ALL_FACTIONS


    table.insert(
        children,
        {
            tag = "Option",

            attributes = {
                selected =
                    allSelected
                    and "true"
                    or "false"
            },

            value =
                ALL_FACTIONS
        }
    )


    for _, faction
        in ipairs(getFactions(pool)) do

        table.insert(
            children,
            {
                tag = "Option",

                attributes = {
                    selected =
                        filters.faction
                            == faction
                        and "true"
                        or "false"
                },

                value =
                    faction
            }
        )
    end


    return children
end


local function buildModelRow(model)

    local spawnable =
        model.asset ~= nil


    return {
        tag =
            "HorizontalLayout",

        attributes = {
            preferredHeight = 42,
            spacing = 8,
            childForceExpandHeight = "true",
            childForceExpandWidth = "false"
        },

        children = {

            {
                tag = "Text",

                attributes = {
                    preferredWidth = 205,
                    fontSize = 15,
                    color = "#FFFFFF",
                    alignment = "MiddleLeft"
                },

                value =
                    model.name
                    or model.id
            },

            {
                tag = "Text",

                attributes = {
                    preferredWidth = 95,
                    fontSize = 12,
                    color = "#B8B8B8",
                    alignment = "MiddleLeft"
                },

                value =
                    modelFaction(model)
            },

            {
                tag = "Button",

                attributes = {
                    id =
                        "fowwArmorySpawn__"
                        .. model.id,

                    preferredWidth = 78,

                    fontSize = 14,

                    textColor =
                        "#FFFFFF",

                    colors =
                        "#426A42|#527F52|#315331|#555555",

                    interactable =
                        spawnable
                        and "true"
                        or "false",

                    onClick =
                        "fowwArmorySpawnModel"
                },

                value =
                    spawnable
                    and "Spawn"
                    or "No asset"
            }
        }
    }
end


local function countModels(pool)

    local count = 0


    if pool ~= nil
        and pool.models ~= nil then

        for _, _
            in pairs(pool.models) do

            count =
                count + 1
        end
    end


    return count
end


local function countSpawnable(models)

    local count = 0


    for _, model
        in ipairs(models) do

        if model.asset ~= nil then
            count =
                count + 1
        end
    end


    return count
end


local function buildExpandedUI(pool)

    local filtered =
        ArmoryUI.getFilteredModels(
            pool
        )


    local spawnable =
        countSpawnable(
            filtered
        )


    local rows = {}


    for _, model
        in ipairs(filtered) do

        table.insert(
            rows,
            buildModelRow(model)
        )
    end


    if #rows == 0 then

        table.insert(
            rows,
            {
                tag = "HorizontalLayout",

                attributes = {
                    preferredHeight = 34,
                    spacing = 8,

                    childForceExpandHeight =
                        "true",

                    childForceExpandWidth =
                        "false"
                },

                children = {

                    {
                        tag = "Text",

                        attributes = {
                            preferredWidth = 350,
                
                            fontSize = 22,
                            fontStyle = "Bold",

                            color = "#FFFFFF",

                            alignment =
                                "MiddleLeft"
                        },

                        value =
                            "FOWW Armory"
                    },

                    {
                        tag = "Button",

                        attributes = {
                            id =
                                "fowwArmoryCollapse",

                            preferredWidth = 42,

                            fontSize = 20,

                            textColor =
                                "#FFFFFF",

                            colors =
                                "#454545|#5A5A5A|#303030|#252525",

                            onClick =
                                "fowwArmoryToggleCollapsed"
                        },

                        value = "-"
                    }
                }
            },
        )
    end


    --------------------------------------------------
    -- Scroll content needs an explicit preferred size.
    --------------------------------------------------

    local contentHeight =
        math.max(
            44,
            #rows * 44
        )


    return {
        {
            tag = "Panel",

            attributes = {
                id =
                    "fowwArmoryPanel",

                width = 430,
                height = 590,

                rectAlignment =
                    "UpperRight",

                offsetXY =
                    "-20 -20",

                color =
                    "#202020EE"
            },

            children = {

                {
                    tag =
                        "VerticalLayout",

                    attributes = {
                        padding =
                            "14 14 12 12",

                        spacing = 9,

                        childForceExpandWidth =
                            "true",

                        childForceExpandHeight =
                            "false"
                    },

                    children = {

                        ----------------------------------
                        -- Title
                        ----------------------------------

                        {
                            tag = "Text",

                            attributes = {
                                preferredHeight = 30,
                                fontSize = 22,
                                fontStyle = "Bold",
                                color = "#FFFFFF",
                                alignment = "MiddleCenter"
                            },

                            value =
                                "FOWW Armory"
                        },


                        ----------------------------------
                        -- Status
                        ----------------------------------

                        {
                            tag = "Text",

                            attributes = {
                                preferredHeight = 22,
                                fontSize = 13,
                                color = "#B8B8B8",
                                alignment = "MiddleCenter"
                            },

                            value =
                                tostring(
                                    countModels(pool)
                                )
                                .. " unlocked  •  "
                                .. tostring(#filtered)
                                .. " matching  •  "
                                .. tostring(spawnable)
                                .. " spawnable"
                        },


                        ----------------------------------
                        -- Filters
                        ----------------------------------

                        {
                            tag =
                                "HorizontalLayout",

                            attributes = {
                                preferredHeight = 36,
                                spacing = 8,
                                childForceExpandWidth =
                                    "false",
                                childForceExpandHeight =
                                    "true"
                            },

                            children = {

                                {
                                    tag =
                                        "InputField",

                                    attributes = {
                                        id =
                                            "fowwArmorySearch",

                                        preferredWidth =
                                            235,

                                        text =
                                            filters.search,

                                        placeholder =
                                            "Search models...",

                                        fontSize = 14,

                                        textColor =
                                            "#FFFFFF",

                                        colors =
                                            "#353535|#454545|#303030|#222222",

                                        onEndEdit =
                                            "fowwArmorySearchChanged"
                                    }
                                },

                                {
                                    tag =
                                        "Dropdown",

                                    attributes = {
                                        id =
                                            "fowwArmoryFaction",

                                        preferredWidth =
                                            155,

                                        fontSize = 14,

                                        textColor =
                                            "#FFFFFF",

                                        itemTextColor =
                                            "#FFFFFF",

                                        itemBackgroundColors =
                                            "#353535",

                                        dropdownBackgroundColor =
                                            "#252525",

                                        onValueChanged =
                                            "fowwArmoryFactionChanged"
                                    },

                                    children =
                                        buildFactionOptions(
                                            pool
                                        )
                                }
                            }
                        },


                        ----------------------------------
                        -- Model list
                        ----------------------------------

                        {
                            tag =
                                "VerticalScrollView",

                            attributes = {
                                preferredHeight = 390,

                                scrollSensitivity = 25,

                                scrollbarBackgroundColor =
                                    "#252525",

                                scrollbarColors =
                                    "#777777|#999999|#555555|#555555"
                            },

                            children = {

                                {
                                    tag =
                                        "VerticalLayout",

                                    attributes = {
                                        preferredHeight =
                                            contentHeight,

                                        spacing = 2,

                                        childForceExpandWidth =
                                            "true",

                                        childForceExpandHeight =
                                            "false"
                                    },

                                    children =
                                        rows
                                }
                            }
                        },


                        ----------------------------------
                        -- Actions
                        ----------------------------------

                        {
                            tag =
                                "HorizontalLayout",

                            attributes = {
                                preferredHeight = 38,
                                spacing = 8,
                                childForceExpandHeight =
                                    "true",
                                childForceExpandWidth =
                                    "true"
                            },

                            children = {

                                {
                                    tag =
                                        "Button",

                                    attributes = {
                                        id =
                                            "fowwArmorySpawnFiltered",

                                        fontSize = 15,

                                        textColor =
                                            "#FFFFFF",

                                        colors =
                                            "#426A42|#527F52|#315331|#555555",

                                        interactable =
                                            spawnable > 0
                                            and "true"
                                            or "false",

                                        onClick =
                                            "fowwArmorySpawnFiltered"
                                    },

                                    value =
                                        "Spawn filtered"
                                },

                                {
                                    tag =
                                        "Button",

                                    attributes = {
                                        id =
                                            "fowwArmoryResetFilters",

                                        fontSize = 15,

                                        textColor =
                                            "#FFFFFF",

                                        colors =
                                            "#555555|#666666|#444444|#333333",

                                        onClick =
                                            "fowwArmoryResetFilters"
                                    },

                                    value =
                                        "Reset filters"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
end

local function buildCollapsedUI()

    return {
        {
            tag = "Panel",

            attributes = {
                id =
                    "fowwArmoryCollapsedPanel",

                width = 190,
                height = 44,

                rectAlignment =
                    "UpperRight",

                offsetXY =
                    "-20 -20",

                color =
                    "#202020EE"
            },

            children = {

                {
                    tag = "Button",

                    attributes = {
                        id =
                            "fowwArmoryExpand",

                        width = 174,
                        height = 32,

                        rectAlignment =
                            "MiddleCenter",

                        fontSize = 17,

                        textColor =
                            "#FFFFFF",

                        colors =
                            "#353535|#4A4A4A|#2A2A2A|#252525",

                        onClick =
                            "fowwArmoryToggleCollapsed"
                    },

                    value =
                        "FOWW Armory  >"
                }
            }
        }
    }
end


local function buildUI(pool)

    if collapsed then
        return buildCollapsedUI()
    end

    return buildExpandedUI(pool)
end

--------------------------------------------------
-- Public UI API
--------------------------------------------------

function ArmoryUI.mount(pool)

    UI.setXmlTable(
        buildUI(pool)
    )

    print(
        "[FOWW] Armory UI mounted"
    )
end


function ArmoryUI.refresh(pool)

    ArmoryUI.mount(pool)
end


function ArmoryUI.setSearch(
    value,
    pool
)

    filters.search =
        value or ""

    ArmoryUI.refresh(pool)
end


function ArmoryUI.setFaction(
    value,
    pool
)

    filters.faction =
        value
        or ALL_FACTIONS

    ArmoryUI.refresh(pool)
end


function ArmoryUI.resetFilters(pool)

    filters.search =
        ""

    filters.faction =
        ALL_FACTIONS

    ArmoryUI.refresh(pool)
end

function ArmoryUI.toggleCollapsed(
    pool
)

    collapsed =
        not collapsed

    ArmoryUI.refresh(
        pool
    )
end


return ArmoryUI