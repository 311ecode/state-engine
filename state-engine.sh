#!/usr/bin/env bash


STATE_ENGINE_defaultStatePath=$RCDIR
STATE_ENGINE_statePath=$StatePath || "${STATE_ENGINE_defaultStatePath}"
[[ ! -z ${StatePath+z} ]] || STATE_ENGINE_statePath=$STATE_ENGINE_defaultStatePath && dbgvar STATE_ENGINE_statePath is at ${STATE_ENGINE_statePath}
STATE_ENGINE_stateFileName='state'
STATE_ENGINE_stateFile="${STATE_ENGINE_statePath}/${STATE_ENGINE_stateFileName}"
touch "$STATE_ENGINE_stateFile"

addState(){
  readStateFile
  local state="$(printState)"
  local variableName=$1
  local optionalValue=$2
  # local stateFile="$3"

  [[ -z "$2" ]] && 
  read -r variableValue
  [[ -z "$2" ]] || variableValue="$optionalValue"

  addStateLine(){
      local name="$1"
      local value="$2"
      local line="${name}='${value}'"
      echo -e "$line" 
  }

  [[ -n $(echo "$state" | grep "$variableName" ) ]] || 
  addStateLine "${variableName}" "${variableValue}" >> "$STATE_ENGINE_stateFile"
  [[ -n $(echo "$state" | grep "$variableName" ) ]] && 
  deleteStateLineStartsWith "${variableName}" &&
  addStateLine "${variableName}" "${variableValue}" >> "$STATE_ENGINE_stateFile"
  readStateFile
}


readStateFile() {
  touch $STATE_ENGINE_stateFile
  set -o allexport
  source $STATE_ENGINE_stateFile
  set +o allexport
}

unloadStateFile() {
  touch "$STATE_ENGINE_stateFile"
  for line in $(cat "$STATE_ENGINE_stateFile");do
    unset $(echo "$line"|  awk -F "=" '{print $1}')
  done
}

printState() {
  cat $STATE_ENGINE_stateFile
}

deleteStateLineStartsWith() {
  local name=$1
  echo -e "$(printState | sed -n "/^${name}\='/!p")" > "$STATE_ENGINE_stateFile"
  unset "$1"
}

deleteStateLine() {
  PS3="Enter a number of a line you want to remove: "

  select line in $(printState)
  do
      echo "Selected Line: $line"
      local name=$(echo "$line" | awk -F "=" '{print $1}')
      deleteStateLineStartsWith "$name"
      echo "line $REPLY is removed frome the state file."
  done
}

editState(){
  code "$STATE_ENGINE_stateFile"
}

doStgEveryNSeconds(){
  readStateFile
  local variableName="_timer_$1"
  local secondsInterval=$2
  local variableValue=${!variableName}
  local now=$(date +"%s")

  addTimer(){
    addState "${variableName}" "$((now+secondsInterval))"
  }

  local command="${*:3}"
  [[ -n $variableValue ]] || addTimer 
  [[ "$now" -gt "$variableValue" ]] && addTimer &&
  ${command}
}
