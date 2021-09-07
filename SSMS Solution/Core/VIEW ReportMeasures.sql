CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasures] AS
/*<object><sequence>50</sequence></object>*/
WITH
	Errors AS (
		SELECT
			MeasureID
			,Error
			,LogTimestamp
		FROM [tdq].[alpha_Log]
	)
SELECT
	MeasureID
	,MeasureCode
	,MeasureDescription
	,RefreshLastTimestampStarted
	,CasesToday				=CasesClosing
	,CasesTodayResolved		=CasesOpening-CasesCarried
	,CasesTodayIdentified	=CasesClosing-CasesCarried
	,CasesTodayNetChange	=CasesClosing-CasesOpening
	,MeasureOwner
	,MeasureCategory
	,ReportFields
	,RefreshPolicy
	,RefreshTimeOffset
	,RefreshNext
	,Error					=IIF(EXISTS(
								SELECT 1
								FROM [tdq].[alpha_Log]
								WHERE
									MeasureID			=Measures.MeasureID
									AND Error			=1
									AND LogTimestamp	>RefreshLastTimestampStarted
										),1,0)
FROM
	[tdq].[alpha_Measures] Measures
	CROSS APPLY [tdq].[alpha_CasesSummary](MeasureID, DATEADD(SECOND,-1,[tdq].[alpha_RoundDate](SYSDATETIMEOFFSET(),'DAY')) AT TIME ZONE 'UTC', DATEADD(SECOND,1,SYSDATETIMEOFFSET()) AT TIME ZONE 'UTC') CaseSummary

WHERE Valid = 1
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasures]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
