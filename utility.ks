//Calculate the "roll degrees" which need to be moved.  This is based on the calculated roll degree
//distance assuming the craft rotated it's facing ForeVector to point at headingDirection:Forevector
//without making any roll adjustment.  This allows us to predict the needed change in roll before
//we've arrived at our final heading, so that we can pre-emptively start rolling.
//This calculation allows for a smooth transition from the current heading to desired heading, allowing
//the change in yaw, change in pitch, and change in roll to happen as one uniform motion.
//Note that you cannot simply use the "navball" roll as a guide for orienting the craft, as the "roll"
//of the craft varies dramatically based on pitch when moving between more extreme latitudes and longitudes.
//Input to this function is the actual Direction object (not navball!).
//Use heading_direction(navballDirection) to convert if needed.
function desiredRollChange {
  parameter headingDirection. 

  LOCAL normalVector TO VECTORCROSSPRODUCT(SHIP:FACING:FOREVECTOR, headingDirection:FOREVECTOR):NORMALIZED.
  LOCAL normalDegrees TO VANG(SHIP:FACING:FOREVECTOR, headingDirection:FOREVECTOR).
  LOCAL calculatedDirection TO ANGLEAXIS(normalDegrees, normalVector) * SHIP:FACING.
  LOCAL calcNormal TO VECTORCROSSPRODUCT(calculatedDirection:STARVECTOR, headingDirection:STARVECTOR):NORMALIZED.
  LOCAL rollDegrees TO VANG(calculatedDirection:STARVECTOR, headingDirection:STARVECTOR).

  if(VANG(calcNormal, calculatedDirection:FOREVECTOR) > 90) {
    SET rollDegrees TO -rollDegrees. 
  }

  return rollDegrees.
}


//This function stabalizes the aircraft by changing the ship pitch based on current ship's momentum.  It acts as "SAS" 
function stabalize {
    PARAMETER desiredControlChange.
    SET angMom TO getAngularMomentum.
    PRINT "Angular Momentum: " + angMom.

    SET SHIP:CONTROL:PITCH TO -0.5 * MIN(1, (angMom:PITCH/50)) + desiredControlChange:PITCH.
    SET SHIP:CONTROL:YAW TO -0.5 * MIN(1, (angMom:YAW/50)) + desiredControlChange:YAW.
    SET SHIP:CONTROL:ROLL TO -0.5 * MIN(1, (angMOM:ROLL/50)) + desiredControlChange:ROLL.
}

//Angular momentum is bassackwards.
//This function returns the angular moment of the craft, relative to the orientation (UP) of the craft.
//+1 X is equivalent to rising pitch
//+1 Y is equivalent to nose moving right
//+1 Z is equivalent to rotating clockwise as observed when facing forward.
function getAngularMomentum {
  SET myAngMom To SHIP:ANGULARMOMENTUM.
  return R(-myAngMom:X, -myAngMom:Z, -myAngMom:Y).
}

function rotateTowards {
  parameter desiredNavballDirection.
  parameter previousNavballDirection.
  parameter refreshInterval.

  local currentNavballDirection IS navball_direction(SHIP).
  local navballDistance IS navball_delta(currentNavballDirection, desiredNavballDirection).
  local navballDelta IS navball_delta(previousNavballDirection, currentNavballDirection).
  local currentControl IS SHIP:CONTROL.
  local currentRoll IS currentNavballDirection:ROLL.

  //calculate desired pitch control change based on navball pitch, desired pitch, and pitch change
  local desiredPitchChange IS calculateDesiredControlChange(currentNavballDirection:PITCH, previousNavballDirection:PITCH, desiredNavballDirection:PITCH, refreshInterval).

  //calculate desired yaw control change based on navball yaw, desired yaw, and yaw change.
  local desiredYawChange IS calculateDesiredControlChange(currentNavballDirection:YAW, previousNavballDirection:YAW, desiredNavballDirection:YAW, refreshInterval).

  //calculate desired roll control change based on navball roll, desired roll, and roll change.
  local desiredRollChange IS calculateDesiredControlChange(currentNavballDirection:ROLL, previousNavballDirection:ROLL, desiredNavballDirection:ROLL, refreshInterval).

  //Given that the craft is rolled, the actual adjustment to controls is dependent on the orientation of the craft.
  //For example, if we want to pitch "up", but the craft is currently on it's side, then the desired control
  //change is not an adjustment to the PITCH control; it's actually an adjustment to the YAW control.  This is true
  //for pitch and yaw controls.  Roll is unaffected by this.
  local cosRoll IS cos(currentRoll).
  local sinRoll IS sin(currentRoll).

  local calculatedPitchChange IS MIN(1, (cosRoll * desiredPitchChange) + (sinRoll * desiredYawChange)).
  local calculatedYawChange IS MIN(1, (cosRoll * desiredYawChange) - (sinRoll * desiredPitchChange)).
  local calculatedRollChange IS MIN(1, desiredRollChange).

//  PRINT "Desired Pitch Change: " + desiredPitchChange.
//  PRINT "Desired Yaw Change: " + desiredYawChange.
//  PRINT "Desired Roll Change: " + desiredRollChange.

//  PRINT "Calculated Pitch Change: " + calculatedPitchChange.
//  PRINT "Calculated Yaw Change: " + calculatedYawChange.

  //Dampen the controls (more finer controls) when near desired pitch when navballDelta is small).
  local pitchDampener IS MIN(1, MAX(abs(navballDistance:PITCH/4), navballDelta:PITCH*2)).
  local yawDampener IS MIN(1, MAX(abs(navballDistance:YAW/4), navballDelta:YAW*2)).
  local rollDampener IS MIN(1, MAX(abs(navballDistance:ROLL/4), navballDelta:ROLL*2)).

//  stabalize(R(calculatedPitchChange, calculatedYawChange, calculatedRollChange)).
}

//This function calculates a desired control change based on the 
//current degree, previous degree, desired degree and refresh interval.
//it can be used to calculate a desired control change for pitch, yaw and roll.
//degrees are expected to be between 0 and 360 degrees.
function calculateDesiredControlChange {
   parameter currentDegree.
   parameter previousDegree.
   parameter desiredDegree.
   parameter refreshInterval.

   local degreeChange IS degreeDelta(currentDegree, previousDegree). // degree change between last refresh interval, signed
   local degreeDistance IS degreeDelta(desiredDegree, currentDegree). // distance between current degree and desired degree, signed
   local degreeChangePerSecond IS abs(degreeChange) / refreshInterval.

   //should we accelerate, or brake?
   local timeToDegree IS -1.
   local shouldBrake IS FALSE.
   if (abs(degreeChange) > 0 AND degreeDistance / degreeChange < 0) {
      //this means we are moving farther from our desired degree.  Either our degreeDistance is + and our degreeChange is -,
      //or our degreeDistance is - and our degreeChange is +.  Our desired control change should put us "towards" the desired degree.
   } else {
      SET timeToDegree TO (degreeDistance / degreeChange) * refreshInterval.

      //If we're < 2 seconds from being at our desired degree, it's time to brake, i.e. move control in opposite direction.
      if (timeToDegree < 2) {
        SET shouldBrake TO TRUE.
      }
   }

   local desiredControlChange IS 0.

   //if we should brake, then our control should be away from our desired degree, multiplied by how soon we're expecting to arrive at the degree (if we're about to get to degree, brake harder).
   if (shouldBrake) {
      local multiplier IS 2 / timeToDegree.

      SET desiredControlChange TO 0.05 * multiplier.

      if(degreeChange > 0) {
          SET desiredControlChange TO -desiredControlChange.
      }

      return desiredControlChange.

      //If we aren't braking, then let's decide if we're already rotating fast enough.  To maintain some control of the aircraft, we should make sure that we aren't rotating too quickly in any direction (pitch, yaw, roll).  Anything faster than 20 degrees per second is probably plenty fast to rotate, and we should deccelerate.  Note that we only care about rotation speed
      //if we are moving TOWARDS our desired degree.
   } else if (degreeChangePerSecond > 20 AND timeToDegree > 0) {
      SET desiredControlChange TO 0.05 * MAX(1, degreeChangePerSecond/20). //slow down proportionally to how much faster we were going.

      if(degreeChange > 0) {
        SET desiredControlChange TO -desiredControlChange.
      }

      //We're OK to accelerate, as we're rotating at a reasonable speed, and our delta degree is > 1 second away.
      //How much do we accelerate?  Depends how far we are from our delta and how fast we're rotating.
   } else {
      SET desiredControlChange TO 0.01.

      //We're flying away from our target
      if (timeToDegree < 0) {
        SET desiredControlChange TO desiredControlChange * MAX(10, degreeChangePerSecond).
      }

      //If we're already near our desired degree, our change needs to be drastically reduced
      SET desiredControlChange TO MAX(1, degreeDistance/20).

      if (degreeDistance < 0) {
         SET desiredControlChange TO -desiredControlChange.
      }

   }

   if (shouldBrake) {
      SET desiredControlChange TO MIN(1, desiredControlChange).
   } else {
      SET desiredControlChange TO MIN(0.1, desiredControlChange).
   }

//   PRINT "DESIRED CONTROL CHANGE: " + desiredControlChange.
//   PRINT "DegreeDistance: " + degreeDistance.
//   PRINT "Degree Change Per Second: " + degreeChangePerSecond.

   SET desiredControlChange TO desiredControlChange * MAX(MIN(1, abs(degreeDistance)/10), MIN(1, degreeChangePerSecond/5)).

   return desiredControlChange.
}

//Returns a Direction representing the change in pitch, yaw and roll.
//Delta values range from -180 to 180 degrees.
function navball_delta {
  parameter sourceNavball.
  parameter destinationNavball.

  return R(degreeDelta(destinationNavball:PITCH, sourceNavball:PITCH),
           degreeDelta(destinationNavball:YAW, sourceNavball:YAW),
           degreeDelta(destinationNavball:Roll, sourceNavball:Roll)).
}

function degreeDelta {
    parameter destinationDegree.
    parameter sourceDegree.

    SET delta TO destinationDegree - sourceDegree.
    IF (delta < -180) {
        Set delta TO delta + 360.
    } ELSE IF (delta > 180) {
        SET delta TO delta - 360.
    }

    return delta.
}

//This function adds the degreeDelta to the sourceNavballDirection and returns a new direction.
//Essentially the same as rotating sourceNavigationDirection by the given degreeDelta.
function addDelta {
  parameter sourceNavballDirection.
  parameter navballDelta.

  return R(sourceNavballDirection:PITCH + navballDelta:PITCH, 
           sourceNavballDirection:YAW + navballDelta:YAW, 
           sourceNavballDirection:ROLL + navballDelta:ROLL).
}

function navball_prograde {
  parameter ves IS SHIP.
  local direction IS navball_direction(ves, ves:PROGRADE).

  return R(direction:PITCH, direction:YAW, 0).//Prograde has no roll, ever. that just doesn't make sense.
}

function navball_direction {
  parameter ves IS SHIP.
  parameter direction IS ves:facing.
  return R(pitch_for(ves, direction), compass_for(ves, direction), roll_for(ves, direction)).
}

function compass_for {
  parameter ves IS SHIP.
  parameter direction IS ves:facing.

  local pointing is direction:forevector.
  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}

function east_for {
  parameter ves IS SHIP.

  return vcrs(ves:up:vector, ves:north:vector).
}

function pitch_for {
  parameter ves IS SHIP.
  parameter direction IS ves:facing.

  return 90 - vang(ves:up:vector, direction:forevector).
}

//"Roll" as calculated by by Facing:Roll is, well, difficult to use in calculations involving sin & cosine.
//This function takes the negative facing direction to invert axis, then adds 270 to recenter "level with horizon" at 0, then adds
//360 to remove any negative (original set went from 0 - 360, so it was possible to have -360 + 270 < 0), then mod 360 to remap
//back to degrees.
//invertedRoll(invertedRoll(roll)) = roll for all values 0 <= roll <= 360.
//This method acts as a conversion to and from.
function invertedRoll {
  parameter roll.
  SET newRoll TO mod(630 - roll, 360).

  return newRoll.
}

function roll_for {
  parameter ves IS SHIP.
  parameter direction IS ves:facing.
  
  if vang(direction:vector,ship:up:vector) < 0.2 { //this is the dead zone for roll when the ship is vertical
    return 0.
  } else {
    local raw is vang(vxcl(direction:vector,ship:up:vector), direction:starvector).
    if vang(ves:up:vector, direction:topvector) > 90 {
      if raw > 90 {
        return 270 - raw.
      } else {
        return -90 - raw.
      }
    } else {
      return raw - 90.
    }
  } 
}.

function roll_for_backup {
  parameter ves IS SHIP.
  
  if vang(ship:facing:vector,ship:up:vector) < 0.2 { //this is the dead zone for roll when the ship is vertical
    return 0.
  } else {
    local raw is vang(vxcl(ship:facing:vector,ship:up:vector), ves:facing:starvector).
    if vang(ves:up:vector, ves:facing:topvector) > 90 {
      if raw > 90 {
        return 270 - raw.
      } else {
        return -90 - raw.
      }
    } else {
      return raw - 90.
    }
  } 
}.

//Calculate the heading direction for the given navball direction.
function heading_direction {
  parameter navballDirection.

  LOCAL headingDirection TO HEADING(navballDirection:YAW, navballDirection:PITCH).
  LOCAL headingDirection TO ANGLEAXIS(-navballDirection:ROLL, headingDirection:FOREVECTOR) * headingDirection.

  return headingDirection.
}

//use to find the initial bearing for the shortest path around a sphere from...
function circle_bearing {
 parameter
  p1, //...this point...
  p2. //...to this point.

 return mod(360+arctan2(sin(p2:lng-p1:lng)*cos(p2:lat),cos(p1:lat)*sin(p2:lat)-sin(p1:lat)*cos(p2:lat)*cos(p2:lng-p1:lng)),360).
}.

//use to find the distance from...
function circle_distance {
 parameter
  p1,     //...this point...
  p2,     //...to this point...
  radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
  return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

function clamp {
  parameter value.
  parameter minValue.
  parameter maxValue.

  return MAX(MIN(value, maxValue), minValue).
}