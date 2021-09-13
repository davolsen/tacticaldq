CREATE OR ALTER VIEW [tdq].[alpha_ReportCases] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>50</sequence></object>*/
WITH
	Measurements AS (
		SELECT *
		FROM
			(
				SELECT
					MeasurementID
					,MeasureID
					,ColumnName		='CaseColumn' + CAST(ROW_NUMBER() OVER (PARTITION BY MeasurementID ORDER BY (SELECT NULL)) AS nvarchar(128))
					,ColumnValue	=SUBSTRING(value,2,LEN(value)-2)
				FROM
					[tdq].[alpha_Measurements]
					CROSS APPLY STRING_SPLIT(CaseColumns,',')
			) Measurements
			PIVOT (
				MAX(ColumnValue)
				FOR ColumnName IN ([CaseColumn1],[CaseColumn2],[CaseColumn3],[CaseColumn4],[CaseColumn5],[CaseColumn6],[CaseColumn7],[CaseColumn8],[CaseColumn9])
			) ColumnPivot
	)
SELECT
	Measures.MeasureID
	,Measures.MeasureCode
	,Measurements.MeasurementID
	,CaseID
	,CaseColumn1
	,CaseValue1
	,CaseColumn2
	,CaseValue2
	,CaseColumn3
	,CaseValue3
	,CaseColumn4
	,CaseValue4
	,CaseColumn5
	,CaseValue5
	,CaseColumn6
	,CaseValue6
	,CaseColumn7
	,CaseValue7
	,CaseColumn8
	,CaseValue8
	,CaseColumn9
	,CaseValue9
	,CaseValuesExtended
	,Identified
FROM
	[tdq].[alpha_Cases]				Cases
	JOIN Measurements								ON Measurements.MeasurementID	=Cases.MeasurementID
	JOIN [tdq].[alpha_Measures]		Measures		ON Measures.MeasureID			=Measurements.MeasureID;
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportCases]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'