CREATE OR ALTER FUNCTION [tdq].[alpha_RefreshTempColumns]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
(
	@TempCaseTableName nvarchar(128)
)
RETURNS nvarchar(1178)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @return nvarchar(4000) = (
		SELECT STRING_AGG('['+name+']',',')
		FROM tempdb.sys.columns
		WHERE
			object_id = OBJECT_ID('tempdb..'+@TempCaseTableName)
			AND column_id < 10
	);
	RETURN @return;
END;
