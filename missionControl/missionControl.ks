RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/input.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").

RUNONCEPATH("0:/missionControl/panels/dockingPanel.ks").
RUNONCEPATH("0:/missionControl/panels/orbitPanel.ks").
RUNONCEPATH("0:/missionControl/panels/rendevousPanel.ks").
RUNONCEPATH("0:/missionControl/panels/sstoPanel.ks").
RUNONCEPATH("0:/missionControl/panels/systemsPanel.ks").

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