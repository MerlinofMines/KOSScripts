RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").

function changeOrbitalRadiusAtApoapsis {
	parameter desiredRadius.

	LOCAL deltaV IS getDeltaVForOrbitRadiusChangeAtApoapsis(desiredRadius).

	//create node
	Local nd Is node(timeAtNextApoapsis(), 0, 0, deltaV).
	add nd.

	//execute
	LOCAL throttleController IS matchPeriapsisThrottleController@:bind(lexicon(),desiredRadius).
	executeNextManeuverWithController(throttleController).

	REMOVE nd.
}

function changeOrbitalRadiusAtPeriapsis {
	parameter desiredRadius.

	LOCAL deltaV IS getDeltaVForOrbitRadiusChangeAtPeriapsis(desiredRadius).

	//create node
	Local nd Is node(timeAtNextPeriapsis(), 0, 0, deltaV).
	add nd.

	//TODO: IT's incorrect to assume that the right thing is the apoapsis.  Depending on the burn, the thing we should
	//be watching might be the *new* periapsis.  A determination of which needs to be done based on the expected new orbit.
	//Then, we also need to allow ourselves to burn through the transition from AP->PE, if needed, before we start watching
	//This is likely done using a hybrid approach. (matchOrbitalRadiusWithManeuverThrottleController)
	//execute
	LOCAL throttleController IS matchApoapsisThrottleController@:bind(lexicon(),desiredRadius).
	executeNextManeuverWithController(throttleController).

	REMOVE nd.
}


function matchOrbitalRadiusWithManeuverThrottleController {
	parameter previousState.
	parameter desiredRadius.
	parameter orbitalRadiusSupplier.
	parameter nd. //Maneuver Node
	parameter dv0.//Original vector of maneuver

	//If the lexicon isn't empty, or we're below 5% remaining dV, then we're fine tuning
	IF previousState:LENGTH > 0 OR (nd:deltav:mag/dv0:mag) < 0.05 {
		return matchOrbitalRadiusThrottleController(previousState, desiredRadius, orbitalRadiusSupplier).
	} else {
		return deltaVRemainingThrottleController(nd, dv0).
	}
}

function matchApoapsisThrottleController {
	parameter previousState.
	parameter desiredRadius.
	LOCAL orbitalRadiusSupplier IS {return SHIP:ORBIT:APOAPSIS.}.
	return matchOrbitalRadiusThrottleController(previousState, desiredRadius, orbitalRadiusSupplier).
}

function matchPeriapsisThrottleController {
	parameter previousState.
	parameter desiredRadius.
	LOCAL orbitalRadiusSupplier IS {return SHIP:ORBIT:PERIAPSIS.}.
	return matchOrbitalRadiusThrottleController(previousState, desiredRadius, orbitalRadiusSupplier).
}

function matchOrbitalRadiusThrottleController {
	parameter previousState.
	parameter desiredRadius.
	parameter orbitalRadiusSupplier.

	//First Iteration, set up state and return 100%.
	IF NOT previousState:HASKEY("R") {
		SET previousState["R"] TO orbitalRadiusSupplier().
		SET previousState["T"] TO TIME:SECONDS.
		SET previousState["H"] TO 1.
		WAIT 0.1.//We wait a little longer on the first iteration, as we are expecting it to take time for us to start burning.
		return 1.
	}

	LOCAL previousRadius IS previousState["R"].
	LOCAL previousTime IS previousState["T"].
	LOCAL previousThrottle IS previousState["H"].

	LOCAL newRadius IS orbitalRadiusSupplier().
	LOCAL newTime IS TIME:SECONDS.

	LOCAL radiusChange IS newRadius - previousRadius.
	LOCAL timeChange IS newTime - previousTime.
	LOCAL radiusChangeRate IS radiusChange/timeChange.

	PRINT "Old Radius: " + previousRadius.
	PRINT "New Radius: " + newRadius.
	PRINT "Desired Radius: " + desiredRadius.
	PRINT "Radius change rate: " + radiusChangeRate.


	LOCAL timeToDesiredRadius IS (desiredRadius-newRadius)/(radiusChangeRate).

	PRINT "timeToDesiredRadius: " + timeToDesiredRadius.

	//If we're past our desiredApoapsis, call it quits
	IF timeToDesiredRadius <= 0 RETURN -1.

	//IF we're stupid close to our target orbit, and our change rate is also low, call it quits.
	IF abs(1 - (orbitalRadiusSupplier()/desiredRadius)) < 0.001 AND abs(radiusChangeRate) < 0.1 {
		RETURN -1.
	}

	SET previousState["R"] TO newRadius.
	SET previousState["T"] TO newTime.

	//Need to wait a non-zero amount of time to allow for an actual "burn".
	WAIT 0.01.

	//Still have >1 burn time, previous throttle is ok.
	IF timeToDesiredRadius > 1 {
		return previousThrottle.
	}

	//Time to calculate new throttle.
	LOCAL newThrottle IS min(1,2*timeToDesiredRadius) * previousThrottle.
	SET previousState["H"] TO newThrottle.
	return newThrottle.
}

function circularizeMaintainingApoapsis {
	PRINT "Circularizing Maintaining Apoapsis".

	if(SHIP:ORBIT:ECCENTRICITY < 0.001) {
		PRINT "Orbit is already circular. Skipping circularization burn.".
		return.
	}

	shortInfo("Calculating Apoapsis Circularization Burn").
	Local nd Is getApoapsisCircularizationBurnManeuverNode().
	Add nd.

	shortInfo("Executing Circularization Burn").
	executeNextManeuver().

	shortInfo("Circularization Burn Complete").
}

function circularizeMaintainingPeriapsis {
	PRINT "Circularizing Maintaining Periapsis".

	if(SHIP:ORBIT:ECCENTRICITY < 0.001) {
		PRINT "Orbit is already circular. Skipping circularization burn.".
		return.
	}

	shortInfo("Calculating Periapsis Circularization Burn").
	Local nd Is getPeriapsisCircularizationBurnManeuverNode().
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
	parameter primaryEngines.
	parameter secondaryEngines IS list().

	PRINT "Circularizing Maintaining Prograde".

	SAS ON.
	WAIT 0.5.
	SET SASMODE TO "PROGRADE".

	PRINT "Primary Engines: ".
	PRINT primaryEngines.
	PRINT "Secondary Engines: ".
	PRINT secondaryEngines.

	LOCAL combinedEngines IS primaryEngines:COPY.
	for eng IN secondaryEngines {
		combinedEngines:add(eng).
	}

	PRINT "Combined Engines: ".
	PRINT combinedEngines.

	//Step 1, we need to make sure all engines, primary and secondary, are ignited.
	//If the engine is already ignited, then leave it.
	//If not, then we need to ignite it, but not accidentally turn it "on".  To do this, we need to set the throttle
	//limit on the engine to 0.
	for eng IN combinedEngines {
		if NOT eng:IGNITION {
            SET eng:THRUSTLIMIT TO 0.
            eng:ACTIVATE().
		}
	}

	//Step 2, calculate the max thrust, ISP using only primary.
	LOCAL ispPrimary IS calculateISPForEngines(primaryEngines).
	LOCAL maxThrustPrimary IS calculateMaxThrustForEngines(primaryEngines).

	//Step 3, calculate the max thrust, ISP using only secondary.
//	LOCAL ispSecondary IS calculateISPForEngines(secondaryEngines).
	LOCAL maxThrustSecondary IS calculateMaxThrustForEngines(secondaryEngines).

	//Step 3, calculate the max thrust, ISP using primary and secondary.
	LOCAL ispCombined IS calculateISPForEngines(combinedEngines).
	LOCAL maxThrustCombined IS calculateMaxThrustForEngines(combinedEngines).

	LOCAL primaryOn IS FALSE.//Assume Case 1.
	LOCAL secondaryOn IS FALSE.//Assume Case 1.

	//Step 4, determine the current status of engines (is primary already firing? secondary?).
	for eng in primaryEngines {
		IF(eng:THRUST > 0) { //Engine is on right now!!
			SET primaryOn TO TRUE.
			break.
		}
	}

	for eng in secondaryEngines {
		IF (eng:THRUST > 0) { //Engine is on right now!!
			SET secondaryOn TO TRUE.
			break.
		}
	}
	LOCAL currentCase IS 1.
	LOCAL neededPrimaryThrustLimiter IS 0.0.
	LOCAL neededSecondaryThrustLimiter IS 0.0.

	IF secondaryOn {
		SET currentCase TO 4.
	} ELSE IF primaryOn {
		SET currentCase TO 2.
	}

	LOCAL minEccentricity IS SHIP:ORBIT:ECCENTRICITY.

	//Step 5, iteratively determine if/when we need to fire the primary, or fire primary and secondary, based on current case.
	UNTIL FALSE {
		CLEARSCREEN.
		LOCAL circularizationDeltaV IS getApoapsisCircularizationBurnDeltaV().
		LOCAL primaryBurnDuration IS calculateBurnDurationFromEngineThrust(ispPrimary, maxThrustPrimary, circularizationDeltaV).
//		LOCAL secondaryBurnDuration IS calculateBurnDurationFromEngineThrust(ispSecondary, maxThrustSecondary, circularizationDeltaV).
		LOCAL combinedBurnDuration IS calculateBurnDurationFromEngineThrust(ispCombined, maxThrustCombined, circularizationDeltaV).

//		PRINT "ISP Primary: " + ispPrimary.
//		PRINT "Max Thrust Primary: " + maxThrustPrimary.
//		PRINT "ISP Secondary: " + ispSecondary.
//		PRINT "Max Thrust Secondary: " + maxThrustSecondary.
//		PRINT "ISP Combined: " + ispCombined.
//		PRINT "Max Thrust Combined: " + maxThrustCombined.
//		PRINT "".
		PRINT "Needed Delta V: " + circularizationDeltaV.
		PRINT "Burn Duration Primary: " + primaryBurnDuration.
//		PRINT "Burn Duration Secondary: " + secondaryBurnDuration.
		PRINT "Burn Duration Combined: " + combinedBurnDuration.

		LOCAL timeToAp IS timeToApoapsis().
		LOCAL timeToPe IS timeToPeriapsis().
		LOCAL neededThrustPrimary IS getNeededThrustForDeltaVInDuration(circularizationDeltaV,timeToAp, ispPrimary).
		LOCAL neededThrustCombined IS getNeededThrustForDeltaVInDuration(circularizationDeltaV,timeToAp, ispCombined).
		LOCAL neededBurnDurationPrimary IS calculateBurnDurationFromEngineThrust(ispPrimary, neededThrustPrimary, circularizationDeltaV).
		LOCAL neededBurnDurationCombined IS calculateBurnDurationFromEngineThrust(ispCombined, neededThrustCombined, circularizationDeltaV).

//		PRINT "Needed Thrust Primary: " + neededThrustPrimary.
//		PRINT "Needed Burn Duration Primary: " + neededBurnDurationPrimary.
//		PRINT "Needed Thrust Combined: " + neededThrustCombined.
//		PRINT "Needed Burn Duration Combined: " + neededBurnDurationCombined.
//		PRINT "Time To Ap:           " + timeToAp.

		//Step 6, determine needed case based on needed burn duration primary, time to apoapsis and current case.
		IF timeToAp * 1.5 < combinedBurnDuration {//We're already too late, full throttle.
			SET currentCase TO 4.
			SET neededPrimaryThrustLimiter TO 1.0.
			SET neededSecondaryThrustLimiter TO 1.0.
		//We're in transfer window from case 3 to 4, need to adjust throttle limits, or
		//We're already in case 4 and we still need secondary engines.
		} ELSE IF (timeToAp * 1.25 < combinedBurnDuration) OR (currentCASE = 4 AND timeToAp * 2.0 < primaryBurnDuration) {
			LOCAL neededThrustCombined IS getNeededThrustForDeltaVInDuration(circularizationDeltaV,timeToAp, ispCombined).
			LOCAL neededThrustSecondary IS neededThrustCombined - maxThrustPrimary.

			SET currentCase TO 4.
			SET neededPrimaryThrustLimiter TO 1.0.
			IF NOT secondaryEngines:EMPTY {
				SET neededSecondaryThrustLimiter TO MIN(1,MAX(0,neededThrustSecondary/maxThrustSecondary)).
			}
		//We're in case 3; we know we will need secondary, but not yet.
		} ELSE IF timeToAp * 2.0 < primaryBurnDuration {
			SET currentCase TO 3.
			SET neededPrimaryThrustLimiter TO 1.0.
			SET neededSecondaryThrustLimiter TO 0.0.
		//We're in case 2, or in transfer window from CASE 1 to 2, need to adjust primary throttle, or
		//We're pushing out our apoapsis and time to apoapsis slightly, but not too much.
		} ELSE IF timeToAp < primaryBurnDuration OR (currentCase = 2 AND 0.5*timeToAp < primaryBurnDuration) OR timeToAp < 1 {
			LOCAL neededThrustPrimary IS getNeededThrustForDeltaVInDuration(circularizationDeltaV,timeToAp, ispPrimary).

			SET currentCase TO 2.
			SET neededPrimaryThrustLimiter TO MIN(1,MAX(0,neededThrustPrimary/maxThrustPrimary)).
			SET neededSecondaryThrustLimiter TO 0.0.
		} ELSE { //timeToAp is more than we need if we only burn primary, we're in case 1.
			SET currentCase TO 1.
			SET neededPrimaryThrustLimiter TO 0.0.
			SET neededSecondaryThrustLimiter TO 0.0.
		}

		PRINT "Current Case: " + currentCase.
		PRINT "Needed Primary Thrust Limiter: " + neededPrimaryThrustLimiter.
		PRINT "Needed Secondary Thrust Limiter: " + neededSecondaryThrustLimiter.
		PRINT "Eccentricity: " + SHIP:ORBIT:ECCENTRICITY.

		for eng in primaryEngines {
			SET eng:THRUSTLIMIT TO neededPrimaryThrustLimiter*100.
		}

		for eng in secondaryEngines {
			SET eng:THRUSTLIMIT TO neededSecondaryThrustLimiter*100.
		}

		LOCK THROTTLE TO 1.0.

		IF NOT currentCase = 1 OR SHIP:ORBIT:ECCENTRICITY < 0.000001 OR timeToPe < timeToAp {
			LOCAL newEccentricity IS SHIP:ORBIT:ECCENTRICITY.
			IF newEccentricity <= minEccentricity {
				SET minEccentricity TO newEccentricity.
			} else {
				SET THROTTLE TO 0.0.
				UNLOCK THROTTLE.

				for eng in primaryEngines {
					SET eng:THRUSTLIMIT TO 0.
				}

				for eng in secondaryEngines {
					SET eng:THRUSTLIMIT TO 0.
				}
				RETURN.
			}
		}

	}
}

function getApoapsisCircularizationBurnManeuverNode {
	Local timeAtApoapsis Is ETA:APOAPSIS + TIME:SECONDS.
	Local deltaV Is getApoapsisCircularizationBurnDeltaV().

	//create node
	Local nd Is node(timeAtApoapsis, 0, 0, deltaV).
	return nd.
}

function getPeriapsisCircularizationBurnManeuverNode {
	Local timeAtPeriapsis Is ETA:PERIAPSIS + TIME:SECONDS.
	Local deltaV Is getPeriapsisCircularizationBurnDeltaV().

	//create node
	Local nd Is node(timeAtPeriapsis, 0, 0, -deltaV).
	return nd.
}

function getDeltaVForOrbitRadiusChangeAtApoapsis {
	parameter desiredRadius.

	LOCAL r IS SHIP:ORBIT:BODY:RADIUS.
	LOCAL a IS (SHIP:ORBIT:APOAPSIS + 2*r + desiredRadius)/2.
	LOCAL mu IS SHIP:ORBIT:BODY:MU.

	LOCAL vi IS visViva(SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:APOAPSIS + r, mu).
	LOCAL vf IS visViva(a, SHIP:ORBIT:APOAPSIS + r, mu).

	return vf - vi.
}

function getDeltaVForOrbitRadiusChangeAtPeriapsis {
	parameter desiredRadius.

	LOCAL r IS SHIP:ORBIT:BODY:RADIUS.
	LOCAL a IS (SHIP:ORBIT:PERIAPSIS + 2*r + desiredRadius)/2.
	LOCAL mu IS SHIP:ORBIT:BODY:MU.

	LOCAL vi IS visViva(SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:PERIAPSIS + r, mu).
	LOCAL vf IS visViva(a, SHIP:ORBIT:PERIAPSIS + r, mu).

	PRINT "Axis: " + SHIP:ORBIT:SEMIMAJORAXIS.
	PRINT "Periapsis: " + SHIP:ORBIT:PERIAPSIS.

	PRINT "vi: " + vi.
	PRINT "vf: " + vf.

	PRINT "Velocity at periapsis: " + VELOCITYAT(SHIP,timeAtNextPeriapsis()):ORBIT:MAG.

	return vf - vi.
}

//https://en.wikipedia.org/wiki/Vis-viva_equation
function visViva {
	parameter a.
	parameter r.
	parameter mu.

	return sqrt(mu * ( (2 / r) - ( 1 / a ))).
}

function getApoapsisCircularizationBurnDeltaV {
	Local timeAtApoapsis Is ETA:APOAPSIS + TIME:SECONDS.
	Local mu Is SHIP:Orbit:Body:Mu.
	Local vi Is VelocityAt(SHIP, timeAtApoapsis):Orbit:MAG.
	Local r Is positionVectorAt(SHIP, timeAtApoapsis):MAG.
	Local vf Is sqrt(mu /r).

	// calculate deltaV
	Local deltaV Is vf - vi.
	return deltaV.
}

function getPeriapsisCircularizationBurnDeltaV {
	Local timeAtPeriapsis Is ETA:PERIAPSIS + TIME:SECONDS.
	Local mu Is SHIP:Orbit:Body:Mu.
	Local vi Is VelocityAt(SHIP, timeAtPeriapsis):Orbit:MAG.
	Local r Is positionVectorAt(SHIP, timeAtPeriapsis):MAG.

	PRINT "Orbiting Body: " + SHIP:ORBIT:BODY.
	PRINT "Initial Velocity: " + vi.
	PRINT "Radius: " + r.

	Local vf Is sqrt(mu/r).

	// calculate deltaV
	Local deltaV Is vi - vf.
	return deltaV.
}

function getNeededThrustForDeltaVInDuration {
	parameter deltaV.
	parameter burnDuration.
	parameter isp.

	LOCAL exhaustVelocity IS isp * 9.82.

	LOCAL eTerm IS CONSTANT:e ^ (deltaV / exhaustVelocity).

	LOCAL temp IS (1 - (1/eTerm)).

	LOCAL neededThrust IS SHIP:MASS * exhaustVelocity * temp / burnDuration.

	return neededThrust.
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

