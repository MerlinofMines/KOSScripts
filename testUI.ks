RUNONCEPATH("0:/missionControl/missionControl.ks").

CLEARSCREEN.
openMissionControl().

//LOCAL testCall IS testPrint@.
//
//LOCAL test1 IS testCall:bind("Test 1").
//LOCAL test2 IS testCall:bind("Test 2").
//
//testCall("Test None").
//test1().
//test2().

function testPrint {
	parameter title.
	PRINT "Printing: " + title.
}
