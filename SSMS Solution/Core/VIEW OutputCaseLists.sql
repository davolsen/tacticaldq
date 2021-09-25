CREATE OR ALTER VIEW [tdq].[alpha_OutputCaseLists] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>70</Sequence></Object>*/
WITH
	Refreshes AS (
		SELECT
			RefreshID
			,MeasureID
			,Published
			,Unpublished
			,TimestampStarted
			,HasChanges			=IIF(CasesChange > 0,1,0)
			,MeasureHasCases	=IIF(EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE MeasureID = Refreshes.MeasureID),1,0)
		FROM
			[tdq].[alpha_ReportRefreshesDetail] Refreshes
			CROSS APPLY [tdq].[alpha_CasesSummary](MeasureID,DATEADD(SECOND,-1,TimestampStarted) AT TIME ZONE 'UTC',DATEADD(SECOND,1,TimestampCompleted) AT TIME ZONE 'UTC') CasesSummary
	)
	,CaseLists AS (
		SELECT 
			*
			,Age		=ROW_NUMBER() OVER (PARTITION BY MeasureID, HasChanges ORDER BY TimestampStarted DESC)
			,AgeList	=ROW_NUMBER() OVER (PARTITION BY MeasureID, HasChanges, Published, Unpublished ORDER BY TimestampStarted DESC)
		FROM Refreshes
	)
SELECT
	CaseLists.MeasureID
	,Measures.MeasureCode
	,CaseLists.RefreshID
	,CaseLists.TimestampStarted
	,CaseLists.Published
	,CaseLists.Unpublished
	,CaseListStatus	=CASE
						WHEN
							CaseLists.RefreshID				=LatestCaseList.RefreshID
							AND CaseLists.Published			=1
							AND CaseLists.Unpublished		=0
								THEN 'CUR'
						WHEN
							CaseLists.RefreshID				=LatestCaseList.RefreshID
							AND (
								CaseLists.Published			=0
								OR CaseLists.Unpublished	=1
							)
								THEN 'NEW'
						ELSE 'OLD' END
	,CaseListName	=CAST(Measures.MeasureCode
					+' '+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Measures.MeasureDefinition,'<','_'),'>','_'),':','_'),'"','_'),'/','_'),'\','_'),'|','_'),'?','_'),'*','_'),'.',''),1,260-LEN(Measures.MeasureCode)-15-2)
					+' '+REPLACE(CONVERT(nvarchar(16),CaseLists.TimestampStarted,120),':','') AS nvarchar(260))
FROM
	CaseLists
	JOIN CaseLists LatestCaseList ON
		LatestCaseList.MeasureID		=CaseLists.MeasureID
		AND LatestCaseList.HasChanges	=1
		AND LatestCaseList.Age			=1
	LEFT JOIN [tdq].[alpha_Measures] Measures ON Measures.MeasureID = CaseLists.MeasureID
WHERE
	CaseLists.HasChanges = 1
	AND (
		(--published
			CaseLists.Published			=1
			AND CaseLists.Unpublished	=0
		)
		OR (--OR is current/new and should be published or unpublished
			CaseLists.RefreshID				=LatestCaseList.RefreshID
			AND CaseLists.MeasureHasCases	=1
		)
	);
GO
SELECT * FROM [tdq].[alpha_OutputCaseLists];

--update tdq.alpha_refreshes set Published = 0, Unpublished = 0