RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/output.ks").
CLEARSCREEN.

Print "Starting Landing Sequence.".
SET orbitHeight to 71000.
Print "Orbital Height will be " + orbitHeight.

Print "Waiting for throttle to be set at 0.".
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

WAIT UNTIL THROTTLE = 0.0.

SET AG1 TO FALSE.
SET AG2 TO TRUE.

//Print "Engaging SAS".
shortInfo("Pointing Retrograde").
SAS ON.
SET SASMODE TO "RETROGRADE".

UNTIL ABS(LONGITUDE - 172.5) < .1  {
    CLEARSCREEN.
    PRINT "Longitude: " + LONGITUDE.
    PRINT "Latitude: " + LATITUDE.
    PRINT "Roll: " + SHIP:FACING:TOPVECTOR:Y.
    PRINT "FACING: " + SHIP:FACING.
}

shortInfo("Throttling Up to 100%").
LOCK THROTTLE TO 1.0.

WAIT UNTIL PERIAPSIS < 5000.

shortInfo("Throttling Down.").
LOCK THROTTLE TO 0.0.

WAIT 1.

SET SASMODE TO "PROGRADE".

UNTIL VANG(SHIP:FACING:VECTOR, PROGRADE:VECTOR).

SAS OFF.

SET currentPrograde TO progradeDegrees().
SET currentPitch to SHIP:CONTROL:PITCH.
SET refreshInterval to 0.05. // 50ms.
SET pitchChange to 0.02.

SET currentPrograde TO progradeDegrees().
SET currentPitch to SHIP:CONTROL:PITCH.
SET refreshInterval to 0.05. // 50ms.
SET pitchChange to 0.02.

UNTIL ALTITUDE < 15000 {
    CLEARSCREEN.
    PRINT "Longitude: " + LONGITUDE.
    PRINT "Latitude: " + LATITUDE.
    PRINT "Roll: " + SHIP:FACING:TOPVECTOR:Y.
    PRINT "FACING: " + SHIP:FACING.

    Print "current Prograde: " + currentPrograde.

    SET degreesAboveHorizon TO getDirection().
    SET newPrograde To progradeDegrees().

    SET progradeChange TO newPrograde - currentPrograde.
    SET currentPrograde TO newPrograde.

    SET currentHeading TO SHIP:FACING:PITCH.
    SET currentRoll TO SHIP:FACING:TOPVECTOR:Y.

    PRINT "degreesAboveHorizon: " + degreesAboveHorizon.
    PRINT "Current Prograde: " + currentPrograde.
    Print "Current Ship Pitch: " + SHIP:CONTROL:PITCH.
    PRINT "progradeChange: "+ progradeChange.
    PRINT "Current Heading: " + currentHeading.
    PRINT "Current Roll: " + currentRoll.

    SET newPitch to currentPitch.
    if (progradeChange < 0 AND degreesAboveHorizon > currentPrograde) {
        print "Raising Pitch".
        SET newPitch TO currentPitch + pitchChange * MIN(1, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange > 0 AND degreesAboveHorizon < currentPrograde) {
        print "Lowering Pitch".
        SET newPitch to currentPitch - pitchChange * MIN(1, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange < 0 AND degreesAboveHorizon < currentPrograde) {
        print "Falling, maintaining pitch".
    } else if (progradeChange > 0 AND degreesAboveHorizon > currentPrograde) {       
       print "Rising, maintaining pitch".
    }

    SET rollChange TO 0.
    if (currentHeading < 180 AND currentRoll < 0) {
        SET rollChange TO -0.1 * (currentHeading / 10).
    } else if (currentHeading < 180 AND currentRoll > 0) {
        SET rollChange TO 0.025 * (currentHeading / 10).
    } else if (currentHeading > 180 AND currentRoll < 0) {
        SET rollChange TO -0.025 * ((360 - currentHeading) / 10).
    } else if (currentHeading > 180 AND currentRoll > 0) {
        SET rollChange TO 0.1 * ((360 - currentHeading) / 10).
    }

    SET SHIP:CONTROL:PITCH TO newPitch.
    SET currentPitch To newPitch.
    SET SHIP:CONTROL:ROLL TO rollChange.

    WAIT refreshInterval.
}

SET SHIP:CONTROL:NEUTRALIZE to True.


info("Good Luck").



EXIT.

UNTIL SHIP:GROUNDSPEED > 160 OR ALT:RADAR > 5 {
//    SET facing TO SHIP:FACING.
    SET pitch to SHIP:FACING:PITCH - 0.2. // runway is a little off from east it seems.
//    Print "Facing: " + facing.
//    Print "Pitch: " + facing:PITCH.
//    Print "Heading: " + heading.

    SET SHIP:CONTROL:PITCH TO 0.5.    

    if pitch < 10 {
//        Print "Turn Left.".
        SET steer TO (pitch / 100).
    } else if pitch > 350 {
        SET steer TO ((360 - pitch) / -100). 
//        Print "Turn Right.".
    } else {
//        Print "Way off! Abort.".
    }
//    Print "Steer: " + steer.
    SET SHIP:CONTROL:WHEELSTEER TO steer.
}


WAIT UNTIL ALT:RADAR > 5.

shortInfo("Raising Gear.").
GEAR OFF.

SET currentPrograde TO progradeDegrees().
SET currentPitch to SHIP:CONTROL:PITCH.
SET refreshInterval to 0.05. // 50ms.
SET pitchChange to 0.02.

UNTIL ALTITUDE > 20000 {
        
    CLEARSCREEN.
    Print "current Prograde: " + currentPrograde.

    SET degreesAboveHorizon TO getDirection().
    SET newPrograde To progradeDegrees().

    SET progradeChange TO newPrograde - currentPrograde.
    SET currentPrograde TO newPrograde.

    SET currentHeading TO SHIP:FACING:PITCH.
    SET currentRoll TO SHIP:FACING:TOPVECTOR:Y.

    PRINT "degreesAboveHorizon: " + degreesAboveHorizon.
    PRINT "Current Prograde: " + currentPrograde.
    Print "Current Ship Pitch: " + SHIP:CONTROL:PITCH.
    PRINT "progradeChange: "+ progradeChange.
    PRINT "Current Heading: " + currentHeading.
    PRINT "Current Roll: " + currentRoll.

    if (progradeChange < 0 AND degreesAboveHorizon > currentPrograde) {
        print "Raising Pitch".
        SET newPitch TO currentPitch + pitchChange * MIN(1, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange > 0 AND degreesAboveHorizon < currentPrograde) {
        print "Lowering Pitch".
        SET newPitch to currentPitch - pitchChange * MIN(1, ABS(degreesAboveHorizon - currentPrograde)).
    } else if (progradeChange < 0 AND degreesAboveHorizon < currentPrograde) {
        print "Falling, maintaining pitch".
    } else if (progradeChange > 0 AND degreesAboveHorizon > currentPrograde) {
       print "Rising, maintaining pitch".
    }

    SET rollChange TO 0.
    if (currentHeading < 180 AND currentRoll < 0) {
        SET rollChange TO -0.1 * (currentHeading / 10).
    } else if (currentHeading < 180 AND currentRoll > 0) {
        SET rollChange TO 0.025 * (currentHeading / 10).
    } else if (currentHeading > 180 AND currentRoll < 0) {
        SET rollChange TO -0.025 * ((360 - currentHeading) / 10).
    } else if (currentHeading > 180 AND currentRoll > 0) {
        SET rollChange TO 0.1 * ((360 - currentHeading) / 10).
    }

    SET SHIP:CONTROL:PITCH TO newPitch.
    SET currentPitch To newPitch.
    SET SHIP:CONTROL:ROLL TO rollChange.

//    if (ABS(degreesAboveHorizon - progradeDegrees) < 1) {
//        PRINT "STABLE PITCH".
//    } else if (degreesAboveHorizon > progradeDegrees) {
//        PRINT "PITCHING UP".
//        SET SHIP:CONTROL:PITCH TO SHIP:CONTROL:PITCH + 0.1.
//    } else {
//        PRINT "PITCHING Down".
//        SET SHIP:CONTROL:PITCH TO SHIP:CONTROL:PITCH - 0.1.
//    }

    WAIT refreshInterval.
}

SET SHIP:CONTROL:NEUTRALIZE to True.

shortInfo("Engaging SAS").
SAS ON.

shortInfo("Igniting Nuclear Engine").
SET AG2 TO TRUE.    

SET switchMode TO FALSE.
UNTIL APOAPSIS > 71000 {

    IF (ALTITUDE > 26000 AND switchMode = FALSE) {
        shortInfo("Switching Rapiers Mode.").
        SET AG3 TO TRUE.
        SET switchMode TO TRUE.
    }

}

shortInfo("APOAPSIS at " + SHIP:ORBIT:APOAPSIS).
shortInfo("Turning off Rapiers.").
SET AG1 TO FALSE.
SET SASMODE TO "PROGRADE".

WAIT UNTIL ETA:APOAPSIS < 12.
shortInfo("Aproaching Apoapsis, Re-igniting Rapiers.").
SET AG1 TO TRUE.

WAIT UNTIL SHIP:ORBIT:PERIAPSIS > 72000.

SET AG1 TO FALSE.
SET AG2 TO FALSE.
info("Orbital Insertion Complete.", 100).

LOCK THROTTLE TO 0.0.
WAIT UNTIL THROTTLE = 0.0.

UNLOCK STEERING.
UNLOCK THROTTLE.
wait 1.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

shortInfo("Engaging Solar Panels").
SET AG4 TO True.

info("Launch Complete", 100).


function getDirection {
    if (ALTITUDE < 5000) {
        return getDirectionSub5000().
    }

    if (ALTITUDE < 10000) {
        return getDirectionSub10000().
    } else {
        return 20.
    }
}

function getDirectionSub5000 {
    SET airSpeed to SHIP:AIRSPEED.

    SET altitudeWeight TO MAX(0.001, 1 - (ALTITUDE / 5000)).
    PRINT "altitudeWeight: " + altitudeWeight.
    SET speedWeight TO MAX(0.001, 1 - (airSpeed / 500)) / (altitudeWeight * 1.5).
    PRINT "speedWeight: " + speedWeight.

    //Calculate individual vectors based on importance of speed & altitude.
    SET altitudeVector TO V(100,30,0):NORMALIZED * altitudeWeight.
//    PRINT "altitudeVector: " + altitudeVector.
    SET speedVector TO V(100, 5, 0):NORMALIZED * speedWeight.
//    PRINT "speedVector: " + speedVector.

    //Ignore Speed if altitude < 3000.  Assume we are able to increase speed while rising to 3000.
//    if (ALTITUDE < 3000) {
//        SET speedVectory TO speedVector * 0.
//    }

    //Calculate weighted final vector.  
    SET finalVector TO altitudeVector + speedVector.
    SET finalVector TO finalVector:NORMALIZED.

//    Print "Final Vector is: " + finalVector.

    //Calculate angle above horizon using tangent of vector.  
    SET opposite TO finalVector:Y.
    SET adjacent TO finalVector:X.

    SET degreesAboveHorizon TO ARCTAN(opposite / adjacent).
    PRINT "degrees above horizon: " + degreesAboveHorizon.

    return degreesAboveHorizon.
}

function getDirectionSub10000 {
    SET airSpeed to SHIP:AIRSPEED.

    SET speedWeight TO MAX(0.001, 1 - ((airSpeed - 500) / 600)).
    PRINT "speedWeight: " + speedWeight.

    SET altitudeWeight TO MAX(0.001, 1 - ((ALTITUDE - 5000) / 5000)) / (speedWeight * 3).
    PRINT "altitudeWeight: " + altitudeWeight.
 
    //Calculate individual vectors based on importance of speed & altitude.
    SET altitudeVector TO V(100,50,0):NORMALIZED * altitudeWeight.
//    PRINT "altitudeVector: " + altitudeVector.
    SET speedVector TO V(100, 0, 0):NORMALIZED * speedWeight.
//    PRINT "speedVector: " + speedVector.

    //Calculate weighted final vector.  
    SET finalVector TO altitudeVector + speedVector.
    SET finalVector TO finalVector:NORMALIZED.

//    Print "Final Vector is: " + finalVector.

    //Calculate angle above horizon using tangent of vector.  
    SET opposite TO finalVector:Y.
    SET adjacent TO finalVector:X.

    SET degreesAboveHorizon TO ARCTAN(opposite / adjacent).
    PRINT "degrees above horizon: " + degreesAboveHorizon.

    return degreesAboveHorizon.}

function deltaProgradeDegrees {
    parameter previousProgradeDegreesAboveHorizon.

    DECLARE LOCAL pd TO 90 - vang(SHIP:up:vector, SHIP:PROGRADE:forevector).

    DECLARE LOCAL dpd TO pd - previousProgradeDegreesAboveHorizon.
    SET previousProgradeDegreesAboveHorizon TO pd.

    Print "deltaProgradeDegrees: " + dpd.

    return dpd.
}

function progradeDegrees {
    return 90 - vang(SHIP:up:vector, SHIP:PROGRADE:forevector).
}

function pointAt {
    Parameter degreesFromNorth.
    Parameter pitchAboveHorizon.
    Paremeter tolerance IS 0.25.

    local refreshInterval = 0.05 //50 ms.
    //Represents the maximum torque (estimate) for Merlin Mark 2, at full raw input (pitch/yaw/roll).  
    //Units are expressed as momentum per second, based on refresh interval.  
    local maxTorque = V(22/refreshInterval, 19.3/refreshInterval, 16.5/refreshInterval).

    //Rough translation of angular momentum amount per degree change.
    //Units are expressed as momentum per (degrees /s). (For example, 1 degree of pitch change / s = 90 momentum).
    local degreePerMomentum = V(90,105,25).

    SET facing TO SHIP:FACING.
    SET heading TO HEADING(degreesFromNorth, pitchAboveHorizon).

    SET currentPitch to SHIP:CONTROL:PITCH.
    SET currentYaw to SHIP:CONTROL:YAW.
    SET currentRoll to SHIP:CONTROL:ROLL.
    SET currentMom TO SHIP:ANGULARMOMENTUM.
    SET momChange TO V(0,0,0).
    SET refreshInterval to 0.05. // 50ms.
    SET pitchChange to 0.
    SET yawChange to 0.
    SET rollChange to 0.

    SET pitchDelta TO degreeDelta(heading:YAW, facing:YAW).//In terms of control, directions yaw is actually "Pitch".
    SET yawDelta TO degreeDelta(heading:PITCH - facing:PITCH). //In terms of control, directiosn pitch is actually "Yaw".
    SET rollDelta TO -degreeDelta(heading:ROLL - facing:ROLL). //Roll is actually negative, go figure.

    SET rollChange TO 0.
    if (currentHeading < 180 AND currentRoll < 0) {
        SET rollChange TO -0.1 * (currentHeading / 10).
    } else if (currentHeading < 180 AND currentRoll > 0) {
        SET rollChange TO 0.025 * (currentHeading / 10).
    } else if (currentHeading > 180 AND currentRoll < 0) {
        SET rollChange TO -0.025 * ((360 - currentHeading) / 10).
    } else if (currentHeading > 180 AND currentRoll > 0) {
        SET rollChange TO 0.1 * ((360 - currentHeading) / 10).
    }



        //Set Pitch
        SET SHIP:CONTROL:PITCH TO newPitch.
        SET currentPitch To newPitch.

        //Set Yaw
        SET SHIP:CONTROL:YAW TO newYaw.
        SET currentYaw To newYaw.

        //Set Roll
        SET SHIP:CONTROL:ROLL TO rollChange.
        SET currentRoll To newRoll.

        WAIT refreshInterval.
    }
    print "Orientation Complete".
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
}