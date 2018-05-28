RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/rendevous.ks").

Local targetVessel IS Vessel("Kerbin Science Orbiter").
Local sourceVessel IS SHIP.


UNTIL FALSE {
	CLEARSCREEN.
	CLEARVECDRAWS().
	Local targetTimeToPeriapsis IS timeAtNextPeriapsis(targetVessel) + 100.

	Local targetPeriapsisPosition IS positionVectorAt(targetVessel, targetTimeToPeriapsis).

	drawVector(targetPeriapsisPosition, "Target Periapsis", targetVessel:Orbit:Body:Position).

	LOCAL startTime IS TIME:SECONDS.
	Local timeToMinPeriapsis1 IS timeOfMinimumVectorAngle(targetVessel, targetTimeToPeriapsis, TIME:SECONDS, sourceVessel).
	LOCAL endTime IS TIME:SECONDS.

	PRINT "Time to calculate 1: " + (endTime - startTime).

	SET startTime TO TIME:SECONDS.
	Local timeToMinPeriapsis2 IS timeOfMinimumVectorAngle2(targetVessel, targetTimeToPeriapsis, sourceVessel).
	SET endTime TO TIME:SECONDS.

	PRINT "Time to calculate 2: " + (endTime - startTime).

	LOCAL startTime IS TIME:SECONDS.
	Local timeToMinPeriapsis3 IS timeOfMinimumVectorAngle3(targetVessel, targetTimeToPeriapsis, sourceVessel).
	LOCAL endTime IS TIME:SECONDS.

	PRINT "Time to calculate 3: " + (endTime - startTime).

	Local sourcePosition1 IS positionVectorAt(sourceVessel, timeToMinPeriapsis1).
	Local sourcePosition2 IS positionVectorAt(sourceVessel, timeToMinPeriapsis2).
	Local sourcePosition3 IS positionVectorAt(sourceVessel, timeToMinPeriapsis3).

	drawVector(sourcePosition1, "Source at Periapsis 1", sourceVessel:Orbit:Body:Position).
	drawVector(sourcePosition2, "Source at Periapsis 2", sourceVessel:Orbit:Body:Position).
	drawVector(sourcePosition3, "Source at Periapsis 2", sourceVessel:Orbit:Body:Position).

	Print "Time 1: " + timeToMinPeriapsis1.
	Print "Time 2: " + timeToMinPeriapsis2.
	Print "Time 2: " + timeToMinPeriapsis3.

	Print "Difference in angle 1: " + VANG(targetPeriapsisPosition, sourcePosition1).
	Print "Difference in angle 2: " + VANG(targetPeriapsisPosition, sourcePosition2).
	Print "Difference in angle 3: " + VANG(targetPeriapsisPosition, sourcePosition3).

	Print "Difference in time 2: " + (abs(timeToMinPeriapsis1 - timeToMinPeriapsis2)).
	Print "Difference in time 3: " + (abs(timeToMinPeriapsis1 - timeToMinPeriapsis3)).

	Print "Actual Source True Anomaly: " + trueAnomalyAt(timeToMinPeriapsis1, sourceVessel).

	Print "Actual Target True Anomaly: " + trueAnomalyAt(targetTimeToPeriapsis, targetVessel).

	Wait 1.
}
