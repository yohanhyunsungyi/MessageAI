#!/bin/bash

###############################################################################
# MessageAI Notification Deployment Script
# Deploys Cloud Functions for push notifications
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_ID="messagingai-75f21"
FUNCTIONS_DIR="backend/functions"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     MessageAI Notification Deployment Script           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo -e "${YELLOW}Install it with: npm install -g firebase-tools${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Firebase CLI found"

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Firebase${NC}"
    echo -e "${BLUE}Logging in...${NC}"
    firebase login
fi

echo -e "${GREEN}✓${NC} Logged in to Firebase"

# Set project
echo -e "${BLUE}Setting Firebase project: ${PROJECT_ID}${NC}"
firebase use $PROJECT_ID

# Navigate to functions directory
if [ ! -d "$FUNCTIONS_DIR" ]; then
    echo -e "${RED}❌ Functions directory not found: $FUNCTIONS_DIR${NC}"
    exit 1
fi

cd $FUNCTIONS_DIR
echo -e "${GREEN}✓${NC} Functions directory found"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found${NC}"
    exit 1
fi

# Install dependencies
echo ""
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install

echo -e "${GREEN}✓${NC} Dependencies installed"

# Go back to root
cd ../..

# Deploy functions
echo ""
echo -e "${BLUE}🚀 Deploying Cloud Functions...${NC}"
echo ""

firebase deploy --only functions

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             ✨ Deployment Successful! ✨                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Test notifications with two devices"
    echo -e "  2. Monitor logs: ${BLUE}firebase functions:log${NC}"
    echo -e "  3. View metrics in Firebase Console"
    echo ""
    echo -e "${YELLOW}Deployed functions:${NC}"
    firebase functions:list
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ❌ Deployment Failed! ❌                    ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check Firebase CLI login: firebase login"
    echo -e "  2. Verify project access: firebase projects:list"
    echo -e "  3. Check billing enabled (Blaze plan required)"
    echo -e "  4. View errors above"
    exit 1
fi

