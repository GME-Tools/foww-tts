local App = {}

function App.onLoad(saved_data)
    print("[FOWW] App loaded from src/foww/app.lua")
end

function App.onSave()
    return ""
end

return App