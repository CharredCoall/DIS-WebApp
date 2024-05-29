from flask import Flask, jsonify, render_template, request, session
import psycopg2
import json

app = Flask(__name__)

app.secret_key = '''rG7Oj}{mKXfN5f*pF$1f<]WQ-tm8I*b0^L"FgZfshA$]cBD8B-gi.W-*0~H0!j;'''
app.config.update(
    SESSION_COOKIE_HTTPONLY=True
)

def call_sql(function, input,returns):
    conn = psycopg2.connect(database="pigeonhole", user="postgres", password="testPassword", host="127.0.0.1", port="5432")

    conn.autocommit = True

    cursor = conn.cursor()

    if not type(input) == list :
        input_string = input
    else:
        input_string = str(input.pop(0))
        for v in input :
            input_string += ", " + str(v)

    if (returns):
        cursor.execute("SELECT * FROM {}({});".format(function, input_string))
    else:
        print ("CALL {}({});".format(function, input_string))
        cursor.execute("CALL {}({});".format(function, input_string))

    if returns :
        result = cursor.fetchall()
        conn.close
        return result
    conn.close  

@app.route("/")
def show_test():
    
    return "Success"

@app.route("/game")
def show_game():
    return render_template("Game.html")

@app.route("/pigeon", methods=["GET","PUT","POST"])
def pigeon():
    match request.method:
        case "GET":
            if request.content_type == "application/json":
                request_result = request.get_json()
                if request_result == None or not "pigeon" in request_result:
                    return jsonify("Input needs dictionary with positive integer at 'pigeon'\n Instead got: {}".format(request_result)), 400
                if not type(request_result["pigeon"]) == int:
                    return jsonify("Input needs dictionary with positive integer at 'pigeon'\n Instead got: {} with type: {}".format(request_result,type(request_result["pigeon"]))), 400

                result = call_sql("get_pigeon_by_id",request_result["pigeon"],True)

                if len(result) > 1:
                    return jsonify("ServerError, Too many results"), 500

                if result[0][0] != request_result["pigeon"]:
                    if result[0][0] == None:
                        return jsonify("Pigeon with id: {} Not Found".format(request_result["pigeon"])), 404
                    return jsonify("ServerError, Incorrect Result" + str(result[0])), 500

                return jsonify(result[0])
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
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

                        return jsonify("Success")

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  



@app.route("/score", methods=["GET","PUT"])
def score():
    match request.method:
        case "GET":
            if request.content_type == "application/json":
                request_result = request.get_json()
            
                if request_result != None or "user" in request_result:
                    if type(request_result["user"]) == int:
                        result = call_sql("get_score_by_user",request_result["user"],True)
                        if result[0][0] == None :
                            return jsonify(None)
                        return jsonify(result)

            result = call_sql("get_all_scores", "", True)

            if result[0][0] == None:
                return jsonify(None)
            return jsonify(result)
        
        case "PUT":
            if request.content_type == "application/json":
                request_result = request.get_json()
        
                if request_result != None and "user" in request_result and "score" in request_result and "game" in request_result:
                    if type(request_result["user"]) == int and type(request_result["score"]) == int and type(request_result["game"]) == str:

                        call_sql("set_score",[request_result['user'], "'" + request_result['game'] + "'", request_result['score']], False)
                        return jsonify("Success")

                return jsonify("Input Error: {}".format(request_result)), 400    
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
            
@app.route("/buy_hat", methods=["PUT"])
def buy_hat():
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
    if request.content_type == "application/json":
        request_result = request.get_json()

        if request_result != None and "user" in request_result :
            if type(request_result["user"]) == int or type(request_result["user"]) == str:

                if type(request_result["user"]) == str:
                    request_result["user"] = "'" + request_result["user"] + "'"
                    
                userData = call_sql("get_user", request_result['user'], True)
                if userData == []:
                    return jsonify("User: {} Not Found".format(request_result["user"])), 404
                userData = userData[0]
                id = userData[0]
                pigeons = call_sql("get_pigeons_by_user", id, True)
                pigeonholes = call_sql("get_pigeonholes_by_user", id, True)

                return jsonify({"pigeons": pigeons, "pigeonholes": pigeonholes, "userData": userData})

        return jsonify("Input Error: {}".format(request_result)), 400  
    return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  

@app.route("/user", methods=["POST","GET"])
def user():
    match request.method:
        case "POST":
            if request.content_type == "application/json":
                request_result = request.get_json()

                if request_result != None and "username" in request_result and "pass" in request_result :
                    if type(request_result["username"]) == str and type(request_result["pass"]) == str:

                        call_sql("create_user",["'" + request_result['username'] + "'", "'" + request_result["pass"] + "'",], False)
                        return jsonify("Succes")

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400    
        case "GET":
            if 'user_id' in session:
                print(session['user_id'])
            if request.content_type == "application/json":
                request_result = request.get_json()

                if request_result != None and "username" in request_result and "pass" in request_result :
                    if type(request_result["username"]) == str and type(request_result["pass"]) == str:
                        if call_sql("confirm_pass",["'" + request_result['username'] + "'", "'" + request_result["pass"] + "'",], True)[0][0]:
                            session.clear()
                            session['user_id'] = call_sql("get_user","'" + request_result['username'] + "'",True)[0][0]
                            session.modified = True
                            return jsonify(True)
                        
                        return jsonify("Incorrect Password: {}".format(request_result)), 400

                return jsonify("Input Error: {}".format(request_result)), 400  
            return jsonify("Format Error \n Expected : json Got {}".format(request.content_type)), 400  
            
        


@app.after_request
def add_header_home(response):
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    return response


if __name__ == '__main__' :
    app.run(debug=True)