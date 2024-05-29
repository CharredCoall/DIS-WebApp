from DumpDB import dump_db
from Setup import user, password, host, port
import psycopg2

dump_db()

conn = psycopg2.connect(database="pigeonhole", user=user, password=password, host=host, port=port)

conn.autocommit = True

cursor = conn.cursor()

sql = '''
    INSERT INTO players VALUES(0,'testUser',crypt('testPassword', gen_salt('bf')), 500);

    INSERT INTO pigeonholes VALUES(0,0,0);
    INSERT INTO pigeonholes VALUES(1,0,1);

    INSERT INTO pigeons VALUES(0,0,0,'playing',12,7,18);

    INSERT INTO hats VALUES(0,25,'hat')
'''

cursor.execute(sql)
conn.close 

