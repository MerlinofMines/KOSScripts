DECLARE GLOBAL OVERVIEW_TAB TO "".
DECLARE GLOBAL MISSION_TASK_LIST TO list().

//Mission Utilities
function refreshActiveTasks {
    OVERVIEW_TAB:CLEAR().
    LOCAL label IS OVERVIEW_TAB:ADDLABEL("Mission Overview").
    SET label:STYLE:ALIGN TO "CENTER".

    //    OVERVIEW_TAB:AddLabel("Mission Overview").

    Local layout IS OVERVIEW_TAB:addVLayout().
    Local missionBox IS layout:ADDSCROLLBOX().

    Local taskIterator IS MISSION_TASK_LIST:COPY:ITERATOR.

    UNTIL NOT taskIterator:NEXT {
        LOCAL taskBox IS missionBox:AddHBox().

        //Remove Button
        LOCAL removeButton IS taskBox:ADDBUTTON("X").

        LOCAL index IS taskIterator:INDEX.

        SET removeButton:STYLE:WIDTH TO 20.
        SET removeButton:STYLE:MARGIN:RIGHT TO 5.
        SET removeButton:ONCLICK TO {removeMissionTask(index).}.

        //Mission Label
        Local missionlabel IS getTaskName(taskIterator:VALUE).

        taskBox:AddLabel(missionlabel).
    }

    IF MISSION_TASK_LIST:LENGTH > 1 {
        LOCAL clearButton IS OVERVIEW_TAB:AddButton("Clear all Tasks").
        SET clearButton:ONCLICK TO { clearMissionTasks().}.
    }
}

function insertMissionTask {
    parameter index.
    parameter task.

    MISSION_TASK_LIST:INSERT(index, task).

    LOCAL taskName IS getTaskName(task).
    Print "Inserted Mission Task: " + taskName.

    refreshActivetasks().
}

function addMissionTask {
    parameter task.

    MISSION_TASK_LIST:ADD(task).

    LOCAL taskName IS getTaskName(task).
    Print "Added Mission Task: " + taskName.

    refreshActivetasks().
    }

function removeMissionTask {
    parameter index.

    LOCAL task IS MISSION_TASK_LIST[index].
    LOCAL taskName is getTaskname(task).

    MISSION_TASK_LIST:REMOVE(index).

    PRINT "Removed Mission Task: " + taskName.

    refreshActiveTasks().
}

function clearMissionTasks {
    MISSION_TASK_LIST:CLEAR().

    Print "Cleared Mission Tasks.".

    refreshActiveTasks().
}


function addMissionTaskButton {
    parameter taskTab.
    parameter taskName.
    parameter taskDelegate.
    parameter buttonLabel IS taskName.

    LOCAL taskButton IS taskTab:ADDBUTTON(buttonLabel).
    SET taskButton:ONCLICK TO {
        addMissionTask(getTask(taskName, taskDelegate)).
        activateButton(taskButton).
    }.
}

function activateButton {
    parameter button.
    SET button:STYLE:TEXTCOLOR TO GREEN.
    SET button:STYLE:HOVER:TEXTCOLOR TO GREEN.
    SET button:STYLE:ON:TEXTCOLOR TO GREEN.
    WAIT 0.25.
    SET button:STYLE:TEXTCOLOR TO WHITE.
    SET button:STYLE:HOVER:TEXTCOLOR TO WHITE.
    SET button:STYLE:ON:TEXTCOLOR TO WHITE.
}

function executeMission {
    CLEARSCREEN.
    for task IN MISSION_TASK_LIST {
        Local taskName IS getTaskName(task).
        Local taskDelegate IS getTaskDelegate(task).

        PRINT "Executing Task: " + taskName.
        taskDelegate().
    }
}


//Task Utilities
function getTask {
    parameter name.
    parameter delegate.

    return list(name, delegate).
}

function getTaskName {
    parameter task.
    return task[0].
}

function getTaskDelegate {
    parameter task.
    return task[1].
}