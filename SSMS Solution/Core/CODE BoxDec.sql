CREATE OR ALTER FUNCTION [tdq].[alpha_BoxDec]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
(
	@ObjectName nvarchar(128)
)
RETURNS decimal(19,5)
AS
BEGIN
	DECLARE @return decimal(19,5) = (
		SELECT TOP 1 DefinitionDecimal
		FROM [tdq].[alpha_box]
		WHERE
			ObjectName		=@ObjectName
			AND ObjectType	='CONF'
	);
	RETURN @return;
END;
