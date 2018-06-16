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

	LOCAL selectGUI IS GUI(200).
	LOCAL label IS selectGUI:ADDLABEL(title).
	LOCAL popup is selectGUI:addPopupMenu().
	LOCAL ok IS selectGUI:ADDBUTTON("OK").

	SET ok:ONCLICK to myClickChecker@.

	for option in options {
		popup:addoption(option).
	}

	selectGUI:SHOW().

	wait until isOKClicked.

	selectGUI:HIDE().

	return popup:value.
}

function myClickChecker {
	PRINT "I've been clicked!".
	SET isOKClicked TO TRUE.
}