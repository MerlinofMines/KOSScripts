RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/rendevous/rendevous.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").

function encounter {
    parameter targetBody.
    parameter targetCaptureRadius.

    longInfo("Beginning Encounter with " + targetBody).

    SET TARGET TO targetBody.

    info("Matching Target Inclination").
    matchInclination(targetBody).

    info("Circularing Orbit").
    circularizeMaintainingApoapsis().

    info("Initiating Hohmann Transfer").
    LOCAL throttleController IS encounterThrottleController@:bind(lexicon()):bind(targetBody):bind(targetCaptureRadius).
    hohmannTransfer(targetBody, throttleController).

    info("Warping to Target Sphere of Influence").
    WAIT 1.
    WARPTO( ETA:TRANSITION + TIME:SECONDS).

    WAIT UNTIL SHIP:ORBIT:BODY = targetBody.

    info("Initiating Capture").
    circularizeMaintainingPeriapsis().

    info("Encounter Complete").
}

function encounterThrottleController {
    parameter previousState.
    parameter targetBody.
    parameter desiredPe.//Periapsis of encountered body
    parameter desiredAp.//Apoapsis without encounter

    if NOT SHIP:ORBIT:HASNEXTPATCH {
        PRINT "No Encounter Yet".
        return matchApoapsisThrottleController(previousState, desiredAp).
    } else IF NOT (SHIP:ORBIT:NEXTPATCH:BODY = targetBody) {
        PRINT "WARNING: ENCOUNTER WITH UNEXPECTED BODY DETECTED: " + SHIP:ORBIT:NEXTPATCH:BODY.
        return matchApoapsisThrottleController(previousState, desiredAp).
    }
    PRINT "Detected Correct Encounter.".

//See if this is the first time we detected the encounter, reset state and begin calculating new throttle
    IF NOT previousState:HASKEY("E") {
        LOCAL previousThrottle IS previousState["H"].
        previousState:CLEAR.
        SET previousState["E"] TO TRUE.
        SET previousState["H"] TO previousThrottle.
        SET previousState["T"] TO TIME:SECONDS.
        SET previousState["P"] TO SHIP:ORBIT:NEXTPATCH:PERIAPSIS.
        SET previousState["I"] TO SHIP:ORBIT:NEXTPATCH:INCLINATION.

    //TODO: previousThrottle may be too high in some cases, not sure yet, as is waiting 0.01. sec.
        WAIT 0.01.
        return previousThrottle.
    }

    LOCAL previousPe IS previousState["P"].
    LOCAL previousTime IS previousState["T"].
    LOCAL previousThrottle IS previousState["H"].
    LOCAL previousInclination IS previousState["I"].

    LOCAL newPe IS SHIP:ORBIT:NEXTPATCH:PERIAPSIS.
    LOCAL newInclination IS SHIP:ORBIT:NEXTPATCH:INCLINATION.
    LOCAL newTime IS TIME:SECONDS.

    IF previousInclination < 90 AND previousPE > 0 {
        PRINT "Previous Inclination < 90.".
        PRINT "BEFORE: " + previousPE.
        SET previousPe TO -previousPe.
    }

    IF newInclination < 90 AND newPe > 0 {
        PRINT "New Inclination < 90.".
        PRINT "BEFORE: " + newPe.
        SET newPe TO -newPe.
    }

    LOCAL peChange IS newPe - previousPe.
    LOCAL timeChange IS newTime - previousTime.
    LOCAL peChangeRate IS peChange/timeChange.

    PRINT "Previous Throttle: " + previousThrottle.
    PRINT "Previous Pe: " + previousPe.
    PRINT "Previous Inclination: " + previousInclination.

    PRINT "Desired Pe: " + desiredPe.
    PRINT "Time Change: " + timeChange.
    PRINT "New Inclination: " + newInclination.
    PRINT "Periapsis change rate: " + peChangeRate.

    IF newPe > desiredPe RETURN -1.

    PRINT "Desired Periapsis Gap: " + abs(1 - (newPe/desiredPe)).
//IF we're stupid close to our target orbit, and our change rate is also low, call it quits.
    IF abs(1 - (newPe/desiredPe)) < 0.001 AND peChangeRate < 0.1 {
        RETURN -1.
    }

    SET previousState["I"] TO SHIP:ORBIT:NEXTPATCH:INCLINATION.
    SET previousState["P"] TO SHIP:ORBIT:NEXTPATCH:PERIAPSIS. //Don't store modified value, use the original.
    SET previousState["T"] TO newTime.

//Need to wait a non-zero amount of time to allow for an actual "burn".
    WAIT 0.01.

//Still have >1 burn time, previous throttle is ok.
    IF newPe + peChangeRate < desiredPe {
        return previousThrottle.
    }

//Time to calculate new throttle.
    LOCAL newThrottle IS min(1,2*(desiredPe+0.1-newPe)/(peChangeRate)) * previousThrottle.
    SET previousState["H"] TO newThrottle.
    return newThrottle.
}
