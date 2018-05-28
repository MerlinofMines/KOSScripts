CLEARSCREEN.

EXIT.

Print "Starting Launch Sequence.".
SET orbitHeight to 75000.
Print "Orbital Height will be " + orbitHeight.

Print "Waiting for throttle to be set at 0.".
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

WAIT UNTIL THROTTLE = 0.0.

SET countdown TO 3.

Print ("Launching in ").
UNTIL countdown = 0 {
  Print countdown.
  SET countdown TO countdown - 1.
  WAIT 1.
}

Print "Launch is a go.".

Print "Throttling Up to 100%".
LOCK THROTTLE TO 1.0.

//Print "Engaging SAS".
//SAS ON.

Print "Setting trajectory Due East.".

LIST ENGINES IN elist.

UNTIL STAGE:NUMBER = 0 OR SHIP:ORBIT:APOAPSIS > orbitHeight {
    LOCK STEERING TO UP + R(0,getDirection(),180).
    SET activeEngine TO FALSE.

    FOR e IN elist {
        IF e:FLAMEOUT {
            STAGE.
            PRINT "Detected Engine Flameout.  Proceeding to stage " + STAGE:NUMBER.

            UNTIL STAGE:READY {
                WAIT 0.
            }

            LIST ENGINES IN elist.
            BREAK.
        }

        IF e:IGNITION {
            SET activeEngine TO true.
        }
    }

    IF activeEngine = FALSE {
       STAGE.
       PRINT "No Active Engine.  Proceeding to stage " + STAGE:NUMBER.
    }
}

LOCK THROTTLE TO 0.0.
WAIT UNTIL THROTTLE = 0.0.
UNTIL ALTITUDE > 70000 {
    lock steering to prograde.
    WAIT 1.
}

Print "Calculating Maneuver Burn.".
SET burn to calculateCircularizationBurn(orbitHeight).
add burn.
WAIT 1.

Print "Executing Circularization Burn.".
executeNextManeuver().
//remove burn.

Print "Circularization Burn Complete.".

UNLOCK STEERING.
UNLOCK THROTTLE.
wait 1.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

Print "Launch Complete".

function getDirection {
    if(altitude < 100) {
        return 0.
    } else if (altitude < 500) {
        return -2.
    }

//    //Constant for our logarithm.  This logarithm roughly corresponds to the correct gravity turn trajectory based on altitude, scaled down by a factor of 2000.
//    SET C to 1.025.
//    SET x to SHIP:ORBIT:APOAPSIS / 2000.//

//    //Derivate of logarithmic function gives us correct trajectory based on altitude, as rise over run.
//    SET dydx TO (1/x)*(1/LN(C)). //(1/x * (1/ln C)//

//    //Calculate angle in degrees from horizon.
//    SET angleFromHorizon To ARCTAN(dydx).//

//    //UpOffSet will be a - angle from "up", i.e. subtract angle from 90, but we want to be negative as we are heading east.
//    SET upOffSet TO angleFromHorizon - 90.//

//    return upOffSet.

    declare orbit TO SHIP:ORBIT:APOAPSIS.
    if (orbit < 5000) {
        return -5.
    } else if (orbit < 10000) {
        return -10.
    } else if (orbit < 20000) {
        return -20.
    } else if (orbit < 30000) {
        return -25.
    } else {
        return -30.
    }
}

//Taken shamefully from https://www.reddit.com/r/Kos/comments/5rp0w5/maneuver_nodes/ 
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

//reference:
function executeNextManeuver {
    // Get Next Maneuver
    SET n TO NEXTNODE.

    SET deltaV to n:BURNVECTOR:MAG/2.

    // In the pursuit of a1...
    // What's our effective ISP?
    SET eIsp TO 0.
    SET eThrust to 0.

    LIST engines IN my_engines.
    FOR eng IN my_engines {
        SET eIsp TO eIsp + eng:maxthrust / maxthrust * eng:isp.
        Set eThrust To eThrust + eng:AVAILABLETHRUST.
    }

    //Print ISP:
    //Print "Specific Impulse: " + eIsp.

    //Print Thrust
    //Print "Thrust: " + eThrust.

    // What's our effective exhaust velocity?
    SET Ve TO eIsp * 9.82.
    //Print "Exhaust Velocity: " + Ve.

    // What's the Flow Rate? (metric tons / s)
    Set eFlowRate TO eThrust / Ve.
    //Print "Flow Rate: " + eFlowRate.

    Set startMass To mass.

    SET endMass TO CONSTANT():e^(LN(startMass) - deltaV/Ve).
    //Print "Start Mass: " + startMass.
    //Print "End Mass: " + endMass.

    SET deltaMass TO (startMass - endMass) * CONSTANT():e^(-1*(deltaV * 0.001) / Ve).
    //Print "Delta Mass: " + deltaMass.

    Set t To deltaMass / eFlowRate.

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

    print "Estimated burn duration: " + t + " seconds".

    // Set the start and end times.
    SET start_time TO TIME:SECONDS + n:ETA - t.

    // Wait for Craft to approach node execution.  Assuming 30 seconds is enough time to orient the spacecraft.
    WAIT UNTIL TIME:SECONDS >= start_time - 30.
    Print "Maneuver Execution on 30 seconds.".

    // Point at the node.
    LOCK STEERING TO n:BURNVECTOR.
    WAIT UNTIL VANG(SHIP:FACING:VECTOR, n:BURNVECTOR) < 0.25.

    // Wait to start the burn.
    WAIT UNTIL TIME:SECONDS >= start_time.

    //Start Node Execution, continue until Delta V is exhausted.
    maneuverBurn().

    LOCK throttle TO 0.
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

function maneuverBurn2 {
        // Get Next Maneuver
    SET n TO NEXTNODE.

    SET deltaV to n:BURNVECTOR:MAG.

    // In the pursuit of a1...
    // What's our effective ISP?
    SET eIsp TO 0.
    SET eThrust to 0.

    LIST engines IN my_engines.
    FOR eng IN my_engines {
        SET eIsp TO eIsp + eng:maxthrust / maxthrust * eng:isp.
        Set eThrust To eThrust + eng:AVAILABLETHRUST.
    }

    //Print ISP:
    //Print "Specific Impulse: " + eIsp.

    //Print Thrust
    //Print "Thrust: " + eThrust.

    // What's our effective exhaust velocity?
    SET Ve TO eIsp * 9.82.
    //Print "Exhaust Velocity: " + Ve.

    // What's the Flow Rate? (metric tons / s)
    Set eFlowRate TO eThrust / Ve.
    //Print "Flow Rate: " + eFlowRate.

    Set startMass To mass.

    SET endMass TO CONSTANT():e^(LN(startMass) - deltaV/Ve).
    //Print "Start Mass: " + startMass.
    //Print "End Mass: " + endMass.

    SET deltaMass TO (startMass - endMass) * CONSTANT():e^(-1*(deltaV * 0.001) / Ve).
    //Print "Delta Mass: " + deltaMass.

    Set t To deltaMass / eFlowRate.

    Print "Node Burn time: " + t.

    lock throttle to 1.
    Wait t.
    lock throttle to 0.
}