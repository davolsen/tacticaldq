CREATE OR ALTER VIEW [tdq].[alpha_ReportCaseLists] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>50</sequence></object>*/
WITH
	Refreshes AS (
		SELECT
			MeasureID
			,CurrentCases
			,Published
			,Unpublished
			,TimestampStarted	=MAX(TimestampStarted)
		FROM (
			SELECT
				MeasureID
				,CurrentCases	=CASE
									WHEN EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE RefreshID = Refreshes.RefreshID) THEN 1
									ELSE 0 END
				,Published
				,Unpublished
				,TimestampStarted
			FROM [tdq].[alpha_Refreshes] Refreshes
		) Refreshes

		GROUP BY MeasureID, CurrentCases, Published, Unpublished
	)
SELECT
	Measures.MeasureID
	,Measures.MeasureCode
	,Refreshes.TimestampStarted
	,Refreshes.CurrentCases
	,Refreshes.Published
	,Refreshes.Unpublished
	,FileState	=CASE
					WHEN CurrentCases = 0
						AND Published = 0
						AND Unpublished = 0
												THEN 'OLD'
					WHEN Published = 1
						AND Unpublished = 0
						AND MAX(Refreshes.TimestampStarted) OVER (PARTITION BY Measures.MeasureID) > Refreshes.TimestampStarted
												THEN 'OLD'
					WHEN CurrentCases = 1
						AND Published = 0		THEN 'NEW'
												ELSE 'CUR' END
	,CaseFile	=Measures.MeasureCode
				+' '+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Measures.MeasureDescription,'<','_'),'>','_'),':','_'),'"','_'),'/','_'),'\','_'),'|','_'),'?','_'),'*','_'),'.',''),1,260-2-19-LEN(Measures.MeasureCode))
				+' '+CAST(TimestampStarted AS nvarchar(16))
FROM
	[tdq].[alpha_Measures] Measures
	JOIN Refreshes ON Refreshes.MeasureID = Measures.MeasureID
WHERE
	Unpublished = 0
	AND NOT (CurrentCases = 0 AND Published = 0);
GO
SELECT * FROM [tdq].[alpha_ReportCaseLists]
--select distinct RefreshID from [tdq].[alpha_Cases]
--where measureid = '2AA29809-1C51-4398-9362-DF157DF5D629'

--update [tdq].[alpha_Refreshes] set published = 1 where RefreshID = 1409;