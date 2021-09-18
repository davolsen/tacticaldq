CREATE OR ALTER VIEW [tdq].[alpha_MeasuresValidation] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>31</Sequence></Object>*/
WITH
	Definitions AS (
		SELECT
			definition
			,MetaStart	=CHARINDEX('<Measure>',definition,1)					
			,MetaEnd	=CHARINDEX('</Measure>',definition,1) + 10
		FROM
			sys.sql_modules
			JOIN sys.all_objects ON all_objects.object_id = sql_modules.object_id
		WHERE
			OBJECT_NAME(sql_modules.object_id)		LIKE	[tdq].[alpha_BoxText]('HomePrefix') + [tdq].[alpha_BoxText]('MeasureViewPattern')
			AND SCHEMA_NAME(all_objects.schema_id)	=		[tdq].[alpha_BoxText]('HomeSchema')
	)
	,MetaData AS (
		SELECT
			ObjectName
			,MeasureCode		=NULLIF(XMLData.value('(/measure/code/text())[1]','nvarchar(100)'),'')
			,MeasureID			=TRY_CAST(XMLData.value('(/measure/id/text())[1]','nchar(36)') AS uniqueidentifier)
			,MeasureDefinition	=NULLIF(XMLData.value('(/measure/definition/text())[1]','nvarchar(500)'),'')
			,RefreshPolicy		=ISNULL(NULLIF(XMLData.value('(/measure/refreshPolicy/text())[1]','nvarchar(20)'),''),[tdq].[alpha_BoxText]('RefreshPolicyDefault'))
			,RefreshTimeOffset	=ISNULL(TRY_CAST(XMLData.value('(/measure/refreshTimeOffset/text())[1]','nchar(5)') AS time(0)),[tdq].[alpha_BoxDate]('RefreshTimeOffsetDefault'))
			,MeasureOwner		=NULLIF(TRY_CAST(XMLData.query('/measure/owner/text()') AS nvarchar(254)),'')
			,MeasureCategory	=NULLIF(TRY_CAST(XMLData.query('/measure/category/text()') AS nvarchar(254)),'')
			,ReportFields		=XMLData.query('/measure/reportFields')
		FROM (
			SELECT
				ObjectName
				,XMLData		=TRY_CAST(SUBSTRING(definition,MetaStart,MetaEnd - MetaStart) AS xml)
			FROM Definitions
			WHERE
				MetaStart	>0
				AND MetaEnd	>0
		) MetaData
	)
	,Measures AS (
		SELECT
			*
			,MeasureIDCount		=COUNT(*) OVER (PARTITION BY MeasureID)
			,RefreshTimeMinutes	=DATEDIFF(MINUTE,'00:00',RefreshTimeOffset)
			,RefreshWeekDay		=(((CASE LEFT(RefreshPolicy,2) WHEN 'Mo' THEN 1 WHEN 'Tu' THEN 2 WHEN 'We' THEN 3 WHEN 'Th' THEN 4 WHEN 'Fr' THEN 5 WHEN 'Sa' THEN 6 WHEN 'Su' THEN 7 END-@@DATEFIRST)+7)%7)+1
			,Today				=DATEPART(WEEKDAY,SYSDATETIME())
		FROM MetaData
	)
	,Refresh AS (
		SELECT
			MeasureID
			,MaxTimestampStarted	=MAX(TimestampStarted)
			,LastStartedDay			=[tdq].[alpha_RoundDate](MAX(TimestampStarted),'DAY')		
			,LastStartedHour		=[tdq].[alpha_RoundDate](MAX(TimestampStarted),'HOUR')
		FROM [tdq].[alpha_Refreshes]
		GROUP BY MeasureID
	)
SELECT
	MeasureID						=IIF(MeasureIDCount = 1, Measures.MeasureID, NULL)
	,MeasureCode
	,ObjectName
	,MeasureDefinition
	,MeasureOwner
	,RefreshPolicy
	,RefreshTimeOffset
	,MeasureCategory
	,ReportFields					=IIF(DATALENGTH(ReportFields) > 5, ReportFields,NULL)
FROM
	Measures
GO
SELECT * FROM tdq.[alpha_MeasuresValidation]
 