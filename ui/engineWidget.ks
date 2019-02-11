DECLARE GLOBAL PRIMARY_ENGINES TO getDefaultPrimaryEngines().
DECLARE GLOBAL SECONDARY_ENGINES TO getDefaultSecondaryEngines().
DECLARE GLOBAL UNASSIGNED_ENGINES TO getDefaultUnassignedEngines().
DECLARE GLOBAL ENGINE_PANELS TO LIST().

//Use this function to add a new engine choice panel where appropriate.
function engineChoicePanel {
    parameter panel.

    parameter choicePanel IS panel:ADDVLAYOUT().
    parameter choiceScrollPanel IS choicePanel:ADDSCROLLBOX().

    ENGINE_PANELS:ADD(choiceScrollPanel).

    refreshEnginePanels().
}

function refreshEnginePanels {
    FOR panel IN ENGINE_PANELS {
        refreshEnginePanel(panel).
    }
}

function refreshEnginePanel {
    parameter enginePanel.
    enginePanel:CLEAR().

    //Primary Engines
    LOCAL primaryEnginePanel IS enginePanel:ADDVBOX().
    LOCAL primaryEngineIterator IS PRIMARY_ENGINES:COPY:ITERATOR.

    LOCAL primaryEnginelabel IS primaryEnginePanel:ADDLABEL("Primary Engines").
    SET primaryEnginelabel:STYLE:ALIGN TO "CENTER".

    IF PRIMARY_ENGINES:EMPTY {
        LOCAL nonelabel IS primaryEnginePanel:ADDLABEL("None").
        SET nonelabel:STYLE:ALIGN TO "CENTER".
    }

    UNTIL NOT primaryEngineIterator:NEXT {
        LOCAL engine IS primaryEngineIterator:VALUE.
        LOCAL index IS primaryEngineIterator:INDEX.

        engineDetailBox(primaryEnginePanel, engine, FALSE, TRUE, PRIMARY_ENGINES, index).
    }

    //Secondary Engines
    LOCAL secondaryEnginePanel IS enginePanel:ADDVBOX().
    LOCAL secondaryEngineIterator IS SECONDARY_ENGINES:COPY:ITERATOR.

    LOCAL secondaryEnginelabel IS secondaryEnginePanel:ADDLABEL("Secondary Engines").
    SET secondaryEnginelabel:STYLE:ALIGN TO "CENTER".

    IF SECONDARY_ENGINES:EMPTY {
        LOCAL nonelabel IS secondaryEnginePanel:ADDLABEL("None").
        SET nonelabel:STYLE:ALIGN TO "CENTER".
    }

    UNTIL NOT secondaryEngineIterator:NEXT {
        LOCAL engine IS secondaryEngineIterator:VALUE.
        LOCAL index IS secondaryEngineIterator:INDEX.

        engineDetailBox(secondaryEnginePanel, engine, FALSE, TRUE, SECONDARY_ENGINES, index).
    }

    //Unassigned Engines
    LOCAL unassignedEnginePanel IS enginePanel:ADDVBOX().
    LOCAL unassignedEngineIterator IS UNASSIGNED_ENGINES:COPY:ITERATOR.

    LOCAL unassignedEnginelabel IS unassignedEnginePanel:ADDLABEL("Unassigned Engines").
    SET unassignedEnginelabel:STYLE:ALIGN TO "CENTER".

    IF UNASSIGNED_ENGINES:EMPTY {
        LOCAL nonelabel IS unassignedEnginePanel:ADDLABEL("None").
        SET nonelabel:STYLE:ALIGN TO "CENTER".
    }

    UNTIL NOT unassignedEngineIterator:NEXT {
        LOCAL engine IS unassignedEngineIterator:VALUE.
        LOCAL index IS unassignedEngineIterator:INDEX.

        engineDetailBox(unassignedEnginePanel, engine, TRUE, FALSE, UNASSIGNED_ENGINES, index).
    }
}

function engineDetailBox {
    parameter panel.
    parameter engine.
    parameter showAddButtons.
    parameter showRemoveButton.
    parameter parentList.
    parameter index.

    LOCAL outerBox IS panel:ADDVBOX().
    LOCAL engineBox IS outerBox:AddHBox().
    LOCAL highlight IS HIGHLIGHT(engine, RGBA(0,1,0,1)).
    SET highlight:ENABLED TO FALSE.

    //Remove Button
    if showRemoveButton {
        LOCAL removeButton IS engineBox:ADDBUTTON("X").

        SET removeButton:STYLE:WIDTH TO 20.
        SET removeButton:STYLE:MARGIN:RIGHT TO 5.
        SET removeButton:ONCLICK TO {removeEngine(parentList, index).}.
    }

    //Add Buttons
    if showAddButtons {
        LOCAL addPrimaryButton IS engineBox:ADDBUTTON("P").
        LOCAL addSecondaryButton IS engineBox:ADDBUTTON("S").

        SET addPrimaryButton:STYLE:WIDTH TO 20.
        SET addPrimaryButton:STYLE:MARGIN:RIGHT TO 5.
        SET addPrimaryButton:ONCLICK TO {addPrimaryEngine(index).}.

        SET addSecondaryButton:STYLE:WIDTH TO 20.
        SET addSecondaryButton:STYLE:MARGIN:RIGHT TO 5.
        SET addSecondaryButton:ONCLICK TO {addSecondaryEngine(index).}.
    }

    //Engine Label
    Local enginelabel IS getEngineName(engine).
    engineBox:AddLabel(enginelabel).

    //Detail Box
    LOCAL detailBox IS outerBox:ADDHBox().
    detailBox:ADDLABEL("ISP: " + engine:ISP).

    //Detail Button
    LOCAL showDetailButton IS engineBox:ADDBUTTON(">").
    LOCAL hideDetailButton IS engineBox:ADDBUTTON("^").
    SET showDetailButton:STYLE:WIDTH TO 20.
    SET showDetailButton:STYLE:MARGIN:RIGHT TO 5.
    SET hideDetailButton:STYLE:WIDTH TO 20.
    SET hideDetailButton:STYLE:MARGIN:RIGHT TO 5.

    SET hideDetailButton:VISIBLE TO FALSE.
    SET detailBox:VISIBLE TO FALSE.

    SET showDetailButton:ONCLICK TO {
        SET showDetailButton:VISIBLE TO FALSE.
        SET hideDetailButton:VISIBLE TO TRUE.
        SET detailBox:VISIBLE TO TRUE.
        SET highlight:ENABLED TO TRUE.
    }.

    SET hideDetailButton:ONCLICK TO {
        SET showDetailButton:VISIBLE TO TRUE.
        SET hideDetailButton:VISIBLE TO FALSE.
        SET detailBox:VISIBLE TO FALSE.
        SET highlight:ENABLED TO FALSE.
    }.
}

function getPrimaryEngines {
    return PRIMARY_ENGINES:COPY.
}

function getSecondaryEngines {
    return SECONDARY_ENGINES:COPY.
}

function removeEngine {
    parameter engineList.
    parameter index.

    LOCAL eng IS engineList[index].
    engineList:REMOVE(index).
    UNASSIGNED_ENGINES:ADD(eng).

    refreshEnginePanels().
}

function addPrimaryEngine {
    parameter index.
    addEngine(PRIMARY_ENGINES,index).
}

function addSecondaryEngine {
    parameter index.

    addEngine(SECONDARY_ENGINES,index).
}

function addEngine {
    parameter engineList.
    parameter index.

    LOCAL eng IS UNASSIGNED_ENGINES[index].
    engineLIST:ADD(eng).
    UNASSIGNED_ENGINES:REMOVE(index).

    refreshEnginePanels().
}

function getDefaultPrimaryEngines {
    return getEnginesWithTag("primary").
}

function getDefaultSecondaryEngines {
    return getEnginesWithTag("secondary").
}

function getDefaultUnassignedEngines {
    LIST ENGINES in my_engines.
    SET engineList TO LIST().
    for eng IN my_engines {
        if NOT (eng:TAG = "primary") AND NOT (eng:TAG = "secondary") {
            engineList:ADD(eng).
        }
    }

    return engineList.
}

function getEnginesWithTag {
    parameter tag.

    LIST ENGINES in my_engines.
    SET engineList TO LIST().
    for eng IN my_engines {
        if eng:TAG = tag {
            engineList:ADD(eng).
        }
    }

    return engineList.
}

function getEngineName {
    parameter engine.
    return engine:NAME+" "+engine:TAG.
}