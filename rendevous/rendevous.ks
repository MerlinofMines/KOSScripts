RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").
RUNONCEPATH("0:/orbital_maneuvers.ks").
RUNONCEPATH("0:/input.ks").

function rendevousWithPlan {
    LIST Targets IN targets.

    Local targetVessel Is selectTargetVessel(targets, "Select Rendevous Target").

    Print "Beginning Rendevous with " + targetVessel.
    rendevous(targetVessel).
}

function rendevous {
    parameter targetVessel.

    longInfo("Beginning Rendevous with " + targetVessel).

    SET TARGET TO targetVessel.

    info("Matching Target Inclination").
    matchInclination(targetVessel).

    info("Circularing Orbit").
    circularizeMaintainingApoapsis().

    info("Initiating Hohmann Transfer").
    hohmannTransfer(targetVessel).

    finalApproach(targetVessel).

    info("Rendevous Complete").

}

//This function makes final adjustments to the approach to ensure that we
function finalApproach {
    parameter targetVessel.
    parameter sourceVessel Is SHIP.

//Step 1: Calculate
    shortInfo("Calculating separation distance at final approach.").
    Local separationTime IS timeOfMinimumSeparation(targetVessel, sourceVessel, timeAtNextApoapsis(sourceVessel)).

    Local sourcePosition IS positionVectorAt(sourceVessel, separationTime).
    Local targetPosition IS positionVectorAt(targetVessel, separationTime).

    Local separationDistance IS (targetPosition - sourcePosition):MAG.

    Print "Minimum Separation Time: " + separationTime.
    Print "Minimum Separation Distance: " + separationDistance.

    drawVector(sourcePosition, "Source Position", sourceVessel:Orbit:Body:Position).
    drawVector(sourcePosition, "Target Position", sourceVessel:Orbit:Body:Position).

    if (separationTime - 60 > TIME:SECONDS) {
        WARPTO(separationTime - 60).
    }

    SET NAVMODE TO "Target".
    SET SASMODE TO "Retrograde".

    UNTIL (VANG(sourceVessel:Facing:Forevector, -relativeVelocity(targetVessel, sourceVessel)) < 0.1) {
    //        CLEARSCREEN.
    //        CLEARVECDRAWS().

        Local relVelocity IS relativeVelocity(targetVessel, sourceVessel).

    //        drawVector(relVelocity, "Relative Velocity").
    //        PRINT "Relative Velocity: " + relVelocity:MAG.
    //        Print "Angle: " + VANG(sourceVessel:Facing:Forevector, -relativeVelocity(targetVessel, sourceVessel)).

        WAIT 0.01.
    }

    Print "Oriented Correctly.  Waiting for Suicide Burn.".

    LOCAL DONE IS FALSE.

    Local minSeparationDistance IS MAX(30, separationDistance).//Don't come closer than 30 meters.

    UNTIL FALSE {
    //        CLEARSCREEN.
    //        CLEARVECDRAWS().
        Local relVelocity IS relativeVelocity(targetVessel, sourceVessel).

        Local suicideBurnTime IS calculateBurnDuration(relVelocity:MAG).

        LOCAL a is relVelocity:MAG/suicideBurnTime.
        LOCAL d IS targetVessel:POSITION.
        LOCAL theta IS VANG(relVelocity,d).
        LOCAL r IS d*cos(theta).

        Local suicideTravelDistance IS -0.5*a*(suicideBurnTime*suicideBurnTime) + relVelocity:MAG*suicideBurnTime.
        LOCAL travelVector IS relVelocity:NORMALIZED*suicideTravelDistance.
        Local finalSeparationDistance IS d - travelVector.

    //        Print "Suicide Burn Time: " + suicideBurnTime.
    //        Print "a: " + a.
    //        PRINT "Distance To Target: " + d:MAG.
    //        PRINT "Remaining Travel Distance: " + r.
    //        Print "Travel Distance: " + suicideTravelDistance.
    //        Print "Final Separation Distance: " + finalSeparationDistance:MAG.

    //        drawVector(d, "Position").
    //        drawVector(-finalSeparationDistance, "Final", d).
    //        drawVector(travelVector, "Travel").

    //TODO: Fudge factor for when we aren't going to come within 30 meters of the station, to ensure we burn at the appropriate time.
        if ( finalSeparationDistance:MAG < minSeparationDistance + 1) {
            BREAK.
        }
        WAIT 0.01.
    }

    shortInfo("Executing Suicide Burn.").
    suicideBurn(targetVessel).
    shortInfo("Suicide Burn Complete.").
}

function suicideBurn {
    parameter targetVessel.
    parameter sourceVessel IS SHIP.

    UNTIL relativeVelocity(targetVessel, sourceVessel):MAG < 0.01 {

        Local relVelocity IS relativeVelocity(targetVessel, sourceVessel).
        Local burnTime IS calculateBurnDuration(relVelocity:MAG).

        SET THROTTLE TO MIN(1, burnTime).
    }

    SET THROTTLE TO 0.
    SET SASMODE TO "STABILITYASSIST".

    Print "Suicide burn complete.  Final Relative Velocity: " + relativeVelocity(targetVessel, sourceVessel):MAG.
    Print "Final Separation Distance: " + separationDistanceAtTime(sourceVessel, targetVessel, TIME:SECONDS).
}
//This function assumes that you have already performed an inclination change and the targetVessel Is in the
//same plane as sourceVessel.  It also assumes that your starting orbit is roughtly circular.
//ThrottleController Parameter is expected to be a delegate bindable to a delegateController which will be bound and then executed.
function hohmannTransfer {
    parameter targetOrbital.
    parameter throttleController IS delegateThrottleController@.

    //1. Calculate Transfer Time.
    PRINT "Calculating Hohmann Transfer Time.  This may take up to 30 seconds.".
    shortInfo("Calculating Hohmann Transfer Time").

    LOCAL transferTime IS getHohmannTransferTime(targetOrbital).

    //2. Calculate Burn Amount.
    LOCAL transferDeltaV IS getHohmannTransferDeltaV(targetOrbital, transferTime).

    //3. Calculate final apoapsis of hohmann transfer orbit
    LOCAL positionVector IS positionVectorAt(SHIP, transferTime).
    LOCAL targetPeriapsisVector IS getPeriapsisVector(targetOrbital).
    LOCAL hohmannTrueAnomaly IS VANG(-positionVector, targetPeriapsisVector).
    LOCAL hohmannRadius IS getRadiusFromTrueAnomaly(targetOrbital, hohmannTrueAnomaly).
    LOCAL desiredRadius IS hohmannRadius - SHIP:ORBIT:BODY:RADIUS.

    Print "Desired Radius: " + desiredRadius.

    //4. Set up Maneuver.
    SET myNode to NODE(transferTime, 0, 0, transferDeltaV).
    ADD myNode.

    //5.  Set up Throttle Controller
    LOCAL hohmannThrottleController IS matchOrbitalRadiusWithManeuverThrottleController@:bind(lexicon()):bind(desiredRadius).

    if (desiredRadius > SHIP:ORBIT:APOAPSIS OR (transferDeltaV < 0 AND desiredRadius > PERIAPSIS)) {
        LOCAL orbitalRadiusSupplier IS {return SHIP:ORBIT:APOAPSIS.}.
        SET hohmannThrottleController TO hohmannThrottleController:bind(orbitalRadiusSupplier).
    } else {
        LOCAL orbitalRadiusSupplier IS {return SHIP:ORBIT:PERIAPSIS.}.
        SET hohmannThrottleController TO hohmannThrottleController:bind(orbitalRadiusSupplier).
    }

    SET hohmannThrottleController TO hohmannThrottleController:bind(myNode).

    //6. Execute Maneuver
    LOCAL controller IS throttleController:bind(hohmannThrottleController).

    executeNextManeuverWithController(controller).

    shortInfo("Hohmann Transfer Complete").
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

    PRINT "Closest Calculated Separation Distance: " + separationDistance.

//Confirm That we haven't already missed our hohmann Transfer Window for this orbit.
//2. Calculate Burn Amount.
    LOCAL transferDeltaV IS getHohmannTransferDeltaV(targetOrbital, transferTime).
    LOCAL burnDuration IS calculateHalfBurnDuration(transferDeltaV).
//	PRINT "Delta V: " + transferDeltaV.
//	PRINT "Half Butn Duration: " + burnDuration.

//This is hardcoded...
    IF separationDistance < 1000 {
        IF TIME:SECONDS + burnDuration > transferTime {
            PRINT "Burn Window Missed For this Orbit.  Calculating beginning With Next Orbit".
        } ELSE {
            return transferTime.
        }
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
    //        WAIT 0.05.
    }

    if(stepDuration < errorBound) {
    //    		PRINT "Achieved requested result in " + iterationCount + " iterations".
    //    		PRINT "Step Duration: " + stepDuration.
    //    		PRINT "Closest Separation Distance: " + closestSeparationDistance.
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
//    drawVector(hohmannPositionVector, "hohmannPositionVector",SHIP:ORBIT:BODY:POSITION).

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
//    drawVector(targetOrbitalPosition, "targetOrbitalPosition",SHIP:ORBIT:BODY:POSITION).

//5. Subtract 3 from 4 and take MAG to get separation distance.
    LOCAL separationDistance IS (hohmannPositionVector - targetOrbitalPosition):MAG.
    return separationDistance.
}

//This function will always burn at the next "ascending node" to match the inclination of the target vessel.
//It will recursively call itself until the final inclination Is < 0.01.
//Note: This functio needs some work.  Calculation of the eccentricity vector Is off, and Is likely affecting
//The calculation of the ascending node location (leading to a pre-burn, which means we have to iterate).
//Furthermore, a smarter algorithm for the inclination burn may help accomplish the plane change with 1 burn and remove
//the need to recurse.
function matchInclination {
    parameter targetOrbital.

    Local relativeInc Is relativeInclination(targetOrbital:ORBIT).

    if (relativeInc < 0.001) {
        PRINT "Inclination Change Complete.".
        PRINT "Final Relative Inclination: " + relativeInclination(targetOrbital:ORBIT).
        return.
    }

    SAS ON.
    SET NAVMODE TO "Orbit".
    WAIT 0.5.
    SET SASMODE TO "ANTINORMAL".
    WAIT 0.5.

    Local shipOrbitalVelocity Is SHIP:ORBIT:VELOCITY:ORBIT.
    Local shipOrbitalPosition Is SHIP:ORBIT:BODY:ORBIT:POSITION.

    PRINT "Rotating to Anti-Normal in preparation for inclination burn.".

    UNTIL (VANG(SHIP:FACING:FOREVECTOR, VCRS(shipOrbitalVelocity,shipOrbitalPosition)) < 0.1) {
    //		CLEARSCREEN.
    //		CLEARVECDRAWS().
    //		PRINT "Angle: " + VANG(SHIP:FACING:FOREVECTOR, VCRS(shipOrbitalVelocity,shipOrbitalPosition)).
    //		drawVector(SHIP:FACING:FOREVECTOR:NORMALIZED*30,"Facing").
    //		drawVector(VCRS(shipOrbitalVelocity,shipOrbitalPosition)*30,"Normal").

        SET shipOrbitalVelocity TO SHIP:ORBIT:VELOCITY:ORBIT.
        SET shipOrbitalPosition TO SHIP:ORBIT:BODY:ORBIT:POSITION.
    }

    Local timeToBurn Is timeToInclinationBurn(targetOrbital).

    IF (timeToBurn - 10 > TIME:SECONDS) {
        WARPTO(timeToBurn - 10).
    }

    UNTIL TIME:SECONDS > timeToBurn {
    //		CLEARSCREEN.
    //		Print "Time to Burn: " + (timeToBurn - TIME:SECONDS).
    }

    inclinationBurn(targetOrbital).

//  We are recursing as our algorithm isn't quite good enough yet.
    matchInclination(targetOrbital).
}

function inclinationBurn {
    parameter targetVessel.

    Local relI Is 1000.

    SET DONE TO FALSE.

    UNTIL FALSE {
        CLEARSCREEN.
        Local newRelI Is relativeInclination(targetVessel:ORBIT).
        PRINT "Old Relative Inclination: " + relI.
        PRINT "New Relative Inclination: " + newRelI.
        if(newRelI - relI > relI*0.01) {
            BREAK.
        }

        if(newRelI > 0.02) {
            SET THROTTLE to 1.0.
        }

        if(newRelI < 0.02) {
            SET THROTTLE TO 0.5.
        }

        if(newRelI < 0.01) {
            SET THROTTLE TO 0.2.
        }

        if(newRelI < 0.005) {
            SET THROTTLE TO 0.1.
        }

        if(newRelI < 0.002) {
            SET THROTTLE TO 0.01.
        }

        SET relI TO newRelI.
        WAIT 0.01.
    }

    SET THROTTLE TO 0.0.

//	WAIT UNTIL THROTTLE = 0.
    WAIT 1.

    UNLOCK THROTTLE.

    PRINT "Inclination Burn Complete.".
}

function timeToInclinationBurn {
    parameter targetVessel.

    //Delta V calculation for inclination change, taken from:
    //https://en.wikipedia.org/wiki/Orbital_inclination_change#Calculation

    Local relativeInc Is relativeInclination(targetVessel:ORBIT).
    PRINT "Relative Inclination: " + relativeInc.

    Local timeAtNextAscendingNode Is timeAtNextRelativeAscendingNode(targetVessel).

    Local vectorToAscendingNode Is positionVectorAt(SHIP, timeAtNextAscendingNode).

    Local trueAnomalyAscending Is trueAnomalyFromStateVectors(vectorToAscendingNode).

    Local deltaVRequired Is inclinationChangeDeltaV(relativeInc, trueAnomalyAscending).

//	PRINT "Delta V Required: " + deltaVRequired.

    Local halfBurnTime Is calculatehalfBurnDuration(deltaVRequired).

//  info("Inclination Change Half Burn Time: " + halfBurnTime).

    SET timeToAscendingNodeBurn TO timeAtNextAscendingNode - halfBurnTime.

    if (timeToAscendingNodeBurn < TIME:SECONDS) {
        SET timeToAscendingNodeBurn TO timeToAscendingNodeBurn + SHIP:ORBIT:PERIOD.
    }

//  Start a tiny bit second early, so we can tail off nicely at the end.
    return timeToAscendingNodeBurn - 0.25.
}

function inclinationChangeDeltaV {
    parameter inclinationChangeDegrees.
    parameter trueAnomalyAtTime.
    Local e Is SHIP:ORBIT:ECCENTRICITY.
    Local omega Is SHIP:ORBIT:ARGUMENTOFPERIAPSIS.
    Local f Is trueAnomalyAtTime.
    Local n Is 360 / SHIP:ORBIT:PERIOD.
    Local a Is SHIP:ORBIT:SEMIMAJORAXIS.

//	PRINT "e: " + e.
//	PRINT "omega: " + omega.
//	PRINT "f: " + f.
//	PRINT "n: " + n.
//	PRINT "a: " + a.

//	Local multiplier Is 2*sqrt(1 - (e*e))*cos(omega + f)*n*a / (1 + (SHIP:ORBIT:ECCENTRICITY * cos(f))).
    Local multiplier Is 2 * VELOCITY:ORBIT:MAG.

    return multiplier * sin(inclinationChangeDegrees/2).
}

function relativeInclination {
    parameter targetOrbit.
    parameter sourceOrbit Is SHIP:ORBIT.

    Local shipOrbitalVelocity Is sourceOrbit:VELOCITY:ORBIT.
    Local shipOrbitalPosition Is -sourceOrbit:BODY:ORBIT:POSITION.

    Local targetOrbitalVelocity Is targetOrbit:VELOCITY:ORBIT.
    Local targetOrbitalPosition Is (targetOrbit:POSITION - targetOrbit:BODY:ORBIT:POSITION).

    Local shipOrbitalMomentum Is VCRS(shipOrbitalPosition, shipOrbitalVelocity).
    Local targetOrbitalMomentum Is VCRS(targetOrbitalPosition, targetOrbitalVelocity).
    Local relativeInc Is VANG(shipOrbitalMomentum, targetOrbitalMomentum).

//	PRINT "Relative Inclination: " + relativeInc.
    return relativeInc.
}

function relativeVelocity {
    parameter targetVessel.
    parameter sourceVessel IS SHIP.

    return sourceVessel:Orbit:Velocity:Orbit - targetVessel:Orbit:Velocity:Orbit.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumSeparation {
    parameter targetVessel.
    parameter sourceVessel Is SHIP.
    parameter startTime IS TIME:SECONDS.

    Local stepNumber Is 4.
    Local stepDuration Is SHIP:ORBIT:PERIOD / stepNumber.

    Local minimumSeparationTime Is timeOfMinimumSeparationIterate(sourceVessel, targetVessel, startTime, stepNumber, stepDuration).

    return minimumSeparationTime.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumSeparationIterate {
    parameter sourceVessel.
    parameter targetVessel.
    parameter startTime.
    parameter stepNumber.
    parameter stepDuration.
    parameter errorBound Is 0.01. //Error bound, in seconds.
    parameter iterationCount Is 1.

    Local closestSeparationDistance Is separationDistanceAtTime(sourceVessel, targetVessel, startTime).
    Local closestSeparationTime Is startTime.

    FROM {Local step Is 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
    //		PRINT "Step is: " + step.
        Local separationTime Is startTime + (step * stepDuration).

    //		PRINT "Separation Time is: " + separationTime.

        Local newClosestSeparationDistance Is separationDistanceAtTime(sourceVessel, targetVessel, separationTime).

        IF (newClosestSeparationDistance < closestSeparationDistance) {
            SET closestSeparationDistance TO newClosestSeparationDistance.
            SET closestSeparationTime TO separationTime.
        }
    }

    if(stepDuration < errorBound) {
    //		PRINT "Achieved requested result in " + iterationCount + " iterations".
    //		PRINT "Step Duration: " + stepDuration.
    //		PRINT "Closest Separation Distance: " + closestSeparationDistance.
        return closestSeparationTime.
    }

    Local newStartTime Is closestSeparationTime - stepDuration.
    Local newStepDuration TO (stepDuration * 2) / stepNumber.

    Local revisedClosestSeparationTime TO timeOfMinimumSeparationIterate(sourceVessel, targetVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

    return revisedClosestSeparationTime.
}

function separationDistanceAtTime {
    parameter sourceVessel.
    parameter targetVessel.
    parameter specificTime.

    Local sourceVesselPosition Is POSITIONAT(sourceVessel, specificTime).
    Local targetVesselPosition Is POSITIONAT(targetVessel, specificTime).

//	PRINT "Source Vessel Position: " + sourceVesselPosition.
//	PRINT "Target Vessel Position: " + targetVesselPosition.

//	drawVector(sourceVesselPosition, "SourcePosition").
//	drawVector(targetVesselPosition, "TargetPosition").

    return (sourceVesselPosition - targetVesselPosition):MAG.
}

function timeToRelativeAscendingNode {
    parameter targetVessel.
    parameter sourceVessel Is SHIP.

    return timeAtNextRelativeAscendingNode(targetVessel, sourceVessel) - TIME:SECONDS.
}

function timeAtNextRelativeAscendingNode {
    parameter targetVessel.
    parameter sourceVessel Is SHIP.

    Local shipOrbitalPosition Is positionVectorAt(sourceVessel, TIME:SECONDS).
    Local targetOrbitalPosition Is positionVectorAt(targetVessel, TIME:SECONDS).

    Local shipOrbitalVelocity Is sourceVessel:ORBIT:VELOCITY:ORBIT.
    Local targetOrbitalVelocity Is targetVessel:ORBIT:VELOCITY:ORBIT.

    Local shipOrbitalMomentum Is VCRS(shipOrbitalPosition, shipOrbitalVelocity).
    Local targetOrbitalMomentum Is VCRS(targetOrbitalPosition, targetOrbitalVelocity).

//	drawVector(shipOrbitalPosition, "Ship Position", sourceVessel:ORBIT:BODY:POSITION).
//	drawVector(shipOrbitalVelocity:NORMALIZED*(sourceVessel:ORBIT:APOAPSIS + sourceVessel:ORBIT:BODY:RADIUS), "Ship Velocity").
//	drawVector(shipOrbitalMomentum:NORMALIZED*(sourceVessel:ORBIT:APOAPSIS + sourceVessel:ORBIT:BODY:RADIUS), "Ship Momentum", sourceVessel:ORBIT:BODY:POSITION).
//	drawVector(targetOrbitalMomentum, "Target Momentum", targetVessel:ORBIT:BODY:POSITION).

//	Local relativeInc Is VANG(shipOrbitalMomentum, targetOrbitalMomentum).
//	PRINT "Relative Inclination: " + relativeInc.

//Ascending Node position and velocity.  Note that magnitude is not correct, but it is also not important.
    Local vectorToAscendingNode Is VCRS(shipOrbitalMomentum, targetOrbitalMomentum):NORMALIZED.
//	LOCAL velocityAtAscendingNode IS VCRS(shipOrbitalMomentum, vectorToAscendingNode):NORMALIZED.

//	drawVector(vectorToAscendingNode:NORMALIZED*(sourceVessel:ORBIT:APOAPSIS + sourceVessel:ORBIT:BODY:RADIUS), "Node Vector", sourceVessel:Orbit:Body:Position).
//	drawVector(velocityAtAscendingNode:NORMALIZED*(sourceVessel:ORBIT:APOAPSIS + sourceVessel:ORBIT:BODY:RADIUS), "Ascending Node Velocity Vector", vectorToAscendingNode:NORMALIZED*(sourceVessel:ORBIT:APOAPSIS + sourceVessel:ORBIT:BODY:RADIUS)+sourceVessel:Orbit:Body:Position).

//The below was taken graciously from the following post:
//https://www.reddit.com/r/Kos/comments/4hhrld/finding_the_relative_andn/

//Calculate eccentricity vector.
//See this equation: https://en.wikipedia.org/wiki/Eccentricity_vector#Calculation
    Local eccentricityVector Is getEccentricityVector(sourceVessel).

//Get True Anomaly of Relative Ascending Node.
//See this equation: https://en.wikipedia.org/wiki/True_anomaly#From_state_vectors
    Local trueAnomalyAscending Is trueAnomalyFromStateVectors(vectorToAscendingNode).

    Local meanAnomalyAscending Is meanAnomalyFromTrueAnomaly(trueAnomalyAscending, eccentricityVector:Mag).

//Get Time to Relative Ascending Node from Periapsis
//	Local t Is ETA:PERIAPSIS + TIME:SECONDS - sourceVessel:ORBIT:PERIOD.
    Local t IS timeAtNextPeriapsis(sourceVessel) - sourceVessel:ORBIT:PERIOD.
    Local n Is 360/sourceVessel:ORBIT:PERIOD.

    Local timeAtNextAscendingNode Is meanAnomalyAscending / n + t.

//	Print "True anomaly ascending: " + trueAnomalyAscending.
//	Print "Mean Anomaly ascending: " + meanAnomalyAscending.

    IF (timeAtNextAscendingNode < TIME:SECONDS) {
        SET timeAtNextAscendingNode TO timeAtNextAscendingNode + sourceVessel:ORBIT:PERIOD.
    }

    LOCAL position IS positionVectorAt(SHIP, timeAtNextAscendingNode).

//	drawVector(position, "Calculated Time At Next Ascending Node", SHIP:ORBIT:BODY:POSITION).

    return timeAtNextAscendingNode.
}