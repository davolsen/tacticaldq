CREATE OR ALTER PROC [tdq].[alpha_OutputCaseListPublish](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>71</Sequence></Object>*/
	@MeasureID uniqueidentifier
) AS BEGIN
	DECLARE
		@CurrentCases	bit =IIF(EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE MeasureID = @MeasureID),1,0)
		,@RefreshID		int	=(
								SELECT RefreshID
								FROM (
									SELECT
										RefreshID
										,Age		=ROW_NUMBER() OVER (ORDER BY TimestampStarted DESC)
									FROM [tdq].[alpha_Refreshes] Refreshes
									WHERE
										MeasureID = @MeasureID
										AND EXISTS (SELECT 1 FROM [tdq].[alpha_Cases] WHERE RefreshID = Refreshes.RefreshID)
								)T
								WHERE Age = 1
							);

	UPDATE [tdq].[alpha_Refreshes]
	SET Unpublished		=	1
	WHERE MeasureID		=	@MeasureID;

	UPDATE [tdq].[alpha_Refreshes]
	SET
		Published		=1
		,Unpublished	=0
	WHERE RefreshID	=@RefreshID;

	SELECT
		RefreshID	=@RefreshID
		,MeasureXML =(
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
			WHERE MeasureID = @MeasureID
			FOR XML PATH('Measure'), Type
		)
		,ReportXML
	FROM [tdq].[alpha_ReportCasesXML]
	WHERE MeasureID = @MeasureID
END;
GO
SELECT * FROM [tdq].[alpha_OutputCaseLists];
EXEC [tdq].[alpha_OutputCaseListPublish] @MeasureID = '3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E';
SELECT * FROM [tdq].[alpha_OutputCaseLists];
