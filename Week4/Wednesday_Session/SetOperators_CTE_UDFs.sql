/*=====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/*==========================================================
	1) Retrieve a list of users who meet at least one of 
	   these criteria:
			1. Reputation greater than 8000
		    2. Created more than 15 posts
	   Display UserId, DisplayName, and Reputation.
	   Ensure that each user appears only once in the 
	   results.
==========================================================*/
SELECT Id AS 'User Id',
	   DisplayName,
	   Reputation
FROM Users
WHERE Reputation > 8000
UNION
SELECT U.Id,
       U.DisplayName,
	   U.Reputation
FROM Users AS U
INNER JOIN Posts AS P
ON P.OwnerUserId = U.Id
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING COUNT(P.Id) > 15;

/*==========================================================
	2) Find users who satisfy BOTH of these conditions
	   simultaneously:
			1. Have reputation greater than 3000
			2. Have earned at least 5 badges
	   Display UserId, DisplayName, and Reputation.
==========================================================*/
SELECT Id AS 'User Id',
	   DisplayName,
	   Reputation
FROM Users
WHERE Reputation > 3000
INTERSECT
SELECT U.Id,
       U.DisplayName,
	   U.Reputation
FROM Users AS U
INNER JOIN Badges AS B
ON B.UserId = U.Id
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING COUNT(B.Id) >= 5;

/*==========================================================
	3) Identify posts that have a score greater than 20 but
	   have never received any comments. Display PostId, 
	   Title, and Score.
==========================================================*/
SELECT Id AS 'Post Id',
       Title,
	   Score
FROM Posts
WHERE Score > 20
EXCEPT
SELECT P.Id,
       P.Title,
	   P.Score
FROM Posts AS P
INNER JOIN Comments AS C
ON C.PostId = P.Id
WHERE P.Score > 20;

/*==========================================================
	4) Create a new permanent table called Posts_Backup that 
	   stores all posts with a score greater than 10.
	   The new table should include: Id, Title, Score, 
	   ViewCount, CreationDate, OwnerUserId.
==========================================================*/
SELECT Id, 
       Title,
	   Score, 
	   ViewCount,
	   CreationDate,
	   OwnerUserId
INTO Posts_Backup
FROM Posts
WHERE Score > 10;

/*==========================================================
	5) Create a new table called ActiveUsers containing 
	   users who meet the following criteria:
			1. Reputation greater than 1000
			2. Have created at least one post
       The table should include: UserId, DisplayName, 
	   Reputation, Location, and PostCount (calculated).
==========================================================*/
SELECT U.Id AS 'User Id',
       U.DisplayName,
	   U.Reputation,
	   U.[Location],
	   COUNT(P.Id) AS 'Post Count'
INTO ActiveUsers
FROM Users AS U
INNER JOIN Posts AS P
ON P.OwnerUserId = U.Id
WHERE U.Reputation > 1000
GROUP BY U.Id,
		 U.DisplayName,
		 U.Reputation,
		 U.[Location]
HAVING COUNT(P.Id) >= 1;

/*==========================================================
	6) Create a new empty table called Comments_Template 
	   that has the exact same structure as the Comments 
	   table but contains no data rows.
==========================================================*/
SELECT *
INTO Comments_Template 
FROM Comments
WHERE 0 = 1;

/*==========================================================
	7) Create a summary table called PostEngagementSummary 
	   that combines data from Posts, Users, and Comments 
	   tables.
	   The table should include: PostId, Title, AuthorName, 
	   Score, ViewCount, CommentCount (calculated), 
	   TotalCommentScore (calculated)
	   Include only posts that have received at least 3
	   comments.
==========================================================*/
SELECT P.Id AS PostId,
	   P.Title,
	   U.DisplayName AS AuthorName,
	   P.Score,
	   P.ViewCount,
	   COUNT(C.Id) AS CommentCount,
	   SUM(C.Score) AS TotalCommentScore
INTO PostEngagementSummary
FROM Posts AS P
INNER JOIN Users AS U
ON P.OwnerUserId = U.Id
INNER JOIN Comments AS C
ON C.PostId = P.Id
GROUP BY P.Id,
		 P.Title,
		 U.DisplayName,
		 P.Score,
		 P.ViewCount
HAVING COUNT(C.Id) >= 3

/*==========================================================
	8) Develop a reusable calculation that determines the 
	   age of a post in days based on its creation date.
       Input: CreationDate (DATETIME)
       Output: Age in days (INTEGER)
       Test your solution by displaying posts with their 
	   calculated ages.
==========================================================*/
-- Create PostCreationAge Function in dbo Schema (Main)
GO
CREATE OR ALTER FUNCTION dbo.PostCreationAge(@CreationDate DATETIME)
RETURNS INT
AS
BEGIN
	DECLARE @Age INT;
	SET @Age = DATEDIFF(Day,@CreationDate,SYSDATETIME())
	RETURN @Age;
END;

-- Test the function on Posts Table
SELECT Id AS 'Post Id',
       dbo.PostCreationAge(CreationDate) AS 'Post Ages'
FROM Posts;

/*==========================================================
	9) Develop a reusable calculation that assigns a badge 
	   level to users based on their reputation and post 
	   activity.
       Inputs: Reputation (INT), PostCount (INT)
       Output: Badge level (VARCHAR)
       Logic:
       'Gold' if reputation > 10000 AND posts > 50
       'Silver' if reputation > 5000 AND posts > 20
       'Bronze' if reputation > 1000 AND posts > 5
       'None' otherwise
==========================================================*/
-- Create SetBadgeLevel Function in dbo Schema (Main)
GO
CREATE OR ALTER FUNCTION dbo.SetBadgeLevel(@Reputation INT, @PostCount INT)
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @BadgeLevel VARCHAR(10);
	IF(@Reputation > 10000 AND @PostCount > 50)
		SET @BadgeLevel = 'Gold'
	ELSE IF(@Reputation > 5000 AND @PostCount > 20)
		SET @BadgeLevel = 'Silver'
	ELSE IF(@Reputation > 1000 AND @PostCount > 5)
		SET @BadgeLevel = 'Bronze'
	ELSE
		SET @BadgeLevel = 'None'
	RETURN @BadgeLevel;
END;

-- Test the function on Posts and Users Tables
SELECT U.Id AS 'User ID',
	   U.Reputation,
	   COUNT(P.Id) AS PostCount,
	   dbo.SetBadgeLevel(U.Reputation,COUNT(P.Id)) AS 'Badge Level'
FROM Users AS U
INNER JOIN Posts AS P
ON P.OwnerUserId = U.Id
GROUP BY U.Id, U.Reputation;

/*==========================================================
	10) Develop a reusable query that retrieves posts 
	    created within a specified number of days from today.
        Input: @DaysBack (INT) - number of days to look back
        Output: Table with PostId, Title, Score, ViewCount,
		CreationDate
        Test with different day ranges (e.g., 30 days, 
		90 days).
==========================================================*/
-- Create GetPostsCreatedWithinSpecificPeriod Function in dbo Schema (Main)
GO
CREATE OR ALTER FUNCTION dbo.GetPostsCreatedWithinSpecificPeriod(@DaysBack INT)
RETURNS TABLE
AS 
RETURN
(
	SELECT Id AS PostID,
		   Title,
		   Score,
		   ViewCount,
		   CreationDate
	FROM Posts
	WHERE DATEDIFF(DAY,CreationDate,SYSDATETIME()) = @DaysBack 
)

-- Test the function
SELECT *
FROM dbo.GetPostsCreatedWithinSpecificPeriod(6362)

SELECT *
FROM dbo.GetPostsCreatedWithinSpecificPeriod(6229);

/*==========================================================
	11) Develop a reusable query that finds top users from a 
	    specific location or all locations based on 
		reputation threshold.
        Inputs: @MinReputation (INT), @Location (VARCHAR)
        Output: Table with UserId, DisplayName, Reputation, 
		Location, CreationDate
        If @Location is NULL, return users from all locations.
        Test with different parameters.
==========================================================*/
-- Create FindTopUsersFromSpecificLocationsV1 (MSTVF) Function in dbo Schema (Main)
GO
CREATE OR ALTER FUNCTION dbo.FindTopUsersFromSpecificLocationsV1(@MinReputation INT, @Location VARCHAR(100) = NULL)
RETURNS @TopUsersLocations TABLE
(
	UserId INT,
	DispalyName VARCHAR(50),
	Reputation INT,
	[Location] VARCHAR(100),
	CreationDate DATETIME2
)
AS 
BEGIN
	IF(@Location IS NULL)
		INSERT INTO @TopUsersLocations
		SELECT Id AS UserId,
			   DisplayName,
			   Reputation,
			   [Location],
			   CreationDate
		FROM Users
		WHERE Reputation >= @MinReputation
	ELSE
		INSERT INTO @TopUsersLocations
		SELECT Id AS UserId,
			   DisplayName,
			   Reputation,
			   [Location],
			   CreationDate
		FROM Users
		WHERE (Reputation >= @MinReputation AND @Location = [Location]) 
	RETURN
END;

-- Test the function
SELECT *
FROM dbo.FindTopUsersFromSpecificLocationsV1(1000 , 'Oakland, CA')

SELECT *
FROM dbo.FindTopUsersFromSpecificLocationsV1(1000,DEFAULT);

------------- Other Solution Using ITVF (Best for Performance) -------------

-- Create FindTopUsersFromSpecificLocationsV2 (ITVF) Function in dbo Schema (Main)
GO
CREATE OR ALTER FUNCTION dbo.FindTopUsersFromSpecificLocationsV2(@MinReputation INT, @Location VARCHAR(100) = NULL)
RETURNS TABLE
AS 
RETURN
(		
	SELECT Id AS UserId,
			   DisplayName,
			   Reputation,
			   [Location],
			   CreationDate
		FROM Users
		WHERE Reputation >= @MinReputation AND (@Location = [Location] OR @Location IS NULL) 
)

-- Test the function
SELECT *
FROM dbo.FindTopUsersFromSpecificLocationsV2(1000 , 'Oakland, CA')

SELECT *
FROM dbo.FindTopUsersFromSpecificLocationsV2(1000,DEFAULT);

/*==========================================================
	12) Write a query to find the top 3 highest scoring 
	    posts for each PostTypeId.
        Use a subquery or CTE with ROW_NUMBER() and 
		PARTITION BY.
        Display PostTypeId, Title, Score, and the rank.
==========================================================*/
WITH TopHighestScoringPosts AS
(
	SELECT PostTypeId,
		   Title,
		   Score,
		   ROW_NUMBER() OVER (PARTITION BY PostTypeId ORDER BY Score DESC) AS PostRank
	FROM Posts
)
SELECT *
FROM TopHighestScoringPosts
WHERE PostRank <= 3;

/*==========================================================
	13) Write a query using a CTE to find all users whose 
	    reputation is above the average reputation. 
		The CTE should calculate 
			1. the average reputation first.
			2. Display DisplayName, Reputation, and the 
			   average reputation.
==========================================================*/
WITH AverageReputation AS
(
	SELECT CAST(AVG(Reputation) AS DECIMAL(10,2)) AS AverageRep
	FROM Users
)
SELECT DisplayName,
	   Reputation,
	   AverageRep
FROM Users
CROSS JOIN AverageReputation
WHERE Reputation > AverageRep; 
--ORDER BY Reputation ASC

/*==========================================================
	14) Write a query using a CTE to calculate the total 
	    number of posts and average score for each user. 
	    Then join with the Users table to display: 
	    DisplayName, Reputation, TotalPosts, and AvgScore.
		Only include users with more than 5 posts.
==========================================================*/
WITH UserPostStats (OwnerUserId,TotalPostsPerUser, AveragePostScorePerUser) AS
(
	SELECT OwnerUserId,
		   COUNT(Id),
		   CAST(AVG(Score) AS DECIMAL(10,2))
	FROM Posts
	GROUP BY OwnerUserId
)
SELECT U.DisplayName,
	   U.Reputation,
	   UPS.TotalPostsPerUser,
	   UPS.AveragePostScorePerUser
FROM Users AS U
INNER JOIN UserPostStats AS UPS
ON UPS.OwnerUserId = U.Id
WHERE UPS.TotalPostsPerUser > 5;

/*==========================================================
	15) Write a query using multiple CTEs:
        First CTE: Calculate post count per user
        Second CTE: Calculate badge count per user
        Then join both CTEs with Users table to show:
        DisplayName, Reputation, PostCount, and BadgeCount.
        Handle NULL values by replacing them with 0.
==========================================================*/
WITH PostCountPerUser (OwnerUserId,PostCount) AS
(
	SELECT OwnerUserId,
		   COUNT(Id)
	FROM Posts
	GROUP BY OwnerUserId
),BadgeCountPerUser (UserId,BadgeCount) AS
(
	SELECT UserId,
		   COUNT(Id)
	FROM Badges
	GROUP BY UserId
)
SELECT U.DisplayName,
	   U.Reputation,
	   ISNULL(PCU.PostCount,0) AS PostCount,
	   ISNULL(BCU.BadgeCount,0) AS BadgeCount
FROM Users AS U
LEFT JOIN PostCountPerUser AS PCU
ON PCU.OwnerUserId = U.Id
LEFT JOIN BadgeCountPerUser AS BCU
ON BCU.UserId = U.Id;

/*==========================================================
	16) Write a recursive CTE to generate a sequence of 
	    numbers from 1 to 20. 
		Display the generated numbers.
==========================================================*/
GO
WITH NumberSequence AS
(
	-- Anchor
	SELECT 1 AS Number
	UNION ALL
	-- First Recursive Part (Only Recursive Part in this case)
	SELECT Number + 1
	FROM NumberSequence
	WHERE Number < 20
)
SELECT *
FROM NumberSequence;