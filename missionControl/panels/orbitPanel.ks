RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").

function orbitTab {
    parameter taskCategories.

    Local orbitCategory IS addTab(taskCategories, "Orbit", FALSE).
    Local orbitOptions IS addTabWidget(orbitCategory, TRUE).

    LOCAL circularizeAtApoapsisTab IS addTab(orbitOptions, "Circularize At Apoapsis", TRUE).
    circularizeAtApoapsisPanel(circularizeAtApoapsisTab).

    LOCAL circularizeAtPeriapsisTab IS addTab(orbitOptions, "Circularize At Periapsis", TRUE).
    circularizeAtPeriapsisPanel(circularizeAtPeriapsisTab).

    LOCAL circularizeProgradeTab IS addTab(orbitOptions, "Circularize Prograde", TRUE).
    circularizeProgradePanel(circularizeProgradeTab).

    LOCAL executeManeuverTab IS addTab(orbitOptions, "Execute Maneuver", TRUE).
    addMissionTaskButton(executeManeuverTab, "Execute Maneuver", {executeNextManeuver().}).
}

//Panels
function circularizeAtApoapsisPanel {
    parameter panel.

    LOCAL circularizeButton IS panel:ADDBUTTON("Circularize At Apoapsis").
    SET circularizeButton:ONCLICK TO {
        addMissionTask(circularizeAtApoapsisTask()).
        activateButton(circularizeButton).
    }.
}

function circularizeAtPeriapsisPanel {
    parameter panel.

    LOCAL circularizeButton IS panel:ADDBUTTON("Circularize At Periapsis").
    SET circularizeButton:ONCLICK TO {
        addMissionTask(circularizeAtPeriapsisTask()).
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
        primaryEngineList:addLabel(choice:NAME+" "+choice:TAG).
        primaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        secondaryEnginePopup:options:remove(primaryEnginePopup:INDEX).
        SET primaryEnginePopup:INDEX TO 0.
        SET secondaryEnginePopup:INDEX TO 0.
    }.

    SET secondaryEnginePopup:ONCHANGE TO {
        parameter choice.

        if (choice = "Select Engine") { return. }.
        secondaryEngines:add(choice).
        secondaryEngineList:addLabel(choice:NAME+" "+choice:TAG).
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

//Tasks
function circularizeAtApoapsisTask {
    LOCAL taskName IS "Circularize at Apoapsis".
    LOCAL taskDelegate IS circularizeMaintainingApoapsis@.

    return getTask(taskName, taskDelegate).
}

function circularizeAtPeriapsisTask {
    LOCAL taskName IS "Circularize at Periapsis".
    LOCAL taskDelegate IS circularizeMaintainingPeriapsis@.

    return getTask(taskName, taskDelegate).
}

function circularizeProgradeTask {
    parameter primaryEngines.
    parameter secondaryEngines.

    LOCAL taskName IS "Circularize Prograde".
    LOCAL taskDelegate IS circularizeMaintainingPrograde@:bind(primaryEngines):bind(secondaryEngines).

    return getTask(taskName, taskDelegate).
}