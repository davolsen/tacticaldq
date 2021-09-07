CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasurementsDailyXML] AS
/*<object><sequence>60</sequence></object>*/
SELECT (
	SELECT
		[@MeasureID]			=MeasureID
		,[@ReportDateClosing]	=ReportDateClosing
		,MeasureCode
		,ReportDateOpening
		,DaysPast
		,CasesOpening
		,CasesResolved
		,CasesIdentified
		,CasesCarried
		,CasesClosing
		,CasesChange
		,CasesNetChange
	FROM [tdq].[alpha_ReportMeasurementsDaily]
	FOR XML PATH('MeasurementDaily'), ROOT('MeasurementSummariesDaily'), TYPE
) AS ReportXML;
GO
SELECT * FROM [tdq].[alpha_ReportMeasurementsDailyXML];