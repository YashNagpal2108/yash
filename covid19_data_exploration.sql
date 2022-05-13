/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--converting date into date data type
alter table PortfolioProject..CovidDeaths
alter column date date

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, cast(date as date) as Date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- total tests vs total cases
select location, date, total_tests, total_cases, convert(decimal(5,3), total_tests/total_cases) as testspercase
from PortfolioProject..CovidDeaths
where total_tests is not null
and total_cases is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_tests, total_cases,total_deaths, cast((total_deaths/total_cases)*100 as decimal(5,3)) as DeathPercentage, convert(decimal(5,3), total_tests/total_cases) as testspercase 
From PortfolioProject..CovidDeaths
Where location like '%india%'
and continent is not null 
and total_deaths is not null
and total_tests is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_tests, total_cases,  cast((total_cases/population)*100 as decimal(6,4)) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
where CAST((total_cases/population)*100 as decimal(6,4))>0.0000
and total_tests is not null
order by 1,2

      
-- Countries with Highest Infection Rate compared to Population

Select Location, Population, population_density , total_tests , MAX(total_cases) as HighestInfectionCount, cast(Max((total_cases/population)*100) as decimal(6,3))  as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, population_density, total_tests
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount, population, (MAX(cast(Total_deaths as int))/population)*100 as PercentPopulationDied
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location, population
order by PercentPopulationDied desc

-- countries with highest vaccination count
select location, SUM(CAST( new_vaccinations as numeric) )  as total_vaccination
from portfolioproject..CovidVaccinations
where continent is not null
group by location
order by 2 desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- showing continents with highest vaccinations

Select continent, sum(cast(new_vaccinations as int)) as Totalvaccinations
From PortfolioProject..CovidVaccinations
Where continent is not null 
Group by continent
order by totalvaccinations desc

-- GLOBAL NUMBERS

Select SUM(dea.new_cases) as total_cases, SUM(cast(dea.new_deaths as int)) as total_deaths, SUM(cast(dea.new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage, sum(cast(vac.new_vaccinations as numeric)) as totalvaccinations
From PortfolioProject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
on dea.location = vac.location
where dea.continent is not null 

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated, convert(decimal(7,4),SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)/dea.population)*100 as percentpopulationvaccinated 
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
AND vac.new_vaccinations is not null
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query to show percentage of population vaccinated

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as percentpopulationvaccinated
From PopvsVac
order by 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query
-- droping date and looking at latest total people vaccinated country wise

DROP Table if exists #PopulationVaccinated
Create Table #PopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)

Insert into #PopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND VAC.new_vaccinations IS NOT NULL
order by 3 desc

Select Location, Population, max(RollingVaccinations)  as totalvaccinations, max(RollingVaccinations/Population)*1000 as totalvaccinationsper1000people
From #PopulationVaccinated
group by Location, Population
order by totalvaccinations desc



-- Creating View to store data for later visualizations

Create View PopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
AND VAC.new_vaccinations IS NOT NULL


select * from PopulationVaccinated