CREATE OR ALTER FUNCTION [tdq].[alpha_RoundDate]
/*<object><sequence>10</sequence></object>*/
(
	@Timestamp	datetimeoffset(0)
	,@Rounding	varchar(11)			='DAY'
)
RETURNS datetimeoffset(0)
AS BEGIN
	SET @Timestamp = @Timestamp AT TIME ZONE [tdq].[alpha_BoxText]('WorkingTimezoneName')
	RETURN TODATETIMEOFFSET(DATETIMEOFFSETFROMPARTS(YEAR(@Timestamp),MONTH(@Timestamp),DAY(@Timestamp),IIF(@Rounding = 'HOUR', DATEPART(HOUR,@Timestamp), 0),0,0,0,0,0,7),DATEPART(TZOFFSET,@Timestamp));
END;