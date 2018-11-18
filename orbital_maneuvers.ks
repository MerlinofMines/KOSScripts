RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").

function circularizeMaintainingApoapsis {
	parameter sourceVessel IS SHIP.

	PRINT "Circularizing Maintaining Apoapsis".

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

//This method of circularization will circularize an orbit while maintaining orientation towards prograde.
//It works by calculating the estimated time it'll take for the engines to circularize at apoapsis and ensuring that
//the this time is less than the time it will take to get to apoapsis.  As the engines fire the time to apoapsis will increase
//and so a steady state can be achieved by controlling the thrust to ensure that we reach apoapsis at the same time that
//our orbit is circularized.

//Input to this method is two Lists of engines, primary and (optional) secondary.  The algorithm will attempt to use
//The primary engines and use the secondary and primary in combination if/when it is determined
//that both are needed to circularize the orbit, etc.

//It's useful for things like circularization during orbital ascent to ensure that your final orbit is circularized correctly,
//especially if you know that you'll need an additional "burn" to reach orbital velocity.

//Important: This method will manipulate the input engines (activating if necessary).  The state of the engines
//after calling this method may, and could likely be, different than when before the method was invoked.
function circularizeMaintainingPrograde {
	parameter primaryEngineList.
	parameter secondaryEngineList IS list().

	PRINT "Circularizing Maintaining Prograde".

	PRINT "Primary Engines: ".
	PRINT primaryEngineList.
	PRINT "Secondary Engines: ".
	PRINT secondaryEngineList.
}

function getApoapsisCircularizationBurnManeuverNode {
	parameter sourceVessel IS SHIP.

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

//TODO: Not sure if this function works, may be better to use the one above and pull out the part which creates a maneuver
//node into a special function.
function calculateCircularizationBurn {
	parameter alt.

	local mu is body:mu.
	local br is body:radius.

// present orbit properties
	local vom is velocity:orbit:mag.               // actual velocity
	local r is br + altitude.                      // actual distance to body
	local ra is br + apoapsis.                     // radius at burn apsis
	local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis

	local sma1 is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

// future orbit properties
	local r2 is br + apoapsis.               // distance after burn at apoapsis
	local sma2 is (alt + 2*br + apoapsis)/2. // semi major axis target orbit
	local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

// create node
	local deltav is v2 - v1.
	local nd is node(time:seconds + eta:apoapsis, 0, 0, deltav).
	return nd.
}

