from flask import Flask
from flask import jsonify
from flask import render_template
from flask import request
import psycopg2
import json

app = Flask(__name__)

def call_sql(function, input,returns):
    conn = psycopg2.connect(database="pigeonhole", user="postgres", password="testPassword", host="127.0.0.1", port="5432")

    conn.autocommit = True

    cursor = conn.cursor()

    if not type(input) == list :
        input_string = input
    else:
        input_string = input.pop(0)
        for v in input :
            input_string += ", " + v

    if (returns):
        cursor.execute("SELECT * FROM {}({});".format(function, input_string))
    else:
        cursor.execute("{}({});".format(function, input_string))

    if returns :
        result = cursor.fetchall()
    conn.close  

    if returns :
        return result

@app.route("/")
def show_test():
    
    return "Success"

@app.route("/game")
def show_game():
    return render_template("Game.html")

@app.route("/pigeon", methods=["GET"])
def pigeon():
    request_result = request.get_json()
    if request_result == None or not "pigeon" in request_result:
        return "Input needs dictionary with positive integer at 'pigeon'\n Instead got: {}".format(request_result), 400
    if not type(request_result["pigeon"]) == int:
        return "Input needs dictionary with positive integer at 'pigeon'\n Instead got: {} with type: {}".format(request_result,type(request_result["pigeon"])), 400

    result = call_sql("get_pigeon_by_id",request_result["pigeon"],True)

    if len(result) > 1:
        return "ServerError, Too many results", 500

    if result[0][0] != request_result["pigeon"]:
        if result[0][0] == None:
            return "Pigeon with id: {} Not Found".format(request_result["pigeon"]), 404
        return "ServerError, Incorrect Result" + str(result[0]), 500

    return jsonify(result)

@app.after_request
def add_header_home(response):
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    return response


if __name__ == '__main__' :
    app.run(debug=True)