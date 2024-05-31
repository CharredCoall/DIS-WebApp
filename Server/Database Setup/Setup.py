import psycopg2
from sys import path
import os
path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),'..')))
from DBInit import database, _user, password, host, port

if __name__ == "__main__":

    conn = psycopg2.connect(database=database, user=_user, password=password, host=host, port=port)

    conn.autocommit = True

    cursor = conn.cursor()

    sql = '''
        CREATE DATABASE pigeonhole;
    '''

    try :
        cursor.execute(sql)
    except: 
        pass

    conn.close 

    database = 'pigeonhole'

    conn = psycopg2.connect(database="pigeonhole", user=_user, password=password, host=host, port=port)
    conn.autocommit = True
    cursor = conn.cursor()

    sql = ''' 

        DROP SCHEMA IF EXISTS public CASCADE;
        

        CREATE SCHEMA public;

        
        CREATE EXTENSION pgcrypto;

        
        CREATE TYPE game AS ENUM ('clicker', 'shooter','fbi');

        
        CREATE TABLE players(
            id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
            username text UNIQUE NOT NULL,
            password text NOT NULL,
            money integer CHECK (money >= 0) 
        );

        
        CREATE TABLE pigeonholes(
            id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
            player_id integer REFERENCES players(id) ON DELETE CASCADE,
            position integer,
            UNIQUE (player_id, position)
        );

        
        CREATE TABLE pigeons(
            id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
            owner_id integer REFERENCES players(id) ON DELETE CASCADE,
            pigeonhole_id integer UNIQUE REFERENCES pigeonholes(id) ON DELETE CASCADE,
            chance integer,
            intelligence integer,
            constitution integer
        );

        
        CREATE TABLE hats(
            id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
            price double precision CHECK (price > 0),
            img_name text
        );

        
        CREATE TABLE highscore(
            user_id integer REFERENCES players(id) ON DELETE CASCADE,
            game game,
            score integer,
            score_time timestamp,
            PRIMARY KEY (user_id, game) 
        );

        
        CREATE TABLE wears(
            pigeon integer REFERENCES pigeons(id) ON DELETE CASCADE PRIMARY KEY,
            hat integer REFERENCES hats(id) ON DELETE CASCADE
        );

        
        CREATE TABLE owns(
            player_id integer REFERENCES players(id) ON DELETE CASCADE,
            hat integer REFERENCES hats(id) ON DELETE CASCADE,
            amount integer CHECK (amount > 0),
            PRIMARY KEY (player_id, hat)
        );


        CREATE OR REPLACE FUNCTION public.confirm_pass(_username text, _password text)
        RETURNS boolean
        LANGUAGE plpgsql
        AS $function$
        BEGIN
            IF (EXISTS (SELECT * FROM players WHERE username = _username AND password = crypt(_password, password))) THEN
                RETURN TRUE;
            ELSE 
                RETURN FALSE;
            END IF;
        END;
        $function$;
        

        CREATE OR REPLACE FUNCTION public.get_all_scores()
        RETURNS highscore
        LANGUAGE sql
        AS $function$
            SELECT * FROM highscore;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_pigeon_by_id(_id integer)
        RETURNS pigeons
        LANGUAGE sql
        AS $function$
            SELECT * FROM pigeons WHERE id = _id LIMIT 1;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_pigeon_by_pigeonhole(_id integer)
        RETURNS TABLE(id integer)
        LANGUAGE sql
        AS $function$
            SELECT id FROM pigeons WHERE pigeonhole_id = _id;
        $function$;
        
        
        CREATE OR REPLACE FUNCTION public.get_pigeonholes_by_user(_id integer)
        RETURNS TABLE(id integer, pos integer)
        LANGUAGE sql
        AS $function$
            SELECT id, position AS pos FROM pigeonholes WHERE player_id = _id;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_pigeons_by_user(_id integer)
        RETURNS TABLE(id integer, pigeonhole_id integer, chance integer, intelligence integer, constitution integer, hat integer)
        LANGUAGE sql
        AS $function$
            SELECT id, pigeonhole_id, chance, intelligence, constitution, hat FROM pigeons LEFT JOIN wears ON id = pigeon  WHERE owner_id = _id;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_hats_by_user(_id integer)
        RETURNS TABLE(hat integer, amount integer)
        LANGUAGE sql
        AS $function$
            SELECT hat, amount - COALESCE(cnt,0) AS amount FROM (owns INNER JOIN hats h ON hat = id) FULL JOIN 
            (SELECT count(hat) AS cnt, hat AS _hat FROM wears INNER JOIN pigeons ON pigeon = id GROUP BY hat, owner_id HAVING owner_id = 0 ) ON hat = _hat
            WHERE player_id = 0;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_score_by_user(_id integer)
        RETURNS highscore
        LANGUAGE sql
        AS $function$
                SELECT * FROM highscore WHERE user_id = _id;
        $function$;
        

        CREATE OR REPLACE FUNCTION public.get_user(_username text)
        RETURNS TABLE(id integer, username text, money integer)
        LANGUAGE sql
        AS $function$
            SELECT id, username, money FROM players WHERE username = _username LIMIT 1;
        $function$;

        
        CREATE OR REPLACE FUNCTION public.get_user(_id integer)
        RETURNS TABLE(id integer, username text, money integer)
        LANGUAGE sql
        AS $function$
            SELECT id, username, money FROM players WHERE id = _id LIMIT 1;
        $function$;

                
        CREATE OR REPLACE FUNCTION public.pigeonhole_is_available(_id integer)
        RETURNS boolean
        LANGUAGE plpgsql
        AS $function$
        BEGIN
            IF (NOT EXISTS (SELECT * FROM pigeonholes WHERE id = _id)) THEN
                RETURN FALSE;
            ELSE
                IF (EXISTS (SELECT id FROM pigeons WHERE pigeonhole_id = _id LIMIT 1)) THEN
                    RETURN FALSE;
                ELSE 
                    RETURN TRUE;
                END IF;
            END IF;
        END;
        $function$;

        CREATE OR REPLACE PROCEDURE public.add_score(IN _id integer, IN _game game, IN _score integer)
        LANGUAGE sql
        AS $procedure$
            INSERT INTO highscore VALUES(_id, _game, _score, current_timestamp)
        $procedure$;

        
        CREATE OR REPLACE PROCEDURE public.buy_hat(IN _id integer, IN _hat integer)
        LANGUAGE plpgsql
        AS $procedure$
        BEGIN
            IF EXISTS( SELECT * FROM owns WHERE player_id = _id AND hat = _hat) THEN
                UPDATE owns 
                SET amount = amount + 1  
                WHERE player_id = _id AND hat = _hat;
            ELSE
                INSERT INTO owns 
                VALUES (_id, _hat, 1);
            END IF;
            UPDATE players SET money = money - (SELECT price FROM hats WHERE id = _hat) WHERE id = _id;
        END;
        $procedure$;


        CREATE OR REPLACE PROCEDURE public.create_pigeon(IN _owner_id integer, IN _pigeonhole_id integer)
        LANGUAGE sql
        AS $procedure$
            INSERT INTO pigeons(owner_id, pigeonhole_id, chance, intelligence, constitution) VALUES(_owner_id, _pigeonhole_id, (SELECT ROUND(RANDOM()*19+1)), (SELECT ROUND(RANDOM()*19+1)), (SELECT ROUND(RANDOM()*19+1)));
        $procedure$;


        CREATE OR REPLACE PROCEDURE public.create_user(IN _username text, IN _password text)
        LANGUAGE plpgsql
        AS $procedure$
            BEGIN
                INSERT INTO players(username, password, money) VALUES(_username, crypt(_password, gen_salt('bf')), 500);
                FOR hole in 1..20 LOOP
                    INSERT INTO pigeonholes(player_id,position) VALUES((SELECT id FROM get_user(_username)), hole);
                END LOOP;
            END;
        $procedure$;

        
        CREATE OR REPLACE PROCEDURE public.equip_hat(IN _id integer, IN _hat integer)
        LANGUAGE plpgsql
        AS $procedure$
        BEGIN
            If Exists (SELECT * FROM wears WHERE pigeon = _id AND hat = _hat) THEN
                DELETE FROM wears WHERE pigeon = _id;
            ELSE 
                IF EXISTS( SELECT * FROM wears WHERE pigeon = _id) THEN
                    DELETE FROM wears WHERE pigeon = _id;
                END IF;
                INSERT INTO wears 
                VALUES (_id, _hat);
            END IF;
        END;
        $procedure$;

        CREATE OR REPLACE PROCEDURE public.set_score(IN _id integer, IN _game game, IN _score integer)
        LANGUAGE plpgsql
        AS $procedure$
        BEGIN
            IF EXISTS( SELECT * FROM highscore WHERE game = _game AND user_id = _id) THEN
                UPDATE highscore 
                SET score = _score 
                WHERE game = _game AND user_id = _id;
            ELSE
                INSERT INTO highscore (user_id, game, score, created_at) 
                VALUES (_id, _game, _score, current_timestamp);
            END IF;
        END;
        $procedure$;

        
        CREATE OR REPLACE PROCEDURE public.update_pigeon(IN _id integer, IN _chance integer, IN _constitution integer)
        LANGUAGE sql
        AS $procedure$
            UPDATE pigeons SET chance = _chance, constitution = _constitution WHERE id = _id 
        $procedure$;

        

    '''

    cursor.execute(sql)

    conn.close 