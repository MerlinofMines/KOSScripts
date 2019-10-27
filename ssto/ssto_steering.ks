RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/constants.ks").

function getRunwaySteeringRawControlValue {
    LOCAL controlClamp IS getSteeringControlClamp().

    LOCAL value IS clamp(getSteeringAngle/1000, -controlClamp, controlClamp).

    return value.
}

function getSteeringAngle {
    LOCAL runwayTargetPosition IS getRunwayForwardSteeringTargetPosition().

    LOCAL facingVector IS SHIP:FACING:FOREVECTOR.

    LOCAL angleDIFF IS VANG(runwayTargetPosition, facingVector).

    IF (VANG(VCRS(runwayTargetPosition, facingVector),SHIP:FACING:TOPVECTOR) < 90) {
        return angleDiff.
    } else {
        return -angleDiff.
    }
}

function getSteeringControlClamp {
    return MIN(1 / (SHIP:VELOCITY:SURFACE:MAG * 5), 1).
}

function getRunwayForwardSteeringTargetPosition {
    LOCAL targetPosition IS getRunwayForwardTargetPosition().

    LOCAL runwayVector IS getRunwayForwardVector().

    return targetPosition - runwayVector*targetPosition:MAG/2.
}

function getRunwayForwardVector {
    LOCAL runwayVector IS getRunwayVector():NORMALIZED.
    LOCAL shipFacingVector IS SHIP:FACING:FOREVECTOR.

    if (VANG(shipFacingVector, runwayVector) > 90) {
       return -runwayVector.
    } else {
       return runwayVector.
    }
}

function getRunwayForwardTargetPosition {
    if VANG(getRunwayForwardVector(), getRunwayVector()) < 90 {
        return RUNWAY_EAST_COORDINATES:POSITION.
    } else {
        return RUNWAY_WEST_COORDINATES:POSITION.
    }
}


function getRunwayVector {
    return RUNWAY_EAST_COORDINATES:POSITION - RUNWAY_WEST_COORDINATES:POSITION.
}