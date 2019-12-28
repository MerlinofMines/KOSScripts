RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/maneuver.ks").
RUNONCEPATH("0:/orbital_information.ks").

function executeDescent {
    SAS ON.

    SET SASMODE TO "RETROGRADE".

    WAIT UNTIL VANG(SHIP:FACING:FOREVECTOR, SHIP:ORBIT:VELOCITY:ORBIT) > 179.5.

    PRINT "READY".

    SET THROTTLE TO 1.0.

    LOCAL previousGroundSpeed IS GROUNDSPEED.

    UNTIL abs(GROUNDSPEED) > previousGroundSpeed OR GROUNDSPEED < 1 {
        SET previousGroundSpeed TO GROUNDSPEED.
    }

    SET THROTTLE TO 0.
}



//This function currently assumes that we are landing mostly vertical; doesn't work well if ground speed is signficant.
function rocketLanding {

    SAS ON.

    SET SASMODE TO "RETROGRADE".

    suicideBurn().
}

function suicideBurn {
    LOCAL throttleController IS suicideBurnController@:bind(lexicon()).

    maneuverBurn(throttleController).

    Print "Suicide burn complete.".
}

//TODO: These params don't have sane defaults, they are specific to myu testing craft.
function suicideBurnController {
    parameter previousState.
    parameter desiredHeightAboveSurface IS 6.5. //0 meters.  Can be overridden to allow the rocket to hover in air, or to compensate for the height of the craft.
    parameter desiredSpeedAtSurface IS -1. //m/s, represents the final speed we should be going at (- means towards surface) at final approach) TODO Not sure if this works, heads up.
    parameter effectiveAccelerationUsage IS 0.95. //0.0-1.0, represents % of effective thrust to use (100% being full throttle).
    parameter distanceCutoffMargin IS 0.02. //meters, represents how close to "desired height" before we cut the engines.

    //See if this is the first time we have entered the loop. Set previous state and begin calculating suicide burn.
    IF NOT previousState:HASKEY("S") {
        SET previousState["S"] TO 0. //State.  0 = not started burn, 1 = started burning

        return 0.
    }

    LOCAL dF IS desiredHeightAboveSurface.
    LOCAL d0 IS ALT:RADAR.
    LOCAL vF IS desiredSpeedAtSurface.
    LOCAL v0 IS VERTICALSPEED.

    LOCAL distance IS abs(d0 - dF).  //TODO: May need bounding box for the craft as well so you know where the "bottom" of the ship is at.
    LOCAL deltaV IS abs(v0 - vF).

    //TODO: Calculate a from engine thrust using cos of vertical speed & ground speed
    LOCAL aEngineThrust IS accelerationFromEngineThrust().
    LOCAL aGravity IS accelerationFromGravity().
    LOCAL effectiveAcceleration IS aEngineThrust - aGravity.

    //How long to "desired Speed" ?
    LOCAL timeToDesiredSpeed IS 2*(dF - d0) / (v0 + vF).
    LOCAL accelerationToDesiredSpeed IS  (vF - v0)/timeToDesiredSpeed.

    PRINT "Vertical Speed: " + VERTICALSPEED.
    PRINT "Distance to Desired Height: " + distance.
    PRINT "Time To Desired Speed: " + timeToDesiredSpeed.
    PRINT "Acceleration To Desired Speed: " + accelerationToDesiredSpeed.

    PRINT "Maximum Possible Engine Acceleration: " + aEngineThrust.
    PRINT "Gravity Acceleration: " + aGravity.
    PRINT "Effective Acceleration: " + effectiveAcceleration.
    PRINT "Status: " + SHIP:STATUS.

    LOCAL state IS previousState["S"]. //State.  0 = not started burnt, 1 = started burning

    if (timeToDesiredSpeed < 5 AND NOT LEGS) {
        LEGS ON.
    }

    if d0 < dF OR SHIP:STATUS = "LANDED" {
        return -1. //We did it!.
    }

    if (state = 0 AND (accelerationToDesiredSpeed < effectiveAcceleration*effectiveAccelerationUsage)) return 0. //Not yet.

    if (v0 > vF OR state = 2) {
        SET previousState["S"] TO 2.
        PRINT "In Final Phase.".

        //TODO: this needs some work to fine-tune 2nd parameter, but initial seems OK
        LOCAL throttle IS clamp((aGravity/aEngineThrust) + ((vf - v0) / aEngineThrust), 0, 1).

        PRINT "Throttle: " + throttle.

        return throttle.
    }

    SET previousState["S"] TO 1.

    //Gravity + Effective = Engine.
    LOCAL throttle IS clamp((aGravity/aEngineThrust) + (accelerationToDesiredSpeed / aEngineThrust), 0, 1).

    PRINT "Throttle: " + throttle.

    return throttle.
}

function accelerationFromGravity {
    return body:mu / (altitude + body:radius)^2.
}

//TODO: Where do you belong?
//https://en.wikipedia.org/wiki/Specific_impulse
function accelerationFromEngineThrust {
    LIST engines IN my_engines.
    LOCAL eThrust IS calculateAvailableThrustForEngines(my_engines).

    return eThrust / SHIP:MASS.
}