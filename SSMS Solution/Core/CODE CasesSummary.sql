CREATE OR ALTER FUNCTION [tdq].[alpha_CasesSummary]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>10</sequence></object>*/
(
	@MeasureID	uniqueidentifier
	,@BeginUTC	datetime2
	,@EndUTC	datetime2
)
RETURNS TABLE AS RETURN (
	WITH
		CasesOpening AS (
			SELECT CaseID
			FROM [tdq].[alpha_Cases] FOR SYSTEM_TIME AS OF @BeginUTC
			WHERE MeasureID = @MeasureID
		)
		,CasesClosing AS (
			SELECT CaseID
			FROM [tdq].[alpha_Cases] FOR SYSTEM_TIME AS OF @EndUTC
			WHERE MeasureID = @MeasureID
		)
	SELECT
		CasesOpening	=COUNT(CasesOpening.CaseID)
		,CasesCarried	=COUNT(IIF(CasesOpening.CaseID IS NOT NULL AND CasesClosing.CaseID IS NOT NULL, 1, NULL))
		,CasesClosing	=COUNT(CasesClosing.CaseID)
	FROM
		CasesOpening
		FULL OUTER JOIN CasesClosing ON CasesClosing.CaseID = CasesOpening.CaseID
);