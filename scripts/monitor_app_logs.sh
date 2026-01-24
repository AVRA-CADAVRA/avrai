#!/bin/bash
# Monitor AVRAI app logs in real-time

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/avrai_app_logs.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AVRAI App Log Monitor${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Monitoring logs from: $LOG_FILE"
echo "Press Ctrl+C to stop"
echo ""

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Follow the log file
tail -f "$LOG_FILE" 2>/dev/null || {
    echo -e "${YELLOW}Waiting for app to start...${NC}"
    echo ""
    
    # Wait for log file to have content
    while [ ! -s "$LOG_FILE" ]; do
        sleep 1
    done
    
    tail -f "$LOG_FILE"
}
