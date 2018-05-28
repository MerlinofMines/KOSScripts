function selectTargetVessel {
	LIST Targets IN targets.
	parameter targetOptions IS targets.
	parameter title IS "Select Target Vessel".
	return selectOption(targetOptions, title).
}

function selectOption {
	parameter options.
	parameter title IS "Select Option".

	SET isOKClicked TO FALSE.

	LOCAL gui IS GUI(200).
	LOCAL label IS gui:ADDLABEL(title).
	LOCAL popup is gui:addPopupMenu().
	LOCAL ok IS gui:ADDBUTTON("OK").

	for option in options {
		popup:addoption(option).
	}	

	gui:SHOW().

	SET ok:ONCLICK to myClickChecker@.
//	wait until popup:CHANGED.
	wait until isOKClicked.
	gui:HIDE().

	return popup:value.

}

function myClickChecker {
	SET isOKClicked TO TRUE.
}