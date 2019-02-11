RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").
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

    engineChoicePanel(panel).

    LOCAL circularizeButton IS panel:ADDBUTTON("Circularize Prograde").

    SET circularizeButton:ONCLICK TO {
        LOCAL primaryEngines IS getPrimaryEngines().
        LOCAL secondaryEngines IS getSecondaryEngines().

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