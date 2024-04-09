#!/bin/bash

# Define the order of notes in an octave
note_order=("C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B")

# Function to get the index of a note in the note_order array
get_note_index() {
    local note="$1"
    for i in "${!note_order[@]}"; do
        if [[ "${note_order[$i]}" == "$note" ]]; then
            echo $i
            return
        fi
    done
    echo -1
}

# Check if a directory was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

directory="$1"

# Check if the provided directory exists
if [ ! -d "$directory" ]; then
    echo "Directory does not exist: $directory"
    exit 1
fi

# Temporary file to hold filenames and sort keys
temp_file=$(mktemp /tmp/sort_piano_notes.XXXXXX)

# Populate the temporary file with sort keys based on note and octave
for file in "$directory"/*; do
    filename=$(basename -- "$file")
    note_and_octave=${filename%%-*}
    note=${note_and_octave:0:2} # Assume note (including sharp if present)
    octave=${note_and_octave:2:1} # Extract octave

    # Handle natural notes (single character notes)
    if ! [[ $note =~ "#" ]]; then
        note=${note_and_octave:0:1}
        octave=${note_and_octave:1:1}
    fi

    note_index=$(get_note_index "$note")
    if [[ $note_index -ne -1 ]]; then
        sort_key=$(printf "%02d%02d" "$octave" "$note_index") # Create sort key as octaveNoteIndex
        echo "$sort_key $file" >> "$temp_file"
    fi
done

# Sort the temporary file and rename files
counter=1
while read -r line; do
    file=$(echo "$line" | cut -d ' ' -f 2-)
    new_name=$(printf "%d - %s" "$counter" "$(basename -- "$file")")
    mv "$file" "$directory/$new_name"
    ((counter++))
done < <(sort -n "$temp_file")

# Clean up
rm "$temp_file"

echo "Files have been sorted and renamed."
