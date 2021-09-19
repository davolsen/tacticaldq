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
			,RefreshHasCases	=IIF(EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE RefreshID = Refreshes.RefreshID),1,0)
			--,MeasureHasCases	=IIF(EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE MeasureID = Refreshes.MeasureID),1,0)
		FROM [tdq].[alpha_Refreshes] Refreshes
	)
	,CaseLists AS (
		SELECT 
			*
			,Age		=ROW_NUMBER() OVER (PARTITION BY MeasureID, RefreshHasCases ORDER BY TimestampStarted DESC)
			,AgeList	=ROW_NUMBER() OVER (PARTITION BY MeasureID, RefreshHasCases, Published, Unpublished ORDER BY TimestampStarted DESC)
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
							CaseLists.RefreshID			=LatestCaseList.RefreshID
							AND CaseLists.Published		=1
							AND CaseLists.Unpublished	=0
								THEN 'CUR'
						WHEN
							CaseLists.RefreshID			=LatestCaseList.RefreshID
							AND (
								CaseLists.Published			=0
								OR CaseLists.Unpublished	=1
							)
								THEN 'NEW'
						ELSE 'OLD' END
	,CaseListName	=Measures.MeasureCode
					+' '+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Measures.MeasureDefinition,'<','_'),'>','_'),':','_'),'"','_'),'/','_'),'\','_'),'|','_'),'?','_'),'*','_'),'.',''),1,260-2-19-LEN(Measures.MeasureCode))
					+' '+CAST(CaseLists.TimestampStarted AS nvarchar(16))
FROM
	CaseLists
	JOIN CaseLists LatestCaseList ON
		LatestCaseList.MeasureID			=CaseLists.MeasureID
		AND LatestCaseList.RefreshHasCases	=1
		AND LatestCaseList.Age				=1
	LEFT JOIN [tdq].[alpha_Measures] Measures ON Measures.MeasureID = CaseLists.MeasureID
WHERE
	CaseLists.RefreshHasCases = 1
	AND (
		CaseLists.RefreshID = LatestCaseList.RefreshID
		OR (CaseLists.Published = 1 AND CaseLists.Unpublished = 0)
	);
--WHERE
--	Unpublished = 0
--	AND NOT (CurrentCases = 0 AND Published = 0);
GO
SELECT * FROM [tdq].[alpha_OutputCaseLists];

--update tdq.alpha_refreshes set Published = 0, Unpublished = 0