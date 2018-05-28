RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/control.ks").

SAS OFF.

SET pitchStability TO PIDLoop(0.2, 0, 0.001, -1, 1).
SET yawStability TO PIDLoop(0.2, 0, 0.001, -1, 1).
SET rollStability TO PIDLoop(0.2, 0, 0.001, -1, 1).

SET pitchMovement TO PIDLoop(0.04, 0, 0.2, -1, 1).
SET yawMovement TO PIDLoop(0.04, 0, 0.2, -1, 1).
SET rollMovement TO PIDLoop(0.02, 0, 0.1, -1, 1).

function resetHoldDesiredDirection {
	//Stability
	pitchStability:RESET().
	yawStability:RESET().
	rollStability:RESET().

	//Movement
	pitchStability:RESET().
	yawStability:RESET().
	rollStability:RESET().
}

function holdDesiredDirection {
	parameter desiredDirection.

	SET previousRCS TO RCS.
//	RCS OFF.

	//Current Facing Information
	LOCAL navball IS navball_direction(SHIP).
	LOCAL currentROLL IS navball:ROLL.
    LOCAL cosRoll IS cos(currentRoll).
    LOCAL sinRoll IS sin(currentRoll).  
//	Print "Ship Navball Direction: " + navball_direction(SHIP).

//	SET foreArrow TO VECDRAW(V(0,0,0), SHIP:FACING:FOREVECTOR*30, RGB(1,0,0),"F",1.0, TRUE, 0.2).
//	SET starArrow TO VECDRAW(V(0,0,0), SHIP:FACING:STARVECTOR*30, RGB(0,1,0),"S",1.0, TRUE, 0.2).
//	SET topArrow TO VECDRAW(V(0,0,0), SHIP:FACING:TOPVECTOR*30, RGB(0,0,1),"T",1.0, TRUE, 0.2).
//	SET upArrow TO VECDRAW(OFFSET, SHIP:UP:FOREVECTOR, RGB(1,1,0),"U", 1.0, TRUE, 0.2).

	//Calculate the desired heading based on the desired navball direction.
	SET headingDirection TO heading_direction(desiredDirection).	

//	SET foreArrow2 TO VECDRAW(V(0,0,0), headingDirection:FOREVECTOR*30, RGB(1,0,0),"DF",1.0, TRUE, 0.2).
//	SET starArrow2 TO VECDRAW(V(0,0,0), headingDirection:STARVECTOR*30, RGB(0,1,0),"DS",1.0, TRUE, 0.2).
//	SET topArrow2 TO VECDRAW(V(0,0,0), headingDirection:TOPVECTOR*30, RGB(0,0,1),"DT",1.0, TRUE, 0.2).

	//Calculate the distance and direction of shortest path to desired direction.
	SET currentNav TO LATLNG(navball:PITCH, navball:YAW).
	SET desiredNav TO LATLNG(desiredDirection:PITCH, desiredDirection:YAW).

	SET directionAngle TO circle_bearing(currentNav, desiredNav).
	SET bearing TO degreeDelta(directionAngle, currentROLL).
	SET distance TO circle_distance(currentNav, desiredNav, 10).

//	Print "Direction Angle: " + directionAngle.
//	Print "Bearing: " + bearing.
//	Print "Distance: " + distance.

	//Based on the current bearing to desired heading, calculate the "pitch", "yaw" and "roll" distance.
	//This converts the real pitch and yaw distance to the ship oriented pitch and yaw distance.  It also
	//calculates the roll distance by predicting the needed roll change assuming the craft was already pointed
	//at the desired heading.
	local pitchDistance IS distance * cos(bearing).
	local yawDistance IS distance * sin(bearing).
	local rollDistance TO desiredRollChange(headingDirection).

    //If we're far from our heading, roll is really painful, and changes drastically.  Better to not start rolling until we're near our target.
    if(VANG(headingDirection:FOREVECTOR, SHIP:FACING:FOREVECTOR) > 90) {
      SET rollDistance TO 0.
    }

//	PRINT "Calculated Pitch Distance: " + pitchDistance.
//	PRINT "Calculated Yaw Distance: " + yawDistance.
// 	PRINT "Calculated Roll Distance: " + rollDistance.

	//Pass the distances to the movement PIDLoops.
	LOCAL pitchChange IS -pitchMovement:UPDATE(TIME:SECONDS, pitchDistance) * 360.
	LOCAL yawChange IS -yawMovement:UPDATE(TIME:SECONDS, yawDistance) * 360.
	LOCAL rollChange IS rollMovement:UPDATE(TIME:SECONDS, rollDistance) * 100.

	LOCAL angularMomentum IS getAngularMomentum().

//	PRINT "Pitch Change: " + pitchChange.
//	PRINT "Yaw Change: " + yawChange.
//	PRINT "Roll Change: " + rollChange.

	SET pitchStability:SETPOINT TO pitchChange.
	SET yawStability:SETPOINT TO yawChange.
	SET rollStability:SETPOINT TO rollChange.

//	Print "Pitch SetPoint: " + pitchStability:SETPOINT.
//	Print "Yaw SetPoint: " + yawStability:SETPOINT.
//	Print "Roll SetPoint: " + rollStability:SETPOINT.

	LOCAL pMChange IS pitchStability:UPDATE(TIME:SECONDS, angularMomentum:PITCH).
	LOCAL yMChange IS yawStability:UPDATE(TIME:SECONDS, angularMomentum:YAW).
	LOCAL rMChange IS rollStability:UPDATE(TIME:SECONDS, angularMomentum:ROLL).

//	PRINT "Pitch M Change: " + pMChange.
//	PRINT "Yaw M Change: " + yMChange.
//	PRINT "Roll M Change: " + rMChange.

	LOCAL desiredControl IS R(pMChange, yMChange, rMChange).

	//Set control, with overrides from pilot input.
	setRawControl(desiredControl).

  	SET previousNavball TO navball.

  	if(previousRCS) {
	  	RCS ON.  	
  	}
}