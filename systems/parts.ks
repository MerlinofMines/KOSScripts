function getClosestPart {
    parameter partList. //List<Part>>
    parameter sourcePosition. //Vector

    LOCAL closestPart IS partList[0].
    LOCAL closestDistance IS (closestPart:POSITION - sourcePosition):MAG.

    for part IN partList {
        LOCAL distance IS (part:POSITION - sourcePosition):MAG.

        IF distance < closestDistance {
            SET closestPart TO part.
            SET closestDistance TO distance.
        }
    }

    return closestPart.
}