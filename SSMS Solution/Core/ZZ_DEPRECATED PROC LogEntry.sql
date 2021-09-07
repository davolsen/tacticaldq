CREATE OR ALTER PROC [tdq].[alpha_LogEntry] (
	@LogEntryID		int = NULL OUTPUT--If an entry already exists, supply ID to update
	,@LogMessage	nvarchar(4000) = NULL
	,@LogSource		nvarchar(128) = NULL
	,@Code			nvarchar(50) = NULL
	,@Error			bit = NULL
) AS BEGIN
	BEGIN TRY
		--Create log entry
		INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
		VALUES (
			CASE
				WHEN @LogSource IS NOT NULL THEN @LogSource
				WHEN ERROR_STATE() IS NOT NULL THEN ERROR_PROCEDURE()
				ELSE NULL
					END
			,CASE
				WHEN @Code IS NOT NULL THEN @Code
				WHEN ERROR_STATE() IS NOT NULL THEN ERROR_NUMBER()
				ELSE NULL
					END
			,CASE
				WHEN @Error IS NOT NULL THEN @Error
				WHEN ERROR_STATE() IS NOT NULL THEN 1
				ELSE NULL
					END
			,CASE
				WHEN @LogMessage IS NOT NULL THEN @LogMessage
				WHEN ERROR_STATE() IS NOT NULL THEN ERROR_MESSAGE()
				ELSE NULL
					END
		);
	END TRY
	BEGIN CATCH
		INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, ERROR_MESSAGE());
	END CATCH;
END;