declare -A game_board row_count col_count diag_count anti_diag_count
declare -i board_size=3

possible_moves=()
players_symbols=()
selected_save=""
current_player=""
current_turn=""
winner=""
is_win=false

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
    echo "Current Player: $current_player" >> "$save_file"
    echo "Current Turn: $current_turn" >> "$save_file"
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
        echo "Select game save number (1 to $saves_count):"
        read user_input
        if [[ "$user_input" =~ ^[0-9]+$ ]]; then
            if (( user_input >= 1 && user_input <= saves_count )); then
                selected_save="${saves_list[$((user_input-1))]}"
                formatted_save_name=$(echo "$selected_save" | sed 's/_/ /g; s/-/:/g; s/.txt//')
                echo "Selected save: $formatted_save_name"
                break  
            else
                echo "The number must be between 1 and $saves_count! Try again."
            fi
        else
            echo "It's not a number! Try again."
        fi
    done
}

game_save_load() {
    local save_file=$1
    if [[ ! -f "$save_file" ]]; then
        echo "Save game does not exist: $save_file"
        return 1
    fi
    echo "Loading game..."

    while IFS= read -r line; do
        if [[ "$line" =~ ^Current\ Player:\ (.+)$ ]]; then
            current_player="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Current\ Turn:\ (.+)$ ]]; then
            current_turn="${BASH_REMATCH[1]}"
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
    echo "Game loaded successfully!"
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
    echo "Player 1's symbol: ${players_symbols[0]}."
    echo "Player 2's symbol: ${players_symbols[1]}."
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
    local row=$1
    local col=$2
    local player_symbol=$3
    (( row_count["$player_symbol,$row"]++ ))
    (( col_count["$player_symbol,$col"]++ ))
    if (( row == col )); then
        (( diag_count["$player_symbol"]++ ))
    fi
    if (( row + col == board_size - 1 )); then
        (( anti_diag_count["$player_symbol"]++ ))
    fi
     echo ${diag_count["$player_symbol,$row"]}
    if (( row_count["$player_symbol,$row"] == board_size || col_count["$player_symbol,$col"] == board_size || diag_count["$player_symbol"] == board_size || anti_diag_count["$player_symbol"] == board_size )); then
        is_win=true
    else
        is_win=false
    fi
}


player_move() {
    local player=$1
    local move
    local row col
    while true; do
        echo -n "Possible moves: "
        echo "${possible_moves[@]}"
        echo "Player $player, enter your move:"
        read move
        if [[ "$move" =~ ^[A-Ca-c][1-3]$ ]]; then
            col=$(echo "$move" | cut -c1 | tr 'A-C' '0-2')
            row=$(echo "$move" | cut -c2-2 | tr '1-3' '0-2')
            if [[ ${game_board[$row,$col]} == "." ]]; then
                game_board[$row,$col]=${players_symbols[$((player-1))]}
                remove_used_move "$move"
                win_checker "$row" "$col" "${players_symbols[$((player-1))]}"
                game_board_print
                if [[ $is_win == true ]]; then
                    echo "Player $player (${players_symbols[$((player-1))]}) wins!"
                    # exit 0
                fi
                if [[ $is_win == false && ${#possible_moves[@]} -eq 0 ]]; then
                    echo Draw! Nobody wins!
                    # exit 0 
                fi
                break
            else
                echo "This position is already taken. Try again."
            fi
        else
            echo "Invalid input. Please enter a valid move from list."
        fi
    done
}





game_board_init

symbol_chooser

player_move "1"

player_move "2"

player_move "1"

player_move "2"

player_move "1"

player_move "2"
player_move "1"
player_move "2"
player_move "1"
player_move "2"
player_move "1"

# symbol_chooser
# game_board_checker
# get_player_by_symbol "X"
# echo $current_player

