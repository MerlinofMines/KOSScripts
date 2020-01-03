RUNONCEPATH("0:/docking/docking.ks").
RUNONCEPATH("0:/docking/grabbing.ks").
RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").

function dockingTab {
    parameter taskCategories.

    //Docking Category
    Local dockingCategory IS addTab(taskCategories, "Docking", FALSE).
    Local dockingOptions IS addTabWidget(dockingCategory, TRUE).

    dockOnPortPanel(dockingOptions).
    undockPanel(dockingOptions).

    grabPanel(dockingOptions).
}

function grabPanel {
    parameter dockingOptions.

    Local panel IS addTab(dockingOptions, "Grab", TRUE).

    LOCAL grabbers IS getGrabbers(SHIP).

    LOCAL label IS panel:ADDLABEL("Source Grabber").
    LOCAL sourcePortPopup is panel:addPopupMenu().

    for option IN grabbers {
        sourcePortPopup:addoption(option).
    }

    SET grabbableTargets TO getDockableTargets(SHIP).

    LOCAL label IS panel:ADDLABEL("Target").
    LOCAL targetPopup is panel:addPopupMenu().

    LOCAL label IS panel:ADDLABEL("Target Part").
    LOCAL targetPartPopup IS panel:addPopupMenu().

    for option IN grabbableTargets {
        targetPopup:addoption(option).
    }

    if grabbableTargets:LENGTH > 0 {
        SET targetPartPopup:OPTIONS TO getGrabbableParts(grabbableTargets[0]).
    }

    SET targetPopup:ONCHANGE TO {
        parameter choice.
        SET targetPartPopup:OPTIONS TO getGrabbableParts(choice).
    }.

    Local grabButton IS panel:ADDBUTTON("Grab").

    SET grabButton:ONCLICK TO {
        addMissionTask(grabTask(sourcePortPopup:VALUE, targetPopup:VALUE, targetPartPopup:VALUE)).
        activateButton(grabButton).
    }.
}

function getGrabbableParts {
    parameter targetVessel.

    LOCAL grabbableParts IS list().

    for part IN targetVessel:PARTS {
        grabbableParts:ADD(part).
    }

    return grabbableParts.
}

function dockOnPortPanel {
    parameter dockingOptions.

    Local panel IS addTab(dockingOptions, "Dock", TRUE).

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

    if dockableTargets:LENGTH > 0 {
        SET targetPortPopup:OPTIONS TO getDockablePorts(dockableTargets[0]).
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
        addMissionTask(getTask("Undock " + popup:VALUE:NAME, {
            PRINT "Undocking " + popup:VALUE:TOSTRING + "Docking Port".
            popup:VALUE:UNDOCK().
        }, "Undock " + popup:VALUE:TOSTRING + " Docking Port")).
        activateButton(executeButton).
    }.
}

function grabTask {
    parameter sourceGrabber.
    parameter targetVessel.
    parameter targetPart.

    Local taskName IS "Grabbing " + targetVessel:SHIPNAME.
    Local delegate IS grabPartUsingGrabber@:bind(sourceGrabber, targetPart).

    return getTask(taskName, delegate).
}

function dockOnPortTask {
    parameter sourcePort.
    parameter targetVessel.
    parameter targetPort.

    Local taskName IS "Docking with " + targetVessel:SHIPNAME.
    Local delegate IS dockUsingDockingPorts@:bind(sourcePort, targetPort).

    return getTask(taskName, delegate).
}