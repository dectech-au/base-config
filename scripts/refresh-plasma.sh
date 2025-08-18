#!/usr/bin/env bash

kquitapp6 plasmashell
kquitapp6 kactivitymanagerd
rm -f ~/.cache/ksycoca*
kbuildsycoca6 --noincremental
plasmashell --replace & disown
