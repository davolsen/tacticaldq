CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasurePropertiesXML] AS
/*<object><sequence>60</sequence></object>*/
WITH
	MeasureProperties AS (
		SELECT
			MeasureTag			=1
			,[Measure!1!id]		=MeasureID
			,PropertyTag		=2
			,[Property!2!name]	=PropertyName
			,[Property!2!value]	=PropertyValue
		FROM [tdq].[alpha_ReportMeasureProperties]
	)
	,ExplicitLayout AS (
		SELECT DISTINCT
			Tag					=MeasureTag
			,Parent				=NULL
			,[Measure!1!id]
			,[Property!2!name]	=NULL
			,[Property!2!value]	=NULL
		FROM MeasureProperties
		UNION ALL SELECT
			Tag					=PropertyTag
			,Parent				=MeasureTag
			,[Measure!1!id]
			,[Property!2!name]
			,[Property!2!value]
		FROM MeasureProperties
)
SELECT ReportXML = (
	SELECT * FROM ExplicitLayout
	ORDER BY [Measure!1!id],[Property!2!name]
	FOR XML EXPLICIT, ROOT('ReportMeasures'), Type
);
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasurePropertiesXML];
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
