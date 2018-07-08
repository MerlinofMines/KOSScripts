RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/orbital_information.ks").
RUNONCEPATH("0:/rendevous.ks").

UNTIL TRUE {
    CLEARSCREEN.
    CLEARVECDRAWS().

    LOCAL myTarget IS Vessel("Kerbin Science Orbiter").
//    LOCAL myTarget IS Vessel("Merlin Mark I - Crew Configuration").
    LOCAL timeToAscendingNode IS timeToRelativeAscendingNode(myTarget,SHIP).

    prettyPrintTime(timeToAscendingNode,": ").
    WAIT 0.01.
}


UNTIL FALSE {
    CLEARSCREEN.
    CLEARVECDRAWS().

    LOCAL eccentricity IS SHIP:ORBIT:ECCENTRICITY.
    LOCAL trueAnomaly IS SHIP:ORBIT:TRUEANOMALY.
    LOCAL trueAnomalyFromState IS trueAnomalyAt(TIME:SECONDS, SHIP).

    LOCAL eccentricAnomaly IS eccentricAnomalyFromTrueAnomaly(trueAnomaly, eccentricity).
    LOCAL meanAnomaly IS meanAnomalyFromEccentricAnomaly(eccentricAnomaly, eccentricity).
    LOCAL meanAnomalyFromTrue IS meanAnomalyFromTrueAnomaly(trueAnomaly, eccentricity).

    PRINT "True Anomaly (known): " + trueAnomaly.
    PRINT "True Anomaly from state: " + trueAnomalyFromState.
    PRINT "Diff in True Anomaly: " + abs(trueAnomaly - trueAnomalyFromState).
    Print "Eccentric Anomaly: " + eccentricAnomaly.
    Print "Mean Anomaly: " + meanAnomaly.
    Print "Mean Anomaly from True: " +  meanAnomalyFromTrue.


//    PRINT "Diff in Mean Anomaly: " + abs(meanAnomaly - meanAnomalyFromTrue).

    LOCAL etaPer IS ETA:PERIAPSIS.
    LOCAL etaApo IS ETA:APOAPSIS.

    LOCAL periapsisTime IS timeToPeriapsis(SHIP).
    LOCAL apoapsisTime is timeToApoapsis(SHIP).

    prettyPrintTime(apoapsisTime, "Ap: ").
    prettyPrintTime(etaApo, "rAp: ").
    prettyPrintTime(periapsisTime, "Pe: ").
    prettyPrintTime(etaPer, "rPe: ").

    PRINT "Difference Pe: " + (round(periapsisTime - etaPer,6)).
    PRINT "Difference Ap: " + (round(apoapsisTime - etaApo, 6)).

    WAIT 0.01.
}