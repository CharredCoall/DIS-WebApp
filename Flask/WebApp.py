from flask import Flask
from flask import jsonify
from flask import render_template
import psycopg2


app = Flask(__name__)

@app.route("/")
def show_test():
    
    return "Success"

@app.route("/game")
def show_game():
    return render_template("Game.html");


@app.after_request
def add_header_home(response):
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    return response


if __name__ == '__main__' :
    app.run(debug=True)