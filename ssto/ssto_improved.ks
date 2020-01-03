RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/constants.ks").
RUNONCEPATH("0:/ssto/ssto_steering.ks").

function sstoLaunch {
    parameter primaryEngines.
    parameter secondaryEngines IS list().
    parameter sicoCutoff IS 69000.

    CLEARSCREEN.

    Print "Starting Launch Sequence.".
    SET orbitHeight to 75000.
    Print "Orbital Height will be " + orbitHeight.

    Print "Waiting for throttle to be set at 0.".
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

    WAIT UNTIL THROTTLE = 0.0.

    SET countdown TO 3.

    info("Launch is a go.").

    shortInfo("Launching in ", countdown + 1).
    UNTIL countdown = 0 {
      shortInfo(countdown, 1).
      SET countdown TO countdown - 1.
      WAIT 1.
    }

    shortInfo("Activating Rapiers.").
    SET AG1 TO TRUE.

    WAIT 1.

    BRAKES OFF.

    shortInfo("Throttling Up to 100%").
    LOCK THROTTLE TO 1.0.

    UNTIL RUNWAY_EAST_COORDINATES:DISTANCE < 200 OR ALT:RADAR > 5 {
        SET SHIP:CONTROL:PITCH TO 0.5.
        SET SHIP:CONTROL:WHEELSTEER TO getRunwaySteeringRawControlValue().
    }

    SET currentPrograde TO progradeDegrees().
    SET currentTime TO TIME:SECONDS.
    SET currentPitch to SHIP:CONTROL:PITCH.
    SET currentVelocity TO SHIP:AIRSPEED.
    SET refreshInterval to 0.05. // 50ms.
    SET pitchChange to 1.
    SET desiredPitch TO getDirection().
    SET desiredAcceleration TO 1.0.
    WAIT refreshInterval.

    LOCK STEERING TO getDesiredHeading().

    SET SHIP:CONTROL:NEUTRALIZE to True.

    WAIT UNTIL ALT:RADAR > 5.

    shortInfo("Raising Gear.").
    GEAR OFF.

    WAIT UNTIL SHIP:ALTITUDE > 20000.

    UNLOCK STEERING.
    SET SHIP:CONTROL:NEUTRALIZE to True.

    shortInfo("Engaging SAS").
    SAS ON.

    shortInfo("Igniting Nuclear Engine").
    SET AG2 TO TRUE.

    SET switchMode TO FALSE.
    UNTIL APOAPSIS > sicoCutoff {

        IF (ALTITUDE > 26000 AND switchMode = FALSE) {
            shortInfo("Switching Rapiers Mode.").
            SET AG3 TO TRUE.
            SET switchMode TO TRUE.
        }
    }

    shortInfo("APOAPSIS at " + SHIP:ORBIT:APOAPSIS).
    shortInfo("Turning off Rapiers.").
    SET AG1 TO FALSE.

    circularizeMaintainingPrograde(primaryEngines, secondaryEngines).

    LOCK THROTTLE TO 0.0.
    WAIT UNTIL THROTTLE = 0.0.

    //Shutdown Engines and reset Thrust Limiters
    SET AG1 TO FALSE.
    SET AG2 TO FALSE.

    for eng in primaryEngines {
        SET eng:THRUSTLIMIT TO 100.
        eng:shutdown().
    }

    for eng in secondaryEngines {
        SET eng:THRUSTLIMIT TO 100.
        eng:shutdown().
    }

    info("Orbital Insertion Complete.", 100).

    UNLOCK STEERING.
    UNLOCK THROTTLE.
    wait 1.

    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

    shortInfo("Engaging Solar Panels").
    SET AG4 TO True.

    shortInfo("Engaging Primary Engines").
    for eng in primaryEngines {
        SET eng:THRUSTLIMIT TO 100.
        eng:activate().
    }

    info("Launch Complete", 100).
}

function getDesiredHeading {
    CLEARVECDRAWS().
    CLEARSCREEN.

    LOCAL idealPitch IS getDirection().

    PRINT "Ideal Pitch: " + idealPitch.

    LOCAL newTime IS TIME:SECONDS.
    LOCAL timeDelta IS newTime - currentTime.
    LOCAL newVelocity IS SHIP:AIRSPEED.
    LOCAL acceleration IS (newVelocity - currentVelocity)/timeDelta.

    //Global State
    SET currentTime TO newTime.
    SET currentVelocity TO newVelocity.

    LOCAL currentPitch IS navball_direction(SHIP):PITCH.

    PRINT "Current Pitch: " + currentPitch.

    if(abs(currentPitch - desiredPitch) > pitchChange) {
        PRINT "CASE 1".
    } else if (acceleration < desiredAcceleration) {
        PRINT "CASE 2".
        SET desiredPitch TO desiredPitch - pitchChange.

    } else if (currentPitch < (idealPitch - pitchChange) AND acceleration > 3*desiredAcceleration) {
        PRINT "CASE 3".
        SET desiredPitch TO desiredPitch + pitchChange.
    } else if (currentPitch > (idealPitch + pitchChange)) {
        SET desiredPitch TO desiredPitch - pitchChange.
        PRINT "CASE 4".
    } else {
        PRINT "CASE 5".
    }

    Print "Desired Pitch: " + desiredPitch.

    LOCAL desiredHeading IS HEADING(90, desiredPitch).

//    drawDirection(desiredHeading, "Desired Heading").
//    drawDirection(SHIP:FACING, "Current Heading").

    return desiredHeading.
}

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

    SET altitudeWeight TO 4*MAX(0.001, 1 - (ALTITUDE / 5000)).
    PRINT "altitudeWeight: " + altitudeWeight.
    SET speedWeight TO MAX(0.001, 1 - (airSpeed / 500)) / (altitudeWeight * 1.5).
    PRINT "speedWeight: " + speedWeight.

    //Calculate individual vectors based on importance of speed & altitude.
    SET altitudeVector TO V(100,30,0):NORMALIZED * altitudeWeight.
//    PRINT "altitudeVector: " + altitudeVector.
    SET speedVector TO V(100, -10, 0):NORMALIZED * speedWeight.
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