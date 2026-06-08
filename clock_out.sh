#!/bin/bash
cd /Users/azizbekjuraev/Desktop/jibble_bot
export $(cat .env | xargs)

/opt/homebrew/bin/mix run -e "JibbleBot.clock_out()"
