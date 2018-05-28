SET coors TO LATLNG(-0.0502200201,-74.490112304).

SET currentPrograde TO progradeDegrees().
SET currentPitch to SHIP:CONTROL:PITCH.
SET refreshInterval to 0.05. // 50ms.
SET pitchChange to 0.02.
//SET currentRoll TO SHIP:CONTROL:ROLL.

SAS OFF.

//TODO, until landing
UNTIL FALSE {
	CLEARSCREEN.	
    PRINT "Longitude: " + LONGITUDE.
    PRINT "Latitude: " + LATITUDE.

//    PRINT "Heading: " + coors:HEADING.
//    PRINT "Bearing: " + coors:BEARING.
//    PRINT "Roll: " + invertedRoll(SHIP:FACING:ROLL).

//    Print "current Prograde: " + currentPrograde.

//    SET degreesAboveHorizon TO getDirection().
	SET degreesAboveHorizon To 30.
    SET newPrograde To progradeDegrees().

    SET progradeChange TO newPrograde - currentPrograde.
    SET currentPrograde TO newPrograde.

    SET currentBearing TO coors:BEARING.
    SET currentRoll TO mod(roll_for(SHIP) + 360, 360).
    //invertedRoll(SHIP:FACING:ROLL).
    SET currentRollControl TO SHIP:CONTROL:ROLL.

    PRINT "Desired Prograde: " + degreesAboveHorizon.
    PRINT "Current Ship Pitch: " + pitch_for(SHIP)..
    Print "Current Ship Pitch Control: " + SHIP:CONTROL:PITCH.
    PRINT "progradeChange: "+ progradeChange.

    SET newPitch TO 0.

    if (progradeChange < 0 AND degreesAboveHorizon > currentPrograde) {
        print "Raising Pitch".
        SET newPitch TO currentPitch + pitchChange * MIN(0.3, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange > 0 AND degreesAboveHorizon < currentPrograde) {
        print "Lowering Pitch".
        SET newPitch to currentPitch - pitchChange * MIN(0.3, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange < 0 AND degreesAboveHorizon < currentPrograde) {
    	SET newPitch to currentPitch - pitchChange * Min(0.1, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange > 0 AND degreesAboveHorizon > currentPrograde) {
    	SET newPitch to currentPitch + pitchChange * Min(0.1, ABS(degreesAboveHorizon - currentPrograde)).
    }

    SET SHIP:CONTROL:PITCH TO newPitch.
    SET currentPitch To newPitch.

    SET rollChange TO 0.
    //Calculate DesiredRoll
//    SET desiredRoll TO getDesiredRollDegreeForBearing(currentBearing).
    SET desiredRoll TO 0.

    //Calculate desiredRollChange
    SET desiredRollChange TO getDesiredRollChange(desiredRoll, currentRoll).
    SET desiredRollControl TO getDesiredRollControlForRollChange(desiredRollChange).

    PRINT "Current Bearing: " + currentBearing.
    PRINT "Current Roll: " + currentRoll.
    Print "Roll For: " + roll_for(SHIP).
    PRINT "Desired Roll: " + desiredRoll.
    PRINT "Desired Roll Change: " + desiredRollChange.
    PRINT "Desired Roll Control: " + desiredRollControl.

    SET SHIP:CONTROL:ROLL TO desiredRollControl * MIN(abs(newPrograde/degreesAboveHorizon), abs(degreesAboveHorizon/newPrograde)).

    WAIT refreshInterval.
}

function getDesiredRollControlForRollChange {
	parameter desiredRollChange.

	if(desiredRollChange > 0) {
		return 0.5 * min(1, abs(desiredRollChange) / 50).
	} else {
		return -0.5 * min(1, abs(desiredRollChange) / 50).	
	}
}

function getDesiredRollChange {
	parameter desiredRoll.
	parameter currentRoll.

	return -(invertedRoll(desiredRoll) - invertedRoll(currentRoll)).

}

function getDesiredRollDegreeForBearing {
	parameter bearing.

	Print "Bearing: " + bearing.

	//if current bearing is negative, we want a roll > 360 - (10 * MIN(1, abs(bearing)/10).

	//if current bearing is +, we want a roll < 10 * MIN(1, abs(bearing)/10).

	if (bearing > 0) {
		return 10 * MIN(1, abs(bearing)).
	} else {
		return 360 - (10 * MIN(1, abs(bearing))).
	}
}

function getDirection {
	return 3.
}

function progradeDegrees {
    return 90 - vang(SHIP:up:vector, SHIP:PROGRADE:forevector).
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

function pitch_for {
  parameter ves.

  return 90 - vang(ves:up:vector, ves:facing:forevector).
}
