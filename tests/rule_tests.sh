#!/bin/bash

# We deliberately don't use `set -e` because we capture and process the errors manually.

####################################################
# Linting stage
####################################################

echo 
echo "Validating and linting Sigma syntax..."

# Disable colourised outputs because it makes things messy
# when the terminal doesn't support colours.
LINT_OUTPUT=$(NO_COLOR=1 rsigma rule lint ./rules/ --output-format json)

# Check if the output is valid JSON data containing findings
if echo "$LINT_OUTPUT" | jq -e '.findings' >/dev/null 2>&1; then
    
    # Extract only the errors using jq
    ERRORS=$(echo "$LINT_OUTPUT" | jq -r '
      .findings[]? 
      | select(.severity == "error")

      | "* [\(.rule)] in \(.path):\(.line) -> \(.message)"
    ')

    # If the error string is non-empty, print them and exit 1
    if [ -n "$ERRORS" ]; then
      echo
      echo "VALIDATION ERROR(S):"
      echo "$ERRORS"
      exit 1
    fi

else
    # Fallback: If rsigma output is a raw string (fatal syntax error), 
    # it won't have a JSON structure. Print the raw error text and fail.
    if [ -n "$LINT_OUTPUT" ]; then
        echo "FATAL ERROR:"
        echo "$LINT_OUTPUT"
        exit 1
    fi
fi

echo "Linting completed."

####################################################
# Rule unit tests
####################################################

echo
echo "Running logic validation..."

# Create a clean file to store all individual JSON results
REPORT_FILE="test_suite_results.json"
echo "[]" > "$REPORT_FILE"

find ./tests -type f -name "*.expect.yaml" | while read -r expectation_file; do
  # Extract the folder containing this expectations file
  test_dir=$(dirname "$expectation_file")
  
  # Run rsigma using the exact paths for this specific test case
  rsigma rule backtest \
    --rules ./rules/ \
    --corpus "${test_dir}/" \
    --expectations "$expectation_file" \
    --output-format json > temp_res.json 2>/dev/null 
  
  # Merge this test's expectations array into the master report file
  if [ -s temp_res.json ]; then
    jq --slurpfile new temp_res.json '. + $new[0].expectations' "$REPORT_FILE" > temp_combined.json
    mv temp_combined.json "$REPORT_FILE"
  fi

done

rm -f temp_res.json

# Print the final X/Y passed block
jq -r '
  length as $total 
  | map(select(.pass == true)) | length as $pass
  | "Result: \($pass)/\($total) expectations passed (\($total - $pass) failed)."
' "$REPORT_FILE"

# If failures exist, print just the failed tests and exit with error code.
if jq -e 'map(select(.pass == false)) | length > 0' "$REPORT_FILE" >/dev/null; then
  echo 
  echo "FAILED TESTS:"
  jq -r '
    .[] 
    | select(.pass == false) 
    | "  • Rule [\(.rule)] -> Expected \(.bound), but fired \(.actual) times."
  ' "$REPORT_FILE"
  exit 1
fi

exit 0
