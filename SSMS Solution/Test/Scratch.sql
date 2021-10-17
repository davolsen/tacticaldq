/*
truncate table tdq.alpha_Log;
GO
ALTER TABLE tdq.alpha_cases SET (SYSTEM_VERSIONING=OFF);
GO
DROP TABLE tdq.alpha_CasesResolved;
truncate table tdq.alpha_cases;
--ALTER TABLE tdq.alpha_cases ADD PERIOD FOR SYSTEM_TIME([Identified],[Resolved]);;
ALTER TABLE tdq.alpha_cases SET (SYSTEM_VERSIONING=ON(HISTORY_TABLE=[tdq].[alpha_CasesResolved]))
truncate table tdq.alpha_Refreshes;

/*
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE [tdq].[alpha_Cases] ADD PERIOD FOR SYSTEM_TIME (Identified, Resolved)
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CasesResolved));
*/
*/


EXEC [tdq].[alpha_Schedule]

Select TOP 100 * from tdq.alpha_Log ORDER BY LogEntryID desc
select * from tdq.alpha_Refreshes ORDER BY RefreshID DESC, MeasureID;
select * from tdq.alpha_Cases ORDER BY RefreshID DESC;
select * from tdq.alpha_CasesResolved ORDER BY RefreshID DESC;
--SELECT TOP 1 * INTO #mytmp FROM tdq.alpha_Cases;

SELECT * FROM sys.sql_modules where definition like '%@SQL %'

select * from sys.sql_modules where definition like '%casesmergestatement%'