/*
truncate table tdq.alpha_Log;
GO
ALTER TABLE tdq.alpha_cases SET (SYSTEM_VERSIONING=OFF);
GO
DROP TABLE tdq.alpha_casehistory;
truncate table tdq.alpha_cases;
--ALTER TABLE tdq.alpha_cases ADD PERIOD FOR SYSTEM_TIME([Identified],[Resolved]);;
ALTER TABLE tdq.alpha_cases SET (SYSTEM_VERSIONING=ON(HISTORY_TABLE=[tdq].[alpha_CaseHistory]))
truncate table tdq.alpha_measurements;
*/

EXEC [tdq].[alpha_Schedule]
--select * from tdq.alpha_Measures
--select * from [tdq].[alpha_MeasurementJobs]

Select * from tdq.alpha_Log
order by LogEntryID desc
select * from tdq.alpha_Measurements ORDER BY MeasurementID DESC, MeasureID
select * from tdq.alpha_Cases ORDER BY MeasurementID DESC, MeasureID
select * from tdq.alpha_CaseHistory ORDER BY MeasurementID DESC, MeasureID;
--SELECT TOP 1 * INTO #mytmp FROM tdq.alpha_Cases;


SELECT DataTable.OrderLineID, Quantity, CAST(BadData AS int)
	FROM
		WorldWideImporters.Sales.OrderLines DataTable
		JOIN (
			SELECT
				OrderLineID
				,BadData	=Quantity + (Quantity*((CAST(Rnd%10 AS decimal)-5)/100))
				,Proportion	=CAST(ROW_NUMBER() OVER (ORDER BY NEWID()) AS decimal)/COUNT(*) OVER (PARTITION BY NULL)
			FROM WorldWideImporters.Sales.OrderLines,(SELECT Rnd=ABS(CHECKSUM(NEWID()))) Rnd
			
		) CreateFaults ON CreateFaults.OrderLineID = DataTable.OrderLineID
	WHERE Proportion < (0.100-0.000)*RAND()+0.000
	and Quantity <> CAST(BadData AS int);


DECLARE @x as nvarchar(2);
SET @x = N'𒉹';
PRINT @x
PRINT LEN(@x);
PRINT DATALENGTH(@x);


select REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE('This?is<a:test','<','_'),'>','_'),':','_'),'"','_'),'/','_'),'\','_'),'|','_'),'?','_'),'*','_');