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
*/

select * from sys.sql_modules where definition like '%UpdateLastTimestampStarted%'

EXEC [tdq].[alpha_Schedule]
--select * from tdq.alpha_Measures
--select * from [tdq].[alpha_RefreshesPending]

Select TOP 100 * from tdq.alpha_Log
order by LogEntryID desc
select * from tdq.alpha_Refreshes ORDER BY RefreshID DESC, MeasureID;
select * from tdq.alpha_Cases ORDER BY RefreshID DESC;
select * from tdq.alpha_CasesResolved ORDER BY RefreshID DESC;
--SELECT TOP 1 * INTO #mytmp FROM tdq.alpha_Cases;

[tdq].[alpha_measures]

/*
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE [tdq].[alpha_Cases] ADD PERIOD FOR SYSTEM_TIME (Identified, Resolved)
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CasesResolved));
*/






exec tdq.alpha_Refresh '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E';

select top 10 * from tdq.alpha_ReportRefreshesDetail where measureID = '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E' order by TimestampCompleted desc


select * from WorldWideImporters.Sales.Customers

begin tran;
update WorldWideImporters.Sales.Customers
set BuyingGroupID = Y.BuyingGroupID
FROM WorldWideImporters.Sales.Customers X JOIN WorldWideImportersClean.Sales.Customers Y ON Y.CustomerID = X.CustomerID;
SELECT * FROM [tdq].[alpha_measure_CUST-MAST-BGRP] ;
commit;

--select * from sys.sql_modules where definition like '%alpha_CasesSummary%'

EXEC [tdq].[alpha_OutputCaseListUnpublish] @RefreshID = 2626;

EXEC [tdq].[alpha_OutputCaseListPublish] @MeasureID = '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E'


SELECT RefreshID
								FROM (
									SELECT
										RefreshID
										,Age		=ROW_NUMBER() OVER (ORDER BY TimestampStarted DESC)
									FROM [tdq].[alpha_Refreshes] Refreshes
									WHERE
										MeasureID = '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E'
										AND EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE RefreshID = Refreshes.RefreshID)
								)T
								WHERE Age = 1
