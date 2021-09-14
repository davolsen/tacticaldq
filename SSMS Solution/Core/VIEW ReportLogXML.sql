CREATE OR ALTER VIEW [tdq].[alpha_ReportLogXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>60</sequence></object>*/
SELECT (
	SELECT
		[@ID]					=LogEntryID
		,Timestamp				=LogTimestamp
		,[Source]				=LogSource
		,MeasureID
		,MeasurementID
		,Code
		,Error
		,[Message]				=LogMessage
		,MeasureCode
		,MeasurementStarted
		,MeasurementCompleted
		,MeasurementDurationSeconds
	FROM [tdq].[alpha_ReportLog]
	FOR XML PATH('Entry'), ROOT('Log'), TYPE
) AS ReportXML;
GO
SELECT * FROM [tdq].[alpha_ReportLogXML];