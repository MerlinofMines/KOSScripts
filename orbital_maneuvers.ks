RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").

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

