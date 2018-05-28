RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/flight.ks").

SET pitchStability TO PIDLoop(0.06, 0, 0.000, -1, 1).
SET yawStability TO PIDLoop(0.06, 0, 0.000, -1, 1).
SET yawStability TO PIDLoop(0.06, 0, 0.000, -1, 1).

SET refreshInterval TO 0.001.

UNTIL FALSE {
	
	//from Utility
	LOCAL angularMomentum IS getAngularMomentum().

	LOCAL pMChange IS pitchStability:UPDATE(TIME:SECONDS, angularMomentum:PITCH).
	LOCAL yMChange IS yawStability:UPDATE(TIME:SECONDS, angularMomentum:YAW).
	LOCAL rMChange IS yawStability:UPDATE(TIME:SECONDS, angularMomentum:ROLL).

	SET SHIP:CONTROL:PITCH TO pMChange.
	SET SHIP:CONTROL:YAW TO yMChange.
	SET SHIP:CONTROL:ROLL TO rMChange.

}