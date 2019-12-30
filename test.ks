RUNONCEPATH("0:/landing/rocket_landing.ks").
RUNONCEPATH("0:/launch/rocket_launch.ks").

//fromKSP().
//fromMun().
//launchFromMun().

doit().

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