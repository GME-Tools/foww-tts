local App =
    require("foww.app")


--------------------------------------------------
-- Lifecycle
--------------------------------------------------

function onLoad(saved_data)

    App.onLoad(
        saved_data
    )
end


function onSave()

    return App.onSave()
end


--------------------------------------------------
-- Products
--------------------------------------------------

function fowwOpenProduct(
    object,
    player_color,
    alt_click
)

    App.setProductState(
        object,
        player_color,
        true
    )
end


function fowwSetProductState(
    object,
    player_color,
    opened
)

    App.setProductState(
        object,
        player_color,
        opened
    )
end


--------------------------------------------------
-- Armory UI : filters
--------------------------------------------------

function fowwArmorySearchChanged(
    player,
    value,
    id
)

    App.setArmorySearch(
        value
    )
end


function fowwArmoryFactionChanged(
    player,
    value,
    id
)

    App.setArmoryFaction(
        value
    )
end


function fowwArmoryResetFilters(
    player,
    value,
    id
)

    App.resetArmoryFilters()
end


--------------------------------------------------
-- Armory UI : spawn one
--------------------------------------------------

function fowwArmorySpawnModel(
    player,
    value,
    id
)

    local prefix =
        "fowwArmorySpawn__"


    if id == nil then
        return
    end


    if string.sub(
        id,
        1,
        #prefix
    ) ~= prefix then

        return
    end


    local modelId =
        string.sub(
            id,
            #prefix + 1
        )


    App.spawnArmoryModel(
        modelId,
        player.color
    )
end


--------------------------------------------------
-- Armory UI : spawn filtered
--------------------------------------------------

function fowwArmorySpawnFiltered(
    player,
    value,
    id
)

    App.spawnArmoryFiltered(
        player.color
    )
end


--------------------------------------------------
-- Armory UI : collapse
--------------------------------------------------

function fowwArmoryToggleCollapsed(
    player,
    value,
    id
)

    App.toggleArmoryCollapsed()
end


--------------------------------------------------
-- Cards UI
--------------------------------------------------

function fowwSpawnAvailableCards(
    player,
    value,
    id
)

    App.spawnAvailableCards(
        player.color
    )
end