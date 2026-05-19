#Requires AutoHotkey v2.0

CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ========================================
; GUI
; ========================================

myGui := Gui(, "Minecraft AutoSeller")

; ========================================
; GLOBALS
; ========================================

global running := false
global itemsSold := 0
global runtimeSeconds := 0

global inventorySlotData := []
global inventorySlotControls := []

global craftingControls := []
global materialControls := []

global currentPickX := ""
global currentPickY := ""
global isPicking := false

global inventoryStartY := 120
global inventorySpacing := 38

global emptySlotColor := 0x828282
global colorTolerance := 25

global sellCommand := "/ah sell 80k"

global minActionDelay := 2600
global maxActionDelay := 4200
global randomOffset := 6

global craftOutputAmount := 6
global craftStackSize := 64

; ========================================
; DEFAULT INVENTORY SLOTS
; ========================================

inventorySlotData.Push({x: 0, y: 0})
inventorySlotData.Push({x: 0, y: 0})

; ========================================
; PAGE HEADER
; ========================================

AddPageHeader(gui, text) {
    gui.SetFont("s13 Bold", "Segoe UI")
    gui.AddText("x20 y30 w570 h25 Center c3399FF", text)
    gui.SetFont("s9", "Segoe UI")
}

; ========================================
; TABS
; ========================================

tabs := myGui.AddTab3(
    "x10 y10 w610 h500",
    ["Main", "Inventory", "Crafting", "Materials", "Settings"]
)

; ========================================
; MAIN TAB
; ========================================

tabs.UseTab("Main")

AddPageHeader(myGui, "Macro Controls")

mainGroup := myGui.AddGroupBox("x20 y60 w570 h240", "")

startBtn := myGui.AddButton("x50 y105 w140 h40", "Start Macro")
stopBtn  := myGui.AddButton("x230 y105 w140 h40", "Stop Macro")
saveBtn  := myGui.AddButton("x410 y105 w140 h40", "Save Settings")

statusText := myGui.AddText("x50 y195 w250 h25", "Status: Idle")
modeText := myGui.AddText("x50 y225 w250 h25", "Mode: Waiting")

itemsText := myGui.AddText("x340 y195 w220 h25", "Items Sold: 0")
runtimeText := myGui.AddText("x340 y225 w220 h25", "Runtime: 00:00:00")

startBtn.OnEvent("Click", StartMacro)
stopBtn.OnEvent("Click", StopMacro)
saveBtn.OnEvent("Click", SaveSettings)

; ========================================
; INVENTORY TAB
; ========================================

tabs.UseTab("Inventory")

AddPageHeader(myGui, "Inventory Slots")

inventoryGroup := myGui.AddGroupBox("x20 y60 w570 h360", "")

; Sell slot

myGui.AddText("x40 y85 w100 h25", "Sell Slot")

global sellSlotXEdit := myGui.AddEdit("x110 y82 w70", "0")
global sellSlotYEdit := myGui.AddEdit("x200 y82 w70", "0")

sellSlotPickBtn := myGui.AddButton("x290 y82 w60 h24", "Pick")
sellSlotTestBtn := myGui.AddButton("x370 y82 w60 h24", "Test")

sellSlotPickBtn.OnEvent(
    "Click",
    BeginCoordinatePick.Bind(sellSlotXEdit, sellSlotYEdit)
)

sellSlotTestBtn.OnEvent(
    "Click",
    TestCoordinates.Bind(sellSlotXEdit, sellSlotYEdit)
)

; Confirm slot

myGui.AddText("x40 y390 w90", "Confirm")

global confirmXEdit := myGui.AddEdit("x110 y388 w70", "1104")
global confirmYEdit := myGui.AddEdit("x200 y388 w70", "375")

confirmPickBtn := myGui.AddButton("x290 y388 w60 h24", "Pick")
confirmTestBtn := myGui.AddButton("x370 y388 w60 h24", "Test")

confirmPickBtn.OnEvent(
    "Click",
    BeginCoordinatePick.Bind(confirmXEdit, confirmYEdit)
)

confirmTestBtn.OnEvent(
    "Click",
    TestCoordinates.Bind(confirmXEdit, confirmYEdit)
)

; Slot buttons

addSlotBtn := myGui.AddButton("x110 y435 w150 h35", "+ Add Slot")
removeSlotBtn := myGui.AddButton("x330 y435 w150 h35", "- Remove Slot")

addSlotBtn.OnEvent("Click", AddInventorySlot)
removeSlotBtn.OnEvent("Click", RemoveInventorySlot)

; ========================================
; CRAFTING TAB
; ========================================

tabs.UseTab("Crafting")

AddPageHeader(myGui, "Crafting Grid")

myGui.AddText(
    "x40 y51 w500 h18 cGray",
    "* Set unused crafting slots to 0, 0"
)

craftingGroup := myGui.AddGroupBox("x20 y60 w570 h410", "")

craftingData := [
    ["Top Left", 762, 294],
    ["Top Middle", 830, 294],
    ["Top Right", 907, 293],
    ["Middle Left", 756, 364],
    ["Center", 833, 363],
    ["Middle Right", 903, 362],
    ["Bottom Left", 756, 437],
    ["Bottom Middle", 829, 438],
    ["Bottom Right", 907, 435],
    ["Output Slot", 1139, 365]
]

Loop craftingData.Length {

    slot := craftingData[A_Index]

    yPos := 90 + ((A_Index - 1) * 33)

    label := myGui.AddText("x40 y" yPos " w90", slot[1])

    xEdit := myGui.AddEdit(
        "x140 y" (yPos - 2) " w70",
        slot[2]
    )

    yEdit := myGui.AddEdit(
        "x225 y" (yPos - 2) " w70",
        slot[3]
    )

    pickBtn := myGui.AddButton(
        "x320 y" (yPos - 2) " w55 h23",
        "Pick"
    )

    testBtn := myGui.AddButton(
        "x390 y" (yPos - 2) " w55 h23",
        "Test"
    )

    pickBtn.OnEvent(
        "Click",
        BeginCoordinatePick.Bind(xEdit, yEdit)
    )

    testBtn.OnEvent(
        "Click",
        TestCoordinates.Bind(xEdit, yEdit)
    )

    craftingControls.Push({
        label: label,
        xEdit: xEdit,
        yEdit: yEdit,
        pickBtn: pickBtn,
        testBtn: testBtn
    })
}

; ========================================
; MATERIALS TAB
; ========================================

tabs.UseTab("Materials")

AddPageHeader(myGui, "Material Slots")

myGui.AddText(
    "x40 y51 w520 h18 cGray",
    "* Put material slots to 0, 0 if recipe slot is unused"
)

materialGroup := myGui.AddGroupBox("x20 y60 w570 h410", "")

materialData := [

    ; Put 0,0 for unused recipe slots

    ["Top Left", 886, 629],
    ["Top Middle", 957, 633],
    ["Top Right", 1035, 633],

    ["Middle Left", 885, 705],
    ["Center", 961, 705],
    ["Middle Right", 1029, 707],

    ["Bottom Left", 1103, 634],
    ["Bottom Middle", 1180, 624],
    ["Bottom Right", 1245, 633]
]

Loop materialData.Length {

    slot := materialData[A_Index]

    yPos := 90 + ((A_Index - 1) * 33)

    label := myGui.AddText("x40 y" yPos " w90", slot[1])

    xEdit := myGui.AddEdit(
        "x140 y" (yPos - 2) " w70",
        slot[2]
    )

    yEdit := myGui.AddEdit(
        "x225 y" (yPos - 2) " w70",
        slot[3]
    )

    pickBtn := myGui.AddButton(
        "x320 y" (yPos - 2) " w55 h23",
        "Pick"
    )

    testBtn := myGui.AddButton(
        "x390 y" (yPos - 2) " w55 h23",
        "Test"
    )

    pickBtn.OnEvent(
        "Click",
        BeginCoordinatePick.Bind(xEdit, yEdit)
    )

    testBtn.OnEvent(
        "Click",
        TestCoordinates.Bind(xEdit, yEdit)
    )

    materialControls.Push({
        label: label,
        xEdit: xEdit,
        yEdit: yEdit,
        pickBtn: pickBtn,
        testBtn: testBtn
    })
}

; ========================================
; SETTINGS TAB
; ========================================

tabs.UseTab("Settings")

AddPageHeader(myGui, "Automation Settings")

settingsGroup := myGui.AddGroupBox("x20 y60 w570 h260", "")

myGui.AddText("x50 y105 w120 h25", "Sell Command")

global sellCommandEdit := myGui.AddEdit(
    "x180 y102 w250 h25",
    sellCommand
)

myGui.AddText("x50 y145 w140 h25", "Items Per Craft")

global outputAmountEdit := myGui.AddEdit(
    "x180 y142 w80 h25",
    craftOutputAmount
)

myGui.AddText("x300 y145 w120 h25", "Stack Size")

global stackSizeEdit := myGui.AddEdit(
    "x410 y142 w80 h25",
    craftStackSize
)

global craftingToggle := myGui.AddCheckbox(
    "x50 y190 w240 h30",
    "Enable Auto Crafting"
)

global humanMouseToggle := myGui.AddCheckbox(
    "x50 y240 w240 h30",
    "Enable Human Mouse"
)

global randomDelayToggle := myGui.AddCheckbox(
    "x50 y290 w240 h30",
    "Enable Random Delays"
)

craftingToggle.Value := 1
humanMouseToggle.Value := 1
randomDelayToggle.Value := 1

tabs.UseTab()

; ========================================
; DRAW INVENTORY SLOTS
; ========================================

DrawInventorySlots() {

    global myGui
    global tabs
    global inventorySlotData
    global inventorySlotControls
    global inventoryStartY
    global inventorySpacing

    for ctrl in inventorySlotControls {

        ctrl.label.Visible := false
        ctrl.xEdit.Visible := false
        ctrl.yEdit.Visible := false
        ctrl.pickBtn.Visible := false
        ctrl.testBtn.Visible := false
    }

    inventorySlotControls := []

    tabs.UseTab("Inventory")

    Loop inventorySlotData.Length {

        slot := inventorySlotData[A_Index]

        yPos := inventoryStartY + (
            (A_Index - 1) * inventorySpacing
        )

        label := myGui.AddText(
            "x40 y" (yPos + 15),
            "Slot " A_Index
        )

        xEdit := myGui.AddEdit(
            "x110 y" (yPos + 13) " w70",
            slot.x
        )

        yEdit := myGui.AddEdit(
            "x200 y" (yPos + 13) " w70",
            slot.y
        )

        pickBtn := myGui.AddButton(
            "x290 y" (yPos + 13) " w60 h24",
            "Pick"
        )

        testBtn := myGui.AddButton(
            "x370 y" (yPos + 13) " w60 h24",
            "Test"
        )

        pickBtn.OnEvent(
            "Click",
            BeginCoordinatePick.Bind(xEdit, yEdit)
        )

        testBtn.OnEvent(
            "Click",
            TestCoordinates.Bind(xEdit, yEdit)
        )

        inventorySlotControls.Push({
            label: label,
            xEdit: xEdit,
            yEdit: yEdit,
            pickBtn: pickBtn,
            testBtn: testBtn
        })
    }

    tabs.UseTab()
}

; ========================================
; ADD SLOT
; ========================================

AddInventorySlot(*) {

    global inventorySlotData

    if (inventorySlotData.Length >= 9)
        return

    inventorySlotData.Push({
        x: 0,
        y: 0
    })

    DrawInventorySlots()
}

; ========================================
; REMOVE SLOT
; ========================================

RemoveInventorySlot(*) {

    global inventorySlotData

    if (inventorySlotData.Length <= 1)
        return

    inventorySlotData.Pop()

    DrawInventorySlots()
}

; ========================================
; COORD PICKING
; ========================================

BeginCoordinatePick(xControl, yControl, *) {

    global currentPickX
    global currentPickY
    global isPicking

    currentPickX := xControl
    currentPickY := yControl

    isPicking := true

    ToolTip("Hover slot and press F8")
}

F8:: {

    global currentPickX
    global currentPickY
    global isPicking

    if !isPicking
        return

    MouseGetPos(&mx, &my)

    currentPickX.Text := mx
    currentPickY.Text := my

    isPicking := false

    ToolTip("Coordinates Saved")

    SetTimer(RemoveToolTip, -1000)
}

; ========================================
; TEST COORDS
; ========================================

TestCoordinates(xControl, yControl, *) {

    x := Integer(xControl.Text)
    y := Integer(yControl.Text)

    MouseMove(x, y, 10)

    ToolTip("Testing Coordinates")

    SetTimer(RemoveToolTip, -1000)
}

RemoveToolTip() {
    ToolTip()
}

; ========================================
; GET INVENTORY SLOTS
; ========================================

GetInventorySlots() {

    global inventorySlotControls

    slots := []

    for slotObj in inventorySlotControls {

        if !running
            return

        slots.Push({
            x: Integer(slotObj.xEdit.Text),
            y: Integer(slotObj.yEdit.Text)
        })
    }

    return slots
}

; ========================================
; EMPTY SLOT DETECTION
; ========================================

IsSlotEmpty(x, y) {

    global emptySlotColor
    global colorTolerance

    currentColor := PixelGetColor(x, y, "RGB")

    r1 := (currentColor >> 16) & 0xFF
    g1 := (currentColor >> 8) & 0xFF
    b1 := currentColor & 0xFF

    r2 := (emptySlotColor >> 16) & 0xFF
    g2 := (emptySlotColor >> 8) & 0xFF
    b2 := emptySlotColor & 0xFF

    return (
        Abs(r1 - r2) <= colorTolerance
        && Abs(g1 - g2) <= colorTolerance
        && Abs(b1 - b2) <= colorTolerance
    )
}

; ========================================
; RANDOMIZED CLICK
; ========================================

RandomizedClick(x, y) {

    global randomOffset

    dx := Random(-randomOffset, randomOffset)
    dy := Random(-randomOffset, randomOffset)

    MouseMove(x + dx, y + dy, 10)

    Sleep(Random(60, 120))

    Click(x + dx, y + dy)

    Sleep(Random(80, 140))
}

; ========================================
; START MACRO
; ========================================

StartMacro(*) {

    global running
    global statusText
    global modeText
    global runtimeSeconds

    if running
        return

    running := true

    runtimeSeconds := 0

    statusText.Text := "Status: Running"
    modeText.Text := "Mode: Selling"

    SetTimer(UpdateRuntime, 1000)

    SetTimer(MainLoop, -1)
}

; ========================================
; STOP MACRO
; ========================================

StopMacro(*) {

    global running
    global statusText
    global modeText
    global runtimeText
    global runtimeSeconds

    running := false

    statusText.Text := "Status: Stopped"
    modeText.Text := "Mode: Waiting"

    runtimeSeconds := 0

    runtimeText.Text := "Runtime: 00:00:00"

    SetTimer(UpdateRuntime, 0)
}

; ========================================
; MAIN LOOP
; ========================================

MainLoop(*) {

    global running
    global itemsSold
    global itemsText
    global sellCommandEdit
    global humanMouseToggle
    global randomDelayToggle
    global sellSlotXEdit
    global sellSlotYEdit
    global confirmXEdit
    global confirmYEdit
    global modeText

    if !running
        return

    slots := GetInventorySlots()

    sellX := Integer(sellSlotXEdit.Text)
    sellY := Integer(sellSlotYEdit.Text)

    confirmX := Integer(confirmXEdit.Text)
    confirmY := Integer(confirmYEdit.Text)

    hasItems := false

for slot in slots {

    if !running
        return

    if (slot.x <= 0 || slot.y <= 0)
        continue

    ; Skip empty slots
    ; Move mouse to slot before checking color
    MouseMove(slot.x, slot.y, 0)

    Sleep(100)

    if IsSlotEmpty(slot.x, slot.y)
        Sleep(150)
    if IsSlotEmpty(slot.x, slot.y)
        continue

    hasItems := true

    ; ========================================
    ; KEEP USING CURRENT SLOT UNTIL EMPTY
    ; ========================================

    while running {

    ; Move mouse to slot before checking
    MouseMove(slot.x, slot.y, 0)

    Sleep(500)

    if IsSlotEmpty(slot.x, slot.y)
        sleep(150)
    if isSlotEmpty(slot.x, slot.y)
        break

        if !running
            return

        ; ========================================
        ; PICK ITEM FROM INVENTORY
        ; ========================================

        if humanMouseToggle.Value {

            dx := Random(-randomOffset, randomOffset)
            dy := Random(-randomOffset, randomOffset)

            MouseMove(slot.x + dx, slot.y + dy, 10)
            Sleep(100)

            Click(slot.x + dx, slot.y + dy)

        } else {

            MouseMove(slot.x, slot.y, 10)
            Sleep(100)

            Click(slot.x, slot.y)
        }

        Sleep(200)

        ; ========================================
        ; PLACE INTO SELL SLOT
        ; ========================================

        if humanMouseToggle.Value {

            dx2 := Random(-randomOffset, randomOffset)
            dy2 := Random(-randomOffset, randomOffset)

            MouseMove(sellX + dx2, sellY + dy2, 10)
            Sleep(100)

            Click(sellX + dx2, sellY + dy2)

        } else {

            MouseMove(sellX, sellY, 10)
            Sleep(100)

            Click(sellX, sellY)
        }

        ; ========================================
        ; WAIT
        ; ========================================

        if randomDelayToggle.Value
            Sleep(Random(minActionDelay, maxActionDelay))
        else
            Sleep(minActionDelay)

        ; ========================================
        ; SEND SELL COMMAND
        ; ========================================

        Send("{Esc}")

        Sleep(200)

        Send("/")

        Sleep(120)

        commandText := sellCommandEdit.Text

        if SubStr(commandText, 1, 1) = "/"
            commandText := SubStr(commandText, 2)

        SendText(commandText)

        Sleep(120)

        Send("{Enter}")

        ; ========================================
        ; CLICK CONFIRM
        ; ========================================

        Sleep(500)

        if (confirmX > 0 && confirmY > 0) {

            if humanMouseToggle.Value {

                dx3 := Random(-randomOffset, randomOffset)
                dy3 := Random(-randomOffset, randomOffset)

                MouseMove(confirmX + dx3, confirmY + dy3, 10)
                Sleep(100)

                Click(confirmX + dx3, confirmY + dy3)

            } else {

                MouseMove(confirmX, confirmY, 10)
                Sleep(100)

                Click(confirmX, confirmY)

                Sleep(200)

                Send("e")
            }
        }

        ; ========================================
        ; WAIT FOR SLOT TO UPDATE
        ; ========================================

        Sleep(1200)
    }
}

; ========================================
; ALL SLOTS EMPTY -> CRAFT
; ========================================

if !hasItems {

    ; Only craft if enabled
    if craftingToggle.Value {

        modeText.Text := "Mode: Crafting"

        RunCrafting()

        if !running
            return

        modeText.Text := "Mode: Selling"

        Sleep(1500)

    } else {

        modeText.Text := "Mode: STOPPED - No Items"

        StopMacro()
    }
    }

    if running
        SetTimer(MainLoop, -1)
}

; ========================================
; BUILD CRAFTING OBJECTS
; ========================================

BuildCraftingObjects() {

    global craftingControls
    global materialControls

    craftSlots := {}
    materialSlots := {}

    ; ========================================
    ; CRAFT SLOTS
    ; ========================================

    craftSlots.topLeft := {
        x: Integer(craftingControls[1].xEdit.Text),
        y: Integer(craftingControls[1].yEdit.Text)
    }

    craftSlots.topMiddle := {
        x: Integer(craftingControls[2].xEdit.Text),
        y: Integer(craftingControls[2].yEdit.Text)
    }

    craftSlots.topRight := {
        x: Integer(craftingControls[3].xEdit.Text),
        y: Integer(craftingControls[3].yEdit.Text)
    }

    craftSlots.middleLeft := {
        x: Integer(craftingControls[4].xEdit.Text),
        y: Integer(craftingControls[4].yEdit.Text)
    }

    craftSlots.center := {
        x: Integer(craftingControls[5].xEdit.Text),
        y: Integer(craftingControls[5].yEdit.Text)
    }

    craftSlots.middleRight := {
        x: Integer(craftingControls[6].xEdit.Text),
        y: Integer(craftingControls[6].yEdit.Text)
    }

    craftSlots.bottomLeft := {
        x: Integer(craftingControls[7].xEdit.Text),
        y: Integer(craftingControls[7].yEdit.Text)
    }

    craftSlots.bottomMiddle := {
        x: Integer(craftingControls[8].xEdit.Text),
        y: Integer(craftingControls[8].yEdit.Text)
    }

    craftSlots.bottomRight := {
        x: Integer(craftingControls[9].xEdit.Text),
        y: Integer(craftingControls[9].yEdit.Text)
    }

    craftSlots.output := {
        x: Integer(craftingControls[10].xEdit.Text),
        y: Integer(craftingControls[10].yEdit.Text)
    }

    ; ========================================
    ; MATERIAL SLOTS
    ; ========================================

    materialSlots.topLeft := {
    x: Integer(materialControls[1].xEdit.Text),
    y: Integer(materialControls[1].yEdit.Text)
}

materialSlots.topMiddle := {
    x: Integer(materialControls[2].xEdit.Text),
    y: Integer(materialControls[2].yEdit.Text)
}

materialSlots.topRight := {
    x: Integer(materialControls[3].xEdit.Text),
    y: Integer(materialControls[3].yEdit.Text)
}

materialSlots.middleLeft := {
    x: Integer(materialControls[4].xEdit.Text),
    y: Integer(materialControls[4].yEdit.Text)
}

materialSlots.center := {
    x: Integer(materialControls[5].xEdit.Text),
    y: Integer(materialControls[5].yEdit.Text)
}

materialSlots.middleRight := {
    x: Integer(materialControls[6].xEdit.Text),
    y: Integer(materialControls[6].yEdit.Text)
}

materialSlots.bottomLeft := {
    x: Integer(materialControls[7].xEdit.Text),
    y: Integer(materialControls[7].yEdit.Text)
}

materialSlots.bottomMiddle := {
    x: Integer(materialControls[8].xEdit.Text),
    y: Integer(materialControls[8].yEdit.Text)
}

materialSlots.bottomRight := {
    x: Integer(materialControls[9].xEdit.Text),
    y: Integer(materialControls[9].yEdit.Text)
}

    return {
        craftSlots: craftSlots,
        materialSlots: materialSlots
    }
}

; ========================================
; FILL CRAFT SLOT
; ========================================

FillCraftSlot(materialSlot, craftSlot) {

    RandomizedClick(materialSlot.x, materialSlot.y)

    Sleep(Random(80, 140))

    RandomizedClick(craftSlot.x, craftSlot.y)

    Sleep(Random(80, 140))
}

; ========================================
; WAIT UPDATE
; ========================================

WaitForInventoryUpdate() {
    Sleep(Random(180, 320))
}

; ========================================
; CURSOR EMPTY
; ========================================

EnsureCursorEmpty() {
}

; ========================================
; CHECK IF MATERIAL SLOT IS EMPTY
; ========================================

AreCraftMaterialsMissing(materialSlots) {

    slots := [
        materialSlots.topLeft,
        materialSlots.topMiddle,
        materialSlots.topRight,

        materialSlots.middleLeft,
        materialSlots.center,
        materialSlots.middleRight,

        materialSlots.bottomLeft,
        materialSlots.bottomMiddle,
        materialSlots.bottomRight
    ]

    for slot in slots {

        ; Ignore empty coordinate slots
        if (slot.x <= 0 || slot.y <= 0)
            continue

        MouseMove(slot.x, slot.y, 0)

        Sleep(80)

        ; Double-check to reduce false positives
        if IsSlotEmpty(slot.x, slot.y) {

            Sleep(150)

            if IsSlotEmpty(slot.x, slot.y)
                return true
        }
    }

    return false
}

; ========================================
; RUN CRAFTING
; ========================================

RunCrafting() {

    global outputAmountEdit
    global stackSizeEdit
    global inventorySlotControls
    global modeText

    data := BuildCraftingObjects()

    craftSlots := data.craftSlots
    materialSlots := data.materialSlots

    ; Stop if materials are missing
    if AreCraftMaterialsMissing(materialSlots) {

    modeText.Text := "Mode: OUT OF MATERIALS"

    Sleep(300)

    StopMacro()

    return
}

    outputAmount := Integer(outputAmountEdit.Text)
    stackSize := Integer(stackSizeEdit.Text)

    ; Prevent divide by zero
    if (outputAmount <= 0)
        outputAmount := 1

    craftsPerSlot := Floor(stackSize / outputAmount)

    ; Minimum of 1
    if (craftsPerSlot < 1)
        craftsPerSlot := 1

    Send("e")

    Sleep(Random(120, 220))

    ; Open crafting table
    Click "Right"

    Sleep(500)

    ; ========================================
    ; LOOP THROUGH INVENTORY SLOTS
    ; ========================================

    for slotObj in inventorySlotControls {

        slotX := Integer(slotObj.xEdit.Text)
        slotY := Integer(slotObj.yEdit.Text)

        if (slotX <= 0 || slotY <= 0)
            continue

        ; ========================================
        ; CRAFT INTO THIS SLOT
        ; ========================================

        Loop craftsPerSlot {

            if !running
                return

            ; Fill recipe

            FillCraftSlot(materialSlots.topLeft, craftSlots.topLeft)
            FillCraftSlot(materialSlots.topMiddle, craftSlots.topMiddle)
            FillCraftSlot(materialSlots.topRight, craftSlots.topRight)

            FillCraftSlot(materialSlots.middleLeft, craftSlots.middleLeft)
            FillCraftSlot(materialSlots.center, craftSlots.center)
            FillCraftSlot(materialSlots.middleRight, craftSlots.middleRight)

            FillCraftSlot(materialSlots.bottomLeft, craftSlots.bottomLeft)
            FillCraftSlot(materialSlots.bottomMiddle, craftSlots.bottomMiddle)
            FillCraftSlot(materialSlots.bottomRight, craftSlots.bottomRight)

            Sleep(200)

            ; Take crafted item
            RandomizedClick(
                craftSlots.output.x,
                craftSlots.output.y
            )

            Sleep(150)

            ; Place into inventory slot
            RandomizedClick(slotX, slotY)

            Sleep(250)
        }
    }

    Send("{Esc}")

    Sleep(Random(120, 220))
}

; ========================================
; UPDATE RUNTIME
; ========================================

UpdateRuntime(*) {

    global runtimeSeconds
    global runtimeText

    runtimeSeconds += 1

    hours := runtimeSeconds // 3600
    minutes := Mod(runtimeSeconds // 60, 60)
    seconds := Mod(runtimeSeconds, 60)

    timeStr := Format(
        "{:02}:{:02}:{:02}",
        hours,
        minutes,
        seconds
    )

    runtimeText.Text := "Runtime: " timeStr
}

; ========================================
; SAVE SETTINGS
; ========================================

SaveSettings(*) {

    global inventorySlotControls
    global craftingControls
    global materialControls
    global craftingToggle
    global humanMouseToggle
    global randomDelayToggle
    global sellCommandEdit
    global itemsSold
    global emptySlotColor
    global colorTolerance

    iniFile := A_ScriptDir "\settings.ini"

    IniWrite(
    outputAmountEdit.Text,
    iniFile,
    "Crafting",
    "OutputAmount"
)

IniWrite(
    stackSizeEdit.Text,
    iniFile,
    "Crafting",
    "StackSize"
)

    ; Inventory

    for index, slot in inventorySlotControls {

        IniWrite(
            slot.xEdit.Text,
            iniFile,
            "Inventory",
            "Slot" index "X"
        )

        IniWrite(
            slot.yEdit.Text,
            iniFile,
            "Inventory",
            "Slot" index "Y"
        )
    }

    IniWrite(
        inventorySlotControls.Length,
        iniFile,
        "Inventory",
        "Count"
    )

    ; Crafting

    for index, slot in craftingControls {

        IniWrite(
            slot.xEdit.Text,
            iniFile,
            "Crafting",
            "Slot" index "X"
        )

        IniWrite(
            slot.yEdit.Text,
            iniFile,
            "Crafting",
            "Slot" index "Y"
        )
    }

    ; Materials

    for index, slot in materialControls {

        IniWrite(
            slot.xEdit.Text,
            iniFile,
            "Materials",
            "Slot" index "X"
        )

        IniWrite(
            slot.yEdit.Text,
            iniFile,
            "Materials",
            "Slot" index "Y"
        )
    }

    ; Settings

    IniWrite(
        craftingToggle.Value,
        iniFile,
        "Settings",
        "AutoCraft"
    )

    IniWrite(
        humanMouseToggle.Value,
        iniFile,
        "Settings",
        "HumanMouse"
    )

    IniWrite(
        randomDelayToggle.Value,
        iniFile,
        "Settings",
        "RandomDelay"
    )

    IniWrite(
        sellCommandEdit.Text,
        iniFile,
        "Settings",
        "SellCommand"
    )

    ; Detection

    IniWrite(
        emptySlotColor,
        iniFile,
        "Detection",
        "EmptySlotColor"
    )

    IniWrite(
        colorTolerance,
        iniFile,
        "Detection",
        "Tolerance"
    )

    ; Stats

    IniWrite(
        itemsSold,
        iniFile,
        "Stats",
        "ItemsSold"
    )

    ; Sell slot

IniWrite(
    sellSlotXEdit.Text,
    iniFile,
    "Settings",
    "SellSlotX"
)

IniWrite(
    sellSlotYEdit.Text,
    iniFile,
    "Settings",
    "SellSlotY"
)

; Confirm slot

IniWrite(
    confirmXEdit.Text,
    iniFile,
    "Settings",
    "ConfirmX"
)

IniWrite(
    confirmYEdit.Text,
    iniFile,
    "Settings",
    "ConfirmY"
)

    MsgBox("Settings Saved")
}

; ========================================
; LOAD SETTINGS
; ========================================

LoadSettings() {

    global inventorySlotData
    global craftingControls
    global materialControls
    global craftingToggle
    global humanMouseToggle
    global randomDelayToggle
    global sellCommandEdit
    global itemsSold
    global itemsText
    global emptySlotColor
    global colorTolerance
    global stackSizeEdit

    iniFile := A_ScriptDir "\settings.ini"

    outputAmountEdit.Text := IniRead(
    iniFile,
    "Crafting",
    "OutputAmount",
    craftOutputAmount
)

stackSizeEdit.Text := IniRead(
    iniFile,
    "Crafting",
    "StackSize",
    craftStackSize
)

    ; Inventory

    count := IniRead(
        iniFile,
        "Inventory",
        "Count",
        inventorySlotData.Length
    )

    inventorySlotData := []

    if (count > 0) {

        Loop count {

            x := IniRead(
                iniFile,
                "Inventory",
                "Slot" A_Index "X",
                0
            )

            y := IniRead(
                iniFile,
                "Inventory",
                "Slot" A_Index "Y",
                0
            )

            inventorySlotData.Push({
                x: x,
                y: y
            })
        }
    }

    if (inventorySlotData.Length = 0) {

        inventorySlotData.Push({x: 0, y: 0})
        inventorySlotData.Push({x: 0, y: 0})
    }

    DrawInventorySlots()

    ; Crafting

    for index, slot in craftingControls {

        slot.xEdit.Text := IniRead(
            iniFile,
            "Crafting",
            "Slot" index "X",
            slot.xEdit.Text
        )

        slot.yEdit.Text := IniRead(
            iniFile,
            "Crafting",
            "Slot" index "Y",
            slot.yEdit.Text
        )
    }

    ; Materials

    for index, slot in materialControls {

        slot.xEdit.Text := IniRead(
            iniFile,
            "Materials",
            "Slot" index "X",
            slot.xEdit.Text
        )

        slot.yEdit.Text := IniRead(
            iniFile,
            "Materials",
            "Slot" index "Y",
            slot.yEdit.Text
        )
    }

    ; Toggles

    craftingToggle.Value := IniRead(
        iniFile,
        "Settings",
        "AutoCraft",
        1
    )

    humanMouseToggle.Value := IniRead(
        iniFile,
        "Settings",
        "HumanMouse",
        1
    )

    randomDelayToggle.Value := IniRead(
        iniFile,
        "Settings",
        "RandomDelay",
        1
    )

    sellCommandEdit.Text := IniRead(
        iniFile,
        "Settings",
        "SellCommand",
        sellCommandEdit.Text
    )

    ; Sell slot

sellSlotXEdit.Text := IniRead(
    iniFile,
    "Settings",
    "SellSlotX",
    sellSlotXEdit.Text
)

sellSlotYEdit.Text := IniRead(
    iniFile,
    "Settings",
    "SellSlotY",
    sellSlotYEdit.Text
)

; Confirm slot

confirmXEdit.Text := IniRead(
    iniFile,
    "Settings",
    "ConfirmX",
    confirmXEdit.Text
)

confirmYEdit.Text := IniRead(
    iniFile,
    "Settings",
    "ConfirmY",
    confirmYEdit.Text
)

    ; Detection

    emptySlotColor := IniRead(
        iniFile,
        "Detection",
        "EmptySlotColor",
        emptySlotColor
    )

    colorTolerance := Integer(
        IniRead(
            iniFile,
            "Detection",
            "Tolerance",
            colorTolerance
        )
    )

    ; Stats

    itemsSold := IniRead(
        iniFile,
        "Stats",
        "ItemsSold",
        0
    )

    itemsText.Text := "Items Sold: " itemsSold
}

; ========================================
; HOTKEYS
; ========================================

F6::StartMacro()

F7:: {

    global running
    global modeText
    global statusText

    ; HARD STOP
    running := false

    ; kill timers immediately
    SetTimer(MainLoop, 0)
    SetTimer(UpdateRuntime, 0)

    ; update UI
    statusText.Text := "Status: Force Stopped"
    modeText.Text := "Mode: STOPPED"

    ToolTip("MACRO FORCE STOPPED")

    SetTimer(RemoveToolTip, -1000)
}

; ========================================
; INIT
; ========================================

DrawInventorySlots()

LoadSettings()

myGui.Show("w630 h520")