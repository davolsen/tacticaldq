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
select * from tdq.alpha_Measurements ORDER BY MeasurementID DESC, MeasureID;
select * from tdq.alpha_Cases ORDER BY MeasurementID DESC;
select * from tdq.alpha_CaseHistory ORDER BY MeasurementID DESC;
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


ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);


ALTER TABLE [tdq].[alpha_Cases] ADD PERIOD FOR SYSTEM_TIME (Identified, Resolved)
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CaseHistory));

exec tdq.alpha_Refresh '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E';

GO

DECLARE @Measurement TABLE(MeasurementID int, MeasureID char(1));
INSERT @Measurement VALUES (1,'Y'),(2,'Y'),(3,'N'),(4,'Y');
DECLARE @Cases TABLE(MeasurementID int, DataValue char(1));
INSERT @Cases VALUES (1,'c'),(1,'o'),(2,'r'),(2,'q'),(3,'r'),(3,'c'),(1,'z');

DECLARE @MeasureID char(1) = 'Y'
DECLARE @MeasurementID char(1) = 4

SELECT * FROM @Cases;

WITH NewCases AS (SELECT * FROM (VALUES ('c'),('o'),('r'),('e'),('c'),('t'))T(DataValue))
MERGE @Cases CurrentCases
USING NewCases ON NewCases.DataValue = CurrentCases.DataValue AND EXISTS(SELECT 1 FROM @Measurement WHERE MeasurementID = CurrentCases.MeasurementID AND MeasureID = @MeasureID)
WHEN NOT MATCHED THEN INSERT (MeasurementID,DataValue) VALUES (@MeasurementID,DataValue)
WHEN NOT MATCHED BY SOURCE AND EXISTS(SELECT 1 FROM @Measurement WHERE MeasurementID = CurrentCases.MeasurementID AND MeasureID = @MeasureID) THEN DELETE;

;
SELECT * FROM @Cases;




update tdq.alpha_CaseHistory set measureid = mes.measureid
from tdq.alpha_cases cases join tdq.alpha_measurements mes on mes.MeasurementID = cases.MeasurementID