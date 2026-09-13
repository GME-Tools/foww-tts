local DebugUI = {}

local XML = [[
<Panel
    id="fowwDebugPanel"
    width="280"
    height="200"
    rectAlignment="UpperRight"
    offsetXY="-20 -20"
    color="#202020E8"
>
    <VerticalLayout
        padding="12 12 10 10"
        spacing="8"
        childAlignment="UpperCenter"
        childForceExpandWidth="true"
        childForceExpandHeight="false"
    >
        <Text
            preferredHeight="30"
            fontSize="20"
            fontStyle="Bold"
            color="#FFFFFF"
            alignment="MiddleCenter"
        >
            FOWW Debug
        </Text>

        <Button
            id="fowwDebugShowModels"
            preferredHeight="38"
            fontSize="16"
            color="#454545|#5A5A5A|#303030|#252525"
            textColor="#FFFFFF"
            onClick="fowwDebugShowModels"
        >
            Show available models
        </Button>

        <Button
            id="fowwDebugClearModels"
            preferredHeight="38"
            fontSize="16"
            color="#454545|#5A5A5A|#303030|#252525"
            textColor="#FFFFFF"
            onClick="fowwDebugClearModels"
        >
            Clear models
        </Button>

        <Button
            id="fowwDebugRebuildPool"
            preferredHeight="38"
            fontSize="16"
            color="#454545|#5A5A5A|#303030|#252525"
            textColor="#FFFFFF"
            onClick="fowwDebugRebuildPool"
        >
            Rebuild pool
        </Button>
    </VerticalLayout>
</Panel>
]]


function DebugUI.mount()

    UI.setXml(XML)

    print("[FOWW] Debug UI mounted")
end


return DebugUI