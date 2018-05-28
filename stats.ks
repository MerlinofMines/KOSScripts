calculateAnticipatedFacingDelta().
//calculateMomentumDegreeChangeConstant().
UNTIL FALSE {
	
	LOCAl angVel IS SHIP:ANGULARVEL.

	PRINT("Angular Velocity: " + angVel).

//	  SET mom TO SHIP:ANGULARMOMENTUM.
//	  SET myFacing TO SHIP:FACING.

//	  Print "Facing: " + myFacing.

//    PRINT "Longitude: " + LONGITUDE.
//    PRINT "Latitude: " + LATITUDE.
//    PRINT "Roll: " + SHIP:FACING:TOPVECTOR:Y.
//    PRINT "FACING: " + myFacing.

//	  PRINT "Pitch: " + myFacing:YAW.
//	  PRINT "Yaw: " + myFacing:PITCH.
//	  PRINT "Roll: " + myFacing:ROLL.

//    PRINT "Compass: " + compass.
//    Print "Pitch: " + pitch.
//    Print "Yaw: " + east_for(SHIP).
//    Print "Roll: " + roll.
//    Print "Vang: " + vang(R(pitch,compass,roll):FOREVECTOR, R(20,90,0):FOREVECTOR).
//    Print "Heading: " + myHeading.

//    PRINT "Pitch Momentum: " + -mom:X.
//    PRINT "Pitch Momentum Change: " + (mom:X - prevMom:X).
//    PRINT "Pitch Change: " + degreeDelta(myFacing:YAW, prevFacing:YAW).
//    IF(abs(degreeDelta(myFacing:YAW, prevFacing:YAW)) > 0) {
//	    PRINT "Pitch / Momentum: " + abs(mom:X / degreeDelta(myFacing:YAW, prevFacing:YAW)).
//    } ELSE {
//    	PRINT "Pitch / Momentum: 0".
//    }
//    PRINT "Yaw Momentum: " + -mom:Z.
//    PRINT "Yaw Momentum Change: " + (mom:Z - prevMom:Z).
//    PRINT "Yaw Change: " + degreeDelta(myFacing:PITCH, prevFacing:PITCH).
//    IF(abs(myFacing:PITCH - prevFacing:PITCH) > 0) {
//	    PRINT "Yaw / Momentum: " + abs(mom:Z / degreeDelta(myFacing:PITCH, prevFacing:PITCH)).
//    } ELSE {
//    	PRINT "Yaw / Momentum: 0".
//    }
//    PRINT "Roll Momentum: " + -mom:Y.
//    PRINT "Roll Momentum Change: " + (mom:Y - prevMom:Y).
//    PRINT "Roll Change: " + -degreeDelta(myFacing:ROLL, prevFacing:ROLL).
//    IF(abs(degreeDelta(myFacing:ROLL, prevFacing:ROLL)) > 0) {
//	    PRINT "Roll / Momentum: " + abs(mom:Y / degreeDelta(myFacing:ROLL, prevFacing:ROLL)).
//    } ELSE {
//    	PRINT "Roll / Momentum: 0".
//    }

//    pointAt(90, 20).
}

function calculateAnticipatedFacingDelta {
	SET refreshInterval TO 0.3.

	SET prevFacing TO SHIP:FACING.

	UNTIL FALSE {
		
		SET expectedDelta TO anticipatedFacingDelta(refreshInterval).
		SET expectedDirection TO getAdjustedFacingDirection(prevFacing, expectedDelta).
	    SET prevMom to correctAngMom.

	    WAIT refreshInterval.
	    CLEARSCREEN.

	    SET newMom to correctAngMom.

	    PRINT "Pitch Momentum: " + newMom:X.
	    PRINT "Yaw Momentum: " + newMom:Y.
	    PRINT "Roll Momentum: " + newMom:Z.

	    PRINT "Pitch Momentum Change: " + (newMom:X - prevMom:X).
	    PRINT "Yaw Momentum Change: " + (newMom:Y - prevMom:Y).
	    PRINT "Roll Momentum Change: " + (newMom:Z - prevMom:Z).

		SET facing TO SHIP:FACING.

	    //Determine facing delta
	    SET myFacingDelta TO facingDelta(prevFacing).
	    SET calculatedDirection TO getAdjustedFacingDirection(prevFacing, myFacingDelta).

	    //Print Facing Delta
	    PRINT "Pitch Delta:          " + myFacingDelta:X. 	
	    PRINT "Expected Pitch Delta: " + expectedDelta:X.
	    PRINT "Yaw Delta:            " + myFacingDelta:Y. 
	    PRINT "Expected Yaw Delta:   " + expectedDelta:Y.
	    PRINT "Roll Delta:           " + myFacingDelta:Z.
	    PRINT "Expected Roll Delta:   " + expectedDelta:Z.

		//Print Direction
		PRINT "Pitch:          " + facing:PITCH.
		PRINT "Calced Pitch:   " + calculatedDirection:PITCH.
		PRINT "Expected Pitch: " + expectedDirection:PITCH.
		PRINT "Yaw:            " + facing:YAW.
		PRINT "Calced Yaw:     " + calculatedDirection:YAW.
		PRINT "Expected Yaw:   " + expectedDirection:YAW.
		PRINT "Roll:           " + facing:ROLL.
		PRINT "Calced Roll:    " + calculatedDirection:ROLL.
		PRINT "Expected Roll:  " + expectedDirection:ROLL.

	    SET prevFacing TO facing.

//	    LOCAL expectedDirection TO calculateFinalDirection().

//	    SET myMom to correctAngMom.
//	    Print "----------------------".
//	    Print "Momentum: " + myMom.
//	    Print "Expected Final Pitch : " + expectedDirection:PITCH.
//	    Print "Expected Final Yaw   : " + expectedDirection:YAW.
//	    Print "Expected Final Roll  : " + expectedDirection:ROLL.
	}
}

function calculateMomentumDegreeChangeConstant {

	local refreshInterval TO 0.1.

      SET prevFacing TO SHIP:FACING.
	  SET prevMom TO correctAngMom.


	UNTIL FALSE {
	  WAIT refreshInterval.
	  CLEARSCREEN.

	  SET facing TO SHIP:FACING.
	  SET mom TO correctAngMom.

	    //Determine facing delta
	    SET pitchDelta TO degreeDelta(facing:YAW, prevFacing:YAW).//In terms of control, directions yaw is actually "Pitch".
	    SET yawDelta TO degreeDelta(facing:PITCH, prevFacing:PITCH). //In terms of control, directions pitch is actually "Yaw".
	    SET rollDelta TO -degreeDelta(facing:ROLL, prevFacing:ROLL). //Roll is negative, go figure.

	    //Print Facing Delta
	    PRINT "Pitch Delta: " + pitchDelta. 
	    PRINT "Yaw Delta: " + yawDelta. 
	    PRINT "Roll Delta: " + rollDelta.

	    //Print Momentum 
	    PRINT "Pitch Momentum: " + mom:X.
	    PRINT "Yaw Momentum: " + mom:Y.
	    PRINT "Roll Momentum: " + mom:Z.


	    //Determine momentum -> degree conversion constants.
	    Set pitchConstant TO 1 / ((pitchDelta / mom:X) / refreshInterval).
	    Set yawConstant TO 1 / ((yawDelta / mom:X) / refreshInterval).
	    Set rollConstant TO 1 / ((rollDelta / mom:X) / refreshInterval).

	    //****** THIS IS THE IMPORTANT BIT*****//
	    //Pitch Constant - 860.
	    //Yaw Constant - 1080.
	    //Roll Constant - 240.

	    //Print constants 
	    PRINT "Pitch Constant: " + pitchConstant.
	    PRINT "Yaw Constant: " + yawConstant.
	    PRINT "Roll Constant: " + rollConstant.

	    //Reset previous values for next iteration.
	    SET prevFacing TO facing.
	    SET prevMom To mom.
	}
}

//Why not pass in direction?  Well, as the craft orbits a body, the heading for "pitch above horizon" is constantly changing.
//It makes more sense to re-calculate the new heading each iteration, ensure that we are still on target as we orbit the body.
function pointAt {

    Parameter degreesFromNorth.
    Parameter pitchAboveHorizon.
    Parameter tolerance IS 0.25.

    SET refreshInterval To 0.1. //100 ms.

    //Represents the maximum torque (estimate) for Merlin Mark 2, at full raw input (pitch/yaw/roll).
    SET myTorque TO torqueConstants.

    //Rough translation of angular momentum amount per degree change.
    SET myMomentumDegrees to momentumConstants.

    //Setup
//    SET currentPitch to SHIP:CONTROL:PITCH.
//    SET currentYaw to SHIP:CONTROL:YAW.
//    SET currentRoll to SHIP:CONTROL:ROLL.
//    SET currentMom TO SHIP:ANGULARMOMENTUM.
//    SET momChange TO V(0,0,0).
//    SET refreshInterval to 0.05. // 50ms.
//    SET pitchChange to 0.
//    SET yawChange to 0.
//    SET rollChange to 0.

	//TODO: Until tolerance for direction AND momentum are met.
	UNTIL FALSE {

		//Calculate newHeading based on requested degreesFromNorth & pitchAboveHorizon).
    	SET newHeading TO HEADING(degreesFromNorth, pitchAboveHorizon).

		//Determine delta between current direction and newHeading.
		SET deltaDirection TO facingDelta(SHIP:FACING, newHeading).

		//Determine ships current momentum, with corrected units for pitch, yaw & roll.
		SET myMomentum TO correctMomentum().

		//Determine the expected direction change of ship after refreshInterval based on momentum.
		SET momentumDirectionDelta TO anticipatedFacingDelta(refreshInterval).

		//Assuming we executed a "full stop" to halt our angular momentum, where would we end up?  Note
		//that this is best effort..if the craft is spinning rapidly, this estimate will be off.  
		//That's OK, as we iterate, we'll gradually get our roll correct and halted, and the estimate will improve.



//		SET expectedEndDirection TO momentumDirectionDelta*


		//What should our momentum be to get us exactly where we wanted?

		//Ok, so we have our momentum, and our needed momentum. Calculate needed momentum Delta vector, taking into account the
		//current orientation of the craft.  (If your sideways and need to increase pitch momentum, that means you actually need to make a change to yaw Momentum, and the available torque for Yaw may be different than for pitch).


		//Now that we have the needed change in momentum along our crafts axes, we can set the raw controls based on the available torque for those axes.  Calculate needed raw controls.


		//Set raw controls.


		//Wait & repeat.
		WAIT refreshInterval.
	}

    //Determine pitch delta to target
    SET pitchDelta TO degreeDelta(myHeading:YAW, facing:YAW).//In terms of control, directions yaw is actually "Pitch".
    SET yawDelta TO degreeDelta(myHeading:PITCH, facing:PITCH). //In terms of control, directions pitch is actually "Yaw".
    SET rollDelta TO -degreeDelta(myHeading:ROLL, facing:ROLL). //Roll is negative, go figure.

//    PRINT "Pitch Delta: " + pitchDelta. 
//    PRINT "Yaw Delta: " + yawDelta. 
//    PRINT "Roll Delta: " + rollDelta.

    //Get current rotation based on momentum
    Set pitchMomDeg TO (currentMom:X / degreesPerMomentum:X) * refreshInterval.
    Set yawMomDeg TO (currentMom:Y / degreesPerMomentum:Y) * refreshInterval.
    Set rollMomDeg TO (currentMom:Z / degreesPerMomentum:Z) * refreshInterval.

//    Print "Pitch Momentum (deg): " + -pitchMomDeg.
//    Print "Yaw Momentum (deg): " + yawMomDeg.
//    Print "Roll Momentum (deg): " + rollMomDeg.




    IF(abs(pitchDelta) < 0.5) {
//    	Print "Pitch is Good.".
    } ELSE IF(pitchDelta > 0 ) {
//    	Print "Pitch Up".
//    	SET pitchChange TO 0.05 * cos(rollDelta).
    } ELSE {
//    	PRINT "Pitch Down.".
//    	SET pitchChange TO -0.05 * cos(rollDelta).
    }

    IF(abs(yawDelta) < 0.5) {
//    	Print "Yaw is Good.".
    } ELSE IF(yawDelta > 0) {
//    	Print "Yaw Right (" + yawDelta + ")".
//    	SET yawChange TO 0.05 * cos(rollDelta).
    } ELSE {
//    	PRINT "Yaw Left (" + yawDelta + ")". 
//    	SET yawChange TO -0.05 * cos(rollDelta).
    }

    IF(abs(rollDelta) < 0.05) {
//    	Print "Roll is Good.".
    } ELSE IF(rollDelta > 0) {
//    	PRINT "Roll Right.".
//    	SET rollChange TO 0.05.
    } ELSE {
//    	PRINT "Roll Left.".
//    	SET rollChange TO -0.5.
    }

    //Temporarily testing
    SET newPitch TO pitchChange.
    SET newYaw TO yawChange.
    SET newRoll TO rollChange.

    //Set Pitch
    SET SHIP:CONTROL:PITCH TO 0.
    SET currentPitch To newPitch.

    //Set Yaw
    SET SHIP:CONTROL:YAW TO 0.
    SET currentYaw To newYaw.

    //Set Roll
    SET SHIP:CONTROL:ROLL TO 0.
    SET currentRoll To newRoll.

//    WAIT refreshInterval.
}

//function is best estimate of the final direction of the craft, based on available torque and current momentum.
function calculateFinalDirection {
	Set refreshInterval to 0.5.

	//Get current momentum, torque and direction
	SET mom TO correctAngMom.
	SET initialDirection TO SHIP:FACING.
	SET direction TO SHIP:FACING.
	SET iterations TO 0.
	LOCAL currentRoll TO invertedRoll(direction:ROLL).

	UNTIL FALSE {
		SET iterations TO iterations + 1.
		//Get expected facing delta and new direction.
		LOCAL expectedDelta TO anticipatedFacingDelta(refreshInterval, mom, currentRoll).
		SET direction TO getAdjustedFacingDirection(direction, expectedDelta).

		//Calculate change in momentum assuming maximum torque is applied
		SET mom TO reverseTorque(mom, refreshInterval).

		if(ABS(mom:X) < 0.5 AND ABS(mom:Y) < 0.5) {
			BREAK.
		}
	}

	PRINT "Iterations: " + iterations.
	Print "Pitch Change: " + (direction:PITCH - initialDirection:PITCH).
	Print "Yaw Change: " + (direction:Yaw - initialDirection:Yaw).
	Print "Roll Change: " + (direction:Roll - initialDirection:Roll).

	return direction.
}

function reverseTorque {
	parameter correctMomentumVector.
	parameter duration.

	LOCAL torque TO torqueConstants() * duration.

	//Set the torque to the least of remaining momentum or available torque.
	LOCAL pitchTorque TO min(torque:X, abs(correctMomentumVector:X)).
	LOCAL yawTorque TO min(torque:Y, abs(correctMomentumVector:Y)).
	LOCAL rollTorque TO min(torque:Z, abs(correctMomentumVector:Z)).

	//Invert torque if momentum is in opposite direction.
	if (correctMomentumVector:X > 0) {
		SET pitchTorque TO -pitchTorque.
	}
	if (correctMomentumVector:Y > 0) {
		SET yawTorque to -yawTorque.
	}
	if (correctMomentumVector:Z > 0) {
		SET rollTorque to -rollTorque.
	}

	LOCAL torqueToApply TO V(pitchTorque, yawTorque, rollTorque).
	return applyTorque(correctMomentumVector, torqueToApply).
}

function applyTorque {
	parameter correctMomentumVector.
	parameter torqueVector.

	return V(correctMomentumVector:X + torqueVector:X,
			 correctMomentumVector:Y + torqueVector:Y,
			 correctMomentumVector:Z + torqueVector:Z).
}

//Calculates the anticipated facing delta, based on current ships orientation and momentum.
//Value is returned as a vector in the form V(Pitch, Yaw, Roll), where the components represent
//a change in degrees in that vector.  Works best when input secondsfromNow is small.
function anticipatedFacingDelta {
	parameter secondsFromNow.
	parameter mom IS correctAngMom.
	parameter currentRoll IS invertedRoll(facing:ROLL).

	SET myConstants TO momentumConstants.
//	Print "Raw Roll:          " + facing:ROLL.
//	Print "inverted roll:     " + currentRoll.
//	Print "inverted ^ 2 roll: " + invertedRoll(currentRoll).

	SET myCos TO cos(currentRoll).
	SET mySin TO sin(currentRoll).

	SET dP TO correctAngMom:X / (myConstants:X * secondsFromNow).
	SET dY TO correctAngMom:Y / (myConstants:Y * secondsFromNow).

	SET deltaPitch TO myCos * dP - mySin * dY.
	SET deltaYaw TO mySIN * dP + myCos * dY.
	SET deltaRoll TO correctAngMom:Z / (myConstants:Z * secondsFromNow).

	return V(deltaPitch, deltaYaw, deltaRoll).
}

//Angular momentum is bassackwards.
//This function returns the angular moment of the craft, relative to the orientation (UP) of the craft.
//+1 X is equivalent to rising pitch
//+1 Y is equivalent to nose moving right
//+1 Z is equivalent to rotating clockwise as observed when facing forward.
function correctAngMom {
	SET myAngMom To SHIP:ANGULARMOMENTUM.
	return V(-myAngMom:X, -myAngMom:Z, -myAngMom:Y).
}

function correctRoll {
	parameter facingDirection.
	//"Level when facing east should be 0 degrees"
	SET myCorrectRoll TO mod(630 - facingDirection:ROLL, 360).

	return myCorrectRoll.
}

//Represents the conversion of momentum units to degrees. (calculated through experimenation)
function momentumConstants {
	return V(860, 1080, 240).
}

//Represents the amount of change in angular momentum which can be exerted on the vessel. (calculated through experimentation)
function torqueConstants {
	return V(22.0, 20, 16.5).
}


//Calculates a new direction based on an input facing direction and facing delta.
//This function takes the heavy lifting out of applying a calculated facing delta
//to the direction represented in KOS, as there is a transform between pitch/yaw, and inversing the roll.
function getAdjustedFacingDirection {
	parameter facingDirection.
	parameter myFacingDelta.

	Set newPitch TO mod(facingDirection:PITCH + myFacingDelta:Y, 360). 
	Set newYaw TO mod(facingDirection:YAW + myFacingDelta:X, 360).
	Set newRoll TO mod(invertedRoll(invertedRoll(facingDirection:ROLL) + myFacingDelta:Z),360).

	return R(newPitch, newYaw, newRoll).
}

function facingDelta {
	parameter prevFacing.
	parameter newFacing IS SHIP:FACING.

    //Determine facing delta
    SET pitchDelta TO degreeDelta(newFacing:YAW, prevFacing:YAW).//In terms of control, directions yaw is actually "Pitch".
    SET yawDelta TO degreeDelta(newFacing:PITCH, prevFacing:PITCH). //In terms of control, directions pitch is actually "Yaw".
    SET rollDelta TO degreeDelta(invertedRoll(newFacing:ROLL), invertedRoll(prevFacing:ROLL)). //Need to get corrected Roll.

    return V(pitchDelta, yawDelta, rollDelta).

}

//"Roll" as calculated by by Facing:Roll is, well, difficult to use in calculations involving sin & cosine.
//This function takes the negative facing direction to invert axis, then adds 270 to recenter "level with horizon" at 0, then adds
//360 to remove any negative (original set went from 0 - 360, so it was possible to have -360 + 270 < 0), then mod 360 to remap
//back to degrees.
//invertedRoll(invertedRoll(roll)) = roll for all values 0 <= roll <= 360.
//This method acts as a conversion to and from.
function invertedRoll {
	parameter roll.
	SET newRoll TO mod(630 - roll, 360).

	return newRoll.
}

function degreeDelta {
    parameter destinationDegree.
    parameter sourceDegree.

    SET delta TO destinationDegree - sourceDegree.
    IF (delta < -180) {
        Set delta TO delta + 360.
    } ELSE IF (delta > 180) {
        SET delta TO delta - 360.
    }

    return delta.
}

function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}

function compass_for {
  parameter ves.

  local pointing is ves:facing:forevector.
  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}

function pitch_for {
  parameter ves.

  return 90 - vang(ves:up:vector, ves:facing:forevector).
}

function roll_for {
  parameter ves.
  
  if vang(ship:facing:vector,ship:up:vector) < 0.2 { //this is the dead zone for roll when the ship is vertical
    return 0.
  } else {
    local raw is vang(vxcl(ship:facing:vector,ship:up:vector), ves:facing:starvector).
    if vang(ves:up:vector, ves:facing:topvector) > 90 {
      if raw > 90 {
        return 270 - raw.
      } else {
        return -90 - raw.
      }
    } else {
      return raw - 90.
    }
  } 
}.