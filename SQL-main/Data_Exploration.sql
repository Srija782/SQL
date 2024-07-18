use Portfolio_project
select * from Portfolio_project.dbo.CovidDeaths
where continent is not NULL

--select top 10 * from Portfolio_project.dbo.CovidVaccinations order by 3,4

--select data that we are going to use
select location,date,total_cases,new_cases,total_deaths,population
from dbo.CovidDeaths order by 1,2

--Looking for Totaldeaths vs Total cases
--show us the likelihood of death in your country
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths 
--where location like '%states%'
where continent is not NULL
order by 1,2

--Looking at Total Cases vs Population
select location,date,total_cases,population,(total_cases/population)*100 as CasesPercent
from dbo.CovidDeaths 
--where location like '%states%'
order by 1,2

--Looking at the countries which has highest infection rate
select location,max(total_cases) as HighestInfectionCount,max(total_cases/population)*100 as percentPopulation
from dbo.CovidDeaths 
group by location
order by 3 desc

--Looking at the countries which has highest death count per population
select location,max(cast(total_deaths as int)) as DeathCount
from dbo.CovidDeaths 
where continent is not null
group by location
order by 2 desc

--Looking at the countries which has highest death count per population
select continent,max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths 
where continent is not null
group by continent
order by TotalDeathCount desc

--Global numbers
select sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from covidDeaths
where continent is not null
--group by date
order by 1,2


--Use CTE for vac vs pop
With VacvsPop(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as(
-- Looking at total population Vs. Vaccinated

select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
from CovidVaccinations v 
join CovidDeaths d
	on v.location=d.location
	and v.date = d.date
where d.continent is not null
--order by 2,3
)
select location,(RollingPeopleVaccinated/population)*100  from VacvsPop 

--with Temp Table
drop table if exists #PercentPopvaccinated
create table #PercentPopvaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopvaccinated
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
from CovidVaccinations v 
join CovidDeaths d
	on v.location=d.location
	and v.date = d.date
--where d.continent is not null
--order by 2,3
select *,(RollingPeopleVaccinated/population)*100  from #PercentPopvaccinated 



-- creating views to store data for later visualizations

create view PercentPopvaccinated as
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(convert(int,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
from CovidVaccinations v 
join CovidDeaths d
	on v.location=d.location
	and v.date = d.date
where d.continent is not null
--order by 2,3
