CREATE OR ALTER FUNCTION [tdq].[alpha_BoxDate]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
(
	@ObjectName nvarchar(128)
)
RETURNS datetimeoffset(0)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @return datetimeoffset(0) = (
		SELECT TOP 1 DefinitionDate
		FROM [tdq].[alpha_box]
		WHERE
			ObjectName		=@ObjectName
			AND ObjectType	='CONF'
	);
	RETURN @return;
END;
