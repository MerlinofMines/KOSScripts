RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/output.ks").
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

shortInfo("Throttling Up to 100%").
LOCK THROTTLE TO 1.0.

//Print "Engaging SAS".
//SAS ON.

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
SET currentVelocity TO SHIP:AIRSPEED.
SET refreshInterval to 0.05. // 50ms.
SET pitchChange to 0.02.

WAIT refreshInterval.

UNTIL ALTITUDE > 20000 {
    LOCAL newVelocity IS SHIP:AIRSPEED.
    LOCAL acceleration IS newVelocity - currentVelocity.
    SET currentVelocity TO newVelocity.
    SET currentPitch to SHIP:CONTROL:PITCH.


    if (acceleration > refreshInterval) {
        SET newPitch TO SHIP:CONTROL:PITCH + 0.002.
    } else {
        SET newPITCH TO SHIP:CONTROL:PITCH - 0.002.
    }

    SET currentHeading TO SHIP:FACING:PITCH.
    SET currentRoll TO SHIP:FACING:TOPVECTOR:Y.

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

shortInfo("Engaging SAS").
SAS ON.

shortInfo("Igniting Nuclear Engine").
SET AG2 TO TRUE.    

SET switchMode TO FALSE.
UNTIL APOAPSIS > 69000 {

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

SET circularized TO FALSE.
SET orbitEccentricity TO SHIP:ORBIT:ECCENTRICITY.

UNTIL (SHIP:ORBIT:PERIAPSIS > 72000 AND circularized) {
    //If our current eccentricity is more than our previous then we're as circular as we're gonna get.
    if(SHIP:ORBIT:ECCENTRICITY > orbitEccentricity) {
        SET circularized TO TRUE.
    }

    SET orbitEccentricity TO SHIP:ORBIT:ECCENTRICITY.
    WAIT 0.01.
}

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