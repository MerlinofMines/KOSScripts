RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").
RUNONCEPATH("0:/input.ks").

//rendevousWithPlan().

function rendevousWithPlan {
	LIST Targets IN targets.

	Local targetVessel IS selectTargetVessel(targets, "Select Rendevous Target").

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
	parameter sourceVessel IS SHIP.




// calculate time to sucide burn.

//	WAIT UNTIL (positionAt(targetVessel, TIME:SECONDS) - positionAt(targetVessel, TIME:SECONDS)):MAG < 1000.

//	suicideBurn(targetVessel).


}

function circularizeAtApoapsis {
	parameter sourceVessel IS SHIP.

	shortInfo("Calculating Apoapsis Circularization Burn").
	Local nd IS getApoapsisCircularizationBurnManeuverNode(sourceVessel).

	Add nd.

	shortInfo("Executing Circulration Burn").
	executeNextManeuver().

	shortInfo("Circularization Burn Complete").
}

//This function assumes that you have already performed an inclination change and the targetVessel is in the
//same plane as sourceVessel. 
function hohmannTransfer {
	parameter targetVessel.
	parameter sourceVessel IS SHIP.

	//The first step here is to figure out when to burn to apoapsis.  We have a choice here.  We can either immediately
	//Burn up to apoapsis and then calculate our expected separation distance, or we can figure out the optimal time
	//to Burn up to apoapsis

	//Note, how do we hohman transfer to a lower orbit? Would be nice to handle that in this method as well.

	//Step 1: Identify the point in time to burn prograde (or possibly retrograde) in order raise (or possibly lower) our apoapsis to intersect nicely with the apoapsis of our target.  For highly eccentric orbits this will not result in an efficient transfer, but for most circular orbits this isn't as big a factor, and makes the next step simple, as we now have a well known point of minimum intersection at which we can burn prograde to synchronize the orbital periods to force a rendevous
	//using our target's (and so by our) apoapsis.

	shortInfo("Matching Target Apoapsis").
	shortInfo("Calculating Apoapsis Alighnment Maneuver").
	Local nd IS getManeuverNodeToMatchTargetApoapsis(targetVessel, sourceVessel).

	Add nd.

	//Step 2: Execute Burn to change apoapsis to match our target's apoapsis.
	shortInfo("Executing Apoapsis Alignment Maneuver").
	executeNextManeuver().
	WAIT 2.

	//Step 3: Find out how many rotations we need to warp through until the target vessel
	//is on it's closest approach to us.
	shortInfo("Calculating Time to Closest Approach").
	LOCAL closestApproachAtApoapsisTime IS getTimeToClosestApproachAt(targetVessel, timeAtNextApoapsis(sourceVessel), sourceVessel).

	LOCAL periapsisBeforeClosestApproachTime IS closestApproachAtApoapsisTime - sourceVessel:ORBIT:PERIOD/2.

	IF (periapsisBeforeClosestApproachTime > TIME:SECONDS) {
		shortInfo("Warping to Closest approach").
        WARPTO(periapsisBeforeClosestApproachTime).
        WAIT UNTIL periapsisBeforeClosestApproachTime < TIME:SECONDS.
    }

	shortInfo("Calculating Minimum Orbital intersection").
	Local timeAtIntersection IS timeOfMinimumOrbitalIntersection(targetVessel, periapsisBeforeClosestApproachTime, SHIP).

	info("Forcing a Rendevous").
	shortInfo("Calculating Rendevous Burn").
	LOCAL rendevousBurnDeltaV IS calculateRendevousBurnDeltaV(target, timeAtIntersection).

//	Print "Needed Delta V to Synchronize Orbits: " + rendevousBurnDeltaV.

	Local nd IS NODE(timeAtIntersection, 0, 0, rendevousBurnDeltaV).

	Add nd.

	SAS ON.
	SET SASMODE TO "MANEUVER".

	shortInfo("Rotating to Rendevous Burn").
	UNTIL VANG(SHIP:FACING:VECTOR, nd:BURNVECTOR) < 0.1 {
		CLEARSCREEN.
		PRINT "Orienting to Rendevous Burn".
		Print "Angle: " + VANG(SHIP:FACING:VECTOR, nd:BURNVECTOR).
	}

	LOCAL halfBurnDuration IS calculatehalfBurnDuration(rendevousBurnDeltaV).
	Local rendevousBurnTime IS timeAtIntersection - halfBurnDuration.

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
	parameter sourceVessel IS SHIP.

	//Step 1: Calculate Needed Orbital period to meet target at next time of orbital intersection.
	//TODO: Think about changing this to just use "now", and add orbital periods after calculating time of minimum angle
	//vector.
	Local startTime IS timeAtNextPeriapsis(targetVessel).
	UNTIL startTime > timeOfOrbitalIntersectionAtClosestApproach {
		SET startTime TO startTime + targetVessel:Orbit:Period.
	}

	Local targetTimeAtNextIntersection IS 
	timeofMinimumVectorAngle(sourceVessel, timeOfOrbitalIntersectionAtClosestApproach, startTime, targetVessel).

	Local neededSourceVesselPeriod IS targetTimeAtNextIntersection - timeOfOrbitalIntersectionAtClosestApproach.

	Print "Needed Source Vessel Period: " + neededSourceVesselPeriod.
	Print "Current Source Vessel Period: " + sourceVessel:Orbit:Period.

	//Step 2: Calculate Needed semi major axis length to have that orbital period.
	//See https://en.wikipedia.org/wiki/Orbital_period#Small_body_orbiting_a_central_body
	Local mu IS sourceVessel:Orbit:Body:Mu.
	Local neededSemiMajorAxis IS (mu*(neededSourceVesselPeriod^2) / (4*(CONSTANT:PI^2)))^(1.0/3.0).

	Print "Needed Source Vessel Semi Major Axis: " + neededSemiMajorAxis.
	Print "Current Source Vessel Semi Major Axis: " + sourceVessel:Orbit:SemiMajorAxis.

	//Step 3: Calculate needed orbital velocity at timeOfOrbitalIntersectionAtClosestApproach 
	//See https://en.wikipedia.org/wiki/Vis-viva_equation.
	Local r IS positionVectorAt(sourceVessel, timeOfOrbitalIntersectionAtClosestApproach):MAG.
	Local neededOrbitalVelocityAtIntersection IS SQRT(mu*(2/r - 1/neededSemiMajorAxis)).

	//Step 4: difference in Delta V is simply the needed orbital velocity minus current velocity
	//at the time of orbital intersection at closest approach.
	Local currentOrbitalVelocityAtIntersection IS VelocityAt(sourceVessel,timeOfOrbitalIntersectionAtClosestApproach):ORBIT:MAG.
	Local neededDeltaV IS neededOrbitalVelocityAtIntersection - currentOrbitalVelocityAtIntersection.

	return neededDeltaV.
}

//This function will return a maneuver node which will
//align the periapsis & apoapsis of the sourceVessel with the targetVessel.
//This function assumes the two vessels are already in the same plane.
//This function needs some improvement, the location of the final apoapsis is not exactly right, but darn close!
function getManeuverNodeToMatchTargetApoapsis {
	parameter targetVessel.
	parameter sourceVessel IS SHIP.

	LOCAL timeAtApoapsis IS timeAtNextApoapsis(targetVessel).

	LOCAL targetPeriapsisVector IS -positionVectorAt(targetVessel, timeAtApoapsis).

	LOCAL t IS timeofMaximumVectorAngle(targetVessel, timeAtApoapsis, sourceVessel).

	LOCAL positionVector IS positionVectorAt(sourceVessel, t).

//	PRINT "Time of maximum Vector Angle: " + t.

//	drawVector(targetPeriapsisVector, "Periapsis Vector", sourceVessel:ORBIT:BODY:POSITION).
//	drawVector(positionVector, "Maximum Angle", sourceVessel:ORBIT:BODY:POSITION).

	LOCAL deltaV IS deltaVToChangeApoapsisAt(t, targetVessel:ORBIT:APOAPSIS, sourceVessel).

    // future orbit properties
    local r2 IS positionVectorAt(sourceVessel, t):MAG.
    local sma2 is (r2 + sourceVessel:ORBIT:BODY:RADIUS + targetVessel:ORBIT:APOAPSIS)/2. // semi major axis target orbit
    local v2 is sqrt((sourceVessel:ORBIT:BODY:mu * (2/r2 - 1/sma2 ) ) ).

	LOCAL targetApoapsisProgradeVector IS VelocityAt(targetVessel, timeAtApoapsis):ORBIT.

	LOCAL sourceProgradeVectorAtNewPeriapsis IS VelocityAt(sourceVessel, t):ORBIT.

	LOCAL neededProgradeVectorAtNewPeriapsis IS -targetApoapsisProgradeVector:NORMALIZED*v2.

//	PRINT "Needed Prograde velocity: " + neededProgradeVectorAtNewPeriapsis:MAG.

	LOCAL deltaVector IS neededProgradeVectorAtNewPeriapsis - sourceProgradeVectorAtNewPeriapsis.

	//Need to convert deltaVector to 
//	PRINT "Needed Delta V: " + deltaVector:MAG.

//	PRINT "Vector: " + deltaVector.

	Local vectorAngleDiff IS VANG(neededProgradeVectorAtNewPeriapsis, sourceProgradeVectorAtNewPeriapsis).

	//Let's try out this shnazzy eq.
	LOCAL argOfPerDeltaV IS 2*sqrt(sourceVessel:ORBIT:BODY:MU / (sma2*(1-sourceVessel:ORBIT:ECCENTRICITY^2)))*sin(vectorAngleDiff/2).

//	PRINT "Vector Angle Diff: " + vectorAngleDiff.
//	PRINT "argOfPerDeltaV: " + argOfPerDeltaV.

//	PRINT "cos of argOfPerDeltaV: " + cos(vectorAngleDiff)*argOfPerDeltaV.

//	PRINT "cosAngle: " + cos(vectorAngleDiff)*cos(vectorAngleDiff)*deltaVector:MAG.
//	PRINT "sinAngle: " + sin(vectorAngleDiff)*deltaVector:MAG.

    local nd is node(t, argOfPerDeltaV, 0, deltaVector:MAG).

    return nd.
}

function deltaVToChangeApoapsisAt {
    parameter newPeriapsisTime.
    parameter newApoapsis.
    parameter sourceVessel IS SHIP.

    local mu is body:mu.
    local br is body:radius.

    // present orbit properties
    local vom is velocity:orbit:mag.               // actual velocity
    local r is br + altitude.                      // actual distance to body

    local v1 IS VelocityAt(sourceVessel, newPeriapsisTime):ORBIT:MAG. //velocity at new burn periapsis
    local sma1 is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

//    PRINT "r: " + r.
//    PRINT "sma1: " + sma1.
//    PRINT "Known Sma1: " + ship:ORBIT:SEMIMAJORAXIS.
//    PRINT "Vom: " + vom.
//    PRINT "MU: " + mu.

    // future orbit properties
    local r2 IS positionVectorAt(sourceVessel, newPeriapsisTime):MAG.
    local sma2 is (r2 + br + newApoapsis)/2. // semi major axis target orbit
    local v2 is sqrt((mu * (2/r2 - 1/sma2 ) ) ).

//    PRINT "r2: " + r2.
//    PRINT "sma2: " + sma2.
//    PRINT  "V2: " + v2.
//    PRINT "VOM ^ 2: " + vom^2.

//    PRINT "Other Stuff: " + (2/r2 - 1/sma2 ).
//    PRINT "Other Stuff * mu: " + (2/r2 - 1/sma2 ) * mu.

    // create node
    local deltav is v2 - v1.

    return deltaV.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumOrbitalIntersection {
	parameter targetVessel.
	parameter afterTime.
	parameter sourceVessel IS SHIP.	

	LOCAL startTime IS afterTime.
	LOCAL stepNumber IS 5.
	LOCAL stepDuration IS SHIP:ORBIT:PERIOD / stepNumber.

	LOCAL minimumSeparationTime IS timeOfMinimumOrbitalIntersectionIterate(sourceVessel, targetVessel, startTime, stepNumber, stepDuration).

	return minimumSeparationTime.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumOrbitalIntersectionIterate {
	parameter sourceVessel.
	parameter targetVessel.
	parameter startTime.
	parameter stepNumber.
	parameter stepDuration.
	parameter errorBound IS 0.01. //Error bound, in seconds.
	parameter iterationCount IS 1.

	LOCAL minimumOrbitalIntersectionDistance IS timeOfMinimumVectorAngle(sourceVessel, startTime, TIME:SECONDS, targetVessel).
	LOCAL minimumOrbitalIntersectionTime IS startTime.

	FROM {LOCAL step IS 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
//		PRINT "Step is: " + step.
		LOCAL intersectionTime IS startTime + (step * stepDuration).

//		PRINT "IntersectionTime: " + intersectionTime.
		Local sourceVesselPosition IS positionVectorAt(sourceVessel, intersectionTime).

		Local minimumVectorAngleTime IS timeOfMinimumVectorAngle(sourceVessel, intersectionTime, TIME:SECONDS, targetVessel).
		LOCAL targetVesselPosition IS positionVectorAt(targetVessel, minimumVectorAngleTime).

//		drawVector(sourceVesselPosition, "SourcePosition." + step, sourceVessel:ORBIT:BODY:POSITION).
//		drawVector(targetVesselPosition, "TargetPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

	//	PRINT "Source Vessel Position: " + sourceVesselPosition.
	//	PRINT "Target Vessel Position: " + targetVesselPosition.

		Local newOrbitalIntersectionDistance IS (targetVesselPosition - sourceVesselPosition):MAG.

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

	LOCAL newStartTime IS minimumOrbitalIntersectionTime - stepDuration.
	LOCAL newStepDuration TO (stepDuration * 2) / stepNumber.

	LOCAL revisedMinimumOrbitalIntersectionTime TO timeOfMinimumOrbitalIntersectionIterate(sourceVessel, targetVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

	return revisedMinimumOrbitalIntersectionTime.
}

//Hybrid which gets a good estimate using VectorAngle2, then refines it using the iterations.
//This method is only slightly faster than method 1, but is slightly less accurate.
function timeOfMinimumVectorAngle3 {
	parameter targetVessel.
	parameter pointInTime.
	parameter sourceVessel IS SHIP.

	Local guesstime IS timeOfMinimumVectorAngle2(targetVessel, pointIntime, sourceVessel).
		
	LOCAL positionVectorAtTime IS positionVectorAt(targetVessel, pointInTime).

	LOCAL stepNumber IS 4.
	LOCAL stepDuration IS 30 / stepNumber. //30 seconds should be a small enough band.

	LOCAL minimumVectorAngleTime IS timeofMinimumVectorAngleIterate(positionVectorAtTime, sourceVessel, guesstime - 15, stepNumber, stepDuration).

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
//mean anomaly of source vessel is the meanAnomaly at pointInTime, meaning it *should* be the time at which
//the sourceVessel is closest in its orbit to the target vessels orbit at the same point (rotation about it's orbit).  
//This point can be used to identify the "orbital intercept" distance at that point.  
//Using iteration, you should be able to calculate the time to "Orbital Intercept" (time when the spacecraft would be nearest each other if they were at the same point in their orbit).

//This method is much faster than the iterative approach, but is innacurate up to several seconds. Good for getting a good estimate, but not for accuracy.
function timeOfMinimumVectorAngle2 {
	parameter targetVessel.
	parameter pointInTime.
	parameter sourceVessel IS SHIP.

//	Print "Step 1".
	//Step 1: Get point in time at apoapsis of both target and source vessel. 
	Local sourceTimeAtNextApoapsis IS timeAtNextApoapsis(sourceVessel).
	Local targetTimeAtNextApoapsis IS timeAtNextApoapsis(targetVessel).

//	Print "Step 2".
	//Step 2: Get the true anomaly of the source vessel at the target vessels time to apoapsis.
	Local sourceTrueAnomalyAtTargetApoapsis IS trueAnomalyAt(targetTimeAtNextApoapsis, sourceVessel).

//	Print "Step 3".
	//Step 3: Calculate the "delta mean anomaly" of source and target vessel. Note that this needs to be signed.
	Local sourcePositionAtApoapsis IS positionVectorAt(sourceVessel, sourceTimeAtNextApoapsis).
	Local targetPositionAtApoapsis IS positionVectorAt(targetVessel, targetTimeAtNextApoapsis).

	Local apoapsisAngle IS VANG(sourcePositionAtApoapsis, targetPositionAtApoapsis).

	Local sourceOrbitNormal IS VCRS(positionVectorAt(sourceVessel, pointInTime), VelocityAt(sourceVessel, pointInTime):ORBIT).
	Local apoapsisNormal IS VCRS(positionVectorAt(sourceVessel, sourceTimeAtNextApoapsis),
								 positionVectorAt(targetVessel, targetTimeAtNextApoapsis)).

	IF VANG(sourceOrbitNormal, apoapsisNormal) < 180 {
		SET apoapsisAngle TO -apoapsisAngle.
	}

	Local deltaMeanAnomaly IS apoapsisAngle.

	Print "Delta Mean Anomaly: " + deltaMeanAnomaly.

//	Print "Step 4".
	//Step 4: Get mean anomaly of targetVessel orbit at time "pointInTime".
	Local targetVesselTrueAnomaly IS trueAnomalyAt(pointInTime, targetVessel).
	Local targetVesselMeanAnomaly IS meanAnomalyFromTrueAnomaly(targetVesselTrueAnomaly, targetVessel:ORBIT:ECCENTRICITY).

	if (positionVectorAt(targetVessel,pointInTime) * VelocityAt(targetVessel,pointInTime):ORBIT < 0) {
		SET targetVesselMeanAnomaly TO 360 - targetVesselMeanAnomaly.
	}

	//Step 5: Use the "delta mean anomaly" to get the mean anomaly of sourceVessel at pointInTime.
	Local sourceVesselMeanAnomaly IS targetVesselMeanAnomaly - deltaMeanAnomaly.

	SET targetVesselMeanAnomaly TO MOD(targetVesselMeanAnomaly + 360,360).
	SET sourceVesselMeanAnomaly TO MOD(sourceVesselMeanAnomaly + 360,360). 

	Print "Target Vessel Mean Anomaly: " + targetVesselMeanAnomaly.
	Print "Source Vessel Mean Anomaly: " + sourceVesselMeanAnomaly.

	//Step 6: Calculate time diff from sourceVessel point at Periapsis using period and Kepler's equation (see mobile bookmarks).
	Local n IS 360 / sourceVessel:ORBIT:PERIOD.
	Local timeDiffToMeanAnomaly IS sourceVesselMeanAnomaly/n.

	//Step 7: Calculate sourceVessel next time to periapsis and add time diff to get t, which should be the time at which the
	//mean anomaly of source vessel is the meanAnomaly at pointInTime, meaning it *should* be the time at which
	//the sourceVessel is closest in its orbit to the target vessels orbit at the same point (rotation about it's orbit).  
	Local sourceTimeAtPeriapsis IS timeAtNextPeriapsis(sourceVessel).
	Local timeToPointInTime IS sourceTimeAtPeriapsis + timeDiffToMeanAnomaly.

	if(timeToPointInTime - sourceVessel:ORBIT:PERIOD > TIME:SECONDS) {
		SET timeToPointInTime TO timeToPointInTime - sourceVessel:ORBIT:PERIOD.
	}

	return timeToPointInTime.	
}

//Returns the point in time at which the angle between source vessel's position vector (see positionVectorAt())
//and the target vessel's position vector (assumed to be at a specific known point in time/space, such as it's apoapsis)
//is at a minimum.  
//
//This function is very useful for determining the point in time that a rendevous burn to synchronize the periods
//of an orbit should take place, assuming that the vessels were previously placed in to orbits such that their intersection is
//at a minimum at a known point in time/space, such as at the source or target's apoapsis or periapsis.
//
//Note: this function assumes the source and target vessels are orbiting roughly in the same plane.
function timeofMinimumVectorAngle {
	parameter targetVessel.
	parameter pointInTime.
	parameter startTime IS TIME:SECONDS.
	parameter sourceVessel IS SHIP.

	LOCAL positionVectorAtTime IS positionVectorAt(targetVessel, pointInTime).

	LOCAL stepNumber IS 4.
	LOCAL stepDuration IS sourceVessel:ORBIT:PERIOD / stepNumber.

	LOCAL minimumVectorAngleTime IS timeofMinimumVectorAngleIterate(positionVectorAtTime, sourceVessel, startTime, stepNumber, stepDuration).

	return minimumVectorAngleTime.	
}

function timeofMinimumVectorAngleIterate {
	parameter positionVector.
	parameter sourceVessel.			
	parameter startTime.
	parameter stepNumber.
	parameter stepDuration.
	parameter errorBound IS 0.01. //Error bound, in seconds.
	parameter iterationCount IS 1.

	LOCAL minimumVectorAngle IS VANG(positionVector, positionVectorAt(sourceVessel, startTime)).
	LOCAL minimumVectorAngleTime IS startTime.

	FROM {LOCAL step IS 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
//		PRINT "Step is: " + step.
		LOCAL vectorAngleTime iS startTime + (step * stepDuration).

//		PRINT "Vector Angle Time is: " + vectorAngleTime.

		LOCAL vesselPosition IS positionVectorAt(sourceVessel, vectorAngleTime).

//		drawVector(positionVector, "TestPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

		LOCAL newMinimumVectorAngle IS VANG(vesselPosition, positionVector).

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

	LOCAL newStartTime IS minimumVectorAngleTime - stepDuration.
	LOCAL newStepDuration TO (stepDuration * 2) / stepNumber.

	LOCAL revisedMinimumVectorAngleTime TO timeofMinimumVectorAngleIterate(positionVector, sourceVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

	return revisedMinimumVectorAngleTime.
}

//Returns the point in time at which the angle between source vessel's position vector (see positionVectorAt())
//and the target vessel's position vector (assumed to be at a specific known point in time/space, such as it's apoapsis)
//is at a maximum.
//
//This function is very useful for determining the point in time that a burn to minimize the intersection distance at a known point in time/space.  For example, this method might tell you the exact time that you should burn prograde such that your new apoapsis will intersect with your target's apoapsis, making it much easier to perform a rendevous (as you would now know that you need to burn at apoapsis to synchronize your periods to create a rendevous).
//
//Note: this function assumes the source and target vessels are orbiting roughly in the same plane.
function timeofMaximumVectorAngle {
	parameter targetVessel.
	parameter pointInTime.
	parameter sourceVessel IS SHIP.

	LOCAL positionVectorAtTime IS positionVectorAt(targetVessel, pointInTime).

	LOCAL startTime IS TIME:SECONDS.
	LOCAL stepNumber IS 3.
	LOCAL stepDuration IS SHIP:ORBIT:PERIOD / stepNumber.

	LOCAL maximumVectorAngleTime IS timeofMaximumVectorAngleIterate(positionVectorAtTime, sourceVessel, startTime, stepNumber, stepDuration).

	return maximumVectorAngleTime.
}

function timeofMaximumVectorAngleIterate {
	parameter positionVector.
	parameter sourceVessel.			
	parameter startTime.
	parameter stepNumber.
	parameter stepDuration.
	parameter errorBound IS 0.01. //Error bound, in seconds.
	parameter iterationCount IS 1.

	LOCAL maximumVectorAngle IS VANG(positionVector, positionVectorAt(sourceVessel, startTime)).
	LOCAL maximumVectorAngleTime IS startTime.

	FROM {LOCAL step IS 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
//		PRINT "Step is: " + step.
		LOCAL vectorAngleTime iS startTime + (step * stepDuration).

//		PRINT "Vector Angle Time is: " + vectorAngleTime.

		LOCAL vesselPosition IS positionVectorAt(sourceVessel, vectorAngleTime).

//		drawVector(positionVector, "TestPosition." + step, sourceVessel:ORBIT:BODY:POSITION).

		LOCAL newMaximumVectorAngle IS VANG(vesselPosition, positionVector).

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

	LOCAL newStartTime IS maximumVectorAngleTime - stepDuration.
	LOCAL newStepDuration TO (stepDuration * 2) / stepNumber.

	LOCAL revisedMaximumVectorAngleTime TO timeofMaximumVectorAngleIterate(positionVector, sourceVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

	return revisedMaximumVectorAngleTime.
}

function getApoapsisCircularizationBurnManeuverNode {
    parameter sourceVessel.

    local timeAtApoapsis IS timeAtNextApoapsis(sourceVessel).
    local mu is sourceVessel:Orbit:Body:Mu.
    local vi IS VelocityAt(sourceVessel, timeAtApoapsis):Orbit:MAG.
    local r IS positionVectorAt(sourceVessel, timeAtApoapsis):MAG.

    local vf is sqrt(mu /r).

    // create node
    local deltav is vf - vi.
    local nd is node(timeAtApoapsis, 0, 0, deltav).
    return nd.
}

function getTimeToClosestApproachAt {
	parameter targetVessel.
	parameter closestApproachTime.
	parameter sourceVessel IS SHIP.

	LOCAL timeToClosestApproach IS closestApproachTime.

	//Safety check, as we aren't sure if the referenced closestApproachTime is
	//in the future or in the past.  Ideally it should be in the future, but no harm
	//in "catching up" to current time by adding intervals of ORBIT:PERIOD.
	UNTIL timeToClosestApproach > TIME:SECONDS {
		SET timeToClosestApproach TO timeToClosestApproach + sourceVessel:ORBIT:PERIOD.
	}

	//TODO: This calculation can be made much faster, as we should be able to calculate the "delta" in
	//True anomaly per each orbit.  Since true anomaly is a measure of rotation around a circle, it should be constant.
	//Thus, we can extrapolate future true anomalies by calculating the true anomaly at closest approach and 1 orbit after closest approach.  After that, it's just a matter of continuing to add delta true anomaly until we are satisfied.

	UNTIL (trueAnomalyAt(timeToClosestApproach, targetVessel) > 180
	  AND trueAnomalyAt(timeToClosestApproach + sourceVessel:ORBIT:PERIOD, targetVessel) < 180) {
		SET timeToClosestApproach TO timeToClosestApproach + sourceVessel:ORBIT:PERIOD.

//		PRINT "True Anomaly: " + trueAnomalyAt(timeToClosestApproach, targetVessel).

//		LOCAL sourcePositionVector IS positionVectorAt(sourceVessel, timeToClosestApproach).
//		LOCAL targetPositionVector IS positionVectorAt(targetVessel, timeToClosestApproach).

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
//rotation is at a minimum.
function rendevousBurn {
	parameter targetVessel.
	parameter minimumSeparationTime. //This is the time we expect to be at minimum separation after completing burn. 
	parameter sourceVessel IS SHIP.

	SET THROTTLE to 1.0.

	LOCAL minSeparationDistance IS separationDistanceAtTime(SHIP, targetVessel, minimumSeparationTime).
	
	UNTIL FALSE {
		CLEARSCREEN.
		LOCAL newDistance IS separationDistanceAtTime(SHIP, targetVessel, minimumSeparationTime).

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
		}
	}

	SET THROTTLE TO 0.0.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
}

//This function will always burn at the next "ascending node" to match the inclination of the target vessel.
//It will recursively call itself until the final inclination is < 0.01.
//Note: This functio needs some work.  Calculation of the eccentricity vector is off, and is likely affecting
//The calculation of the ascending node location (leading to a pre-burn, which means we have to iterate).
//Furthermore, a smarter algorithm for the inclination burn may help accomplish the plane change with 1 burn and remove
//the need to recurse.
function matchInclination {
	parameter targetVessel.

	LOCAL relativeInc IS relativeInclination(targetVessel:ORBIT).

	if (relativeInc < 0.01) {
		PRINT "Inclination Change Complete.".
		PRINT "Final Relative Inclination: " + relativeInclination(targetVessel:ORBIT).
		return.
	}

	SAS ON.
	SET SASMODE TO "ANTINORMAL". 

	LOCAL shipOrbitalVelocity IS SHIP:ORBIT:VELOCITY:ORBIT.
	LOCAL shipOrbitalPosition IS SHIP:ORBIT:BODY:ORBIT:POSITION.

	UNTIL (VANG(SHIP:FACING:FOREVECTOR, VCRS(shipOrbitalVelocity,shipOrbitalPosition)) < 0.1) {
		CLEARSCREEN.
		CLEARVECDRAWS().
		PRINT "Rotating to Anti-Normal in preparation for inclination burn.".
		PRINT "Angle: " + VANG(SHIP:FACING:FOREVECTOR, VCRS(shipOrbitalVelocity,shipOrbitalPosition)).
//		drawVector(SHIP:FACING:FOREVECTOR:NORMALIZED*30,"Facing").
//		drawVector(VCRS(shipOrbitalVelocity,shipOrbitalPosition)*30,"Normal").

		SET shipOrbitalVelocity TO SHIP:ORBIT:VELOCITY:ORBIT.
		SET shipOrbitalPosition TO SHIP:ORBIT:BODY:ORBIT:POSITION.
	}

	LOCAL timeToBurn IS timeToInclinationBurn(targetVessel).

	IF (timeToBurn - 10 > TIME:SECONDS) {
        WARPTO(timeToBurn - 10).
    }

	UNTIL TIME:SECONDS > timeToBurn {
		CLEARSCREEN.
		Print "Time to Burn: " + (timeToBurn - TIME:SECONDS).
	}

	inclinationBurn(targetVessel).

	//We are recursing as our algorithm isn't quite good enough yet.
	matchInclination(targetVessel).
}

function inclinationBurn {
	parameter targetVessel.

	SET THROTTLE to 1.0.

	LOCAL relI IS 1000.

	SET DONE TO FALSE.

	UNTIL FALSE {
		CLEARSCREEN.
		LOCAL newRelI IS relativeInclination(targetVessel:ORBIT).
		PRINT "Relative Inclination: " + newRelI.
		if(newRelI > relI AND newRelI < 0.1) {
			BREAK.
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
	parameter sourceVessel IS SHIP.

	return timeAtNextRelativeAscendingNode(target, sourceVessel) - TIME:SECONDS.	
}

function timeAtNextRelativeAscendingNode {
	parameter targetVessel.
	parameter sourceVessel IS SHIP.

	LOCAL shipOrbitalPosition IS positionVectorAt(sourceVessel, TIME:SECONDS).
	LOCAL targetOrbitalPosition IS positionVectorAt(targetVessel, TIME:SECONDS).

	LOCAL shipOrbitalVelocity IS sourceVessel:ORBIT:VELOCITY:ORBIT.
	LOCAL targetOrbitalVelocity IS targetVessel:ORBIT:VELOCITY:ORBIT.

	LOCAL shipOrbitalMomentum IS VCRS(shipOrbitalPosition, shipOrbitalVelocity).
	LOCAL targetOrbitalMomentum IS VCRS(targetOrbitalPosition, targetOrbitalVelocity).

//	drawVector(shipOrbitalMomentum, "Ship Momentum", sourceVessel:ORBIT:BODY:POSITION).
//	drawVector(targetOrbitalMomentum, "Target Momentum", targetVessel:ORBIT:BODY:POSITION).

//	LOCAL relativeInc IS VANG(shipOrbitalMomentum, targetOrbitalMomentum).
//	PRINT "Relative Inclination: " + relativeInc.

	//Ascending or descending node
	LOCAL vectorToAscendingNode IS VCRS(shipOrbitalMomentum, targetOrbitalMomentum).

//	drawVector(vectorToAscendingNode, "Node Vector", sourceVessel:Orbit:Body:Position).

	//The below was taken graciously from the following post:
	//https://www.reddit.com/r/Kos/comments/4hhrld/finding_the_relative_andn/

	//Calculate eccentricity vector.  
	//See this equation: https://en.wikipedia.org/wiki/Eccentricity_vector#Calculation
	LOCAL eccentricityVector IS getEccentricityVector(sourceVessel).

	//Get True Anomaly of Relative Ascending Node.  
	//See this equation: https://en.wikipedia.org/wiki/True_anomaly#From_state_vectors
	LOCAL trueAnomalyAscending iS trueAnomalyFromStateVectors(vectorToAscendingNode, shipOrbitalVelocity).

	Local meanAnomalyAscending IS meanAnomalyFromTrueAnomaly(trueAnomalyAscending, eccentricityVector:Mag).

	//Get Time to Relative Ascending Node from Periapsis
	LOCAL t IS ETA:PERIAPSIS + TIME:SECONDS - sourceVessel:ORBIT:PERIOD.
	LOCAL n IS 360/sourceVessel:ORBIT:PERIOD.

	LOCAL timeAtNextAscendingNode IS meanAnomalyAscending / n + t.

	if (VANG(positionVectorAt(sourceVessel,timeAtNextAscendingNode), vectorToAscendingNode) > 90) {
		SET meanAnomalyAscending TO 360 - meanAnomalyAscending.
		SET timeAtNextAscendingNode TO meanAnomalyAscending / n + t.
	}

	IF (timeAtNextAscendingNode < TIME:SECONDS) {
		SET timeAtNextAscendingNode TO timeAtNextAscendingNode + sourceVessel:ORBIT:PERIOD.
	}

	return timeAtNextAscendingNode.
}

function timeToInclinationBurn {
	parameter targetVessel.

	//Delta V calculation for inclination change, taken from:
	//https://en.wikipedia.org/wiki/Orbital_inclination_change#Calculation

	LOCAL relativeInc IS relativeInclination(targetVessel:ORBIT).
	PRINT "Relative Inclination: " + relativeInc.

	LOCAL timeAtNextAscendingNode IS timeAtNextRelativeAscendingNode(targetVessel).

	LOCAL vectorToAscendingNode IS positionVectorAt(SHIP, timeAtNextAscendingNode).

	LOCAL shipOrbitalVelocity IS SHIP:ORBIT:VELOCITY:ORBIT.

	LOCAL trueAnomalyAscending iS trueAnomalyFromStateVectors(vectorToAscendingNode, shipOrbitalVelocity).

	LOCAL deltaVRequired IS inclinationChangeDeltaV(relativeInc, trueAnomalyAscending).

//	PRINT "Delta V Required: " + deltaVRequired.

	LOCAL halfBurnTime IS calculatehalfBurnDuration(deltaVRequired).

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
	LOCAL e IS SHIP:ORBIT:ECCENTRICITY.
	LOCAL omega IS SHIP:ORBIT:ARGUMENTOFPERIAPSIS.
	LOCAL f IS trueAnomalyAtTime.
	LOCAL n IS 360 / SHIP:ORBIT:PERIOD.
	LOCAL a IS SHIP:ORBIT:SEMIMAJORAXIS.

	PRINT "e: " + e.
	PRINT "omega: " + omega.
	PRINT "f: " + f.
	PRINT "n: " + n.
	PRINT "a: " + a.

//	LOCAL multiplier IS 2*sqrt(1 - (e*e))*cos(omega + f)*n*a / (1 + (SHIP:ORBIT:ECCENTRICITY * cos(f))).
	LOCAL multiplier IS 2 * VELOCITY:ORBIT:MAG.

	return multiplier * sin(inclinationChangeDegrees/2).
}

function relativeInclination {
	parameter targetOrbit.
	parameter sourceOrbit IS SHIP:ORBIT.

	LOCAL shipOrbitalVelocity IS sourceOrbit:VELOCITY:ORBIT.
	LOCAL shipOrbitalPosition IS -sourceOrbit:BODY:ORBIT:POSITION.

	LOCAL targetOrbitalVelocity IS targetOrbit:VELOCITY:ORBIT.
	LOCAL targetOrbitalPosition IS (targetOrbit:POSITION - targetOrbit:BODY:ORBIT:POSITION).

	LOCAL shipOrbitalMomentum IS VCRS(shipOrbitalPosition, shipOrbitalVelocity).
	LOCAL targetOrbitalMomentum IS VCRS(targetOrbitalPosition, targetOrbitalVelocity).
	LOCAL relativeInc IS VANG(shipOrbitalMomentum, targetOrbitalMomentum).

//	PRINT "Relative Inclination: " + relativeInc.
	return relativeInc.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumSeparation {
	parameter targetVessel.
	parameter sourceVessel IS SHIP.	

	LOCAL startTime IS TIME:SECONDS.
	LOCAL stepNumber IS 4.
	LOCAL stepDuration IS SHIP:ORBIT:PERIOD / stepNumber.

	LOCAL minimumSeparationTime IS timeOfMinimumInterceptionSeparationIterate(sourceVessel, targetVessel, startTime, stepNumber, stepDuration).

	return minimumSeparationTime.
}

//Warning, this function assumes the two vessels are currently orbiting the same body.
function timeOfMinimumSeparationIterate {
	parameter sourceVessel.
	parameter targetVessel.
	parameter startTime.
	parameter stepNumber.
	parameter stepDuration.
	parameter errorBound IS 0.01. //Error bound, in seconds.
	parameter iterationCount IS 1.

	LOCAL closestSeparationDistance IS 10000000000000000.
	LOCAL closestSeparationTime IS startTime.

	FROM {LOCAL step IS 1.} UNTIL step >= stepNumber STEP {SET step TO step + 1.} DO {
//		PRINT "Step is: " + step.
		LOCAL separationTime iS startTime + (step * stepDuration).

//		PRINT "Separation Time is: " + separationTime.

		Local newClosestSeparationDistanceAt IS separationDistanceAtTime(sourceVessel, targetVessel, separationTime).

		IF (newClosestSeparationDistance < closestSeparationDistance) {
			SET closestSeparationDistance TO newClosestSeparationDistance.
			SET closestSeparationTime TO separationTime.
		}
	}

	if(stepDuration < errorBound) {
		PRINT "Achieved requested result in " + iterationCount + " iterations".
		PRINT "Step Duration: " + stepDuration.
		PRINT "Closest Separation Distance: " + closestSeparationDistance.
		return closestSeparationTime.
	}

	LOCAL newStartTime IS closestSeparationTime - stepDuration.
	LOCAL newStepDuration TO (stepDuration * 2) / stepNumber.

	LOCAL revisedClosestSeparationTime TO timeOfMinimumSeparationIterate(sourceVessel, targetVessel, newStartTime, stepNumber, newStepDuration, errorBound, iterationCount+1).

	return revisedMinimumOrbitalIntersectionTime.
}

function separationDistanceAtTime {
	parameter sourceVessel.
	parameter targetVessel.
	parameter specificTime.

	LOCAL sourceVesselPosition IS POSITIONAT(sourceVessel, specificTime).
	LOCAL targetVesselPosition IS POSITIONAT(targetVessel, specificTime).

//	PRINT "Source Vessel Position: " + sourceVesselPosition.
//	PRINT "Target Vessel Position: " + targetVesselPosition.

//	drawVector(sourceVesselPosition, "SourcePosition").
//	drawVector(targetVesselPosition, "TargetPosition").

	return (sourceVesselPosition - targetVesselPosition):MAG.
}