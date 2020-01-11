RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/rendevous/rendevous.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").

function encounter {
    parameter targetBody.
    parameter targetCaptureRadius.
    parameter positiveInclination IS TRUE.//Positive or negative inclination?  Essentially, which side of the encountered body do you want your periapsis to be on? (Postive = in front of, negative = behind)

    longInfo("Beginning Encounter with " + targetBody).

    SET TARGET TO targetBody.

    info("Matching Target Inclination").
    matchInclination(targetBody).

    info("Circularing Orbit").
    circularizeMaintainingApoapsis().

    info("Initiating Hohmann Transfer").
    LOCAL throttleController IS encounterThrottleController@:bind(lexicon()):bind(targetBody):bind(targetCaptureRadius):bind(positiveInclination).
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
    parameter desiredPe. //Periapsis of encountered body
    parameter positiveInclination.//Positive or negative inclination?  Essentially, which side of the encountered body do you want your periapsis to be on? (Postive = in front of, negative = behind)
    parameter delegateController. //Without an encounter, use this controller delegate.

    if NOT SHIP:ORBIT:HASNEXTPATCH {
        PRINT "No Encounter Yet".
        return delegateController().
    } else IF NOT (SHIP:ORBIT:NEXTPATCH:BODY = targetBody) {
        PRINT "WARNING: ENCOUNTER WITH UNEXPECTED BODY DETECTED: " + SHIP:ORBIT:NEXTPATCH:BODY.
        return delegateController().
    }

    PRINT "Detected Correct Encounter.".
    LOCAL orbitalRadiusSupplier IS encounterOrbitalPeriapsis@:bind(SHIP:ORBIT:NEXTPATCH):bind(desiredPe):bind(positiveInclination).

    return matchOrbitalRadiusThrottleController(previousState, desiredPe, orbitalRadiusSupplier).
}

function encounterOrbitalPeriapsis {
    parameter orbit.
    parameter desiredPeriapsis.
    parameter positiveInclination. //Positive or negative inclination?  Essentially, which side of the encountered body do you want your periapsis to be on? (Postive = in front of, negative = behind)

    LOCAL currentPeriapsis IS orbit:PERIAPSIS.
    LOCAL currentInclination IS orbit:INCLINATION.

    if ( (positiveInclination AND currentInclination < 90) OR (NOT positiveInclination AND currentInclination > 90)) { //We're on the opposite side of the body
        SET currentPeriapsis TO -((2 * orbit:BODY:RADIUS) + currentPeriapsis + desiredPeriapsis).
    }

    return currentPeriapsis.
}