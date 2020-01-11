RUNONCEPATH("0:/landing/rocket_landing.ks").
RUNONCEPATH("0:/launch/rocket_launch.ks").
RUNONCEPATH("0:/rendevous/encounter.ks").
RUNONCEPATH("0:/docking/grabbing.ks").

//fromKSP().
//fromMun().
//launchFromMun().

//doit().

encounter_burn(BODY("Mun") ,7000).

//testGrabberPartDubbed().

function testGrabberPartDubbed {
    LOCAL grabber IS getGrabbers()[0].

    LOCAL targetVessel IS VESSEL("Merlin Mark I - Front Carrier Ship").

    grabDubbedPartUsingGrabber(grabber, targetVessel, "Lab").

}

function encounter_burn {
    parameter targetBody.
    parameter targetCaptureRadius.

    LOCAL throttleController IS encounterThrottleController@:bind(lexicon()):bind(targetBody):bind(targetCaptureRadius):bind(false):bind(matchApoapsisThrottleController@:bind(lexicon()):bind(12000000)).

    executeNextManeuverWithController(throttleController).
    shortInfo("Hohmann Transfer Complete").
}

function doit {
    if ( SHIP:STATUS = "LANDED") {
        launchFromMun().
    } else {
        fromMun().
    }
}

function launchFromMun {

    LIST ENGINES in myEngines.

    for eng IN myEngines {
        SET eng:THRUSTLIMIT TO 20.
    }

    launchRocket(6000,HEADING(-90, 45)).
}

function fromMun {

    PRINT " RUNNING".

    LIST ENGINES in myEngines.

    SET THROTTLE TO 0.

    for eng IN myEngines {
        eng:ACTIVATE.
    }

    executeDescent().

    for eng IN myEngines {
        SET eng:THRUSTLIMIT TO 50.
    }

    WAIT 0.5.

    rocketLanding().
}

function fromKSP {

    PRINT "SAS ON".
    SAS ON.

    WAIT 0.5.

    PRINT "THROTTLING UP".

    SET THROTTLE TO 1.

    WAIT 0.5.

    PRINT "LAUNCH".
    STAGE.

    WAIT 0.5.

    SET SASMODE TO "PROGRADE".

    WAIT 0.5.

    PRINT "LEGS OFF".
    LEGS OFF.

    WAIT UNTIL SHIP:RESOURCES[3]:AMOUNT < 100.

    PRINT "CUTTING ENGINES".

    SET THROTTLE TO 0.

    WAIT UNTIL VERTICALSPEED < 0.

    rocketLanding().

}