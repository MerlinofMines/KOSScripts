function hasGrabber {
    parameter vessel IS SHIP.

    return getGrabbers():LENGTH > 0.
}

function getGrabbers {
    parameter vessel IS SHIP.

    return vessel:PARTSDUBBED("GrapplingDevice").
}

function armGrabber {
    parameter part.
    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return.
    }

    LOCAL module IS part:GETMODULE("ModuleAnimateGeneric").

    if NOT module:HASEVENT("arm") {
        PRINT "Requested Grabber cannot be armed, ignoring.".
        return.
    }

    PRINT "Arming Grabber".
    module:DOEVENT("arm").
    WAIT 3.
}

function disarmGrabber {
    parameter part.
    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return.
    }

    LOCAL module IS part:GETMODULE("ModuleAnimateGeneric").

    if NOT module:HASEVENT("disarm") {
        PRINT "Requested Grabber cannot be disarmed, ignoring.".
        return.
    }

    PRINT "Disarming Grabber".
    module:DOEVENT("disarm").
    WAIT 3.
}

function releaseGrabber {
    parameter part.
    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return.
    }

    if NOT isGrabberConnected(part) {
        PRINT "Grabber is not connected, ignoring request to release.".
    }

    LOCAL module IS part:GETMODULE("ModuleGrappleNode").

    PRINT "Releaseing Grabber".
    module:DOEVENT("release").
    WAIT 1.
}

function isGrabberArmed {
    parameter part.

    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return false.
    }

    LOCAL module IS part:GETMODULE("ModuleAnimateGeneric").

    return module:HASEVENT("disarm").
}

function isGrabberConnected {
    parameter part.

    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return false.
    }

    LOCAL module IS part:GETMODULE("ModuleGrappleNode").

    return module:HASEVENT("release").
}

function isGrabber {
    parameter part.

    return part:HASMODULE("ModuleAnimateGeneric") AND part:HASMODULE("ModuleGrappleNode").
}