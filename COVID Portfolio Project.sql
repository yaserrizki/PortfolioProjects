SELECT *
FROM CovidDeaths
--WHERE continent is NULL --> Shows the 'location' data of Continents
WHERE continent is NOT NULL --> Shows the 'location' data of Countries
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are gonna be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL

-- [Total Cases vs Total Deaths]
SELECT location, date, total_cases, total_deaths
FROM CovidDeaths
WHERE continent is NOT NULL

-- Likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%states%' AND continent is NOT NULL

-- [Total Cases vs Population]
-- Shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasesPerPopulation
FROM CovidDeaths
WHERE location like '%states%' AND continent is NOT NULL

-- Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfection, MAX((total_cases/population))*100 AS PopulationInfectedPercentage
FROM CovidDeaths
--WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC

-- Countries with highest death compared to population
SELECT location, population, MAX(total_deaths) AS TotalDeathCount, MAX((total_deaths/population))*100 AS PopulationDeathPercentage
FROM CovidDeaths
--WHERE location like '%states%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PopulationDeathPercentage DESC

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount --> convert 'total_deaths' datatype to int (integer)
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAK THINGS DOWN BY CONTINENT
-- This below queries shows the data continet is also part of country/location (it's not supposed to be that)
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount --> convert 'total_deaths' datatype to int (integer)
FROM CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount --> convert 'total_deaths' datatype to int (integer)
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations
-- These queries are just give you the total sum of vaccinated people for each country (location)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location)
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location) --> alternative way to convert to integer
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- These queries will give you the cummulative of total sum of vaccinated people for each country (location) as the day progress 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cum_sum_vacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL --AND dea.location LIKE '%Indonesia%'
ORDER BY 2,3

-- Using the queries above with CTE
WITH PopVsVac AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cum_sum_vacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL --AND dea.location LIKE '%Indonesia%'
--ORDER BY 2,3
)

SELECT *, (cum_sum_vacc / population)*100 AS cum_sum_vacc_percentage
FROM PopVsVac


--Using the queries with Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cum_sum_vacc numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cum_sum_vacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (cum_sum_vacc / population)*100 AS cum_sum_vacc_percentage
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cum_sum_vacc
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated