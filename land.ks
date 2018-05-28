RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/flight.ks").

SET runwayWest to latlng( -0.048597000539, -74.72335052490).

SET runwayLineUpRoll TO PIDLoop(1.0,0.0,0.1,-0.2,0.2).

SET refreshInterval TO 0.001.

SET previousNavball TO navball_direction(SHIP).
WAIT refreshInterval.

SAS OFF. 

UNTIL FALSE {
  local runwayLineUpDistance IS runwayWest:LAT - LATITUDE.

  Print "Distance: " + runwayLineUpDistance.

  local desiredROLL IS runwayLineUpRoll:UPDATE(TIME:SECONDS, runwayLineUpDistance).

  SET SHIP:CONTROL:ROLL TO desiredRoll.

  WAIT refreshInterval.
}
