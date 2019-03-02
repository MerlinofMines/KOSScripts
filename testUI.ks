CLEARSCREEN.

RUNPATH("0:/missionControl/missionControl.ks").
startMissionControl().

function engineTest {
	SET isLaunchClicked TO FALSE.

	LOCAL gui IS GUI(800,800).

	LOCAL layout IS gui:ADDHLAYOUT().

	engineChoicePanel(layout).
	engineChoicePanel(layout).
	engineChoicePanel(layout).

	LOCAL launchButton IS gui:ADDBUTTON("Launch Mission").

	gui:SHOW().

	SET launchButton:ONCLICK to launchClickChecker@.
	wait until isLaunchClicked.
	gui:HIDE().

	PRINT "Mission Completed Successfully.".
}

//TODO: Generic way to create a click button checker.
function launchClickChecker {
	SET isLaunchClicked TO TRUE.
}








