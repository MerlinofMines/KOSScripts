RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/input.ks").
RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").

RUNONCEPATH("0:/missionControl/panels/dockingPanel.ks").
RUNONCEPATH("0:/missionControl/panels/orbitPanel.ks").
RUNONCEPATH("0:/missionControl/panels/rendevousPanel.ks").
RUNONCEPATH("0:/missionControl/panels/sstoPanel.ks").
RUNONCEPATH("0:/missionControl/panels/systemsPanel.ks").

DECLARE GLOBAL MISSION_CONTROL IS missionControlGUI().
DECLARE GLOBAL MISSION_CONTROL_BUTTON IS missionControlButton(MISSION_CONTROL).
MISSION_CONTROL:HIDE().

function startMissionControl {
    MISSION_CONTROL_BUTTON:SHOW().
    WAIT UNTIL FALSE.
}

function missionControlGUI {
    LOCAL missionControlWindow IS GUI(800,800).
    addMissionTabs(missionControlWindow).
    missionControlWindow:HIDE().

    return missionControlWindow.
}

function missionControlButton {
    parameter missionControlWindow.

    LOCAL buttonGUI IS GUI(10,10).
    SET buttonGUI:X TO 1878.
    SET buttonGUI:Y TO 500.

    SET buttonGUI:SKIN:BUTTON:PADDING:RIGHT TO 0.
    SET buttonGUI:SKIN:BUTTON:MARGIN:RIGHT TO 0.
    SET buttonGUI:DRAGGABLE TO FALSE.
    LOCAL BUTTON_LABEL IS buttonGUI:ADDBUTTON("").
    SET BUTTON_LABEL:IMAGE TO "ui/MissionControl".

    SET BUTTON_LABEL:ONCLICK TO {
        SET missionControlWindow:VISIBLE TO (NOT missionControlWindow:VISIBLE).
    }.

    SET BUTTON_LABEL:STYLE:PADDING:RIGHT TO 0.
    SET BUTTON_LABEL:STYLE:MARGIN:RIGHT TO 0.
    SET BUTTON_LABEL:STYLE:PADDING:LEFT TO 0.
    SET BUTTON_LABEL:STYLE:MARGIN:LEFT TO 0.
    SET BUTTON_LABEL:STYLE:PADDING:BOTTOM TO 0.
    SET BUTTON_LABEL:STYLE:MARGIN:BOTTOM TO 0.
    SET BUTTON_LABEL:STYLE:PADDING:TOP TO 0.
    SET BUTTON_LABEL:STYLE:MARGIN:TOP TO 0.

    return buttonGUI.
}

function addMissionTabs {
    parameter gui.

    LOCAL columns IS gui:ADDHLAYOUT().

    //Overriding the reference to OVERVIEW_TAB from mission.ks.  Not terribly pretty, but effective.
    SET OVERVIEW_TAB TO columns:ADDVBOX().
    SET OVERVIEW_TAB:STYLE:WIDTH TO 400.
    SET OVERVIEW_TAB:STYLE:HEIGHT TO 400.

    LOCAL addTaskTab IS columns:ADDVBOX().
    SET addTaskTab:STYLE:WIDTH to 400.
    SET addTaskTab:STYLE:HEIGHT to 400.

    //Option 1: Show both overview & Tasks side by side
    addMissionTaskButtons(addTaskTab).
    refreshActiveTasks().
//    addMissionTaskButtons(addTaskTab).

    //Option 2: Tabs, showing overview or tasks only.
//    Local missionTabs IS addTabWidget(gui).
//    DECLARE GLOBAL OVERVIEW_TAB IS addTab(missionTabs, "Mission Overview").
//    Local addTaskTab IS addTab(missionTabs, "Add Task").
//    addTaskTab:addLabel("Add Task").

//    return missionTabs.

    LOCAL launchButton IS gui:ADDBUTTON("Launch Mission").

    SET launchButton:ONCLICK TO {
        gui:HIDE().
        MISSION_CONTROL_BUTTON:HIDE().
        executeMission().
        shortInfo("Mission Completed Successfully.").
        clearMissionTasks().
        MISSION_CONTROL_BUTTON:SHOW().
    }.
}

function addMissionTaskButtons {
    parameter addTaskTab.

    LOCAL label IS addTaskTab:ADDLABEL("Add Mission Tasks").
    SET label:STYLE:ALIGN TO "CENTER".

    Local taskCategories IS addTabWidget(addTaskTab).

    systemsTab(taskCategories).
    sstoTab(taskCategories).
    rendevousTab(taskCategories).
    dockingTab(taskCategories).
    orbitTab(taskCategories).
}