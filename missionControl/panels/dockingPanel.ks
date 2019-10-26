RUNONCEPATH("0:/docking.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").

function dockingTab {
    parameter taskCategories.

    //Docking Category
    Local dockingCategory IS addTab(taskCategories, "Docking", FALSE).
    Local dockingOptions IS addTabWidget(dockingCategory, TRUE).

    Local dockOnPortTab IS addTab(dockingOptions, "Dock", TRUE).
    dockOnPortPanel(dockOnPortTab).

    undockPanel(dockingOptions).
}

function dockOnPortPanel {
    parameter panel.
    LOCAL dockingPorts IS getDockablePorts(SHIP).

    LOCAL label IS panel:ADDLABEL("Source Port").
    LOCAL sourcePortPopup is panel:addPopupMenu().

    for option IN dockingPorts {
        sourcePortPopup:addoption(option).
    }

    SET dockableTargets TO getDockableTargets(SHIP).

    LOCAL label IS panel:ADDLABEL("Target").
    LOCAL targetPopup is panel:addPopupMenu().

    LOCAL label IS panel:ADDLABEL("Target Port").
    LOCAL targetPortPopup IS panel:addPopupMenu().

    for option IN dockableTargets {
        targetPopup:addoption(option).
    }

    SET targetPopup:ONCHANGE TO {
        parameter choice.
        SET targetPortPopup:OPTIONS TO getDockablePorts(choice).
    }.

    Local dockButton IS panel:ADDBUTTON("Dock").
    SET dockButton:ONCLICK TO {
        addMissionTask(dockOnPortTask( sourcePortPopup:VALUE, targetPopup:VALUE, targetPortPopup:VALUE)).
        activateButton(dockButton).
    }.
}

function undockPanel {
    parameter panel.

    Local undockTab IS addTab(panel, "Undock", TRUE).

    SET dockingPorts TO SHIP:DockingPorts.

    LOCAL popup is undockTab:addPopupMenu().
    SET popup:OPTIONSUFFIX to "TOSTRING".

    for option IN dockingPorts {
        popup:addoption(option).
    }

    Local executeButton IS undockTab:ADDBUTTON("Undock Port").
    SET executeButton:ONCLICK TO {
        addMissionTask(getTask("Undock " + popup:VALUE:TOSTRING + " Docking Port", {
            PRINT "Undocking " + popup:VALUE:TOSTRING + "Docking Port".
            popup:VALUE:UNDOCK().
        })).
        activateButton(executeButton).
    }.
}

function dockOnPortTask {
    parameter sourcePort.
    parameter targetVessel.
    parameter targetPort.

    Local taskName IS "Docking with " + targetVessel:SHIPNAME.
    Local delegate IS dock@:bind(sourcePort, targetPort).

    return getTask(taskName, delegate).
}