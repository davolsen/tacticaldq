CREATE OR ALTER VIEW [tdq].[alpha_ReportCasesDailyXML] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>60</sequence></object>*/
SELECT (
	SELECT
		[@MeasureID]			=MeasureID
		,[@ReportDateClosing]	=ReportDateClosing
		,MeasureCode
		,ReportDateOpening
		,DaysPast
		,CasesOpening
		,CasesResolved
		,CasesIdentified
		,CasesCarried
		,CasesClosing
		,CasesChange
		,CasesNetChange
	FROM [tdq].[alpha_ReportCasesDaily]
	FOR XML PATH('Summary'), ROOT('ReportCasesDaily'), TYPE
) AS ReportXML;
GO
SELECT * FROM [tdq].[alpha_ReportCasesDailyXML];