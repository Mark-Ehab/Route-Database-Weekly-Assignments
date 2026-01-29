/*===========================================================================
	Use StackOverflow2010 Database instead of master Database (Default)
============================================================================*/
USE StackOverflow2010;

/*===========================================================================================
	1) Write the SQL commands to:
       a) Disable the trigger trg_Posts_LogInsert
       b) Enable the trigger trg_Posts_LogInsert
       c) Check if the trigger is disabled or enabled
=============================================================================================*/
-- Disable trg_LogPostsCreationAfterInsert trigger on Posts table
DISABLE TRIGGER DBO.trg_LogPostsCreationAfterInsert
ON Posts;

-- Check if trigger is disabled 
SELECT [name],
       is_disabled
FROM SYS.triggers
WHERE object_id = OBJECT_ID('trg_LogPostsCreationAfterInsert');

-- Enable trg_LogPostsCreationAfterInsert trigger on Posts table
ENABLE TRIGGER DBO.trg_LogPostsCreationAfterInsert
ON Posts;

-- Check if trigger is enabled 
SELECT [name],
       is_disabled
FROM SYS.triggers
WHERE object_id = OBJECT_ID('trg_LogPostsCreationAfterInsert');

/*===========================================================================================
	2) Create a SQL login, database user, and grant them SELECT permission on the Users table
       only.
=============================================================================================*/
-- Create a SQL login on server level called UserLogin_1 (Server Level)
CREATE LOGIN TestLogin
WITH PASSWORD = 'P@$$w0rd123';

-- Create a database user for recently created login on StackOverflow2010 (Database Level)
CREATE USER SofDbUser
FOR LOGIN TestLogin;

-- Grant the recently created user related to TestLogin LOGIN a SELECT permission on the 
-- Users table only directly
GRANT SELECT ON Users TO SofDbUser;

/*===========================================================================================
	3) Create a database role called "DataAnalysts" and grant it:
       - SELECT permission on all tables
       - EXECUTE permission on all stored procedures
       - Then add a user to this role.     
=============================================================================================*/
-- Create a database role called "DataAnalysts"
CREATE ROLE DataAnalysts;

-- Grant SELECT permission on all tables to DataAnalysts role 
GRANT SELECT ON SCHEMA::DBO TO DataAnalysts;

-- Grant EXECUTE permission on all stored procedures to DataAnalysts role 
GRANT EXECUTE TO DataAnalysts;

-- Add SofDbUser user to DataAnalysts role
ALTER ROLE DataAnalysts ADD MEMBER SofDbUser;

/*===========================================================================================
	4) Write SQL to REVOKE INSERT and UPDATE permissions from a role called "DataEntry" on 
       the Posts table.
=============================================================================================*/
-- Create a role called DataEntry
CREATE ROLE DataEntry;

-- Grant INSERT and UPDATE permissions on Posts table to DataEntry role
GRANT INSERT, UPDATE ON Posts TO DataEntry;

-- Add SofDbUser use as a member to DataEntry role 
ALTER ROLE DataEntry ADD MEMBER SofDbUser;

-- REVOKE INSERT and UPDATE permissions from a role called "DataEntry"
REVOKE INSERT, UPDATE ON Posts FROM DataEntry;

/*===========================================================================================
	5) Write SQL to DENY DELETE permission on the Users table to a specific user, even if 
       they have it through a role.
       Explain why DENY is used instead of REVOKE
=============================================================================================*/
-- Deny DELETE permission on the Users table to SofDbUser
DENY DELETE ON Users TO SofDbUser;

/*-------------------------------------------------------------------------
    DENY is used instead of REVOKE to block permission(s) on a specific 
    user on user level and even on role level for all roles that user is a
    member of unlike REVOKE that removes permission(s) from a specific user
    only eihter on user level or on role level which means if this 
    permission been revoked is already granted to role the user is a member
    of, this means that user can still use this permission.
--------------------------------------------------------------------------*/
/*===========================================================================================
	6) Create a comprehensive audit trigger that tracks all changes to the Comments table,
       storing:
       - Operation type (INSERT/UPDATE/DELETE)
       - Before and after values for UPDATE
       - Timestamp and user who made the change
=============================================================================================*/
-- Alter ChangeLog table to add a new column that stores
-- user who made the change
GO
ALTER TABLE ChangeLog
ADD DbUserName VARCHAR(2000);

-- Create a comprehensive audit trigger that tracks all changes to the Comments table
-- after INSERT/UPDATE/DELETE operations called trg_AuditCommentsChange
GO
CREATE OR ALTER TRIGGER DBO.trg_AuditCommentsChange
ON DBO.Comments
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    -- Disable COUNT messages 
    SET NOCOUNT ON;

    -- Check committed operation type
    IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS(SELECT 1 FROM Deleted)
    BEGIN
        -- Insert into ChangeLog table that an UPDATE opperation is committed
        -- on Comments table
        INSERT INTO ChangeLog(TableName,
                              ActionType,
                              UserId,
                              Details,
                              NewValue,
                              OldValue,
                              LogTime,
                              DbUserName)
        SELECT 'Comments',
               'UPDATE COMMENT',
               I.UserId,
               CONCAT('Comment with ID (',D.Id,') is updated on Comments table'),
               I.[Text],
               D.[Text],
               SYSDATETIME(),
               SYSTEM_USER
        FROM Deleted AS D
        INNER JOIN Inserted AS I
        ON I.Id = D.Id

        -- Print that updated comment(s) is/are logged successfully
        PRINT CHAR(10) + 'Updated comment(s) is/are logged successfully !';
    END
    ELSE IF EXISTS(SELECT 1 FROM Inserted) 
    BEGIN 
        -- Insert into ChangeLog table that an INSERT operation is committed 
        -- on Comments table
        INSERT INTO ChangeLog(TableName,
                              ActionType,
                              UserId,
                              Details,
                              NewValue,
                              LogTime,
                              DbUserName)
        SELECT 'Comments',
               'INSERT COMMENT',
               I.UserId,
               CONCAT('New comment with ID (',I.Id,') is inserted into Comments table'),
               I.[Text],
               SYSDATETIME(),
               SYSTEM_USER
        FROM Inserted AS I      
        
        -- Print that inserted comment(s) is/are logged successfully
        PRINT CHAR(10) + 'New inserted comment(s) is/are logged successfully !';
    END
    ELSE 
    BEGIN
        -- Insert into ChangeLog table that a DELETE operation is committed 
        -- on Comments table 
        INSERT INTO ChangeLog(TableName,
                              ActionType,
                              UserId,
                              Details,
                              OldValue,
                              LogTime,
                              DbUserName)
        SELECT 'Comments',
               'DELETE COMMENT',
               D.UserId,
               CONCAT('Comment with ID (',D.Id,') is deleted from Comments table'),
               D.[Text],
               SYSDATETIME(),
               SYSTEM_USER
        FROM Deleted AS D

        -- Print that deleted comment(s) is/are logged successfully
        PRINT CHAR(10) + 'Deleted comment(s) is/are logged successfully !';
    END
END

-- Test the created trigger 
-- Insert
INSERT INTO Comments (CreationDate,
                      PostId,
                      Score,
                      Text)
VALUES(SYSDATETIME(),
       12496734,
       200,
       'test test test test comment');

-- Update 
UPDATE Comments
SET [Text] = 'Test Comment (U)'
WHERE Id = 91214754;

-- Delete
DELETE Comments
WHERE Id = 91214754;

SELECT * FROM Comments ORDER BY Id DESC
SELECT * FROM Posts ORDER BY Id DESC
SELECT * FROM ChangeLog ORDER BY Id DESC

/*===========================================================================================
	7) Write a query to view all triggers in the database along with:
       - their status (enabled/disabled), type (AFTER/INSTEAD OF), and
       - the tables they're attached to.
=============================================================================================*/
SELECT Trg.[name] AS TriggerName,
       CASE
            WHEN Trg.is_disabled != 1 THEN 'Enabled'
            ELSE 'Disabled'
       END AS TriggerStatus,
       CASE
            WHEN Trg.is_instead_of_trigger != 1 THEN 'AFTER'
            ELSE 'INSTEAD OF'
       END AS TriggerType,
       Tbl.[name] AS TriggerAttachedTable
FROM SYS.triggers AS Trg
INNER JOIN SYS.tables AS Tbl
ON Trg.parent_id = Tbl.object_id;

/*===========================================================================================
	8) Write a query to view all permissions granted to a specific role or user, including 
       the object name, permission type, and state.
=============================================================================================*/
SELECT DBPri.[name] AS UserOrRoleName,
       DBPri.[type_desc] AS [Type],
       O.[name] AS ObjectName,
       DBPer.permission_name AS PermissionType,
       DBPer.state_desc AS PermissionState
FROM sys.database_principals AS DBPri
INNER JOIN sys.database_permissions AS DBPer
ON DBPri.principal_id = DBPer.grantee_principal_id
LEFT JOIN sys.objects AS O
ON O.object_id = DBPer.major_id
ORDER BY DBPri.[name]