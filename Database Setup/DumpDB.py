import psycopg2
from Setup import user, password, host, port

def dump_db ():
    conn = psycopg2.connect(database="pigeonhole", user=user, password=password, host=host, port=port)

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