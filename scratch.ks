RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/orbital_information.ks").
LOCAL b IS VESSEL("Kerbin Science Orbiter").

erase().
CLEARSCREEN.

//    LOCAL transferTime IS TIME:SECONDS + nd:ETA.

LOCAL transferTime IS getHohmannTransferTime(b).

LOCAL transferDeltaV IS getHohmannTransferDeltaV(b,transferTime).

SET myNode to NODE(transferTime,0,0,transferDeltaV).

ADD myNode.

UNTIL TRUE {
    erase().
    CLEARSCREEN.
    PRINT "True Anomaly: " + b:ORBIT:trueAnomaly.
    PRINT "LAN: " + b:ORBIT:LAN.
    PRINT "AOP: " + b:ORBIT:ARGUMENTOFPERIAPSIS.
    PRINT "Eccentricity: " + b:ORBIT:ECCENTRICITY.

    LOCAL knownRadius IS positionVectorAt(b,TIME:SECONDS):MAG.
    LOCAL calculatedRadius IS getRadiusFromTrueAnomaly(b,b:ORBIT:trueAnomaly).

    PRINT "Calculated Radius: " + calculatedRadius.
    PRINT "Known Radius:      " + knownRadius.

    PRINT "Difference: " + (calculatedRadius-knownRadius).

//    PRINT "SOLAR PRIME VECTOR: " + SOLARPRIMEVECTOR:NORMALIZED.

//    drawVector(SOLARPRIMEVECTOR*2*(b:ORBIT:APOAPSIS+b:ORBIT:BODY:RADIUS),"Prime Solar Vector",KERBIN:POSITION).
//    drawVector(getReferencePlaneNormalVector*2*(b:ORBIT:APOAPSIS+b:ORBIT:BODY:RADIUS),"Other Dir",KERBIN:POSITION).
    drawVector(getLANVector(b)*2*(b:ORBIT:APOAPSIS+b:ORBIT:BODY:RADIUS),"LAN Vector",KERBIN:POSITION).
    drawVector(getPeriapsisVector(b)*(b:ORBIT:PERIAPSIS+b:ORBIT:BODY:RADIUS),"Periapsis Vector", KERBIN:POSITION).
    WAIT 0.05.
}

function getHohmannTransferDeltaV {
    parameter targetOrbital.
    parameter transferTime.

    LOCAL positionVector IS positionVectorAt(SHIP,transferTime).

    //1. Calculate the radius of target orbital at given transferTime.
    //Note that the true anomaly > 180 doesn't matter since cos(degrees) = cos(-degrees).
    LOCAL targetPeriapsisVector IS getPeriapsisVector(targetOrbital).
    LOCAL hohmannTrueAnomaly IS VANG(-positionVector,targetPeriapsisVector).
    LOCAL hohmannRadius IS getRadiusFromTrueAnomaly(targetOrbital,hohmannTrueAnomaly).

    //2. Calculate theoritical position vector of the SHIP at that target Orbital.
    LOCAL hohmannPositionVector IS -positionVector:NORMALIZED*hohmannRadius.

    //3. Calculate SMA for hohmann transfer orbit.
    LOCAL hohmannSMA IS (positionVector:MAG + hohmannRadius)/2.

    //4.  Using vis viva equation, calculate needed delta V at transferTime.
    //See https://en.wikipedia.org/wiki/Vis-viva_equation
    LOCAl v2 IS SHIP:ORBIT:BODY:MU * ( (2 / positionVector:MAG) - (1 / hohmannSMA) ).
    LOCAL hohmannVelocity IS sqrt(v2).

    LOCAL currentVelocity IS VELOCITYAT(SHIP,transferTime):ORBIT:MAG.

    return hohmannVelocity - currentVelocity.
}

function getHohmannTransferTime {
    parameter targetOrbital.
    parameter startTime Is TIME:SECONDS.
    Local stepNumber Is 10.
    Local stepDuration Is SHIP:ORBIT:PERIOD / stepNumber.

    Local transferTime Is getHohmannTransferTimeIterate(targetOrbital, startTime, stepNumber, stepDuration).

    LOCAL separationDistance IS getHohmannTransferSeparationDistance(targetOrbital, transferTime).

    PRINT "Hohmann Separation Distance: " + separationDistance.

    //This is hardcoded...
    IF separationDistance < 1000 {
        return transferTime.
    }

    return getHohmannTransferTime(targetOrbital,startTime+SHIP:ORBIT:PERIOD).
}


function getHohmannTransferTimeIterate {
    parameter targetOrbital.
    parameter startTime.
    parameter stepNumber.
    parameter stepDuration.
    parameter errorBound Is 0.01. //Error bound, in seconds.
    parameter iterationCount Is 1.

    Local closestSeparationDistance Is getHohmannTransferSeparationDistance(targetOrbital, startTime).
    Local closestSeparationTime Is startTime.

    FROM {Local step Is 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
//    		PRINT "Step is: " + step.
        Local separationTime Is startTime + (step * stepDuration).

//    		PRINT "Separation Time is: " + separationTime.

        Local newClosestSeparationDistance Is getHohmannTransferSeparationDistance(targetOrbital, separationTime).

        IF (newClosestSeparationDistance < closestSeparationDistance) {
            SET closestSeparationDistance TO newClosestSeparationDistance.
            SET closestSeparationTime TO separationTime.
        }
        WAIT 0.05.
    }

    if(stepDuration < errorBound) {
    		PRINT "Achieved requested result in " + iterationCount + " iterations".
    		PRINT "Step Duration: " + stepDuration.
    		PRINT "Closest Separation Distance: " + closestSeparationDistance.
        return closestSeparationTime.
    }

    Local newStartTime Is closestSeparationTime - stepDuration.
    Local newStepDuration TO (stepDuration * 2) / stepNumber.

    Local bestTransferTime TO getHohmannTransferTimeIterate(targetOrbital, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

    return bestTransferTime.
}


//This function will calculate the separation distance from the target orbital
//if a Hohmann Transfer burn was initiated at the given transfer time.
//It does this by calculating the time at which SHIP will be at orbital radius
//of the target orbital after the hohmann transfer was completed, and then calculating the
//distance from there to the actual position of the targetOrbital at that point in time.

//This function assumes that SHIP and targetOrbital are coplanar, though the result will still be
//true if called for a targetOrbital that is not coplanar.

//This function also, reasonably, assumes that the targetOrbital and SHIP are orbiting the same body.
function getHohmannTransferSeparationDistance {
    parameter targetOrbital.
    parameter transferTime.

    LOCAL positionVector IS positionVectorAt(SHIP,transferTime).

    //1. Calculate the radius of target orbital if transfer was initiated at transferTime.\
    //Note that the true anomaly > 180 doesn't matter since cos(degrees) = cos(-degrees).
    LOCAL targetPeriapsisVector IS getPeriapsisVector(targetOrbital).
    LOCAL hohmannTrueAnomaly IS VANG(-positionVector,targetPeriapsisVector).
    LOCAL hohmannRadius IS getRadiusFromTrueAnomaly(targetOrbital,hohmannTrueAnomaly).

    //2. Calculate theoritical position vector of the SHIP at that target Orbital.
    LOCAL hohmannPositionVector IS -positionVector:NORMALIZED*hohmannRadius.
    drawVector(hohmannPositionVector, "hohmannPositionVector",SHIP:ORBIT:BODY:POSITION).

    //3. Calculate the time it'll take for SHIP to reach targetOrbital radius and add to transferTime.
    LOCAL hohmannSMA IS (positionVector:MAG + hohmannRadius)/2.
    LOCAL hohmannTransferSeconds IS CONSTANT:PI*sqrt(hohmannSMA*hohmannSMA*hohmannSMA/SHIP:ORBIT:BODY:MU).
    LOCAL arrivalInstant IS hohmannTransferSeconds+transferTime.

//    PRINT "Body Radius: " + SHIP:ORBIT:BODY:RADIUS.
//    PRINT "hohmannRadius: " + hohmannRadius.
//    PRINT "hohmannSMA: " + hohmannSMA.
//    PRINT "hohmannTransferSeconds: " + hohmannTransferSeconds.
//    PRINT "arrivalInstant: " + arrivalInstant.

    //4. Calculate Position of targetOrbital at that instant in time.
    LOCAL targetOrbitalPosition IS POSITIONAT(targetOrbital,arrivalInstant) - SHIP:ORBIT:BODY:POSITION.
    drawVector(targetOrbitalPosition, "targetOrbitalPosition",SHIP:ORBIT:BODY:POSITION).

    //5. Subtract 3 from 4 and take MAG to get separation distance.
    LOCAL separationDistance IS (hohmannPositionVector - targetOrbitalPosition):MAG.
    return separationDistance.
}

//Since the MUN has 0 inclination with respect to the "reference plane", we can reverse
//engineer the normal vector to the true reference plane using the cross product of it and the solar prime vector.
function getReferencePlaneNormalVector {
    LOCAL refVector IS POSITIONAT(MUN,0).
    return VCRS(refVector, SOLARPRIMEVECTOR):NORMALIZED.
}

function getLANVector {
    parameter targetOrbital.

    LOCAL c IS 1.
    LOCAL p IS 1.

    //IF no inclination, the LANVector is the same as the SOLARPRIMEVECTOR.
    IF targetOrbital:ORBIT:LAN = 0 {
        return SOLARPRIMEVECTOR:NORMALIZED.
    } ELSE {
        LOCAL rotation IS -ANGLEAXIS(targetOrbital:ORBIT:LAN,getReferencePlaneNormalVector()).
        return (rotation*SOLARPRIMEVECTOR):NORMALIZED.
    }
}

function getPeriapsisVector {
    parameter targetOrbital.

    IF targetOrbital:ORBIT:ECCENTRICITY > 0 {
        LOCAL timeAtPeriapsis IS timeToOrbitRevolutionsFromLastPeriapsis(1, targetOrbital)+TIME:SECONDS.
        return positionVectorAt(targetOrbital, timeAtPeriapsis).
    }

    LOCAL lanVector IS getLANVector(targetOrbital).
    LOCAL refAngle IS -ANGLEAXIS(targetOrbital:Orbit:INCLINATION,lanVector)*SOLARPRIMEVECTOR.

    IF (VANG(refAngle,getReferencePlaneNormalVector()) > 90) {
        SET refAngle TO -refAngle.
    }

//    drawVector(refAngle*(targetOrbital:ORBIT:PERIAPSIS+b:ORBIT:BODY:RADIUS),"Reference Vector", KERBIN:POSITION).

    LOCAL orbitNormalVector IS VCRS(lanVector, refAngle).
//    drawVector(orbitNormalVector*(targetOrbital:ORBIT:PERIAPSIS+b:ORBIT:BODY:RADIUS),"Normal Vector", KERBIN:POSITION).

    LOCAL periapsisVector IS ANGLEAXIS(targetOrbital:ORBIT:ARGUMENTOFPERIAPSIS, orbitNormalVector)*lanVector.

    return periapsisVector:NORMALIZED.
}

//See https://en.wikipedia.org/wiki/True_anomaly#Radius_from_true_anomaly
function getRadiusFromTrueAnomaly {
    parameter targetOrbital.
    parameter trueAnomaly.

    LOCAL e IS targetOrbital:ORBIT:ECCENTRICITY.
    LOCAL a IS targetOrbital:ORBIT:SEMIMAJORAXIS.

    LOCAL numerator IS 1 - (e*e).
    LOCAL denominator IS 1 + e*cos(trueAnomaly).

    return a*numerator/denominator.
}