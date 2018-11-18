
function changeApoapsis {
    parameter newAltitude.

    local mu is body:mu.
    local br is body:radius.

    // present orbit properties
    local vom is velocity:orbit:mag.               // actual velocity
    local r is br + altitude.                      // actual distance to body
    local ra is br + periapsis.                     // radius at burn periapsis
    local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn periapsis

    local sma1 is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

    // future orbit properties
    local r2 is br + periapsis.               // distance after burn at periapsis
    local sma2 is (periapsis + 2*br + newAltitude)/2. // semi major axis target orbit
    local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

    // create node
    local deltav is v2 - v1.
    local nd is node(time:seconds + eta:periapsis, 0, 0, deltav).
    return nd.
}

//TODO: There's a reference from KER needed here.
function executeNextManeuver {
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
    maneuverBurn().

    REMOVE n.

    SET throttle TO 0.
    UNLOCK THROTTLE.
}

// Taken Shamefully from
function maneuverBurn {
    //Get Next Maneuver.
    SET nd TO NEXTNODE.

    //we only need to lock throttle once to a certain variable in the beginning of the loop,
    //and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    set done to False.
    //initial deltav
    set dv0 to nd:deltav.
    until done
    {
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to ship:maxthrust/ship:mass.

        //throttle is 100% until there is less than 0.25 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(8*nd:deltav:mag/max_acc, 1).

        //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
        //this check is done via checking the dot product of those 2 vectors
        if vdot(dv0, nd:deltav) < 0
        {
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            lock throttle to 0.
            break.
        }

        //we have very little left to burn, less then 0.1m/s
        if nd:deltav:mag < 0.1
        {
            print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            //we burn slowly until our node vector starts to drift significantly from initial vector
            //this usually means we are on point
            wait until vdot(dv0, nd:deltav) < 0.5.

            lock throttle to 0.
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            set done to True.
        }
    }
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
        } ELSE {
            PRINT "Warning, " + eng:name + " is not active, it's ISP cannot be calculated.".
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
        } ELSE {
            PRINT "Warning, " + eng:name + " is not active, it's max thrust cannot be calculated.".
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