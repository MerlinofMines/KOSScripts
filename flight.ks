RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/control.ks").

SAS OFF.

SET pitchStability TO PIDLoop(0.02, 0.00, 0.005, -1, 1).
SET yawStability TO PIDLoop(0.02, 0.00, 0.005, -1, 1).
SET rollStability TO PIDLoop(0.02, 0.00, 0.005, -1, 1).

SET pitchMovement TO PIDLoop(0.03, 0.001, 0.03, -1, 1).
SET yawMovement TO PIDLoop(0.01, 0.001, 0.03, -1, 1).
SET rollMovement TO PIDLoop(0.01, 0.001, 0.03, -1, 1).

SET refreshInterval TO 0.03.

SET previousTime TO TIME:SECONDS.

//SET STEERINGMANAGER:SHOWSTEERINGSTATS TO TRUE.

//SET STEERINGMANAGER:PITCHTS TO 1.

//LOCK STEERING TO getRunwayHeadingDirection().

SET deployGEAR TO TRUE.

SET previousFacing TO navball_direction(SHIP, SHIP:FACING).

//Cooked Steering Solution
//UNTIL FALSE {
//	CLEARSCREEN.
//	CLEARVECDRAWS().

//	PRINT "Torque Adjust: " + SteeringManager:PITCHTORQUEADJUST.
//	Print "Pitch Settling Time: " + SteeringManager:PITCHTS.

//	SET runwayDirection TO getRunwayHeadingDirection.	

//	drawDirection(runwayDirection, "Runway").
//	drawDirection(SHIP:FACING, "Facing").
//	drawDirection(SHIP:SRFPROGRADE, "Prograde").
//	drawDirection(SteeringManager:TARGET, "Steering").

//	if(deployGear AND SHIP:AIRSPEED < 150) {
//		GEAR ON.
//		BRAKES ON.
//		SET deployGEAR TO FALSE.
//	}
//}

//Row Control Solution
UNTIL FALSE {
	CLEARSCREEN.
	CLEARVECDRAWS().

	//Calculate the desired heading based on the desired navball direction.


//	LOCAL desiredRoll IS getDesiredRoll().

	//1.
	//Calculate the desired heading based on the desired navball direction.
	SET runwayDirection TO getRunwayDirection().
	SET headingDirection TO heading_direction(runwayDirection).	

	//2.
	SET surfacePrograde TO SHIP:SRFPROGRADE.
	SET navballPrograde TO navball_direction(SHIP, surfacePrograde).

	//3. 	
	SET myFacing TO SHIP:FACING.
	SET navballFacing TO navball_direction(SHIP, myFacing).

	//4.  TODO: ROLL SHOULD BE CALCULATED BASED ON bearing from prograde to runway.
	SET desiredDirection TO oriented_navball_delta(navballFacing, runwayDirection).
//	SET desiredDirection TO navball_delta(navballFacing, runwayDirection).

	Print "Desired Direction: " + desiredDirection.
//	drawNavballDirection(desiredDirection, "Desired").

//	drawDirection(headingDirection,"Runway").
//	drawDirection(myFacing, "Facing").
//	drawDirection(surfacePrograde, "Prograde").

	drawNavballDirection(runwayDirection, "Runway").
//	drawNavballDirection(navballFacing, "Facing").
	drawNavballDirection(navballPrograde, "Prograde").
//	drawNavballDirection(desiredDirection, "Desired").

	SET pitchChange TO clamp(desiredDirection:PITCH * 20, -300, 300).
	SET yawChange TO clamp(desiredDirection:YAW * 5, -100, 100).
	SET rollChange TO clamp(desiredDirection:ROLL * 5, -100, 100).

	//Pass the distances to the movement PIDLoops.
//	LOCAL pitchChange IS pitchMovement:UPDATE(TIME:SECONDS, desiredDirection:PITCH) * 360.
//	LOCAL yawChange IS yawMovement:UPDATE(TIME:SECONDS, desiredDirection:YAW) * 360.
//	LOCAL rollChange IS rollMovement:UPDATE(TIME:SECONDS, desiredDirection:ROLL) * 360.

	PRINT "Pitch Change: " + pitchChange.
	PRINT "Yaw Change: " + yawChange.
	PRINT "Roll Change: " + rollChange.

	SET pitchStability:SETPOINT TO pitchChange.
	SET yawStability:SETPOINT TO yawChange.
	SET rollStability:SETPOINT TO rollChange.

//	Print "Pitch SetPoint: " + pitchStability:SETPOINT.
//	Print "Yaw SetPoint: " + yawStability:SETPOINT.
//	Print "Roll SetPoint: " + rollStability:SETPOINT.

	LOCAL angularMomentum IS getAngularMomentum().
	PRINT "Angular Momentum: " + angularMomentum.

	LOCAL pMChange IS pitchStability:UPDATE(TIME:SECONDS, angularMomentum:PITCH).
	LOCAL yMChange IS yawStability:UPDATE(TIME:SECONDS, angularMomentum:YAW).
	LOCAL rMChange IS rollStability:UPDATE(TIME:SECONDS, angularMomentum:ROLL).

//	PRINT "Pitch M Change: " + pMChange.
//	PRINT "Yaw M Change: " + yMChange.
//	PRINT "Roll M Change: " + rMChange.

	LOCAL desiredMomentum IS R(angularMomentum:PITCH + pitchChange,
							   angularMomentum:YAW + yawChange,
							   angularMomentum:ROLL + rollChange).

	LOCAL desiredControl IS R(pMChange * MIN(1, abs(desiredMomentum:PITCH) / 100),
							  yMChange * MIN(1, abs(desiredMomentum:YAW) / 200),
							  rMChange * MIN(1, abs(desiredMomentum:ROLL) / 200)).

	//Set control, with overrides from pilot input.
	setRawControl(desiredControl).

  	WAIT refreshInterval.
}

//This function uses the current prograde and desired prograde to determine a "bearing", which is then
//converted to a "roll" for the aircraft.  The intention is to allow us to use pitch to adjust our prograde most effectively (we want to keep our yaw momentum at a minimum and only use pitch / roll for controlling prograde, as this greatly adds stability of the aircraft and is far more efficient than yaw).
function getDesiredFacingNavballDirection {
	parameter progradeNavball.
	parameter desiredProgradeNavball.

	Print "Prograde Direction: " + progradeNavball.

	//Now the tricky part.  Let's treat the two directions (minus roll) as geocoordinates on a sphere, and use the two
	//to come up with a "bearing" between the two.  This bearing will serve as the basis for our roll angle.
	local progradeGEO IS LATLNG(progradeNavball:PITCH, progradeNavball:YAW).
	local desiredProgradeGEO IS LATLNG(desiredProgradeNavball:PITCH, desiredProgradeNavball:YAW).

	local closestBearing IS circle_bearing(progradeGEO, desiredProgradeGEO).
	local closestDistance IS circle_distance(progradeGEO, desiredProgradeGEO, 1).

	//Now let's munge a little.  if we're above then the roll is actually opposite, and our pitch will put us proper.

	Print "Original Bearing: " + closestBearing.

	if (closestBearing > 270) {
		SET closestBearing TO closestBearing - 360.
	} else if (closestBearing > 90) {
		SET closestBearing TO closestBearing - 180.
	}

	SET closestBearing TO MIN(MAX(-30, closestBearing),30).

	PRINT "Closest Bearing: " + closestBearing.
	PRINT "Closet Distance: " + closestDistance.

	return closestBearing.


	return desiredNavballFacingDirection.
}

function getRunwayHeadingDirection {
	return heading_direction(getRunwayDirection()).	
}

//Not actually returning the direction, we are manipulating.
function getRunwayDirection {
	return getLatLongDirection(RUNWAY_EAST_COORDINATES).
}

//Returns the navball direction of a given set of GeoCoordinates.
function getLatLongDirection {
	parameter coordinates.
	local geoHeading IS coordinates:HEADING.
	
	//Let's calculate the angle using the distance and altitude difference (90 - arcsin()).
	local geoDistance IS coordinates:DISTANCE.

	local myAltitude IS ALT:RADAR.
	local runwayAltitude IS coordinates:TERRAINHEIGHT + 100.

	local height IS (runwayAltitude - myAltitude) * 1.62. //(we want this to be negative).

	local pitchAngle IS arcsin(height/geoDistance). // opposite (height) over hypotinuse (distance) should give us the angle.

	LOCAL geoNavballDirection IS R(pitchAngle, geoHeading, 0). //pitch, yaw, roll

	return geoNavballDirection.
}

//This function calculates the navball delta (in degrees) between the given source direction (starting direction) and 
//the given destination (target direction) factoring in the current roll and the desired roll.  This is different than the raw
//navball_delta, which does not take the source direction's current roll into account when calculating the yaw and pitch delta.
function oriented_navball_delta {
	parameter sourceNavballDirection.
	parameter destinationNavballDirection.

	//Current Facing Information
	LOCAL currentROLL IS sourceNavballDirection:ROLL.
    LOCAL cosRoll IS cos(currentRoll).
    LOCAL sinRoll IS sin(currentRoll).  

	//Calculate the desired heading based on the desired navball direction.
	SET headingDirection TO heading_direction(destinationNavballDirection).	

	//Calculate the distance and direction of shortest path to desired direction.
	SET currentNav TO LATLNG(sourceNavballDirection:PITCH, sourceNavballDirection:YAW).
	SET desiredNav TO LATLNG(destinationNavballDirection:PITCH, destinationNavballDirection:YAW).

	SET directionAngle TO circle_bearing(currentNav, desiredNav).
	SET bearing TO degreeDelta(directionAngle, currentROLL).
	SET distance TO circle_distance(currentNav, desiredNav, 10).

	Print "Direction Angle: " + directionAngle.
	Print "Bearing: " + bearing.
	Print "Distance: " + distance.

	//Based on the current bearing to desired heading, calculate the "pitch", "yaw" and "roll" distance.
	//This converts the real pitch and yaw distance to the ship oriented pitch and yaw distance.  It also
	//calculates the roll distance by predicting the needed roll change assuming the craft was already pointed
	//at the desired heading.
	local pitchDistance IS distance * cos(bearing).
	local yawDistance IS distance * sin(bearing).
	local rollDistance TO desiredRollChange(headingDirection).

	PRINT "Calculated Pitch Distance: " + pitchDistance.
	PRINT "Calculated Yaw Distance: " + yawDistance.
 	PRINT "Calculated Roll Distance: " + rollDistance.

 	return R(pitchDistance, yawDistance, rollDistance).
}


function drawNavballDirection {
	parameter navballDirection.
	parameter label.
	drawDirection(heading_direction(navballDirection), label).	
}

function drawDirection {
	parameter direction.
	parameter label.

	LOCAL runwayForeVector TO VECDRAW(V(0,0,0), direction:FOREVECTOR*30, RGB(1,0,0),label + ".F",1.0, TRUE, 0.2).
	LOCAL runwayStarVector TO VECDRAW(V(0,0,0), direction:STARVECTOR*30, RGB(0,1,0),label + ".S",1.0, TRUE, 0.2).
//	LOCAL runwayTopVector TO VECDRAW(V(0,0,0), direction:TOPVECTOR*30, RGB(0,0,1),label + ".T",1.0, TRUE, 0.2).
}