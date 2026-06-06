-- Olympics Data Analysis:

-- 1.	How many Olympics games have been held?
SELECT count(distinct(GAMES)) AS Countof_Olympics_Games
FROM athlete_events;

-- 2.	Extract all Olympics games held so far.
SELECT distinct(GAMES) AS Olympics_Games
FROM athlete_events
ORDER BY 1;

-- 3.	Total no of nations who participated in each Olympics game?
SELECT Games, COUNT(DISTINCT(region)) AS Nations_Participated
FROM athlete_events a
LEFT JOIN noc_regions r
 ON a.NOC = r.NOC
GROUP BY Games
ORDER BY Games;

-- 4.	Which year saw the highest and lowest no of countries participating in Olympics?
WITH CTE1 AS(
SELECT `Year`, COUNT(distinct(region)) AS Countries_Participated
FROM athlete_events a
LEFT JOIN noc_regions e
	ON a.NOC = e.NOC
GROUP BY 1
)
SELECT `Year`, Countries_Participated
FROM CTE1
where Countries_Participated = (SELECT MAX(Countries_Participated) FROM CTE1)
UNION
SELECT `Year`, Countries_Participated
FROM CTE1
where Countries_Participated = (SELECT MIN(Countries_Participated) FROM CTE1);

-- 5.	Which nation has participated in all of the Olympic games?
SELECT region, count(DISTINCT(games)) AS participated
FROM athlete_events a
LEFT JOIN noc_regions e
	ON a.NOC = e.NOC
GROUP BY 1
HAVING count(DISTINCT(games)) = (SELECT count(DISTINCT(games)) FROM athlete_events);

-- 6.	Find the Ratio of male and female athletes participated in all Olympic games.
SELECT CONCAT( ROUND( SUM(CASE WHEN Sex='M' THEN 1 ELSE 0 END) / SUM(CASE WHEN Sex='F' THEN 1 ELSE 0 END) ,1),':1') AS male_female_ratio
FROM athlete_events;

-- 7.	Fetch the top 5 athletes who have won the most gold medals.
SELECT ID, `NAME`, MEDAL, count(*) as Count
FROM athlete_events
WHERE MEDAL = 'Gold'
group by 1,2
order by 4 desc
limit 5 ;

-- 8.	Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT ID, `NAME`, count(medal) AS medals
FROM athlete_events
group by 1,2
order by 3 desc
limit 5 ;

-- 9.	Identify the sport which was played in all summer Olympics.
SELECT Sport
FROM athlete_events
WHERE Season = 'Summer'
GROUP BY Sport
HAVING COUNT(DISTINCT Games) =
(
    SELECT COUNT(DISTINCT Games)
    FROM athlete_events
    WHERE Season = 'Summer'
);

-- 10.	Which Sports were just played only once in the Olympics?
SELECT Sport
FROM athlete_events
GROUP BY Sport
HAVING COUNT(DISTINCT Games) = 1;

-- 11.	Fetch the total no of sports played in each Olympics game.
SELECT Games, count(distinct(Sport)) AS Sports_Count
FROM athlete_events
GROUP BY Games
ORDER BY Games;

-- 12.	Fetch details of the oldest athletes to win a gold medal.
SELECT *
FROM athlete_events
WHERE MEDAL = 'Gold' AND Age IS NOT NULL
order by Age desc
limit 1;

-- 13.	Fetch the top 5 most successful countries in Olympics. Success is defined by no of medals won.
SELECT region, Count(medal) AS Medals_Won
FROM athlete_events a
LEFT JOIN noc_regions r
 ON a.NOC = r.NOC
GROUP BY region
ORDER BY 2 DESC
LIMIT 5;

-- 14.	List down total gold, silver and bronze medals won by each country.
SELECT region,
SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events a
LEFT JOIN noc_regions r
 ON a.NOC = r.NOC
WHERE region IS NOT NULL
GROUP BY region;

-- ALTERNATE APPROACH
SELECT region, Medal, count(Medal) AS Medals
FROM athlete_events a
LEFT JOIN noc_regions r
 ON a.NOC = r.NOC
WHERE Medal IS NOT NULL AND region IS NOT NULL
GROUP BY region, Medal
ORDER BY region;

-- 15.	List down total gold, silver and bronze medals won by each country corresponding to each Olympic game.
SELECT Games, region,
SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events a
LEFT JOIN noc_regions r
 ON a.NOC = r.NOC
WHERE region IS NOT NULL
GROUP BY 1,2
ORDER BY 1,2;

-- 16.	Identify which country won the most gold, most silver and most bronze medals in each Olympic game.
WITH country_medals AS(
SELECT Games, region,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events a
JOIN noc_regions r
	ON a.NOC = r.NOC
WHERE Medal IS NOT NULL
GROUP BY 1,2
),
ranked AS (
SELECT *,
DENSE_RANK() OVER (PARTITION BY Games ORDER BY Gold_Medals DESC) AS Gold_Rank,
DENSE_RANK() OVER (PARTITION BY Games ORDER BY Silver_Medals DESC) AS Silver_Rank,
DENSE_RANK() OVER (PARTITION BY Games ORDER BY Bronze_Medals DESC) AS Bronze_Rank
FROM country_medals
)
SELECT Games,
MAX(CASE WHEN Gold_Rank = 1 THEN region END) AS Most_Gold,
MAX(CASE WHEN Silver_Rank = 1 THEN region END) AS Most_Silver,
MAX(CASE WHEN Bronze_Rank = 1 THEN region END) AS Most_Bronze
FROM ranked
GROUP BY Games
ORDER BY Games;

-- 17.	Identify which country won the most gold, most silver, most bronze medals and the most medals in each Olympic game.

WITH Medals AS(
SELECT Games, Region, COUNT(Medal) AS Total_Medals,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events a
JOIN noc_regions r
	ON a.NOC = r.NOC
GROUP BY Games, Region
ORDER BY Games, Region
),
rankings AS(
SELECT *,
DENSE_RANK() OVER(PARTITION BY games ORDER BY Gold_Medals DESC) AS Gold_Rank,
DENSE_RANK() OVER(PARTITION BY games ORDER BY Silver_Medals DESC) AS Silver_Rank,
DENSE_RANK() OVER(PARTITION BY games ORDER BY Bronze_Medals DESC) AS Bronze_Rank,
DENSE_RANK() OVER(PARTITION BY games ORDER BY Total_Medals DESC) AS Overall_Rank
FROM Medals
)
SELECT Games,
MAX(CASE WHEN Gold_Rank = 1 THEN region END) AS Most_Gold,
MAX(CASE WHEN Silver_Rank = 1 THEN region END) AS Most_Silver,
MAX(CASE WHEN Bronze_Rank = 1 THEN region END) AS Most_Bronze,
MAX(CASE WHEN Overall_Rank = 1 THEN region END) AS Overall
FROM rankings
GROUP BY Games
ORDER BY Games;

-- 18.	Which countries have never won gold medal but have won silver/bronze medals?
SELECT region,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_Medals,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_Medals,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_Medals
FROM athlete_events a
JOIN noc_regions r
	ON a.NOC = r.NOC
GROUP BY region
HAVING SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) = 0
	AND SUM(CASE WHEN Medal IN ('Silver','Bronze') THEN 1 ELSE 0 END) > 0;

-- 19.	In which Sport/event, India has won highest medals.
SELECT region, Sport, `Event`, Count(Medal) AS Medals_Won
FROM athlete_events a
JOIN noc_regions r
	ON a.NOC = r.NOC
Where region = 'India' AND Medal IS NOT NULL
GROUP BY Sport, `Event`
ORDER BY Count(Medal) DESC
LIMIT 1;

-- 20.	Break down all Olympic games where India won medal for Hockey and how many medals in each Olympic games.
SELECT Games, Count(Medal) Medals_Won
FROM athlete_events a
JOIN noc_regions r
	ON a.NOC = r.NOC
Where region = 'India'
	AND Sport = 'Hockey'
	AND Medal IS NOT NULL
GROUP BY Games
ORDER BY Games;