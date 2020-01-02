RUNONCEPATH("0:/docking/docking.ks").
RUNONCEPATH("0:/systems/grabber.ks").
RUNONCEPATH("0:/output.ks").

function grabPartUsingGrabber {
    parameter sourceGrabber.
    parameter targetPart.

    if (NOT isGrabber(sourceGrabber)) {
        PRINT "Requested Grabber is not a grabber, ignoring.".
    }

    if (NOT isGrabberArmed(sourceGrabber)) {
        PRINT "Arming Grabber".
        armGrabber(sourceGrabber).
    }

    LOCAL sourcePositionSupplier IS {return sourceGrabber:POSITION.}.
    LOCAL targetPositionSupplier IS {return targetPart:POSITION.}.
    LOCAL sourceDirectionSupplier IS {return sourceGrabber:FACING.}.
    LOCAL targetDirectionSupplier IS {return LOOKDIRUP(-targetPart:POSITION, sourceGrabber:FACING:TOPVECTOR).}.//This means grab it by looking at it.
    LOCAL dockedDetector IS {return isGrabberConnected(sourceGrabber).}.

    dock(sourcePositionSupplier, targetPositionSupplier, sourceDirectionSupplier, targetDirectionSupplier, dockedDetector).

    info("Grabbed Successfully").
}

