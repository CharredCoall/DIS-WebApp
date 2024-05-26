from flask import Flask
from flask import jsonify
from flask import render_template
from flask import request
import psycopg2
import json

app = Flask(__name__)

def call_sql(sql,returns):
    conn = psycopg2.connect(database="pigeonhole", user="postgres", password="testPassword", host="127.0.0.1", port="5432")

    conn.autocommit = True

    cursor = conn.cursor()

    cursor.execute(sql)

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
    sql = '''SELECT * FROM pigeons WHERE id = {};'''.format(request_result["pigeon"])

    result = call_sql(sql,True)

    if len(result) == 0:
        return "Pigeon with id: {} Not Found".format(request_result["pigeon"]), 404

    return jsonify(result)

@app.after_request
def add_header_home(response):
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    return response


if __name__ == '__main__' :
    app.run(debug=True)