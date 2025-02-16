# Tic Tac Toe in Bash

A classic Tic Tac Toe game implemented in Bash script with singleplayer vs AI and multiplayer modes.

## Features

- 🎮 Two game modes: Singleplayer vs AI (using Minimax algorithm) and Multiplayer
- 💾 Save/Load game functionality
- 🖥️ ASCII-based interactive interface
- 🔍 Input validation and error handling
- 📅 Automatic save file naming with timestamps

## Installation & Running

1. Clone the repository:
    ```bash
    git clone https://github.com/AdrianDajakaj/bash-tic-tac-toe.git

2. Make the script executable:
    ```bash
    chmod +x tic-tac-toe-game.sh

3. Run the game:
    ```bash
    ./tic-tac-toe-game.sh

## Game Modes
### Singleplayer
Play against an AI that uses the Minimax algorithm for optimal moves.

### Multiplayer
Play with a friend on the same machine.

## Key Functions Documentation
### Core Functions
- game_board_init() - Initializes empty 3x3 board and possible moves list

- game_board_print() - Displays the current game board with ASCII art

- win_checker() - Checks for winning combinations

- is_board_completed() - Checks for draw condition

### Game Logic
- player_move() - Handles human player input and move validation

- best_computer_move() - AI logic using Minimax algorithm

- minimax() - Recursive Minimax implementation for optimal AI decisions

### Save System
- game_save() - Saves current game state to timestamped file

- game_save_load() - Loads game from selected save file

- game_save_chooser() - Interactive save file selector

### Utilities
- symbol_chooser() - Handles player symbol selection (X/O)

- remove_used_move() - Updates available moves list

- main_menu() - Handles main menu navigation

## Save System Details
Saved games are stored as .txt files with timestamp names. Each save contains:

- Game mode

- Current player/turn

- Player symbols

- Board state

Use 'S' during gameplay to save.

## AI Implementation
The singleplayer AI uses:

- Minimax algorithm for optimal decision making

- Recursive score calculation

- Depth-limited search (due to Bash limitations)

- Fallback to random moves if Minimax fails

## Game Controls
During gameplay:

- Enter moves in format A1, A2, etc.

- S - Save game

- M - Return to main menu

## Requirements
- Bash 4.0+ (for associative arrays support)

- Linux/macOS environment

## Contributing
Contributions welcome! Please follow standard Bash scripting best practices and maintain compatibility with POSIX standards.