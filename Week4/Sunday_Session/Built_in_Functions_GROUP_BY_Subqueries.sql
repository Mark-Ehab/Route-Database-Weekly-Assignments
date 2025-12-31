/*=====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/*=====================================================
	1) Write a query to display all user display 
	   names in uppercase along with the length of 
	   their display name.
======================================================*/
SELECT UPPER(DisplayName) AS 'Display Name in Upper Case',
       LEN(DisplayName) AS 'Display Name Length'
FROM Users

/*=====================================================
	2) Write a query to show all posts with their 
	   titles and calculate how many days have passed 
	   since each post was created.Use DATEDIFF to 
	   calculate the difference from CreationDate to 
       today.
======================================================*/
SELECT Title AS 'Post Title', 
       DATEDIFF(DAY, CreationDate ,SYSDATETIME()) AS 'Days Passed Since Each Post was Created'
FROM Posts

/*=====================================================
	3) Write a query to count the total number of 
	   posts for each user.Display the OwnerUserId 
	   and the count of their posts.Only include users 
	   who have created posts.
======================================================*/
SELECT P.OwnerUserId AS 'Post Owner ID',
       COUNT(P.Id) AS 'Created Posts'
FROM Posts AS P
INNER JOIN Users AS U
ON P.OwnerUserId = U.Id
GROUP BY P.OwnerUserId

/*=====================================================
	4) Write a query to find users whose reputation 
	   is greater than the average reputation of all 
	   users. Display their DisplayName and Reputation. 
	   Use a subquery in the WHERE clause.
======================================================*/
SELECT DisplayName AS 'User Name',
       Reputation  AS 'User Reputation'
FROM Users
WHERE Reputation > (
						SELECT ROUND(AVG(Reputation * 1.0),0)
						FROM Users
				   ) 

/*=====================================================
	5) Write a query to display each post title along 
	   with the first 50 characters of the title. If 
	   the title is NULL, replace it with 'No Title'. 
	   Use SUBSTRING and ISNULL functions.
======================================================*/
SELECT ISNULL(Title,'No Title') AS 'Full Post Title',
       ISNULL(SUBSTRING(Title,1,50),'No Title') AS 'First 50 Characters Post Title'
FROM Posts

/*=====================================================
	6) Write a query to calculate the total score and 
	   average score for each PostTypeId. Also show 
	   the count of posts for each type.Only include 
	   post types that have more than 100 posts.
======================================================*/
SELECT PostTypeId,
       SUM(Score) AS 'Total Score',
       ROUND(AVG(Score * 1.0),0) AS 'Score Average',
	   COUNT(Id) AS 'Count of Posts'
FROM Posts
GROUP BY PostTypeId
HAVING COUNT(Id) > 100

/*=====================================================
	7) Write a query to show each user's DisplayName 
	   along with the total number of badges they have 
	   earned. Use a subquery in the SELECT clause to 
	   count badges for each user.
======================================================*/
SELECT DisplayName AS 'Username',
       (
		   SELECT COUNT(Id) 
		   FROM Badges AS B 
		   WHERE B.UserId = U.Id 
		   GROUP BY UserId
	   ) AS 'Total Number Badges Per User'
FROM Users AS U

/*=====================================================
	8) Write a query to find all posts where the title 
	   contains the word 'SQL'. Display the title, 
	   score, and format the CreationDate as 
	   'Mon DD, YYYY'.Use CHARINDEX and FORMAT 
	   functions
======================================================*/
SELECT Title AS 'Post Title',
	   Score AS 'Post Score',
	   FORMAT(CreationDate,'MMM dd, yyyy') AS 'Post Creation Date'
FROM Posts
WHERE Title IS NOT NULL AND CHARINDEX('SQL',Title) != 0

/*=====================================================
	9) Write a query to group comments by PostId and 
	   calculate:
       Total number of comments
       Sum of comment scores
       Average comment score
       Only show posts that have more than 5 comments.
======================================================*/
SELECT PostId,
       COUNT(Id) AS 'Total number of comments',
	   SUM(Score) AS 'Sum of comment scores',
	   ROUND(AVG(Score * 1.0),0) AS 'Average comment score'
FROM Comments
GROUP BY PostId
HAVING COUNT(Id) > 5
--ORDER BY COUNT(*) ASC

/*=====================================================
	10) Write a query to find all users whose location 
	    is not NULL.Display their DisplayName, Location, 
		and calculate their reputation level using 
		IIF:'High' if reputation> 5000, otherwise 
		'Normal'.
======================================================*/
SELECT DisplayName AS 'Username',
       [Location] AS 'User Location',
	   IIF(Reputation > 5000,'High','Normal') AS 'Reputation Level',
	   Reputation
FROM Users
WHERE [Location] IS NOT NULL
--ORDER BY Reputation ASC

/*=====================================================
	11) Write a query using a derived table (subquery 
	    in FROM) to:
		- First, calculate total posts and average score 
		  per user
        - Then, join with Users table to show DisplayName
        - Only include users with more than 3 posts
        The derived table must have an alias
======================================================*/
SELECT PostsOwners.OwnerUserId,
       U.DisplayName AS Username,
	   PostsOwners.TotalPostsPerUser,
	   PostsOwners.AverageScorePerUser
FROM
(
	SELECT OwnerUserId,
		   COUNT(Id) AS TotalPostsPerUser,
		   ROUND(AVG(Score * 1.0),0) AS AverageScorePerUser
	FROM Posts
	GROUP BY OwnerUserId
) AS PostsOwners
INNER JOIN Users AS U
ON PostsOwners.OwnerUserId = U.Id
WHERE PostsOwners.TotalPostsPerUser > 3
--ORDER BY PostsOwners.TotalPostsPerUser

/*=====================================================
	12) Write a query to group badges by UserId and 
	    badge Name.
        - Count how many times each user earned each 
		specific badge.
        Display UserId, badge Name, and the count.
        Only show combinations where a user earned 
		the same badge more than once
======================================================*/
SELECT UserId AS 'User ID',
       [Name] AS 'Badge Name',
	   COUNT(*) AS 'Badges Number Per User And Badge Name'
FROM Badges
GROUP BY UserId,[Name]
HAVING  COUNT(*) > 1
--ORDER BY UserId,COUNT(*)

/*=====================================================
	13) Write a query to display user information along 
	    with their account age in years. Use DATEDIFF 
		to calculate years between CreationDate and 
		current date. Round the result to 2 decimal 
        places.
        Also show the absolute value of their DownVotes.
======================================================*/
SELECT DisplayName AS 'Username',
	   [Location],
	   Reputation,
	   ROUND(DATEDIFF(YEAR,CreationDate,SYSDATETIME()),2) AS 'Account Age In Years',
	   ABS(DownVotes) AS 'Absolute Value of DownVotes'
	   --,DownVotes
FROM Users
--ORDER BY DownVotes ASC

/*=====================================================
	14) Write a complex query that:
        - Uses a derived table to calculate comment 
		  statistics per post
        - Joins with Posts and Users tables
        - Shows: Post Title, Author Name, Author 
		  Reputation,Comment Count, and Total Comment 
		  Score
        - Filters to only show posts with more than 
		  3 comments and post score greater than 10
        - Uses COALESCE to replace NULL author names 
		  with 'Anonymous'
======================================================*/
SELECT P.Title,
	   COALESCE(U.DisplayName,'Anonymous') AS AuthorName,
	   U.Reputation AS AuthorReputation,
	   CS.PostCommentsCount,
	   CS.PostTotalCommentScore
FROM
(
	SELECT PostId,
		   COUNT(*) AS PostCommentsCount,
		   SUM(Score) AS PostTotalCommentScore
	FROM Comments
	GROUP BY PostId
) AS CS
INNER JOIN Posts AS P
ON CS.PostId = P.Id
LEFT JOIN Users AS U
ON P.OwnerUserId = U.Id
WHERE CS.PostCommentsCount > 3 
	  AND P.Score > 10
ORDER BY CS.PostCommentsCount,
		 CS.PostTotalCommentScore