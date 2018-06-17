RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/input.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/rendevous.ks").
RUNONCEPATH("0:/docking.ks").
RUNONCEPATH("0:/ssto.ks").

//TODO: Should these be global?  Doesn't really make sense to have more than 1 mission widget per CPU..this is probably ok.
SET MISSION_TASK_LIST TO list().
SET MISSION_SOI TO SHIP:BODY.

function openMissionControl {
    SET isLaunchClicked TO FALSE.

    LOCAL gui IS GUI(800,800).

    addMissionTabs(gui).

    LOCAL launchButton IS gui:ADDBUTTON("Launch Mission").

    gui:SHOW().

    SET launchButton:ONCLICK to launchClickChecker@.
    wait until isLaunchClicked.
    gui:HIDE().

    executeMission().

    PRINT "Mission Completed Successfully.".
}

//TODO: Generic way to create a click button checker.
function launchClickChecker {
    SET isLaunchClicked TO TRUE.
}

function addMissionTabs {
    parameter gui.

    LOCAL columns IS gui:ADDHLAYOUT().

    LOCAL overviewTab IS columns:ADDVBOX().
    SET overviewTab:STYLE:WIDTH TO 400.
    SET overviewTab:STYLE:HEIGHT TO 400.

    LOCAL addTaskTab IS columns:ADDVBOX().
    SET addTaskTab:STYLE:WIDTH to 400.
    SET addTaskTab:STYLE:HEIGHT to 400.

    //Option 1: Show both overview & Tasks side by side
    addMissionTaskButtons(overviewTab, addTaskTab).
    refreshActiveTasks(overviewTab).
//    addMissionTaskButtons(overviewTab, addTaskTab).

    //Option 2: Tabs, showing overview or tasks only.
//    Local missionTabs IS addTabWidget(gui).
//    Local overviewTab IS addTab(missionTabs, "Mission Overview").
//    Local addTaskTab IS addTab(missionTabs, "Add Task").
//    addTaskTab:addLabel("Add Task").

//    return missionTabs.
}

function refreshActiveTasks {
    parameter overviewTab.

    overviewTab:CLEAR().
    LOCAL label IS overviewTab:ADDLABEL("Mission Overview").
    SET label:STYLE:ALIGN TO "CENTER".

//    overviewTab:AddLabel("Mission Overview").

    Local layout IS overviewTab:addVLayout().
    Local missionBox IS layout:ADDSCROLLBOX().

    Local taskIterator IS MISSION_TASK_LIST:COPY:ITERATOR.

    UNTIL NOT taskIterator:NEXT {
        LOCAL taskBox IS missionBox:AddHBox().

        //Remove Button
        LOCAL removeButton IS taskBox:ADDBUTTON("X").

        LOCAL index IS taskIterator:INDEX.

        SET removeButton:STYLE:WIDTH TO 20.
        SET removeButton:STYLE:MARGIN:RIGHT TO 5.
        SET removeButton:ONCLICK TO {removeMissionTask(overviewTab, index).}.

        //Mission Label
        Local missionlabel IS getTaskName(taskIterator:VALUE).

        taskBox:AddLabel(missionlabel).
    }

    IF MISSION_TASK_LIST:LENGTH > 1 {
        LOCAL clearButton IS overviewTab:ADDButton("Clear all Tasks").
        SET clearButton:ONCLICK TO { clearMissionTasks(overviewTab).}.
    }
}

function insertMissionTask {
    parameter overviewTab.
    parameter index.
    parameter task.

    MISSION_TASK_LIST:INSERT(index, task).

    LOCAL taskName IS getTaskName(task).
    Print "Inserted Mission Task: " + taskName.

    refreshActivetasks(overviewTab).
}

function addMissionTask {
    parameter overviewTab.
    parameter task.

    MISSION_TASK_LIST:ADD(task).

    LOCAL taskName IS getTaskName(task).
    Print "Added Mission Task: " + taskName.

    refreshActivetasks(overviewTab).
}

function removeMissionTask {
    parameter overviewTab.
    parameter index.

    LOCAL task IS MISSION_TASK_LIST[index].
    LOCAL taskName is getTaskname(task).

    MISSION_TASK_LIST:REMOVE(index).

    PRINT "Removed Mission Task: " + taskName.

    refreshActiveTasks(overviewTab).
}

function clearMissionTasks {
    parameter overviewTab.

    MISSION_TASK_LIST:CLEAR().

    Print "Cleared Mission Tasks.".

    refreshActiveTasks(overviewTab).
}

function addMissionTaskButtons {
    parameter overviewTab.
    parameter addTaskTab.

    LOCAL label IS addTaskTab:ADDLABEL("Add Mission Tasks").
    SET label:STYLE:ALIGN TO "CENTER".

    Local taskCategories IS addTabWidget(addTaskTab).

    Local variableBox IS addTaskTab:AddStack().

    //Ship Systems Category
    Local shipCategory IS addTab(taskCategories, "Ship Systems").
    Local shipOptions IS addTabWidget(shipCategory, TRUE).

    Local gearTab IS addTab(shipOptions, "Gear", TRUE).
    addMissionTaskButton(overviewTab, gearTab, "Lower Gear", {GEAR ON. WAIT 5.}).
    addMissionTaskButton(overviewTab, gearTab, "Raise Gear", {GEAR OFF. WAIT 5.}).

    Local brakeTab IS addTab(shipOptions, "Brakes", TRUE).
    addMissionTaskButton(overviewTab, brakeTab, "Brakes On", {BRAKES ON. WAIT 1.}).
    addMissionTaskButton(overviewTab, brakeTab, "Brakes Off", {BRAKES OFF. WAIT 1.}).

    Local lightTab IS addTab(shipOptions, "Lights", TRUE).
    addMissionTaskButton(overviewTab, lightTab, "Lights On", {LIGHTS ON. WAIT 1.}).
    addMissionTaskButton(overviewTab, lightTab, "Lights Off", {LIGHTS OFF. WAIT 1.}).

    Local solarTab IS addTab(shipOptions, "Solar Panels", TRUE).
    addMissionTaskButton(overviewTab, solarTab, "Deploy Panels", {PANELS ON. WAIT 10.}).
    addMissionTaskButton(overviewTab, solarTab, "Retract Panels", {PANELS OFF. WAIT 10.}).

    //SSTO Category
    Local sstoCategory IS addTab(taskCategories, "SSTO").
    Local sstoOptions IS addTabWidget(sstoCategory, TRUE).

    Local sstoTab IS addTab(sstoOptions, "Launch", TRUE).
    addMissionTaskButton(overviewTab, sstoTab, "SSTO Launch", sstoLaunch@).

    //Rendevous Category
    Local rendevousCategory IS addTab(taskCategories, "Rendevous", FALSE).
    Local rendevousOptions IS addTabWidget(rendevousCategory, TRUE).

    Local matchInclinationTab IS addTab(rendevousOptions, "Match Inclination", TRUE).
    matchInclinationPanel(overviewTab, matchInclinationTab).

    Local rendevousTab IS addTab(rendevousOptions, "Rendevous", TRUE).
    rendevousPanel(overviewTab, rendevousTab).

    //Docking Category
    Local dockingCategory IS addTab(taskCategories, "Docking", FALSE).
    Local dockingOptions IS addTabWidget(dockingCategory, TRUE).

    Local dockOnPortTab IS addTab(dockingOptions, "Dock", TRUE).
    dockOnPortPanel(overviewTab, dockOnPortTab).

    //Test Category
    Local testCategory IS addTab(taskCategories, "Test").
    addMissionTaskButton(overviewTab, testCategory, "Test Task 1", {Print "Performing Test Task 1".}).
    addMissionTaskButton(overviewTab, testCategory, "Test Task 2", {Print "Performing Test Task 2".}).
}

function addMissionTaskButton {
    parameter overviewTab.
    parameter taskTab.
    parameter taskName.
    parameter taskDelegate.

    LOCAL taskButton IS taskTab:ADDBUTTON(taskName).
    SET taskButton:ONCLICK TO {
        addMissionTask(overviewTab, getTask(taskName, taskDelegate)).
        activateButton(taskButton).
    }.
}

function activateButton {
    parameter button.
    SET button:STYLE:TEXTCOLOR TO GREEN.
    SET button:STYLE:HOVER:TEXTCOLOR TO GREEN.
    SET button:STYLE:ON:TEXTCOLOR TO GREEN.
    WAIT 0.25.
    SET button:STYLE:TEXTCOLOR TO WHITE.
    SET button:STYLE:HOVER:TEXTCOLOR TO WHITE.
    SET button:STYLE:ON:TEXTCOLOR TO WHITE.
}

function executeMission {
    for task IN MISSION_TASK_LIST {
        Local taskName IS getTaskName(task).
        Local taskDelegate IS getTaskDelegate(task).

        PRINT "Executing Task: " + taskName.
        taskDelegate().
    }
}

//***** Below are more complicated tasks that can be executed as part of a mission *****//
function rendevousTask {
    parameter targetVessel.
    Local delegate IS rendevous@:bind(targetVessel).
    return getTask("Rendevous with " + targetVessel:SHIPNAME, delegate).
}

function rendevousPanel {
    parameter overviewTab.
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Rendevous").
    LOCAL popup is panel:addPopupMenu().

    LIST Targets IN targets.

    for option IN targets {
        popup:addoption(option).
    }

    Local rendevousButton IS panel:ADDBUTTON("Rendevous").
    SET rendevousButton:ONCLICK TO {
        addMissionTask(overviewTab, rendevousTask(popup:VALUE)).
        activateButton(rendevousButton).
    }.
}

function matchInclinationTask {
    parameter targetVessel.
    Local delegate IS matchInclination@:bind(targetVessel).
    return getTask("Match Inclination with " + targetVessel:SHIPNAME, delegate).
}

function matchInclinationPanel {
    parameter overviewTab.
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Match Inclination").
    LOCAL popup is panel:addPopupMenu().
    LIST Targets IN targets.

    for option IN targets {
        popup:addoption(option).
    }

    Local matchInclinationButton IS panel:ADDBUTTON("Match Inclination").
    SET matchInclinationButton:ONCLICK TO {
        addMissionTask(overviewTab, matchInclinationTask(popup:VALUE)).
        activateButton(matchInclinationButton).
    }.
}

function dockOnPortTask {
    parameter sourcePort.
    parameter targetVessel.

    Local taskName IS "Docking with " + targetVessel:SHIPNAME.
    Local delegate IS dockWithTarget@:bind(sourcePort, targetVessel).

    return getTask(taskName, delegate).
}

function dockOnPortPanel {
    parameter overviewTab.
    parameter panel.
    LOCAL dockingPorts IS getDockablePorts(SHIP).

    LOCAL label IS panel:ADDLABEL("Source Port").
    LOCAL sourcePortPopup is panel:addPopupMenu().

    for option IN dockingPorts {
        sourcePortPopup:addoption(option).
    }

    LIST Targets IN dockableTargets.

    LOCAL label IS panel:ADDLABEL("Target Port").
    LOCAL targetPopup is panel:addPopupMenu().

    for option IN dockableTargets {
        targetPopup:addoption(option).
    }

    Local dockButton IS panel:ADDBUTTON("Dock").
    SET dockButton:ONCLICK TO {
        addMissionTask(overviewTab, dockOnPortTask( sourcePortPopup:VALUE, targetPopup:VALUE)).
        activateButton(dockButton).
    }.
}

function getTask {
    parameter name.
    parameter delegate.

    return list(name, delegate).
}

function getTaskName {
    parameter task.
    return task[0].
}

function getTaskDelegate {
    parameter task.
    return task[1].
}