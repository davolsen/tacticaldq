CREATE OR ALTER VIEW [tdq].[alpha_MeasuresActivity] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>31</Sequence></Object>*/
WITH
	Refresh AS (
		SELECT
			MeasureID
			,MaxTimestampStarted	=MAX(TimestampStarted)
			,LastStartedDay			=[tdq].[alpha_RoundDate](MAX(TimestampStarted),'DAY')		
			,LastStartedHour		=[tdq].[alpha_RoundDate](MAX(TimestampStarted),'HOUR')
			,Today					=DATEPART(WEEKDAY,SYSDATETIME())
		FROM [tdq].[alpha_Refreshes]
		GROUP BY MeasureID
	)
SELECT
	MEasures.MeasureID
	,MeasureCode
	,ObjectName
	,MeasureDefinition
	,MeasureOwner
	,RefreshLastTimestampStarted	=MaxTimestampStarted AT TIME ZONE [tdq].[alpha_BoxText]('WorkingTimezoneName')
	,RefreshPolicy
	,RefreshTimeOffset
	,RefreshNext					=CASE
										WHEN MaxTimestampStarted IS NULL THEN DATEADD(SECOND,-1,SYSDATETIMEOFFSET())
										ELSE
											DATEADD(MINUTE,RefreshTimeMinutes,CASE LEFT(RefreshPolicy,1)
												WHEN 'C'	THEN MaxTimestampStarted
												WHEN 'H'	THEN DATEADD(HOUR,1,LastStartedHour)--TODO: NOPE
												WHEN 'D'	THEN DATEADD(DAY,1,LastStartedDay)
												ELSE DATEADD(DAY,IIF(DATEPART(WEEKDAY,MaxTimestampStarted) >= RefreshWeekDay,7,0) + (RefreshWeekDay - Today),LastStartedDay)
													END) END

	,MeasureCategory
	,ReportFields					=IIF(DATALENGTH(ReportFields) > 5, ReportFields,NULL)
FROM
	[tdq].[alpha_Measures] Measures
	LEFT JOIN Refresh ON Refresh.MeasureID = Measures.MeasureID
WHERE Valid = 1;
GO

SELECT * FROM [tdq].[alpha_MeasuresActivity];