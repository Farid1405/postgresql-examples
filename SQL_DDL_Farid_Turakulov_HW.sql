 
-- CREATE DATABASE subway_system;
CREATE SCHEMA IF NOT EXISTS subway;

CREATE TABLE IF NOT EXISTS subway."station_type"(
	PK_station_type_ID SERIAL PRIMARY KEY,
	station_type_name VARCHAR(50) NOT NULL DEFAULT 'ordinary'
); 

CREATE TABLE IF NOT EXISTS subway."tariff"(
	PK_tariff_ID SERIAL PRIMARY KEY,
	tariff_name VARCHAR(50) UNIQUE NOT NULL ,
	price_per_card DECIMAL NOT NULL,
	price_per_ride DECIMAL NOT NULL DEFAULT 0, -- on some tariffs there are unlimited number of rides so that every ride will cost 0 
	CONSTRAINT positive_price_card CHECK (price_per_card > 0) -- card can't be free because there are expenses related to it's prodution
);


CREATE TABLE IF NOT EXISTS subway."subway_pass_card"(
	PK_subway_pass_card_number SERIAL UNIQUE PRIMARY KEY,
	card_holder_name VARCHAR (50) DEFAULT 'Name',
	card_holder_surname VARCHAR (50) DEFAULT 'Surname',
	card_holder_full_name VARCHAR(100) GENERATED ALWAYS AS (card_holder_name||' '|| card_holder_surname) STORED,
	card_holder_telephone VARCHAR (30) DEFAULT '998XXXXXXXXX',
	card_balance DECIMAL DEFAULT 0,
	expiry_date DATE NOT NULL DEFAULT  (now()+ interval '3 year'), -- after 3 years card needs to be replaced
	FK_tariff_ID INT REFERENCES subway."tariff" (PK_tariff_ID)
);

CREATE TABLE IF NOT EXISTS subway."subway_line"(
	PK_subway_line_ID SERIAL PRIMARY KEY,
	line_color VARCHAR(50) NOT NULL,
	subway_line_length_in_km DECIMAL CONSTRAINT line_length CHECK(subway_line_length_in_km > 0), -- line's length can't be 0 or less 
	start_time TIME NOT NULL,
	end_time TIME NOT NULL
);

CREATE TABLE IF NOT EXISTS subway."station"(
	PK_station_ID SERIAL PRIMARY KEY,
	station_name VARCHAR(50) UNIQUE NOT NULL,
	number_of_exits INT NOT NULL CONSTRAINT st_exit_number CHECK(number_of_exits>0), -- every station must have at least one exit
	FK_subway_line_ID INT REFERENCES subway."subway_line" (PK_subway_line_ID)
);

CREATE TABLE IF NOT EXISTS subway."station_station_type"(  -- bridge table to link several station types to station
	PK_station_station_type_ID SERIAL PRIMARY KEY,
	FK_station_type_ID INT NOT NULL REFERENCES subway."station_type" (PK_station_type_ID),
	FK_station_ID INT NOT NULL REFERENCES subway."station" (PK_station_ID)
);

CREATE TABLE IF NOT EXISTS subway."one_time_ticket"(
	PK_one_time_pass_code_ID SERIAL PRIMARY KEY,
	dead_time TIMESTAMP NOT NULL DEFAULT now()+(15 * interval '1 minute'), -- By default ticket will expire after 15 minutes from time when it was generated
	number_of_use INT NOT NULL DEFAULT 1 CHECK (number_of_use > 0),
	price DECIMAL DEFAULT 1400,		-- the price for a ticket in my countrie's subway 
	FK_station_ID INT REFERENCES subway."station" (PK_station_ID)
);
CREATE TABLE IF NOT EXISTS subway."subway_ride"(
	PK_subway_ride_ID SERIAL PRIMARY KEY,
	date_of_ride TIMESTAMP DEFAULT NOW(),
	FK_station_ID INT REFERENCES subway."station" (PK_station_ID)
);

CREATE TABLE IF NOT EXISTS subway."employee"(
	PK_employee_ID SERIAL PRIMARY KEY,
	employee_name VARCHAR(50) NOT NULL,
	employee_surname VARCHAR(50) NOT NULL,
	employee_position VARCHAR(50) NOT NULL,
	salary DECIMAL NOT NULL,
	FK_station_station_ID int REFERENCES subway."station" (PK_station_ID),
	CONSTRAINT valid_salary CHECK (salary > 300000) -- in my country this is minimal salary 
);

CREATE TABLE IF NOT EXISTS subway."cross_station"(
	PK_cross_station_ID SERIAL PRIMARY KEY,
	FK_first_station_station_ID int REFERENCES subway."station" (PK_station_ID),
	FK_second_station_station_ID int REFERENCES subway."station" (PK_station_ID),
	UNIQUE (FK_first_station_station_ID, FK_second_station_station_ID)
);
CREATE TABLE IF NOT EXISTS subway."train" (
	PK_train_ID SERIAL PRIMARY KEY,
	train_number int NOT NULL UNIQUE,
	train_last_maintenance_date TIMESTAMP,
	FK_line_ID int REFERENCES subway."subway_line" (PK_subway_line_ID),
	FK_train_driver_ID int REFERENCES subway."employee" (PK_employee_ID)
);
CREATE TABLE IF NOT EXISTS subway."tunnel"(
	PK_tunnel_ID SERIAL PRIMARY KEY,
	tunnel_length DECIMAL NOT NULL,
	FK_subway_line_ID INT NOT NULL REFERENCES subway."subway_line" (PK_subway_line_ID),
	FK_from_station_station_ID int NOT NULL REFERENCES subway."station" (PK_station_ID),
	FK_to_station_station_ID int NOT NULL REFERENCES subway."station" (PK_station_ID),
	CONSTRAINT valid_tunnel_length CHECK(tunnel_length>0)
);
CREATE TABLE IF NOT EXISTS subway."power_station"(
	PK_power_station_ID SERIAL PRIMARY KEY,
	current_status VARCHAR(50) DEFAULT 'idle',
	power_capacity_in_megawatts DECIMAL NOT NULL,
	last_maintenance_date TIMESTAMP,
	FK_station_station_ID int REFERENCES subway."station" (PK_station_ID)
);

--  			INSERTING station types

INSERT INTO subway.station_type (station_type_name) -- type of station which will cross with another station
SELECT 'cross'
WHERE NOT EXISTS
    (SELECT station_type_name
     FROM subway.station_type
     WHERE UPPER(station_type_name) = 'CROSS' )
UNION ALL
SELECT 'terminus'
WHERE NOT EXISTS
    (SELECT station_type_name
     FROM subway.station_type
     WHERE UPPER(station_type_name) = 'TERMINUS' )
UNION ALL
SELECT 'ordinary'
WHERE NOT EXISTS
    (SELECT station_type_name
     FROM subway.station_type
     WHERE UPPER(station_type_name) = 'ORDINARY' )
RETURNING *;


--  			INSERTING tariffs
INSERT INTO subway.tariff (tariff_name, price_per_card, price_per_ride)
SELECT 'standard',
       5000,
       1400
WHERE NOT EXISTS
    (SELECT tariff_name
     FROM subway.tariff
     WHERE UPPER(tariff_name) = 'STANDARD' )
UNION ALL
SELECT 'student',-- students will by cards for 83000 and have an unlimited number of rides
       83000,
       0
WHERE NOT EXISTS
    (SELECT tariff_name
     FROM subway.tariff
     WHERE UPPER(tariff_name) = 'STUDENT' ) 
RETURNING *;

--  			INSERTING pass cards

INSERT INTO subway."subway_pass_card" (card_holder_name,
                                       card_holder_surname,
                                       card_holder_telephone,
                                       card_balance,
                                       FK_tariff_ID)
SELECT 'Steve',
       'Portman',
       '9987656748',
       5000,
  (SELECT PK_tariff_id
   FROM subway."tariff"
   WHERE UPPER(tariff_name) = 'STANDARD')
WHERE NOT EXISTS
    (SELECT card_holder_full_name
     FROM subway."subway_pass_card"
     WHERE UPPER(card_holder_full_name) = 'STEVE PORTMAN'
       AND card_holder_telephone = '9987656748' )
UNION ALL
SELECT 'Michael',
       'Scott',
       '5703433400',
       0,
  (SELECT PK_tariff_id
   FROM subway.tariff
   WHERE UPPER(tariff_name) = 'STANDARD')
WHERE NOT EXISTS
    (SELECT card_holder_full_name
     FROM subway."subway_pass_card"
     WHERE UPPER(card_holder_full_name) = 'MICHAEL SCOTT'
       AND card_holder_telephone = '5703433400' ) 
RETURNING *;


--  			INSERTING subway line

INSERT INTO subway."subway_line" (line_color,
                                  subway_line_length_in_km,
                                  start_time,
                                  end_time)
SELECT 'red',
      10,    
      '06:00:00'::time,
      '01:00:00'::time
WHERE NOT EXISTS
    (SELECT line_color
     FROM subway."subway_line"
     WHERE UPPER(line_color) = 'RED' )
UNION ALL
SELECT 'blue',
      10,    
      '05:00:00'::time,
      '23:00:00'::time
WHERE NOT EXISTS
    (SELECT line_color
     FROM subway."subway_line"
     WHERE UPPER(line_color) = 'BLUE' )
UNION ALL
SELECT 'green',
      15,    
      '06:00:00'::time,
      '00:00:00'::time
WHERE NOT EXISTS
    (SELECT line_color
     FROM subway."subway_line"
     WHERE UPPER(line_color) = 'GREEN' ) 
RETURNING *;

--  			INSERTING stations

INSERT INTO subway."station" (station_name,
                              number_of_exits,
                              FK_subway_line_ID)
SELECT 'Shoganai',
       4,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'RED')
WHERE NOT EXISTS
    (SELECT station_name
     FROM subway."station"
     WHERE UPPER(station_name) = 'SHOGANAI' )
UNION ALL
SELECT 'Estrenar',
       4,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'RED')
WHERE NOT EXISTS
    (SELECT station_name
     FROM subway."station"
     WHERE UPPER(station_name) = 'ESTRENAR' ) 
UNION ALL
SELECT 'Airag',
       3,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'BLUE')
WHERE NOT EXISTS
    (SELECT station_name
     FROM subway."station"
     WHERE UPPER(station_name) = 'AIRAG' )
UNION ALL
SELECT 'Abbiocco',
       4,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'BLUE')
WHERE NOT EXISTS
    (SELECT station_name
     FROM subway."station"
     WHERE UPPER(station_name) = 'ABBIOCCO' )
UNION ALL
SELECT 'Dumbom',
       4,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'GREEN')
WHERE NOT EXISTS
    (SELECT station_name
     FROM subway."station"
     WHERE UPPER(station_name) = 'DUMBOM' ) 
RETURNING *;

--  			INSERTING data in bridge table that links to station type and station

INSERT INTO subway."station_station_type" (FK_station_type_ID,
                                           FK_station_ID)
SELECT (SELECT PK_station_type_ID FROM subway."station_type" WHERE UPPER(station_type_name) = 'CROSS'),
      (SELECT PK_station_ID FROM subway."station" WHERE UPPER(station_name) = 'SHOGANAI') 
UNION ALL
SELECT  (SELECT PK_station_type_ID FROM subway."station_type" WHERE UPPER(station_type_name) = 'TERMINUS'),
        (SELECT PK_station_ID FROM subway."station" WHERE UPPER(station_name) = 'AIRAG')
UNION ALL
SELECT  (SELECT PK_station_type_ID FROM subway."station_type" WHERE UPPER(station_type_name) = 'CROSS'), -- Airag is going to be the last station on one side of the line that crosses with Shoganai
        (SELECT PK_station_ID FROM subway."station" WHERE UPPER(station_name) = 'AIRAG')
UNION ALL
SELECT  (SELECT PK_station_type_ID FROM subway."station_type" WHERE UPPER(station_type_name) = 'CROSS'),
        (SELECT PK_station_ID FROM subway."station" WHERE UPPER(station_name) = 'ABBIOCCO')
UNION ALL
SELECT  (SELECT PK_station_type_ID FROM subway."station_type" WHERE UPPER(station_type_name) = 'CROSS'),
        (SELECT PK_station_ID FROM subway."station" WHERE UPPER(station_name) = 'DUMBOM') 
RETURNING *;

--  			INSERTING data in one-tickets table

INSERT INTO subway."one_time_ticket" (number_of_use,
                                      FK_station_ID)
SELECT 2,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ABBIOCCO')
UNION ALL
SELECT 2,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'AIRAG') RETURNING *;

--  			INSERTING data in subway rides table that is used to collect statistical data about the usage of subway system

INSERT INTO subway."subway_ride" (FK_station_ID)
SELECT
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'AIRAG')
UNION ALL
SELECT
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ABBIOCCO')
UNION ALL
SELECT
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'SHOGANAI') 
RETURNING *;


--  			INSERTING employees
INSERT INTO subway."employee" (employee_name,
                               employee_surname,
                               employee_position,
                               salary,
                               FK_station_station_ID)
SELECT 'Tom',
       'Scott',
       'driver',
       3000000,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'SHOGANAI')
WHERE NOT EXISTS
    (SELECT employee_name,
            employee_surname
     FROM subway."employee"
     WHERE UPPER(employee_name) = 'TOM'
       AND UPPER(employee_surname) = 'SCOTT' )
UNION ALL
SELECT 'Jordan',
       'Peterson',
       'cashier',
       2500000,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'AIRAG')
WHERE NOT EXISTS
    (SELECT employee_name,
            employee_surname
     FROM subway."employee"
     WHERE UPPER(employee_name) = 'JORDAN'
       AND UPPER(employee_surname) = 'PETERSON' )
UNION ALL
SELECT 'Cassian',
       'Andor',
       'lineman',
       2000000,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ABBIOCCO')
WHERE NOT EXISTS
    (SELECT employee_name,
            employee_surname
     FROM subway."employee"
     WHERE UPPER(employee_name) = 'CASSIAN'
       AND UPPER(employee_surname) = 'ANDOR' )
UNION ALL
SELECT 'Josh',
       'McCheese',
       'driver',
       2500000,
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'DUMBOM')
WHERE NOT EXISTS
    (SELECT employee_name,
            employee_surname
     FROM subway."employee"
     WHERE UPPER(employee_name) = 'JOSH'
       AND UPPER(employee_surname) = 'MCCHEESE' ) RETURNING *;

-- INSERTING data into table with stations that cross each other

INSERT INTO subway."cross_station" (FK_first_station_station_ID,
                                    FK_second_station_station_ID)
SELECT
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'AIRAG'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'SHOGANAI')
UNION ALL
SELECT
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ABBIOCCO'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'DUMBOM') 
RETURNING *;

-- INSERTING data into trains table

INSERT INTO subway."train" (train_number,
                            train_last_maintenance_date,
                            FK_line_ID,
                            FK_train_driver_ID)
SELECT 7474,
       now(),
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'BLUE'),
  (SELECT PK_employee_ID
   FROM subway."employee"
   WHERE UPPER(employee_name) = 'CASSIAN'
     AND UPPER(employee_surname) = 'ANDOR')
UNION ALL
SELECT 7475,
       now(),
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'GREEN'),
  (SELECT PK_employee_ID
   FROM subway."employee"
   WHERE UPPER(employee_name) = 'JOSH'
     AND UPPER(employee_surname) = 'MCCHEESE')
RETURNING *;


-- INSERTING data into tunnels table

INSERT INTO subway."tunnel" (tunnel_length,
                             FK_subway_line_ID,
                             FK_from_station_station_ID,
                             FK_to_station_station_ID)
SELECT 1.5,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'BLUE'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ABBIOCCO'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'AIRAG') 
UNION ALL
SELECT 1.5,
  (SELECT PK_subway_line_ID
   FROM subway."subway_line"
   WHERE UPPER(line_color) = 'RED'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ESTRENAR'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'SHOGANAI') RETURNING *;

-- INSERTING data into tunnels table

INSERT INTO subway."power_station" (current_status,
                                    power_capacity_in_megawatts,
                                    last_maintenance_date,
                                    FK_station_station_ID)
SELECT 'under maintenance',
       1541.21,
       TO_TIMESTAMP('2022-02-22 19:10:25'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'SHOGANAI')
UNION ALL 
SELECT 'in use',
       8742.21,
       TO_TIMESTAMP('2022-02-22 19:10:25'),
  (SELECT PK_station_ID
   FROM subway."station"
   WHERE UPPER(station_name) = 'ESTRENAR') RETURNING *;


-- Adding new column to every table
ALTER TABLE subway."cross_station" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."employee" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."one_time_ticket" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."power_station" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."station" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."station_station_type" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."station_type" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."subway_line" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."subway_pass_card" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."subway_ride" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."tariff" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."train" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway."tunnel" ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

-- Checking random table:

SELECT * FROM subway."cross_station";
SELECT * FROM subway."employee";
SELECT * FROM subway."one_time_ticket";
SELECT * FROM subway."power_station";
SELECT * FROM subway."station";
SELECT * FROM subway."station_station_type";
SELECT * FROM subway."station_type";
SELECT * FROM subway."subway_line";
SELECT * FROM subway."subway_pass_card";
SELECT * FROM subway."subway_ride";
SELECT * FROM subway."tariff";
SELECT * FROM subway."train";
SELECT * FROM subway."tunnel";
