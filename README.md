# Pigeonhole Principle
The Pigeonhole Principle is a web-app game. The main game is developed in the Godot Engine, and using http requests, communicating with flask we are able to run this as a web-app.
The game has a few flaws and unintentional gameplay features/bugs, but these are described below in the Gameplay Description section.
The database for our game is a way to keep track of all the data and potentially play and compete with other people.

## Requirements
Run the code below to install the necessary modules.

    pip install -r requirements.txt

## Database initialization
 - Have a existing postgres database.
 - In the DBInit.py file, set database to your postgres database name, set _user to an admin database user, set password to the password of that user, set host to the ip your database is on (if using localhost, leave it as 127.0.0.1), set port to what port your database is on (standard port is 5432).
 - Run the file Setup.py
 - Run the file DummyData.py

## Running Flask
 - Run the file WebApp.py

### To run the Web-App
 - Open your browser on Localhost:5000
 - Play the game!

## Regex Usage
 - WebApp.py, in the call_sql function, to substitute " and ' for the codes %22% and %27%, to protect the server from any sql injection attacks.
 - In our gd scripts, the function _on_request_completed, used in different scripts to get headers.
 - In showscores.gd, used to change the format of dates from how it looks in the server to how we want it to look.

## Stored Procedures and Functions
All SQL calls are made with either stored procedures or functions.
The stored procedures and function are in the database.

## Gameplay Description
The Pigeonhole Principle is a game about owning and improving pigeons to get better scores in the two minigames.
This is done by playing the minigames and improving the individual pigeon's stats - constitution and chance.

### Login Screen
When you enter the web-app there is a play button, this makes you be able to enter a username and a password, there are two buttons, one to create a new account and one to log back in to an existing account, you have the option of having the game "remember me" using cookies. 

### Main Menu
The main menu is the game hub, where you can go into the shop, see highscores, customize pigeons and enter the games with a specific pigeon.
In the bottom left is a button for the highscore menu, this keeps track of all accounts and their scores in both games, you can use the switch button to look at both games' highscores.
In the bottom right is a button for the shop menu, where you can spend money to buy cosmetics or hats for your pigeons, these have no gameplay benefits, but look great on your pigeons.
After waiting for a bit in the main menu there will slowly begin to fly in some pigeons, you can have up to three and once you have three birds occasionally fly across the screen never landing in a "pigeonhole".
After a pigeon has settled in a pigeonhole you can click on them, once clicked on the camera will zoom in on the specific pigeon. Now you can equip hats that you have bought and look at the pigeon's stats.
There is also a play button this will give one of two options "Shooter" and "Clicker", clicking on one of the buttons will start that particular minigame.

### Minigames
In our minigames, we won't tell how to get an optimal score on each of the games, but you will have to get optimal stats on the pigeons you play with, our game isn't designed so that you get better results purely by having better stats, but a combination of low and high stats might go a long way.

#### Shooter Minigame
For this minigame, you use the left and right arrowkeys to move your pigeon as well as the spacebar to shoot.
Your goal is to hit the clothes being thrown by the lady on the right, getting 100 points for each one hit.
You have 30 seconds to hit as many as possible.
Once done you will recieve your score, level-up and the amount of money you have earned. Then you can head back to the main menu, where the score, stats and money should be updated.

#### Clicker Minigame
For this minigame, you use the "q", "w" and "e" buttons to play, there will be text telling you what buttons to press. 
Pressing the right button causes your pigeon to take a bite out of the piece of food on the ground.
There will be displayed how much "health" the piece of food has left, once depleted to 0% you will get points for eating the food, then a new piece of food will spawn.
You get 60 seconds to get as many points as possible. 
Once the time runs out, like the other game you will recieve your score, level-up and the amount of money you have earned, as well as a button back to the main menu, where everything should be updated.

## Assets for our game
We have used a bunch of artwork, music, sound effects to make our game feel more alive.
We have made all the assets ourselved, except the music, which is copyright free music.
All the sprites are digitally drawn, the sound effects we have recorded ourselves.

### Links for the music we used
 - Login Screen Music: https://www.youtube.com/watch?v=oOPRvxV3n0k&ab_channel=TomatoTune
 - Main Menu Music: https://www.youtube.com/watch?v=IC5ps3qgSFs&ab_channel=bdProductions%7CMusicForVideos
 - Clicker Game Music: https://pixabay.com/music/synthwave-lady-of-the-80x27s-128379/
 - Shooter Game Music: https://pixabay.com/music/scary-childrens-tunes-creepy-devil-dance-166764/
 - 3,2,1,Go! Sound effect: https://pixabay.com/sound-effects/321-go-8-bit-video-game-sound-version-1-145007/
 - Victory Sound effetc: https://pixabay.com/sound-effects/goodresult-82807/

