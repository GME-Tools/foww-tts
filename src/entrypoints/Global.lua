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