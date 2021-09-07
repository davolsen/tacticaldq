CREATE OR ALTER FUNCTION [tdq].[alpha_BoxDec]
/*<object><sequence>10</sequence></object>*/
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
