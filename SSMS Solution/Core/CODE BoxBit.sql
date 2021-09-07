CREATE OR ALTER FUNCTION [tdq].[alpha_BoxBit]
/*<object><sequence>10</sequence></object>*/
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
