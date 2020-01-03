RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/ssto/ssto_improved.ks").

function sstoTab {
    parameter taskCategories.

    Local sstoCategory IS addTab(taskCategories, "SSTO").
    Local sstoOptions IS addTabWidget(sstoCategory, TRUE).

    Local sstoPanel IS addTab(sstoOptions, "Launch", TRUE).
    sstoLaunchPanel(sstoPanel).
}

function sstoLaunchPanel {
    parameter panel.

    LOCAL launchButton IS panel:ADDBUTTON("Launch").

    SET launchButton:ONCLICK TO {
        LOCAL primaryEngines IS getPrimaryEngines().
        LOCAL secondaryEngines IS getSecondaryEngines().
        LOCAL sicoCutoff IS 69000. //TODO: Make an input value.

        IF primaryEngines:EMPTY {
            PRINT "Please select at least one primary engine.".
            return.
        }

        addMissionTask(sstoLaunchTask(primaryEngines, secondaryEngines, sicoCutoff)).
    }.
}

function sstoLaunchTask {
    parameter primaryEngines.
    parameter secondaryEngines.
    parameter sicoCutoff.

    Local delegate IS sstoLaunch@:bind(primaryEngines):bind(secondaryEngines):bind(sicoCutoff).
    return getTask("SSTO Launch", delegate, getSSTOLaunchTaskDetail(primaryEngines, secondaryEngines, sicoCutoff)).
}

function getSSTOLaunchTaskDetail {
    parameter primaryEngines.
    parameter secondaryEngines.
    parameter sicoCutoff.

    PRINT "Terminal Input: " + Terminal:INPUT:RETURN + ":" + Terminal:INPUT:RETURN.
    LOCAL detailString IS "SICO Cutoff Apoapsis: " + sicoCutoff + char(10) + char(10).
    SET detailString TO detailString + "Primary Engines: " + char(10) + primaryEngines + char(10) + char(10).
    SET detailString TO detailString + "Secondary Engines: " + char(10) + secondaryEngines + char(10) + char(10).

    return detailString.
}