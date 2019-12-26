function executeNextManeuver {
    SET nd TO NEXTNODE.
    set dv0 to nd:deltav.

    LOCAL controller IS deltaVRemainingThrottleController@:bind(nd):bind(dv0).

//    LOCAL controller IS matchApoapsisThrottleController@:bind(lexicon()):bind(100000).

    executeNextManeuverWithController(controller).
}

function executeNextManeuverWithController {
    parameter throttleController.

    // Get Next Maneuver
    SET n TO NEXTNODE.

    SET deltaV to n:BURNVECTOR:MAG.

    LOCAL t IS calculateHalfBurnDuration(deltaV).

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

    REMOVE n.

    SET throttle TO 0.
}

//Throttle Controller allows us to burn through maneuvers which are trying to optimize different attributes besides
//just the remaining delta v.  Very useful for long burns for things like encounters, etc which rarely match
//the delta v of the maneuver burn because of the burn duration.
//throttleController is expected to return a value between 0.0 and 1.0 until the burn is complete, at which
//point throttleController should return -1 (or any negative number) indicating that the burn has been completed.
function maneuverBurn {
    parameter throttleController.

    SET myThrottle TO 1.

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

function encounterThrottleController {
    parameter previousState.
    parameter targetBody.
    parameter desiredPe.//Periapsis of encountered body
    parameter desiredAp.//Apoapsis without encounter

    if NOT SHIP:ORBIT:HASNEXTPATCH {
        PRINT "No Encounter Yet".
        return matchApoapsisThrottleController(previousState, desiredAp).
    } else IF NOT (SHIP:ORBIT:NEXTPATCH:BODY = targetBody) {
        PRINT "WARNING: ENCOUNTER WITH UNEXPECTED BODY DETECTED: " + SHIP:ORBIT:NEXTPATCH:BODY.
        return matchApoapsisThrottleController(previousState, desiredAp).
    }
    PRINT "Detected Correct Encounter.".

    //See if this is the first time we detected the encounter, reset state and begin calculating new throttle
    IF NOT previousState:HASKEY("E") {
        LOCAL previousThrottle IS previousState["H"].
        previousState:CLEAR.
        SET previousState["E"] TO TRUE.
        SET previousState["H"] TO previousThrottle.
        SET previousState["T"] TO TIME:SECONDS.
        SET previousState["P"] TO SHIP:ORBIT:NEXTPATCH:PERIAPSIS.
        SET previousState["I"] TO SHIP:ORBIT:NEXTPATCH:INCLINATION.

        //TODO: previousThrottle may be too high in some cases, not sure yet, as is waiting 0.01. sec.
        WAIT 0.01.
        return previousThrottle.
    }

    LOCAL previousPe IS previousState["P"].
    LOCAL previousTime IS previousState["T"].
    LOCAL previousThrottle IS previousState["H"].
    LOCAL previousInclination IS previousState["I"].

    LOCAL newPe IS SHIP:ORBIT:NEXTPATCH:PERIAPSIS.
    LOCAL newInclination IS SHIP:ORBIT:NEXTPATCH:INCLINATION.
    LOCAL newTime IS TIME:SECONDS.

    IF previousInclination < 90 AND previousPE > 0 {
        PRINT "Previous Inclination < 90.".
        PRINT "BEFORE: " + previousPE.
        SET previousPe TO -previousPe.
    }

    IF newInclination < 90 AND newPe > 0 {
        PRINT "New Inclination < 90.".
        PRINT "BEFORE: " + newPe.
        SET newPe TO -newPe.
    }

    LOCAL peChange IS newPe - previousPe.
    LOCAL timeChange IS newTime - previousTime.
    LOCAL peChangeRate IS peChange/timeChange.

    PRINT "Previous Throttle: " + previousThrottle.
    PRINT "Previous Pe: " + previousPe.
    PRINT "Previous Inclination: " + previousInclination.

    PRINT "Desired Pe: " + desiredPe.
    PRINT "Time Change: " + timeChange.
    PRINT "New Inclination: " + newInclination.
    PRINT "Periapsis change rate: " + peChangeRate.

    IF newPe > desiredPe RETURN -1.

    PRINT "Desired Periapsis Gap: " + abs(1 - (newPe/desiredPe)).
    //IF we're stupid close to our target orbit, and our change rate is also low, call it quits.
    IF abs(1 - (newPe/desiredPe)) < 0.001 AND peChangeRate < 0.1 {
        RETURN -1.
    }

    SET previousState["I"] TO SHIP:ORBIT:NEXTPATCH:INCLINATION.
    SET previousState["P"] TO SHIP:ORBIT:NEXTPATCH:PERIAPSIS. //Don't store modified value, use the original.
    SET previousState["T"] TO newTime.

    //Need to wait a non-zero amount of time to allow for an actual "burn".
    WAIT 0.01.

    //Still have >1 burn time, previous throttle is ok.
    IF newPe + peChangeRate < desiredPe {
        return previousThrottle.
    }

    //Time to calculate new throttle.
    LOCAL newThrottle IS min(1,2*(desiredPe+0.1-newPe)/(peChangeRate)) * previousThrottle.
    SET previousState["H"] TO newThrottle.
    return newThrottle.
}

function deltaVRemainingThrottleController {
    parameter nd.
    parameter dv0.

    //recalculate current max_acceleration, as it changes while we burn through fuel
    set max_acc to ship:maxthrust/ship:mass.

    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, nd:deltav) < 0
    {
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        return -1.
    }

    //we have very little left to burn, less then 0.1m/s
    if nd:deltav:mag < 0.1
    {
        print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
    //we burn slowly until our node vector starts to drift significantly from initial vector
    //this usually means we are on point
        wait until vdot(dv0, nd:deltav) < 0.5.

        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).

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