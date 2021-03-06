RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").
RUNONCEPATH("0:/systems/fairing.ks").

function systemsTab {
    parameter taskCategories.

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

    fairingTabPanel(shipOptions).

    grabberTabPanel(shipOptions).

    engineTabPanel(shipOptions).

    sasTabPanel(shipOptions).

    Local agTab IS addTab(shipOptions, "Action Groups", TRUE).
    agTabPanel(agTab).
}

function grabberTabPanel {
    parameter panel.

    LOCAL grabbers IS getGrabbers().

    IF grabbers:LENGTH = 0 return.

    LOCAL grabberTab IS addTab(panel, "Grabbers", TRUE).

    LOCAL popup is grabberTab:addPopupMenu().
    SET popup:OPTIONSUFFIX to "TITLE".

    for option IN grabbers {
        popup:addoption(option).
    }

    Local armButton IS grabberTab:ADDBUTTON("Arm").
    SET armButton:ONCLICK TO {
        addMissionTask(getTask("Arm " + popup:VALUE:NAME, {
            armGrabber(popup:VALUE).
        })).
        activateButton(armButton).
    }.

    Local disarmButton IS grabberTab:ADDBUTTON("Disarm").
    SET disarmButton:ONCLICK TO {
        addMissionTask(getTask("Disarm " + popup:VALUE:NAME, {
            disarmGrabber(popup:VALUE).
        })).
        activateButton(disarmButton).
    }.

    Local releaseButton IS grabberTab:ADDBUTTON("Release").
    SET releaseButton:ONCLICK TO {
        addMissionTask(getTask("Release " + popup:VALUE:NAME, {
            releaseGrabber(popup:VALUE).
        })).
        activateButton(releaseButton).
    }.
}

function fairingTabPanel {
    parameter panel.

    LOCAL fairings IS getFairings().

    IF fairings:LENGTH = 0 return.

    LOCAL fairingTab IS addTab(panel, "Fairings", TRUE).

    LOCAL popup is fairingTab:addPopupMenu().
    SET popup:OPTIONSUFFIX to "TITLE".

    for option IN fairings {
        popup:addoption(option).
    }

    Local executeButton IS fairingTab:ADDBUTTON("Deploy Fairing").
    SET executeButton:ONCLICK TO {
        addMissionTask(getTask("Deploy " + popup:VALUE:NAME + " Fairing", {
            PRINT "Deploying " + popup:VALUE:NAME.
            deployFairing(popup:VALUE).
        })).
        activateButton(executeButton).
    }.
}

function engineTabPanel {
    parameter panel.

    Local enginesTab IS addTab(panel, "Engines", TRUE).

    LOCAL primaryEnginePanel IS enginesTab:ADDVBOX().
    LOCAL primaryEnginelabel IS primaryEnginePanel:ADDLABEL("Primary Engines").
    SET primaryEnginelabel:STYLE:ALIGN TO "CENTER".

    LOCAL activatePrimaryEnginesButton IS primaryEnginePanel:ADDBUTTON("Activate").
    SET activatePrimaryEnginesButton:ONCLICK TO activatePrimaryEnginesButtonHandler@:BIND(true).

    LOCAL deactivatePrimaryEnginesButton IS primaryEnginePanel:ADDBUTTON("Deactivate").
    SET deactivatePrimaryEnginesButton:ONCLICK TO activatePrimaryEnginesButtonHandler@:BIND(false).

    LOCAL secondaryEnginePanel IS enginesTab:ADDVBOX().
    LOCAL secondaryEngineLabel IS secondaryEnginePanel:ADDLABEL("Secondary Engines").
    SET secondaryEngineLabel:STYLE:ALIGN TO "CENTER".

    LOCAL activateSecondaryEnginesButton IS secondaryEnginePanel:ADDBUTTON("Activate").
    SET activateSecondaryEnginesButton:ONCLICK TO activateSecondaryEnginesButtonHandler@:BIND(true).

    LOCAL deactivateSecondaryEnginesButton IS secondaryEnginePanel:ADDBUTTON("Deactivate").
    SET deactivateSecondaryEnginesButton:ONCLICK TO activateSecondaryEnginesButtonHandler@:BIND(false).
}

function agTabPanel {
    parameter panel.

    LOCAL scrollPanel IS panel:addscrollbox().

    LOCAL ag1Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag1Panel, "AG1 On", {AG1 ON. WAIT 0.5.}).
    addMissionTaskButton(ag1Panel, "AG1 Off", {AG1 OFF. WAIT 0.5.}).

    LOCAL ag2Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag2Panel, "AG2 On", {AG2 ON. WAIT 0.5.}).
    addMissionTaskButton(ag2Panel, "AG2 Off", {AG2 OFF. WAIT 0.5.}).

    LOCAL ag3Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag3Panel, "AG3 On", {AG3 ON. WAIT 0.5.}).
    addMissionTaskButton(ag3Panel, "AG3 Off", {AG3 OFF. WAIT 0.5.}).

    LOCAL ag4Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag4Panel, "AG4 On", {AG4 ON. WAIT 0.5.}).
    addMissionTaskButton(ag4Panel, "AG4 Off", {AG4 OFF. WAIT 0.5.}).

    LOCAL ag5Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag5Panel, "AG5 On", {AG5 ON. WAIT 0.5.}).
    addMissionTaskButton(ag5Panel, "AG5 Off", {AG5 OFF. WAIT 0.5.}).

    LOCAL ag6Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag6Panel, "AG6 On", {AG6 ON. WAIT 0.5.}).
    addMissionTaskButton(ag6Panel, "AG6 Off", {AG6 OFF. WAIT 0.5.}).

    LOCAL ag7Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag7Panel, "AG7 On", {AG7 ON. WAIT 0.5.}).
    addMissionTaskButton(ag7Panel, "AG7 Off", {AG7 OFF. WAIT 0.5.}).

    LOCAL ag8Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag8Panel, "AG8 On", {AG8 ON. WAIT 0.5.}).
    addMissionTaskButton(ag8Panel, "AG8 Off", {AG8 OFF. WAIT 0.5.}).

    LOCAL ag9Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag9Panel, "AG9 On", {AG9 ON. WAIT 0.5.}).
    addMissionTaskButton(ag9Panel, "AG9 Off", {AG9 OFF. WAIT 0.5.}).

    LOCAL ag10Panel IS scrollPanel:ADDHLAYOUT().
    addMissionTaskButton(ag10Panel, "AG10 On", {AG10 ON. WAIT 0.5.}).
    addMissionTaskButton(ag10Panel, "AG10 Off", {AG10 OFF. WAIT 0.5.}).
}

function sasTabPanel {
    parameter panel.

    LOCAL sasTab IS addTab(panel, "SAS", TRUE).
    LOCAL scrollPanel IS sasTab:addscrollbox().

    LOCAL engageSASPanel IS scrollPanel:ADDVLAYOUT().
    LOCAL engageSASLabel IS engageSASPanel:ADDLABEL("SAS").
    SET engageSASLabel:STYLE:ALIGN TO "CENTER".

    LOCAL sasOnOffPanel IS engageSASPanel:ADDHLAYOUT().
    addMissionTaskButton(sasOnOffPanel, "Engage", {SAS ON. WAIT 0.5.}).
    addMissionTaskButton(sasOnOffPanel, "Disengage", {SAS OFF. WAIT 0.5.}).

    LOCAL sasModePanel IS scrollPanel:ADDVLayout().
    LOCAL sasModeLabel IS sasModePanel:ADDLABEL("SAS Mode").
    SET sasModeLabel:STYLE:ALIGN TO "CENTER".

    LOCAL sasStabilityPanel IS sasModePanel:ADDHLAYOUT().
    addMissionTaskButton(sasStabilityPanel, "Stability", {SET SASMODE to "STABILITY". WAIT 0.5.}).
    addMissionTaskButton(sasStabilityPanel, "Maneuver", {SET SASMODE to "MANEUVER". WAIT 0.5.}).

    LOCAL sasProgradePanel IS sasModePanel:ADDHLAYOUT().
    addMissionTaskButton(sasProgradePanel, "Prograde", {SET SASMODE to "PROGRADE". WAIT 0.5.}).
    addMissionTaskButton(sasProgradePanel, "Retrograde", {SET SASMODE to "RETROGRADE". WAIT 0.5.}).

    LOCAL sasNormalPanel IS sasModePanel:ADDHLAYOUT().
    addMissionTaskButton(sasNormalPanel, "Normal", {SET SASMODE to "NORMAL". WAIT 0.5.}).
    addMissionTaskButton(sasNormalPanel, "Anti-Normal", {SET SASMODE to "ANTINORMAL". WAIT 0.5.}).

    LOCAL sasRadialPanel IS sasModePanel:ADDHLAYOUT().
    addMissionTaskButton(sasRadialPanel, "Radial Out", {SET SASMODE to "RADIALOUT". WAIT 0.5.}).
    addMissionTaskButton(sasRadialPanel, "Radial In", {SET SASMODE to "RADIALIN". WAIT 0.5.}).

    LOCAL sasTargetPanel IS sasModePanel:ADDHLAYOUT().
    addMissionTaskButton(sasTargetPanel, "Target", {SET SASMODE to "TARGET". WAIT 0.5.}).
    addMissionTaskButton(sasTargetPanel, "Anti-Target", {SET SASMODE to "ANTITARGET". WAIT 0.5.}).
}

function activatePrimaryEnginesButtonHandler {
    parameter activate IS FALSE.
    activateEnginesButtonHandler(getPrimaryEngines(), activate).
}

function activateSecondaryEnginesButtonHandler {
    parameter activate IS FALSE.
    activateEnginesButtonHandler(getSecondaryEngines(), activate).
}

function activateEnginesButtonHandler {
    parameter myEngines.
    parameter activate IS FALSE.

    IF myEngines:length = 0 {
        return.
    }

    LOCAL activateText IS "Activate".
    IF (NOT activate) {
        SET activateText TO "Deactivate".
    }

    PRINT "Added Mission task to " + activateText + " the following engines:".

    PRINT myEngines.

    addMissionTask(getTask(activateText + " " + myEngines:length + " engines", activateEnginesTask@:BIND(myEngines):bind(activate))).
}


function activateEnginesTask {
    parameter myEngines.
    parameter activate IS FALSE.

    PRINT myEngines.
    PRINT "Activate: " + activate.
    if (activate) {
        PRINT "Activating the following Engines:".
    } else {
        PRINT "Deactivating the following Engines:".
    }

    FOR engine IN myEngines {
        PRINT engine:NAME.
        if(activate) {
            engine:ACTIVATE().
        } else {
            engine:SHUTDOWN().
        }
    }

    WAIT 1.
}