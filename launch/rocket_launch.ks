RUNONCEPATH("0:/orbital_maneuvers.ks").

//TODO: Not doing Staging yet!
function launchRocket {
    parameter cutoffApoapsis.
    parameter launchDirection.

    SAS OFF.
//    PRINT "SAS ON".
//    SAS ON.

    SET THROTTLE TO 0.
    WAIT 0.5.

    LIST ENGINES IN myEngines.
    for eng IN myEngines {
        eng:ACTIVATE.
    }
    WAIT 0.5.

    PRINT "THROTTLING UP".
    SET THROTTLE TO 1.
    WAIT 0.5.

    PRINT "LAUNCH".
    STAGE.

    WAIT 1.0.

//    SET SASMODE TO "PROGRADE".
    LOCK STEERING TO launchDirection.

    WAIT 0.5.

    PRINT "LEGS OFF".
    LEGS OFF.

    WAIT UNTIL SHIP:ORBIT:APOAPSIS > cutoffApoapsis.

    PRINT "CUTTING ENGINES".
    SET THROTTLE TO 0.

    PRINT "Pointing Prograde".
    UNLOCK STEERING.
    SAS ON.
    SET SASMODE TO "PROGRADE".

    circularizeMaintainingPrograde(myEngines).

}