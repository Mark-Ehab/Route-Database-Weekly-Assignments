/*=====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/*===========================================================================================
	1) Optimize the performance of queries that search for posts by a specific
       user with a minimum score threshold, ordered by score.
       Example query pattern:
       "Find all posts by user 5 with score > 50, ordered by score descending"
       Tasks:
       a) Design and implement an appropriate index structure
       b) Ensure the index covers all columns needed by the query
       c) Write a test query that demonstrates the optimization
       d) Verify the index was created successfully
=============================================================================================*/

-- Example query pattern whose performance needs to be optimized
GO
SELECT OwnerUserId, 
       Score
FROM Posts
WHERE OwnerUserId = 5 
      AND Score > 50 
ORDER BY Score DESC

-- Create a non-clustered composite Index on (OwnerUserId, Score DESC) columns on Posts table
GO
CREATE NONCLUSTERED INDEX IX_Posts_OwnerUserId_Score
ON Posts(OwnerUserId,Score DESC)


/*===========================================================================================
	2) Optimize queries that frequently access high-value posts. These queries
       always filter for posts with score > 100 and non-null titles.
       Tasks:
       a) Design an index that only includes posts meeting these criteria
       b) Include relevant columns in the index
       c) Write a query that demonstrates the optimization
       d) Explain why this specialized index design is beneficial
=============================================================================================*/

-- Example query pattern whose performance needs to be optimized
GO
SELECT Id,
       Title,
       Score
FROM Posts
WHERE Score > 100
      AND Title IS NOT NULL

-- Create a non-clustered filter Index on (Score DESC) column on Posts table in addition to including Title column values
GO
CREATE NONCLUSTERED INDEX IX_Posts_Score_Greater_Than_100_And_Title_Is_NULL
ON Posts(Score DESC)
INCLUDE(Title)
WHERE (
        Score > 100
        AND Title IS NOT NULL
      )

/*------------------------------------------------------------------------------------
    This specialized Index design (Filtered Index) is beneficial in this case (A query
    that is frequently access high-value posts) for couple of reasons 
    which are :
    1) It reduces storage cost since it's a filtered index that is applied only on 
       selected posts whose score is greater than 100 and have a title rather than
       been applied on whole table rows which makes it smaller (does not consume 
       many pages on Hard Disk) and faster (Indexing only records that fullfill the
       condition).
    2) It's perfect to use for sparse columns (contains many NULL values) like
       in title column in posts table as it indexes only posts with titles.

    Findings:
    - Before applying the non-clustered filtered index, actual execution plan was 
      (Clustered Index Scan on PK_Posts__Id Index) and almost read all rows of clustered 
      index table.
    - After applying the non-clustered filtered index, actual execution plan was 
      (Non-Clustered Index Scan on IX_Posts_Score_Greater_Than_100_And_Title_Is_NULL 
      Index) and read only the returned number of rows.
------------------------------------------------------------------------------------*/