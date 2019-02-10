RUNONCEPATH("0:/ui/tab_widget.ks").
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