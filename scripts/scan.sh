#!/bin/bash

# Replace these with your actual Nessus credentials and scan ID
NESSUS_URL="https://<your-vm-ip>:8834"
NESSUS_USERNAME="your_nessus_username"
NESSUS_PASSWORD="your_nessus_password"
SCAN_ID="your_scan_id"

# Login to Nessus and get a session token
TOKEN=$(curl -k -X POST -H "Content-Type: application/json" -d '{"username":"'"$NESSUS_USERNAME"'","password":"'"$NESSUS_PASSWORD"'"}' "$NESSUS_URL/session" | jq -r .token)

# Start the scan
curl -k -X POST -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" "$NESSUS_URL/scans/$SCAN_ID/launch"

# Wait for the scan to complete (this is a simplistic approach; you might want to implement a loop to check the scan status)
echo "Waiting for the scan to complete..."
sleep 600

# Export the scan results
SCAN_EXPORT_ID=$(curl -k -X POST -H "X-Cookie: token=$TOKEN" -H "Content-Type: application/json" -d '{"format":"pdf"}' "$NESSUS_URL/scans/$SCAN_ID/export" | jq -r .file)
sleep 10
curl -k -X GET -H "X-Cookie: token=$TOKEN" "$NESSUS_URL/scans/$SCAN_ID/export/$SCAN_EXPORT_ID/download" --output report.pdf

# Cleanup: logout from Nessus
curl -k -X DELETE -H "X-Cookie: token=$TOKEN" "$NESSUS_URL/session"

echo "Scan complete. Report saved as report.pdf"

