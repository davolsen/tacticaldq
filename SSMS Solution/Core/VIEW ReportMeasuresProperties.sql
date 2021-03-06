CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasuresProperties] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>50</Sequence></Object>*/
	WITH
		ReportingProperties AS (
			SELECT
				MeasureID
				,PropertyTag	=T2.ReportFields.value('local-name(.)','varchar(500)')
				,PropertyName	=T2.ReportFields.value('(@name)','varchar(500)') 
				,PropertyValue	=T2.ReportFields.value('(.[1])','varchar(500)') 
			FROM
				[tdq].[alpha_Measures] Measures
				CROSS APPLY Measures.ReportFields.nodes('/ReportFields/*')	T2(ReportFields)
			WHERE
				Measures.ReportFields IS NOT NULL
				AND Measures.MeasureID IS NOT NULL
		)
	SELECT
		MeasureID
		,PropertyName	=ISNULL(PropertyName, PropertyTag)
		,PropertyValue
	FROM ReportingProperties;
GO
SELECT * FROM [tdq].[alpha_ReportMeasuresProperties];