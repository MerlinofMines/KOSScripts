RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/ssto_improved.ks").

function sstoTab {
    parameter taskCategories.

    Local sstoCategory IS addTab(taskCategories, "SSTO").
    Local sstoOptions IS addTabWidget(sstoCategory, TRUE).

    Local sstoPanel IS addTab(sstoOptions, "Launch", TRUE).
    sstoLaunchPanel(sstoPanel).
}

function sstoLaunchPanel {
    parameter panel.

    engineChoicePanel(panel).

    LOCAL launchButton IS panel:ADDBUTTON("Launch").

    SET launchButton:ONCLICK TO {
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

        addMissionTask(sstoLaunchTask(primaryEngines, secondaryEngines)).
    }.
}

function sstoLaunchTask {
    parameter primaryEngines.
    parameter secondaryEngines.

    Local delegate IS sstoLaunch@:bind(primaryEngines):bind(secondaryEngines).
    return getTask("SSTO Launch", delegate).
}