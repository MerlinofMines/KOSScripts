RUNONCEPATH("0:/utility.ks").

function drawNavballDirection {
	parameter navballDirection.
	parameter label.
	drawDirection(heading_direction(navballDirection), label).	
}

function drawDirection {
	parameter direction.
	parameter label.
	parameter startingVector IS V(0,0,0).

	LOCAL runwayForeVector TO VECDRAW(startingVector, direction:FOREVECTOR*30, RGB(1,0,0),label + ".F",1.0, TRUE, 0.2).
	LOCAL runwayStarVector TO VECDRAW(startingVector, direction:STARVECTOR*30, RGB(0,1,0),label + ".S",1.0, TRUE, 0.2).
	LOCAL runwayTopVector TO VECDRAW(startingVector, direction:TOPVECTOR*30, RGB(0,0,1),label + ".T",1.0, TRUE, 0.2).
}

function drawVector {
	parameter endingVector.
	parameter label.
	parameter startingVector IS V(0,0,0).
	LOCAL drawnVector TO VECDRAW(startingVector, endingVector, RGB(1,0,0), label, 1.0, TRUE, 0.2).
}