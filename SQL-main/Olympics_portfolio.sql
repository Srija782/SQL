--There are 2 csv files present in this zip file. The data contains 120 years of olympics history. There are 2 daatsets 
--1- athletes : it has information about all the players participated in olympics
--2- athlete_events : it has information about all the events happened over the year.(athlete id refers to the id column in athlete table)

--import these datasets in sql server and solve below problems:



select top 10 * from athlete_events

select top 10 * from athletes

--Descriptive Statistics
-- There are 135571 players in total and there are 1031 teams 


--select distinct(team) from athletes order by team asc

--1 which team has won the maximum gold medals over the years.

--Method 1
with cte as(
select e.*,a.id,a.team from athlete_events  e left join athletes a
on e.athlete_id = a.id
where medal = 'Gold')
select team, count(distinct event) from cte group by team
order by 2 desc

--Method 2:
select team,count(distinct event) as cnt from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by team
order by cnt desc

--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

with cte as(
select a.team as a_team,year,count(distinct event) as year_count,rank() over(partition by a.team order by count(distinct event) desc) as rn
from athlete_events  e
inner join athletes a
				on e.athlete_id = a.id where medal = 'Silver'
group by a.team,year
				--order by a_team
)
select a_team,sum(year_count),max(case when rn = 1 then year end) as max_year  from cte
group by a_team



--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years
with cte as(
select athlete_id, count(medal) as total_medals,count(case when medal = 'Gold' then medal end) as gold_medals,
count(case when medal in ('Silver','Bronze') then medal end) as other_medals
 from athlete_events  
group by athlete_id)

select top 1 * from cte join athletes a
on cte.athlete_id = a.id where total_medals = gold_medals
order by gold_medals desc

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.



with cte as(
select year,athlete_id, count(medal) as medal_count,dense_rank() over(partition by year order by count(medal) desc) as rn from athlete_events 
where medal = 'Gold'
group by year,athlete_id)

select year,string_agg(name,','),medal_count from cte join athletes on cte.athlete_id = athletes.id
where rn = 1
group by year,medal_count;


--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

with cte as(
select *, rank() over(partition by medal order by year) as rn from athlete_events ae join athletes a on ae.athlete_id=a.id
where team = 'India' and medal is not null
)
select distinct medal,year,event from cte where rn = 1;

--6 find players who won gold medal in summer and winter olympics both.
with cte as(
select distinct name,season, medal from athlete_events ae join athletes a on ae.athlete_id=a.id
where medal = 'Gold'
--order by name,medal,season
)
select name,count(*) from cte group by name
having count(*) > 1
order by 2 desc;

--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

select year,name,string_agg(medal,','),count(distinct medal) from athlete_events ae join athletes a on ae.athlete_id=a.id
where medal is not null
group by year,name
having count(distinct medal)=3

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

with cte as(

select *, count(*) over(partition by athlete_id,event)  as cnt from (select *,ROW_NUMBER() over(partition by athlete_id,event order by year) as rn,
lag(year,1) over(partition by athlete_id,event order by year) as prev_year,
lead(year,1) over(partition by athlete_id,event order by year) as next_year
from athlete_events ae join athletes a on ae.athlete_id=a.id
where year > =2000 and medal ='Gold' and season = 'Summer') a)

select * from cte 
where year = next_year-4 and year=prev_year+4 
order by athlete_id,event,year




