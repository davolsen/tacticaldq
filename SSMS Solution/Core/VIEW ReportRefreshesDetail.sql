CREATE OR ALTER VIEW [tdq].[alpha_ReportRefreshesDetail] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>50</Sequence></Object>*/

WITH
	CasesIdentifiedCurrent AS (
		SELECT Refreshes.RefreshID, CaseCount=COUNT(CaseID)
		FROM
			[tdq].[alpha_Cases]				Cases
			JOIN [tdq].[alpha_Refreshes]	Refreshes ON
				Refreshes.MeasureID		=Cases.MeasureID
				AND Cases.Identified	BETWEEN Refreshes.TimestampStarted AND Refreshes.TimestampCompleted
		GROUP BY Refreshes.RefreshID
	)
	,CasesIdentifiedHistorical AS (
		SELECT Refreshes.RefreshID, CaseCount=COUNT(CaseID)
		FROM
			[tdq].[alpha_CasesResolved]		Cases
			JOIN [tdq].[alpha_Refreshes]	Refreshes ON
				Refreshes.MeasureID		=Cases.MeasureID
				AND Cases.Identified	BETWEEN Refreshes.TimestampStarted AND Refreshes.TimestampCompleted
		GROUP BY Refreshes.RefreshID
	)
	,CasesCarriedCurrent AS (
		SELECT Refreshes.RefreshID, CaseCount=COUNT(CaseID)
		FROM
			[tdq].[alpha_Cases]				Cases
			JOIN [tdq].[alpha_Refreshes]	Refreshes ON
				Refreshes.MeasureID		=Cases.MeasureID
				AND Cases.Identified	<Refreshes.TimestampStarted
		GROUP BY Refreshes.RefreshID
	)
	,CasesCarriedHistorical AS (
		SELECT Refreshes.RefreshID, CaseCount=COUNT(CaseID)
		FROM
			[tdq].[alpha_CasesResolved]		Cases
			JOIN [tdq].[alpha_Refreshes]	Refreshes ON
				Refreshes.MeasureID		=Cases.MeasureID
				AND Cases.Identified	<Refreshes.TimestampStarted
				AND Cases.Resolved		>Refreshes.TimestampCompleted
		GROUP BY Refreshes.RefreshID
	)
	,CasesResolved AS (
		SELECT Refreshes.RefreshID, CaseCount=COUNT(CaseID)
		FROM
			[tdq].[alpha_CasesResolved]		Cases
			JOIN [tdq].[alpha_Refreshes]	Refreshes ON
				Refreshes.MeasureID		=Cases.MeasureID
				AND Cases.Resolved		BETWEEN Refreshes.TimestampStarted AND Refreshes.TimestampCompleted
		GROUP BY Refreshes.RefreshID
	)
	,Summary AS (
		SELECT
			Refresh.RefreshID
			,CasesIdentified	=ISNULL(CasesIdentifiedCurrent.CaseCount,0) + ISNULL(CasesIdentifiedHistorical.CaseCount,0)
			,CasesCarried		=ISNULL(CasesCarriedCurrent.CaseCount,0) + ISNULL(CasesCarriedHistorical.CaseCount,0)
			,CasesResolved		=ISNULL(CasesResolved.CaseCount,0)
			
		FROM
			[tdq].[alpha_Refreshes]	Refresh 
			LEFT JOIN	[tdq].[alpha_Measures] Measures	ON Measures.MeasureID					=Refresh.MeasureID
			LEFT JOIN	CasesIdentifiedCurrent			ON CasesIdentifiedCurrent.RefreshID		=Refresh.RefreshID
			LEFT JOIN	CasesIdentifiedHistorical		ON CasesIdentifiedHistorical.RefreshID	=Refresh.RefreshID
			LEFT JOIN	CasesCarriedCurrent				ON CasesCarriedCurrent.RefreshID		=Refresh.RefreshID
			LEFT JOIN	CasesCarriedHistorical			ON CasesCarriedHistorical.RefreshID		=Refresh.RefreshID
			LEFT JOIN	CasesResolved					ON CasesResolved.RefreshID				=Refresh.RefreshID
	)

SELECT
	Refresh.RefreshID
	,Refresh.MeasureID
	,MeasureCode
	,Refresh.TimestampStarted
	,Refresh.TimestampCompleted
	,Refresh.Published
	,Refresh.Unpublished
	,Recency			=ROW_NUMBER() OVER (PARTITION BY Measures.MeasureID ORDER BY TimestampStarted DESC)
	,CasesOpening		=CasesCarried + CasesResolved
	,CasesResolved		=CasesResolved
	,CasesIdentified	=CasesIdentified
	,CasesCarried		=CasesCarried
	,CasesClosing		=CasesCarried + CasesIdentified
	,CasesChange		=CasesIdentified + CasesResolved
	,CasesNetChange		=CasesIdentified - CasesResolved
FROM
	[tdq].[alpha_Refreshes]				Refresh 
	JOIN								Summary		ON Summary.RefreshID	=Refresh.RefreshID
	LEFT JOIN	[tdq].[alpha_Measures]	Measures	ON Measures.MeasureID	=Refresh.MeasureID
WHERE DATEDIFF(DAY,TimestampStarted,SYSDATETIMEOFFSET()) <= [tdq].[alpha_BoxDec]('ReportHistoryDays');
GO

DECLARE @Start AS datetime2(7) = SYSDATETIME();
SELECT * FROM [tdq].[alpha_ReportRefreshesDetail] order by TimestampStarted desc;
PRINT DATEDIFF(MILLISECOND,@Start,SYSDATETIME());
