RUNONCEPATH("0:/ui/tab_widget.ks").
RUNONCEPATH("0:/missionControl/mission.ks").
RUNONCEPATH("0:/rendevous.ks").

function rendevousTab {
    parameter taskCategories.

    Local rendevousCategory IS addTab(taskCategories, "Rendevous", FALSE).
    Local rendevousOptions IS addTabWidget(rendevousCategory, TRUE).

    Local rendevousTaskTab IS addTab(rendevousOptions, "Rendevous", TRUE).
    rendevousPanel(rendevousTaskTab).

    Local matchInclinationTab IS addTab(rendevousOptions, "Match Inclination", TRUE).
    matchInclinationPanel(matchInclinationTab).

    LOCAL encounterTab is addTab(rendevousOptions, "Encounter", TRUE).
    encounterPanel(encounterTab).
}

//Panels
function matchInclinationPanel {
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Match Inclination").

    Local choices IS panel:ADDHLAYOUT().

    Local targetChoice IS choices:ADDRADIOBUTTON("Targets", TRUE).
    Local bodyChoice IS choices:ADDRADIOBUTTON("Bodies", FALSE).

    LOCAL popup is panel:addPopupMenu().
    LIST Targets IN targets.
    LIST bodies in bodies.

    for option IN targets {
        popup:addoption(option).
    }

    SET targetChoice:ONCLICK TO {
        popup:CLEAR.
        for option IN targets {
            popup:addoption(option).
        }
    }.

    SET bodyChoice:ONCLICK TO {
        popup:CLEAR.
        for bodyOption in bodies {
            popup:addoption(bodyOption).
        }
        set popup:value to body.
    }.

    Local matchInclinationButton IS panel:ADDBUTTON("Match Inclination").
    SET matchInclinationButton:ONCLICK TO {
        addMissionTask(matchInclinationTask(popup:VALUE)).
        activateButton(matchInclinationButton).
    }.
}

function rendevousPanel {
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Rendevous").
    LOCAL popup is panel:addPopupMenu().

    LIST Targets IN targets.

    for option IN targets {
        popup:addoption(option).
    }

    Local rendevousButton IS panel:ADDBUTTON("Rendevous").
    SET rendevousButton:ONCLICK TO {
        addMissionTask(rendevousTask(popup:VALUE)).
        activateButton(rendevousButton).
    }.
}

function encounterPanel {
    parameter panel.

    LOCAL label IS panel:ADDLABEL("Encounter").
    LOCAL popup is panel:addPopupMenu().

    LIST BODIES IN targets.

    for option IN targets {
        popup:addoption(option).
    }

    LOCAL infoLabel IS panel:ADDLABEL("Capture Radius:").
    LOCAL captureRadiusField IS panel:ADDTEXTFIELD("").

    Local encounterButton IS panel:ADDBUTTON("Encounter").

    SET encounterButton:ONCLICK TO {
        LOCAL encounterBody IS popup:VALUE.
        LOCAL captureRadius IS captureRadiusField:TEXT:TONUMBER(-1).

        IF (captureRadius < 0 OR captureRadius > encounterBody:SOIRADIUS) {
            SET infoLabel:TEXT TO "Please Enter a valid capture radius:".
        } ELSE {
            SET infoLabel:TEXT TO "Capture Radius:".
            addMissionTask(encounterTask(encounterBody,captureRadius)).
            activateButton(encounterButton).
        }
    }.
}

//Tasks
function rendevousTask {
    parameter targetVessel.
    Local delegate IS rendevous@:bind(targetVessel).
    return getTask("Rendevous with " + targetVessel:SHIPNAME, delegate).
}

function matchInclinationTask {
    parameter targetVessel.
    Local delegate IS matchInclination@:bind(targetVessel).
    return getTask("Match Inclination with " + targetVessel:NAME, delegate).
}

function encounterTask {
    parameter encounterBody.
    parameter captureRadius.

    Local delegate IS encounter@:bind(encounterBody):bind(captureRadius).
    return getTask("Encounter with " + encounterBody:NAME+" @ " + captureRadius +"m", delegate).
}

