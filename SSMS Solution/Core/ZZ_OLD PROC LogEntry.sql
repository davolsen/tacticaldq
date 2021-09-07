CREATE OR ALTER PROC [tdq].[alpha_LogEntry] (
	@LogEntryID		int = NULL OUTPUT--If an entry already exists, supply ID to update
	,@LogMessage	nvarchar(4000) = NULL
	,@LogSource		nvarchar(128) = NULL
	,@Code			nvarchar(50) = NULL
	,@Error		bit = NULL
	,@Completed		bit = NULL--will also set CompletedTimestamp
	,@MeasureID		uniqueidentifier = NULL
	,@CaseCount		int = NULL--record count for measurements
) AS BEGIN
	BEGIN TRY
		IF @LogEntryID IS NULL BEGIN
			--Create log entry
			DECLARE @LogEntryIDTable TABLE(LogEntryID int)--capture new LogEntryID
			INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, Completed, LogMessage)
			OUTPUT inserted.LogEntryID INTO @LogEntryIDTable
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
					WHEN @Completed IS NOT NULL THEN @Completed
					WHEN ERROR_STATE() IS NOT NULL THEN 0
					ELSE NULL
						END
				,CASE
					WHEN @LogMessage IS NOT NULL THEN @LogMessage
					WHEN ERROR_STATE() IS NOT NULL THEN ERROR_MESSAGE()
					ELSE NULL
						END
			);
			--Return LogEntryID
			SET @LogEntryID = (SELECT TOP 1 LogEntryID FROM @LogEntryIDTable);
			SELECT * FROM [tdq].[alpha_Log] WHERE LogEntryID = @LogEntryID
			RETURN @LogEntryID;
		END;
		ELSE BEGIN
			UPDATE [tdq].[alpha_Log]
			SET
				Code = CASE
					WHEN @Code IS NOT NULL THEN @Code
					WHEN ERROR_STATE() IS NOT NULL THEN ERROR_PROCEDURE()
					ELSE Code
						END
				,Error = CASE
					WHEN @Error IS NOT NULL THEN @Error
					WHEN ERROR_STATE() IS NOT NULL THEN 1
					ELSE Error
						END
				,Completed = CASE
					WHEN @Completed IS NOT NULL THEN @Completed
					WHEN ERROR_STATE() IS NOT NULL THEN 0
					ELSE Completed
						END
				,CompletedTimetamp = IIF(@Completed = 1,SYSDATETIMEOFFSET(),CompletedTimetamp)
				,LogMessage = CASE
					WHEN @LogMessage IS NOT NULL THEN @LogMessage
					WHEN ERROR_STATE() IS NOT NULL THEN ERROR_MESSAGE()
					ELSE LogMessage
						END
		END;
	END TRY
	BEGIN CATCH
		INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, Completed, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, 0, ERROR_MESSAGE());
	END CATCH;
END;