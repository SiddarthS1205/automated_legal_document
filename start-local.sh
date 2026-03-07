#!/bin/bash

# Start Local Development Script
# This script starts both the mock server and frontend

echo "🚀 Starting Legal Document Processing System (Local Mode)"
echo "=========================================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo ""

# Install dependencies if needed
if [ ! -d "mock-server/node_modules" ]; then
    echo "📦 Installing mock server dependencies..."
    cd mock-server
    npm install
    cd ..
    echo "✅ Mock server dependencies installed"
    echo ""
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend
    npm install
    cd ..
    echo "✅ Frontend dependencies installed"
    echo ""
fi

# Create .env.development if it doesn't exist
if [ ! -f "frontend/.env.development" ]; then
    echo "📝 Creating frontend .env.development..."
    echo "REACT_APP_API_ENDPOINT=http://localhost:3001" > frontend/.env.development
    echo "✅ Frontend environment configured"
    echo ""
fi

echo "=========================================="
echo "🎯 Starting servers..."
echo "=========================================="
echo ""
echo "📡 Mock Server will run on: http://localhost:3001"
echo "🌐 Frontend will run on: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping servers..."
    kill $MOCK_PID $FRONTEND_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start mock server in background
cd mock-server
npm start &
MOCK_PID=$!
cd ..

# Wait a bit for mock server to start
sleep 3

# Start frontend in background
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

# Wait for both processes
wait
