CREATE OR ALTER VIEW [tdq].[alpha_ReportCasesXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>60</sequence></object>*/
--WITH
--	MeasureProperties AS (
--		SELECT
--			MeasureTag			=1
--			,[Measure!1!id]		=MeasureID
--			,PropertyTag		=2
--			,[Property!2!name]	=PropertyName
--			,[Property!2!value]	=PropertyName
--		FROM [tdq].[alpha_ReportMeasureProperties]
--	)
--	,ExplicitLayout AS (
--		SELECT DISTINCT
--			Tag					=MeasureTag
--			,Parent				=NULL
--			,[Measure!1!id]
--			,[Property!2!name]	=NULL
--			,[Property!2!value]	=NULL
--		FROM MeasureProperties
--		UNION ALL SELECT
--			Tag					=PropertyTag
--			,Parent				=MeasureTag
--			,[Measure!1!id]
--			,[Property!2!name]
--			,[Property!2!value]
--		FROM MeasureProperties
--)
--SELECT ReportXML = (
--	SELECT * FROM ExplicitLayout
--	ORDER BY [Measure!1!id],[Property!2!name]
--	FOR XML EXPLICIT, ROOT('ReportMeasures'), Type
--);
SELECT
	Measures.MeasureID
	,ReportXML =(
		SELECT
			[@ID]				=CaseID
			,Identified
			,[CaseValue1/@Name]	=CaseColumn1
			,CaseValue1
			,[CaseValue2/@Name]	=CaseColumn2
			,CaseValue2
			,[CaseValue3/@Name]	=CaseColumn3
			,CaseValue3
			,[CaseValue4/@Name]	=CaseColumn4
			,CaseValue4
			,[CaseValue5/@Name]	=CaseColumn5
			,CaseValue5
			,[CaseValue6/@Name]	=CaseColumn6
			,CaseValue6
			,[CaseValue7/@Name]	=CaseColumn7
			,CaseValue7
			,[CaseValue8/@Name]	=CaseColumn8
			,CaseValue8
			,[CaseValue9/@Name]	=CaseColumn9
			,CaseValue9
			,CaseValuesExtended
		FROM [tdq].[alpha_ReportCases]
		WHERE MeasureID = Measures.MeasureID
		FOR XML PATH('Case'), ROOT('Cases'), TYPE
	)
FROM [tdq].[alpha_ReportMeasures] Measures;
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportCasesXML];
