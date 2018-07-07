function meanAnomalyAt {
	parameter orbitTime.
	parameter sourceVessel IS SHIP.

	Local trueAnomaly IS trueAnomalyAt(orbitTime, sourceVessel).

	Local meanAnomaly IS meanAnomalyFromTrueAnomaly(trueAnomaly, sourceVessel:Orbit:Eccentricity).

	return meanAnomaly.
}

function eccentricAnomalyAt {
	parameter orbitTime.
	parameter sourceVessel IS SHIP.

	Local trueAnomaly IS trueAnomalyAt(orbitTime, sourceVessel).

	Local eccentricAnomaly IS eccentricAnomalyFromTrueAnomaly(trueAnomaly, sourceVessel:Orbit:Eccentricity).

	return eccentricAnomaly.
}

function trueAnomalyAt {
	parameter orbitTime.
	parameter sourceVessel IS SHIP.

	LOCAL orbitalPosition IS positionVectorAt(sourceVessel, orbitTime).
	LOCAL orbitalVelocity IS VelocityAt(sourceVessel,orbitTime):ORBIT.

	return trueAnomalyFromStateVectors(orbitalPosition, orbitalVelocity, sourceVessel).
}

//See this equation: https://en.wikipedia.org/wiki/True_anomaly#From_state_vectors
function trueAnomalyFromStateVectors {
	parameter orbitalPosition.
	parameter orbitalVelocity.
	parameter sourceVessel IS SHIP.

	LOCAL eccentricityVector IS getEccentricityVector(sourceVessel).

//	Print "VDOT: " + VDOT(eccentricityVector, orbitalPosition).
//	Print "Bottom: " + eccentricityVector:MAG * orbitalPosition:MAG.
//	Print "Before Arc Cos: " + VDOT(eccentricityVector, orbitalPosition) / (eccentricityVector:MAG * orbitalPosition:MAG).
//	Print "Arc Cos: " + arccos(VDOT(eccentricityVector, orbitalPosition) / (eccentricityVector:MAG * orbitalPosition:MAG)).

	LOCAL trueAnomaly IS arccos(VDOT(eccentricityVector, orbitalPosition) / (eccentricityVector:MAG * orbitalPosition:MAG)).

	if (orbitalPosition * orbitalVelocity < 0) {
		SET trueAnomaly TO 360 - trueAnomaly.
	}

	return trueAnomaly.
}

function eccentricAnomalyFromTrueAnomaly {
	parameter trueAnomaly.
	parameter eccentricity.

	LOCAL cosE IS (eccentricity + cos(trueAnomaly)) / (1 + (eccentricity * cos(trueAnomaly))).

//	PRINT "cosE: " + cosE.

	LOCAL eccentricAnomaly IS arccos(cosE).

	if(trueAnomaly > 180 AND eccentricAnomaly < 180) {
		SET eccentricAnomaly TO 360 - eccentricAnomaly.
	}

	return eccentricAnomaly.
}

function meanAnomalyFromEccentricAnomaly {
	parameter eccentricAnomaly.
	parameter eccentricity.
	LOCAL meanAnomaly IS eccentricAnomaly - eccentricity * abs(sin(eccentricAnomaly)) * CONSTANT:RADTODEG.

	return meanAnomaly.
}

function meanAnomalyFromTrueAnomaly {
	parameter trueAnomaly.
	parameter eccentricity.

	LOCAL eccentricAnomaly IS eccentricAnomalyFromTrueAnomaly(trueAnomaly, eccentricity).
	LOCAL meanAnomaly IS meanAnomalyFromEccentricAnomaly(eccentricAnomaly, eccentricity).

	return meanAnomaly.
}

//TODO: Change method signature, put sourceVessel as 2nd param, default to SHIP.
function positionVectorAt {
	parameter sourceVessel.
	parameter orbitTime.

	return POSITIONAT(sourceVessel, orbitTime) - sourceVessel:ORBIT:BODY:POSITION.
}

function getEccentricityVector {
	parameter sourceVessel IS SHIP.

	//Method 1, which appears to have some innacuracy:
//	LOCAL shipOrbitalVelocity IS sourceVessel:ORBIT:VELOCITY:ORBIT.
//	LOCAL shipOrbitalPosition IS -sourceVessel:ORBIT:BODY:ORBIT:POSITION.

//	LOCAL shipOrbitalMomentum IS VCRS(shipOrbitalPosition, shipOrbitalVelocity).

//	LOCAL eccentricityVector IS (VCRS(shipOrbitalVelocity, shipOrbitalMomentum) / sourceVessel:ORBIT:BODY:MU)
//								 - (shipOrbitalPosition / shipOrbitalPosition:MAG).

	//Method 2, seems to be more accurate
	LOCAL timeAtPeriapsis IS timeAtNextPeriapsis(sourceVessel).

	LOCAL positionAtPeriapsis IS positionVectorAt(sourceVessel, timeAtPeriapsis).

	LOCAL newEccentricityVector IS positionAtPeriapsis:NORMALIZED * sourceVessel:ORBIT:ECCENTRICITY.

	return newEccentricityVector.
}

//Returns the next instant in time that the source vessel will be at its orbital apoapsis.
function timeAtNextApoapsis {
	parameter sourceVessel IS SHIP.

	return timeToApoapsis(sourceVessel) + TIME:SECONDS.
}

//Returns the next instant in time that the source vessel will be at its orbital periapsis.
function timeAtNextPeriapsis {
	parameter sourceVessel IS SHIP.

	return timeToPeriapsis(sourceVessel) + TIME:SECONDS.
}

//Returns the seconds until the source vessel will be at its orbital periapsis.  To get the actual point in time, add Time:SECONDS.
//Uses time equation
function timeToPeriapsis {
	parameter sourceVessel IS SHIP.

	//1 revolution from last periapsis will be the next time we're at periapsis.
	return timeToOrbitRevolutionsFromLastPeriapsis(1, sourceVessel).
}

//Returns the seconds until the source vessel will be at its orbital apoapsis.  To get the actual point in time, add Time:SECONDS.
//Uses time equation
function timeToApoapsis {
	parameter sourceVessel IS SHIP.

	//Half a revolution will be at apoapsis.
	LOCAL timeToNextApoapsis IS timeToOrbitRevolutionsFromLastPeriapsis(0.5, sourceVessel).
	
	//It's possible that we already passed apoapsis since last periapsis (we're currently on our way towards periapsis)
	IF timeToNextApoapsis < 0 {
		SET timeToNextApoapsis TO timeToNextApoapsis + sourceVessel:ORBIT:PERIOD.
	}

	return timeToNextApoapsis.
}

//Returns the time in seconds until the source vessel goes through the given revolutions
//through it's orbit.  This parameter can be a decimal, and can be used to get the next time
//to periapsis (revolutions = 1), next Apoapsis (revolutions = 0.5), etc.
//Derivation is taken by calculating mean anomaly from eccentric anomaly and then dividing by mean motion.
function timeToOrbitRevolutionsFromLastPeriapsis {
	parameter revolutions.
	parameter sourceVessel IS SHIP.

	LOCAL a iS sourceVessel:ORBIT:SEMIMAJORAXIS.
	LOCAL mu IS sourceVessel:ORBIT:BODY:MU.
	LOCAL e IS sourceVessel:ORBIT:ECCENTRICITY.
	LOCAL period IS sourceVessel:ORBIT:PERIOD.

	LOCAL v is sourceVessel:ORBIT:TRUEANOMALY.
	LOCAL tau IS eccentricAnomalyFromTrueAnomaly(v, e).

//mean anomaly divided by mean motion gives you a reference (t - T) of where we are at in our orbit.
	//see https://en.wikipedia.org/wiki/Mean_anomaly#Formula.
	//Note that for the purposes this calculation we need meanAnomaly in Radians instead of degrees.
	LOCAL timeSinceLastPeriapsis IS sqrt(a*a*a/mu)*(CONSTANT:DegToRad*tau - e*sin(tau)).

//	PRINT "t is: " + t.
//	"Revolutions True Anomaly: " + v.
//	PRINT "Eccentric Anomaly: " + tau.
//	PRINT "Period: " + period.
//	PRINT "Revolutions: " + revolutions.
//	PRINT "timeSinceLastPeriapsis Before negative: " + timeSinceLastPeriapsis.


	return revolutions*period - timeSinceLastPeriapsis.	
}

