CREATE OR ALTER PROC [tdq].[alpha_OutputCaseListUnpublish](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>72</Sequence></Object>*/
	@RefreshID int
) AS BEGIN
	UPDATE [tdq].[alpha_Refreshes]
	SET Unpublished		=1
	WHERE RefreshID		=@RefreshID;
END;
GO
--SELECT * FROM [tdq].[alpha_OutputCaseLists];
--EXEC [tdq].[alpha_OutputCaseListUnpublish] @RefreshID = 2411;
--SELECT * FROM [tdq].[alpha_OutputCaseLists];
