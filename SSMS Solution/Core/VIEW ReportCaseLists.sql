CREATE OR ALTER VIEW [tdq].[alpha_ReportCaseLists] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>50</Sequence></Object>*/
WITH
	Refreshes AS (
		SELECT
			*
			,Superceded = MAX(Refreshes.TimestampStarted) OVER (PARTITION BY Refreshes.MeasureID) 
		FROM (
			SELECT *
				,Age = ROW_NUMBER() OVER (PARTITION BY MeasureID, CurrentCases, Published, Unpublished ORDER BY TimestampStarted DESC)
			FROM (
				SELECT
					MeasureID
					,CurrentCases	=CASE
										WHEN EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE RefreshID = Refreshes.RefreshID) THEN 1
										ELSE 0 END
					,Published
					,Unpublished
					,TimestampStarted
					,RefreshID
				FROM [tdq].[alpha_Refreshes] Refreshes
			)T
		) Refreshes
		WHERE Age = 1
	)
SELECT
	Refreshes.MeasureID
	,Measures.MeasureCode
	,LastRefreshID	=RefreshID
	,Refreshes.TimestampStarted
	,Refreshes.CurrentCases
	,Refreshes.Published
	,Refreshes.Superceded
	,Refreshes.Unpublished
	,CaseListStatus	=CASE
						/*WHEN CurrentCases = 1
							AND Published = 1
							AND Unpublished = 0
													THEN 'CUR'*/
						WHEN CurrentCases = 0
							AND Published = 0
							AND Unpublished = 0
													THEN 'OLD'
						WHEN Published = 1
							AND Unpublished = 0
							AND MAX(Refreshes.TimestampStarted) OVER (PARTITION BY Refreshes.MeasureID) > Refreshes.TimestampStarted
													THEN 'OLD'
						WHEN CurrentCases = 1
							AND Published = 0		THEN 'NEW'
													ELSE 'CUR' END
	,CaseListName	=Measures.MeasureCode
					+' '+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Measures.MeasureDefinition,'<','_'),'>','_'),':','_'),'"','_'),'/','_'),'\','_'),'|','_'),'?','_'),'*','_'),'.',''),1,260-2-19-LEN(Measures.MeasureCode))
					+' '+CAST(TimestampStarted AS nvarchar(16))
FROM
	Refreshes
	LEFT JOIN [tdq].[alpha_Measures] Measures ON Measures.MeasureID = Refreshes.MeasureID
WHERE
	Unpublished = 0
	AND NOT (CurrentCases = 0 AND Published = 0);
GO
SELECT * FROM [tdq].[alpha_ReportCaseLists];