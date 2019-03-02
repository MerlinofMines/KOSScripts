//Currently expects seconds > 0
function prettyPrintTime {
    parameter seconds.
    parameter label is "Time: ".

    LOCAL hours IS floor(abs(seconds)/3600).
    LOCAL minutes IS floor((abs(seconds) - hours*3600)/60).
    LOCAL remainingSeconds IS round(abs(seconds) - (hours*3600 + minutes*60), 2).

    LOCAL negativeLabel IS "".
    IF (seconds < 0) {SET negativeLabel TO "-".}

    LOCAL hourLabel IS "".
    IF (hours > 0) {SET hourLabel TO hours + "h ". }

    LOCAL minuteLabel IS "".
    IF (minutes > 0) {SET minuteLabel TO minutes + "m ". }

    LOCAL secondLabel IS remainingSeconds + "s".

    Print label + negativeLabel + hourLabel + minuteLabel + secondLabel.
}

function longInfo {
    parameter text.
    parameter duration IS 300.
    output(text, BLUE, duration).    
}

function shortInfo {
    parameter text.
    parameter duration IS 5.
    output(text, BLUE, duration).
}

function info {
    parameter text.
    parameter duration IS 60.
    output(text, BLUE, duration).
}

function error {
    parameter text.
    parameter duration IS 120.
    output(text, RED, duration).
}

function output {
    parameter text.
    parameter color.
    parameter duration.

    Print text.
    HUDTEXT( text,
         duration,
         2,
         18,
         color,
         FALSE).
}