-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Reusable SQL File for all Clinical Trial Years
-- MAGIC This notebook is fully rerunnable using the datasets for Clinical Trials from 2023, 2021 and 2020. <br>
-- MAGIC Please note that the RDD notebook must be fully run before this one, or the preprocessed .csv files will not have been created and saved to DBFS for use in this notebook. <br>
-- MAGIC Please choose the year for analysis by changing the <b> "year" </b> variable in the Python cell below ("Cmd 2") <b> and also </b> the <b> "trials_year" </b> variable in the SQL cell below that ("Cmd 3").

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # set year for analysis (from 2020, 2021 or 2023)
-- MAGIC year = '2023'
-- MAGIC
-- MAGIC # load csv saved from RDD notebook
-- MAGIC clinical_trials_df = spark.read.csv(f"/FileStore/tables/df_{year}.csv")
-- MAGIC
-- MAGIC # rename columns, different column names depending on number of columns
-- MAGIC if len(clinical_trials_df.columns) == 9:
-- MAGIC     clinical_trials_df = clinical_trials_df.toDF('Id', 'Sponsor', 'Status', 'Start', 'Completion', 'Type', 'Submission', 'Conditions', 'Interventions')
-- MAGIC else:
-- MAGIC     clinical_trials_df = clinical_trials_df.toDF("Id", "StudyTitle", "Acronym", "Status", "Conditions", "Interventions", "Sponsor", "Collaborators", "Enrolment", "FunderType", "Type", "StudyDesign", "Start", "Completion")
-- MAGIC
-- MAGIC # remove header row from DF
-- MAGIC clinical_trials_df = clinical_trials_df.filter(clinical_trials_df.Id != "Id")
-- MAGIC
-- MAGIC # create DF for companies from csv saved in RDD notebook
-- MAGIC companies_df = spark.read.csv("/FileStore/tables/companies_df.csv")
-- MAGIC companies_df = companies_df.toDF("Parent_Company")
-- MAGIC # filter to remove header row
-- MAGIC companies_df = companies_df.filter(companies_df.Parent_Company != "Parent_Company")
-- MAGIC
-- MAGIC # create temporary views for SQL queries
-- MAGIC clinical_trials_df.createOrReplaceTempView("ClinicalTrials")
-- MAGIC companies_df.createOrReplaceTempView("PharmaCompanies")

-- COMMAND ----------

-- set year for analysis (from 2020, 2021 or 2023) - please ensure this matches the "year" variable in the Python cell above
DECLARE OR REPLACE VARIABLE trials_year STRING;
SET VAR trials_year = '2023'

-- COMMAND ----------

-- store ClinicalTrials temporary view as permanent table
CREATE OR REPLACE TABLE default.ClinicalTrials
AS
SELECT *
FROM ClinicalTrials

-- COMMAND ----------

-- store companies temporary view as permanent table
CREATE OR REPLACE TABLE default.PharmaCompanies
AS
SELECT *
FROM PharmaCompanies

-- COMMAND ----------

SHOW TABLES

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 1
-- MAGIC How many distinct studies are in the dataset?

-- COMMAND ----------

-- find number of distinct studies
SELECT COUNT(DISTINCT Id) AS NumDistinctStudies
FROM default.ClinicalTrials

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 2
-- MAGIC List all types contained in the "Type" column with their frequencies, ordered from most frequent to least frequent

-- COMMAND ----------

SELECT Type,
      COUNT(*) AS NumPerType
FROM default.ClinicalTrials
GROUP BY Type
ORDER BY NumPerType DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 3
-- MAGIC List the top 5 conditions (from Conditions) with their frequencies.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE delimiter STRING;

-- COMMAND ----------

SET VARIABLE delimiter = (SELECT IF(trials_year = '2023', '[|]', '[,]'));

-- COMMAND ----------

SELECT delimiter

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW conditions_view AS
SELECT EXPLODE(SPLIT(Conditions, delimiter)) AS Conditions
FROM default.ClinicalTrials

-- COMMAND ----------

-- group the view by Conditions, then aggregate by count to show number of each condition to show the top 5 conditions with their frequencies
SELECT Conditions,
        COUNT(*) AS NumPerCondition
FROM conditions_view
GROUP BY Conditions
ORDER BY NumPerCondition DESC
LIMIT 5

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 4
-- MAGIC Find the 10 most common sponsors that are not pharmaceutical companies, along with the number of clinical trials they have sponsored. Assume that the pharma.csv dataset column "Parent Company" contains all possible pharmaceutical companies.

-- COMMAND ----------

-- find distinct pharma companies
SELECT DISTINCT Parent_Company AS PharmaCompany
FROM default.PharmaCompanies

-- COMMAND ----------

-- view sponsors that do not appear in the PharmaCompanies table, group by Sponsor and aggregate by count to view 10 most common sponsors that are not pharma companies, with the number of trials they have sponsored
SELECT Sponsor,
        COUNT(*) AS TrialsPerSponsor
FROM default.ClinicalTrials
WHERE Sponsor NOT IN (SELECT DISTINCT Parent_Company
                      FROM default.PharmaCompanies)
GROUP BY Sponsor
ORDER BY TrialsPerSponsor DESC
LIMIT 10

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Question 5
-- MAGIC Plot number of completed studies for each month in 2023. Include visualisation as well as table of values

-- COMMAND ----------

-- create variables for setting date format and status format
DECLARE OR REPLACE VARIABLE date_format_regex STRING;
DECLARE OR REPLACE VARIABLE status_format STRING;

-- COMMAND ----------

-- set date and status formats according to year
SET VARIABLE date_format_regex = (SELECT IF(trials_year = '2023', '(....-..)', '(...)'));
SET VARIABLE status_format = (SELECT IF(trials_year = '2023', 'COMPLETED', 'Completed'));

-- COMMAND ----------

-- check date and status formats
SELECT trials_year, date_format_regex, status_format

-- COMMAND ----------

-- table showing number of completed clinical trials per month for selected year
CREATE OR REPLACE TEMPORARY VIEW month_trials AS
SELECT 
  CASE
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-01') THEN 'Jan'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-02') THEN 'Feb'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-03') THEN 'Mar'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-04') THEN 'Apr'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-05') THEN 'May'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-06') THEN 'Jun'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-07') THEN 'Jul'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-08') THEN 'Aug'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-09') THEN 'Sep'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-10') THEN 'Oct'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-11') THEN 'Nov'
        WHEN regexp_extract(Completion, date_format_regex) = CONCAT(trials_year, '-12') THEN 'Dec'
        ELSE regexp_extract(Completion, date_format_regex) 
  END AS MonthOfYear,
  COUNT(*) AS TrialsPerMonth,
  CASE
        WHEN MonthOfYear = 'Jan' OR MonthOfYear = CONCAT(trials_year, '-01') THEN 1
        WHEN MonthOfYear = 'Feb' OR MonthOfYear = CONCAT(trials_year, '-02') THEN 2
        WHEN MonthOfYear = 'Mar' OR MonthOfYear = CONCAT(trials_year, '-03') THEN 3
        WHEN MonthOfYear = 'Apr' OR MonthOfYear = CONCAT(trials_year, '-04') THEN 4
        WHEN MonthOfYear = 'May' OR MonthOfYear = CONCAT(trials_year, '-05') THEN 5
        WHEN MonthOfYear = 'Jun' OR MonthOfYear = CONCAT(trials_year, '-06') THEN 6
        WHEN MonthOfYear = 'Jul' OR MonthOfYear = CONCAT(trials_year, '-07') THEN 7
        WHEN MonthOfYear = 'Aug' OR MonthOfYear = CONCAT(trials_year, '-08') THEN 8
        WHEN MonthOfYear = 'Sep' OR MonthOfYear = CONCAT(trials_year, '-09') THEN 9
        WHEN MonthOfYear = 'Oct' OR MonthOfYear = CONCAT(trials_year, '-10') THEN 10
        WHEN MonthOfYear = 'Nov' OR MonthOfYear = CONCAT(trials_year, '-11') THEN 11
        WHEN MonthOfYear = 'Dec' OR MonthOfYear = CONCAT(trials_year, '-12') THEN 12
  END AS MonthNumber
FROM default.ClinicalTrials
WHERE Status = status_format AND Completion LIKE CONCAT('%', trials_year, '%')
GROUP BY MonthOfYear
ORDER BY MonthNumber

-- COMMAND ----------

-- display table of completed trials per month in selected year, using month names
SELECT MonthOfYear,
        TrialsPerMonth
FROM month_trials

-- COMMAND ----------

-- display visualisation of completed trials per month in selected year, using month names
SELECT MonthOfYear,
        TrialsPerMonth
FROM month_trials

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Further Analysis 3
-- MAGIC The 2023 Clinical Trials dataset is the only one with information regarding "Enrolment" in each trial. <br>
-- MAGIC Please note the other years' datasets will not work in this section.

-- COMMAND ----------

-- find the top 10 completed trials with largest enrolment
SELECT Id,
        StudyTitle,
        Enrolment,
        Status,
        Conditions,
        Type,
        Start,
        Completion
FROM default.ClinicalTrials
WHERE Status = 'COMPLETED'
ORDER BY CAST(Enrolment AS int) DESC
LIMIT 10

-- COMMAND ----------

-- find total number of completed trials
SELECT COUNT(*) AS NumCompletedTrials
FROM default.clinicaltrials
WHERE Status = 'COMPLETED'

-- COMMAND ----------

-- find number of completed trials with null Enrolment values
SELECT COUNT(*) AS NumTrialsNullEnrolment
FROM default.clinicaltrials
WHERE Status = 'COMPLETED' AND Enrolment IS NULL

-- COMMAND ----------

-- find average enrolment for completed trials, with how many completed trials have enrolment greater and less than the average
SELECT (SELECT ROUND(AVG(CAST(Enrolment AS int)))
          FROM default.ClinicalTrials
          WHERE Status = 'COMPLETED')  AS AverageEnrolment,
        (SELECT COUNT(*)
          FROM default.ClinicalTrials 
          WHERE Status = 'COMPLETED' AND CAST(Enrolment AS int) > (SELECT AVG(CAST(Enrolment AS int))
                                          FROM default.ClinicalTrials
                                          WHERE Status = 'COMPLETED')) AS NumCompletedTrialsGreaterThanAverageEnrolment,
        (SELECT COUNT(*) 
          FROM default.ClinicalTrials 
          WHERE Status = 'COMPLETED' AND CAST(Enrolment AS int) < (SELECT AVG(CAST(Enrolment AS int))
                                          FROM default.ClinicalTrials
                                          WHERE Status = 'COMPLETED')) AS NumCompletedTrialsLessThanAverageEnrolment     

-- COMMAND ----------

-- find average enrolment for trials that have greater than average enrolment
SELECT ROUND(AVG(CAST(Enrolment AS int))) AS AvgEnrolmentForTrialsAboveAvg
FROM default.ClinicalTrials
WHERE Id IN (SELECT Id
              FROM default.ClinicalTrials 
              WHERE Status = 'COMPLETED' AND CAST(Enrolment AS int) > (SELECT AVG(CAST(Enrolment AS int))
                                              FROM default.ClinicalTrials
                                              WHERE Status = 'COMPLETED'))
