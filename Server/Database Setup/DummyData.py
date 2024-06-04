from DumpDB import dump_db
from sys import path
import os
path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),'..')))
from DBInit import _user, password, host, port
import psycopg2

dump_db()

conn = psycopg2.connect(database="pigeonhole", user=_user, password=password, host=host, port=port)

conn.autocommit = True

cursor = conn.cursor()

sql = '''
    INSERT INTO players VALUES(0,'testUser',crypt('testPassword', gen_salt('bf')), 500);

    INSERT INTO pigeonholes(player_id, position) VALUES(0,0);
    INSERT INTO pigeonholes(player_id, position) VALUES(0,1);
    INSERT INTO pigeonholes(player_id, position) VALUES(0,2);

    INSERT INTO pigeons VALUES(0,0,0,12,7,18);

    INSERT INTO hats VALUES(0,25,'Hat');
    INSERT INTO hats VALUES(1,50,'SunHat');
    INSERT INTO hats VALUES(2,150,'Cowboy');
    INSERT INTO hats VALUES(3,100,'Crown');
    INSERT INTO hats VALUES(4,75,'Flower');
    INSERT INTO hats VALUES(5,25,'Tinfoil');
    INSERT INTO hats VALUES(6,1,'Baret');
    INSERT INTO hats VALUES(7,2,'Cap');
    INSERT INTO hats VALUES(8,3,'ClownHair');
    INSERT INTO hats VALUES(9,1,'DevilHorns');
    INSERT INTO hats VALUES(10,10,'Fedora');
    INSERT INTO hats VALUES(11,2,'GreenHat');
    INSERT INTO hats VALUES(12,3,'Luigi');
    INSERT INTO hats VALUES(13,3,'Mario');
    INSERT INTO hats VALUES(14,1,'PinkHat');
    INSERT INTO hats VALUES(15,2,'Shroom');
    INSERT INTO hats VALUES(16,3,'SillyHat');
    INSERT INTO hats VALUES(17,4,'VikingHat');
    INSERT INTO hats VALUES(18,1,'AnimeHair');
    INSERT INTO hats VALUES(19,10,'Baby');
    INSERT INTO hats VALUES(20,3,'BunnyEars');
    INSERT INTO hats VALUES(21,5,'Sombrero');
    INSERT INTO hats VALUES(23,50,'FancyHat');
    INSERT INTO hats VALUES(24,10,'FrogHat');
'''

cursor.execute(sql)
conn.close 

