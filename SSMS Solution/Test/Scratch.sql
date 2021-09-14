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


/*
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE [tdq].[alpha_Cases] ADD PERIOD FOR SYSTEM_TIME (Identified, Resolved)
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CaseHistory));
*/


exec tdq.alpha_Refresh '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E';

GO

with x as (
select casechecksum from tdq.alpha_cases a join tdq.alpha_measurements b on b.measurementid = a.measurementid  where b.MeasureID = '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E')
,y as (select binary_checksum(*) casechecksum from [tdq].[alpha_measure_CUST-MAST-BGRP])
,z as (select XCase = x.CaseChecksum, YCase = y.casechecksum from
x full outer join y on y.casechecksum = x.casechecksum)
select *
FROM z




SELECT * FROM [tdq].[alpha_CasesSummary]('3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E',CAST('2021-09-14 09:11 +12:00' as datetimeoffset) AT TIME ZONE 'UTC',CAST('2021-09-14 09:12 +12:00' as datetimeoffset) AT TIME ZONE 'UTC')

select * from [tdq].[alpha_ReportMeasurementsDetail]

select checksum(*) casechecksum from [tdq].[alpha_measure_CUST-MAST-BGRP]
select * into #x from [tdq].[alpha_measure_CUST-MAST-BGRP]
select checksum(*) from #x