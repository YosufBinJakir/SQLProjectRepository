CREATE DATABASE diagonsticscenter
GO
USE diagonsticscenter
GO
CREATE TABLE testtypes
(	
	typeid INT PRIMARY KEY,
	typename	NVARCHAR(40) NOT NULL UNIQUE
)
GO
CREATE TABLE tests
(	
	testid INT PRIMARY KEY,
	testname	NVARCHAR(40) NOT NULL,
	fee MONEY NOT NULL,
	typeid INT NOT NULL REFERENCES testtypes (typeid)
)
GO
CREATE TABLE testentries
(
	entryid INT NOT NULL PRIMARY KEY,
	patientname NVARCHAR(50) NOT NULL,
	dateofbirth DATE NOT NULL,
	mobileno NVARCHAR(20) NOT NULL,
	testdate DATE NOT NULL DEFAULT GETDATE(),
	duedate DATE NOT NULL,
	[status] BIT NOT NULL
)
GO
CREATE TABLE entrytests
(
	entryid INT NOT NULL REFERENCES testentries(entryid),
	testid INT NOT NULL REFERENCES tests(testid),
	PRIMARY KEY (entryid, testid)
)
GO
/*
 * Procedures 
 * */
-- for test types
CREATE PROCEDURE spinserttype  @name NVARCHAR(40), @id INT OUTPUT
AS
BEGIN TRY
	SELECT @id=ISNULL(MAX(typeid),0)+1 FROM testtypes
	INSERT INTO testtypes (typeid, typename)
	VALUES (@id, @name)
	RETURN @@ROWCOUNT
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
	RETURN 0
END CATCH
GO
CREATE PROCEDURE spupdatetype @id INT, @name NVARCHAR(40)
AS
BEGIN TRY
	UPDATE testtypes 
	SET typename=@name
	WHERE typeid = @id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROCEDURE spdeletetype @id INT
AS
BEGIN TRY
	DELETE testtypes 
	WHERE typeid = @id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
-- for tests
CREATE PROCEDURE spinserttest @id INT, @name NVARCHAR(40), @fee MONEY, @typeid INT
AS
BEGIN TRY
	INSERT INTO tests (testid, testname,fee, typeid)
	VALUES (@id, @name,@fee, @typeid)
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROCEDURE spupdatetest @id INT, @name NVARCHAR(40), @fee MONEY, @typeid INT
AS
BEGIN TRY
	UPDATE tests 
	SET testname=@name, fee=@fee, typeid=@typeid
	WHERE testid = @id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROCEDURE spdeletetest @id INT
AS
BEGIN TRY
	DELETE tests 
	WHERE testid = @id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
--for testentry
CREATE PROCEDURE spinserttestentry @id INT,
	@patient NVARCHAR(50) ,
	@dob DATE ,
	@mobile NVARCHAR(20),
	@testdate DATE = NULL,
	@duedate DATE = NULL
AS
BEGIN TRY
	INSERT INTO testentries (entryid, patientname, dateofbirth, mobileno, testdate, duedate, [status])
	VALUES (@id, @patient, @dob, @mobile, ISNULL(@testdate, GETDATE()), ISNULL(@duedate, GETDATE()), 0)
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROCEDURE spupdatetestentry  @id INT,
	@patient NVARCHAR(50) ,
	@dob DATE ,
	@mobile NVARCHAR(20),
	@testdate DATE ,
	@duedate DATE ,
	@status BIT

AS
BEGIN TRY
	UPDATE testentries 
	SET patientname= @patient, dateofbirth=@dob, mobileno=@mobile, testdate=@testdate, duedate=@duedate, [status]=@status
	WHERE entryid=@id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROCEDURE spdeletetestentry @id INT
AS
BEGIN TRY
	DELETE testentries 
	WHERE entryid = @id
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROC spinsertentrytest @eid INT, @tid INT
AS
BEGIN TRY
	INSERT INTO entrytests (entryid, testid)
	VALUES (@eid, @tid)
	
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROC spupdateentrytest @eid INT, @tid INT
AS
BEGIN TRY
	UPDATE entrytests 
	SET entryid=@eid, testid=@tid
	WHERE entryid = @eid AND testid = @tid
	
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
CREATE PROC spdeleteentrytest @eid INT, @tid INT
AS
BEGIN TRY
	DELETE entrytests 
	
	WHERE entryid = @eid AND testid = @tid
	
END TRY
BEGIN CATCH 
	DECLARE @err NVARCHAR(500)
	SELECT @err = ERROR_MESSAGE()
	RAISERROR(@err, 16, 1)
END CATCH
GO
/*
 * Views
 * */
--all data
CREATE VIEW vAll
AS
SELECT tt.typename, t.testname, t.fee, te.patientname, te.dateofbirth, te.mobileno, te.testdate, te.duedate, te.[status]
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GO
CREATE VIEW vDueTests
AS
SELECT te.patientname, te.dateofbirth, te.mobileno, tt.typename, t.testname, t.fee, te.testdate
FROM testentries te
INNER JOIN entrytests et ON te.entryid = et.entryid
INNER JOIN tests t ON et.testid = t.testid
INNER JOIN testtypes tt ON t.typeid = tt.typeid
WHERE te.[status]=0
GO
CREATE VIEW vReportCurrentMonth
AS
SELECT  t.testname,  COUNT(*) 'count', SUM(t.fee) 'total'
FROM testentries te
INNER JOIN entrytests et ON te.entryid = et.entryid
INNER JOIN tests t ON et.testid = t.testid
INNER JOIN testtypes tt ON t.typeid = tt.typeid
WHERE YEAR(testdate) = YEAR(GETDATE()) AND MONTH(testdate) = MONTH(GETDATE())
GROUP BY t.testname
GO
/*
 * Functions
 * */
CREATE FUNCTION fnReportsInDates(@from DATE, @to DATE) RETURNS TABLE
AS
RETURN (SELECT te.patientname, te.dateofbirth, te.mobileno, tt.typename, t.testname, t.fee, te.testdate
FROM testentries te
INNER JOIN entrytests et ON te.entryid = et.entryid
INNER JOIN tests t ON et.testid = t.testid
INNER JOIN testtypes tt ON t.typeid = tt.typeid
WHERE testdate BETWEEN @from AND @to
)
GO
CREATE FUNCTION fnReportInDates(@from DATE, @to DATE)RETURNS TABLE
AS
RETURN (
	SELECT  t.testname,  COUNT(*) 'count', SUM(t.fee) 'total'
	FROM testentries te
	INNER JOIN entrytests et ON te.entryid = et.entryid
	INNER JOIN tests t ON et.testid = t.testid
	INNER JOIN testtypes tt ON t.typeid = tt.typeid
	WHERE testdate BETWEEN @from AND @to
	GROUP BY t.testname
)
GO
CREATE TRIGGER trentrytest 
ON entrytests 
INSTEAD OF INSERT 
AS
BEGIN
	DECLARE @ti INT, @ei INT
	SELECT @ei = entryid, @ti=testid FROM inserted
	IF EXISTS( SELECT 1 FROM entrytests WHERE testid = @ti AND entryid = @ei)
	BEGIN
		RAISERROR( 'Already exists', 16, 1)
	END
	ELSE
	BEGIN
		INSERT INTO entrytests (entryid, testid) 
		VALUES (@ei, @ti)
	END
END
GO
CREATE TRIGGER trupdatetest 
ON tests
AFTER UPDATE
AS
BEGIN
	DECLARE @of MONEY, @nf MONEY
	SELECT @of = fee FROM deleted
	SELECT @nf = fee FROM inserted
	IF UPDATE(fee)
	BEGIN
		IF @nf < @of*.80
		BEGIN
			ROLLBACK TRAN
			RAISERROR( 'Cannot lower fee more than 20 percent', 16, 1)
		END
	END
END
GO
CREATE TRIGGER trdeleteentrytest
ON entrytests
AFTER DELETE
AS
BEGIN
	DECLARE @ei INT, @status BIT
	SELECT @ei = entryid FROM deleted
	SELECT @status =[status]
	FROM testentries
	WHERE entryid = @ei
	IF @status = 1
	BEGIN
		ROLLBACK TRAN
		RAISERROR('Cannot delete completed test', 16, 1)
	END
END