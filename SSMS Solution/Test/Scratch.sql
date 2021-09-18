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

GO

WITH
	Definitions AS (
		SELECT
			definition
			,ObjectName	='['+SCHEMA_NAME(all_objects.schema_id)+']'
						+'.['+OBJECT_NAME(sql_modules.object_id)+']'	
			,MetaStart	=CHARINDEX('<Measure>',definition,1)					
			,MetaEnd	=CHARINDEX('</Measure>',definition,1) + 10
		FROM
			sys.sql_modules
			JOIN sys.all_objects ON all_objects.object_id = sql_modules.object_id
		WHERE
			OBJECT_NAME(sql_modules.object_id)		LIKE	[tdq].[alpha_BoxText]('HomePrefix') + [tdq].[alpha_BoxText]('MeasureViewPattern')
			AND SCHEMA_NAME(all_objects.schema_id)	=		[tdq].[alpha_BoxText]('HomeSchema')
	)
	,MetaData AS (
			SELECT
				ObjectName
				,XMLData =IIF(MetaEnd>MetaStart,TRY_CAST(SUBSTRING(definition,MetaStart,MetaEnd - MetaStart) AS xml),NULL)
			FROM Definitions
	)
	SELECT * FROM MetaData;