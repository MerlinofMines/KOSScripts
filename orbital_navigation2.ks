RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/flight.ks").
RUNONCEPATH("0:/control.ks").

SAS OFF.

SET pitchMovement TO PIDLoop(0.05, 0, 1, -1, 1).
SET yawMovement TO PIDLoop(0.05, 0, 1, -1, 1).
SET rollMovement TO PIDLoop(0.02, 0, 1, -1, 1).

SET refreshInterval TO 0.001.

//Pitch, yaw, roll
SET desiredDirection TO R(0, 90, -90).

CLEARVECDRAWS().

UNTIL FALSE {

	CLEARSCREEN.

	//Current Facing Information
	LOCAL navball IS navball_direction(SHIP).
	LOCAL currentROLL IS navball:ROLL.
    LOCAL cosRoll IS cos(currentRoll).
    LOCAL sinRoll IS sin(currentRoll).  
	Print "Ship Navball Direction: " + navball_direction(SHIP).

	SET foreArrow TO VECDRAW(V(0,0,0), SHIP:FACING:FOREVECTOR*30, RGB(1,0,0),"F",1.0, TRUE, 0.2).
	SET starArrow TO VECDRAW(V(0,0,0), SHIP:FACING:STARVECTOR*30, RGB(0,1,0),"S",1.0, TRUE, 0.2).
	SET topArrow TO VECDRAW(V(0,0,0), SHIP:FACING:TOPVECTOR*30, RGB(0,0,1),"T",1.0, TRUE, 0.2).
//	SET upArrow TO VECDRAW(OFFSET, SHIP:UP:FOREVECTOR, RGB(1,1,0),"U", 1.0, TRUE, 0.2).

	//Calculate the desired heading based on the desired navball direction.
	SET headingDirection TO heading_direction(desiredDirection).	

	SET foreArrow2 TO VECDRAW(V(0,0,0), headingDirection:FOREVECTOR*30, RGB(1,0,0),"DF",1.0, TRUE, 0.2).
	SET starArrow2 TO VECDRAW(V(0,0,0), headingDirection:STARVECTOR*30, RGB(0,1,0),"DS",1.0, TRUE, 0.2).
	SET topArrow2 TO VECDRAW(V(0,0,0), headingDirection:TOPVECTOR*30, RGB(0,0,1),"DT",1.0, TRUE, 0.2).


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

//	PRINT "Calculated Pitch Distance: " + pitchDistance.
	PRINT "Calculated Yaw Distance: " + yawDistance.
// 	PRINT "Calculated Roll Distance: " + rollDistance.

	//Pass the distances to the movement PIDLoops.
	LOCAL pitchChange IS -pitchMovement:UPDATE(TIME:SECONDS, pitchDistance).// * 360.
	LOCAL yawChange IS -yawMovement:UPDATE(TIME:SECONDS, yawDistance).// * 360.
	LOCAL rollChange IS rollMovement:UPDATE(TIME:SECONDS, rollDistance).// * 100.

	PRINT "Pitch Change: " + pitchChange.
	PRINT "Yaw Change: " + yawChange.
	PRINT "Roll Change: " + rollChange.

	LOCAL desiredControl IS R(pitchChange, yawChange, rollChange).

	//Set control, with overrides from pilot input.
	setRawControl(desiredControl).

  	SET previousNavball TO navball.

  	WAIT refreshInterval.
}

//Calculate the "roll degrees" which need to be moved.  This is based on the calculated roll degree
//distance assuming the craft rotated it's facing ForeVector to point at headingDirection:Forevector
//without making any roll adjustment.  This allows us to predict the needed change in roll before
//we've arrived at our final heading, so that we can pre-emptively start rolling.
//This calculation allows for a smooth transition from the current heading to desired heading, allowing
//the change in yaw, change in pitch, and change in roll to happen as one uniform motion.
//Note that you cannot simply use the "navball" roll as a guide for orienting the craft, as the "roll"
//of the craft varies dramatically based on pitch when moving between more extreme latitudes and longitudes.
//Input to this function is the actual Direction object (not navball!).
//Use heading_direction(navballDirection) to convert if needed.
function desiredRollChange {
	parameter headingDirection.	

	LOCAL normalVector TO VECTORCROSSPRODUCT(SHIP:FACING:FOREVECTOR, headingDirection:FOREVECTOR):NORMALIZED.
	LOCAL normalDegrees TO VANG(SHIP:FACING:FOREVECTOR, headingDirection:FOREVECTOR).
	LOCAL calculatedDirection TO ANGLEAXIS(normalDegrees, normalVector) * SHIP:FACING.
	LOCAL calcNormal TO VECTORCROSSPRODUCT(calculatedDirection:STARVECTOR, headingDirection:STARVECTOR):NORMALIZED.
	LOCAL rollDegrees TO VANG(calculatedDirection:STARVECTOR, headingDirection:STARVECTOR).

	if(VANG(calcNormal, calculatedDirection:FOREVECTOR) > 90) {
		SET rollDegrees TO -rollDegrees. 
	}

	//If we're far from our heading, roll is really painful, and changes drastically.  Better to not start rolling until we're near our target.
	if(VANG(headingDirection:FOREVECTOR, SHIP:FACING:FOREVECTOR) > 90) {
		SET rollDegrees TO 0.
	}

//	Print "Roll Degrees Off: " + rollDegrees.

//	Print "normalDegrees: " + normalDegrees.

//	SET normalVecctor TO VECDRAW(V(0,0,0), calcNormal*30, RGB(1,1,0),"N",1.0,TRUE,0.2).

//	SET foreArrow3 TO VECDRAW(V(0,0,0), calculatedDirection:FOREVECTOR*30, RGB(1,0,0),"CF",1.0, TRUE, 0.2).
//	SET starArrow3 TO VECDRAW(V(0,0,0), calculatedDirection:STARVECTOR*30, RGB(0,1,0),"CS",1.0, TRUE, 0.2).
//	SET topArrow3 TO VECDRAW(V(0,0,0), calculatedDirection:TOPVECTOR*30, RGB(0,0,1),"CT",1.0, TRUE, 0.2).

	return rollDegrees.
}


//Calculate the heading direction for the given navball direction.
function heading_direction {
	parameter navballDirection.

	LOCAL headingDirection TO HEADING(navballDirection:YAW, navballDirection:PITCH).
	LOCAL headingDirection TO ANGLEAXIS(-navballDirection:ROLL, headingDirection:FOREVECTOR) * headingDirection.

	return headingDirection.
}

//use to find the initial bearing for the shortest path around a sphere from...
function circle_bearing {
 parameter
  p1, //...this point...
  p2. //...to this point.

 return mod(360+arctan2(sin(p2:lng-p1:lng)*cos(p2:lat),cos(p1:lat)*sin(p2:lat)-sin(p1:lat)*cos(p2:lat)*cos(p2:lng-p1:lng)),360).
}.

//use to find the distance from...
function circle_distance {
 parameter
  p1,     //...this point...
  p2,     //...to this point...
  radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
  return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.