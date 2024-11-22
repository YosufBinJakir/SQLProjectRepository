USE diagonsticscenter
GO
/*
 * Sample data
 * */
INSERT INTO testtypes (typeid, typename) VALUES (1, 'Blood')
INSERT INTO testtypes (typeid, typename) VALUES (2, 'Urine')
INSERT INTO testtypes (typeid, typename) VALUES (3, 'ECG')
GO
SELECT * FROM testtypes
GO
INSERT INTO tests (testid, testname, fee, typeid)
VALUES 
(1, 'CBC', 670.00, 1),
(2, 'BMP', 1400, 1),
(3, 'CMP', 2700.00, 1),
(4, 'Lipid panel (LDL)', 1700.00, 1),
(5, 'Lipid panel (HDL)', 3500.00, 1)
GO 
INSERT INTO tests (testid, testname, fee, typeid)
VALUES 
(6, 'RBC', 150.00, 2),
(7, 'WBC', 150, 2),
(8, 'Creatinine', 700.00, 2)
GO 
INSERT INTO tests (testid, testname, fee, typeid)
VALUES 
(9, 'ECG (R)', 450.00, 3),
(10, 'ECG (Ex)', 450, 3),
(11, 'ECG (Ambulatory)', 600.00, 3)
GO 
SELECT * FROM tests
GO
/*
 * Test procedures
 */
 DECLARE @id INT
 EXEC spinserttype 'X-Ray', @id OUTPUT
 SELECT @id AS 'New Id'
--EXEC spinserttype  'X-Ray', @id OUTPUT --fails, name duplicate
GO
SELECT * FROM testtypes
GO
EXEC spupdatetype 4, 'X-Ray1'
GO
SELECT * FROM testtypes
GO
EXEC spupdatetype 4, 'X-Ray'
GO
SELECT * FROM testtypes
GO
INSERT INTO testtypes VALUES (5, 'Test')
GO
SELECT * FROM testtypes
GO
EXEC spdeletetype 5
GO
SELECT * FROM testtypes
GO
EXEC spinserttest 12, 'Sugar (R)', 100, 1
EXEC spinserttest 13, 'Sugar (BF)', 100, 1
EXEC spinserttest 14, 'Sugar (AF)', 100, 1
GO
EXEC spupdatetest 12, 'Sugar (R)', 120, 1
GO
EXEC spdeletetest 14
GO
SELECT * FROM tests
GO
EXEC spinserttestentry 1, 'Monirul Islam', '1981-07-12', '01867XXXXXX'
EXEC spinserttestentry 2, 'Jakirul Islam', '1981-07-12', '01867XXXXXX', '2022-03-01', '2022-03-06'
GO
SELECT * FROM testentries
GO
EXEC spupdatetestentry 2, 'Jakirul Islam', '1981-07-12', '01867XXXXXX', '2022-03-01', '2022-03-06', 1
GO
SELECT * FROM testentries
GO
EXEC spinsertentrytest 1, 2
EXEC spinsertentrytest 1, 3
EXEC spinsertentrytest 2, 11
EXEC spinsertentrytest 2, 3
GO
SELECT * FROM entrytests
GO
/*
 * Query
 */
--all data
SELECT tt.typename, t.testname, t.fee, te.patientname, te.dateofbirth, te.mobileno, te.testdate, te.duedate, te.[status]
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GO
--due entries
SELECT te.patientname, te.dateofbirth, te.mobileno, tt.typename, t.testname, t.fee, te.testdate
FROM testentries te
INNER JOIN entrytests et ON te.entryid = et.entryid
INNER JOIN tests t ON et.testid = t.testid
INNER JOIN testtypes tt ON t.typeid = tt.typeid
WHERE te.[status]=0
GO
--test wise report current month
SELECT  t.testname,  COUNT(*), SUM(t.fee)
FROM testentries te
INNER JOIN entrytests et ON te.entryid = et.entryid
INNER JOIN tests t ON et.testid = t.testid
INNER JOIN testtypes tt ON t.typeid = tt.typeid
WHERE YEAR(testdate) = YEAR(GETDATE()) AND MONTH(testdate) = MONTH(GETDATE())
GROUP BY t.testname
/*
 * Test views
 * */
SELECT * FROM vAll
GO
SELECT * FROM vDueTests
GO
SELECT * FROM vReportCurrentMonth

GO
/*
 * Test functions
 * */
SELECT * FROM fnReportsInDates('2022-03-01', '2022-03-10')
GO
SELECT * FROM fnReportInDates('2022-03-01', '2022-03-10')
GO
/*
 * Test triggers
 */
EXEC spinsertentrytest 1, 1
EXEC spinsertentrytest 1, 2 --error
GO
EXEC spupdatetest 12, 'Sugar (R)', 20, 1
GO
DELETE FROM entrytests
WHERE entryid=2 AND testid=3
GO
/*
 * --Queries added
 */

--1 Join Inner 
SELECT tt.typename, t.testname, t.fee, te.patientname, te.dateofbirth, te.mobileno, te.testdate, te.duedate, te.[status]
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GO
--2 Not delievered test
SELECT tt.typename, t.testname, t.fee, te.patientname, te.dateofbirth, te.mobileno, te.testdate, te.duedate, te.[status]
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
WHERE te.[status] = 0
--3 Delivered
SELECT tt.typename, t.testname, t.fee, te.patientname, te.dateofbirth, te.mobileno, te.testdate, te.duedate, te.[status]
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
WHERE te.[status] = 1
--4 Left join
SELECT tt.typename, t.testname, e.patientname, e.testdate
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
LEFT OUTER JOIN entrytests et ON et.testid = t.testid
LEFT OUTER JOIN testentries e ON et.entryid = e.entryid
--5 Same with CTE
SELECT tt.typename, t.testname, tx.patientname, tx.testdate
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
LEFT OUTER JOIN (
SELECT et.testid, e.entryid, e.patientname, e.testdate
FROM entrytests et
INNER JOIN testentries e ON et.entryid = e.entryid) tx ON  tx.testid = t.testid
GO
--6 OUTER not matched
SELECT tt.typename, t.testname
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
LEFT OUTER JOIN entrytests et ON et.testid = t.testid
LEFT OUTER JOIN testentries e ON et.entryid = e.entryid
WHERE e.entryid IS NULL
GO
--7 same using sub-query
SELECT tt.typename, t.testname
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
WHERE t.testid  NOT IN (SELECT testid FROM entrytests)
GO
--8 aggregate
SELECT tt.typename, t.testname, count(et.entryid), SUM(t.fee)
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GROUP BY tt.typename, t.testname
GO
--9 aggregate + having
SELECT tt.typename, t.testname, count(et.entryid) 'testtotal' , SUM(t.fee) 'feetotal'
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GROUP BY tt.typename, t.testname, t.testid
HAVING t.testid = 1
--10 window function
SELECT t.testname, 
count(et.testid) OVER(ORDER BY et.testid) 'testtotal', 
sum(t.fee) OVER(ORDER BY et.testid) 'testtotal',
ROW_NUMBER() OVER(ORDER BY et.testid) 'rownumber',
RANK() OVER(ORDER BY et.testid) 'rank',
DENSE_RANK() OVER(ORDER BY et.testid) 'denserank',
NTILE(2) OVER(ORDER BY et.testid) 'ntile'
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
INNER JOIN entrytests et ON t.testid = et.testid
INNER JOIN testentries te ON te.entryid = et.entryid
GO
--11 CASE
SELECT tt.typename, t.testname, 
CASE WHEN tx.patientname IS NULL THEN '-'
	ELSE tx.patientname
END 'patientname'
FROM testtypes tt
INNER JOIN tests t ON tt.typeid = t.typeid
LEFT OUTER JOIN (
SELECT et.testid, e.entryid, e.patientname, e.testdate
FROM entrytests et
INNER JOIN testentries e ON et.entryid = e.entryid) tx ON  tx.testid = t.testid
GO