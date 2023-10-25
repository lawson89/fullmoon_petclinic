#!/bin/bash

# credit to https://www.baeldung.com/linux/monitor-changes-directory-tree

# we assume running in current folder
DIRECTORY="./srv"

on_change() {
  make add
  make stop-daemon
  make start-daemon
}

file_removed() {
    TIMESTAMP=$(date)
    echo "[$TIMESTAMP]: The file $1$2 was removed"
    on_change
}

file_modified() {
    TIMESTAMP=$(date)
    echo "[$TIMESTAMP]: The file $1$2 was modified"
    on_change
}

file_created() {
    TIMESTAMP=$(date)
    echo "[$TIMESTAMP]: The file $1$2 was created"
    on_change
}

inotifywait -q -m -r -e modify,delete,create "$DIRECTORY" | while read DIRECTORY EVENT FILE; do
    case $EVENT in
        MODIFY*)
            file_modified "$DIRECTORY" "$FILE"
            ;;
        CREATE*)
            file_created "$DIRECTORY" "$FILE"
            ;;
        DELETE*)
            file_removed "$DIRECTORY" "$FILE"
            ;;
    esac
done
