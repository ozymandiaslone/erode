#!/bin/bash

# Set environment variables for Linux build
export LUA_NO_PKG_CONFIG=1
export LUA_LIB="linux/liblua54.a"  # For static linking
export LUA_INC="linux/include"

# Build the project for Linux
cargo build --release
# Check if the build succeeded
if [ $? -eq 0 ]; then
    echo "Linux build completed!"
    
    # Run the game (change the path if necessary)
    ./target/release/erode
else
    echo "Build failed!"
fi
