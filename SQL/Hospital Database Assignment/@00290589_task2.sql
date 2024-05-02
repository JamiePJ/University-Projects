USE master
GO

-- create database before importing flat files
CREATE DATABASE FoodserviceDB;
GO

USE FoodserviceDB
GO

-- add Primary Keys
ALTER TABLE Restaurant
	ADD PRIMARY KEY (Restaurant_ID)

ALTER TABLE Consumers
	ADD PRIMARY KEY (Consumer_ID)

ALTER TABLE Ratings
	ADD PRIMARY KEY (Restaurant_ID, Consumer_ID)

-- add Foreign Keys
ALTER TABLE Ratings
	ADD FOREIGN KEY (Consumer_ID)
		REFERENCES Consumers (Consumer_ID)

ALTER TABLE Ratings
	ADD FOREIGN KEY (Restaurant_ID)
		REFERENCES Restaurant (Restaurant_ID)

ALTER TABLE Restaurant_Cuisines
	ADD FOREIGN KEY (Restaurant_ID)
		REFERENCES Restaurant (Restaurant_ID)
GO

-- Part 2
-- Q1) write a query that lists all restaurants with Medium range price with open area, serving Mexican food
SELECT r.Restaurant_ID,
				r.Name,
				r.Price,
				r.Area,
				rc.Cuisine
FROM Restaurant AS r
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
WHERE r.Price = 'Medium' AND
				r.Area = 'Open' AND 
				rc.Cuisine = 'Mexican'
GO

-- Q2) query that returns total number of restaurants with overall rating 1 and serving Mexican food. 
SELECT COUNT(DISTINCT r.Name) AS NumMexicanRestaurants
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID = ra.Restaurant_ID
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
WHERE rc.Cuisine = 'Mexican' and ra.Overall_Rating = 1

-- Compare with total number of restaurants with overall rating 1 and serving Italian food
SELECT COUNT(DISTINCT r.Name) AS NumItalianRestaurants
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID = ra.Restaurant_ID
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
WHERE rc.Cuisine = 'Italian' and ra.Overall_Rating = 1

-- query for number of overall_ratings where 1 was given
SELECT rc.Cuisine,
				COUNT(*) AS NumberOfOverallRatings1,
				ROUND(CAST(COUNT(*) AS float) / CAST(COUNT(Distinct r.Name) AS float), 2) AS OneRatingsPerRestaurant
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID = ra.Restaurant_ID
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
WHERE ra.Overall_Rating = 1
GROUP BY rc.Cuisine
HAVING rc.Cuisine = 'Mexican' OR
				rc.Cuisine = 'Italian'
ORDER BY NumberOfOverallRatings1 DESC;

-- Q3) calculate average age of consumers who have given 0 to Service_Rating - round if decimal
SELECT ROUND(AVG(Age), 0) AS AvgAgeConsumersServiceRating0
FROM Consumers AS c
INNER JOIN Ratings AS r
ON c.Consumer_ID = r.Consumer_ID
WHERE r.Service_Rating = 0

-- Q4) query returns restaurants ranked by youngest consumer, including restaurant name and food rating given by that consumer. Sort results based on food rating high to low
SELECT r.Name,
				c.Consumer_ID,
				c.Age, 
				ra.Food_Rating
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID =ra.Restaurant_ID
INNER JOIN Consumers AS c
ON c.Consumer_ID = ra.Consumer_ID
WHERE c.Age = (SELECT MIN(Age)
								FROM Consumers)
ORDER BY ra.Food_Rating DESC;
GO

-- Q5) stored procedure for query - Update Service_Rating for all restaurants to '2' if they have parking available ('yes' or 'public')
CREATE OR ALTER PROCEDURE UpdateServiceRating
	AS BEGIN
	UPDATE Ratings
	SET Service_Rating = 2
	WHERE Restaurant_ID IN (SELECT Restaurant_ID
															FROM Restaurant AS r
															WHERE r.Parking = 'Yes' OR
																r.Parking = 'Public')
	END
GO

-- view Service_Rating before executing stored procedure
SELECT r.Restaurant_ID,
				ra.Consumer_ID,
				r.Parking,
				ra.Service_Rating
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID = ra.Restaurant_ID
WHERE r.Parking = 'Yes' OR
	r.Parking = 'Public'
GO

-- execute stored procedure
EXEC UpdateServiceRating
GO

-- view Service_Rating after executing stored procedure
SELECT r.Restaurant_ID,
				ra.Consumer_ID,
				r.Parking,
				ra.Service_Rating
FROM Restaurant AS r
INNER JOIN Ratings AS ra
ON r.Restaurant_ID = ra.Restaurant_ID
WHERE r.Parking = 'Yes' OR
	r.Parking = 'Public'
GO

-- Q6) four queries that use at least once - EXISTS, IN, system functions, GROUP BY/HAVING/ORDER BY clauses
-- query 1) find top 10 restaurant cuisines with the highest average food_rating
SELECT TOP 10 
				rc.Cuisine,
				ROUND(AVG(CAST(ra.Food_Rating AS float)),2) AS AvgFoodRating
FROM Restaurant_Cuisines AS rc
INNER JOIN Ratings AS ra
ON rc.Restaurant_ID = ra.Restaurant_ID
GROUP BY rc.Cuisine
ORDER BY AvgFoodRating DESC
GO

-- query 2) find average overall_rating for "seafood" restaurants for each consumer with "Kids" in the "Children" column, ordered by average overall rating descending
SELECT r.Consumer_ID,
				rc.Cuisine,
				ROUND(AVG(CAST(r.Overall_Rating AS float)), 2) AS AverageOverallRating
FROM Ratings AS r
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
WHERE rc.Cuisine = 'Seafood' AND 
				r.Consumer_ID IN (SELECT Consumer_ID
												FROM Consumers
												WHERE Children = 'Kids')
GROUP BY r.Consumer_ID, 
					rc.Cuisine
ORDER BY AverageOverallRating DESC
GO

-- query 3) find details for consumers who have given a rating to American restaurants, sorted by consumer age in descending order
SELECT DISTINCT Consumer_ID,
				(City + ', ' + State + ', ' + Country) AS ConsumerLocation,
				ISNULL(Smoker, 'Unknown') AS Smoker,
				Drink_Level,
				ISNULL(Transportation_Method, 'Unknown') AS TransportationMethod, 
				ISNULL(Marital_Status, 'Unknown') AS MaritalStatus,
				ISNULL(Children, 'Unknown') AS Children,
				Age,
				ISNULL(Occupation, 'Unknown') AS Occupation,
				ISNULL(Budget, 'Unknown') AS Budget
FROM Consumers
WHERE EXISTS (SELECT 1
								FROM Ratings AS r
								INNER JOIN restaurant_cuisines AS rc
								ON r.Restaurant_ID = rc.Restaurant_ID
								WHERE r.Consumer_ID = Consumers.Consumer_ID AND rc.Cuisine = 'American')
ORDER BY Age DESC
GO

-- query 4) view average ratings for restaurants that allow smoking of any kind
SELECT r.Name,
				r.Smoking_Allowed,
				ROUND(AVG(CAST(ra.Overall_Rating AS float)), 2) AS AverageOverallRating,
				ROUND(AVG(CAST(ra.Food_Rating AS float)), 2) AS AverageFoodRating,
				ROUND(AVG(CAST(ra.Service_rating AS float)), 2) AS AverageServiceRating
FROM Restaurant AS r
INNER JOIN Restaurant_Cuisines AS rc
ON r.Restaurant_ID = rc.Restaurant_ID
INNER JOIN Ratings AS ra
ON ra.Restaurant_ID = r.Restaurant_ID
GROUP BY r.Name,
						r.Smoking_Allowed
HAVING r.Smoking_Allowed != 'No'
ORDER BY AverageOverallRating DESC
GO