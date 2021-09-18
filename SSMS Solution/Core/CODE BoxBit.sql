CREATE OR ALTER FUNCTION [tdq].[alpha_BoxBit]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
(
	@ObjectName nvarchar(128)
)
RETURNS bit
AS
BEGIN
	DECLARE @return bit = (
		SELECT TOP 1 DefinitionBit
		FROM [tdq].[alpha_box]
		WHERE
			ObjectName		=@ObjectName
			AND ObjectType	='CONF'
	);
	RETURN @return;
END;
