//This function takes a controlDirection to set the pitch, yaw and roll controls of the aircraft, taking into account pilot input.
//This function effectively allows you to "set the control" while still obeying manual input from keyboard or joystick, similar to SAS operation in stock KSP.
function setRawControl {
	parameter controlDirection.

	//    PRINT "PILOT PITCH: " + SHIP:CONTROL:PILOTPITCH.
	//    PRINT "PILOT YAW: " + SHIP:CONTROL:PILOTYAW.
	//    PRINT "PILOT ROLL: " + SHIP:CONTROL:PILOTROLL.

	//Override with manual control when necessary.  "Take the wheel johnny!".
	if (abs(SHIP:CONTROL:PILOTPITCH) > 0.001) {
		SET SHIP:CONTROL:PITCH TO SHIP:CONTROL:PILOTPITCH.
	} else {
		SET SHIP:CONTROL:PITCH to controlDirection:PITCH.
	}

	if (abs(SHIP:CONTROL:PILOTYAW) > 0.001) {
		SET SHIP:CONTROL:YAW TO SHIP:CONTROL:PILOTYAW.
	} else {
		SET SHIP:CONTROL:YAW TO controlDirection:YAW.
	} 

	if (abs(SHIP:CONTROL:PILOTROLL) > 0.001) {
		SET SHIP:CONTROL:ROLL TO SHIP:CONTROL:PILOTROLL.
	} else {
		SET SHIP:CONTROL:ROLL TO controlDirection:ROLL.
	}
}