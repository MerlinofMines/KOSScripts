RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").

function orbitTab {
    parameter taskCategories.

    Local orbitCategory IS addTab(taskCategories, "Orbit", FALSE).
    Local orbitOptions IS addTabWidget(orbitCategory, TRUE).

    LOCAL changeOrbitalRadiusTab IS addTab(orbitOptions, "Change Orbital Radius", TRUE).
    changeOrbitalRadiusPanel(changeOrbitalRadiusTab).

    LOCAL circularizeTab IS addTab(orbitOptions, "Circularize Orbit", TRUE).
    circularizeAtApoapsisPanel(circularizeTab).
    circularizeAtPeriapsisPanel(circularizeTab).
    circularizeProgradePanel(circularizeTab).

    LOCAL executeManeuverTab IS addTab(orbitOptions, "Execute Maneuver", TRUE).
    addMissionTaskButton(executeManeuverTab, "Execute Maneuver", {executeNextManeuver().}).
}

//Panels
function changeOrbitalRadiusPanel {
    parameter panel.

    LOCAL infoLabel IS panel:ADDLABEL("Orbital Radius:").
    LOCAL orbitField IS panel:ADDTEXTFIELD("").

    Local choices IS panel:ADDHLAYOUT().

    Local apoapsisChoice IS choices:ADDRADIOBUTTON("Apoapsis", TRUE).
    Local periapsisChoice IS choices:ADDRADIOBUTTON("Periapsis", FALSE).

    Local changeRadiusButton IS panel:ADDBUTTON("Change Apoapsis").

    LOCAL orbitalChangeTask IS changeApoapsisTask@.

    SET apoapsisChoice:ONCLICK TO {
        SET orbitalChangeTask TO changeApoapsisTask@.
        SET changeRadiusButton:TEXT TO "Change Apoapsis".
    }.

    SET periapsisChoice:ONCLICK TO {
        SET orbitalChangeTask TO changePeriapsisTask@.
        SET changeRadiusButton:TEXT TO "Change Periapsis".
    }.

    SET changeRadiusButton:ONCLICK TO {
        LOCAL orbitalRadius IS orbitField:TEXT:TONUMBER(-1).

        IF (orbitalRadius < 0) {
            SET infoLabel:TEXT TO "Please Enter a valid orbital radius:".
        } ELSE {
            SET infoLabel:TEXT TO "Orbital Radius:".
            addMissionTask(orbitalChangeTask(orbitalRadius)).
            activateButton(changeRadiusButton).
            SET orbitField:TEXT TO "".
        }
    }.
}

function changeApoapsisTask {
    parameter desiredRadius.

    LOCAL taskName IS "Change Apoapsis To " + desiredRadius.
    LOCAL taskDelegate IS changeOrbitalRadiusAtPeriapsis@:bind(desiredRadius).

    return getTask(taskName, taskDelegate).
}

function changePeriapsisTask {
    parameter desiredRadius.

    LOCAL taskName IS "Change Periapsis To " + desiredRadius.
    LOCAL taskDelegate IS changeOrbitalRadiusAtApoapsis@:bind(desiredRadius).

    return getTask(taskName, taskDelegate).
}

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