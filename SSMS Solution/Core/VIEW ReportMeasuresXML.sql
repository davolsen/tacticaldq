CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasuresXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>60</sequence></object>*/

SELECT ReportXML = (
	SELECT
		[@ID] = MeasureID
		,MeasureCode
		,MeasureDescription
		,RefreshLastTimestampStarted
		,CasesToday
		,CasesTodayResolved
		,CasesTodayIdentified
		,CasesTodayNetChange
		,MeasureOwner
		,MeasureCategory
		--,ReportFields
		,RefreshPolicy
		,RefreshTimeOffset
		,RefreshNext
		,Error
	FROM [tdq].[alpha_ReportMeasures] Measures
	FOR XML PATH('Measure'), ROOT('Measures'), Type
)
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasuresXML]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
