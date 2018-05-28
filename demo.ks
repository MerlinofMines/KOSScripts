SET angular TO VECDRAWARGS(V(0,0,0), SHIP:ANGULARVEL, RGB(1,0,0), "Reported Angular Velocity", 1, TRUE).
LOCK corrected_angvec TO SHIP:FACING * V(SHIP:ANGULARVEL:X, -(SHIP:ANGULARVEL:Z), SHIP:ANGULARVEL:Y).
SET corrected TO VECDRAWARGS(V(0,0,0), corrected_angvec, RGB(0,1,0), "Corrected Angular Velocity", 1, TRUE).
UNTIL FALSE {
  SET corrected:VEC TO corrected_angvec.
  SET angular:VEC TO SHIP:ANGULARVEL.
}