#!/usr/bin/env bash

function json_to_valid_json() {
  source_file=$1
  echo -n "  - $source_file ... "
  temporary_file_1=$1.1.tmp
  temporary_file_2=$1.2.tmp

  cp "$source_file" "$temporary_file_1"

  # Remove existing brackets to allow for multiple runs
  sed -i "s/\[//" "$temporary_file_1"
  sed -i "s/\]//" "$temporary_file_1"

  echo -n "[" > "$temporary_file_2"
  cat "$temporary_file_1" | sed -e "s/\}$/\},/g" >> "$temporary_file_2"
  echo -n "]" >> "$temporary_file_2"

  # Remove obsolete comma at the end
  cat "$temporary_file_2" | tr '\n' '\f' | sed -e 's/,\f\]/\f\]/' | tr '\f' '\n' > "$temporary_file_1"

  cp "$temporary_file_1" "$source_file"
  rm "$temporary_file_1" "$temporary_file_2"
  echo "OK"
}

json_to_valid_json "results/js.library.json"
json_to_valid_json "results/js.library.version.json"
