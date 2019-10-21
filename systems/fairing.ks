function getFairings {
    parameter vessel IS SHIP.
    return vessel:PARTSTITLEDPATTERN("Protective Shell").
}

function deployFairing {
    parameter fairing.

    if NOT fairing:HASMODULE("ModuleProceduralFairing") {
        PRINT "Requested item is not a fairing: " + fairing.
        return.
    }

    LOCAL module IS fairing:GETMODULE("ModuleProceduralFairing").

    IF NOT module:HASEVENT("deploy") {
        PRINT "Requested fairing has already been deployed.  Ignoring.".
        return.
    }

    module:DOEVENT("deploy").
}

function isFairing {
    parameter part.
}

