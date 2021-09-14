CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasurementsDetail] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>50</sequence></object>*/
SELECT
	Measurements.MeasurementID
	,Measurements.MeasureID
	,MeasureCode
	,Measurements.TimestampStarted
	,Measurements.TimestampCompleted
	,Recency			=ROW_NUMBER() OVER (PARTITION BY Measures.MeasureID ORDER BY TimestampStarted DESC)
	,CasesOpening
	,CasesResolved		=CasesOpening-CasesCarried
	,CasesIdentified	=CasesClosing-CasesCarried
	,CasesCarried
	,CasesClosing
	,CasesChange		=(CasesOpening-CasesCarried)+(CasesClosing-CasesCarried)
	,CasesNetChange		=CasesClosing-CasesOpening
FROM
	[tdq].[alpha_Measurements]	Measurements 
	JOIN		[tdq].[alpha_Measures]	Measures ON Measures.MeasureID = Measurements.MeasureID
	CROSS APPLY [tdq].[alpha_CasesSummary](Measures.MeasureID, DATEADD(SECOND,-1,TimestampStarted) AT TIME ZONE 'UTC', DATEADD(SECOND,1,TimestampCompleted) AT TIME ZONE 'UTC') CaseSummary

WHERE DATEDIFF(DAY,TimestampStarted,SYSDATETIMEOFFSET()) <= [tdq].[alpha_BoxDec]('ReportHistoryDays')
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasurementsDetail]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
ORDER BY MeasurementID DESC;
