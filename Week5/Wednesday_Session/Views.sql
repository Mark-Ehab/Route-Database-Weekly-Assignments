/*=====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/*===========================================================================================
	1) Create a view that displays basic user information including
       - their display name, reputation, location, and account creation date.
       - Name the view: vw_BasicUserInfo
       - Test the view by selecting all records from it
=============================================================================================*/
-- Create a standard simple view called vw_BasicUserInfo
GO
CREATE OR ALTER VIEW vw_BasicUserInfo (Username,
                                       UserReputation,
                                       UserLocation,
                                       UserAccountCreationDate)
WITH SCHEMABINDING,ENCRYPTION
AS
    SELECT DisplayName,
           Reputation,
           [Location],
           CreationDate
    FROM DBO.Users

-- Test the created view by selecting all records from it
GO
SELECT *
FROM vw_BasicUserInfo

/*===========================================================================================
	2) Create a view that shows all posts with their titles, scores,
       - view counts, and creation dates where the score is greater than 10.
       - Name the view: vw_HighScoringPosts
       - Test by querying posts from this view.
=============================================================================================*/
-- Create a standard simple view called vw_HighScoringPosts
GO
CREATE OR ALTER VIEW vw_HighScoringPosts (PostTitle,
                                          PostScore,
                                          PostViewCount,
                                          PostCreationDate)
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT Title,
           Score,
           ViewCount,
           CreationDate
    FROM DBO.Posts
    WHERE Title IS NOT NULL 
          AND Score > 10
    WITH CHECK OPTION;

-- Test by querying posts from the created view
GO
SELECT *
FROM vw_HighScoringPosts 
ORDER BY PostScore ASC

/*===========================================================================================
	3) Create a view that combines data from Users and Posts tables.
       - Show the post title, post score, author name, and author reputation.
       - Name the view: vw_PostsWithAuthors
       - This is a complex view involving joins
=============================================================================================*/
-- Create a standard complex view called vw_PostsWithAuthors
GO
CREATE OR ALTER VIEW vw_PostsWithAuthors (PostTitle,
                                          PostScore,
                                          AuthorName,
                                          AuthorReputation)
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT P.Title,
           P.Score,
           U.DisplayName,
           U.Reputation
    FROM DBO.Posts AS P
    INNER JOIN DBO.Users AS U
    ON P.OwnerUserId = U.Id
    WHERE P.Title IS NOT NULL
    WITH CHECK OPTION;

-- Test the created view by selecting all records from it
GO    
SELECT *
FROM vw_PostsWithAuthors
ORDER BY PostScore ASC

/*===========================================================================================
	4) Create a view that aggregates comment statistics per post.
       - Include: PostId, total comment count, sum of comment scores,
       - and average comment score.
       - Name the view: vw_PostCommentStats
       - This is a complex view with aggregation
=============================================================================================*/
-- Create a standard complex view called vw_PostCommentStats
GO
CREATE OR ALTER VIEW vw_PostCommentStats (PostId,
                                          TotalComments,
                                          TotalCommentsScore,
                                          AverageCommentScore)
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT P.Id,
           COUNT(*),
           SUM(C.Score),
           ROUND(AVG(CAST(C.Score AS DECIMAL(10,2))),2)
    FROM DBO.Posts AS P
    INNER JOIN DBO.Comments AS C
    ON C.PostId = P.Id
    GROUP BY P.Id

-- Test the created view by selecting all records from it
GO    
SELECT *
FROM vw_PostCommentStats
ORDER BY TotalComments ASC

/*===========================================================================================
	5) Create an indexed view that shows user activity summaries.
       - Include: UserId, DisplayName, Reputation, total posts count.
       - Name the view: vw_UserActivityIndexed
       - Make it an indexed view with a unique clustered index on UserId
=============================================================================================*/
-- Create an indexed (materialized) view called vw_UserActivityIndexed
GO
CREATE OR ALTER VIEW vw_UserActivityIndexed (UserId,
                                             Username,
                                             UserReputation,
                                             TotalPostsPerUser)
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT U.Id,
           U.DisplayName,
           U.Reputation,
           COUNT_BIG(*)
    FROM DBO.Users AS U
    INNER JOIN DBO.Posts AS P
    ON P.OwnerUserId = U.Id
    GROUP BY U.Id,
             U.DisplayName,
             U.Reputation

-- Create Unique Clustered Index on UserId Column on vw_UserActivityIndexed to make it Indexed (Materialized)
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_UserActivityIndexed_UserId
ON vw_UserActivityIndexed(UserId)

-- Test the created indexed (materialized) view by selecting all records from it
GO    
SELECT *
FROM vw_UserActivityIndexed

/*===========================================================================================
	6) Create a partitioned view that combines high reputation users
       - (reputation > 5000) and low reputation users (reputation <= 5000)
       - from the same Users table using UNION ALL.
       - Name the view: vw_UsersPartitioned
=============================================================================================*/
/*-------------------------------------------------------------------------------------
  Separate high reputation users and low reputation users into two different physical
  tables on the StackOverflow2010 Database before creation of vw_UsersPartitioned 
  partinioned view to put CHECK constraint on Reptation column of each created table and
  benefit from MS SQL Server Intelligent Data Retrival on Partitioned views 
--------------------------------------------------------------------------------------*/
-- Create a table called HighReputationUsers in DBO schema
GO
CREATE TABLE HighReputationUsers 
(
    Id INT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Reputation INT NOT NULL CHECK (Reputation > 5000),
    [Location] VARCHAR(100),
    UserRegisterationDate DATETIME2 NOT NULL
)

-- Create a table called LowReputationUsers in DBO schema
GO
CREATE TABLE LowReputationUsers 
(
    Id INT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Reputation INT NOT NULL CHECK (Reputation <= 5000),
    [Location] VARCHAR(100),
    UserRegisterationDate DATETIME2 NOT NULL
)

-- Populate HighReputationUsers from Users table where (reputation > 5000)
GO
INSERT INTO HighReputationUsers
SELECT Id,
       DisplayName,
       Reputation,
       [Location],
       CreationDate
FROM Users
WHERE Reputation > 5000

-- Populate LowReputationUsers from Users table where (reputation <= 5000)
INSERT INTO LowReputationUsers
SELECT Id,
       DisplayName,
       Reputation,
       [Location],
       CreationDate
FROM Users
WHERE Reputation <= 5000

-- Test if both table are successfully populated with data
SELECT * FROM HighReputationUsers
SELECT * FROM LowReputationUsers

-- Create a partitioned view called vw_UsersPartitioned
GO
CREATE OR ALTER VIEW vw_UsersPartitioned
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT Id,
           Username,
           Reputation,
           [Location],
           UserRegisterationDate
    FROM DBO.HighReputationUsers -- Users whose reputations are greater than 5000
    UNION ALL
    SELECT Id, 
           Username,
           Reputation,
           [Location],
           UserRegisterationDate
    FROM DBO.LowReputationUsers  -- Users whose reputation are less than or equal 5000

-- Test the created partioned view
GO    
SELECT *
FROM vw_UsersPartitioned

SELECT *
FROM vw_UsersPartitioned
WHERE Reputation > 5000

SELECT *
FROM vw_UsersPartitioned
WHERE Reputation <= 5000

/*===========================================================================================
	7) Create an updatable view on the Users table that shows
       - UserId, DisplayName, and Location.
       - Test the view by updating a user's location through the view.
       - Name the view: vw_EditableUsers
=============================================================================================*/
-- Create a standard simple view called vw_EditableUsers
GO
CREATE OR ALTER VIEW vw_EditableUsers (UserId,
                                       Username,
                                       UserLocation)
WITH SCHEMABINDING,ENCRYPTION
AS
    SELECT Id,
           DisplayName,
           [Location]
    FROM DBO.Users

-- Test the created view by updating a specific user's location through the view
GO
SELECT *
FROM vw_EditableUsers

UPDATE vw_EditableUsers
SET UserLocation = 'San Diego, CA'
WHERE UserId = 8

/*===========================================================================================
	8) Create a view with CHECK OPTION that only shows posts with
       - score greater than or equal to 20.
       - Name the view: vw_QualityPosts
       - Ensure that any updates through this view maintain the score >= 20
         condition .
=============================================================================================*/
-- Create a standard simple view called vw_EditableUsers
GO
CREATE OR ALTER VIEW vw_QualityPosts (PostId,
                                      PostTitle,
                                      PostScore)
WITH SCHEMABINDING,ENCRYPTION
AS
    SELECT Id,
           Title,
           Score
    FROM DBO.Posts
    WHERE Score >= 20
    WITH CHECK OPTION;

-- Ensure that any updates through this view maintain the score >= 20 condition
GO
SELECT * 
FROM vw_QualityPosts
WHERE PostId = 18

-- Valid
UPDATE vw_QualityPosts
SET PostScore = 10
WHERE PostId = 18

-- Not Valid
UPDATE vw_QualityPosts
SET PostScore = 79
WHERE PostId = 18

/*===========================================================================================
	9) Create a complex view that shows comprehensive post information
       - including post details, author information, and comment count.
       - Include: PostId, Title, Score, AuthorName, AuthorReputation,
         CommentCount.
=============================================================================================*/
-- Create a standard complex view called vw_ComprehensivePostInformation
GO
CREATE OR ALTER VIEW vw_ComprehensivePostInformation (PostId,
                                                      PostTitle,
                                                      PostScore,
                                                      AuthorName,
                                                      AuthorReputation,
                                                      CommentCountPerPost)
WITH SCHEMABINDING, ENCRYPTION
AS 
    SELECT P.Id,
           P.Title,
           P.Score,
           U.DisplayName,
           U.Reputation,
           COUNT(C.Id)
    FROM DBO.Posts AS P
    INNER JOIN DBO.Users AS U
    ON P.OwnerUserId = U.Id
    LEFT JOIN DBO.Comments AS C
    ON C.PostId = P.Id
    GROUP BY P.Id,
             P.Title,
             P.Score,
             U.DisplayName,
             U.Reputation

-- Test the created standard complex view by selecting all records from it
GO
SELECT *
FROM vw_ComprehensivePostInformation

/*===========================================================================================
	10) Create a view that shows badge statistics per user.
        - Include: UserId, DisplayName, Reputation, total badge count,
        - and a list of unique badge names (comma-separated if possible,
        - or just the count for simplicity).
        - Name the view: vw_UserBadgeStats .
=============================================================================================*/
-- Create a standard complex view called vw_UserBadgeStats
GO
CREATE OR ALTER VIEW vw_UserBadgeStats (UserId,     
                                        Username,
                                        UserReputation,
                                        TotalBadgeCountPerUser,
                                        TotalUniqueBadgeCountPerUser,
                                        BadgeNamesEarnedPerUser)
WITH SCHEMABINDING, ENCRYPTION
AS 
    SELECT U.Id,     
           U.DisplayName,
           U.Reputation,
           (
                SELECT COUNT(*)
                FROM DBO.Badges
                WHERE UserId = U.Id
           ),
           COUNT(B.[Name]),
           STRING_AGG(CAST(B.[Name] AS VARCHAR(MAX)),',')
    FROM DBO.Users AS U
    INNER JOIN 
    (
        SELECT DISTINCT UserId,
                        [Name]
        FROM DBO.Badges
    ) AS B
    ON B.UserId = U.Id
    GROUP BY U.Id,     
             U.DisplayName,
             U.Reputation

-- Test the created standard complex view by selecting all records from it
GO
SELECT *
FROM vw_UserBadgeStats

/*===========================================================================================
	11) Create a view that shows only active users (those who have
        - posted in the last 365 days from today, or have a reputation > 1000).
        - Include: UserId, DisplayName, Reputation, LastActivityDate
        - Name the view: vw_ActiveUsers.
=============================================================================================*/
-- Create a standard complex view called vw_ActiveUsers
GO
CREATE OR ALTER VIEW vw_ActiveUsers (UserId,
                                     Username,
                                     UserReputation,
                                     UserLastPostActivityDate)
WITH SCHEMABINDING, ENCRYPTION
AS
    SELECT U.Id,
           U.DisplayName,
           U.Reputation,
           P.LastUserPost
    FROM DBO.Users AS U
    INNER JOIN 
    (
        SELECT OwnerUserId,
               MAX(LastActivityDate) AS LastUserPost
        FROM DBO.Posts 
        GROUP BY OwnerUserId
    ) AS P
    ON P.OwnerUserId = U.Id
    WHERE U.Reputation > 1000
          OR DATEDIFF(DAY,P.LastUserPost,SYSDATETIME()) <= 365
    WITH CHECK OPTION;

-- Test the created standard complex view by selecting all records from it
GO
SELECT *
FROM vw_ActiveUsers

/*===========================================================================================
	12) Create an indexed view that calculates total views and average
        - score per user from their posts.
        - Include: UserId, TotalPosts, TotalViews, AvgScore
        - Name the view: vw_UserPostMetrics
        - Create a unique clustered index on UserId
=============================================================================================*/
-- Create an indexed (materialized) view called vw_UserPostMetrics
GO
CREATE OR ALTER VIEW vw_UserPostMetrics (UserId,
                                         TotalPostsPerUser,
                                         TotalPostsViewsPerUser,
                                         TotalPostsScoresPerUser)
WITH SCHEMABINDING,ENCRYPTION
AS 
    SELECT OwnerUserId,
           COUNT_BIG(*),
           SUM(ViewCount),
           SUM(CAST(Score AS DECIMAL(10,2)))
    FROM DBO.Posts
    GROUP BY OwnerUserId

-- Create a unique clustered index on UserId column of vw_UserPostMetrics to make it indexed (materialized)
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_UserPostMetrics_UserId 
ON vw_UserPostMetrics(UserId)

-- Test the created indexed (materialized) view through querying all records from it
SELECT UserId,
       TotalPostsPerUser,
       TotalPostsViewsPerUser,
       ROUND((TotalPostsScoresPerUser / TotalPostsPerUser),2) AS AveragePostsScorePerUser
FROM vw_UserPostMetrics
        
/*===========================================================================================
	13) Create a view that categorizes posts based on their score ranges.
        - Categories: 'Excellent' (>= 100), 'Good' (50-99), 'Average' (10-49),
          'Low' (< 10)
        - Include: PostId, Title, Score, Category
        - Name the view: vw_PostsByCategory
=============================================================================================*/
-- Create a standard simple view called vw_PostsByCategory
GO
CREATE OR ALTER VIEW vw_PostsByCategory (PostId,
                                         PostTitle,
                                         PostScore,
                                         PostCategory)
WITH SCHEMABINDING, ENCRYPTION
AS 
    SELECT Id,
           Title,
           Score,
           CASE
                WHEN Score >= 100 THEN 'Excellent'
                WHEN Score >= 50 AND Score <= 99 THEN 'Good'
                WHEN Score >= 10 AND Score <= 49 THEN 'Averge'
                ELSE 'Low'
           END
    FROM DBO.Posts

-- Test the created standard simple view by selecting all records from it
GO
SELECT *
FROM vw_PostsByCategory