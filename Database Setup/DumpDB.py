import psycopg2


def dump_db ():
    conn = psycopg2.connect(database="pigeonhole", user="postgres", password="testPassword", host="127.0.0.1", port="5432")

    conn.autocommit = True

    cursor = conn.cursor()

    sql = '''
        DELETE FROM players;

        DELETE FROM pigeonholes;

        DELETE FROM pigeons;

        DELETE FROM hats;

        DELETE FROM highscore;

        DELETE FROM wears;

        DELETE FROM owns;
    '''

    cursor.execute(sql)
    conn.close 


if __name__ == '__main__': 
    dump_db()