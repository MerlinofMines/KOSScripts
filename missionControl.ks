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

    LOCAL gui IS GUI(400,800).
    LOCAL label IS gui:ADDLABEL("Mission Control").

    addMissionTabWidget(gui).

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

function addMissionTabWidget {
    parameter gui.

    Local missionTabs IS addTabWidget(gui).

    Local overviewTab IS addTab(missionTabs, "Mission Overview").

    Local addTaskTab IS addTab(missionTabs, "Add Task").
//    addTaskTab:addLabel("Add Task").

    addMissionTaskButtons(overviewTab, addTaskTab).

    return missionTabs.
}

function refreshActiveTasks {
    parameter overviewTab.

    overviewTab:CLEAR().
//    overviewTab:AddLabel("Mission Overview").

    Local missionBox IS overviewTab:addVLayout().

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

function addMissionTaskButtons {
    parameter overviewTab.
    parameter addTaskTab.

    Local taskCategories IS addTabWidget(addTaskTab).

    Local variableBox IS addTaskTab:AddStack().

    //SSTO Category
    Local sstoCategory IS addTab(taskCategories, "SSTO").
    Local sstoOptions IS addTabWidget(sstoCategory, TRUE).

    Local sstoTab IS addTab(sstoOptions, "Launch", TRUE).
    sstoPanel(overviewTab, sstoTab).

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

    Local testTaskButton IS testCategory:ADDBUTTON("Test Task 1").
    SET testTaskButton:ONCLICK TO {
        addMissionTask(overviewTab, testTask("Test Mission 1")).
        activateButton(testTaskButton).
    }.

    Local testTaskButton2 IS testCategory:ADDBUTTON("Test Task 2").
    SET testTaskButton2:ONCLICK TO {
        addMissionTask(overviewTab, testTask("Test Mission 2")).
        activateButton(testTaskButton2).
    }.
}

function activateButton {
    parameter button.
    SET button:STYLE:TEXTCOLOR TO GREEN.
    WAIT 1.
    SET button:STYLE:TEXTCOLOR TO WHITE.
}

function executeMission {
    for task IN MISSION_TASK_LIST {
        Local taskName IS getTaskName(task).
        Local taskDelegate IS getTaskDelegate(task).

        PRINT "Executing Task: " + taskName.
        taskDelegate().
    }
}

//***** Below are tasks that can be executed as part of a mission *****//
function testTask {
    parameter name.

    LOCAL delegate IS {Print "I'm performing my task!".  Print "My Name is: " + name.}.

    return getTask(name, delegate).
}

function sstoTask {
    Local delegate IS sstoLaunch@.
    return getTask("SSTO Launch", delegate).
}

function sstoPanel {
    parameter overviewTab.
    parameter panel.

    Local sstoButton IS panel:ADDBUTTON("SSTO LAUNCH").
    SET sstoButton:ONCLICK TO {
        addMissionTask(overviewTab, sstoTask()).
        activateButton(sstoButton).
    }.
}

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