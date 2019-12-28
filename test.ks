RUNONCEPATH("0:/landing/rocket_landing.ks").

//fromKSP().
fromMun().

function fromMun {

    LIST ENGINES in myEngines.
    for eng IN myEngines {
        SET eng:THRUSTLIMIT TO 80.
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