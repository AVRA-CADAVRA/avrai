#!/bin/bash
# Run app with log monitoring in separate terminal

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AVRAI Manual Testing with Log Monitoring${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Starting app with log monitoring..."
echo ""
echo -e "${YELLOW}The app is launching in the background.${NC}"
echo -e "${YELLOW}Logs are being written to: /tmp/avrai_app_logs.txt${NC}"
echo ""
echo "To view logs in real-time, run in another terminal:"
echo -e "${GREEN}  tail -f /tmp/avrai_app_logs.txt${NC}"
echo ""
echo "Or use the monitor script:"
echo -e "${GREEN}  ./scripts/monitor_app_logs.sh${NC}"
echo ""
echo -e "${BLUE}Testing Checklist:${NC}"
echo "  📋 See: docs/macos_llm_integration/MANUAL_TESTING_CHECKLIST.md"
echo ""
echo "The app should open shortly. Start testing when ready!"
echo ""
