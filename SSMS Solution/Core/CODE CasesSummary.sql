CREATE OR ALTER FUNCTION [tdq].[alpha_CasesSummary]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
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
			WHERE MeasureID = @MeasureID
		)
		,CasesClosing AS (
			SELECT CaseID
			FROM [tdq].[alpha_Cases] FOR SYSTEM_TIME AS OF @EndUTC Cases
			WHERE MeasureID = @MeasureID
		)
		--,CasesCarried AS (
		--	SELECT CaseID FROM CasesOpening
		--	INTERSECT SELECT CaseID FROM CasesClosing
		--)
	SELECT
		CasesOpening	=COUNT(CasesOpening.CaseID)
		,CasesCarried	=COUNT(IIF(CasesOpening.CaseID IS NOT NULL AND CasesClosing.CaseID IS NOT NULL, 1, NULL))
		,CasesClosing	=COUNT(CasesClosing.CaseID)
	FROM
		CasesOpening
		FULL OUTER JOIN CasesClosing ON CasesClosing.CaseID = CasesOpening.CaseID
	--SELECT
	--	CasesOpening	=(SELECT COUNT(*) FROM CasesOpening)
	--	,CasesCarried	=0
	--	,CasesClosing	=(SELECT COUNT(*) FROM CasesClosing)
);
GO
DECLARE @Time AS datetime2(7) = SYSDATETIME();
SELECT * FROM [tdq].[alpha_CasesSummary]('3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E','2021-09-20 08:01:57 +00:00','2021-09-20 08:02:59 +00:00');
PRINT DATEDIFF(MILLISECOND,@Time,SYSDATETIME());

select count(*) from [tdq].alpha_Refreshes