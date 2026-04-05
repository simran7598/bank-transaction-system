CREATE DATABASE BankDB;
USE BankDB;

-- 1. Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15) NOT NULL,
    Address VARCHAR(200)
);
select * from Customers;
-- 2. Accounts Table
CREATE TABLE Accounts (
    AccountID INT IDENTITY PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountType VARCHAR(20) CHECK(AccountType IN ('Savings','Current')),
    Balance DECIMAL(12,2) DEFAULT 0 CHECK (Balance >= 0),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
select * from Accounts

-- 3. Transactions Table
CREATE TABLE Transactions (
    TxnID INT IDENTITY PRIMARY KEY,
    AccountID INT NOT NULL,
    TxnType VARCHAR(20) CHECK(TxnType IN ('Deposit','Withdraw','Transfer')),
    Amount DECIMAL(12,2) CHECK (Amount > 0),
    TxnDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);
select * from Transactions

-- 4. Users Table
CREATE TABLE Users (
    UserID INT IDENTITY PRIMARY KEY,
    Username VARCHAR(50) UNIQUE NOT NULL,
    PasswordHash VARCHAR(200) NOT NULL,
    Role VARCHAR(20) CHECK(Role IN ('Manager','Clerk'))
);

select * from Users

-- 5. Audit Log Table
CREATE TABLE Audit_Log (
    LogID INT IDENTITY PRIMARY KEY,
    ActionBy VARCHAR(50),
    ActionDesc VARCHAR(200),
    ActionTime DATETIME DEFAULT GETDATE()
);
select * from Audit_Log

INSERT INTO Customers (FullName, Email, Phone, Address)
VALUES ('Simran Kaur', 'simran@gmail.com', '9876543210', 'Delhi'),
       ('Rohit Sharma', 'rohit@gmail.com', '9898989898', 'Mumbai');

INSERT INTO Accounts (CustomerID, AccountType, Balance)
VALUES (1, 'Savings', 5000),
       (2, 'Current', 2000);

CREATE PROCEDURE DepositAmount
    @AccID INT,
    @Amt DECIMAL(12,2)
AS
BEGIN
    BEGIN TRANSACTION;

    UPDATE Accounts SET Balance = Balance + @Amt WHERE AccountID = @AccID;

    INSERT INTO Transactions (AccountID, TxnType, Amount) 
    VALUES (@AccID, 'Deposit', @Amt);

    COMMIT;
END;

CREATE PROCEDURE WithdrawAmount
    @AccID INT,
    @Amt DECIMAL(12,2)
AS
BEGIN
    BEGIN TRANSACTION;

    IF (SELECT Balance FROM Accounts WHERE AccountID = @AccID) < @Amt
    BEGIN
        ROLLBACK;
        PRINT 'Insufficient Balance!';
        RETURN;
    END

    UPDATE Accounts SET Balance = Balance - @Amt WHERE AccountID = @AccID;

    INSERT INTO Transactions (AccountID, TxnType, Amount) 
    VALUES (@AccID, 'Withdraw', @Amt);

    COMMIT;
END;

CREATE FUNCTION dbo.GetBalance(@AccID INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    RETURN (SELECT Balance FROM Accounts WHERE AccountID = @AccID);
END;

SELECT dbo.GetBalance(2);


CREATE TRIGGER trg_Audit_Accounts
ON Accounts
AFTER UPDATE
AS
BEGIN
    INSERT INTO Audit_Log (ActionBy, ActionDesc)
    SELECT SYSTEM_USER, 'Account updated: ' + CAST(i.AccountID AS VARCHAR)
    FROM inserted i;
END;
select * from Audit_Log

SELECT c.FullName, c.Phone, a.AccountType, a.Balance
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID;

CREATE VIEW View_Statement AS
SELECT c.FullName, a.AccountID, t.TxnType, t.Amount, t.TxnDate
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID;

CREATE LOGIN bank_clerk WITH PASSWORD='Clerk@123';
CREATE USER bank_clerk FOR LOGIN bank_clerk;

GRANT SELECT, INSERT ON Transactions TO bank_clerk;
REVOKE DELETE ON Accounts FROM bank_clerk;
delete from Transactions
DELETE FROM Accounts WHERE AccountID = 1;

BEGIN TRANSACTION;

UPDATE Accounts SET Balance = Balance - 1000 WHERE AccountID = 1;
UPDATE Accounts SET Balance = Balance + 1000 WHERE AccountID = 2;

COMMIT;

INSERT INTO Users (Username, PasswordHash, Role)
VALUES ('manager1', '1234', 'Manager');

SELECT * FROM Users
WHERE Username='manager1' AND PasswordHash='1234';

CREATE PROCEDURE CheckBalance
    @AccountID INT
AS
BEGIN
    SELECT AccountID, Balance 
    FROM Accounts 
    WHERE AccountID = @AccountID;
END;


EXEC CheckBalance 2;

EXEC DepositAmount 2, 2000;
EXEC WithdrawAmount 2, 2000;

SELECT * FROM View_Statement WHERE AccountID = 2;

CREATE PROCEDURE GetAllTransactions
AS
SELECT * FROM Transactions;
select * from Customers
select * from Accounts
select * from Audit_Log
select * from Transactions
