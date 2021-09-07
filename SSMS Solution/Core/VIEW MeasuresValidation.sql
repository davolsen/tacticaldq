CREATE OR ALTER VIEW [tdq].[alpha_MeasuresValidation] AS
/*<object><sequence>31</sequence></object>*/
WITH
	Definitions AS (
		SELECT
			definition
			,'['
				+ SCHEMA_NAME(all_objects.schema_id)
				+ '].['
				+ OBJECT_NAME(sql_modules.object_id)
				+ ']'	ObjectName
			,CHARINDEX('<measure>',definition,1)					MetaStart
			,CHARINDEX('</measure>',definition,1) + 10				MetaEnd
		FROM
			sys.sql_modules
			JOIN sys.all_objects ON all_objects.object_id = sql_modules.object_id
		WHERE
			OBJECT_NAME(sql_modules.object_id) LIKE [tdq].[alpha_BoxText]('HomePrefix') + [tdq].[alpha_BoxText]('MeasureViewPattern')
			AND SCHEMA_NAME(all_objects.schema_id) = [tdq].[alpha_BoxText]('HomeSchema')
	)
	,MetaData AS (
		SELECT
			ObjectName
			--,XMLData
			,NULLIF(TRY_CAST(XMLData.query('/measure/code/text()') AS nvarchar(100)),'')									MeasureCode
			,TRY_CAST(NULLIF(TRY_CAST(XMLData.query('/measure/id/text()') AS varchar(36)),'') AS uniqueidentifier)			MeasureID
			,NULLIF(TRY_CAST(XMLData.query('/measure/description/text()') AS nvarchar(500)),'')								MeasureDescription
			,NULLIF(TRY_CAST(XMLData.query('/measure/refreshPolicy/text()') AS nvarchar(500)),'')							RefreshPolicy
			,NULLIF(TRY_CAST(XMLData.query('/measure/refreshTimeOffset/text()') AS nvarchar(500)),'')						RefreshTimeOffset
		FROM (
			SELECT
				ObjectName
				,TRY_CAST(SUBSTRING(definition,MetaStart,MetaEnd - MetaStart) AS xml) XMLData
			FROM Definitions
			WHERE
				MetaStart > 0
				AND MetaEnd > 0
		) MetaData
	)
	,MetaDataValidation AS (
		SELECT
			ObjectName
			,MeasureCode
			,COUNT(*) OVER (PARTITION BY MeasureCode)															MeasureCodeCount
			,MeasureID
			,COUNT(*) OVER (PARTITION BY MeasureID)																MeasureIDCount
			,MeasureDescription
			,RefreshPolicy
			,IIF(RefreshPolicy IS NULL OR RefreshPolicy IN
				('Continuous','Hourly','Daily','Mon','Tue','Wed','Thu','Fri','Sat','Sun'), 1, 0)				RefreshPolicyValid
			,TRY_CAST(RefreshTimeOffset AS time(0))																RefreshTimeOffset
			,IIF(RefreshTimeOffset IS NULL OR TRY_CAST(RefreshTimeOffset AS time(0)) IS NOT NULL, 1, 0)			RefreshTimeOffsetValid
		FROM MetaData
	)
SELECT
	ObjectName
	,MeasureCode
	,IIF(MeasureIDCount = 1, MeasureID, NULL)										MeasureID
	,MeasureDescription
	,IIF(RefreshPolicy IS NULL, 1, 0)												RefreshPolicyDefaulted
	,ISNULL(RefreshPolicy,[tdq].[alpha_BoxText]('RefreshPolicyDefault'))			RefreshPolicy
	,IIF(RefreshTimeOffsetValid = 1 AND RefreshTimeOffset IS NULL, 1, 0)			RefreshTimeOffsetDefaulted
	,CASE
		WHEN
			RefreshTimeOffset			IS NULL
			AND RefreshTimeOffsetValid	=1
				THEN CAST([tdq].[alpha_BoxDate]('RefreshTimeOffsetDefault') AS time(0))
		ELSE RefreshTimeOffset
			END RefreshTimeOffset
	,CASE
		WHEN MeasureIDCount			>1		THEN 0
		WHEN MeasureID				IS NULL	THEN 0
		WHEN MeasureCode			IS NULL	THEN 0
		WHEN RefreshPolicyValid		=0		THEN 0
		WHEN RefreshTimeOffsetValid	=0		THEN 0
		ELSE 1
			END AS Valid
	,SUBSTRING(
		IIF(MeasureIDCount		> 1		,', Duplicate Measure ID'			,'')
		+IIF(MeasureCodeCount	> 1		,', Duplicate Measure Codes'		,'')
		+IIF(MeasureID			IS NULL	,', Measure ID missing'				,'')
		+IIF(MeasureCode		IS NULL	,', Measure Code missing'			,'')
		+IIF(RefreshPolicyValid	=0		,', Invalid Refresh Policy'			,'')
		+IIF(RefreshTimeOffsetValid	=0	,', Invalid Refresh Time Offset'	,'')
			, 3, 4000) AS Warnings
FROM MetaDataValidation
GO
SELECT * FROM tdq.[alpha_MeasuresValidation]
 