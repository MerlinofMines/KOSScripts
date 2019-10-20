RUNONCEPATH("0:/missionControl/missionControl.ks").

UNTIL FALSE {
    getMissionControlMiniButton().
}

function getMissionControlMiniButton {
    LOCAL gui IS GUI(100,100).

    SET gui:X TO 1870.
    SET gui:Y TO 574.

    SET GUI:STYLE:BG to "transparent".
    SET GUI:STYLE:BORDER:LEFT TO 5.
    SET GUI:STYLE:BORDER:RIGHT TO 5.
    SET GUI:STYLE:BORDER:TOP TO 5.
    SET GUI:STYLE:BORDER:BOTTOM TO 5.
    SET GUI:STYLE:BORDER:H TO 10.
    SET GUI:STYLE:BORDER:V TO 10.

    LOCAL openButton IS gui:ADDBUTTON("MC").

    SET openButton:STYLE:WIDTH TO 43.
    SET openButton:STYLE:HEIGHT TO 43.

    gui:SHOW().

    LOCAL opened IS FALSE.

    SET openButton:ONCLICK to {SET opened TO TRUE.}.
    wait until opened.

    gui:HIDE().

    openMissionControl().
}