### STAT 6289-10 FINAL PROJECT ###
# Zimu Lin / Huijae Lee

# DATABASE
CREATE DATABASE `final_project`; 
USE `final_project`; 

# CHECK IMPORTED RELATIONS
SELECT * FROM appearances;
# Use red/yellow card, goals, assits, and minutes_played
SELECT * FROM games;
# Use home/away club goals
SELECT * FROM players;
# use height and foot (left/right foot)

### CHECK IF PK IS UNIQUE ###
SELECT count(*) 
	FROM appearances;
SELECT count(*) - count(distinct appearance_id,game_id,player_id) 
	FROM appearances;

SELECT count(*) 
	FROM games;
SELECT count(*) - count(distinct game_id) 
	FROM games;

SELECT count(*) 
	FROM players;
SELECT count(*) - count(distinct player_id, current_club_id) 
	FROM players;

### Normalization of appearances relation ###
### 3NF of appearances relation ###
SELECT * from appearances;
# we can see that appearances relation is already 2NF
# appearance_id is a PK
# player_club_id, player_current_club_id, player_name depends on appearance_id via player_id -> (nf_player_from_appearances)
# competition_id, date depends on appearance_id via game_id -> (nf_game_from_appearances relation)
# yellow_cards, red_cards, goals, assists, and minutes_played depends on appearance_id via (game_id, player_id) -> (nf_game_player)
Create table nf_player_from_appearances AS 
	SELECT distinct player_id, player_club_id, player_current_club_id, player_name
	FROM appearances; 

CREATE table nf_game_from_appearances AS 
	SELECT distinct game_id, competition_id, date 
	FROM appearances;

CREATE table nf_game_player AS
	SELECT game_id, player_id, yellow_cards, red_cards, goals, assists, minutes_played
	FROM appearances;

CREATE table nf_appearances AS
	SELECT distinct appearance_id, player_id, game_id 
    FROM appearances;

### Normalization of games relation ###
# season, date, round, url, aggregate, away_club_id, home_club_id, competition_id,
# away_club_goals, away_club_position, away_club_formation, away_club_manager_name depend on game_id,
# home_club_goals, home_club_position, home_club_formation, attendance,competition_id -> (nf_games_from_games)
# away_club_name depends on away_club_id -> (nf_game_away)
# home_club_name, stadium depends on (game_id,home_club_id) -> (nf_game_home)
# referee, competition_type depends on competition_id -> (nf_competition)
CREATE TABLE nf_games_from_games AS
	SELECT game_id, competition_id, home_club_id, away_club_id, season,  away_club_goals, away_club_position, 
    away_club_formation, date, round, url, aggregate, away_club_manager_name, home_club_goals, home_club_position, 
    home_club_formation, attendance 
    FROM games;

CREATE TABLE nf_game_away AS
	SELECT distinct away_club_id, away_club_name
    FROM games;

CREATE TABLE nf_game_home AS
	SELECT distinct home_club_id, home_club_name, stadium
    FROM games;

CREATE TABLE nf_competition AS
	SELECT distinct competition_id, referee, competition_type 
    FROM games;
SELECT * FROM nf_game_home;

### Normalization of players relation ###
### 2NF of players relation ###
# Players relation has (player_id, current_club_id) as PK.
# first_name, last_name, name, last_season, player_code, country_of_birth, country_of_citizenship, date_of_birth, foot, 
# height_in_cm, image_url, url depend on player_id -> ( nf_players)
# agent_name, sub_position, position, current_club_domestic_competition_id, current_club_name, market_value_in_eur, 
# highest_market_value_in_eur depend on (player_id, current_club_id) -> (nf_players_currentclub)
# We finish here because this is a 3NF form as well.
Create table NF_players AS 
	SELECT player_id, current_club_id, first_name, last_name, name, last_season, player_code, country_of_birth, 
    country_of_citizenship, date_of_birth, foot, height_in_cm, image_url, url, sub_position, position, market_value_in_eur, 
    highest_market_value_in_eur
    FROM players;

Create table NF_players_currentclub AS
	SELECT distinct current_club_id, agent_name, current_club_domestic_competition_id, 
	current_club_name 
    FROM players;

### Here is an example
SELECT game_id, home_club_id, date, round, season, home_club_name, stadium FROM games
ORDER BY home_club_id;

SELECT * FROM nf_game_home
ORDER BY home_club_id;

# Here is another example
# nf_player_from_appearances table
SELECT appearance_id, game_id, player_id, player_club_id, player_current_club_id, player_name 
FROM appearances
ORDER BY player_id;

SELECT * FROM nf_player_from_appearances
ORDER BY player_id;

## we can see that yellow_cards, red_cards, goals, and assists are fully dependent on appearance_id, game_id
# We want to see which could affect players score(apperances relation / goals) 
# Create a new table Soccer using three relations; appearances, players, and games.


### soccer2 relation ###
# We used normalized tables to create soccer2 table.
# We choose nf_appearances, nf_game_player, nf_players,  and nf_games_for_soccer based on our interest.
     CREATE TABLE Soccer2 AS
            SELECT
				ap.appearance_id,
                ap.player_id, 
                ap.game_id, 
                gp.goals, 
                gp.yellow_cards, 
                gp.red_cards, 
                gp.assists,  
                gf.home_club_goals,
                gf.away_club_goals,  
                ps.height_in_cm,
                ps.position
            FROM 
                nf_appearances ap
			LEFT JOIN
				nf_game_player gp ON ap.player_id = gp.player_id AND ap.game_id = gp.game_id
            LEFT JOIN 
                nf_players ps ON ps.player_id = ap.player_id
			LEFT JOIN
				nf_games_from_games gf ON gf.game_id = ap.game_id
            ORDER BY 
                ap.player_id;
                
SELECT * FROM soccer2;

### This is a new relation we are going to use on website.
# Also use this relation for 
SELECT * FROM soccer2
ORDER BY appearance_id;

# This is a table for INDEX, TRIGGER, VIEW,... #
CREATE TABLE test_players AS
SELECT player_id, position, foot, height_in_cm, market_value_in_eur FROM players
WHERE market_value_in_eur IS NOT NULL;


### INDEX ###
SELECT * FROM soccer2;
# Create index for player_id in soccer2. This index will be used on only for searching player_id.
CREATE INDEX soccer2_player_id_index
ON soccer2 (player_id);

SELECT * FROM soccer2 USE INDEX (soccer2_player_id_index)
    WHERE player_id IN (9501, 9794);

    
    
### View ###
CREATE VIEW left_or_right 
	AS SELECT * FROM test_players
		WHERE foot IN ('right','left');
        
SELECT * FROM left_or_right;

### View without check option
CREATE VIEW position_value 
	AS SELECT player_id, position, market_value_in_eur FROM test_players
		WHERE market_value_in_eur >= 500000;

# See View table
SELECT * FROM position_value
ORDER BY player_id;

INSERT INTO position_value VALUES (0001, 'Attack',500001);
INSERT INTO position_value VALUES (0002, 'Defender',500002);
INSERT INTO position_value VALUES (0003, 'Midfield',500003);
# market_value_in_eur is less than 500000, market_value_in_eur = 400000 will not be inserted in VIEW table.
INSERT INTO position_value VALUES (0004, 'Goalkeeper',400000);

# We can see that only three of them are inserted in view table
SELECT * FROM position_value
ORDER BY player_id;


# But we can see all four values are inserted into test_players table.
SELECT * FROM test_players
ORDER BY player_id;

### View WITH CHECK OPTION
CREATE VIEW position_value_check 
	AS SELECT player_id, position, market_value_in_eur FROM test_players
		WHERE market_value_in_eur >= 500000
        WITH CHECK OPTION;

# Check VIEW table
SELECT * FROM position_value_check
ORDER BY player_id;

# Insert two different values; one with conditions met, and one with conditions not met.
INSERT INTO position_value_check VALUES (0005, 'Midfield',500005);
INSERT INTO position_value_check VALUES (0006, 'Goalkeeper',400006);
# Because of 'WITH CHECK OPTION', we can see Message Error Code: 1369 CHECK OPTION failed
SELECT * FROM position_value_check
ORDER BY player_id;

# Here is the difference.
# We COULD insert/update values to test_players table even values do not meet conditions.
# However, WITH CHECK OPTION, we CANNOT insert/update on test_players table because values are not met on WHERE clause.
SELECT * FROM test_players
ORDER BY player_id;



### TRIGGER ###
DROP TRIGGER before_test_update;
# This TRIGGER will be triggered if you UPDATE test_players relation. It will return adding 10 on old market_value_in_eur 
# everytime you do UPDATE. 
CREATE TRIGGER before_test_update
BEFORE UPDATE ON test_players
FOR EACH ROW
SET NEW.market_value_in_eur = OLD.market_value_in_eur +10;

# Let's see test_players before testing our TRIGGER.
SELECT * FROM test_players
ORDER BY player_id;

# IF PREVENT FROM YOU FROM SAFE UPDATES RUN BELOW
SET SQL_SAFE_UPDATES = 0;

# Test TRIGGER
UPDATE test_players 
SET height_in_cm = 200
WHERE player_id <100;

# We can see old_market_value_in_eur has been updated.
SELECT * FROM test_players
ORDER BY player_id;
