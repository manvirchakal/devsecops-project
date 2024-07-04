#!/bin/bash

# Nessus API credentials and URL
NESSUS_URL="https://10.0.2.15:8834"
USERNAME="manvirchakal"
PASSWORD="M@nvir123"
SCAN_ID="6"  # Replace with your actual scan ID

# Function to obtain API token
get_api_token() {
  curl -k -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" "$NESSUS_URL/session" | jq -r .token
}

# Function to check if a scan is running
is_scan_running() {
  scan_id=$1
  status=$(curl -k -X GET -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" "$NESSUS_URL/scans/$scan_id" | jq -r .info.status)
  if [[ "$status" == "running" ]]; then
    return 0
  else
    return 1
  fi
}

# Function to wait for the scan to complete
wait_for_scan_to_complete() {
  scan_id=$1
  while is_scan_running $scan_id; do
    echo "Scan $scan_id is still running..."
    sleep 60
  done
  echo "Scan $scan_id is complete."
}

# Get API token
TOKEN=$(get_api_token)

if [ -z "$TOKEN" ]; then
  echo "Failed to obtain API token."
  exit 1
fi

# Start the scan
echo "Starting Nessus scan with ID $SCAN_ID..."
curl -k -X POST -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" "$NESSUS_URL/scans/$SCAN_ID/launch"

# Wait for the scan to complete
wait_for_scan_to_complete $SCAN_ID

# Export the scan report
REPORT_PATH="/tmp/scan_report.nessus"
REPORT_ID=$(curl -k -X POST -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" -d "{\"format\":\"nessus\"}" "$NESSUS_URL/scans/$SCAN_ID/export" | jq -r .file)
echo "Exporting the scan report to $REPORT_PATH..."

# Wait for the export to be ready
while true; do
  EXPORT_STATUS=$(curl -k -X GET -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" "$NESSUS_URL/scans/$SCAN_ID/export/$REPORT_ID/status" | jq -r .status)
  if [ "$EXPORT_STATUS" == "ready" ]; then
    echo "Report is ready for download."
    break
  else
    echo "Report is being generated..."
    sleep 30
  fi
done

# Download the report
curl -k -X GET -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" "$NESSUS_URL/scans/$SCAN_ID/export/$REPORT_ID/download" -o $REPORT_PATH
echo "Scan report saved to $REPORT_PATH"

# Copy the report from the container to the host
docker cp nessus:$REPORT_PATH ./scan_report.nessus
echo "Scan report saved to ./scan_report.nessus"

# Clean up the session
curl -k -X DELETE -H "X-Cookie: token=$TOKEN" "$NESSUS_URL/session"

