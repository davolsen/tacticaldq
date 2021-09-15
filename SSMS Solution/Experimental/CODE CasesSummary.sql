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
			FROM [tdq].[alpha_Cases] FOR SYSTEM_TIME AS OF @BeginUTC Cases
			WHERE EXISTS (SELECT 1 FROM [tdq].[alpha_Refreshes] WHERE RefreshID = Cases.RefreshID AND MeasureID = @MeasureID)
		)
		,CasesClosing AS (
			SELECT CaseID
			FROM [tdq].[alpha_Cases] FOR SYSTEM_TIME AS OF @EndUTC Cases
			WHERE EXISTS (SELECT 1 FROM [tdq].[alpha_Refreshes] WHERE RefreshID = Cases.RefreshID AND MeasureID = @MeasureID)
		)
	SELECT
		CasesOpening	=COUNT(CasesOpening.CaseID)
		,CasesCarried	=COUNT(IIF(CasesOpening.CaseID IS NOT NULL AND CasesClosing.CaseID IS NOT NULL, 1, NULL))
		,CasesClosing	=COUNT(CasesClosing.CaseID)
	FROM
		CasesOpening
		FULL OUTER JOIN CasesClosing ON CasesClosing.CaseID = CasesOpening.CaseID
);
GO
SELECT * FROM [tdq].[alpha_CasesSummary]('EE71C78F-34F2-4C30-AB81-16BF1C673FE0','2021-08-31','2021-09-01')