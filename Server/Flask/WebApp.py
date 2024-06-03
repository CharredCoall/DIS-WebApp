from flask import Flask, jsonify, render_template, request, session
import psycopg2
import re
from sys import path
import os
path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),'..')))
from DBInit import _user, password, host, port

app = Flask(__name__)

app.secret_key = '''rG7Oj}{mKXfN5f*pF$1f<]WQ-tm8I*b0^L"FgZfshA$]cBD8B-gi.W-*0~H0!j;'''
app.config['CORS_HEADERS'] = 'Content-Type'
app.config.update(
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_SAMESITE='Lax'
)

login_security = True

def call_sql(function, input,returns):
    conn = psycopg2.connect(database="pigeonhole", user=_user, password=password, host=host, port=port)

    conn.autocommit = True

    cursor = conn.cursor()

    if not type(input) == list :
        if type(input) == str :
            input = "'" + re.sub(r"\"", r" %22% ", re.sub(r"'", r" %27% " , input)) + "'"
        input_string = str(input)
    else:
        first_input = input.pop(0)
        if type(first_input) == str :
            first_input = "'" + re.sub(r"\"", r" %22% ", re.sub(r"'", r" %27% ", str(first_input))) + "'"
        input_string = str(first_input)
        for v in input :
            if type(v) == str :
                v = "'" + re.sub(r"\"", r" %22% ", re.sub(r"'", r" %27% ", str(v))) + "'"
            input_string += ", " + str(v)

    if (returns):
        cursor.execute("SELECT * FROM {}({});".format(function, input_string))
    else:
        cursor.execute("CALL {}({});".format(function, input_string))

    if returns :
        result = cursor.fetchall()
        conn.close

        for t in result :
            for v in t:
                if type(v) == str :
                    v = re.sub(r" %22% ", r"\"", re.sub(r" %27% ", "'", str(v)))
                

        return result
    conn.close  

def auth_conn():
    if not login_security:
        return True
    
    if "user_id" in session :
        if call_sql("get_user", session["user_id"], True) != []:
            return True
    
    return False

@app.route("/")
def show_test():
    
    return "Success"

@app.route("/game")
def show_game():
    return render_template("Game.html")

@app.route("/pigeon", methods=["GET","PUT","POST"])
def pigeon():
    if not auth_conn():
        return jsonify("Not logged In"), 401
    match request.method:
        case "GET":
                request_result = request.args.get("pigeon")
                if request_result == None:
                    return jsonify("Input argument with positive integer at 'pigeon'\n Instead got: {}".format(request_result)), 400
                try :
                    request_result = int(request_result)
                except :
                    return jsonify("Input needs dictionary with positive integer at 'pigeon'\n Instead got: {}".format(request_result)), 400

                result = call_sql("get_pigeon_by_id",request_result,True)

                if len(result) > 1:
                    return jsonify("ServerError, Too many results"), 500

                if result[0][0] != request_result:
                    if result[0][0] == None:
                        return jsonify("Pigeon with id: {} Not Found".format(request_result)), 404
                    return jsonify("ServerError, Incorrect Result" + str(result[0])), 500

                return jsonify(result[0])
        case "PUT":
            if request.content_type == "application/json":
                request_result = request.get_json()
        
                if request_result != None and "pigeon" in request_result and "chance" in request_result and "constitution" in request_result:
                    if type(request_result["pigeon"]) == int and type(request_result["chance"]) == int and type(request_result["constitution"]) == int:

                        call_sql("update_pigeon",[request_result['pigeon'], request_result["chance"], request_result['constitution']], False)
                        return jsonify("Success")

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
        case "POST":
            if request.content_type == "application/json":
                request_result = request.get_json()
        
                if request_result != None and "user" in request_result and "pigeonhole":
                    if type(request_result["user"]) == int and type(request_result["pigeonhole"]) == int :
                        available = call_sql("pigeonhole_is_available",request_result["pigeonhole"], True)
                        if not available[0][0]:
                            return jsonify("Input Error, Pigeon already lives here, Or Hole does not exist: {}".format(request_result)), 400  
 
                        call_sql("create_pigeon",[request_result["user"], request_result["pigeonhole"]], False)

                        return jsonify(call_sql("get_pigeon_by_pigeonhole", request_result["pigeonhole"], True))

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  

@app.route("/score", methods=["GET","PUT"])
def score():
    match request.method:
        case "GET":
            user = request.args.get('user')
        
            if user != None :
                if type(user) == int:
                    result = call_sql("get_score_by_user",user,True)
                    if result[0][0] == None :
                        return jsonify(None)
                    return jsonify(result)

            result = call_sql("get_all_scores", "", True)

            if result[0][0] == None:
                return jsonify(None)
            return jsonify(result)
        
        case "PUT":
            
            if not auth_conn():
                return jsonify("Not logged In"), 401
            if request.content_type == "application/json":
                request_result = request.get_json()
        
                if request_result != None and "user" in request_result and "score" in request_result and "game" in request_result:
                    if type(request_result["user"]) == int and type(request_result["score"]) == int and type(request_result["game"]) == str:

                        call_sql("set_score",[request_result['user'],request_result['game'], request_result['score']], False)
                        return jsonify("Success")

                return jsonify("Input Error: {}".format(request_result)), 400    
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
            
@app.route("/buy_hat", methods=["PUT"])
def buy_hat():
    if not auth_conn():
        return jsonify("Not logged In"), 401
    if request.content_type == "application/json":
        request_result = request.get_json()

        if request_result != None and "user" in request_result and "hat" in request_result :
            if type(request_result["user"]) == int and type(request_result["hat"]) == int:

                call_sql("buy_hat",[request_result['user'], request_result["hat"],], False)
                return jsonify("Success")

        return jsonify("Input Error: {}".format(request_result)), 400  
    return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400    

@app.route("/equip_hat", methods=["PUT"])
def equip_hat():
    if not auth_conn():
        return jsonify("Not logged In"), 401
    if request.content_type == "application/json":
        request_result = request.get_json()

        if request_result != None and "pigeon" in request_result and "hat" in request_result :
            if type(request_result["pigeon"]) == int and type(request_result["hat"]) == int:

                call_sql("equip_hat",[request_result['pigeon'], request_result["hat"],], False)
                return jsonify("Success")

        return jsonify("Input Error: {}".format(request_result)), 400  
    return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400    

@app.route("/load_game", methods=["GET"])
def load_game():
    if not auth_conn():
        return jsonify("Not logged In"), 401
    
    request_result = request.args.get("user")

    if request_result != None :
        if type(request_result) == int or type(request_result) == str:
                
            userData = call_sql("get_user", request_result, True)
            if userData == []:
                return jsonify("User: {} Not Found".format(request_result)), 404
            userData = userData[0]
            if not request_result in userData:
                return jsonify("Input Error, Not logged in as this user: {} ".format(request_result)), 400
            id = userData[0]
            pigeons = call_sql("get_pigeons_by_user", id, True)
            pigeonholes = call_sql("get_pigeonholes_by_user", id, True)
            hats = call_sql("get_hats_by_user", id, True)

            return jsonify({"pigeons": pigeons, "pigeonholes": pigeonholes, "userData": userData, "hats": hats})

    return jsonify("Input Error: {}".format(request_result)), 400  

@app.route("/user", methods=["POST","PUT"])
def user():
    match request.method:
        case "POST":
            if request.content_type == "application/json":
                request_result = request.get_json()

                if request_result != None and "username" in request_result and "pass" in request_result :
                    if type(request_result["username"]) == str and type(request_result["pass"]) == str:
                        if call_sql("get_user", request_result['username'],True) != []:
                            return jsonify("User already exists: {}".format(request_result)), 400
                        call_sql("create_user",[request_result['username'], request_result["pass"],], False)
                        session.clear()
                        session['user_id'] = call_sql("get_user", request_result['username'],True)[0][0]
                        session.modified = True

                        return jsonify("Succes")

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400    
        case "PUT":
            if request.content_type == "application/json":
                request_result = request.get_json()

                if request_result != None and "username" in request_result and "pass" in request_result :
                    if type(request_result["username"]) == str and type(request_result["pass"]) == str:
                        if call_sql("confirm_pass",[request_result['username'],request_result["pass"],], True)[0][0]:
                            session.clear()
                            session['user_id'] = call_sql("get_user", request_result['username'],True)[0][0]
                            session.modified = True
                            return jsonify(True), 200, {'Authorization': 'Basic user:' + str(session['user_id'])}
                        
                        return jsonify("Incorrect Password: {}".format(request_result)), 400

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
            
        


@app.after_request
def add_header_home(response):
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    response.headers['Access-Control-Allow-Origin'] = 'http://localhost:5000'
    response.headers['Access-Control-Allow-Methods'] = "GET, PUT, POST"
    response.headers['Access-Control-Allow-Headers'] = "Content-type"
    response.headers['Access-Control-Allow-Credentials'] = "true"
    return response


if __name__ == '__main__' :
    app.run(debug=True)