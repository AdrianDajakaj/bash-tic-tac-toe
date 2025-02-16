declare -A game_board
declare -i board_size=3

possible_moves=()
players_symbols=()
selected_save=""
game_mode=""
current_player=""
current_turn=""
winner=""
game_status=""

game_board_init(){
    is_win=false
    possible_moves=( "A1" "A2" "A3" "B1" "B2" "B3" "C1" "C2" "C3" )
    for i in {0..2}; do
        for j in {0..2}; do
            game_board["$i,$j"]="."
        done
    done
}

counts_init() {
    for symbol in "X" "O"; do
        for j in {0..2}; do
            row_count["$symbol,$j"]=0
            col_count["$symbol,$j"]=0
        done
        diag_count["$symbol"]=0
        anti_diag_count["$symbol"]=0
    done
}

game_board_print(){
    for i in {0..2}; do
        if [ $i -eq 0 ]; then
            echo
            echo "==  TIC TAC TOE  =="
            echo "==================="
            echo "| \ || A | B | C ||"
            echo "|===||===========||"
            echo "|---|+---+---+---+|"
        else
            echo "|---|+---+---+---+|"
        fi
        for j in {0..2}; do
            if [ $j -eq 0 ]; then
                echo -n "| "
                echo -n $((i+1))
                echo -n " || "
            fi
            echo -n ${game_board["$i,$j"]}
            if [ $j -eq 2  ]; then
                echo -n " || "
            else
                echo -n " | "
            fi
        done
        echo
        if [ $i -eq 2 ]; then
            echo "|---|+---+---+---+|"
            echo "==================="
            echo
        fi
    done
}

game_save() {
    local save_file=$(date +"%Y-%m-%d_%H-%M-%S").txt

    echo "Saving game to $save_file"
    echo "Game Mode: $game_mode" >> "$save_file" 
    echo "Current Player: $current_player" >> "$save_file"
    echo "Current Turn: $current_turn" >> "$save_file"
    echo "Player 1 Symbol: ${players_symbols[0]}" >> "$save_file"
    echo "Player 2 Symbol: ${players_symbols[1]}" >> "$save_file"
    echo "Current Board:">> "$save_file"

    for i in {0..2}; do
        for j in {0..2}; do
            echo -n "${game_board["$i,$j"]}" >> "$save_file"
        done
        echo >> "$save_file"
    done
    echo "Game saved!"
}

game_save_chooser(){
    local saves_list=()
    local file_number=1
    for file in *.txt; do
        saves_list[$((file_number-1))]="$file" 
        echo "$file_number. $(echo "$file" | sed 's/_/ /; s/-/:/g; s/.txt//')"
        ((file_number++))
    done
    local saves_count=${#saves_list[@]}
    while true; do
        echo "Select game save number (1 to $saves_count) or 'M' to return to the main menu:"
        read user_input
        if [[ "$user_input" =~ ^[0-9]+$ ]]; then
            if (( user_input >= 1 && user_input <= saves_count )); then
                selected_save="${saves_list[$((user_input-1))]}"
                formatted_save_name=$(echo "$selected_save" | sed 's/_/ /g; s/-/:/g; s/.txt//')
                echo "Selected save: $formatted_save_name"
                
                echo "What would you like to do?"
                echo "1. Load the game"
                echo "2. Remove the game save"
                echo "3. Return"
                read action_choice
                
                case $action_choice in
                    1)
                        game_save_load "$selected_save"
                        break
                        ;;
                    2)
                        game_save_remove "$selected_save"
                        game_save_chooser
                        ;;
                    3)
                        game_save_chooser
                        ;;
                    *)
                        echo "Invalid choice. Try again."
                        game_save_chooser
                        ;;
                esac
            else
                echo "The number must be between 1 and $saves_count! Try again."
            fi
        elif [[ "$user_input" == "M" || "$user_input" == "m" ]]; then
            echo "Returning to the main menu..."
            main_menu
            break
        else
            echo "Invalid input. Try again."
        fi
    done
}

game_save_load() {
    local save_file=$1
    if [[ ! -f "$save_file" ]]; then
        echo "Save game does not exist: $save_file"
        main_menu
    fi
    echo "Loading game..."

    while IFS= read -r line; do
        if [[ "$line" =~ ^Game\ Mode:\ (.+)$ ]]; then
            game_mode="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Current\ Player:\ (.+)$ ]]; then
            current_player="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Current\ Turn:\ (.+)$ ]]; then
            current_turn="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Player\ 1\ Symbol:\ (.+)$ ]]; then
            players_symbols[0]="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Player\ 2\ Symbol:\ (.+)$ ]]; then
            players_symbols[1]="${BASH_REMATCH[1]}"
        elif [[ "$line" == "Current Board:" ]]; then
            board_lines=()
        elif [[ -n "${board_lines[@]}" ]]; then
            board_lines+=("$line")
        fi
    done < "$save_file"
    local i=0
    for row in "${board_lines[@]}"; do
        local j=0
        for cell in $(echo "$row" | grep -o .); do
            game_board["$i,$j"]="$cell"
            ((j++))
        done
        ((i++))
    done
    if [[ "$game_mode" == "multiplayer" ]]; then
        echo "Multiplayer game loaded successfully!"
        game_status="running"
        multiplayer_game
    else
        echo "Singleplayer game loaded successfully!"
    fi
}

game_save_remove(){
    local save_file=$1
    if [[ -f "$save_file" ]]; then
        rm "$save_file"
        echo "Game save has been removed succesfully."
    else
        echo "Game save does not exist."
    fi
}

symbol_chooser(){
    local symbol
    while true; do
        echo "Player 1, choose your symbol (O or X):"
        read symbol
        if [[ "$symbol" == "O" || "$symbol" == "X" ]]; then
            players_symbols[0]=$symbol
            case $symbol in
                "X") 
                    players_symbols[1]="O"
                    ;;
                "O")
                    players_symbols[1]="X"
                    ;;
            esac
            break
        else
            echo "Invalid choice. Please choose either 'O' or 'X'."
        fi
    done
    if [[ "$game_mode" == "singleplayer" ]]; then
        echo "Player 1's symbol: ${players_symbols[0]}."
        echo "Computer's symbol: ${players_symbols[1]}."
    else
        echo "Player 1's symbol: ${players_symbols[0]}."
        echo "Player 2's symbol: ${players_symbols[1]}."
    fi
}

remove_used_move() {
    local search_element=$1
    local index_to_remove=-1
    for i in "${!possible_moves[@]}"; do
        if [[ "${possible_moves[$i]}" == "$search_element" ]]; then
            index_to_remove=$i
            break
        fi
    done
    if [[ $index_to_remove != -1 ]]; then
        unset "possible_moves[$index_to_remove]"
    fi
}

get_player_by_symbol(){
    local symbol=$1
    for i in "${!players_symbols[@]}"; do
        if [[ "${players_symbols[i]}" == "$symbol" ]]; then
            winner="$((i+1))"
        fi
    done
}

win_checker() {
    local player_symbol=$1
    for row in 0 1 2; do
        if [[ ${game_board["$row,0"]} == "$player_symbol" && ${game_board["$row,1"]} == "$player_symbol" && ${game_board["$row,2"]} == "$player_symbol" ]]; then
            return 0
        fi
    done
    for col in 0 1 2; do
        if [[ ${game_board["0,$col"]} == "$player_symbol" && ${game_board["1,$col"]} == "$player_symbol" && ${game_board["2,$col"]} == "$player_symbol" ]]; then
            return 0
        fi
    done
    if [[ ${game_board["0,0"]} == "$player_symbol" && ${game_board["1,1"]} == "$player_symbol" && ${game_board["2,2"]} == "$player_symbol" ]]; then
        return 0
    fi
    if [[ ${game_board["0,2"]} == "$player_symbol" && ${game_board["1,1"]} == "$player_symbol" && ${game_board["2,0"]} == "$player_symbol" ]]; then
        return 0
    fi
    return 1
}

is_board_completed(){
    for i in {0..2}; do
        for j in {0..2}; do
            if [[ ${game_board["$i,$j"]} == "." ]]; then
                return 1
            fi
        done
    done
    return 0
}

player_move() {
    local player=$1
    local move
    local row col
    while true; do
        echo "=== Turn: $current_turn ==="
        echo "Current Player: $current_player (Symbol: ${players_symbols[$((current_player-1))]})"
        game_board_print
        echo -n "Possible moves: "
        echo "${possible_moves[@]}"
        echo "Player $player, enter your move (or type 'S' to save the game, 'M' to return to main menu):"
        read move

        if [[ "$move" == "S" ]]; then
            game_save
            echo "Game saved successfully. Continuing..."
            continue
        fi

        if [[ "$move" == "M" ]]; then
            game_status="menu"
            break
        fi

        if [[ "$move" =~ ^[A-Ca-c][1-3]$ ]]; then
            col=$(echo "$move" | cut -c1 | tr 'A-C' '0-2')
            row=$(echo "$move" | cut -c2-2 | tr '1-3' '0-2')
            if [[ ${game_board[$row,$col]} == "." ]]; then
                game_board[$row,$col]=${players_symbols[$((player-1))]}
                remove_used_move "$move"

                if win_checker "${players_symbols[$((player-1))]}"; then
                    game_board_print
                    echo "Player $player (${players_symbols[$((player-1))]}) wins!"
                    game_status="win"
                    break
                else
                    if [[ ${#possible_moves[@]} -eq 0 ]]; then
                        game_board_print
                        echo "Draw! Nobody wins!"
                        game_status="draw"
                        break
                    fi
                fi
                break
            else
                echo "This position is already taken. Try again."
            fi
        else
            echo "Invalid input."
        fi
    done
}

minimax(){
    local depth=$1
    local is_maximizing=$2
    local a=10000
    local b=-10000
    local best_score
    local score
    if win_checker "${players_symbols[1]}"; then
        echo $a
        return
    elif win_checker "${players_symbols[0]}"; then
        echo $b
        return
    elif is_board_completed; then
        echo 0
        return
    fi

    if [[ $is_maximizing -eq 0 ]]; then
        best_score=-1000
        for i in {0..2}; do
            for j in {0..2}; do
                if [[ ${game_board["$i,$j"]} == "." ]]; then
                    game_board["$i,$j"]=${players_symbols[1]}
                    score=$(minimax $((depth+1)) 1)
                    game_board["$i,$j"]="."
                    if [[ $score -gt $best_score ]]; then
                        best_score=$score
                    fi
                fi
            done
        done
        echo $best_score
    else
        best_score=1000
        for i in {0..2}; do
            for j in {0..2}; do
                if [[ ${game_board["$i,$j"]} == "." ]]; then
                    game_board["$i,$j"]=${players_symbols[0]}
                    score=$(minimax $((depth+1)) 0)
                    game_board["$i,$j"]="."
                    if [[ $score -lt $best_score ]]; then
                        best_score=$score
                    fi
                fi
            done
        done
        echo $best_score
    fi
}

best_computer_move(){
    local best_score=-1000
    local move=(-1 -1)
    for row in {0..2}; do
        for col in {0..2}; do
            if [[ ${game_board["$row,$col"]} == "." ]]; then
                game_board["$row,$col"]=${players_symbols[1]}
                local score=$(minimax 0 1)
                echo "in progress..."
                game_board["$row,$col"]="."
                if [[ $score -ge $best_score ]]; then
                    best_score=$score
                    move[0]=$row
                    move[1]=$col
                fi
            fi
        done
    done  
    if ! [[ ${move[0]} -eq -1 && ${move[1]} -eq -1 ]]; then
        game_board[${move[0]},${move[1]}]=${players_symbols[1]}
        letters=(A B C)
        move_literal="${letters[${move[1]}]}$((${move[0]}+1))"
        remove_used_move "$move_literal"
        echo "Computer moves to $move_literal!"
        return 0
    fi
    return 1
}

computer_move() {
    local move
    local row col
    echo "=== Turn: $current_turn ==="
    echo "Current Player: Computer (Symbol: ${players_symbols[$((current_player-1))]})"
    echo "Computer thinking..."
    if ! best_computer_move; then
        possible_moves_copy=("${possible_moves[@]}") 
        random_index=$((RANDOM % ${#possible_moves_copy[@]}))
        move="${possible_moves_copy[$random_index]}"
        col=$(echo "$move" | cut -c1 | tr 'A-C' '0-2')
        row=$(echo "$move" | cut -c2-2 | tr '1-3' '0-2')
        echo "Computer moves to $move..."
        game_board[$row,$col]=${players_symbols[1]}
        remove_used_move "$move"
    fi
    if  win_checker "${players_symbols[1]}"; then
        game_board_print
        echo "Computer wins!"
        game_status="win"
    else
        if [[ ${#possible_moves[@]} -eq 0 ]]; then
            game_board_print
            echo "Draw! Nobody wins!"
            game_status="draw"
        fi
    fi  
}

main_menu(){
    echo "Main menu"
    echo "1. Single Player"
    echo "2. Multi Player"
    echo "3. Load Game"
    echo "4. Exit"

    read -p "Choose an option (1-4): " choice
    case $choice in
        1) 
            game_board_init
            # symbol_chooser
            current_turn=1
            current_player=1
            game_status="running"
            singleplayer_game 
            ;;
        2) 
            game_board_init
            # symbol_chooser
            current_turn=1
            current_player=1
            game_status="running"
            multiplayer_game    
            ;;
        3) game_save_chooser ;;
        4) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

singleplayer_game() {
    game_mode="singleplayer"
    symbol_chooser
    while [[ $game_status == "running" ]]; do
        if [[ $current_player -eq 1 ]]; then
            player_move "$current_player"
        else
            computer_move
        fi
        if [[ $game_status != "running" ]]; then
            break
        fi
        ((current_turn++))
        if [[ $current_player -eq 1 ]]; then
            current_player=2
        else
            current_player=1
        fi
    done
    echo "Returning to the main menu..."
    main_menu
}

multiplayer_game() {
    game_mode="multiplayer"
    symbol_chooser
    while [[ $game_status == "running" ]]; do
        player_move "$current_player"
        if [[ $game_status != "running" ]]; then
            break
        fi
        ((current_turn++))
        if [[ $current_player -eq 1 ]]; then
            current_player=2
        else
            current_player=1
        fi
    done
    echo "Returning to the main menu..."
    main_menu
}

main_menu








