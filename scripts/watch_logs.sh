#!/bin/bash
# Watch AVRAI app logs in real-time with filtering

LOG_FILE="/tmp/avrai_app_logs.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AVRAI Log Monitor (Real-Time)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Monitoring: $LOG_FILE"
echo "Press Ctrl+C to stop"
echo ""
echo -e "${YELLOW}Filtering for: LLM, Maps, Model, BERT, Errors${NC}"
echo ""

# Wait for log file
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}Waiting for app to start...${NC}"
    while [ ! -f "$LOG_FILE" ]; do
        sleep 1
    done
fi

# Follow logs with highlighting
tail -f "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
    # Highlight important patterns
    if echo "$line" | grep -qiE "(error|exception|failed|❌)"; then
        echo -e "${RED}$line${NC}"
    elif echo "$line" | grep -qiE "(model|llm|bert|llama|coreml)"; then
        echo -e "${CYAN}$line${NC}"
    elif echo "$line" | grep -qiE "(map|marker|boundary|geohash)"; then
        echo -e "${GREEN}$line${NC}"
    elif echo "$line" | grep -qiE "(✅|success|loaded|activated)"; then
        echo -e "${GREEN}$line${NC}"
    elif echo "$line" | grep -qiE "(⚠️|warning)"; then
        echo -e "${YELLOW}$line${NC}"
    else
        echo "$line"
    fi
done
