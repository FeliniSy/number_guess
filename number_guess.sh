#!/bin/bash

# Connect to PostgreSQL (change DB name if needed)
PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Trim username if longer than 22 characters
USERNAME=${USERNAME:0:22}

# Check if user exists
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME';")

# New or returning user message
if [[ -z $USER_INFO ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME');" > /dev/null
else
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"

# Initialize guess and counter
GUESS=0
NUMBER_OF_GUESSES=0

# Start guessing loop
while [[ $GUESS -ne $SECRET_NUMBER ]]; do
  read GUESS_INPUT

  # Validate integer input
  if ! [[ $GUESS_INPUT =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  GUESS=$GUESS_INPUT
  (( NUMBER_OF_GUESSES++ ))

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  fi
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Update user stats
USER_STATS=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME';")
IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_STATS"

# Increment games played and update best game if needed
NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))

if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
  $PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME';" > /dev/null
else
  $PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username = '$USERNAME';" > /dev/null
fi
