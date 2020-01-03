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
        LOCAL outerBox IS missionBox:ADDVBox().
        LOCAL taskBox IS outerBox:AddHBox().
        LOCAL index IS taskIterator:INDEX.

        //Action Box
        LOCAL actionBox IS taskBox:AddHBox().
        SET actionBOX:STYLE:WIDTH TO 78.

        //Move Up Button
        LOCAL moveUpButton IS actionBox:ADDBUTTON("^").
        SET moveUpButton:STYLE:WIDTH TO 20.
        SET moveUpButton:STYLE:MARGIN:RIGHT TO 5.

        IF index > 0 {
            SET moveUpButton:ONCLICK TO {swapMissionTasks(index-1,index).}.
        } ELSE {
            SET moveUpButton:TEXT TO " ".
            SET moveUpButton:STYLE:NORMAL:BG TO "transparent".
            SET moveUpButton:STYLE:NORMAL_ON:BG TO "transparent".
            SET moveUpButton:STYLE:HOVER:BG TO "transparent".
            SET moveUpButton:STYLE:HOVER_ON:BG TO "transparent".
        }

        //Move Down Button
        LOCAL moveDownButton IS actionBox:ADDBUTTON("v").
        SET moveDownButton:STYLE:WIDTH TO 20.
        SET moveDownButton:STYLE:MARGIN:RIGHT TO 5.

        IF index < MISSION_TASK_LIST:LENGTH - 1 {
            SET moveDownButton:ONCLICK TO {swapMissionTasks(index,index+1).}.
        } ELSE {
            SET moveDownButton:TEXT TO " ".
            SET moveDownButton:STYLE:NORMAL:BG TO "transparent".
            SET moveDownButton:STYLE:NORMAL_ON:BG TO "transparent".
            SET moveDownButton:STYLE:HOVER:BG TO "transparent".
            SET moveDownButton:STYLE:HOVER_ON:BG TO "transparent".
        }

        //Remove Button
        LOCAL removeButton IS actionBox:ADDBUTTON("X").

        SET removeButton:STYLE:WIDTH TO 20.
        SET removeButton:STYLE:MARGIN:RIGHT TO 5.
        SET removeButton:ONCLICK TO {removeMissionTask(index).}.

        //Mission Label
        Local missionlabel IS getTaskName(taskIterator:VALUE).

        taskBox:AddLabel(missionlabel).

        //Detail Box
        LOCAL detailBox IS outerBox:ADDHBox().
        SET detailBox:VISIBLE TO FALSE.

        detailBox:ADDLABEL(getTaskDetail(taskIterator:VALUE)).

        //Detail Button
        LOCAL showDetailButton IS taskBox:ADDBUTTON(">").
        LOCAL hideDetailButton IS taskBox:ADDBUTTON("^").

        SET hideDetailButton:VISIBLE TO FALSE.

        SET showDetailButton:STYLE:WIDTH TO 20.
        SET showDetailButton:STYLE:MARGIN:RIGHT TO 5.
        SET hideDetailButton:STYLE:WIDTH TO 20.
        SET hideDetailButton:STYLE:MARGIN:RIGHT TO 5.

        SET showDetailButton:ONCLICK TO {
            SET showDetailButton:VISIBLE TO FALSE.
            SET hideDetailButton:VISIBLE TO TRUE.
            SET detailBox:VISIBLE TO TRUE.
        }.

        SET hideDetailButton:ONCLICK TO {
            SET showDetailButton:VISIBLE TO TRUE.
            SET hideDetailButton:VISIBLE TO FALSE.
            SET detailBox:VISIBLE TO FALSE.
        }.
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

function swapMissionTasks {
    parameter firstIndex.
    parameter secondIndex.

    LOCAL firstTask IS MISSION_TASK_LIST[firstIndex].
    LOCAL secondTask IS MISSION_TASK_LIST[secondIndex].

    //Re-insert First Task
    MISSION_TASK_LIST:REMOVE(firstIndex).
    MISSION_TASK_LIST:INSERT(firstIndex,secondTask).

    //Re-insert First Task
    MISSION_TASK_LIST:REMOVE(secondIndex).
    MISSION_TASK_LIST:INSERT(secondIndex,firstTask).

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
    parameter detail IS name.

    return list(name, delegate, detail).
}

function getTaskName {
    parameter task.
    return task[0].
}

function getTaskDelegate {
    parameter task.
    return task[1].
}

function getTaskDetail {
    parameter task.
    return task[2].
}