/*=====================================================================
	Use StackOverflow 2010 Database instead of master Database (Default)
=======================================================================*/
USE StackOverflow2010

/* Stored Procdures */

/*===========================================================================================
	1) Create a stored procedure named sp_GetRecentBadges that retrieves all badges earned by
       users within the last N days.
       The procedure should accept one input parameter @DaysBack (INT) to determine how many
       days back to search.
       Test the procedure using different values for the number of days.
=============================================================================================*/
-- Create a procedure called sp_GetRecentBadges
   GO
   CREATE OR ALTER PROCEDURE sp_GetRecentBadges @DaysBack INT
   AS
   BEGIN
       -- Disable COUNT messages
       SET NOCOUNT ON

       BEGIN TRY
            -- Check if passed days back values are positive values 
            IF @DaysBack < 0
            BEGIN
                -- Throw an exception
                ;THROW 50001,'Invalid value of passed Days back (Shall be >= 0)',1;
            END

            -- Local Variables Declarations
            DECLARE @TargetDate DATETIME2;

            -- Calaculate TargetDate after which badges earned by users will be retrieved 
            SET @TargetDate = DATEADD(DAY,-@DaysBack,SYSDATETIME());

            -- Select badges earned by users within last period passed in days
            SELECT [Name] AS BadgeName,
                   [Date] AS BadgeEarnedDate
            FROM Badges
            WHERE Date >= @TargetDate;

            -- Print that query is done successfully
            PRINT ''
            PRINT 'Badges earned within ' + CAST(@DaysBack AS VARCHAR(100)) + ' days are retrieved successfully !'
       END TRY 
       BEGIN CATCH
            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT ''
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
       END CATCH
   END

-- Test the created procedure using different values for the number of days.
-- Postive Scenario
EXECUTE sp_GetRecentBadges @DaysBack = 5500
-- Negative Scenario
EXECUTE sp_GetRecentBadges @DaysBack = -5500

/*===========================================================================================
	2) Create a stored procedure named sp_GetUserSummary that retrieves summary statistics 
       for a specific user.
       The procedure should accept @UserId as an input parameter and return the following 
       values as output parameters:
       ● Total number of posts created by the user
       ● Total number of badges earned by the user
       ● Average score of the user’s posts
=============================================================================================*/
-- Create a procedure called sp_GetUserSummary
GO
CREATE OR ALTER PROCEDURE sp_GetUserSummary @UserId INT,
                                            @TotalPosts INT OUTPUT,
                                            @TotalBadges INT OUTPUT,
                                            @AveragePostsScore DECIMAL(10,2) OUTPUT
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if passed user id exists on the DB
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
        BEGIN
            -- Throw an exception
            ;THROW 50008,'Invalid User Id !', 1;
        END

        -- Retrive Total Posts, Total Badges and User Average Post Score of passed user
        SELECT @TotalPosts = ISNULL(P.PostCount,0),
               @TotalBadges = ISNULL(B.BadgeCount,0),
               @AveragePostsScore = P.UserPostAverageScore
        FROM Users AS U
        LEFT JOIN (
                        SELECT OwnerUserId,
                            COUNT(*) AS PostCount,
                            ROUND(AVG(CAST(Score AS DECIMAL(10,2))),2) AS UserPostAverageScore
                        FROM Posts
                        GROUP BY OwnerUserId
                    ) AS P
        ON P.OwnerUserId = U.Id
        LEFT JOIN (
                        SELECT UserId,
                            COUNT(*) AS BadgeCount
                            FROM Badges
                        GROUP BY UserId
                    ) AS B
        ON B.UserId = U.Id
        WHERE U.Id = @UserId
        ORDER BY U.Id ASC

        -- Print that Total Posts, Total Badges and User Average Post Score are retrieved
        PRINT '';
        PRINT 'Total posts of user (' + CAST(@UserId AS VARCHAR(100)) + ') are '+CAST(@TotalPosts AS VARCHAR(100))+' !';
        PRINT '';
        PRINT 'Total badges of user (' + CAST(@UserId AS VARCHAR(100)) + ') are '+CAST(@TotalBadges AS VARCHAR(100))+' !';
        PRINT '';
        PRINT 'Average post score of user (' + CAST(@UserId AS VARCHAR(100)) + ') is '+CAST(@AveragePostsScore AS VARCHAR(100))+' !';
    END TRY
    BEGIN CATCH
        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT ''
        PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH
END

/*----------------------------------------------------------------------------------------------------------------
    Other Solution (Not recommended due to high performance):

    SELECT @TotalPosts = COUNT(DISTINCT P.Id) AS PostCount,
           @TotalBadges = COUNT(DISTINCT B.Id) AS BadgeCount,
           @AveragePostsScore = ROUND(AVG(DISTINCT CAST(P.Score AS DECIMAL(10,2))),2) AS UserPostAverageScore
    FROM Users AS U
    LEFT JOIN Posts AS P
    ON P.OwnerUserId = U.Id
    LEFT JOIN Badges AS B
    ON B.UserId = U.Id
    WHERE U.Id = @UserId
    GROUP BY U.Id,
             U.DisplayName,
             U.Reputation
    ORDER BY U.Id ASC
----------------------------------------------------------------------------------------------------------------*/

-- Test the created stored procedure
-- Positive Scenario
DECLARE @UserTotalPosts INT;
DECLARE @UserTotalBadges INT;
DECLARE @UserAveragePostsScore DECIMAL(10,2);
EXECUTE sp_GetUserSummary @UserId = 2,
                          @TotalPosts = @UserTotalPosts OUTPUT,
                          @TotalBadges = @UserTotalBadges OUTPUT,
                          @AveragePostsScore = @UserAveragePostsScore OUTPUT
SELECT @UserTotalPosts AS UserTotalPosts,
       @UserTotalBadges AS UserTotalBadges,
       @UserAveragePostsScore AS UserAveragePostsScore
-- Negative Scenario
DECLARE @UserTotalPosts1 INT;
DECLARE @UserTotalBadges1 INT;
DECLARE @UserAveragePostsScore1 DECIMAL(10,2);
EXECUTE sp_GetUserSummary @UserId =33939392,
                          @TotalPosts = @UserTotalPosts1 OUTPUT,
                          @TotalBadges = @UserTotalBadges1 OUTPUT,
                          @AveragePostsScore = @UserAveragePostsScore1 OUTPUT

/*===========================================================================================
	3) Create a stored procedure named sp_SearchPosts that searches for posts based on:
       ● A keyword found in the post title
       ● A minimum post score
       The procedure should accept @Keyword as an input parameter and @MinScore as an optional
       parameter with a default value of 0.The result should display matching posts ordered by
       score.
=============================================================================================*/
-- Create a stored procedure called sp_SearchPosts
GO
CREATE OR ALTER PROCEDURE sp_SearchPosts @Keyword VARCHAR(100),
                                         @MinScore INT = 0
AS
BEGIN
    -- Disable COUNT messages 
    SET NOCOUNT ON

    -- Searches for posts based on passed keyword and minimum score
    SELECT Id AS PostId,    
           Title AS PostTitle,
           Score AS PostScore
    FROM Posts
    WHERE (Title LIKE '%' + @Keyword + '%' 
          OR Score >= @MinScore)
          AND Title IS NOT NULL
    ORDER BY Score ASC

    -- Print that query is done successfully
    PRINT ''
    PRINT 'Posts are retrieved successfully !'
END

-- Test the created stored procedure
EXECUTE sp_SearchPosts @Keyword = 'java' , @Minscore = 100
EXECUTE sp_SearchPosts @Keyword = 'C#' 

/*===========================================================================================
	4) Create a stored procedure named sp_GetUserOrError that retrieves user details by user 
       ID.
       If the specified user does not exist, the procedure should raise a meaningful error.
       Use TRY…CATCH for proper error handling.
=============================================================================================*/
-- Create a stored procedure called sp_GetUserOrError
GO
CREATE OR ALTER PROCEDURE sp_GetUserOrError @UserId INT
AS
BEGIN
      -- Disable COUNT messages
      SET NOCOUNT ON

      BEGIN TRY
        -- Check if passed user id exists on the DB
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
        BEGIN
            -- Throw an exception
            ;THROW 50003,'Invalid User Id !', 1;
        END

        -- Retrive user details
        SELECT Id AS UserId,
               DisplayName AS Username,
               [Location] AS UserLocation,
               Reputation AS UserReputation,
               CreationDate AS UserCreationDate
        FROM Users
        WHERE Id = @UserId

        -- Print that query is done successfully
        PRINT ''
        PRINT 'User (' + CAST(@UserId AS VARCHAR(100)) + ') details are retrieved successfully !'
    END TRY
    BEGIN CATCH
        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT ''
        PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_GetUserOrError @UserId = 5
-- Negative Scenario
EXECUTE sp_GetUserOrError @UserId = 13900293

/*===========================================================================================
	5) Create a stored procedure named sp_AnalyzeUserActivity that:
       ● Calculates an Activity Score for a user using the formula:
       Reputation + (Number of Posts × 10)
       ● Returns the calculated Activity Score as an output parameter
       ● Returns a result set showing the user’s top 5 posts ordered by score
=============================================================================================*/
-- Create a stored procedure called sp_AnalyzeUserActivity
GO
CREATE OR ALTER PROCEDURE sp_AnalyzeUserActivity @UserId INT,
                                                 @ActivityScore INT OUTPUT
AS 
BEGIN
       -- Disable COUNT messages
       SET NOCOUNT ON

       BEGIN TRY
        -- Check if passed user id exists on the DB
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
        BEGIN
             -- Throw an exception
            ;THROW 50004,'Invalid User Id !', 1
        END

        -- Retrive user Actvity Score
        SELECT @ActivityScore = Reputation + ((
                   SELECT COUNT(Id)
                   FROM Posts
                   WHERE OwnerUserId = 2
               ) * 10) 
        FROM Users
        WHERE Id = @UserId

        -- Retrive user's top 5 posts by score
        SELECT TOP(5) U.Id AS UserId,
                      U.DisplayName AS Username,
                      P.Score AS TopFiveUserPostsScores   
        FROM Users AS U
        LEFT JOIN Posts AS P
        ON P.OwnerUserId = U.Id
        WHERE U.Id = @UserId
        ORDER BY P.Score DESC

        -- Print that query is done and ActivityScore is calculated successfully
        PRINT ''
        PRINT 'User (' + CAST(@UserId AS VARCHAR(100)) + ') Activity Score is calculated successfully !'
        PRINT ''
        PRINT 'Top 5 posts of User (' + CAST(@UserId AS VARCHAR(100)) + ') are retrieved successfully !'
     
    END TRY
    BEGIN CATCH
        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT ''
        PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH    
END

-- Test the created stored procedure
-- Positive Scenario
DECLARE @UserActivityScore1 INT;
EXECUTE sp_AnalyzeUserActivity @UserID = 2 , @ActivityScore = @UserActivityScore1 OUTPUT
SELECT @UserActivityScore1 AS ActivityScore
-- Negative Scenario
DECLARE @UserActivityScore2 INT;
EXECUTE sp_AnalyzeUserActivity @UserID = 3828383 , @ActivityScore = @UserActivityScore2 OUTPUT

/*===========================================================================================
	6) Create a stored procedure named sp_GetReputationInOut that uses a single input/output
       parameter.
       The parameter should initially contain a UserId as input and return the corresponding 
       user reputation as output.
=============================================================================================*/
-- Create a stored procedure called sp_GetReputationInOut
GO
CREATE OR ALTER PROCEDURE sp_GetReputationInOut @User_IdIn_ReputationOut INT OUTPUT
AS 
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if passed user id exists on the DB
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @User_IdIn_ReputationOut)
        BEGIN
            -- Throw an exception
            ;THROW 50004,'Invalid User Id !', 1
        END

        -- Retrive user reputation
        SELECT @User_IdIn_ReputationOut = Reputation
        FROM Users
        WHERE Id = @User_IdIn_ReputationOut

        -- Print that query is done successfully
        PRINT ''
        PRINT 'User (' + CAST(@User_IdIn_ReputationOut AS VARCHAR(100)) + ') corresponding reputation value is retrieved successfully !' 
    END TRY
    BEGIN CATCH
        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT ''
        PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH     
END

-- Test the created stored procedure
-- Positive Scenario
DECLARE @UserId1 INT = 2;
EXECUTE sp_GetReputationInOut @UserId1 OUTPUT
SELECT @UserId1 AS ActivityScore
-- Negative Scenario
DECLARE @UserId2 INT = 3923939;
EXECUTE sp_GetReputationInOut @UserId2 OUTPUT

/*===========================================================================================
	7) Create a stored procedure named sp_UpdatePostScore that updates the score of a post.
       The procedure should:
       ● Accept a post ID and a new score as input
       ● Validate that the post exists
       ● Use transactions and TRY…CATCH to ensure safe updates
       ● Roll back changes if an error occurs
=============================================================================================*/
-- Create a stored procedure called sp_UpdatePostScore
GO
CREATE OR ALTER PROCEDURE sp_UpdatePostScore @PostId INT,       
                                             @NewPostScore INT
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        BEGIN TRY
            -- Check if passed PostId already exists on the DB
            IF NOT EXISTS (SELECT 1 FROM Posts WHERE Id = @PostId)
            BEGIN
                -- Throw an exception
                ;THROW 50005,'Invalid Post Id !',1;
            END

            -- Update post score with new score value passed
            UPDATE Posts
            SET Score = @NewPostScore
            WHERE Id = @PostId

            -- Print that post score is updated successfully
            PRINT ''
            PRINT 'Post (' + CAST(@PostId AS VARCHAR(100)) + ') corresponding score value is updated successfully !'

            -- Commit the transaction
            COMMIT;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback the transaction
                ROLLBACK
            END 

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT ''
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_UpdatePostScore 30, 40
-- Negative Scenario
EXECUTE sp_UpdatePostScore 3445345, 40

/*===========================================================================================
	8) Create a stored procedure named sp_GetTopUsersByReputation that retrieves the top N
       users whose reputation is above a specified minimum value.
       Then create a permanent table named TopUsersArchive and insert the results returned by 
       the procedure into this table
=============================================================================================*/
-- Create a stored procedure called sp_GetTopUsersByReputation
GO
CREATE OR ALTER PROCEDURE sp_GetTopUsersByReputation @TopUsersNum INT,
                                                     @UserMinReputation INT
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if passed TopUsersNum is a postive value above 0
        IF @TopUsersNum <= 0 
        BEGIN
            -- Throw an exception
            ;THROW 50006,'Invalid TopUsersNum value !',1;
        END

        -- Check if passed UserMinReputation is a postive value above 0
        IF @UserMinReputation <= 0 
        BEGIN
            -- Throw an exception
            ;THROW 50007,'Invalid UserMinReputation value !',1;
        END

        -- Retrive Top N users whose reputations are above passed minimum reputation value
       SELECT TOP(@TopUsersNum) Id AS UserId,
                                DisplayName AS Username,
                                Reputation AS UserReputation
       FROM Users
       WHERE Reputation >= @UserMinReputation
       ORDER BY Reputation DESC

       -- Print that Top N users whose reputations are above passed minimum reputation value are retrieved successfully
       PRINT ''
       PRINT 'Top ' + CAST(@TopUsersNum AS VARCHAR(100)) + ' users whose reputations are above ' +
             CAST(@UserMinReputation AS VARCHAR(100)) + ' are retrieved successfully !'
    END TRY
    BEGIN CATCH
        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT ''
        PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_GetTopUsersByReputation 5,1034
-- Negative Scenarios
EXECUTE sp_GetTopUsersByReputation -5,1034
EXECUTE sp_GetTopUsersByReputation 5,-1034

-- Create a table called TopUsersArchive
CREATE TABLE TopUsersArchive
(
   Id INT IDENTITY(1,1) PRIMARY KEY,
   UserId INT NOT NULL,
   Username VARCHAR(50) NOT NULL,
   UserReputation INT NOT NULL
)

-- Insert results reterned from the stored procedure into TopUsersArchive table
INSERT INTO TopUsersArchive (UserId,Username,UserReputation)
EXECUTE sp_GetTopUsersByReputation 10,50

-- Test TopUsersArchive table after data insertion through querying all of its records 
SELECT *
FROM TopUsersArchive

/*===========================================================================================
	9) Create a stored procedure named sp_InsertUserLog that inserts a new record into a 
       UserLog table.
       The procedure should:
       ● Accept user ID, action, and details as input
       ● Return the newly created log ID using an output parameter
=============================================================================================*/
-- Create a table called UserLog
GO
CREATE TABLE UserLog
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    [Action] VARCHAR(100) NOT NULL,
    Details VARCHAR(4000) NOT NULL
)

-- Create a stored procedure called sp_InsertUserLog
GO
CREATE OR ALTER PROCEDURE sp_InsertUserLog @UserId INT,
                                           @Action VARCHAR(100),
                                           @Details VARCHAR(4000),
                                           @LogId INT OUTPUT
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;
    BEGIN TRANSACTION
        BEGIN TRY
            -- Check if passed user id exists on the DB
            IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
            BEGIN
                -- Throw an exception
                ;THROW 50004,'Invalid User Id !', 1
            END

            -- Insert user activity into UserLog table
            INSERT INTO UserLog (UserId, [Action], Details)
            VALUES (@UserId, @Action, @Details)

            -- Get recent Log Id
            SET @LogId = SCOPE_IDENTITY();

            -- Print that log activity is inserted successfully and concerned log Id is returned
            PRINT '';
            PRINT 'Log activity is inserted successfully with id ('+ CAST(@LogId AS VARCHAR(800)) + ') !'

            -- Commit Transaction
            COMMIT;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback the transaction
                ROLLBACK;
            END 

            -- Set @LogId to -1
            SET @LogId = -1;

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT '';
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
DECLARE @UserActivityLogId INT;
EXECUTE sp_InsertUserLog @UserId = 30,
                         @Action = 'INSERT',
                         @Details= 'Insert new post record',
                         @LogId = @UserActivityLogId OUTPUT
SELECT @UserActivityLogId AS RecentUserActivityLogId
DECLARE @UserActivityLogId1 INT;
EXECUTE sp_InsertUserLog @UserId = 30,
                         @Action = 'DELETE',
                         @Details= 'Delete a post record',
                         @LogId = @UserActivityLogId1 OUTPUT
SELECT @UserActivityLogId1 AS RecentUserActivityLogId1
-- Negative Scenario
DECLARE @UserActivityLogId2 INT;
EXECUTE sp_InsertUserLog @UserId = 3239230,
                         @Action = 'INSERT',
                         @Details= 'Insert new post record',
                         @LogId = @UserActivityLogId2 OUTPUT
SELECT @UserActivityLogId2 AS RecentUserActivityLogId2

/*===========================================================================================
	10) Create a stored procedure named sp_UpdateUserReputation that updates a user’s 
        reputation.The procedure should:
        ● Validate that the reputation value is not negative
        ● Validate that the user exists
        ● Return the number of rows affected
        ● Handle errors appropriately
=============================================================================================*/
-- Create a stored procedure called sp_UpdateUserReputation
GO
CREATE OR ALTER PROCEDURE sp_UpdateUserReputation @UserId INT,
                                                  @UserNewReputation INT
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        BEGIN TRY
            -- Check if passed user id exists on the DB
            IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
            BEGIN
                -- Throw an exception
                ;THROW 50004,'Invalid User Id !', 1
            END

            -- Check if passed reputation value is positive
           IF @UserNewReputation <= 0 
           BEGIN
               -- Throw an exception
               ;THROW 50009,'Invalid UserNewReputation value (Shall be > 0) !',1;
           END

            -- Update specified user with new passed reputation value
            UPDATE Users
            SET Reputation = @UserNewReputation
            WHERE Id = @UserId;

            -- Get the number of affected rows after update
            DECLARE @NumOfAffectedRows INT = @@ROWCOUNT;

            -- Print number of affected rows after update
            PRINT '';
            PRINT 'Number of rows affected after update is ('+ CAST(@NumOfAffectedRows AS VARCHAR(800)) + ') !'

            -- Commit Transaction
            COMMIT;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback the transaction
                ROLLBACK;
            END 

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT '';
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_UpdateUserReputation @UserId = 20,
                                @UserNewReputation = 8002
-- Negative Scenario
EXECUTE sp_UpdateUserReputation @UserId = 4343534,
                                @UserNewReputation = 8002
EXECUTE sp_UpdateUserReputation @UserId = 30,
                                @UserNewReputation = -327

/*===========================================================================================
	11) Create a stored procedure named sp_DeleteLowScorePosts that deletes all posts with a 
        score less than or equal to a given value.
        The procedure should:
        ● Use transactions
        ● Return the number of deleted records as an output parameter
        ● Roll back changes if an error occurs
=============================================================================================*/
GO
-- Insert all posts records into a local temporary table called TempPosts
SELECT *
INTO #TempPosts
FROM Posts

-- Create a stored procedure called sp_DeleteLowScorePosts
GO
CREATE OR ALTER PROCEDURE sp_DeleteLowScorePosts @MaxPostScore INT,
                                                 @NumOfDeletedRows INT OUTPUT    
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        BEGIN TRY
            -- Delete Posts that are less than or equal passed maximum post score from #LocalTempPosts table
            DELETE #TempPosts
            WHERE Score <= @MaxPostScore;

            -- Get the number of affected rows after delete
            SET @NumOfDeletedRows = @@ROWCOUNT;

            -- Print that post score is updated successfully
            PRINT ''
            PRINT CAST(@NumOfDeletedRows AS VARCHAR(100)) + ' Posts are deleted successfully !'

            -- Commit the transaction
            COMMIT;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback the transaction
                ROLLBACK;
            END 

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT ''
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
DECLARE @DeletedRows INT;
EXECUTE sp_DeleteLowScorePosts @MaxPostScore = -37,
                               @NumOfDeletedRows = @DeletedRows OUTPUT
SELECT @DeletedRows AS NumberOfDeletedRows 

SELECT id,score
FROM #TempPosts
ORDER BY score ASC

/*===========================================================================================
	12) Create a stored procedure named sp_BulkInsertBadges that inserts multiple badge 
        records for a user.The procedure should:
        ● Accept a user ID
        ● Accept a badge count indicating how many badges to insert
        ● Insert multiple related records in a single operation
=============================================================================================*/
-- Create a local temporary table called #TempBadges that is clone from Badges table 
-- to test badges bulk insert on it 
GO
CREATE TABLE #TempBadges(
	Id int IDENTITY(1,1) NOT NULL,
	[Name] VARCHAR(1000) NOT NULL,
	UserId INT NOT NULL,
	[Date] DATETIME2 NOT NULL)

-- Create a stored procedure called sp_BulkInsertBadges
GO
CREATE OR ALTER PROCEDURE sp_BulkInsertBadges @UserId INT,
                                              @NumOfBadgesToBeInserted INT
AS
BEGIN 
    -- Disable COUNT messages
    SET NOCOUNT ON

    BEGIN TRANSACTION
        BEGIN TRY 
            -- Check if passed user id exists on the DB
            IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
            BEGIN
                -- Throw an exception
                ;THROW 50004,'Invalid User Id !', 1
            END

            -- Check if passed number of badges to be inserted value is greater than 0
            IF @NumOfBadgesToBeInserted <= 0 
            BEGIN
            -- Throw an exception
            ;THROW 50009,'Invalid NumOfBadgesToBeInserted value (Shall be > 0) !',1;
            END

            -- Create N badge records based on passed number of badges to be inserted
            -- then insert them as a bulk inside the local temp table called #TempBadges
            ;WITH NumberOfBadgesRecordsToBeInserted AS 
            (
                SELECT @UserId AS UserId,
                       'Badge_' + CAST(1 AS varchar(1000)) AS [Name],
                       SYSDATETIME() AS [Date],
                       1 AS Iterator
                UNION ALL
                SELECT @UserId AS UserId,
                       'Badge_' + CAST(Iterator + 1 AS varchar(1000)) AS Number,
                       SYSDATETIME() AS [Date],
                       Iterator + 1 AS Iterator
                FROM NumberOfBadgesRecordsToBeInserted
                WHERE Iterator < @NumOfBadgesToBeInserted
            )
            INSERT INTO #TempBadges (UserId,[Name],[Date])
            SELECT UserId,[Name],[Date]
            FROM NumberOfBadgesRecordsToBeInserted;

            -- Print that bulk records are inserted successfully
            PRINT '';
            PRINT '(' + CAST(@NumOfBadgesToBeInserted AS VARCHAR(900)) + ') rows are inserted successfully into #TempBadges table!';
   
            -- Commit the transaction
            COMMIT;
       END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback the transaction
                ROLLBACK;
            END 

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT ''
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END

-- Test created stored procedure
-- Positive Scenario
EXECUTE sp_BulkInsertBadges @UserId = 5,
                            @NumOfBadgesToBeInserted = 36
-- Test if bulk badge records are inserted successfully
SELECT * 
FROM #TempBadges
-- Negative Scenario
EXECUTE sp_BulkInsertBadges @UserId = 3234239,
                            @NumOfBadgesToBeInserted = 20
EXECUTE sp_BulkInsertBadges @UserId = 2,
                            @NumOfBadgesToBeInserted = -20

/*===========================================================================================
	13) Create a stored procedure named sp_GenerateUserReport that generates a complete user
        report.
        The procedure should:
        ● Call another stored procedure internally to retrieve user statistics
        ● Combine user profile data and statistics
        ● Return a formatted report including a calculated user level
=============================================================================================*/
-- Create a stored procedure called sp_GenerateUserReport
GO
CREATE OR ALTER PROCEDURE sp_GenerateUserReport @UserId INT
AS
BEGIN
     -- Disable COUNT messages
     SET NOCOUNT ON

     BEGIN TRY
        -- Check if passed user id exists on the DB
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @UserId)
        BEGIN
            -- Throw an exception
            ;THROW 50008,'Invalid User Id !', 1;
        END

        -- Variables Declarations
        DECLARE @UserTotalPosts INT;
        DECLARE @UserTotalBadges INT;
        DECLARE @UserAveragePostsScore DECIMAL(10,2);
        EXECUTE sp_GetUserSummary @UserId = @UserId,
                                  @TotalPosts = @UserTotalPosts OUTPUT,
                                  @TotalBadges = @UserTotalBadges OUTPUT,
                                  @AveragePostsScore = @UserAveragePostsScore OUTPUT
        -- Create user profile
        SELECT Id AS UserId,
               DisplayName AS Username,
               [Location] AS UserLocation,
               Reputation AS UserReputation,
               @UserTotalPosts AS UserTotalPosts,
               @UserTotalBadges AS UserTotalBadges,
               @UserAveragePostsScore AS UserAveragePostsScore,
                CASE
                    WHEN Reputation >= 50000 THEN 'Elite'
                    WHEN Reputation >= 30000 AND Reputation <= 49999 THEN 'High'
                    WHEN Reputation >= 10000 AND Reputation <= 29999 THEN 'Medium'
                    ELSE 'Low'
                END AS UserLevel
        FROM Users
        WHERE Id = @UserId
     END TRY   
     BEGIN CATCH
            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT ''
            PRINT 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));      
     END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_GenerateUserReport @UserId = 2
EXECUTE sp_GenerateUserReport @UserId = 3

/* Triggers */

/*===========================================================================================
	1) Create an AFTER INSERT trigger on the Posts table that logs every new post creation 
       into a ChangeLog table.
       The log should include:
       ● Table name
       ● Action type
       ● User ID of the post owner
       ● Post title stored as new data
=============================================================================================*/
-- Create a physical table for DML logs called ChangeLog in DBO schema
GO
CREATE TABLE ChangeLog
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(1000) NOT NULL,
    ActionType NVARCHAR(100) NOT NULL,
    UserId INT NOT NULL,
    Details NVARCHAR(2000) NOT NULL,
    NewValue NVARCHAR(1000) DEFAULT('-'),
    OldValue NVARCHAR(1000) DEFAULT('-'),
    LogTime DATETIME2 NOT NULL
)

-- Create an AFTER INSERT trigger on the Posts table that logs every new post creation 
-- into a ChangeLog table called trg_LogPostsCreationAfterInsert
GO
CREATE OR ALTER TRIGGER DBO.trg_LogPostsCreationAfterInsert
ON DBO.Posts
AFTER INSERT
AS
BEGIN
    -- Disable COUNT messages 
    SET NOCOUNT ON;

    -- Insert commited insertion operation(s) into ChangLog table 
    INSERT INTO ChangeLog (TableName,
                           ActionType,
                           UserId,
                           Details,
                           NewValue,
                           LogTime)
    SELECT 'Posts',
           'Insert New Post',
           I.OwnerUserId,
           'New Post Inserted: ' + ISNULL(I.Title,'No Title'),
           ISNULL(I.Title,'No Title'),
           SYSDATETIME()
    FROM Inserted AS I;

    -- Print that inserted posts are logged successfully
    PRINT CHAR(10) + '(' + CAST(@@ROWCOUNT AS VARCHAR(500)) + ') inserted post(s) is/are logged successfully !';
END

-- Test created trigger by insertion of new post(s) into Posts table
INSERT INTO Posts(Title,
                  Body,
                  CreationDate,
                  PostTypeId,
                  OwnerUserId,
                  ViewCount,
                  LastActivityDate,
                  Score)
VALUES (
        'What is CLR in .NET ?',
        'Test Test Test Test Test Test Test Test Test Test Test Test Test',
        SYSDATETIME(),
        1,
        1,
        0,
        SYSDATETIME(),
        0
       )
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
-- Test if previous posts are already inserted into Posts table
SELECT *
FROM Posts
WHERE Title = 'What is Garbage Collector in java ?'
      OR Title = 'What is CLR in .NET ?'

/*===========================================================================================
	2) Create an AFTER UPDATE trigger on the Users table that tracks changes to the Reputation
       column.
       The trigger should:
       ● Log changes only when the reputation value actually changes
       ● Store both the old and new reputation values in the ChangeLog table
=============================================================================================*/
-- Create an AFTER UPDATE trigger on the Users table that tracks changes to the Reputation
-- column called trg_TrackUserReputationAfterUpdate
GO
CREATE OR ALTER TRIGGER DBO.trg_TrackUserReputationAfterUpdate
ON DBO.Users
AFTER UPDATE 
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Check if user reputation attribute is affected by update operation
    IF UPDATE(Reputation)
    BEGIN
        -- Insert commited update operation into ChangLog table 
        INSERT INTO ChangeLog (TableName,
                               ActionType,
                               UserId,
                               Details,
                               NewValue,
                               OldValue,
                               LogTime)
        SELECT 'Users',
               'Update User Reputation',
               I.Id,
               CONCAT('User (',I.Id,') reputation is updated from ',I.Reputation,' to ',D.Reputation),
               I.Reputation,
               D.Reputation,
               SYSDATETIME()
        FROM Inserted AS I
        INNER JOIN Deleted AS D
        ON I.Id = D.Id
        WHERE I.Reputation != D.Reputation; 
        
        -- Read number of rows affected 
        DECLARE @NumOfRowsAffected INT  = @@ROWCOUNT;

        -- Print that updated reputation is tracked and logged successfully
        PRINT CHAR(10) + 'User (' + CAST(@NumOfRowsAffected AS VARCHAR(500)) + ') reputation is tracked and logged successfully !';
    END 

    -- Print that record is updated successfully
    PRINT CHAR(10) + CAST(@NumOfRowsAffected AS VARCHAR(500)) + ' is updated successfully !';
END

-- Test created trigger by updating a specific user reputation value
UPDATE Users
SET Reputation = 770
WHERE Id = 16

/*===========================================================================================
	3) Create an AFTER DELETE trigger on the Posts table that archives deleted posts into a
       DeletedPosts table.
       All relevant post information should be stored before the post is removed.
=============================================================================================*/
-- Create a table called DeletedPosts to archive deleted posts from Posts table
GO
CREATE TABLE DeletedPosts
(
    [Id] [int] IDENTITY(1,1) NOT NULL,
	[AcceptedAnswerId] [int] NULL,
	[AnswerCount] [int] NULL,
	[Body] [nvarchar](max) NOT NULL,
	[ClosedDate] [datetime] NULL,
	[CommentCount] [int] NULL,
	[CommunityOwnedDate] [datetime] NULL,
	[CreationDate] [datetime] NOT NULL,
	[FavoriteCount] [int] NULL,
	[LastActivityDate] [datetime] NOT NULL,
	[LastEditDate] [datetime] NULL,
	[LastEditorDisplayName] [nvarchar](40) NULL,
	[LastEditorUserId] [int] NULL,
	[OwnerUserId] [int] NULL,
	[ParentId] [int] NULL,
	[PostTypeId] [int] NOT NULL,
	[Score] [int] NOT NULL,
	[Tags] [nvarchar](150) NULL,
	[Title] [nvarchar](250) NULL,
	[ViewCount] [int] NOT NULL
)

-- Create an AFTER DELETE trigger on the Posts table that archives deleted posts into a
-- DeletedPosts table called trg_ArchiveDeletedPosts
GO
CREATE OR ALTER TRIGGER trg_ArchiveDeletedPosts
ON Posts
AFTER DELETE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Insert commited deletion operation(s) into DeletedPosts table 
    INSERT INTO DeletedPosts ([AcceptedAnswerId],
                              [AnswerCount],
                              [Body],
                              [ClosedDate],
                              [CommentCount],
                              [CommunityOwnedDate],
                              [CreationDate],
                              [FavoriteCount],
                              [LastActivityDate],
                              [LastEditDate],
                              [LastEditorDisplayName],
                              [LastEditorUserId],
                              [OwnerUserId],
                              [ParentId],
                              [PostTypeId],
                              [Score],
                              [Tags],
                              [Title],
                              [ViewCount])
        SELECT  D.[AcceptedAnswerId],
                D.[AnswerCount],
                D.[Body],
                D.[ClosedDate],
                D.[CommentCount],
                D.[CommunityOwnedDate],
                D.[CreationDate],
                D.[FavoriteCount],
                D.[LastActivityDate],
                D.[LastEditDate],
                D.[LastEditorDisplayName],
                D.[LastEditorUserId],
                D.[OwnerUserId],
                D.[ParentId],
                D.[PostTypeId],
                D.[Score],
                D.[Tags],
                D.[Title],
                D.[ViewCount]
        FROM Deleted AS D;

        -- Print that deleted posts are archived successfully
        PRINT CHAR(10) + CAST(@@ROWCOUNT AS VARCHAR(500)) + ' post(s) is/are archieved successfully !'; 
    END

    -- Test created trigger by deleting a specific post from Posts table
    DELETE Posts 
    WHERE Id = 100

/*===========================================================================================
	4) Create an INSTEAD OF INSERT trigger on a view named vw_NewUsers (based on the Users
       table).
       The trigger should:
       ● Validate incoming data
       ● Prevent insertion if the DisplayName is NULL or empty
=============================================================================================*/
-- Create a standard simple view called vw_NewUsers
GO
CREATE OR ALTER VIEW vw_NewUsers 
WITH SCHEMABINDING, ENCRYPTION
AS 
    -- Select all users from Users table
    SELECT [Id],
	       [AboutMe],
	       [Age],
	       [CreationDate],
	       [DisplayName],
	       [DownVotes],
	       [EmailHash],
	       [LastAccessDate],
	       [Location],
	       [Reputation],
	       [UpVotes],
	       [Views],
	       [WebsiteUrl],
	       [AccountId]
    FROM DBO.Users;

    -- Test the created view
    GO
    SELECT * FROM vw_NewUsers

    -- Create an INSTEAD OF INSERT trigger on vw_NewUsers view called trg_ValidateUserOnInsertion
    GO
    CREATE OR ALTER TRIGGER DBO.trg_ValidateUserOnInsertion
    ON vw_NewUsers
    INSTEAD OF INSERT
    AS  
    BEGIN
       -- Disable COUNT messages
       SET NOCOUNT ON;

        BEGIN TRY
            -- Check if inserted user DisplayName is NULL or Empty
            IF EXISTS (SELECT 1 FROM Inserted WHERE DisplayName IS NULL)
            BEGIN
                -- Raise an error that user DisplayName is Invalid
                RAISERROR('Invalid User Display Name !',16,1);
            END

            -- Insert into users table
            INSERT INTO Users ([AboutMe],
                               [Age],
                               [CreationDate],
                               [DisplayName],
                               [DownVotes],
                               [EmailHash],
                               [LastAccessDate],
                               [Location],
                               [Reputation],
                               [UpVotes],
                               [Views],
                               [WebsiteUrl],
                               [AccountId])
            SELECT [AboutMe],
                   [Age],
                   [CreationDate],
                   [DisplayName],
                   [DownVotes],
                   [EmailHash],
                   [LastAccessDate],
                   [Location],
                   [Reputation],
                   [UpVotes],
                   [Views],
                   [WebsiteUrl],
                   [AccountId]
            FROM Inserted AS I

            -- Print that user(s) is inserted successfully
            PRINT CHAR(10) + CAST(@@ROWCOUNT AS VARCHAR(500)) + ' user(s) is/are inserted successfully !'
        END TRY
        BEGIN CATCH
            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
    END

    -- Test the created trigger by inserting a specific user into vw_NewUsers view
    -- Positive Scenario
    INSERT INTO vw_NewUsers (CreationDate,
                             DisplayName,
                             DownVotes,
                             LastAccessDate,
                             Reputation,
                             UpVotes,
                             [Views])
    VALUES(SYSDATETIME(),
           'MoSalah',
           9,
           SYSDATETIME(),
           500,
           30,
           40)
    -- Negative Scenario
    INSERT INTO vw_NewUsers (CreationDate,
                             DownVotes,
                             LastAccessDate,
                             Reputation,
                             UpVotes,
                             [Views])
    VALUES(SYSDATETIME(),
           9,
           SYSDATETIME(),
           500,
           30,
           40)
SELECT * 
FROM Users
ORDER BY Id DESC

/*===========================================================================================
	5) Create an INSTEAD OF UPDATE trigger on the Posts table that prevents updates to the Id
       column.
       Any attempt to update the Id column should be:
       ● Blocked
       ● Logged in the ChangeLog table
=============================================================================================*/
-- Create an INSTEAD OF UPDATE trigger on the Posts table that prevents updates to the Id
-- column called trg_PreventPostIdUpdate
GO
CREATE OR ALTER TRIGGER trg_PreventPostIdUpdate
ON Posts
INSTEAD OF UPDATE 
AS 
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Check if post id is attempted to be updated 
    IF UPDATE(Id)
    BEGIN
        -- Insert this attempt to update Post Id into ChangeLog table
        INSERT INTO ChangeLog (TableName,
                                ActionType,
                                UserId,
                                Details,
                                LogTime)
        SELECT 'Posts',
               'Update Post Id',
               D.Id,
               CONCAT('Attempt to update post Id with Id of ','(',D.Id,')'),
               SYSDATETIME()
        FROM Deleted AS D

        -- Raise an error that states that post id cannot be updated
        RAISERROR('Post Ids cannot be updated !',15,1);

        -- Halt the trigger execution
        RETURN;
    END

    -- Update the post
    UPDATE P
    SET P.Score = I.Score
    FROM Inserted AS I 
    INNER JOIN Posts AS P
    ON I.Id = P.Id

    -- Print that record is updated successfully 
    PRINT CHAR(10) + 'Post is updated successfully !';
END

-- Test the created trigger through updating a specific post record
-- Postive Scenario
UPDATE Posts
SET Score = 550
WHERE Id = 4
-- Negative Scenario
UPDATE Posts
SET Id = 5
WHERE Id = 4

/*===========================================================================================
	6) Create an INSTEAD OF DELETE trigger on the Comments table that implements a soft
       delete mechanism.
       Instead of deleting records:
       ● Add an IsDeleted flag
       ● Mark records as deleted
       ● Log the soft delete operation
=============================================================================================*/
-- Create another version of comments table that supports soft delete
GO
CREATE TABLE [dbo].[CommentsSoftDeleted]
(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[PostId] [int] NOT NULL,
	[Score] [int] NULL,
	[Text] [nvarchar](700) NOT NULL,
	[UserId] [int] NULL,
    IsDeleted BIT DEFAULT (0)
)

-- Populate CommentsSoftDeleted table from Comments table
INSERT INTO [CommentsSoftDeleted] ([CreationDate],
                                   [PostId],
                                   [Score],
                                   [Text],
                                   [UserId])
SELECT [CreationDate],
       [PostId],
       [Score],
       [Text],
       [UserId]
FROM Comments

-- Create an INSTEAD OF DELETE trigger on the Comments table that implements a soft
-- delete mechanism called trg_SoftDeleteComment
GO
CREATE OR ALTER TRIGGER DBO.trg_SoftDeleteComment
ON DBO.CommentsSoftDeleted
INSTEAD OF DELETE
AS 
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Set IsDeleted flag in CommentsSoftDeleted table for deleted rows
    UPDATE CSD
    SET IsDeleted = 1
    FROM Deleted AS D
    INNER JOIN CommentsSoftDeleted AS CSD
    ON CSD.Id = D.Id

    -- Print number of deleted comments
    PRINT CHAR(10) + CAST(@@ROWCOUNT AS VARCHAR(500)) + ' row(s) is/are deleted from CommentsSoftDeleted table !' 
END

-- Test the created trigger by soft deleting a comment from CommentsSoftDeleted table
SELECT * FROM CommentsSoftDeleted ORDER BY ID ASC
DELETE CommentsSoftDeleted
WHERE Id = 5

/*===========================================================================================
	7) Create a DDL trigger at the database level that prevents any table from being dropped.
       All drop table attempts should be logged in the ChangeLog table.
=============================================================================================*/
-- Create a DDL trigger at the database level that prevents any table from being dropped
-- called trg_PreventTableDropDB
GO
CREATE OR ALTER TRIGGER trg_PreventTableDropDB
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Variables Definition
    -- Create a variable to hold event data
    DECLARE @DDLEventData XML = EVENTDATA();
    -- Create a variable to hold table name on which action is applied
    DECLARE @TableName NVARCHAR(MAX) = @DDLEventData.value('(/EVENT_INSTANCE/ObjectName)[1]','NVARCHAR(MAX)');

    -- Halt the DROP_TABLE action by rolling back the transaction to ActionLog savepoint
    ROLLBACK;

    -- Print that user is not authorized to drop concerned table on StackOverflow2010 database
    PRINT CHAR(10) + 
            'You are not authorized to drop table ' + @TableName +
            ' on StackOverflow2010 Database !';

    -- Log the table drop attempt into ChangeLog table
    INSERT INTO ChangeLog (TableName,
                           ActionType,
                           Details,
                           LogTime)
    VALUES(@TableName,    
            'DROP_TABLE',
            CONCAT('An attempt to drop the table called ',@TableName),
            SYSDATETIME())
END

-- Test the created trigger by trying to drop any table on StackOverflow2010 database
DROP TABLE [dbo].[Comments_Template];

/*===========================================================================================
	8) Create a DDL trigger that logs all CREATE TABLE operations.
       The trigger should record:
       ● The action type
       ● The full SQL command used to create the table
=============================================================================================*/
-- Create a DDL trigger that logs all CREATE TABLE operations called trg_LogTableCreate
GO
CREATE OR ALTER TRIGGER trg_LogTableCreate
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Variables Definition
    -- Create a variable to hold event data
    DECLARE @DDLEventData XML = EVENTDATA();
    -- Create a variable to hold table name on which action is applied
    DECLARE @TableName NVARCHAR(MAX) = @DDLEventData.value('(/EVENT_INSTANCE/ObjectName)[1]','NVARCHAR(MAX)');
    -- Create a variable to hold full SQL command used to create the table 
    DECLARE @TSQLCommand NVARCHAR(MAX) = @DDLEventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','NVARCHAR(MAX)');

    -- Print that table is created successfully
    PRINT CHAR(10) + @TableName + ' is created successfully !';

    -- Log the table creation attempt into ChangeLog table
    INSERT INTO ChangeLog (TableName,
                           ActionType,
                           Details,
                           LogTime)
    VALUES(@TableName,     
            'CREATE_TABLE',
            CONCAT('An attempt to create a table called ',@TableName,' using the following command ',@TSQLCommand),
            SYSDATETIME())
END

-- Test the created trigger by trying to drop any table on StackOverflow2010 database
CREATE TABLE [dbo].[Comments_Template] (Id INT PRIMARY KEY,Score INT);

/*===========================================================================================
	9) Create a DDL trigger that prevents any ALTER TABLE statement that attempts to drop a
       column.
       All blocked attempts should be logged
=============================================================================================*/
-- Create a DDL trigger that prevents any ALTER TABLE statement that attempts to drop a
-- column called trg_PreventTableColumnDropDB
GO
CREATE OR ALTER TRIGGER trg_PreventTableColumnDropDB
ON DATABASE
FOR ALTER_TABLE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Variable Definitions
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @TableName NVARCHAR(MAX) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]','NVARCHAR(MAX)');
    DECLARE @ColumnName NVARCHAR(MAX) = @EventData.value('(/EVENT_INSTANCE/AlterTableActionList/Drop/Columns/Name)[1]','NVARCHAR(MAX)');   
    DECLARE @TSQLCommand NVARCHAR(MAX) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','NVARCHAR(MAX)');

    -- Check if there is an attempt to drop a column in a specific table
    IF @TSQLCommand LIKE '%DROP COLUMN%'
    BEGIN
        
        -- Print that user is not authorized to drop the concerned column 
        PRINT CHAR(10) + 'You are not authorized to drop column ' + @ColumnName + ' on table ' + @TableName;
        
        -- Rollback the transaction
        ROLLBACK; 
        
        -- Log the column drop attempt on a specific table into the ChangeLog table
        INSERT INTO ChangeLog (TableName,       
                               ActionType,
                               Details,
                               LogTime)
        VALUES (@TableName,
                'DROP_COLUMN',
                CONCAT('An attempt to drop column ',@ColumnName,' on table ',@TableName),
                SYSDATETIME());
    END
END

-- Test the created trigger 
ALTER TABLE [dbo].[Comments_Template]
DROP COLUMN [Score]

/*===========================================================================================
	10) Create a single trigger on the Badges table that tracks INSERT, UPDATE, and DELETE
        operations.
        The trigger should:
        ● Detect the operation type using INSERTED and DELETED tables
        ● Log the action appropriately in the ChangeLog table
=============================================================================================*/
-- Create a single AFTER trigger on the Badges table that tracks INSERT, UPDATE, and DELETE
-- operations called trg_TrackBadgesTableOperaions
GO
CREATE OR ALTER TRIGGER trg_TrackBadgesTableOperaions
ON Badges
AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Check which is DML operation in committed on Badges table
    IF NOT EXISTS (SELECT 1 FROM Deleted) -- New record is inserted into badges table
    BEGIN
        INSERT INTO ChangeLog (TableName,
                               ActionType,
                               UserId,
                               Details,
                               LogTime)
        SELECT 'Badges',
               'Insert New Badge',
               I.UserId,
               CONCAT('New badge of Id (',I.Id,') is inserted'),
               SYSDATETIME()
        FROM Inserted AS I

        -- Print that badge(s) are inserted successfully
        PRINT CHAR(10) + CONCAT(@@ROWCOUNT,' new badge(s) is/are inserted successfully !');
    END
    ELSE IF NOT EXISTS (SELECT 1 FROM Inserted) -- A record is deleted from badges table
    BEGIN
        INSERT INTO ChangeLog (TableName,
                               ActionType,
                               UserId,
                               Details,
                               LogTime)
        SELECT 'Badges',
               'Delete Badge',
               D.UserId,
               CONCAT('Badge of Id (',D.Id,') is deleted'),
               SYSDATETIME()
        FROM Deleted AS D   

        -- Print that badge(s) are deleted successfully
        PRINT CHAR(10) + CONCAT(@@ROWCOUNT,' badge(s) is/are deleted successfully !');
    END
    ELSE -- A record is updated from Badges tablet
    BEGIN
        INSERT INTO ChangeLog (TableName,
                               ActionType,
                               UserId,
                               Details,
                               LogTime)
        SELECT 'Badges',
               'Update Badge',
               I.UserId,
               CONCAT('Badge (',I.Id,') is updated'),
               SYSDATETIME()
        FROM Inserted AS I
        INNER JOIN Deleted AS D
        ON I.Id = D.Id

        -- Print that badge(s) are updated successfully
        PRINT CHAR(10) + CONCAT(@@ROWCOUNT,' badge(s) is/are updated successfully !');
    END
END

-- Test the created trigger by 
-- Insertion of new badge record
-- Update of an already existing badge record
-- Deletion an already existing badge record
INSERT INTO Badges([Name],
                   UserId,
                   [Date])
VALUES('Master',9,SYSDATETIME())

UPDATE Badges
SET [Name] = 'Mortarboard'
WHERE Id = 27676175

DELETE Badges
WHERE Id = 27676177

SELECT * FROM Badges ORDER BY Id DESC

/*===========================================================================================
	11) Create a trigger that maintains summary statistics in a PostStatistics table whenever 
        posts are inserted, updated, or deleted.
        The trigger should update:
        ● Total number of posts
        ● Total score
        ● Average score
        for the affected users.
=============================================================================================*/
-- Create PostStatistics table
SELECT COUNT(*) AS TotalNumberOfPosts,  
       SUM(Score) AS TotalPostScore,
       ROUND(AVG(CAST(Score AS DECIMAL(10,2))),2) AS AveragePostsScore
INTO PostStatistics
FROM Posts

-- Test if PostStatistics table is created successfully
SELECT * FROM PostStatistics

-- Create an AFTER trigger that maintains summary statistics in a PostStatistics table whenever 
-- posts are inserted, updated, or deleted called trg_MainPostStats
GO
CREATE OR ALTER TRIGGER trg_MainPostStats 
ON Posts
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Update posts statistics after DML operation is committed 
    Update PostStatistics
    SET TotalNumberOfPosts = (SELECT COUNT(*) FROM Posts),  
        TotalPostScore = (SELECT SUM(Score) FROM Posts),
        AveragePostsScore = (SELECT ROUND(AVG(CAST(Score AS DECIMAL(10,2))),2) FROM Posts)

    -- Print the post statistics are updated successfully
    PRINT CHAR(10) + 'Post Statistics are updated successfully !';
END

-- Test the created trigger

-- Insert
INSERT INTO Posts(Title,
                  Body,
                  CreationDate,
                  PostTypeId,
                  OwnerUserId,
                  ViewCount,
                  LastActivityDate,
                  Score)
VALUES (
        'What is ADO in .NET ?',
        'Test Test Test Test Test Test Test Test Test Test Test Test Test',
        SYSDATETIME(),
        1,
        1,
        0,
        SYSDATETIME(),
        9000
       )

-- Update
UPDATE Posts
SET Score = 9050
WHERE Id = 12496727

-- Delete
DELETE Posts
WHERE Id = 12496727

SELECT * FROM Posts ORDER BY Id DESC;

SELECT * FROM PostStatistics;

/*===========================================================================================
	12) Create an INSTEAD OF DELETE trigger on the Posts table that prevents deletion of 
        posts with a score greater than 100.
        Any prevented deletion should be logged.
=============================================================================================*/
-- Create an INSTEAD OF DELETE trigger on the Posts table that prevents deletion of 
-- posts with a score greater than 100 called trg_PreventDeletePostsAbove100
GO
CREATE OR ALTER TRIGGER trg_PreventDeletePostsAbove100
ON Posts
INSTEAD OF DELETE
AS
BEGIN
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Check if the score of deleted post is above 100 
    IF EXISTS (SELECT 1 FROM DELETED WHERE Score > 100)
    BEGIN
        -- Log that this attempt to delete the post is prevented into ChangeLog table
        INSERT INTO ChangeLog (TableName,
                               ActionType,
                               UserId,
                               Details,
                               LogTime)
        SELECT 'Posts',
               'Delete Post',
               D.OwnerUserId,
               CONCAT('Post of Id (',D.Id,') is attempted to be deleted but halted as its score is > 100'),
               SYSDATETIME()
        FROM Deleted AS D  

        -- Raise an error
        RAISERROR('Posts with score greater than 100 cannot be deleted',17,1);

        -- Exit the trigger
        RETURN;
    END

    -- If the score of post attempted to be deleted is greater than 100 then delete it
    DELETE Posts
    FROM Posts AS P
    INNER JOIN Deleted AS D
    ON P.Id = D.Id
END

-- Test the created trigger 
DELETE Posts
WHERE Id = 12496719

DELETE Posts
WHERE Id = 12496732

SELECT * FROM Posts ORDER BY Id DESC;

/*===========================================================================================
	13) Write the SQL commands required to:
        1. Disable a specific trigger on the Posts table
        2. Enable the same trigger again
        3. Check whether the trigger is currently enabled or disabled
=============================================================================================*/
-- Disable trg_PreventDeletePostsAbove100 trigger
GO
DISABLE TRIGGER DBO.[trg_PreventDeletePostsAbove100]
ON Posts

SELECT [Name],
       is_disabled
FROM SYS.triggers
WHERE parent_id = object_id('Posts')


--Test
DELETE Posts
WHERE Id = 12496730

-- Enable trg_PreventDeletePostsAbove100 trigger
GO
ENABLE TRIGGER DBO.[trg_PreventDeletePostsAbove100]
ON Posts

SELECT [Name],
       is_disabled
FROM SYS.triggers
WHERE parent_id = object_id('Posts')

--Test
DELETE Posts
WHERE Id = 12496731

SELECT * FROM Posts ORDER BY Id DESC;