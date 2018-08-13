#!/bin/bash

RunningApplications=()

openApp()
{
    open "$1"
}

quitApp()
{
    osascript -e "quit app \"$1\""
}

Applications=(/Applications/*.app)
while true; do
    Application=${Applications[$RANDOM % ${#Applications[@]}]}

    case "$Application" in
    */Chess.app)                continue ;;
    */Dashboard.app)            continue ;;
    */Launchpad.app)            continue ;;
    */Safari.app)               continue ;;
    */Terminal.app)             continue ;;
    */"Touch Bar Dock.app")     continue ;;
    */"Visual Studio Code.app") continue ;;
    */Xcode.app)                continue ;;
    esac

    case $(( $RANDOM & 1 )) in
    1)                          openApp "$Application" ;;
    0)                          quitApp "$Application" ;;
    esac
done
