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
    */"Mission Control.app")    continue ;;
    */Safari.app)               continue ;;
    */Siri.app)                 continue ;;
    */Terminal.app)             continue ;;
    */"Time Machine.app")       continue ;;
    */"Touch Bar Dock.app")     continue ;;
    */"Visual Studio Code.app") continue ;;
    */Xcode.app)                continue ;;
    esac

    case $(( $RANDOM % 10 )) in
    [0-2])                      openApp "$Application" ;;
    [3-9])                      quitApp "$Application" ;;
    esac
done
