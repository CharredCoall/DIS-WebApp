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

    INSERT INTO pigeons VALUES(0,0,1,12,7,18);

    INSERT INTO hats VALUES(0,50,'Hat');
    INSERT INTO hats VALUES(1,100,'SunHat');
    INSERT INTO hats VALUES(2,300,'Cowboy');
    INSERT INTO hats VALUES(3,1500,'Crown');
    INSERT INTO hats VALUES(4,100,'Flower');
    INSERT INTO hats VALUES(5,25,'Tinfoil');
    INSERT INTO hats VALUES(6,50,'Baret');
    INSERT INTO hats VALUES(7,50,'Cap');
    INSERT INTO hats VALUES(8,150,'ClownHair');
    INSERT INTO hats VALUES(9,300,'DevilHorns');
    INSERT INTO hats VALUES(10,700,'Fedora');
    INSERT INTO hats VALUES(11,1000,'GreenHat');
    INSERT INTO hats VALUES(12,1000,'Luigi');
    INSERT INTO hats VALUES(13,1000,'Mario');
    INSERT INTO hats VALUES(14,600,'PinkHat');
    INSERT INTO hats VALUES(15,500,'Shroom');
    INSERT INTO hats VALUES(16,400,'SillyHat');
    INSERT INTO hats VALUES(17,600,'VikingHat');
    INSERT INTO hats VALUES(18,1200,'AnimeHair');
    INSERT INTO hats VALUES(19,3000,'Baby');
    INSERT INTO hats VALUES(20,400,'BunnyEars');
    INSERT INTO hats VALUES(21,500,'Sombrero');
    INSERT INTO hats VALUES(23,1000,'FancyHat');
    INSERT INTO hats VALUES(24,10000,'FrogHat');
'''

cursor.execute(sql)
conn.close 

