//THIS FILE IS UNUSED.  Keeping for posteritiy, and in the unlikely event that it becomes useful.

RUNONCEPATH("0:/rendevous/rendevous.ks").

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumOrbitalIntersection {
    parameter targetVessel.
    parameter afterTime.
    parameter sourceVessel Is SHIP.

    Local startTime Is afterTime.
    Local stepNumber Is 5.
    Local stepDuration Is SHIP:ORBIT:PERIOD / stepNumber.

    Local minimumSeparationTime Is timeOfMinimumOrbitalIntersectionIterate(sourceVessel, targetVessel, startTime, stepNumber, stepDuration).

    return minimumSeparationTime.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumOrbitalIntersectionIterate {
    parameter sourceVessel.
    parameter targetVessel.
    parameter startTime.
    parameter stepNumber.
    parameter stepDuration.
    parameter errorBound Is 0.01. //Error bound, in seconds.
    parameter iterationCount Is 1.

    Local minimumOrbitalIntersectionDistance Is timeOfMinimumVectorAngle(sourceVessel, startTime, TIME:SECONDS, targetVessel).
    Local minimumOrbitalIntersectionTime Is startTime.

    FROM {Local step Is 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
    //		PRINT "Step is: " + step.
        Local intersectionTime Is startTime + (step * stepDuration).

    //		PRINT "IntersectionTime: " + intersectionTime.
        Local sourceVesselPosition Is positionVectorAt(sourceVessel, intersectionTime).

        Local minimumVectorAngleTime Is timeOfMinimumVectorAngle(sourceVessel, intersectionTime, TIME:SECONDS, targetVessel).
        Local targetVesselPosition Is positionVectorAt(targetVessel, minimumVectorAngleTime).

    //		drawVector(sourceVesselPosition, "SourcePosition." + step, sourceVessel:ORBIT:BODY:POSITION).
    //		drawVector(targetVesselPosition, "TargetPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

    //	PRINT "Source Vessel Position: " + sourceVesselPosition.
    //	PRINT "Target Vessel Position: " + targetVesselPosition.

        Local newOrbitalIntersectionDistance Is (targetVesselPosition - sourceVesselPosition):MAG.

        IF (newOrbitalIntersectionDistance < minimumOrbitalIntersectionDistance) {
            SET minimumOrbitalIntersectionDistance TO newOrbitalIntersectionDistance.
            SET minimumOrbitalIntersectionTime TO intersectionTime.
        }
    }

    if(stepDuration < errorBound) {
    //		PRINT "Achieved requested result in " + iterationCount + " iterations".
    //		PRINT "Step Duration: " + stepDuration.
        PRINT "MinimumOrbitalIntersectionDistance: " + minimumOrbitalIntersectionDistance.
        return minimumOrbitalIntersectionTime.
    }

//	drawVector(positionVectorAt(sourceVessel, minimumOrbitalIntersectionTime), "Iteraction." + iterationCount, sourceVessel:ORBIT:BODY:POSITION).

    Local newStartTime Is minimumOrbitalIntersectionTime - stepDuration.
    Local newStepDuration TO (stepDuration * 2) / stepNumber.

    Local revisedMinimumOrbitalIntersectionTime TO timeOfMinimumOrbitalIntersectionIterate(sourceVessel, targetVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

    return revisedMinimumOrbitalIntersectionTime.
}

//Hybrid which gets a good estimate using VectorAngle2, then refines it using the iterations.
//This method Is only slightly faster than method 1, but Is slightly less accurate.
function timeOfMinimumVectorAngle3 {
    parameter targetVessel.
    parameter pointInTime.
    parameter sourceVessel Is SHIP.

    Local guesstime Is timeOfMinimumVectorAngle2(targetVessel, pointIntime, sourceVessel).

    Local positionVectorAtTime Is positionVectorAt(targetVessel, pointInTime).

    Local stepNumber Is 4.
    Local stepDuration Is 30 / stepNumber. //30 seconds should be a small enough band.

    Local minimumVectorAngleTime Is timeofMinimumVectorAngleIterate(positionVectorAtTime, sourceVessel, guesstime - 15, stepNumber, stepDuration).

    return minimumVectorAngleTime.
}

//****EXPERIMENT, NOT YET FIGURED OUT.  BUT CLOSE******
//The below functions might be replaceable with a deterministic function instead of iteraction.  Steps would be as follows:
//Input:   targetVessel, pointInTime, sourceVessel.
//Step 1: Get point in time at apoapsis of both target and source vessel.
//Step 2: Get the true anomaly of the source vessel at the target vessels time to apoapsis.
//Step 3: Calculate the "delta true anomaly" of source and target vessel.
//Step 4: Get true anomaly of targetVessel orbit at time "pointInTime".
//Step 5: Use the delta true anomaly to get the true anomaly of sourceVessel at pointInTime.
//Step 6: Calculate eccentric anomaly at pointInTime of sourceVessel orbit using true anomaly and eccentricity.
//Step 7: Calcualte source vessel mean anomaly at pointInTime from eccentric anomaly
//Step 8: Calculate time diff from sourceVessel point at Periapsis using period and Kepler's equation (see mobile bookmarks).
//Step 9: Calculate sourceVessel next time to periapsis and add time diff to get t, which should be the time at which the
//mean anomaly of source vessel Is the meanAnomaly at pointInTime, meaning it *should* be the time at which
//the sourceVessel Is closest in its orbit to the target vessels orbit at the same point (rotation about it's orbit).
//This point can be used to identify the "orbital intercept" distance at that point.
//Using iteration, you should be able to calculate the time to "Orbital Intercept" (time when the spacecraft would be nearest each other if they were at the same point in their orbit).

//This method Is much faster than the iterative approach, but Is innacurate up to several seconds. Good for getting a good estimate, but not for accuracy.
function timeOfMinimumVectorAngle2 {
    parameter targetVessel.
    parameter pointInTime.
    parameter sourceVessel Is SHIP.

//	Print "Step 1".
//Step 1: Get point in time at apoapsis of both target and source vessel.
    Local sourceTimeAtNextApoapsis Is timeAtNextApoapsis(sourceVessel).
    Local targetTimeAtNextApoapsis Is timeAtNextApoapsis(targetVessel).

//	Print "Step 2".
//Step 2: Get the true anomaly of the source vessel at the target vessels time to apoapsis.
    Local sourceTrueAnomalyAtTargetApoapsis Is trueAnomalyAt(targetTimeAtNextApoapsis, sourceVessel).

//	Print "Step 3".
//Step 3: Calculate the "delta mean anomaly" of source and target vessel. Note that this needs to be signed.
    Local sourcePositionAtApoapsis Is positionVectorAt(sourceVessel, sourceTimeAtNextApoapsis).
    Local targetPositionAtApoapsis Is positionVectorAt(targetVessel, targetTimeAtNextApoapsis).

    Local apoapsisAngle Is VANG(sourcePositionAtApoapsis, targetPositionAtApoapsis).

    Local sourceOrbitNormal Is VCRS(positionVectorAt(sourceVessel, pointInTime), VelocityAt(sourceVessel, pointInTime):ORBIT).
    Local apoapsisNormal Is VCRS(positionVectorAt(sourceVessel, sourceTimeAtNextApoapsis),
            positionVectorAt(targetVessel, targetTimeAtNextApoapsis)).

    IF VANG(sourceOrbitNormal, apoapsisNormal) < 180 {
        SET apoapsisAngle TO -apoapsisAngle.
    }

    Local deltaMeanAnomaly Is apoapsisAngle.

    Print "Delta Mean Anomaly: " + deltaMeanAnomaly.

//	Print "Step 4".
//Step 4: Get mean anomaly of targetVessel orbit at time "pointInTime".
    Local targetVesselTrueAnomaly Is trueAnomalyAt(pointInTime, targetVessel).
    Local targetVesselMeanAnomaly Is meanAnomalyFromTrueAnomaly(targetVesselTrueAnomaly, targetVessel:ORBIT:ECCENTRICITY).

//	if (positionVectorAt(targetVessel,pointInTime) * VelocityAt(targetVessel,pointInTime):ORBIT < 0) {
//		SET targetVesselMeanAnomaly TO 360 - targetVesselMeanAnomaly.
//	}

//Step 5: Use the "delta mean anomaly" to get the mean anomaly of sourceVessel at pointInTime.
    Local sourceVesselMeanAnomaly Is targetVesselMeanAnomaly - deltaMeanAnomaly.

    SET targetVesselMeanAnomaly TO MOD(targetVesselMeanAnomaly + 360,360).
    SET sourceVesselMeanAnomaly TO MOD(sourceVesselMeanAnomaly + 360,360).

    Print "Target Vessel Mean Anomaly: " + targetVesselMeanAnomaly.
    Print "Source Vessel Mean Anomaly: " + sourceVesselMeanAnomaly.

//Step 6: Calculate time diff from sourceVessel point at Periapsis using period and Kepler's equation (see mobile bookmarks).
    Local n Is 360 / sourceVessel:ORBIT:PERIOD.
    Local timeDiffToMeanAnomaly Is sourceVesselMeanAnomaly/n.

//Step 7: Calculate sourceVessel next time to periapsis and add time diff to get t, which should be the time at which the
//mean anomaly of source vessel Is the meanAnomaly at pointInTime, meaning it *should* be the time at which
//the sourceVessel Is closest in its orbit to the target vessels orbit at the same point (rotation about it's orbit).
    Local sourceTimeAtPeriapsis Is timeAtNextPeriapsis(sourceVessel).
    Local timeToPointInTime Is sourceTimeAtPeriapsis + timeDiffToMeanAnomaly.

    if(timeToPointInTime - sourceVessel:ORBIT:PERIOD > TIME:SECONDS) {
        SET timeToPointInTime TO timeToPointInTime - sourceVessel:ORBIT:PERIOD.
    }

    return timeToPointInTime.
}

//Returns the point in time at which the angle between source vessel's position vector (see positionVectorAt())
//and the target vessel's position vector (assumed to be at a specific known point in time/space, such as it's apoapsis)
//is at a minimum.
//
//This function Is very useful for determining the point in time that a rendevous burn to synchronize the periods
//of an orbit should take place, assuming that the vessels were previously placed in to orbits such that their intersection is
//at a minimum at a known point in time/space, such as at the source or target's apoapsis or periapsis.
//
//Note: this function assumes the source and target vessels are orbiting roughly in the same plane.
function timeofMinimumVectorAngle {
    parameter targetVessel.
    parameter pointInTime.
    parameter startTime Is TIME:SECONDS.
    parameter sourceVessel Is SHIP.

    Local positionVectorAtTime Is positionVectorAt(targetVessel, pointInTime).

    Local stepNumber Is 4.
    Local stepDuration Is sourceVessel:ORBIT:PERIOD / stepNumber.

    Local minimumVectorAngleTime Is timeofMinimumVectorAngleIterate(positionVectorAtTime, sourceVessel, startTime, stepNumber, stepDuration).

    return minimumVectorAngleTime.
}

function timeofMinimumVectorAngleIterate {
    parameter positionVector.
    parameter sourceVessel.
    parameter startTime.
    parameter stepNumber.
    parameter stepDuration.
    parameter errorBound Is 0.01. //Error bound, in seconds.
    parameter iterationCount Is 1.

    Local minimumVectorAngle Is VANG(positionVector, positionVectorAt(sourceVessel, startTime)).
    Local minimumVectorAngleTime Is startTime.

    FROM {Local step Is 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
    //		PRINT "Step is: " + step.
        Local vectorAngleTime Is startTime + (step * stepDuration).

    //		PRINT "Vector Angle Time is: " + vectorAngleTime.

        Local vesselPosition Is positionVectorAt(sourceVessel, vectorAngleTime).

    //		drawVector(positionVector, "TestPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

        Local newMinimumVectorAngle Is VANG(vesselPosition, positionVector).

        IF (newMinimumVectorAngle < minimumVectorAngle) {
            SET minimumVectorAngle TO newMinimumVectorAngle.
            SET minimumVectorAngleTime TO vectorAngleTime.
        }
    }

//	Print "Step Duration: " + stepDuration.

    if(stepDuration < errorBound) {
    //		PRINT "Achieved requested result in " + iterationCount + " iterations".
    //		PRINT "Step Duration: " + stepDuration.
    //		PRINT "MinimumVectorAngle: " + minimumVectorAngle.
        return minimumVectorAngleTime.
    }

//	drawVector(positionVectorAt(sourceVessel, minimumVectorAngleTime), "Iteraction." + iterationCount, sourceVessel:ORBIT:BODY:POSITION).

    Local newStartTime Is minimumVectorAngleTime - stepDuration.
    Local newStepDuration TO (stepDuration * 2) / stepNumber.

    Local revisedMinimumVectorAngleTime TO timeofMinimumVectorAngleIterate(positionVector, sourceVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

    return revisedMinimumVectorAngleTime.
}

//Returns the point in time at which the angle between source vessel's position vector (see positionVectorAt())
//and the target vessel's position vector (assumed to be at a specific known point in time/space, such as it's apoapsis)
//is at a maximum.
//
//This function Is very useful for determining the point in time that a burn to minimize the intersection distance at a known point in time/space.  For example, this method might tell you the exact time that you should burn prograde such that your new apoapsis will intersect with your target's apoapsis, making it much easier to perform a rendevous (as you would now know that you need to burn at apoapsis to synchronize your periods to create a rendevous).
//
//Note: this function assumes the source and target vessels are orbiting roughly in the same plane.
function timeofMaximumVectorAngle {
    parameter targetVessel.
    parameter pointInTime.
    parameter sourceVessel Is SHIP.

    Local positionVectorAtTime Is positionVectorAt(targetVessel, pointInTime).

    Local startTime Is TIME:SECONDS.
    Local stepNumber Is 3.
    Local stepDuration Is SHIP:ORBIT:PERIOD / stepNumber.

    Local maximumVectorAngleTime Is timeofMaximumVectorAngleIterate(positionVectorAtTime, sourceVessel, startTime, stepNumber, stepDuration).

    return maximumVectorAngleTime.
}

function timeofMaximumVectorAngleIterate {
    parameter positionVector.
    parameter sourceVessel.
    parameter startTime.
    parameter stepNumber.
    parameter stepDuration.
    parameter errorBound Is 0.01. //Error bound, in seconds.
    parameter iterationCount Is 1.

    Local maximumVectorAngle Is VANG(positionVector, positionVectorAt(sourceVessel, startTime)).
    Local maximumVectorAngleTime Is startTime.

    FROM {Local step Is 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
    //		PRINT "Step is: " + step.
        Local vectorAngleTime Is startTime + (step * stepDuration).

    //		PRINT "Vector Angle Time is: " + vectorAngleTime.

        Local vesselPosition Is positionVectorAt(sourceVessel, vectorAngleTime).

    //		drawVector(positionVector, "TestPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

        Local newMaximumVectorAngle Is VANG(vesselPosition, positionVector).

        IF (newMaximumVectorAngle > maximumVectorAngle) {
            SET maximumVectorAngle TO newMaximumVectorAngle.
            SET maximumVectorAngleTime TO vectorAngleTime.
        }
    }

    if(stepDuration < errorBound) {
    //		PRINT "Achieved requested result in " + iterationCount + " iterations".
    //		PRINT "Step Duration: " + stepDuration.
    //		PRINT "MaximumVectorAngle: " + maximumVectorAngle.
        return maximumVectorAngleTime.
    }

//	drawVector(positionVectorAt(sourceVessel, maximumVectorAngleTime), "Iteraction." + iterationCount, sourceVessel:ORBIT:BODY:POSITION).

    Local newStartTime Is maximumVectorAngleTime - stepDuration.
    Local newStepDuration TO (stepDuration * 2) / stepNumber.

    Local revisedMaximumVectorAngleTime TO timeofMaximumVectorAngleIterate(positionVector, sourceVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

    return revisedMaximumVectorAngleTime.
}

function getTimeToClosestApproachAt {
    parameter targetVessel.
    parameter closestApproachTime.
    parameter sourceVessel Is SHIP.

    Local timeToClosestApproach Is closestApproachTime.

//Safety check, as we aren't sure if the referenced closestApproachTime is
//in the future or in the past.  Ideally it should be in the future, but no harm
//in "catching up" to current time by adding intervals of ORBIT:PERIOD.
    UNTIL timeToClosestApproach > TIME:SECONDS {
        SET timeToClosestApproach TO timeToClosestApproach + sourceVessel:ORBIT:PERIOD.
    }

    UNTIL (trueAnomalyAt(timeToClosestApproach, targetVessel) > 180
            AND trueAnomalyAt(timeToClosestApproach + sourceVessel:ORBIT:PERIOD, targetVessel) < 180) {
        SET timeToClosestApproach TO timeToClosestApproach + sourceVessel:ORBIT:PERIOD.

    //		PRINT "True Anomaly: " + trueAnomalyAt(timeToClosestApproach, targetVessel).

    //		Local sourcePositionVector Is positionVectorAt(sourceVessel, timeToClosestApproach).
    //		Local targetPositionVector Is positionVectorAt(targetVessel, timeToClosestApproach).

    //		drawVector(sourcePositionVector, "Source", sourceVessel:ORBIT:BODY:POSITION).
    //		drawVector(targetPositionVector, "Target", targetVessel:ORBIT:BODY:POSITION).

    //		SET COUNTER TO COUNTER + 1.
    //		WAIT 0.25.
    }

    Print "Final Time To Closest Approach: " + timeToClosestApproach.
    return timeToClosestApproach.
}

//This function will perform a rendevousBurn, meaning that it will begin executing a burn (prograde currently)
//and will terminate the burn once the separation distance between the sourceVessel and the targetVessel on the next
//rotation Is at a minimum.
//Currently Unused, but maybe incorporate into
function rendevousBurn {
    parameter targetVessel.
    parameter minimumSeparationTime. //This Is the time we expect to be at minimum separation after completing burn.
    parameter sourceVessel Is SHIP.

    Local minSeparationDistance Is separationDistanceAtTime(SHIP, targetVessel, minimumSeparationTime).

    UNTIL FALSE {
        CLEARSCREEN.
        Local newDistance Is separationDistanceAtTime(SHIP, targetVessel, minimumSeparationTime).

        PRINT "Minimum Separation Distance: " + newDistance.

        if (newDistance > minSeparationDistance) {
            break.
        }

        SET minSeparationDistance TO newDistance.

        if (newDistance < 100) {
            SET THROTTLE to 0.1.
        } else if (newDistance < 1000) {
            SET THROTTLE to 0.2.
        } else if (newDistance < 2000) {
            SET throttle to 0.5.
        } else {
            SET THROTTLE to 1.0.
        }
    }

    SET THROTTLE TO 0.0.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
}