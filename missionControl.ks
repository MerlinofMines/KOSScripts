RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/input.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/rendevous.ks").
RUNONCEPATH("0:/docking.ks").
RUNONCEPATH("0:/ssto_improved.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").

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

    //Declaring global, to ease readability of other methods in mission control which need to update the overview panel
    //based on events.
    DECLARE GLOBAL OVERVIEW_TAB IS columns:ADDVBOX().
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

function refreshActiveTasks {
    OVERVIEW_TAB:CLEAR().
    LOCAL label IS OVERVIEW_TAB:ADDLABEL("Mission Overview").
    SET label:STYLE:ALIGN TO "CENTER".

//    OVERVIEW_TAB:AddLabel("Mission Overview").

    Local layout IS OVERVIEW_TAB:addVLayout().
    Local missionBox IS layout:ADDSCROLLBOX().

    Local taskIterator IS MISSION_TASK_LIST:COPY:ITERATOR.

    UNTIL NOT taskIterator:NEXT {
        LOCAL taskBox IS missionBox:AddHBox().

        //Remove Button
        LOCAL removeButton IS taskBox:ADDBUTTON("X").

        LOCAL index IS taskIterator:INDEX.

        SET removeButton:STYLE:WIDTH TO 20.
        SET removeButton:STYLE:MARGIN:RIGHT TO 5.
        SET removeButton:ONCLICK TO {removeMissionTask(index).}.

        //Mission Label
        Local missionlabel IS getTaskName(taskIterator:VALUE).

        taskBox:AddLabel(missionlabel).
    }

    IF MISSION_TASK_LIST:LENGTH > 1 {
        LOCAL clearButton IS OVERVIEW_TAB:AddButton("Clear all Tasks").
        SET clearButton:ONCLICK TO { clearMissionTasks().}.
    }
}

function insertMissionTask {
    parameter index.
    parameter task.

    MISSION_TASK_LIST:INSERT(index, task).

    LOCAL taskName IS getTaskName(task).
    Print "Inserted Mission Task: " + taskName.

    refreshActivetasks().
}

function addMissionTask {
    parameter task.

    MISSION_TASK_LIST:ADD(task).

    LOCAL taskName IS getTaskName(task).
    Print "Added Mission Task: " + taskName.

    refreshActivetasks().
}

function removeMissionTask {
    parameter index.

    LOCAL task IS MISSION_TASK_LIST[index].
    LOCAL taskName is getTaskname(task).

    MISSION_TASK_LIST:REMOVE(index).

    PRINT "Removed Mission Task: " + taskName.

    refreshActiveTasks().
}

function clearMissionTasks {
    MISSION_TASK_LIST:CLEAR().

    Print "Cleared Mission Tasks.".

    refreshActiveTasks().
}

function addMissionTaskButtons {
    parameter addTaskTab.

    LOCAL label IS addTaskTab:ADDLABEL("Add Mission Tasks").
    SET label:STYLE:ALIGN TO "CENTER".

    Local taskCategories IS addTabWidget(addTaskTab).

    Local variableBox IS addTaskTab:AddStack().

    //Ship Systems Category
    Local shipCategory IS addTab(taskCategories, "Ship Systems").
    Local shipOptions IS addTabWidget(shipCategory, TRUE).

    Local gearTab IS addTab(shipOptions, "Gear", TRUE).
    addMissionTaskButton(gearTab, "Lower Gear", {GEAR ON. WAIT 5.}).
    addMissionTaskButton(gearTab, "Raise Gear", {GEAR OFF. WAIT 5.}).

    Local brakeTab IS addTab(shipOptions, "Brakes", TRUE).
    addMissionTaskButton(brakeTab, "Brakes On", {BRAKES ON. WAIT 1.}).
    addMissionTaskButton(brakeTab, "Brakes Off", {BRAKES OFF. WAIT 1.}).

    Local lightTab IS addTab(shipOptions, "Lights", TRUE).
    addMissionTaskButton(lightTab, "Lights On", {LIGHTS ON. WAIT 1.}).
    addMissionTaskButton(lightTab, "Lights Off", {LIGHTS OFF. WAIT 1.}).

    Local solarTab IS addTab(shipOptions, "Solar Panels", TRUE).
    addMissionTaskButton(solarTab, "Deploy Panels", {PANELS ON. WAIT 10.}).
    addMissionTaskButton(solarTab, "Retract Panels", {PANELS OFF. WAIT 10.}).

    Local chutesTab IS addTab(shipOptions, "Chutes", TRUE).
    addMissionTaskButton(chutesTab, "Deploy Chutes", {CHUTES ON. WAIT 2.}).
    addMissionTaskButton(chutesTab, "Deply Chutes Safely", {CHUTESSAFE ON. WAIT 2.}).

    //SSTO Category
    Local sstoCategory IS addTab(taskCategories, "SSTO").
    Local sstoOptions IS addTabWidget(sstoCategory, TRUE).

    Local sstoTab IS addTab(sstoOptions, "Launch", TRUE).
    sstoLaunchPanel(sstoTab).
//    addMissionTaskButton(sstoTab, "SSTO Launch", sstoLaunch@).

    //Rendevous Category
    Local rendevousCategory IS addTab(taskCategories, "Rendevous", FALSE).
    Local rendevousOptions IS addTabWidget(rendevousCategory, TRUE).

    Local matchInclinationTab IS addTab(rendevousOptions, "Match Inclination", TRUE).
    matchInclinationPanel(matchInclinationTab).

    Local rendevousTab IS addTab(rendevousOptions, "Rendevous", TRUE).
    rendevousPanel(rendevousTab).

    //Docking Category
    Local dockingCategory IS addTab(taskCategories, "Docking", FALSE).
    Local dockingOptions IS addTabWidget(dockingCategory, TRUE).

    Local dockOnPortTab IS addTab(dockingOptions, "Dock", TRUE).
    dockOnPortPanel(dockOnPortTab).

    //Orbital Maneuver Category
    Local orbitCategory IS addTab(taskCategories, "Orbit", FALSE).
    Local orbitOptions IS addTabWidget(orbitCategory, TRUE).

    LOCAL circularizeAtApoapsisTab IS addTab(orbitOptions, "Circularize At Apoapsis", TRUE).
    circularizeAtApoapsisPanel(circularizeAtApoapsisTab).

    LOCAL circularizeProgradeTab IS addTab(orbitOptions, "Circularize Prograde", TRUE).
    circularizeProgradePanel(circularizeProgradeTab).

//Test Category
//    Local testCategory IS addTab(taskCategories, "Test").
//    addMissionTaskButton(testCategory, "Test Task 1", {Print "Performing Test Task 1".}).
//    addMissionTaskButton(testCategory, "Test Task 2", {Print "Performing Test Task 2".}).
}

function addMissionTaskButton {
    parameter taskTab.
    parameter taskName.
    parameter taskDelegate.

    LOCAL taskButton IS taskTab:ADDBUTTON(taskName).
    SET taskButton:ONCLICK TO {
        addMissionTask(getTask(taskName, taskDelegate)).
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
    CLEARSCREEN.
    for task IN MISSION_TASK_LIST {
        Local taskName IS getTaskName(task).
        Local taskDelegate IS getTaskDelegate(task).

        PRINT "Executing Task: " + taskName.
        taskDelegate().
    }
}

//***** Below are more complicated tasks that can be executed as part of a mission *****//
function sstoLaunchPanel {
    parameter panel.

    LIST Engines IN my_engines.

    LOCAL label IS panel:ADDLABEL("Primary Engines:").
    LOCAL primaryEngineList is panel:addVLAYOUT().
    LOCAL primaryEnginePopup is panel:addPopupMenu().

    LOCAL label IS panel:ADDLABEL("Secondary Engines:").
    LOCAL secondaryEngineList is panel:addVLAYOUT().
    LOCAL secondaryEnginePopup is panel:addPopupMenu().

    primaryEnginePopup:addoption("Select Engine").
    secondaryEnginePopup:addoption("Select Engine").

    for option IN my_engines {
        primaryEnginePopup:addoption(option).
        secondaryEnginePopup:addoption(option).
    }

    LOCAL circularizeButton IS panel:ADDBUTTON("Launch").

    LOCAL primaryEngines IS LIST().
    LOCAL secondaryEngines IS LIST().

    SET primaryEnginePopup:ONCHANGE TO {
        parameter choice.

        if (choice = "Select Engine") { return. }.
        primaryEngines:add(choice).
        primaryEngineList:addLabel(choice:TAG).
        primaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        secondaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        SET primaryEnginePopup:INDEX TO 0.
        SET secondaryEnginePopup:INDEX TO 0.
    }.

    SET secondaryEnginePopup:ONCHANGE TO {
        parameter choice.

        if (choice = "Select Engine") { return. }.
        secondaryEngines:add(choice).
        secondaryEngineList:addLabel(choice:TAG).
        primaryEnginePopup:options:remove(secondaryEnginePopup:INDEX).
        secondaryEnginePopup:options:remove(secondaryEnginePopup:INDEX).
        SET primaryEnginePopup:INDEX TO 0.
        SET secondaryEnginePopup:INDEX TO 0.
    }.

    SET circularizeButton:ONCLICK TO {
        IF primaryEngines:EMPTY {
            PRINT "Please select at least one primary engine.".
            return.
        }

        PRINT "Circularizing Prograde using the following settings:".
        PRINT "Primary Engines: ".
        PRINT primaryEngines.
        PRINT "Secondary Engines: ".
        PRINT secondaryEngines.

        addMissionTask(sstoLaunchTask(primaryEngines, secondaryEngines)).

    //Reset in case we want to perform this task twice during the mission.
        primaryEngineList:CLEAR.
        secondaryEngineList:CLEAR.
        primaryEnginePopup:CLEAR.
        secondaryEnginePopup:CLEAR.
        SET primaryEngines TO LIST().
        SET secondaryEngines TO LIST().
        LIST Engines IN my_engines.

        primaryEnginePopup:addoption("Select Engine").
        secondaryEnginePopup:addoption("Select Engine").

        for option IN my_engines {
            primaryEnginePopup:addoption(option).
            secondaryEnginePopup:addoption(option).
        }
    }.
}

function sstoLaunchTask {
    parameter primaryEngines.
    parameter secondaryEngines.

    Local delegate IS sstoLaunch@:bind(primaryEngines):bind(secondaryEngines).
    return getTask("SSTO Launch", delegate).
}

function rendevousTask {
    parameter targetVessel.
    Local delegate IS rendevous@:bind(targetVessel).
    return getTask("Rendevous with " + targetVessel:SHIPNAME, delegate).
}

function rendevousPanel {
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Rendevous").
    LOCAL popup is panel:addPopupMenu().

    LIST Targets IN targets.

    for option IN targets {
        popup:addoption(option).
    }

    Local rendevousButton IS panel:ADDBUTTON("Rendevous").
    SET rendevousButton:ONCLICK TO {
        addMissionTask(rendevousTask(popup:VALUE)).
        activateButton(rendevousButton).
    }.
}

function matchInclinationTask {
    parameter targetVessel.
    Local delegate IS matchInclination@:bind(targetVessel).
    return getTask("Match Inclination with " + targetVessel:NAME, delegate).
}

function matchInclinationPanel {
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Match Inclination").

    Local choices IS panel:ADDHLAYOUT().

    Local targetChoice IS choices:ADDRADIOBUTTON("Targets", TRUE).
    Local bodyChoice IS choices:ADDRADIOBUTTON("Bodies", FALSE).

    LOCAL popup is panel:addPopupMenu().
    LIST Targets IN targets.
    LIST bodies in bodies.

    for option IN targets {
        popup:addoption(option).
    }

    SET targetChoice:ONCLICK TO {
        popup:CLEAR.
        for option IN targets {
            popup:addoption(option).
        }
    }.

    SET bodyChoice:ONCLICK TO {
        popup:CLEAR.
        for bodyOption in bodies {
            popup:addoption(bodyOption).
        }
        set popup:value to body.
    }.

    Local matchInclinationButton IS panel:ADDBUTTON("Match Inclination").
    SET matchInclinationButton:ONCLICK TO {
        addMissionTask(matchInclinationTask(popup:VALUE)).
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
        addMissionTask(dockOnPortTask( sourcePortPopup:VALUE, targetPopup:VALUE)).
        activateButton(dockButton).
    }.
}

function circularizeAtApoapsisPanel {
    parameter panel.

    LOCAL circularizeButton IS panel:ADDBUTTON("Circularize At Apoapsis").
    SET circularizeButton:ONCLICK TO {
        addMissionTask(circularizeAtApoapsisTask()).
        activateButton(circularizeButton).
    }.
}

function circularizeProgradePanel {
    parameter panel.

    LIST Engines IN my_engines.

    LOCAL label IS panel:ADDLABEL("Primary Engines:").
    LOCAL primaryEngineList is panel:addVLAYOUT().
    LOCAL primaryEnginePopup is panel:addPopupMenu().

    LOCAL label IS panel:ADDLABEL("Secondary Engines:").
    LOCAL secondaryEngineList is panel:addVLAYOUT().
    LOCAL secondaryEnginePopup is panel:addPopupMenu().

    primaryEnginePopup:addoption("Select Engine").
    secondaryEnginePopup:addoption("Select Engine").

    for option IN my_engines {
        primaryEnginePopup:addoption(option).
        secondaryEnginePopup:addoption(option).
    }

    LOCAL circularizeButton IS panel:ADDBUTTON("Circularize Prograde").

    LOCAL primaryEngines IS LIST().
    LOCAL secondaryEngines IS LIST().

    SET primaryEnginePopup:ONCHANGE TO {
        parameter choice.

        if (choice = "Select Engine") { return. }.
        primaryEngines:add(choice).
        primaryEngineList:addLabel(choice:TAG).
        primaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        secondaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        SET primaryEnginePopup:INDEX TO 0.
        SET secondaryEnginePopup:INDEX TO 0.
    }.

    SET secondaryEnginePopup:ONCHANGE TO {
        parameter choice.

        if (choice = "Select Engine") { return. }.
        secondaryEngines:add(choice).
        secondaryEngineList:addLabel(choice:TAG).
        primaryEnginePopup:options:remove(secondaryEnginePopup:INDEX).
        secondaryEnginePopup:options:remove(secondaryEnginePopup:INDEX).
        SET primaryEnginePopup:INDEX TO 0.
        SET secondaryEnginePopup:INDEX TO 0.
    }.

    SET circularizeButton:ONCLICK TO {
        IF primaryEngines:EMPTY {
            PRINT "Please select at least one primary engine.".
            return.
        }

        PRINT "Circularizing Prograde using the following settings:".
        PRINT "Primary Engines: ".
        PRINT primaryEngines.
        PRINT "Secondary Engines: ".
        PRINT secondaryEngines.

        addMissionTask(circularizeProgradeTask(primaryEngines, secondaryEngines)).

        //Reset in case we want to perform this task twice during the mission.
        primaryEngineList:CLEAR.
        secondaryEngineList:CLEAR.
        primaryEnginePopup:CLEAR.
        secondaryEnginePopup:CLEAR.
        SET primaryEngines TO LIST().
        SET secondaryEngines TO LIST().
        LIST Engines IN my_engines.

        primaryEnginePopup:addoption("Select Engine").
        secondaryEnginePopup:addoption("Select Engine").

        for option IN my_engines {
            primaryEnginePopup:addoption(option).
            secondaryEnginePopup:addoption(option).
        }
    }.
}

function circularizeAtApoapsisTask {
    LOCAL taskName IS "Circularize at Apoapsis".
    LOCAL taskDelegate IS circularizeMaintainingApoapsis@:bind(SHIP).

    return getTask(taskName, taskDelegate).
}

function circularizeProgradeTask {
    parameter primaryEngines.
    parameter secondaryEngines.

    LOCAL taskName IS "Circularize Prograde".
    LOCAL taskDelegate IS circularizeMaintainingPrograde@:bind(primaryEngines):bind(secondaryEngines).

    return getTask(taskName, taskDelegate).
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