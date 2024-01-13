--creating table ipl_ball--

CREATE TABLE ipl_ball (
    id_no int,
    innings int,
    over_no int,
    balls int,
    batsman varchar(255),
    non_striker varchar(255),
    bowler varchar(255),
    batsman_runs int,
    extra_runs int,
    total_runs int,
    is_wicket int,
    dismissal_kind varchar(255),
    player_dismissed varchar(255),
    fielder varchar(255),
    extra_type varchar(255),
    batting_team varchar(255),
    bowling_team varchar(255)
);


-- copy data from csv file to ipl ball --

copy ipl_ball from 'C:\Program Files\PostgreSQL\16\data\data_copy\Data\IPL Dataset\IPL_Ball.csv' delimiter ',' csv header;
select * from ipl_ball;

-- creating table ipl_matches--

CREATE TABLE ipl_matches (
    id_no int,
    city varchar(255),
    match_date date,
    player_of_match varchar(255),
    venue varchar(255),
    neutral_venue int,
    team1 varchar(255),
    team2 varchar(255),
    toss_winner varchar(255),
    toss_decision varchar(255),
    winner varchar(255),
    results varchar(255),
    result_margin int,
    eliminator varchar(255),
    methods varchar(255),
    umpire1 varchar(255),
    umpire2 varchar(255)
);


--copy data from csv file to ipl_matches--

copy ipl_matches from 'C:\Program Files\PostgreSQL\16\data\data_copy\Data\IPL Dataset\IPL_matches.csv' delimiter ',' csv header;
select * from ipl_matches;


-- getting the list top 10 players with highest strike rate--


SELECT
    batsman,
    SUM(batsman_runs) AS Total_runs,
    COUNT(balls) AS Balls_faced,
    ROUND((SUM(batsman_runs) * 100.0) / COUNT(balls), 2) AS Strike_rate
FROM
    ipl_Ball
WHERE
    extra_type != 'wides'
GROUP BY
    batsman
HAVING
    COUNT(balls) >= 500
ORDER BY
    Strike_rate DESC
LIMIT 10;

  
select * from ipl_matches; select * from ipl_ball;  


--getting the list of top 10 players with highest average--


SELECT
    b.batsman,
    COUNT(DISTINCT EXTRACT(YEAR FROM m.match_date)) AS season_played,
    SUM(b.batsman_runs) AS total_runs,
    SUM(CASE WHEN b.is_wicket = 1 THEN 1 ELSE 0 END) AS wicket_ball,
    SUM(b.batsman_runs) / NULLIF(SUM(CASE WHEN b.is_wicket = 1 THEN 1 ELSE 0 END), 0) AS Batting_average
FROM
    IPL_Ball b
INNER JOIN
    IPL_Matches m ON b.id_no = m.id_no
GROUP BY
    b.batsman
HAVING
    COUNT(DISTINCT EXTRACT(YEAR FROM m.match_date)) > 2
    AND COUNT(b.balls) > 500
ORDER BY
    Batting_average DESC
LIMIT 10;

-- getting the list of top 10 hard hitting players--

SELECT
    a.batsman,
    a.batting_team,
    COUNT(DISTINCT EXTRACT(YEAR FROM b.match_date)) AS season_played,
    SUM(a.batsman_runs) AS total_runs,
    SUM(CASE WHEN a.batsman_runs IN (4, 6) THEN 1 ELSE 0 END) AS total_boundaries
FROM
    IPL_Ball AS a
    INNER JOIN IPL_Matches AS b ON a.id_no = b.id_no
GROUP BY
    a.batsman, a.batting_team
HAVING
    COUNT(DISTINCT EXTRACT(YEAR FROM b.match_date)) > 2
    AND SUM(CASE WHEN a.batsman_runs IN (4, 6) THEN 1 ELSE 0 END) > 0
ORDER BY
    total_boundaries DESC
LIMIT 10;


--getting top 10 bowlers with best economy--


SELECT
    a.bowler,
    COUNT(DISTINCT EXTRACT(YEAR FROM b.match_date)) AS seasons_played,
    SUM(a.balls) AS total_balls,
    SUM(a.total_runs) AS total_runs,
    ROUND(SUM(a.balls) / 6.0, 0) AS total_overs,
    ROUND(SUM(a.total_runs) / (SUM(a.balls) / 6.0), 2) AS economy
FROM
    ipl_ball AS a
    INNER JOIN ipl_matches AS b ON a.id_no = b.id_no
GROUP BY
    a.bowler
HAVING
    SUM(a.balls) >= 500
ORDER BY
    economy ASC
LIMIT 10;

select * from ipl_ball;


--getting top 10 bowlers with best strike rate--


SELECT
    bowler,
    SUM(total_runs) AS total_runs_given,
    ROUND(SUM(total_balls) / 6, 0) AS total_overs_bowled,
    SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END) AS total_wickets,
    ROUND(SUM(total_balls) / NULLIF(SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END), 0), 2) AS strike_rate
FROM
    (
        SELECT
            bowler,
            SUM(batsman_runs) AS total_runs,
            COUNT(balls) AS total_balls,
            SUM(CASE WHEN dismissal_kind IN ('caught', 'lbw', 'bowled') THEN 1 ELSE 0 END) AS is_wicket
        FROM
            IPL_Ball
        WHERE
            extra_type != 'wide'
        GROUP BY
            bowler, id_no
    ) AS bowler_stats
GROUP BY
    bowler
HAVING
    SUM(total_balls) >= 500
ORDER BY
    strike_rate ASC
LIMIT 10;



-- getting top 10 all rounders--


WITH AllRounderStats AS (
    SELECT
        batsman,
        COUNT(*) AS balls_faced,
        SUM(batsman_runs) AS total_runs
    FROM
        IPL_Ball
    GROUP BY
        batsman
    HAVING
        COUNT(*) >= 500
),
BowlerStats AS (
    SELECT
        bowler,
        COUNT(*) AS balls_bowled,
        COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS total_wickets
    FROM
        IPL_Ball
    GROUP BY
        bowler
    HAVING
        COUNT(*) >= 300
),
AllRounders AS (
    SELECT
        a.batsman,
        a.total_runs,
        a.balls_faced,
        b.balls_bowled,
        b.total_wickets,
        ROUND(a.total_runs * 100.0 / NULLIF(a.balls_faced, 0), 2) AS batting_strikerate,
        ROUND(b.balls_bowled * 1.0 / NULLIF(b.total_wickets, 0), 2) AS bowling_strikerate
    FROM
        AllRounderStats a
    JOIN
        BowlerStats b ON a.batsman = b.bowler
)
SELECT
    batsman,
    batting_strikerate,
    bowling_strikerate
FROM
    AllRounders
ORDER BY
    batting_strikerate DESC, bowling_strikerate ASC
LIMIT 10;
   
-- criteria for wicketkeeper--
/* 
In choosing our T20 team's wicketkeeper, we have set specific criteria to find a player 
who fits well in the fast-paced nature of this format.
Wicketkeeping Skills:
Catches and Stumpings: We're looking for a player who has taken most number of catches and done most no of stumping but 
at least 50 catches and 50 stumpings, showing excellence in securing dismissals.
Batting Ability:
Minimum Balls Faced: The candidate should have faced a minimum of 500 deliveries, 
indicating their ability to stay at the crease.
High Strike Rate: We prefer a player with a good batting strike rate, meaning they score quickly.
Scoring Style:
Runs from Boundaries: We want a player whose runs mostly come from boundaries, 
specifically 4s and 6s, showcasing an aggressive batting style.
Bowling Contributions:
Bowled Over 300 Balls: If the player has bowled more than 300 balls, 
it adds an extra dimension to our team's strategy.
These simple criteria aim to find a wicketkeeper who not only excels at dismissals 
but also contributes effectively to scoring runs and provides strategic options in T20 matches.
*/

--Get the count of cities that have hosted an IPL match--

select count(distinct city) as No_Of_cities from ipl_matches;

/* Create table deliveries_v02 with all the columns of the table ‘deliveries’ 
and an additional column ball_result containing values boundary, dot or other depending on the total_run */

CREATE TABLE deliveries_v02 AS
SELECT *, 
    CASE 
        WHEN total_runs >= 4 THEN 'boundary'
        WHEN total_runs = 0 THEN 'dot'
        ELSE 'other'
    END AS ball_result
FROM ipl_ball;

select * from deliveries_v02;

--Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.--

SELECT
    ball_result,
    COUNT(*) AS total_count
FROM
    deliveries_v02
WHERE
    ball_result IN ('boundary', 'dot')
GROUP BY
    ball_result;
	
/* Write a query to fetch the total number of boundaries scored by each team from the deliveries_v02 table
and order it in descending order of the number of boundaries scored. */

SELECT
    batting_team,
    COUNT(*) AS total_boundaries
FROM
    deliveries_v02
WHERE
    ball_result = 'boundary'
GROUP BY
    batting_team
ORDER BY
    total_boundaries DESC;

/* Write a query to fetch the total number of dot balls bowled by each team 
and order it in descending order of the total number of dot balls bowled. */

SELECT
    bowling_team,
    COUNT(*) AS total_dot_balls
FROM
    deliveries_v02
WHERE
    ball_result = 'dot'
GROUP BY
    bowling_team
ORDER BY
    total_dot_balls DESC;
	
-- Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA--

SELECT
    dismissal_kind,
    COUNT(*) AS total_dismissals
FROM
    deliveries_v02
WHERE
    dismissal_kind IS NOT NULL
    AND dismissal_kind != 'NA'
GROUP BY
    dismissal_kind
ORDER BY
    total_dismissals DESC;

-- Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table--
SELECT
    bowler,
    SUM(extra_runs) AS total_extra_runs
FROM
    ipl_ball
GROUP BY
    bowler
ORDER BY
    total_extra_runs DESC
LIMIT 5;

/* Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 table 
and two additional column (named venue and match_date) of venue and date from table matches*/

CREATE TABLE deliveries_v03 AS
SELECT
    a.*,
    b.venue,
    b.match_date AS date
FROM
    deliveries_v02 AS a
JOIN
    IPL_Matches AS b ON a.id_no = b.id_no;

-- Write a query to fetch the total runs scored for each venue and order it in the descending order of total runs scored.--

SELECT
    venue,
    SUM(total_runs) AS total_runs_scored
FROM
    deliveries_v03
GROUP BY
    venue
ORDER BY
    total_runs_scored DESC;

--Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.--

SELECT
    EXTRACT(YEAR FROM date) AS year,
    SUM(total_runs) AS total_runs_scored
FROM
    deliveries_v03
WHERE
    venue = 'Eden Gardens'
GROUP BY
    year
ORDER BY
    total_runs_scored DESC;
























