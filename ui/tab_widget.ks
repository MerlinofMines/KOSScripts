//Much of this code in this file was taken from https://ksp-kos.github.io/KOS/tutorials/gui.html#creating-the-tabwidget.
function addTabWidget {
    parameter box.
    parameter vertical IS false.

    // Add a vlayout (in case the box is a HBOX, for example),
    // then add a hlayout for the tabs and a stack to hols all the panels.
    if NOT vertical {
        local vbox IS box:ADDVLAYOUT.
        local tabs IS vbox:ADDHLAYOUT.
        local panels IS vbox:ADDSTACK.
        return vbox.
    } else {
        local vbox IS box:ADDHLAYOUT.
        local tabs IS vbox:ADDVLAYOUT.
        local panels IS vbox:ADDSTACK.
        return vbox.
    }
}

function addTab {
    parameter tabwidget. // (the vbox)
    parameter tabname. // title for the tab
    parameter vertical IS TRUE.

    // Get back the two widgets we created in AddTabWidget
    local hboxes IS tabwidget:WIDGETS.
    local tabs IS hboxes[0]. // the HLAYOUT
    local panels IS hboxes[1]. // the STACK

    LOCAL panel IS "".

    // Add another panel, style it correctly
    IF vertical {
        LOCAL panel IS panels:ADDVBOX.
        LOCAL tab IS tabs:ADDBUTTON(tabname).
        SET tab:TOGGLE TO true.
        SET tab:EXCLUSIVE TO true.
        SET tab:ONCLICK TO {panels:showOnly(panel).}.
        IF panels:WIDGETS:LENGTH = 1 {
            SET tab:PRESSED TO true.
            panels:SHOWONLY(panel).
        } else {
            panel:HIDE().
        }

        return panel.
    } ELSE {
        LOCAL panel IS panels:ADDHBOX.
        LOCAL tab IS tabs:ADDBUTTON(tabname).
        SET tab:TOGGLE TO true.
        SET tab:EXCLUSIVE TO true.
        SET tab:ONCLICK TO {panels:showOnly(panel).}.
        IF panels:WIDGETS:LENGTH = 1 {
            SET tab:PRESSED TO true.
            panels:SHOWONLY(panel).
        } else {
            panel:HIDE().
        }

        return panel.
    }
//    SET panel:STYLE TO panel:GUI:SKIN:GET("TabWidgetPanel").

    // Add another tab, style it correctly
    LOCAL tab IS tabs:ADDBUTTON(tabname).
//    SET tab:STYLE TO tab:GUI:SKIN:GET("TabWidgetTab").

    // Set the tab button to be exclusive - when
    // one tab goes up, the others go down.
    SET tab:TOGGLE TO true.
    SET tab:EXCLUSIVE TO true.

    //Set the onclick for the new button to say "show me!!".
    SET tab:ONCLICK TO {panels:showOnly(panel).}.

    // If this is the first tab, make it start already shown (make the tab presssed)
    // Otherwise, we hide it (even though the STACK will only show the first anyway,
    // but by keeping everything "correct", we can be a little more efficient later.
    IF panels:WIDGETS:LENGTH = 1 {
        SET tab:PRESSED TO true.
        panels:SHOWONLY(panel).
    } else {
        panel:HIDE().
    }

    return panel.
}