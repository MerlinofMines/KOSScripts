RUNONCEPATH("0:/input.ks").
RUNONCEPATH("0:/output.ks").
RUNONCEPATH("0:/utility.ks").
RUNONCEPATH("0:/draw.ks").
RUNONCEPATH("0:/control.ks").
RUNONCEPATH("0:/orbital_navigation.ks").

function getDockableTargets {
	parameter sourceVessel IS SHIP.
	LIST Targets IN targets.
	Local dockableTargets IS list().	

	for dockingTarget in targets {
		if ((dockingTarget:Position - sourceVessel:Position):MAG < 500) {
			//TODO: WE could filter out any targets without any dockable ports as well.
			dockableTargets:ADD(dockingTarget).
		}
	}	
	return dockableTargets.
}

function getDockablePorts {
	parameter targetVessel.
	SET dockingPorts TO targetVessel:DockingPorts.
	Local dockablePorts IS list().

	FOR dockingPort IN dockingPorts {
		if NOT isDocked(dockingPort) {
			dockablePorts:Add(dockingPort).
		}
	}

	return dockablePorts.
}

function dockWithPlan {
	LOCAL dockableTargets IS getDockableTargets().

	Local targetVessel IS SHIP.

	LOCAL sourcePort IS selectDockingPort(SHIP, "Source Docking Port").

	IF sourcePort = 0 {
		return "No docking ports available to use for docking.".
	}

	Print "Source Port: " + sourcePort.

	IF dockableTargets:LENGTH = 0 {
		Print "No target vessels in range of docking.".
		return.		
	} ELSE IF dockableTargets:LENGTH = 1 {
		SET targetVessel TO dockableTargets[0].
	} ELSE {
		SET targetVessel TO selectTargetVessel(dockableTargets).
	}

	PRINT("Target Vessel: " + targetVessel).

	LOCAL targetPort IS selectDockingPort(targetVessel, "Target Docking Port").

	IF targetPort = 0 {
		Print targetVessel + " has no available poorts to use for docking.".
	}

	Print "Target Port: " + targetPort.

	sourcePort:CONTROLFROM.

	dockUsingDockingPorts(sourcePort, targetPort).
}

function autoSelectDockingPort {
	parameter targetVessel.

	Local dockablePorts IS getDockablePorts(targetVessel).

	if (dockingPorts:LENGTH = 0) {
		Print "Unable to dock with target vessel, no available ports".
		return.
	} 

	Local bestPort IS dockingPorts[0].
	Local minimumDistance IS (bestPort:NodePosition - SHIP:Orbit:Position):Mag.

	FOR dockablePort IN dockablePorts {
		Local newBestPort IS dockingPorts[0].
		Local newMinimumDistance IS (dockablePort:NodePosition - SHIP:Orbit:Position):Mag.

		IF (newMinimumDistance < minimumDistance) {
			SET minimumDistance TO newMinimumDistance.
			SET bestPort TO newBestPort.
		}
	}

	return bestPort.
}

function selectDockingPort {
	parameter targetVessel.
	parameter title IS "Select Docking Port".

	LOCAL dockingPorts IS getDockablePorts(targetVessel).

	if (dockingPorts:LENGTH = 0) {
		Print "Unable to dock with target vessel, no available ports".
		return.
	} else if (dockingPorts:Length = 1) {
		return dockingPorts[0].
	} else {
		return selectOption(dockingPorts, title).
	}
}

function dockWithTarget {
	parameter sourcePort.
	parameter targetVessel.

	Local targetPort IS autoSelectDockingPort(targetVessel).

	dockUsingDockingPorts(sourcePort, targetPort).
}

function dockUsingDockingPorts {
	parameter sourcePort.
	parameter targetPort.

	LOCAL sourcePositionSupplier IS {return sourcePort:NODEPOSITION.}.
	LOCAL targetPositionSupplier IS {return targetPort:NODEPOSITION.}.
	LOCAL sourceDirectionSupplier IS {return sourcePort:PORTFACING.}.
	LOCAL targetDirectionSupplier IS {return targetPort:PORTFACING.}.
	LOCAL dockedDetector IS {return isDocked(sourcePort).}.

	dock(sourcePositionSupplier, targetPositionSupplier, sourceDirectionSupplier, targetDirectionSupplier, dockedDetector).
}

function dock {
	parameter sourcePositionSupplier.
	parameter targetPositionSupplier.
	parameter sourceDirectionSupplier.
	parameter targetDirectionSupplier.
	parameter dockedDetector.

	//Turn off RCS and translation control
	SET SHIP:CONTROL:TRANSLATION TO V(0,0,0).
	RCS OFF.

	SET refreshInterval TO 0.1.

	SET previousTargetVector TO targetPositionSupplier() - sourcePositionSupplier().

	WAIT refreshInterval.

	info("Moving to correct Orientation").
	UNTIL (dockedDetector()) {
		CLEARSCREEN.
		CLEARVECDRAWS().

//		PRINT("Dock State: " + sourcePort:STATE).

		SET orientation TO -targetDirectionSupplier():FOREVECTOR.
		SET orientationDirection TO LOOKDIRUP(orientation, targetDirectionSupplier():TOPVECTOR).
		LOCK STEERING TO orientationDirection.

		LOCAL targetVector IS targetPositionSupplier() - sourcePositionSupplier().
		LOCAL targetPrograde IS (previousTargetVector - targetVector).
		SET previousTargetVector TO targetVector.

		LOCAL desiredSpeed IS getDesiredDockingSpeed(sourcePositionSupplier(), targetPositionSupplier()).
		LOCAL desiredPrograde IS getDesiredDockingPrograde(orientation, targetVector, desiredSpeed).

//		SET targetProgradeDirection TO LOOKDIRUP(targetPrograde, targetDirectionSupplier():TOPVECTOR).
//		SET targetDirection TO LOOKDIRUP(targetVector, targetDirectionSupplier():TOPVECTOR).

//		Local navballDesiredDirection IS navball_direction(SHIP, orientationDirection).
//		holdDesiredDirection(navballDesiredDirection).

	//	PRINT("Distance: " + targetVector:MAG).
	//	PRINT("Prograde: " + targetPrograde:MAG).


		//Source Port Vectors
	//	drawVector(orientation, "Orientation").
	//	drawVector(targetVector, "Target Vector", sourcePositionSupplier()).
	//	drawVector(desiredPrograde*30, "Desired Prograde", sourcePositionSupplier()).
	//	drawVector(targetPrograde*30, "TargetPrograde", sourcePositionSupplier()).
	//	drawDirection(targetProgradeDirection, "Prograde", sourcePositionSupplier()).

	//	drawDirection(sourceDirectionSupplier(), "Docking Port", sourcePositionSupplier()).
	//	drawDirection(targetDirection, "Target Direction", sourcePositionSupplier()).
	//	drawDirection(orientationDirection, "Orientation Direction", sourcePositionSupplier()).

		//Target Port Vectors
	//	drawDirection(targetDirectionSupplier(), "Target Port", targetPositionSupplier()).
	//	drawVector(targetDirectionSupplier():TOPVECTOR, "Target Top Vector", targetPositionSupplier()).
		
	//	PRINT("Orientation Forevector: " + VANG(orientation,sourceDirectionSupplier():FOREVECTOR)).
	//	PRINT("Orientation TopVector: " + VANG(orientationDirection:TOPVECTOR, sourceDirectionSupplier():TOPVECTOR)).
	//	PRINT("Angular Momentum: " + SHIP:ANGULARMOMENTUM:MAG).

		if ((VANG(orientation,sourceDirectionSupplier():FOREVECTOR) < 0.5)
		 AND (VANG(orientationDirection:TOPVECTOR, sourceDirectionSupplier():TOPVECTOR) < 0.5)
		 AND SHIP:ANGULARMOMENTUM:MAG < 0.5) {
//			Print("Oriented correctly").

			//Remove Rotation.
			SET SHIP:CONTROL:ROTATION TO V(0,0,0).

			WAIT UNTIL SHIP:CONTROL:ROTATION:MAG < 0.01.

			if(RCS = FALSE) {
				RCS ON.
			}

			LOCAL desiredTranslation IS getOrientedTranslation(orientationDirection, desiredPrograde).
			LOCAL currentTranslation IS getOrientedTranslation(orientationDirection, targetPrograde).
			LOCAL deltaTranslation IS desiredTranslation - currentTranslation.
			LOCAL currentTranslation IS getOrientedTranslation(orientationDirection, targetPrograde).
			LOCAL deltaTranslation IS desiredTranslation - currentTranslation.

			PRINT("Translation Change: " + deltaTranslation).
			PRINT("Translation Change Mag: " + deltaTranslation:MAG).

//			drawVector(desiredTranslation*100, "Desired Translation", sourcePositionSupplier()).
//			drawVector(currentTranslation*100, "Current Translation", sourcePositionSupplier()).
//			drawVector(deltaTranslation*100, "Translation Change Needed", sourcePositionSupplier()).

			//Up/Down
			if(abs(deltaTranslation:Y) > 0.001) {
				PRINT("Correcting Up/Down.").
				SET SHIP:CONTROL:TOP TO clamp(deltaTranslation:Y*50, -1, 1).
			} else {
				PRINT "Not Correcting Up/Down".
				SET SHIP:CONTROL:TOP TO 0.
			}
			
			//Left/Right
			if(abs(deltaTranslation:Z) > 0.001) {
				PRINT("Correcting Left/Right.").
				SET SHIP:CONTROL:STARBOARD TO clamp(deltaTranslation:Z*50, -1, 1).
			} else {
				PRINT("Not Correcting Left/Right.").
				SET SHIP:CONTROL:STARBOARD TO 0.
			}

			//Forward/Backwards
			if(abs(deltaTranslation:X) > 0.001) {
				PRINT("Correcting Forwards/Backwards.").
				SET SHIP:CONTROL:FORE TO clamp(deltaTranslation:X*50, -1, 1).
			} else {
				PRINT("Not Correcting Forwards/Backwards.").
				SET SHIP:CONTROL:FORE TO 0.
			}
		} else {
			RCS OFF.
			SET SHIP:CONTROL:TRANSLATION TO V(0,0,0).
		}

		WAIT(refreshInterval).
	}

	SET SHIP:CONTROL:TRANSLATION TO V(0,0,0).
	SET SHIP:CONTROL:ROTATION TO V(0,0,0).
	RCS OFF.

	CLEARSCREEN.
	CLEARVECDRAWS().

	info("Docked Successfully").

}

function getOrientedTranslation {
	parameter orientationDirection.
	parameter relPrograde.

	LOCAL desiredForeVector IS VXCL(orientationDirection:STARVECTOR,VXCL(orientationDirection:TOPVECTOR,relPrograde)).
	LOCAL desiredTopVector IS VXCL(orientationDirection:FOREVECTOR,VXCL(orientationDirection:STARVECTOR,relPrograde)).
	LOCAL desiredStarboardVector IS VXCL(orientationDirection:FOREVECTOR,VXCL(orientationDirection:TOPVECTOR,relPrograde)).

	LOCAL foreTranslation IS desiredForeVector:MAG.
	if(VANG(desiredForeVector,orientationDirection:FOREVECTOR) > 90) {
		SET foreTranslation TO -foreTranslation.
	}

	LOCAL topTranslation IS desiredTopVector:MAG.
	if(VANG(desiredTopVector,orientationDirection:TOPVECTOR) > 90) {
		SET topTranslation TO -topTranslation.
	}

	LOCAL starTranslation IS desiredStarboardVector:MAG.
	if(VANG(desiredStarboardVector,orientationDirection:STARVECTOR) > 90) {
		SET starTranslation TO -starTranslation.
	}

//	return desiredForeVector + desiredTopVector + desiredStarboardVector.
	return V(foreTranslation, topTranslation, starTranslation).
}

function getSourceDockingPort {
	parameter dockingPortTag.
	return getVesselDockingPort(SHIP, dockingPortTag).
}

function getTargetDockingPort {
	parameter targetVesselName.
	parameter dockingPortTag.

	LOCAL targetVessel IS Vessel(targetVesselName).
	return getVesselDockingPort(targetVessel, dockingPortTag).
}

function getVesselDockingPort {
	parameter targetVessel.
	parameter dockingPortTag.
	
	return targetVessel:PartsTagged(dockingPortTag)[0].
}

function getDesiredDockingPrograde {
	parameter orientationVector.
	parameter targetVector.
	parameter desiredSpeed.

	LOCAL desiredPrograde IS (targetVector:NORMALIZED * 3 - orientationVector:Normalized).

	if(VANG(targetVector, orientationVector) > 90) {
		SET desiredPrograde TO targetVector:NORMALIZED - orientationVector:Normalized.
	}

	SET desiredPrograde TO desiredPrograde:NORMALIZED * desiredSpeed.

	return desiredPrograde.
}

function getDesiredDockingSpeed {
	parameter sourcePosition.
	parameter targetPosition.

	LOCAL distance IS (targetPosition - sourcePosition):MAG.

	if (distance > 50) {
		return 0.1.
	} else if(distance > 10) {
		return 0.05.
	} else if(distance > 5) {
		return 0.025.
	} else {
		return 0.0125.
	}
}

function isDocked {
	parameter sourcePort.
	return sourcePort:STATE:CONTAINS("Docked").
}