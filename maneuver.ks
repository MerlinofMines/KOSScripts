function executeNextManeuver {
    SET nd TO NEXTNODE.

    LOCAL controller IS deltaVRemainingThrottleController@:bind(lexicon()):bind(nd).

    executeNextManeuverWithController(controller).
}

function executeNextManeuverWithController {
    parameter throttleController.
    parameter minBurnTime IS 3. //Minimum burn time, prevents innacurate short burns

    // Get Next Maneuver
    SET n TO NEXTNODE.

    SET deltaV to n:BURNVECTOR:MAG.

    LOCAL t IS calculateHalfBurnDuration(deltaV).
    LOCAL throttleLimit IS 1.0.

    SET activeEngines TO getActiveEngines().

    //Very Short Burns tend to be innaccurate, so adjust our throttle limits on active engines before execution to lower thrust limits and extend burn time, if needed.
    if (t < minBurnTime / 2) {
        SET throttleLimit TO  t / (minBurnTime / 2).

        for engine IN activeEngines {
            SET engine:THRUSTLIMIT TO engine:THRUSTLIMIT * throttleLimit.
        }

        SET t TO calculateHalfBurnDuration(deltaV).
    }

    // Set the start and end times.
    SET start_time TO TIME:SECONDS + n:ETA - t.

    SAS ON.
    WAIT 0.5.
    SET SASMODE TO "MANEUVER".

    // Point at the maneuver node.
    WAIT UNTIL VANG(SHIP:FACING:VECTOR, n:BURNVECTOR) < 0.1.

    // Wait for Craft to approach node execution.  Assuming 30 seconds is enough time to orient the spacecraft.
    IF (start_time - TIME:SECONDS > 30) {
        WARPTO(start_time - 30).
    }

    Print "Maneuver Execution in " + (start_time - TIME:SECONDS) + " seconds.".

    // Wait to start the burn.
    WAIT UNTIL TIME:SECONDS >= start_time.

    //Start Node Execution, continue until Delta V is exhausted.
    maneuverBurn(throttleController).

    SET throttle TO 0.

    REMOVE n.

    //Reset Throttle Limits.
    for engine IN activeEngines {
        SET engine:THRUSTLIMIT TO engine:THRUSTLIMIT / throttleLimit.
    }
}

//Throttle Controller allows us to burn through maneuvers which are trying to optimize different attributes besides
//just the remaining delta v.  Very useful for long burns for things like encounters, etc which rarely match
//the delta v of the maneuver burn because of the burn duration.
//throttleController is expected to return a value between 0.0 and 1.0 until the burn is complete, at which
//point throttleController should return -1 (or any negative number) indicating that the burn has been completed.
function maneuverBurn {
    parameter throttleController.

    SET myThrottle TO THROTTLE.

    LOCK THROTTLE TO myThrottle.

    LOCAL newThrottle IS throttleController().

    UNTIL newThrottle < 0 {
        CLEARSCREEN.
        SET myThrottle TO newThrottle.
        SET newThrottle TO throttleController().

        PRINT "Throttle: " + myThrottle.
    }

    lock throttle to 0.
    PRINT "Maneuver Complete".
}

//Note, this is a factory for a controller, not an actual controller.
function deltaVRemainingWithDelegateThrottleControllerFactory {
    parameter delegateController.
    parameter nd.
    parameter deltaVRemainingPercentage IS 0.05.

    LOCAL dv0 IS nd:deltav.
    LOCAL conditional IS { return (nd:deltav:mag/dv0:mag) < deltaVRemainingPercentage. }.

    LOCAL deltaVRemainingController IS deltaVRemainingThrottleController@:bind(lexicon()):bind(nd).

    return conditionalThrottleController@:bind(delegateController):bind(deltaVRemainingController):bind(conditional).
}

function conditionalThrottleController {
    parameter matchesThrottleController.
    parameter otherwiseThrottleController.
    parameter conditional.

    Print "Using conditional Controller".

    if (conditional()) {
        Print "Condition Matches, using matches controller".
        return matchesThrottleController().
    } else {
        Print "Condition Does Not Match, using otherwise controller".
        return otherwiseThrottleController().
    }
}

function delegateThrottleController {
    parameter delegateController.

    return delegateController().
}

function deltaVRemainingThrottleController {
    parameter previousState.
    parameter nd.

    //Store the original vector for comparison later.
    if (NOT previousState:HASKEY("V")) {
        SET previousState["V"] TO nd:deltav.
    }

    LOCAL dv0 IS previousState["V"].

    //recalculate current max_acceleration, as it changes while we burn through fuel
    set max_acc to SHIP:AVAILABLETHRUST/SHIP:MASS.

    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, nd:deltav) < 0
    {
        print "End burn, remain dv " + round(nd:deltav:mag,3) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),3).
        return -1.
    }

    //throttle is 100% until there is less than 0.25 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
    return min(8*nd:deltav:mag/max_acc, 1).
}


function calculateHalfBurnDuration {
    parameter deltaV.

    return calculateBurnDuration(deltaV/2).
}

function calculateBurnDuration {
    parameter deltaV.

    LIST engines IN my_engines.

    LOCAL eIsp IS calculateISPForEngines(my_engines).
    LOCAL eThrust IS calculateAvailableThrustForEngines(my_engines).

    return calculateBurnDurationFromEngineThrust(eIsp, eThrust, deltaV).
}

function calculateISPForEngines {
    parameter engineList IS engines.
    LOCAL eIsp IS 0.

    FOR eng IN engineList {
        IF (eng:IGNITION) {
            SET eIsp TO eIsp + eng:maxthrust / SHIP:MAXTHRUST * eng:isp.
        }
    }

    return eIsp.
}

function calculateMaxThrustForEngines {
    parameter engineList IS engines.
    LOCAL eThrust IS 0.

    FOR eng IN engineList {
        IF (eng:IGNITION) {
            Set eThrust To eThrust + eng:MAXTHRUST.
        }
    }
    return eThrust.
}

function calculateAvailableThrustForEngines {
    parameter engineList IS engines.
    LOCAL eThrust IS 0.

    FOR eng IN engineList {
        IF (eng:IGNITION) {
            SET eThrust TO eThrust + eng:AVAILABLETHRUST.
        }
    }

    return eThrust.
}

function getActiveEngines {
    SET activeEngines TO list().

    LIST ENGINES in myEngines.

    for eng IN myEngines {
        if (eng:IGNITION) {
            activeEngines:ADD(eng).
        }
    }

    return activeEngines.
}


function calculateBurnDurationFromEngineThrust {
    parameter eIsp.
    parameter eThrust.
    parameter deltaV.

    //Print ISP:
    //Print "Specific Impulse: " + eIsp.

    //Print Thrust
    //Print "Thrust: " + eThrust.

    // What's our effective exhaust velocity?
    LOCAL Ve IS eIsp * 9.82.
    //Print "Exhaust Velocity: " + Ve.

    // What's the Flow Rate? (metric tons / s)
    LOCAL eFlowRate IS eThrust / Ve.
    //Print "Flow Rate: " + eFlowRate.

    LOCAL startMass IS SHIP:MASS.

    LOCAL endMass IS CONSTANT():e^(LN(startMass) - (deltaV)/Ve).
    //Print "Start Mass: " + startMass.
    //Print "End Mass: " + endMass.

    LOCAL deltaMass IS (startMass - endMass) * CONSTANT():e^(-1*((deltaV) * 0.001) / Ve).
    //Print "Delta Mass: " + deltaMass.

    return deltaMass / eFlowRate.

//*********************
//                var exhaustVelocity = stage.isp * Units.GRAVITY;
//                var flowRate = stage.thrust / exhaustVelocity;
//                var endMass = Math.Exp(Math.Log(startMass) - deltaVDrain / exhaustVelocity);
//                var deltaMass = (startMass - endMass) * Math.Exp(-(deltaVDrain * 0.001) / exhaustVelocity);
//                burnTime += deltaMass / flowRate;//

//                deltaV -= deltaVDrain;
//                stageDeltaV -= deltaVDrain;
//                startMass -= deltaMass;
//************************

//********* Other Implementation *********//

// Get initial acceleration.
//    SET a0 TO maxthrust / mass.
//    // What's our final mass?
//    SET final_mass TO mass*CONSTANT():e^(-1*n:BURNVECTOR:MAG/Ve).//

//    // Get our final acceleration.
//    SET a1 TO maxthrust / final_mass.
//    // All of that ^ just to get a1..//

//    // Get the time it takes to complete the burn.
//    SET t TO n:BURNVECTOR:MAG / ((a0 + a1) / 2).//

//    //calculate ship's max acceleration
//    //set max_acc to ship:maxthrust/ship:mass.//

//    //set t to n:deltav:mag/max_acc.

//    print "Estimated burn duration: " + t + " seconds".
}