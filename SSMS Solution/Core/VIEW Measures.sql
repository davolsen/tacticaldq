CREATE OR ALTER VIEW [tdq].[alpha_Measures] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>30</Sequence></Object>*/
WITH
	Definitions AS (
		SELECT
			definition
			,ObjectName	=CAST(N'['+OBJECT_SCHEMA_NAME(object_id)+N'].['+OBJECT_NAME(object_id)+N']'	AS nvarchar(522))
			,MetaStart	=CHARINDEX('<Measure>',definition,1)					
			,MetaEnd	=CHARINDEX('</Measure>',definition,1) + 10
		FROM sys.sql_modules
		WHERE
			OBJECT_NAME(object_id)				LIKE [tdq].[alpha_BoxText]('HomePrefix') + [tdq].[alpha_BoxText]('MeasureViewPattern')
			AND OBJECT_SCHEMA_NAME(object_id)	=[tdq].[alpha_BoxText]('HomeSchema')
	)
	,MetaData AS (
		SELECT *, RefreshTimeOffset=ISNULL(MetadataRefreshTimeOffset,[tdq].[alpha_BoxDate]('RefreshTimeOffsetDefault'))
		FROM (SELECT
				*
				,MetadataMeasureID			=TRY_CAST(RawMeasureID AS uniqueidentifier)
				,MetadataRefreshTimeOffset	=TRY_CAST(RawRefreshTimeOffset AS time(0))
			FROM (SELECT
					*
					,MeasureCode			=XMLData.value('(/Measure/Code/text())[1]','nvarchar(100)')
					,MeasureDefinition		=XMLData.value('(/Measure/Definition/text())[1]','nvarchar(500)')
					,RefreshPolicy			=ISNULL(XMLData.value('(/Measure/RefreshPolicy/text())[1]','nvarchar(20)'),[tdq].[alpha_BoxText]('RefreshPolicyDefault'))
					,RawRefreshTimeOffset	=XMLData.value('(/Measure/RefreshTimeOffset/text())[1]','nchar(5)') 
					,MeasureOwner			=XMLData.value('(/Measure/Owner/text())[1]','nvarchar(100)')
					,MeasureCategory		=XMLData.value('(/Measure/Category/text())[1]','nvarchar(100)')
					,ReportFields			=XMLData.query('/Measure/ReportFields')
					,RawMeasureID			=XMLData.value('(/Measure/ID/text())[1]','nchar(36)')
				FROM (SELECT
						ObjectName
						,XMLData =IIF(MetaEnd>MetaStart,TRY_CAST(SUBSTRING(definition,MetaStart,MetaEnd - MetaStart) AS xml),NULL)
					FROM Definitions
		)T)T)T
	)
	,Measures AS (
		SELECT
			MeasureID			=IIF(ROW_NUMBER() OVER (PARTITION BY MetadataMeasureID ORDER BY MeasureCode) = 1,MetadataMeasureID,NULL)
			,*
			,MeasureIDCount		=IIF(MetadataMeasureID IS NOT NULL,COUNT(*) OVER (PARTITION BY MetadataMeasureID),0)
			,MeasureCodeCount	=IIF(MeasureCode IS NOT NULL,COUNT(*) OVER (PARTITION BY MeasureCode),0)
			,RefreshTimeMinutes	=DATEDIFF(MINUTE,'00:00',RefreshTimeOffset)
			,RefreshWeekDay		=(((CASE LEFT(RefreshPolicy,2) WHEN 'Mo' THEN 1 WHEN 'Tu' THEN 2 WHEN 'We' THEN 3 WHEN 'Th' THEN 4 WHEN 'Fr' THEN 5 WHEN 'Sa' THEN 6 WHEN 'Su' THEN 7 END-@@DATEFIRST)+7)%7)+1
		FROM MetaData
	)
	,CleanMeasures AS (SELECT * FROM Measures WHERE  XMLData IS NOT NULL)
	,Errors AS (
		SELECT ObjectName, STRING_AGG(Error, ', ') AS Errors
		FROM (
			SELECT ObjectName, Error='Invalid or Missing Metadata' FROM Measures WHERE XMLData IS NULL
			UNION ALL SELECT ObjectName, Error='Duplicate ID' FROM CleanMeasures WHERE MeasureIDCount > 1
			UNION ALL SELECT ObjectName, Error='Duplicate Code' FROM CleanMeasures WHERE MeasureCodeCount > 1
			UNION ALL SELECT ObjectName, 'Missing ID' FROM CleanMeasures WHERE MetadataMeasureID IS NULL
			UNION ALL SELECT ObjectName, 'Missing Code' FROM CleanMeasures WHERE MeasureCode IS NULL
			UNION ALL SELECT ObjectName, 'Invalid RefreshTimeOffset' FROM CleanMeasures WHERE RawRefreshTimeOffset IS NOT NULL AND MetadataRefreshTimeOffset IS NULL
			UNION ALL SELECT ObjectName, 'Invalid RefreshPolicy' FROM Measures WHERE RefreshPolicy NOT IN ('Continuous','Hourly','Daily') AND RefreshWeekDay = 0
		)T
		GROUP BY ObjectName
	)
SELECT
	Measures.ObjectName
	,MeasureID
	,Valid	=IIF(Errors IS NULL,1,0)
	,MeasureCode
	,MeasureDefinition
	,MeasureOwner
	,MeasureCategory
	,RefreshPolicy
	,RefreshTimeOffset
	,RefreshTimeMinutes
	,RefreshWeekDay
	,ReportFields
	--,XMLData
	,Errors.Errors
	FROM
		Measures
		LEFT JOIN Errors ON Errors.ObjectName = Measures.ObjectName;
GO

SELECT * FROM [tdq].[alpha_Measures];