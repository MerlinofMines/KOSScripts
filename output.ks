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
         1,
         18,
         color,
         FALSE).
}