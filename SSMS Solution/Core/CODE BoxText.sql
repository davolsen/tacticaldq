CREATE OR ALTER FUNCTION [tdq].[alpha_BoxText]
/*<object><sequence>10</sequence></object>*/
(
	@ObjectName nvarchar(128)
)
RETURNS nvarchar(4000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @return nvarchar(4000) = (
		SELECT TOP 1 DefinitionText
		FROM [tdq].[alpha_box]
		WHERE
			ObjectName		=@ObjectName
			AND ObjectType	='CONF'
	);
	RETURN @return;
END;