from DumpDB import dump_db
import psycopg2

dump_db()

conn = psycopg2.connect(database="pigeonhole", user="postgres", password="testPassword", host="127.0.0.1", port="5432")

conn.autocommit = True

cursor = conn.cursor()

sql = '''
    INSERT INTO players VALUES(0,'testUser',crypt('testPassword', gen_salt('bf')));

    INSERT INTO pigeonholes VALUES(0,0,0);

    INSERT INTO pigeons VALUES(0,0,0,'playing',12,7,18);
'''

cursor.execute(sql)
conn.close 

