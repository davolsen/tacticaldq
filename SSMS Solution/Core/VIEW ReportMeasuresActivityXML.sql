CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasuresActivityXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>60</Sequence></Object>*/

SELECT ReportXML = (
	SELECT
		[@ID] = MeasureID
		,MeasureCode
		,MeasureDefinition
		,RefreshLastTimestampStarted
		,CasesToday
		,CasesTodayResolved
		,CasesTodayIdentified
		,CasesTodayNetChange
		,MeasureOwner
		,MeasureCategory
		,CAST(ReportFields AS xml)--not necessary, but allows us to return a blank column name so we don't end with double nesting
		,RefreshPolicy
		,RefreshTimeOffset
		,RefreshNext
		,Error
	FROM [tdq].[alpha_ReportMeasuresActivity] Measures
	FOR XML PATH('Measure'), ROOT('Measures'), Type
)
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasuresActivityXML]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
