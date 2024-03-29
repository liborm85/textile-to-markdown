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

  # Command <?php breaks pandoc transformation - escape it
  replace_code_regex 's/<\?php/<\\?php/g' $pagename 'textile'

  lastStepNumber=$stepsCounter
  stepsCounter=$((stepsCounter+1))

  # transformation from textile to markdown using Pandoc
  pandoc tmp/$pagename-$lastStepNumber.textile -o tmp/$pagename-$stepsCounter.md --from textile --to gfm --wrap=none

  # POST TRANSFORMATIONS

  # Command <?php breaks pandoc transformation - unescape it
  replace_code_regex 's/\\<\\\\php/<\?php/g' $pagename 'md'

  # Command <?php breaks pandoc transformation - unescape it in code statements
  replace_code_regex 's/<\\\?php/<\?php/g' $pagename 'md'

  # MediaWiki link transformation
  replace_code_regex 's/\\\[\\\[(.*)\\\|(.*)\\\]\\\]/[\2](\1)/g' $pagename 'md'

  # remove empty comments (end of list)
  replace_code_regex 's/<!-- -->//g' $pagename 'md'

  # remove multiple new lines
  replace_code '/^$/N;/^\n$/D' $pagename 'md'

  # final markdown output
  cp tmp/$pagename-$stepsCounter.md output/$pagename.md
done