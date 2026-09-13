local App = require("foww.app")


function onLoad(saved_data)
    App.onLoad(saved_data)
end


function onSave()
    return App.onSave()
end


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


function fowwSpawnModel(modelId)

    return App.spawnModel(
        modelId,
        {x = 0, y = 3, z = 8}
    )
end


function fowwShowAvailableModels()

    return App.showAvailableModels()
end


function fowwClearModelDisplay()

    return App.clearModelDisplay()
end


--------------------------------------------------
-- Debug UI callbacks
--------------------------------------------------

function fowwDebugShowModels(
    player,
    value,
    id
)

    App.showAvailableModels()
end


function fowwDebugClearModels(
    player,
    value,
    id
)

    App.clearModelDisplay()
end


function fowwDebugRebuildPool(
    player,
    value,
    id
)

    App.rebuildPool()
end