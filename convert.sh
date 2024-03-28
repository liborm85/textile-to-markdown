#!/bin/bash

# $1 - regex
# $2 - pagename
# $3 - extension
function replace_code() {
  local lastStepNumber=$stepsCounter
  stepsCounter=$((stepsCounter+1))
  sed -e "$1" \
    tmp/$2-$lastStepNumber.$3 > tmp/$2-$stepsCounter.$3
}

# $1 - regex
# $2 - pagename
# $3 - extension
function replace_code_regex() {
  local lastStepNumber=$stepsCounter
  stepsCounter=$((stepsCounter+1))
  sed -r -e "$1" \
    tmp/$2-$lastStepNumber.$3 > tmp/$2-$stepsCounter.$3
}

# cleanup folders
rm tmp/*.textile
rm tmp/*.md
rm output/*.md

# convert all textile files
for filename in input/*.textile
do
  pagename="$(basename -- $filename .textile)"
  echo "$filename (PAGE: $pagename)"

  stepsCounter="0"

  cp $filename tmp/$pagename-0.textile

  # PRE TRANSFORMATIONS

  # Remove "{{fnlist}}" text (returns Redmine REST API)
  replace_code_regex 's/\{\{fnlist\}\}//g' $pagename 'textile'

  lastStepNumber=$stepsCounter
  stepsCounter=$((stepsCounter+1))

  # transformation from textile to markdown using Pandoc
  pandoc tmp/$pagename-$lastStepNumber.textile -o tmp/$pagename-$stepsCounter.md --from textile --to gfm --wrap=none

  # POST TRANSFORMATIONS

  # final markdown output
  cp tmp/$pagename-$stepsCounter.md output/$pagename.md
done