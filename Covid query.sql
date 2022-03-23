---Looking at Countries with the highest cases and deaths, with the death percentage till date.

Select 
	Country_reg,
	MAX(Confirmed_cases) AS 'Total Cases',
	MAX(deaths) AS 'Total Deaths',
	CONCAT(ROUND(100*(MAX(Deaths)) / (MAX(Confirmed_Cases)),2), '%')
	AS 'Death Percentage'

From 
	covid_db

Group by country_reg
Order by 2 DESC, 3 DESC;

---The recovery rates by the top 50 countries of the world

Select	TOP 50 Country_reg, 
		MAX(Confirmed_cases) As 'Total Cases', 
		MAX(recovered) as 'Total Recoveries',
		CONCAT(ROUND(100*(MAX(recovered)) / (MAX(confirmed_cases)),2), '%') as '% of Recovered'
From covid_db
Group by Country_reg
Order by 3 DESC, 4 DESC;

--[India leads the recovery rates in the world]

---Which countries had the most recoveries by August 2021? Listing the top 20

Select	country_reg AS Countries,
		Months,
		Total_Recoveries
from
(Select country_reg,
		DATENAME(month,date) AS Months,
		MAX(recovered) As Total_Recoveries,
		RANK() OVER (Partition by DATENAME(month,date) Order by MAX(recovered) DESC) AS 'Rank1'
From covid_db
Where date = '2021-08-01'
Group by Country_Reg, DATENAME(month,date))
A Where Rank1 Between 1 AND 20
Group by Country_Reg, Months, Total_Recoveries;


---- Top 25 countries with highest vaccinations

Select TOP 25 country as Countries, 
MAX(total_vaccinations) AS Total_Vaccinations
from country_vaccinations$
Group by country
Order by 2 DESC;

---Which vaccines were most used by these countries from 2020-2022?

Select	Vacc_Year, 
		Countries, 
		Vaccinations, 
		Popular_Vaccines 
	from
	(Select DATENAME(Year, date) AS Vacc_Year,
		country as Countries,
		MAX(total_vaccinations) AS Vaccinations,
		vaccines as Popular_Vaccines,
		RANK() OVER (Partition by DATENAME(Year,date) ORDER BY MAX(Total_vaccinations) DESC) AS VaccRank
	From 
	dbo.country_vaccinations$
Group by country, vaccines, DATENAME(Year,date))

A Where VaccRank BETWEEN 1 and 25

Group by	Vacc_Year,
			Countries, 
			Vaccinations, 
			Popular_Vaccines

Order by 1 ASC;

----------
Select * from dbo.covid_db;
Select * from dbo.country_vaccinations$;

----- Countries currently struggling with Covid-19 as of March, 2022

Select 
		cov.Country_reg, 
		cov.Province, 
		MAX(vac.people_vaccinated) AS 'People Vaccinated',
		MAX(cov.active) AS 'Active Cases'
From 

	covid_db cov

JOIN

country_vaccinations$ vac 
		ON 
cov.country_reg = vac.country

AND cov.Date = vac.date

Group by cov.Country_Reg, cov.Province

Order by 4 DESC;

--#Countries are still struggling with the pandemic, even after successful vaccination campaigns.

Select * from dbo.covgdp;
Select * from dbo.covid_db;

---Looking at Recovered patients with respect to GDP Per capita.

Select 
		cov.Country_reg, 
		MAX(cov.recovered) AS 'Recoveries',
		ROUND(gd.gdp_per_capita,2) AS 'GDP Per Capita'

	From

covid_db cov
JOIN
covgdp gd ON cov.Country_Reg = gd.location
AND cov.date = gd.date
Group by	cov.country_reg, 
			gd.gdp_per_capita

Order by 2 DESC;

--# There seems to be no definitive, identifiable correlation between GDP Per Capita and Recoveries made.

---- Comparing male and female smoker percentage with the number of deaths.

Select	cov.country_reg, 
		MAX(cov.deaths) AS Deaths,
		MAX(gd.male_smokers) AS 'Male Smokers %',
		MAX(gd.female_smokers) AS 'Female Smokers %'
	From
covid_db cov
JOIN
covgdp gd ON cov.Country_Reg = gd.location
AND cov.date = gd.date
Group by cov.Country_Reg
Order by 2 DESC;

----BREAKING DOWN THINGS BY CONTINENT

-- Looking at the Case and Death count per Continent

Select	gd.continent AS Continent, 
		MAX(cov.confirmed_cases) 'Confirmed cases', 
		MAX(cov.deaths) 'Deaths'

	From

covgdp gd
INNER JOIN
covid_db cov ON gd.location = cov.Country_Reg
AND gd.date = cov.date
Group by gd.continent
Order by 3 DESC;

--#North America dealt the best as their deaths are lower in proportion in comparison with their total cases





---Notes / Comments

---Exec sp_rename 'covid_19_clean_complete_2022$', 'covid_db';
--Select * from dbo.data_2$;
--Exec sp_rename 'data_2$', 'covgdp';

---Select * from dbo.covid_db;

--Use PortfolioProject;

---Data up till March 2022

--Importing country_vaccinations data file for vaccination records
--Importing covid_2022 data file to compare GDP and smokers count.

--Select * from dbo.country_vaccinations$;










