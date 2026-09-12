local App = require("foww.app")

function onLoad(saved_data)
    App.onLoad(saved_data)
end

function onSave()
    return App.onSave()
end