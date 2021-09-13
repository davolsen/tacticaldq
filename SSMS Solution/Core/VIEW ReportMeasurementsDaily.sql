CREATE OR ALTER VIEW [tdq].[alpha_ReportMeasurementsDaily] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>50</sequence></object>*/
WITH
	CalendarRange AS (
		SELECT
			DaysPast			=ROW_NUMBER() OVER (ORDER BY value) - 1
			,ReportDateOpening	=[tdq].[alpha_RoundDate](SYSDATETIMEOFFSET(),'DAY')
			,ReportDateClosing	=CAST(SYSDATETIMEOFFSET() AS datetimeoffset(0))
		FROM STRING_SPLIT(REPLICATE('.',[tdq].[alpha_BoxDec]('ReportHistoryDays')),'.')
	)
	,Calendar AS (
		SELECT
			ReportDateOpening	=DATEADD(DAY,-DaysPast,ReportDateOpening)
			,ReportDateClosing	=CASE DaysPast
									WHEN 0 THEN ReportDateClosing
									ELSE DATEADD(DAY,-DaysPast+1,ReportDateOpening)
										END
			,DaysPast
		FROM CalendarRange
)
SELECT
	MeasureID
	,MeasureCode
	,ReportDateOpening
	,ReportDateClosing
	,DaysPast
	,CasesOpening
	,CasesResolved		=CasesOpening-CasesCarried
	,CasesIdentified	=CasesClosing-CasesCarried
	,CasesCarried
	,CasesClosing
	,CasesChange		=(CasesOpening-CasesCarried)+(CasesClosing-CasesCarried)
	,CasesNetChange		=CasesClosing-CasesOpening
FROM
	[tdq].[alpha_Measures]
	CROSS JOIN Calendar
	CROSS APPLY [tdq].[alpha_CasesSummary](MeasureID, DATEADD(SECOND,-1,ReportDateOpening) AT TIME ZONE 'UTC', DATEADD(SECOND,1,ReportDateClosing) AT TIME ZONE 'UTC') CaseSummary
GO

--SET DATEFIRST 1
SELECT * FROM [tdq].[alpha_ReportMeasurementsDaily]
--WHERE MeasureID = 'CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7'
ORDER BY ReportDateClosing DESC, MeasureID;
