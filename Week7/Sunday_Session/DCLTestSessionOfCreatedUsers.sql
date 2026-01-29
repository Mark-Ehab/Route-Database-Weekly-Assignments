/*===========================================================================
	Use StackOverflow2010 Database instead of master Database (Default)
============================================================================*/
USE StackOverflow2010;

/*===========================================================================================
	2) Test that SofDbUser related to LOGIN TestLogin can only SELECT from Users table
=============================================================================================*/
-- Select all data from Users table (Positive Scenario)
SELECT *
FROM Users;

-- Update age of user whose id is 2 on Users table (Negative Scenario)
UPDATE Users 
SET Age = 30
WHERE Id = 1;

/*===========================================================================================
	3) Test if SofDbUser can do the following on StackOverflow2010:
		- Select from all tables 
		- Execute all stored procedures
=============================================================================================*/
-- Select all data from Users table (Positive Scenario)
SELECT *
FROM Users;
-- Select all data from Posts table (Positive Scenario)
SELECT *
FROM Posts;
-- Select all data from Comments table (Positive Scenario)
SELECT *
FROM Comments;

-- Execute any stored procedure
EXECUTE [dbo].[sp_GetRecentBadges] @DaysBack = 500;
EXECUTE [dbo].[sp_GetTopUsersByReputation] 8,1000;
EXECUTE [dbo].[sp_SearchPosts] 'C#';

/*===========================================================================================
	4) SofDbUser user has DataEntry role that has permissions of INSERT and UPDATE on Posts
	   table.
	   Try those operations with SofDbUser user before and after revoking those permissions 
	   from DataEntry role
=============================================================================================*/
-- Before Permissions Revoke
-- Try Insert (Permitted)
INSERT INTO Posts(Title,
                  Body,
                  CreationDate,
                  PostTypeId,
                  OwnerUserId,
                  ViewCount,
                  LastActivityDate,
                  Score)
VALUES (
        'What is Garbage Collector in java ?',
        'Test Test Test Test Test Test Test Test Test Test Test Test Test',
        SYSDATETIME(),
        1,
        1,
        0,
        SYSDATETIME(),
        0
       )

-- Try Update (Permitted)
UPDATE Posts
SET Score = 2000
WHERE Id = 12496736;

SELECT * FROM Posts ORDER BY ID DESC ;

-- After Permissions Revoke
-- Try Insert (Not Permitted)
INSERT INTO Posts(Title,
                  Body,
                  CreationDate,
                  PostTypeId,
                  OwnerUserId,
                  ViewCount,
                  LastActivityDate,
                  Score)
VALUES (
        'What is Garbage Collector in java ?',
        'Test Test Test Test Test Test Test Test Test Test Test Test Test',
        SYSDATETIME(),
        1,
        1,
        0,
        SYSDATETIME(),
        0
       )

-- Try Update (Not Permitted)
UPDATE Posts
SET Score = 2000
WHERE Id = 12496736;

SELECT * FROM Posts ORDER BY ID DESC ;

/*===========================================================================================
	5) Try to delete Users table after been denied on SofDbUser
=============================================================================================*/
DELETE Users
WHERE id IS NULL;