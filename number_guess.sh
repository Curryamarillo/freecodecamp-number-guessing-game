#!/bin/bash

# Function to guess the number
GUESS_NUMBER() {
    local RANDOM_NUMBER=$1
    local USER_ID=$2
    local ATTEMPTS=0
    local GUESS
    echo -e "Guess the secret number between 1 and 1000:"
    while true; do
        ((ATTEMPTS++))
        
        read GUESS

        # Check if input is an integer
        if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
            echo "That is not an integer, guess again:"
            continue
        fi

        if [[ $GUESS -eq $RANDOM_NUMBER ]]; then
            echo "You guessed it in $ATTEMPTS tries. The secret number was $RANDOM_NUMBER. Nice job!"

            # Database connection
            PSQL="psql -U freecodecamp -d number_game -t -c"

            # Insert game data into games table
            $PSQL "INSERT INTO games(number, user_id, number_guesses) VALUES ($RANDOM_NUMBER, $USER_ID, $ATTEMPTS);" > /dev/null

            break
        elif [[ $GUESS -lt $RANDOM_NUMBER ]]; then
            echo "It's higher than that, guess again:"
        else
            echo "It's lower than that, guess again:"
        fi
    done
}

# Function to check and greet user
MAIN_MENU() {
    echo -e "Enter your username:"
    read USERNAME

    # Check username length
    if [ ${#USERNAME} -gt 22 ]; then
        echo "Username can have maximum 22 characters."
        exit 1
    fi

    # Database connection
    PSQL="psql -U freecodecamp -d number_game -t --no-align -c"

    # User Input
    USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';" | tr -d '[:space:]'))

    # User Check
    if [[ -z $USER_ID ]]; then
        echo -e "Welcome, $USERNAME! It looks like this is your first time here."
        USER_ID_INSERT=$(echo $($PSQL "INSERT INTO users(username) VALUES('$USERNAME') RETURNING user_id;" | tr -d '[:space:]'))
        USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';" | tr -d '[:space:]'))
    else
        GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID;" | tr -d '[:space:]')
        BEST_GAME=$($PSQL "SELECT COALESCE(MIN(number_guesses), 0) FROM games WHERE user_id=$USER_ID;" | tr -d '[:space:]')
        echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi

    RANDOM_NUMBER=$(shuf -i 1-1000 -n 1)
    GUESS_NUMBER $RANDOM_NUMBER $USER_ID
}

# Main function call
MAIN_MENU

