RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").
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
	circularizeAtApoapsis().

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

    UNTIL (VANG(sourceVessel:Facing:Forevector, relativeVelocity(targetVessel, sourceVessel)) < 0.1) {
        CLEARSCREEN.
        CLEARVECDRAWS().

        Local relVelocity IS relativeVelocity(targetVessel, sourceVessel).

//        drawVector(relVelocity, "Relative Velocity").
        PRINT "Relative Velocity: " + relVelocity:MAG.
        Print "Angle: " + VANG(sourceVessel:Facing:Forevector, relativeVelocity(targetVessel, sourceVessel)).

        WAIT 0.01.
    }

    Print "Oriented Correctly.  Waiting for Suicide Burn.".

    LOCAL DONE IS FALSE.

    Local minSeparationDistance IS MAX(30, separationDistance).//Don't come closer than 30 meters.

    UNTIL FALSE {
        CLEARSCREEN.
        CLEARVECDRAWS().
        Local relVelocity IS relativeVelocity(targetVessel, sourceVessel).

        Local suicideBurnTime IS calculateBurnDuration(relVelocity:MAG).

        Local finalSeparationDistance IS separationDistanceAtTime(sourceVessel, targetVessel, TIME:SECONDS + suicideBurnTime).

        Print "Suicide Burn Time: " + suicideBurnTime.
        Print "Separation Distance: " + finalSeparationDistance.
        //TODO: Fudge factor for when we aren't going to come within 50 meters of the station, to ensure we burn at the appropriate time.
        if ( finalSeparationDistance < minSeparationDistance + 1) {
            BREAK.
        }
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

function circularizeAtApoapsis {
    parameter sourceVessel Is SHIP.

	if(sourceVessel:ORBIT:ECCENTRICITY < 0.001) {
		PRINT "Orbit is already circular. Skipping circularization burn.".
		return.
	}

	shortInfo("Calculating Apoapsis Circularization Burn").
	Local nd Is getApoapsisCircularizationBurnManeuverNode(sourceVessel).

	Add nd.

	shortInfo("Executing Circularization Burn").
	executeNextManeuver().

	shortInfo("Circularization Burn Complete").
}

//This function assumes that you have already performed an inclination change and the targetVessel Is in the
//same plane as sourceVessel.
function hohmannTransfer {
	parameter targetVessel.
	parameter sourceVessel Is SHIP.

	//The first step here Is to figure out when to burn to apoapsis.  We have a choice here.  We can either immediately
	//Burn up to apoapsis and then calculate our expected separation distance, or we can figure out the optimal time
	//to Burn up to apoapsis

	//Note, how do we hohman transfer to a lower orbit? Would be nice to handle that in this method as well.

	//Step 1: Identify the point in time to burn prograde (or possibly retrograde) in order raise (or possibly lower) our apoapsis to intersect nicely with the apoapsis of our target.  For highly eccentric orbits this will not result in an efficient transfer, but for most circular orbits this isn't as big a factor, and makes the next step simple, as we now have a well known point of minimum intersection at which we can burn prograde to synchronize the orbital periods to force a rendevous
	//using our target's (and so by our) apoapsis.

	shortInfo("Matching Target Apoapsis").
	shortInfo("Calculating Apoapsis Alighnment Maneuver").
	Local nd Is getManeuverNodeToMatchTargetApoapsis(targetVessel, sourceVessel).

	Add nd.

	//Step 2: Execute Burn to change apoapsis to match our target's apoapsis.
	shortInfo("Executing Apoapsis Alignment Maneuver").
	executeNextManeuver().
	WAIT 2.//Wait for us to stop moving so that next time warp doesn't fail.

	//Step 3: Find out how many rotations we need to warp through until the target vessel
	//is on it's closest approach to us.
	shortInfo("Calculating Time to Closest Approach").
	Local closestApproachAtApoapsisTime Is getTimeToClosestApproachAt(targetVessel, timeAtNextApoapsis(sourceVessel), sourceVessel).

	Local periapsisBeforeClosestApproachTime Is closestApproachAtApoapsisTime - sourceVessel:ORBIT:PERIOD/2.

	IF (periapsisBeforeClosestApproachTime > TIME:SECONDS) {
		shortInfo("Warping to Closest approach").
        WARPTO(periapsisBeforeClosestApproachTime).
        WAIT UNTIL periapsisBeforeClosestApproachTime < TIME:SECONDS.
    }

	shortInfo("Calculating Minimum Orbital intersection...this may take up to 30 seconds.").
	Local timeAtIntersection Is timeOfMinimumOrbitalIntersection(targetVessel, periapsisBeforeClosestApproachTime, SHIP).

	info("Forcing a Rendevous").
	shortInfo("Calculating Rendevous Burn").
	Local rendevousBurnDeltaV Is calculateRendevousBurnDeltaV(target, timeAtIntersection).

//	Print "Needed Delta V to Synchronize Orbits: " + rendevousBurnDeltaV.

	Local nd Is NODE(timeAtIntersection, 0, 0, rendevousBurnDeltaV).

	Add nd.

	SAS ON.
	SET SASMODE TO "MANEUVER".

	shortInfo("Rotating to Rendevous Burn").
	UNTIL VANG(SHIP:FACING:VECTOR, nd:BURNVECTOR) < 0.1 {
		CLEARSCREEN.
		PRINT "Orienting to Rendevous Burn".
		Print "Angle: " + VANG(SHIP:FACING:VECTOR, nd:BURNVECTOR).
	}

	Local halfBurnDuration Is calculatehalfBurnDuration(rendevousBurnDeltaV).
	Local rendevousBurnTime Is timeAtIntersection - halfBurnDuration.

	IF (rendevousBurnTime > TIME:SECONDS - 15) {
		shortInfo("Warping to Rendevous Burn").
        WARPTO(rendevousBurnTime - 15).
    }

	UNTIL TIME:SECONDS > rendevousBurnTime {
		CLEARSCREEN.
		Print "Time to Rendevous Burn: " + (rendevousBurnTime - TIME:SECONDS).
	}

	//Step 4: Perform the Rendevous Burn.
	shortInfo("Executing Rendevous Burn").
	executeNextManeuver().
	shortInfo("Hohmann Transfer Complete").
}

function calculateRendevousBurnDeltaV {
	parameter targetVessel.
	parameter timeOfOrbitalIntersectionAtClosestApproach.
	parameter sourceVessel Is SHIP.

	//Step 1: Calculate Needed Orbital period to meet target at next time of orbital intersection.
	//TODO: Think about changing this to just use "now", and add orbital periods after calculating time of minimum angle
	//vector.
	Local startTime Is timeAtNextPeriapsis(targetVessel).
	UNTIL startTime > timeOfOrbitalIntersectionAtClosestApproach {
		SET startTime TO startTime + targetVessel:Orbit:Period.
	}

	Local targetTimeAtNextIntersection IS
	timeofMinimumVectorAngle(sourceVessel, timeOfOrbitalIntersectionAtClosestApproach, startTime, targetVessel).

	Local neededSourceVesselPeriod Is targetTimeAtNextIntersection - timeOfOrbitalIntersectionAtClosestApproach.

	Print "Needed Source Vessel Period: " + neededSourceVesselPeriod.
	Print "Current Source Vessel Period: " + sourceVessel:Orbit:Period.

	//Step 2: Calculate Needed semi major axis length to have that orbital period.
	//See https://en.wikipedia.org/wiki/Orbital_period#Small_body_orbiting_a_central_body
	Local mu Is sourceVessel:Orbit:Body:Mu.
	Local neededSemiMajorAxis Is (mu*(neededSourceVesselPeriod^2) / (4*(CONSTANT:PI^2)))^(1.0/3.0).

	Print "Needed Source Vessel Semi Major Axis: " + neededSemiMajorAxis.
	Print "Current Source Vessel Semi Major Axis: " + sourceVessel:Orbit:SemiMajorAxis.

	//Step 3: Calculate needed orbital velocity at timeOfOrbitalIntersectionAtClosestApproach
	//See https://en.wikipedia.org/wiki/Vis-viva_equation.
	Local r Is positionVectorAt(sourceVessel, timeOfOrbitalIntersectionAtClosestApproach):MAG.
	Local neededOrbitalVelocityAtIntersection Is SQRT(mu*(2/r - 1/neededSemiMajorAxis)).

	//Step 4: difference in Delta V Is simply the needed orbital velocity minus current velocity
	//at the time of orbital intersection at closest approach.
	Local currentOrbitalVelocityAtIntersection Is VelocityAt(sourceVessel,timeOfOrbitalIntersectionAtClosestApproach):ORBIT:MAG.
	Local neededDeltaV Is neededOrbitalVelocityAtIntersection - currentOrbitalVelocityAtIntersection.

	return neededDeltaV.
}

//This function will return a maneuver node which will
//align the periapsis & apoapsis of the sourceVessel with the targetVessel.
//This function assumes the two vessels are already in the same plane.
//This function needs some improvement, the location of the final apoapsis Is not exactly right, but darn close!
function getManeuverNodeToMatchTargetApoapsis {
	parameter targetVessel.
	parameter sourceVessel Is SHIP.

	Local timeAtApoapsis Is timeAtNextApoapsis(targetVessel).

	Local targetPeriapsisVector Is -positionVectorAt(targetVessel, timeAtApoapsis).

	Local t Is timeofMaximumVectorAngle(targetVessel, timeAtApoapsis, sourceVessel).

	Local positionVector Is positionVectorAt(sourceVessel, t).

//	PRINT "Time of maximum Vector Angle: " + t.

//	drawVector(targetPeriapsisVector, "Periapsis Vector", sourceVessel:ORBIT:BODY:POSITION).
//	drawVector(positionVector, "Maximum Angle", sourceVessel:ORBIT:BODY:POSITION).

	Local deltaV Is deltaVToChangeApoapsisAt(t, targetVessel:ORBIT:APOAPSIS, sourceVessel).

    // future orbit properties
    Local r2 Is positionVectorAt(sourceVessel, t):MAG.
    Local sma2 Is (r2 + sourceVessel:ORBIT:BODY:RADIUS + targetVessel:ORBIT:APOAPSIS)/2. // semi major axis target orbit
    Local v2 Is sqrt((sourceVessel:ORBIT:BODY:mu * (2/r2 - 1/sma2 ) ) ).

	Local targetApoapsisProgradeVector Is VelocityAt(targetVessel, timeAtApoapsis):ORBIT.

	Local sourceProgradeVectorAtNewPeriapsis Is VelocityAt(sourceVessel, t):ORBIT.

	Local neededProgradeVectorAtNewPeriapsis Is -targetApoapsisProgradeVector:NORMALIZED*v2.

//	PRINT "Needed Prograde velocity: " + neededProgradeVectorAtNewPeriapsis:MAG.

	Local deltaVector Is neededProgradeVectorAtNewPeriapsis - sourceProgradeVectorAtNewPeriapsis.

	//Need to convert deltaVector to
//	PRINT "Needed Delta V: " + deltaVector:MAG.

//	PRINT "Vector: " + deltaVector.

	Local vectorAngleDiff Is VANG(neededProgradeVectorAtNewPeriapsis, sourceProgradeVectorAtNewPeriapsis).

	//Let's try out this shnazzy eq.
	Local argOfPerDeltaV Is 2*sqrt(sourceVessel:ORBIT:BODY:MU / (sma2*(1-sourceVessel:ORBIT:ECCENTRICITY^2)))*sin(vectorAngleDiff/2).

//	PRINT "Vector Angle Diff: " + vectorAngleDiff.
//	PRINT "argOfPerDeltaV: " + argOfPerDeltaV.

//	PRINT "cos of argOfPerDeltaV: " + cos(vectorAngleDiff)*argOfPerDeltaV.

//	PRINT "cosAngle: " + cos(vectorAngleDiff)*cos(vectorAngleDiff)*deltaVector:MAG.
//	PRINT "sinAngle: " + sin(vectorAngleDiff)*deltaVector:MAG.

    Local nd Is node(t, argOfPerDeltaV, 0, deltaVector:MAG).

    return nd.
}

function deltaVToChangeApoapsisAt {
    parameter newPeriapsisTime.
    parameter newApoapsis.
    parameter sourceVessel Is SHIP.

    Local mu Is body:mu.
    Local br Is body:radius.

    // present orbit properties
    Local vom Is velocity:orbit:mag.               // actual velocity
    Local r Is br + altitude.                      // actual distance to body

    Local v1 Is VelocityAt(sourceVessel, newPeriapsisTime):ORBIT:MAG. //velocity at new burn periapsis
    Local sma1 Is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

//    PRINT "r: " + r.
//    PRINT "sma1: " + sma1.
//    PRINT "Known Sma1: " + ship:ORBIT:SEMIMAJORAXIS.
//    PRINT "Vom: " + vom.
//    PRINT "MU: " + mu.

    // future orbit properties
    Local r2 Is positionVectorAt(sourceVessel, newPeriapsisTime):MAG.
    Local sma2 Is (r2 + br + newApoapsis)/2. // semi major axis target orbit
    Local v2 Is sqrt((mu * (2/r2 - 1/sma2 ) ) ).

//    PRINT "r2: " + r2.
//    PRINT "sma2: " + sma2.
//    PRINT  "V2: " + v2.
//    PRINT "VOM ^ 2: " + vom^2.

//    PRINT "Other Stuff: " + (2/r2 - 1/sma2 ).
//    PRINT "Other Stuff * mu: " + (2/r2 - 1/sma2 ) * mu.

    // create node
    Local deltav Is v2 - v1.

    return deltaV.
}

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

function getApoapsisCircularizationBurnManeuverNode {
    parameter sourceVessel.

    Local timeAtApoapsis Is timeAtNextApoapsis(sourceVessel).
    Local mu Is sourceVessel:Orbit:Body:Mu.
    Local vi Is VelocityAt(sourceVessel, timeAtApoapsis):Orbit:MAG.
    Local r Is positionVectorAt(sourceVessel, timeAtApoapsis):MAG.

    Local vf Is sqrt(mu /r).

    // create node
    Local deltav Is vf - vi.
    Local nd Is node(timeAtApoapsis, 0, 0, deltav).
    return nd.
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

//This function will always burn at the next "ascending node" to match the inclination of the target vessel.
//It will recursively call itself until the final inclination Is < 0.01.
//Note: This functio needs some work.  Calculation of the eccentricity vector Is off, and Is likely affecting
//The calculation of the ascending node location (leading to a pre-burn, which means we have to iterate).
//Furthermore, a smarter algorithm for the inclination burn may help accomplish the plane change with 1 burn and remove
//the need to recurse.
function matchInclination {
	parameter targetVessel.

	Local relativeInc Is relativeInclination(targetVessel:ORBIT).

	if (relativeInc < 0.001) {
		PRINT "Inclination Change Complete.".
		PRINT "Final Relative Inclination: " + relativeInclination(targetVessel:ORBIT).
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

	Local timeToBurn Is timeToInclinationBurn(targetVessel).

	IF (timeToBurn - 10 > TIME:SECONDS) {
        WARPTO(timeToBurn - 10).
    }

	UNTIL TIME:SECONDS > timeToBurn {
//		CLEARSCREEN.
//		Print "Time to Burn: " + (timeToBurn - TIME:SECONDS).
	}

	inclinationBurn(targetVessel).

	//We are recursing as our algorithm isn't quite good enough yet.
	matchInclination(targetVessel).
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

	//info("Inclination Change Half Burn Time: " + halfBurnTime).

	SET timeToAscendingNodeBurn TO timeAtNextAscendingNode - halfBurnTime.

	if (timeToAscendingNodeBurn < TIME:SECONDS) {
		SET timeToAscendingNodeBurn TO timeToAscendingNodeBurn + SHIP:ORBIT:PERIOD.
	}

	//Start a tiny bit second early, so we can tail off nicely at the end.
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

    return targetVessel:Orbit:Velocity:Orbit - sourceVessel:Orbit:Velocity:Orbit.
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