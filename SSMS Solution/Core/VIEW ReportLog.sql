CREATE OR ALTER VIEW [tdq].[alpha_ReportLog] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>50</sequence></object>*/
SELECT TOP 1000
	LogEntryID
	,LogTimestamp
	,LogSource
	,LogTable.MeasureID
	,LogTable.MeasurementID
	,Code
	,Error
	,LogMessage
	,Measures.MeasureCode
	,MeasurementStarted			=TimestampStarted
	,MeasurementCompleted		=TimestampCompleted
	,MeasurementDurationSeconds	=DATEDIFF(SECOND,TimestampStarted,TimestampCompleted)
FROM
	[tdq].[alpha_Log]						LogTable
	LEFT JOIN [tdq].[alpha_Measures]		Measures		ON Measures.MeasureID			=LogTable.MeasureID
	LEFT JOIN [tdq].[alpha_Measurements]	Measurements	ON Measurements.MeasurementID	=LogTable.MeasurementID
ORDER BY LogEntryID DESC;
GO

SELECT * FROM [tdq].[alpha_ReportLog]
