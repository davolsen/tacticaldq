CREATE OR ALTER VIEW [tdq].[alpha_LogReportXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>60</sequence></object>*/
SELECT (
	SELECT
		[@ID]					=LogEntryID
		,LogTimestamp
		,LogSource
		,MeasureID
		,MeasurementID
		,Code
		,Error
		,LogMessage
		,MeasureCode
		,MeasurementStarted
		,MeasurementCompleted
	FROM [tdq].[alpha_ReportLog]
	FOR XML PATH('Entry'), ROOT('Log'), TYPE
) AS ReportXML;
GO
SELECT * FROM [tdq].[alpha_LogReportXML];