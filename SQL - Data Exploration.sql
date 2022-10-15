/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--QUESTIONS TO ANALYZE
--- What is the likelihood of dying if a Nigerian contracts covid?
--- What percentage of each country's population is infected with Covid?
--- What countries have the Highest Infection Rate with respect to their Population?
--- What Countries have the Highest Death Count per Population?
--- What continents have the Highest Death Count per Population?


USE PortfolioProject; 
GO

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 3,4


-- Loading datASet

SELECT 
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

-- Looking at the likelihood of death after a Nigerian contracts covid

SELECT 
	Location, 
	date, 
	total_cases,
	total_deaths, 
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE 
	location = 'Nigeria'
	AND continent is not null 
ORDER BY 1,2


--  Showing the percentage of each country's population infected with Covid

SELECT 
	Location, 
	date, 
	Population, 
	total_cases,  
	(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--Where location = 'Nigeria'
ORDER BY 1,2


-- We want to know what countries have the Highest Infection Rate with respect to their Population

SELECT 
	Location, 
	Population, 
	MAX(total_cases) AS HighestInfectionCount,  
	Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY 
	Location, 
	Population
ORDER BY 
	PercentPopulationInfected desc


-- What countries have the Highest Death Count per Population?

SELECT 
	Location, 
	MAX(cASt(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY 
	Location
ORDER BY 
	TotalDeathCount desc



--- NOW WE WOULD BE BREAKING THINGS DOWN BY CONTINENT


-- Looking at contintents that have the highest death count per population?

SELECT 
	continent, 
	MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY 
	continent
ORDER BY 
	TotalDeathCount desc




-- What contintents have the highest infection count per population?
SELECT 
	continent, 
	MAX(total_cases) AS HighestInfectionCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY
	continent
ORDER BY
	HighestInfectionCount desc



-- GLOBAL NUMBERS

-- Total Deaths Globally
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS int)) AS total_deaths, 
	SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2

-- Total Deaths/CASes per day
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS int)) AS total_deaths, 
	SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY date
ORDER BY 1,2



-- Reviewing the Vaccinations table
SELECT * 
FROM CovidVaccinations
ORDER BY 3,4

-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT 
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (
		Partition by 
			dea.location
		ORDER BY 
			dea.location, 
			dea.date 
			) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (
		Partition by 
			dea.location
		ORDER BY 
			dea.location, 
			dea.date 
			) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	On dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
	SELECT 
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (
		Partition by 
			dea.location
		ORDER BY 
			dea.location, 
			dea.date 
			) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT 
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) 
		OVER (
		Partition by 
			dea.location
		ORDER BY 
			dea.location, 
			dea.date 
			) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 


CREATE VIEW TotalDeathCounPerLocation AS
 SELECT 
	location, 
	MAX(cast(Total_deaths as int)) AS TotalDeathCount
 FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY 
	location 
 --ORDER BY 
	--TotalDeathCount DESC


CREATE VIEW TotalDeathCounPerContinent AS
 SELECT 
	continent, 
	MAX(cast(Total_deaths as int)) AS TotalDeathCount
 FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY 
	continent 


-- Checking the Views
SELECT *
FROM PercentPopulationVaccinated
ORDER BY 1

SELECT *
FROM TotalDeathCounPerCountry
ORDER BY 1

SELECT *
FROM TotalDeathCounPerContinent
ORDER BY 1
