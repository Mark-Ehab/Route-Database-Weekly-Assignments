/*===========================================================================
	Use BankManagementSystemDb Database instead of master Database (Default)
============================================================================*/
USE BankManagementSystemDb

/*==============================
	Tables Setup For Assignment
================================*/
GO
CREATE TABLE Bank.AccountBalance 
(
     AccountId INT PRIMARY KEY,
     AccountName VARCHAR(100),
     Balance DECIMAL(18,2) CHECK (Balance >= 0),
     LastUpdated DATETIME DEFAULT GETDATE()
);
GO
CREATE TABLE Bank.TransferHistory 
(
     TransferId INT IDENTITY(1,1) PRIMARY KEY,
     FromAccountId INT,
     ToAccountId INT,
     Amount DECIMAL(18,2),
     TransferDate DATETIME DEFAULT GETDATE(),
     Status VARCHAR(20),
     ErrorMessage VARCHAR(500)
);
GO
CREATE TABLE Bank.AuditTrail
(
     AuditId INT IDENTITY(1,1) PRIMARY KEY,
     TableName VARCHAR(100),
     Operation VARCHAR(50),
     RecordId INT,
     OldValue VARCHAR(500),
     NewValue VARCHAR(500),
     AuditDate DATETIME DEFAULT GETDATE(),
     UserName VARCHAR(100) DEFAULT SYSTEM_USER
);
GO
-- Insert sample data
INSERT INTO Bank.AccountBalance (AccountId, AccountName, Balance)
VALUES
 (101, 'Checking Account', 10000.00),
 (102, 'Savings Account', 25000.00),
 (103, 'Investment Account', 50000.00),
 (104, 'Emergency Fund', 15000.00);
GO

/*===========================================================================================
	1) Write a simple transaction that transfers $500 from Account 101 to Account 102.
       Use BEGIN TRANSACTION and COMMIT TRANSACTION.
       Display the balances before and after the transfer.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
      -- Display balances of accounts before the money transfer
      SELECT AccountId,
             AccountName,
             Balance AS BalanceBeforeMoneyTransfer
      FROM Bank.AccountBalance
      WHERE AccountId = 101 
            OR AccountId = 102
      
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 500;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $500 !',1;
      END

       -- Deduct $500 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $500 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Commit the transaction
        COMMIT;

    -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Succeeded');
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	2) Write a transaction that attempts to transfer $1000 from Account 101 to Account 102, 
       but then rolls it back using ROLLBACK TRANSACTION.
       Verify that the balances remain unchanged..     
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Display balances of accounts before the money transfer
    SELECT AccountId,
            AccountName,
            Balance AS BalanceBeforeMoneyTransfer
    FROM Bank.AccountBalance
    WHERE AccountId = 101 
        OR AccountId = 102

    BEGIN TRANSACTION    
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 1000;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $1000 !',1;
      END

       -- Deduct $1000 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $1000 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)
        
        -- Rollback the transaction
        Rollback;

    -- Display balances of accounts after the money transfer
    SELECT AccountId,
           AccountName,
           Balance AS BalanceAfterMoneyTransfer
    FROM Bank.AccountBalance
    WHERE AccountId = 101 
          OR AccountId = 102
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	3) Write a transaction that checks if Account 101 has sufficient balance before 
       transferring $2000 to Account 102.
       If insufficient, rollback the transaction.
       If sufficient, commit the transaction.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
      -- Display balances of accounts before the money transfer
      SELECT AccountId,
             AccountName,
             Balance AS BalanceBeforeMoneyTransfer
      FROM Bank.AccountBalance
      WHERE AccountId = 101 
            OR AccountId = 102
      
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 2000;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $2000 !',1;
      END

       -- Deduct $2000 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $2000 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Commit the transaction
        COMMIT;

    -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                        ToAccountId,
                                        Amount,
                                        TransferDate,
                                        Status)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Succeeded');
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	4) Write a transaction using TRY...CATCH that transfers money from Account 101 to Account
       102. 
       If any error occurs, rollback the transaction and display the error message.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
      -- Display balances of accounts before the money transfer
      SELECT AccountId,
             AccountName,
             Balance AS BalanceBeforeMoneyTransfer
      FROM Bank.AccountBalance
      WHERE AccountId = 101 
            OR AccountId = 102
      
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 5000;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $5000 !',1;
      END

       -- Deduct $5000 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $5000 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Commit the transaction
        COMMIT;

    -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                        ToAccountId,
                                        Amount,
                                        TransferDate,
                                        Status)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Succeeded');
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	5) Write a transaction that uses SAVE TRANSACTION to create a savepoint after the first 
       update.Then perform a second update and rollback to the savepoint if an error occurs.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
        -- Display balances of accounts before the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceBeforeMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
            OR AccountId = 102
      
        -- Variable Definitions
        DECLARE @Account101CurrentBalance DECIMAL(18,2);
        DECLARE @AmountToBeTransfered DECIMAL(18,2) = 5000;

        -- First Money Transfer
        -- Get account 101 current balance
        SELECT @Account101CurrentBalance = Balance
        FROM Bank.AccountBalance 
        WHERE AccountId = 101

        -- Check if account 101 has sufficient balance
        IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
        BEGIN 
            -- Raise an error that account 101 has no sufficient balance
            ;THROW 50005,'Account 101 has no sufficient balance to deduct $5000 !',1;
        END

        -- Deduct $5000 from account 101 balance 
        UPDATE Bank.AccountBalance
        SET Balance = Balance - @AmountToBeTransfered
        WHERE AccountId = 101;

        -- Log the operation into AuditTrail Table
        INSERT INTO Bank.AuditTrail(TableName,
                                    Operation,
                                    RecordId,
                                    OldValue,
                                    NewValue,
                                    AuditDate,
                                    UserName)
        VALUES ('AccountBalance',
                'Update Balance',
                101,
                (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
                (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
                SYSDATETIME(),
                SYSTEM_USER)

        -- Add $5000 to account 102 balance
        UPDATE Bank.AccountBalance
        SET Balance = Balance + @AmountToBeTransfered
        WHERE AccountId = 102;

        -- Log the operation into AuditTrail Table
        INSERT INTO Bank.AuditTrail(TableName,
                                    Operation,
                                    RecordId,
                                    OldValue,
                                    NewValue,
                                    AuditDate,
                                    UserName)
        VALUES ('AccountBalance',
                'Update Balance',
                102,
                (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
                (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
                SYSDATETIME(),
                SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
                AccountName,
                Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
                OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Log the transfer into TransferHistory Table
        INSERT INTO Bank.TransferHistory(FromAccountId,     
                                            ToAccountId,
                                            Amount,
                                            TransferDate,
                                            Status)
        VALUES (101,    
                102,
                @AmountToBeTransfered,
                SYSDATETIME(),
                'Succeeded');

        -- Save the first money transfer
        SAVE TRANSACTION FirstMoneyTransfer;
        
        -- Second Money Transfer
        -- Get account 101 current balance
        BEGIN TRY 
            -- Display balances of accounts before the money transfer
            SELECT AccountId,
                   AccountName,
                   Balance AS BalanceBeforeMoneyTransfer
            FROM Bank.AccountBalance
            WHERE AccountId = 101 
                OR AccountId = 102

            SELECT @Account101CurrentBalance = Balance
            FROM Bank.AccountBalance 
            WHERE AccountId = 101

            -- Check if account 101 has sufficient balance
            IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
            BEGIN 
                -- Raise an error that account 101 has no sufficient balance
                ;THROW 50005,'Account 101 has no sufficient balance to deduct $5000 !',1;
            END
            -- Deduct $5000 from account 101 balance 
            UPDATE Bank.AccountBalance
            SET Balance = Balance - @AmountToBeTransfered
            WHERE AccountId = 101;

            -- Log the operation into AuditTrail Table
            INSERT INTO Bank.AuditTrail(TableName,
                                        Operation,
                                        RecordId,
                                        OldValue,
                                        NewValue,
                                        AuditDate,
                                        UserName)
            VALUES ('AccountBalance',
                    'Update Balance',
                    101,
                    (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
                    (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
                    SYSDATETIME(),
                    SYSTEM_USER)

            -- Add $5000 to account 102 balance
            UPDATE Bank.AccountBalance
            SET Balance = Balance + @AmountToBeTransfered
            WHERE AccountId = 102;

            -- Log the operation into AuditTrail Table
            INSERT INTO Bank.AuditTrail(TableName,
                                        Operation,
                                        RecordId,
                                        OldValue,
                                        NewValue,
                                        AuditDate,
                                        UserName)
            VALUES ('AccountBalance',
                    'Update Balance',
                    102,
                    (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
                    (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
                    SYSDATETIME(),
                    SYSTEM_USER)

            -- Display balances of accounts after the money transfer
            SELECT AccountId,
                    AccountName,
                    Balance AS BalanceAfterMoneyTransfer
            FROM Bank.AccountBalance
            WHERE AccountId = 101 
                OR AccountId = 102
        
            -- Print that money is transfered successfully from account 101 to account 102
            PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
            ' is transfered successfully from account 101 to account 102';

            -- Log the transfer into TransferHistory Table
            INSERT INTO Bank.TransferHistory(FromAccountId,     
                                            ToAccountId,
                                            Amount,
                                            TransferDate,
                                            Status)
            VALUES (101,    
                    102,
                    @AmountToBeTransfered,
                    SYSDATETIME(),
                    'Succeeded');

            -- Commit the transaction
            COMMIT;
        END TRY
        BEGIN CATCH
            -- Check Trancount
            IF @@TRANCOUNT > 0
            BEGIN
               -- Rollback to FirstMoneyTransfer save point
                ROLLBACK TRANSACTION FirstMoneyTransfer;

                -- Commit the transaction
                COMMIT;
            END

             -- Log the transfer into TransferHistory Table
            INSERT INTO Bank.TransferHistory(FromAccountId,     
                                             ToAccountId,
                                             Amount,
                                             TransferDate,
                                             Status,
                                             ErrorMessage)
            VALUES (101,    
                    102,
                    @AmountToBeTransfered,
                    SYSDATETIME(),
                    'Failed',
                    ERROR_MESSAGE());

            -- Get error message, number, state and severity
            SELECT  ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_STATE() AS ErrorState,
                    ERROR_SEVERITY() AS ErrorSeverity

            -- Print the error message
            PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
        END CATCH
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	6) Write a transaction with nested BEGIN TRANSACTION statements.
       Display @@TRANCOUNT at each level to demonstrate how it changes.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRANSACTION
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Print the TRANCOUNT of the first level transaction
    PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));

    BEGIN TRANSACTION
        -- Print the TRANCOUNT of the second level transaction
        PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));
            
        BEGIN TRANSACTION
            -- Print the TRANCOUNT of the third level transaction
            PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));
            
            -- Commit third level transaction
            COMMIT;

        -- Commit second level transaction
        COMMIT;

    -- Commit first level transaction
    COMMIT;

/*===========================================================================================
	7) Demonstrate ATOMICITY by writing a transaction that performs multiple updates.
       Show that if one fails, all are rolled back.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
        -- Display balances of accounts before the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceBeforeMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
              OR AccountId = 103;

       -- Deduct $1000 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance-1000
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + 1000,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $500 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + 500
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - 500,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $500 to account 103 balance
       UPDATE Bank.AccountBalance
       SET Balance = 'sd'                   -- Potential Error
       WHERE AccountId = 103;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               103,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103) - 500,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
              OR AccountId = 103;
        
        -- Print that updates are done successfully
        PRINT CHAR(10) + 'Balance updates are done successfully !';

        -- Commit the transaction
        COMMIT;
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	8) Demonstrate CONSISTENCY by writing a transaction that ensures the total balance across
       all accounts remains constant.
       Calculate total before and after transfer.
=============================================================================================*/
-- Display sum balances of all accounts before balances update
GO
SELECT SUM(Balance) AS SumOfBalancesBeforeUpdate
FROM Bank.AccountBalance

-- Create the transaction
BEGIN TRANSACTION 
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Deduct $1500 from account 101 balance 
    UPDATE Bank.AccountBalance
    SET Balance = Balance-1500
    WHERE AccountId = 101;

    -- Log the operation into AuditTrail Table
    INSERT INTO Bank.AuditTrail(TableName,
                                Operation,
                                RecordId,
                                OldValue,
                                NewValue,
                                AuditDate,
                                UserName)
    VALUES ('AccountBalance',
            'Update Balance',
            101,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + 1500,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
            SYSDATETIME(),
            SYSTEM_USER);

    -- Add $500 to account 102 balance
    UPDATE Bank.AccountBalance
    SET Balance = Balance + 500
    WHERE AccountId = 102;

    -- Log the operation into AuditTrail Table
    INSERT INTO Bank.AuditTrail(TableName,
                                Operation,
                                RecordId,
                                OldValue,
                                NewValue,
                                AuditDate,
                                UserName)
    VALUES ('AccountBalance',
            'Update Balance',
            102,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - 500,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
            SYSDATETIME(),
            SYSTEM_USER);

    -- Add $500 to account 103 balance
    UPDATE Bank.AccountBalance
    SET Balance = Balance + 500                   
    WHERE AccountId = 103;

    -- Log the operation into AuditTrail Table
    INSERT INTO Bank.AuditTrail(TableName,
                                Operation,
                                RecordId,
                                OldValue,
                                NewValue,
                                AuditDate,
                                UserName)
    VALUES ('AccountBalance',
            'Update Balance',
            103,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103) - 500,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103),
            SYSDATETIME(),
            SYSTEM_USER);
    
    -- Add $500 to account 104 balance
    UPDATE Bank.AccountBalance
    SET Balance = Balance + 500                   
    WHERE AccountId = 104;

    -- Log the operation into AuditTrail Table
    INSERT INTO Bank.AuditTrail(TableName,
                                Operation,
                                RecordId,
                                OldValue,
                                NewValue,
                                AuditDate,
                                UserName)
    VALUES ('AccountBalance',
            'Update Balance',
            104,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 104) - 500,
            (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 104),
            SYSDATETIME(),
            SYSTEM_USER);

    -- Print that updates are done successfully
    PRINT CHAR(10) + 'Balance updates are done successfully !';

    -- Commit the transaction
    COMMIT;

-- Display sum balances of all accounts after balances update
SELECT SUM(Balance) AS SumOfBalancesAfterUpdate
FROM Bank.AccountBalance

/*===========================================================================================
	9) Demonstrate ISOLATION by setting different isolation levels and explaining their 
       effects. Use READ UNCOMMITTED, READ COMMITTED, and SERIALIZABLE.
=============================================================================================*/
/****************************************************************
    Note:The solution of this Q is divided between this session 
         and HelperParallelSessionForTransactionProofs session
*****************************************************************/
-- READ UNCOMMITTED --
/*--------------------------------------------------
    This isolation level may introduce potential 
    - Dirty Reads
    - Non-Repeatable Reads 
    - Phantom Reads
    in concurrent transactions
--------------------------------------------------*/
-- 1) Potential Dirty Read Scenario (Not Prevented)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT AccountId,               
           Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 2) Potential Non-Repeatable Read Scenario (Not Prevented)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

   -- Get balance amount of account 101 again
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 3) Potential Phantom Reads Scenario (Not Prevented)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION
    -- Get number of accounts on the system
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

    -- Get number of accounts on the system again
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Commit the transaction
    COMMIT;

-- READ COMMITTED --
/*--------------------------------------------------
    This isolation level prevents Dirty Reads issue 
    but may introduce potential
    - Non-Repeatable Reads 
    - Phantom Reads
    in concurrent transactions
--------------------------------------------------*/
-- 1) Potential Dirty Read Scenario (Prevented)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT AccountId,               
           Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 2) Potential Non-Repeatable Read Scenario (Not Prevented)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

   -- Get balance amount of account 101 again
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 3) Potential Phantom Reads Scenario (Not Prevented)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION
    -- Get number of accounts on the system
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

    -- Get number of accounts on the system again
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Commit the transaction
    COMMIT;

-- SERIALIZABLE --
/*--------------------------------------------------
    This isolation level prevents Dirty Read and 
    Non-Repeatable reads in concurrent transactions
    but must be used wisely to avoid deadlocks
--------------------------------------------------*/
-- 1) Potential Dirty Read Scenario (Prevented)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT AccountId,               
           Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 2) Potential Non-Repeatable Read Scenario (Prevented)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION
    -- Get balance amount of account 101
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

   -- Get balance amount of account 101 again
    SELECT Balance
    FROM Bank.AccountBalance
    WHERE AccountId = 101;

    -- Commit the transaction
    COMMIT;

-- 3) Potential Phantom Reads Scenario (Prevented)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION
    -- Get number of accounts on the system
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Set a delay for 10 secs 
    WAITFOR DELAY '00:00:10';

    -- Get number of accounts on the system again
    SELECT COUNT(*)
    FROM Bank.AccountBalance

    -- Commit the transaction
    COMMIT;

/*===========================================================================================
	10) Demonstrate DURABILITY by committing a transaction and explaining that the changes 
        will persist even after system restart or failure
=============================================================================================*/
/****************************************************************
    Note:The solution of this Q is divided between this session 
         and HelperParallelSessionForTransactionProofs session
*****************************************************************/
-- Create an open transaction without committing it
BEGIN TRANSACTION
    -- Update balance of account 101 to $600
    UPDATE Bank.AccountBalance
    SET Balance = 600
    WHERE AccountId = 101
    -- leave it open without commit

-- Get current session id
SELECT @@SPID

-- KILL @@SPID --> kill from another session but on the same database

-- Check if account 101 balance is updated although the transaction was not committed 
SELECT AccountId,
       Balance
FROM Bank.AccountBalance
WHERE AccountId = 101

/*===========================================================================================
	11) Write a stored procedure that uses transactions to transfer
        - money between two accounts. Include parameter validation,
        - error handling, and proper transaction management.
=============================================================================================*/
-- Create a stored procedure called sp_TransferMoney
GO
CREATE OR ALTER PROCEDURE sp_TransferMoney @AmountToBeTransfered INT, 
                                           @FromAccountNumber INT,
                                           @ToAccountNumber INT
AS
BEGIN 
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION 
          -- Variable Definitions
          DECLARE @FromAccountCurrentBalance DECIMAL(18,2);
          DECLARE @ErrorMsg VARCHAR(MAX);

          -- Check if FromAccount already exists
          IF NOT EXISTS (SELECT 1 FROM Bank.AccountBalance WHERE AccountId = @FromAccountNumber)
          BEGIN
            -- Set Error Msg
            SET @ErrorMsg = CONCAT(@FromAccountNumber , ' is invalid and doesn''t exist on the system !');

            -- Raise an error that passed FromAccount is not existing
            ;THROW 50002,@ErrorMsg,1;
          END

          -- Check if ToAccount already exists
          IF NOT EXISTS (SELECT 1 FROM Bank.AccountBalance WHERE AccountId = @ToAccountNumber)
          BEGIN
            -- Set Error Msg
            SET @ErrorMsg = CONCAT(@ToAccountNumber , ' is invalid and doesn''t exist on the system !');

            -- Raise an error that passed FromAccount is not existing
            ;THROW 50002,@ErrorMsg,1;
          END

          -- Get FromAccount current balance
          SELECT @FromAccountCurrentBalance = Balance
          FROM Bank.AccountBalance 
          WHERE AccountId = @FromAccountNumber

          -- Check if FromAccount has sufficient balance
          IF (@FromAccountCurrentBalance - @AmountToBeTransfered < 0)
          BEGIN 
            -- Set Error Msg
            SET @ErrorMsg = CONCAT('Account ' , @FromAccountNumber ,
                            ' has no sufficient balance to deduct $' , 
                            @AmountToBeTransfered , ' !');
            -- Raise an error that FromAccount has no sufficient balance
            ;THROW 50005,@ErrorMsg,1;
          END

          -- Display balances of accounts before the money transfer
          SELECT AccountId,
                 AccountName,
                 Balance AS BalanceBeforeMoneyTransfer
          FROM Bank.AccountBalance
          WHERE AccountId = @FromAccountNumber 
                OR AccountId = @ToAccountNumber
      

           -- Deduct amount to be transfered from FromAccount balance 
           UPDATE Bank.AccountBalance
           SET Balance = Balance - @AmountToBeTransfered
           WHERE AccountId = @FromAccountNumber;

           -- Log the operation into AuditTrail Table
           INSERT INTO Bank.AuditTrail(TableName,
                                       Operation,
                                       RecordId,
                                       OldValue,
                                       NewValue,
                                       AuditDate,
                                       UserName)
           VALUES ('AccountBalance',
                   'Update Balance',
                   @FromAccountNumber,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = @FromAccountNumber) + @AmountToBeTransfered,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = @FromAccountNumber),
                   SYSDATETIME(),
                   SYSTEM_USER)

           -- Add amount to be transfered to ToAccount balance 
           UPDATE Bank.AccountBalance
           SET Balance = Balance + @AmountToBeTransfered
           WHERE AccountId = @ToAccountNumber;

           -- Log the operation into AuditTrail Table
           INSERT INTO Bank.AuditTrail(TableName,
                                       Operation,
                                       RecordId,
                                       OldValue,
                                       NewValue,
                                       AuditDate,
                                       UserName)
           VALUES ('AccountBalance',
                   'Update Balance',
                   @ToAccountNumber,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = @ToAccountNumber) - @AmountToBeTransfered,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = @ToAccountNumber),
                   SYSDATETIME(),
                   SYSTEM_USER)

            -- Display balances of accounts after the money transfer
            SELECT AccountId,
                   AccountName,
                   Balance AS BalanceAfterMoneyTransfer
            FROM Bank.AccountBalance
            WHERE AccountId = @FromAccountNumber 
                  OR AccountId = @ToAccountNumber
        
            -- Print that money is transfered successfully from FromAccount to ToAccount
            PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
            ' is transfered successfully from account ' + CAST(@FromAccountNumber AS VARCHAR(1000)) +
            ' to account ' + CAST(@ToAccountNumber AS VARCHAR(1000)) + ' !';

            -- Commit the transaction
            COMMIT;

        -- Log the transfer into TransferHistory Table
        INSERT INTO Bank.TransferHistory(FromAccountId,     
                                         ToAccountId,
                                         Amount,
                                         TransferDate,
                                         Status)
        VALUES (@FromAccountNumber,    
                @ToAccountNumber,
                @AmountToBeTransfered,
                SYSDATETIME(),
                'Succeeded');
    END TRY
    BEGIN CATCH
        -- Check Trancount
        IF @@TRANCOUNT > 0
        BEGIN
            -- Rollback the whole transaction
            ROLLBACK;
        END

         -- Log the transfer into TransferHistory Table
        INSERT INTO Bank.TransferHistory(FromAccountId,     
                                         ToAccountId,
                                         Amount,
                                         TransferDate,
                                         Status,
                                         ErrorMessage)
        VALUES (@FromAccountNumber,    
                @ToAccountNumber,
                @AmountToBeTransfered,
                SYSDATETIME(),
                'Failed',
                ERROR_MESSAGE());

        -- Get error message, number, state and severity
        SELECT  ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE() AS ErrorMessage,
                ERROR_STATE() AS ErrorState,
                ERROR_SEVERITY() AS ErrorSeverity

        -- Print the error message
        PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
    END CATCH
END

-- Test the created stored procedure
-- Positive Scenario
EXECUTE sp_TransferMoney 500,
                         101,
                         103;
-- Negative Scenarios
EXECUTE sp_TransferMoney 20000,
                         101,
                         103;
EXECUTE sp_TransferMoney 20000,
                         105,
                         103;
EXECUTE sp_TransferMoney 20000,
                         103,
                         106;

/*===========================================================================================
	12) Write a transaction that uses multiple savepoints to handle
        - a multi-step operation. If step 2 fails, rollback to savepoint 1.
        - If step 3 fails, rollback to savepoint 2.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Variables Definitions
    DECLARE @AllBalancesUpdated BIT = 1;

    BEGIN TRANSACTION 
       -- Display balances of accounts before the money transfer
       SELECT AccountId,
               AccountName,
               Balance AS BalanceBeforeMoneyTransfer
       FROM Bank.AccountBalance
       WHERE AccountId = 101 
                OR AccountId = 102
                OR AccountId = 103;

       -- Deduct $1000 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - 1000
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + 1000,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)
       -- Save the transaction at this point (Step 1)
       SAVE TRANSACTION Step1;

       -- Deduct $1000 from account 102 balance
       BEGIN TRY
           UPDATE Bank.AccountBalance
           SET Balance = Balance - 1000                   
           WHERE AccountId = 102;

           -- Log the operation into AuditTrail Table
           INSERT INTO Bank.AuditTrail(TableName,
                                       Operation,
                                       RecordId,
                                       OldValue,
                                       NewValue,
                                       AuditDate,
                                       UserName)
           VALUES ('AccountBalance',
                   'Update Balance',
                   102,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) + 1000,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
                   SYSDATETIME(),
                   SYSTEM_USER)
      
           -- Save the transaction at this point (Step 2)
           SAVE TRANSACTION Step2;
       END TRY
       BEGIN CATCH
           -- Check Trancount
           IF @@TRANCOUNT > 0
           BEGIN
               -- Rollback the transaction to Step1 savepoint
               ROLLBACK TRANSACTION Step1;     

               -- Reset @AllBalancesUpdated variable
               SET @AllBalancesUpdated = 0;
           END
       
           -- Get error message, number, state and severity
           SELECT  ERROR_NUMBER() AS ErrorNumber,
                   ERROR_MESSAGE() AS ErrorMessage,
                   ERROR_STATE() AS ErrorState,
                   ERROR_SEVERITY() AS ErrorSeverity
       
           -- Print the error message
           PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
       END CATCH

       -- Deduct $1000 from account 103 balance
       BEGIN TRY
           UPDATE Bank.AccountBalance
           SET Balance = Balance - 1000                  
           WHERE AccountId = 103;

           -- Log the operation into AuditTrail Table
           INSERT INTO Bank.AuditTrail(TableName,
                                       Operation,
                                       RecordId,
                                       OldValue,
                                       NewValue,
                                       AuditDate,
                                       UserName)
           VALUES ('AccountBalance',
                   'Update Balance',
                   103,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103) + 1000,
                   (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 103),
                   SYSDATETIME(),
                   SYSTEM_USER)
           
           -- Check if all balances are updated successfully 
           IF @AllBalancesUpdated = 1
           BEGIN
               -- Print that updates are done successfully
               PRINT CHAR(10) + 'Balance updates are done successfully !';
           END
       END TRY
       BEGIN CATCH
           -- Check Trancount
           IF @@TRANCOUNT > 0
           BEGIN
               -- Rollback the transaction to Step2 savepoint
               ROLLBACK TRANSACTION Step2;         
           END
       
           -- Get error message, number, state and severity
           SELECT  ERROR_NUMBER() AS ErrorNumber,
                   ERROR_MESSAGE() AS ErrorMessage,
                   ERROR_STATE() AS ErrorState,
                   ERROR_SEVERITY() AS ErrorSeverity
           
           -- Print the error message
           PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
       END CATCH

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
              OR AccountId = 103;

        -- Commit the transaction
        COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Check Trancount
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

/*===========================================================================================
	13) - Write a transaction that handles a deadlock scenario using TRY...CATCH. 
        Retry the operation if a deadlock is detected.
=============================================================================================*/
/****************************************************************
    Note:The solution of this Q is divided between this session 
         and HelperParallelSessionForTransactionProofs session
*****************************************************************/
-- Create the transaction 
-- (Tested by running in parallel with other transaction in other session consuming the 
-- same resources (table and rows) but with different order)
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        -- Try to update balance of account 101 while other transaction try to update account 102 balance
        -- (Potential Deadlock)
        UPDATE Bank.AccountBalance
        SET Balance = 100
        WHERE AccountId = 101;

        -- Set a delay of 10 secs keeping the resourse locked until delay is passed
        WAITFOR DELAY '00:00:10'; 
        /*-------------------------------------------------------------------------------------------
           Here deadlock occurs cause this session is locking row 101 and needs to update on 
           row 102 locked by other session while other parallel session is locking row 102 and needs 
           to update on row 101 locked by current session
        --------------------------------------------------------------------------------------------*/

        -- Try to update balance of account 102 while other transaction try to update account 101 balance
        UPDATE Bank.AccountBalance
        SET Balance = 600
        WHERE AccountId = 102;
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

/*===========================================================================================
	14) Write a query to check the current transaction count (@@TRANCOUNT) and demonstrate 
        how it changes within nested transactions.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRANSACTION
    -- Disable COUNT messages
    SET NOCOUNT ON;

    -- Print the TRANCOUNT of the first level transaction
    SELECT @@TRANCOUNT AS TranCountOfFirstLevel;
    PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));

    BEGIN TRANSACTION
        -- Print the TRANCOUNT of the second level transaction
        SELECT @@TRANCOUNT AS TranCountOfSecondLevel;     
        PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));
            
        BEGIN TRANSACTION
            -- Print the TRANCOUNT of the third level transaction
            SELECT @@TRANCOUNT AS TranCountOfThirdLevel
            PRINT CHAR(10) + 'Transaction Count = ' + CAST(@@TRANCOUNT AS VARCHAR(400));
            
            -- Commit third level transaction
            COMMIT;

        -- Commit second level transaction
        COMMIT;

    -- Commit first level transaction
    COMMIT;

/*===========================================================================================
	15) Write a transaction that logs all changes to the AuditTrail table.
        Include before and after values for updates.
=============================================================================================*/
-- Create the transaction
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION 
      -- Display balances of accounts before the money transfer
      SELECT AccountId,
             AccountName,
             Balance AS BalanceBeforeMoneyTransfer
      FROM Bank.AccountBalance
      WHERE AccountId = 101 
            OR AccountId = 102
      
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 500;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $500 !',1;
      END

       -- Deduct $500 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $500 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Commit the transaction
        COMMIT;

    -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Succeeded');
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

-- Check Audit Trial after updates are committed from previous transaction
SELECT * FROM Bank.AuditTrail

/*===========================================================================================
	16) Write a transaction that demonstrates the difference between COMMIT and ROLLBACK by 
        creating two identical transactions, committing one and rolling back the other.
=============================================================================================*/
-- Create the transaction
BEGIN TRANSACTION
    SELECT AccountId,
           Balance 
    FROM Bank.AccountBalance WITH (HOLDLOCK)
    WHERE AccountId = 101;

     WAITFOR DELAY '00:00:10';

     SELECT AccountId,
            Balance 
    FROM Bank.AccountBalance WITH (HOLDLOCK)
    WHERE AccountId = 102;
COMMIT;

BEGIN TRANSACTION
    UPDATE Bank.AccountBalance
    SET Balance = 200
    WHERE AccountId = 101;

     WAITFOR DELAY '00:00:10';

     UPDATE Bank.AccountBalance
     SET Balance = 500
     WHERE AccountId = 102;
COMMIT;

/*===========================================================================================
	17) Write a transaction that enforces a business rule: "Total withdrawals in a single 
        transaction cannot exceed $5000".
        If violated, rollback the transaction.
=============================================================================================*/
-- Create the transaction
BEGIN TRY
    -- Disable COUNT messages 
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        -- Display balances of accounts before the money withdrawals
        SELECT AccountId,
                AccountName,
                Balance AS BalanceBeforeMoneyWithdrawal
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
              OR AccountId = 103

        -- Variables Definitions
        DECLARE @TotalWithdrawals DECIMAL(18,2) = 0;
        DECLARE @ErrorMsg VARCHAR(MAX) ; 

        -- Withdraw $4000 from account 103 balance
        UPDATE Bank.AccountBalance
        SET Balance = Balance - 3000                  
        WHERE AccountId = 101;

        -- Update @TotalWithdrawals
        SET @TotalWithdrawals = @TotalWithdrawals + 3000;

        -- Withdraw $1000 from account 102 balance
        UPDATE Bank.AccountBalance
        SET Balance = Balance - 1000                  
        WHERE AccountId = 102;

        -- Update @TotalWithdrawals
        SET @TotalWithdrawals = @TotalWithdrawals + 1000;

        -- Withdraw $1000 from account 103 balance
        UPDATE Bank.AccountBalance
        SET Balance = Balance - 1000                  
        WHERE AccountId = 103;

        -- Update @TotalWithdrawals
        SET @TotalWithdrawals = @TotalWithdrawals + 1000;

        -- Check if Total withdrawals exceed $5000
        IF @TotalWithdrawals > 5000
        BEGIN
            -- Set error message
            SET @ErrorMsg = CONCAT('Maximum withdraw per transaction is $5000.00 while you are trying to withdraw $',@TotalWithdrawals,' !');
            -- Throw an error stating that maximum withdraw per transaction is $5000
            ;THROW 50020,@ErrorMsg,1;
        END

        -- Display balances of accounts after the money withdrawals
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyWithdrawal
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
              OR AccountId = 103;

        -- Commit the transaction
        COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	18) Write a transaction that uses explicit locking hints (WITH (UPDLOCK)) to prevent 
        concurrent modifications during a transfer
=============================================================================================*/
GO
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION  
      -- Variable Definitions
      DECLARE @Account101CurrentBalance DECIMAL(18,2);
      DECLARE @AmountToBeTransfered DECIMAL(18,2) = 500;

      -- Get account 101 current balance
      SELECT @Account101CurrentBalance = Balance
      FROM Bank.AccountBalance 
      WHERE AccountId = 101

      -- Check if account 101 has sufficient balance
      IF (@Account101CurrentBalance - @AmountToBeTransfered < 0)
      BEGIN 
        -- Raise an error that account 101 has no sufficient balance
        ;THROW 50005,'Account 101 has no sufficient balance to deduct $500 !',1;
      END

       -- Set UPDLOCK on rows where AccountId is 101 and 102 respectivily on Bank.AccountBalance table
       -- to prevent concurrent modifications during a transfer
       SELECT 1
       FROM Bank.AccountBalance WITH (UPDLOCK)
       WHERE AccountId = 101;

       SELECT 1
       FROM Bank.AccountBalance WITH (UPDLOCK)
       WHERE AccountId = 102;

       -- Display balances of accounts before the money transfer
       SELECT AccountId,
              AccountName,
              Balance AS BalanceBeforeMoneyTransfer
       FROM Bank.AccountBalance
       WHERE AccountId = 101 
             OR AccountId = 102

       -- Deduct $500 from account 101 balance 
       UPDATE Bank.AccountBalance
       SET Balance = Balance - @AmountToBeTransfered
       WHERE AccountId = 101;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               101,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) + @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101),
               SYSDATETIME(),
               SYSTEM_USER)

       -- Add $500 to account 102 balance
       UPDATE Bank.AccountBalance
       SET Balance = Balance + @AmountToBeTransfered
       WHERE AccountId = 102;

       -- Log the operation into AuditTrail Table
       INSERT INTO Bank.AuditTrail(TableName,
                                   Operation,
                                   RecordId,
                                   OldValue,
                                   NewValue,
                                   AuditDate,
                                   UserName)
       VALUES ('AccountBalance',
               'Update Balance',
               102,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102) - @AmountToBeTransfered,
               (SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 102),
               SYSDATETIME(),
               SYSTEM_USER)

        -- Display balances of accounts after the money transfer
        SELECT AccountId,
               AccountName,
               Balance AS BalanceAfterMoneyTransfer
        FROM Bank.AccountBalance
        WHERE AccountId = 101 
              OR AccountId = 102
        
        -- Print that money is transfered successfully from account 101 to account 102
        PRINT CHAR(10) + '$' + CAST(@AmountToBeTransfered AS VARCHAR(1000)) +
        ' is transfered successfully from account 101 to account 102';

        -- Commit the transaction
        COMMIT;

    -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Succeeded');
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;
    END

     -- Log the transfer into TransferHistory Table
    INSERT INTO Bank.TransferHistory(FromAccountId,     
                                     ToAccountId,
                                     Amount,
                                     TransferDate,
                                     Status,
                                     ErrorMessage)
    VALUES (101,    
            102,
            @AmountToBeTransfered,
            SYSDATETIME(),
            'Failed',
            ERROR_MESSAGE());

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity

    -- Print the error message
    PRINT CHAR(10) + 'Error (' + CAST(ERROR_NUMBER() AS VARCHAR(1000)) + ') : ' + CAST(ERROR_MESSAGE() AS VARCHAR(5000));
END CATCH

/*===========================================================================================
	19) Write a comprehensive error handling transaction that catches specific error numbers 
        and handles them differently.
        Handle: Constraint violations, insufficient funds, and general errors
=============================================================================================*/
-- Create the transaction
BEGIN TRY
    -- Disable COUNT messages
    SET NOCOUNT ON;

    BEGIN TRANSACTION
        -- Variable Definitions
        DECLARE @AmountOfBalanceToBeInserted DECIMAL (18,2) = 5000;  
        DECLARE @AmountOfBalanceToBeWithdrawed DECIMAL (18,2) = 200; 
        DECLARE @ErrorMsg VARCHAR(MAX);

        -- Try to add new account to Bank.AccountBalance with negative balance value
        INSERT INTO Bank.AccountBalance 
        VALUES(105,
               'Donation Account',
               @AmountOfBalanceToBeInserted,
               SYSDATETIME());

        -- Try to withdraw from account 101
        -- Check if account 101 has a sufficient balance
        IF ((SELECT Balance FROM Bank.AccountBalance WHERE AccountId = 101) < @AmountOfBalanceToBeWithdrawed)
        BEGIN 
              -- Throw an error stating insufficient balance
              ;THROW 50005,'Insufficient Fund Error !',1;
        END
        
        UPDATE Bank.AccountBalance
        SET Balance = @AmountOfBalanceToBeWithdrawed 
        WHERE AccountId = 101;

        -- Update balance with undefined value like a value divided by 0
        UPDATE Bank.AccountBalance
        SET Balance = @AmountOfBalanceToBeWithdrawed / 0
        WHERE AccountId = 102;
      
END TRY
BEGIN CATCH
    -- Check Trancount
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rollback the whole transaction
        ROLLBACK;

        -- Check error number of catched error
        IF(ERROR_NUMBER() = 2627 OR ERROR_NUMBER() = 547 OR ERROR_NUMBER() = 2601 OR ERROR_NUMBER() = 515)
        BEGIN
            -- Print constraint-related error message
            SET @ErrorMsg = 'Constraint Violation Error !';
            PRINT CHAR(10) + @ErrorMsg;
        END
        ELSE IF (ERROR_NUMBER() = 50005)
        BEGIN
            -- Print insufficient fund related error message
            SET @ErrorMsg = 'Insufficient Fund Error !';
            PRINT CHAR(10) + @ErrorMsg;
        END
        ELSE
        BEGIN
            -- Print general error message
            SET @ErrorMsg = 'General Error !';
            PRINT CHAR(10) + @ErrorMsg;    
        END
    END

    -- Get error message, number, state and severity
    SELECT  ERROR_NUMBER() AS ErrorNumber,
            @ErrorMsg AS ErrorMessage,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity
END CATCH

/*===========================================================================================
	20) Write a transaction monitoring query that shows all active transactions in the 
        database, including their status, start time and session information.
=============================================================================================*/
SELECT ExceSession.session_id,
       TranActive.transaction_id,
       TranActive.transaction_state,
       TranActive.transaction_status,
       TranActive.transaction_status2,
       TranActive.transaction_begin_time
FROM sys.dm_tran_active_transactions AS TranActive
INNER JOIN  sys.dm_tran_session_transactions AS TranSession
ON TranActive.transaction_id = TranSession.transaction_id
INNER JOIN sys.dm_exec_sessions AS ExceSession
ON ExceSession.session_id = TranSession.session_id;