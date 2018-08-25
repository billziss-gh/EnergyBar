#!/bin/bash

openApp()
{
    open "$1"
}

quitApp()
{
    osascript -e "quit app \"$1\""
}

for app in Pages Numbers Keynote; do
    openApp /Applications/$app.app
done

sleep 2

for app in Pages Numbers Keynote; do
    quitApp $app
done
