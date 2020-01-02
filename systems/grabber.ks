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

    module:DOEVENT("disarm").
    WAIT 3.
}

function releaseGrabber {
    parameter part.
    if (NOT isGrabber(part)) {
        PRINT "Requested part is not a grabber, ignoring".
        return.
    }

    //TODO: How to release a grapple?
    PRINT "WARNING, GRAPPLE RELEASE NOT IMPLEMENTED.".
}

function isGrabber {
    parameter part.

    return part:HASMODULE("ModuleAnimateGeneric") AND part:HASMODULE("ModuleGrappleNode").
}