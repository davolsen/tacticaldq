CREATE OR ALTER VIEW [tdq].[alpha_ReportLog] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>50</Sequence></Object>*/
SELECT TOP 1000
	LogEntryID
	,LogTimestamp
	,LogSource
	,LogTable.MeasureID
	,LogTable.RefreshID
	,Code
	,Error
	,LogMessage
	,Measures.MeasureCode
	,RefreshStarted			=TimestampStarted
	,RefreshCompleted		=TimestampCompleted
	,RefreshDurationSeconds	=DATEDIFF(SECOND,TimestampStarted,TimestampCompleted)
FROM
	[tdq].[alpha_Log]					LogTable
	LEFT JOIN [tdq].[alpha_Measures]	Measures	ON Measures.MeasureID	=LogTable.MeasureID
	LEFT JOIN [tdq].[alpha_Refreshes]	Refresh		ON Refresh.RefreshID	=LogTable.RefreshID
ORDER BY LogEntryID DESC;
GO

SELECT * FROM [tdq].[alpha_ReportLog]
