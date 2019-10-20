RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/ui/engineWidget.ks").

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

    Local enginesTab IS addTab(shipOptions, "Engines", TRUE).
    engineTabPanel(enginesTab).

    Local agTab IS addTab(shipOptions, "Action Groups", TRUE).
    agTabPanel(agTab).
}

function engineTabPanel {
    parameter panel.

    LOCAL testButton IS panel:ADDBUTTON("Test").
    SET testButton:ONCLICK TO activatePrimaryEnginesButtonHandler@:BIND(true).

    LOCAL primaryEnginePanel IS panel:ADDVBOX().
    LOCAL primaryEnginelabel IS primaryEnginePanel:ADDLABEL("Primary Engines").
    SET primaryEnginelabel:STYLE:ALIGN TO "CENTER".

    LOCAL activatePrimaryEnginesButton IS primaryEnginePanel:ADDBUTTON("Activate").
    SET activatePrimaryEnginesButton:ONCLICK TO activatePrimaryEnginesButtonHandler@:BIND(true).

    LOCAL deactivatePrimaryEnginesButton IS primaryEnginePanel:ADDBUTTON("Deactivate").
    SET deactivatePrimaryEnginesButton:ONCLICK TO activatePrimaryEnginesButtonHandler@:BIND(false).

    LOCAL secondaryEnginePanel IS panel:ADDVBOX().
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