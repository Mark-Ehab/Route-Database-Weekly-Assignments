/*===========================================================================
	Use BankManagementSystemDb Database instead of master Database (Default)
============================================================================*/
USE BankManagementSystemDb

/*===========================================================================
	9) READ UNCOMMITTED, READ COMMITTED, and SERIALIZABLE Concurrent Sessions 
       Demos
============================================================================*/
/*--------------------------------------------------------- 
    Concurrent transaction that may introduce Dirty Read 
    (If it's executed earlier than other transaction)
-----------------------------------------------------------*/
BEGIN TRANSACTION
    -- Update on balance of account 101
    UPDATE Bank.AccountBalance
    SET Balance = 700
    WHERE AccountId = 101

    -- Set a delay for 10 Secs
    WAITFOR DELAY '00:00:10';

    -- Rollback the transacrion 
    ROLLBACK;

-- Test that transaction is rolled back 
SELECT AccountId,
       Balance
FROM Bank.AccountBalance
WHERE AccountId = 101;

/*------------------------------------------------------------ 
    Concurrent transaction that may introduce Non-Repeatable
    Reads 
    (If it's executed later than other transaction)
-------------------------------------------------------------*/
BEGIN TRANSACTION
    -- Update on balance of account 101
    UPDATE Bank.AccountBalance
    SET Balance = 10000
    WHERE AccountId = 101

    -- Commit the transacrion 
    COMMIT;

/*------------------------------------------------------------ 
    Concurrent transaction that may introduce Phantom reads
    (If it's executed later than other transaction)
-------------------------------------------------------------*/
BEGIN TRANSACTION
    -- Insert a new account into Bank.AccountBalance table
    INSERT INTO Bank.AccountBalance
    VALUES(105,   
          'Donnation Account',
          70000,
          SYSDATETIME());

    -- Commit the transacrion 
    COMMIT;

-- Test if new account is added
SELECT *
FROM Bank.AccountBalance

DELETE Bank.AccountBalance
WHERE AccountId = 105;

/*===========================================================================
	10) Durability proof through killing session in which concerned 
        transaction is committed 
============================================================================*/
-- Kill main session to prove transaction durability property 
KILL 52; -- This session id is variable and not static and got from @@SPID on the concerned session

/*===========================================================================
	13) Deadlock Concurrent Session Demo
============================================================================*/
-- A transaction to be executed in parallel with other one in other session 
-- to produce a deadlock
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        -- Try to update balance of account 102 while other transaction try to update account 101 balance
        -- (Potential Deadlock)
        UPDATE Bank.AccountBalance
        SET Balance = 100
        WHERE AccountId = 102;

        -- Set a delay of 10 secs keeping the resourse locked until delay is passed
        WAITFOR DELAY '00:00:10'; 

        -- Try to update balance of account 101 while other transaction try to update account 102 balance
        UPDATE Bank.AccountBalance
        SET Balance = 600
        WHERE AccountId = 101;
        COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK TRANSACTION;
    END

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH