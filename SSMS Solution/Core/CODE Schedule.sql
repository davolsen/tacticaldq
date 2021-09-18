CREATE OR ALTER PROC [tdq].[alpha_Schedule] AS BEGIN
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>41</Sequence></Object>*/
	SET NOCOUNT ON;
	DECLARE
		@ConversationID		uniqueidentifier
		,@Message				xml--Put on the queue
		,@MeasureID			uniqueidentifier--goes in the Task
		,@MeasureCode		nvarchar(50)--goes in the Task
		,@ObjectName		nvarchar(128)--goes in the Task
		,@LogTaskCounter		int = 0--counts Tasks added to queue for logging
		,@LogMeasureList	nvarchar(4000)--lists measures added to queue
		,@ServiceName		nvarchar(128) = '[alpha_Scheduler]';--BRACKETS ARE NEEDED for bootstrap/unpack

	BEGIN TRY
		PRINT 'Open Queue';
		SET @ServiceName = REPLACE(REPLACE(@ServiceName,'[',''),']','');--strip brackets
		BEGIN DIALOG CONVERSATION @ConversationID FROM SERVICE [alpha_Scheduler] TO SERVICE @ServiceName ON CONTRACT [DEFAULT] WITH ENCRYPTION = OFF;
		PRINT 'Loop through measures due for refresh';
		DECLARE NewBatch CURSOR FAST_FORWARD FOR
			SELECT ObjectName, MeasureCode, MeasureID
			FROM [tdq].[alpha_MeasuresActivity] Measures
			WHERE
				RefreshNext < SYSDATETIMEOFFSET()
				AND NOT EXISTS (--and not already in queue
					SELECT 1 FROM [tdq].[alpha_ScheduleCurrent]
					WHERE MeasureID = Measures.MeasureID
				);
		OPEN NewBatch;
		FETCH NEXT FROM NewBatch INTO @ObjectName, @MeasureCode, @MeasureID;
		WHILE @@FETCH_STATUS = 0 BEGIN
			PRINT 'Create a Task XML';
			SET @LogTaskCounter = @LogTaskCounter + 1
			SET @LogMeasureList = ISNULL(@LogMeasureList+', ','')+ISNULL(@MeasureCode, 'ERROR! no measure code')
			SET @Message = (
				SELECT
					@MeasureID		ID
					,@MeasureCode	Code
					,@ObjectName	ObjectName
				FOR XML PATH('Refresh'), TYPE
			);
			PRINT 'Add Task to the queue';
			SEND ON CONVERSATION @ConversationID MESSAGE TYPE [DEFAULT](@Message);
			PRINT 'Get next Task';
			FETCH NEXT FROM NewBatch INTO @ObjectName, @MeasureCode, @MeasureID;
		END;
		PRINT 'No Tasks left to add. Tidy up';
		CLOSE NewBatch;
		DEALLOCATE NewBatch;
		END CONVERSATION @ConversationID;
		PRINT 'Log refresh Tasks added';
		IF @LogTaskCounter > 0 BEGIN
			INSERT INTO [tdq].[alpha_Log](LogSource, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), 'Queued '+CAST(@LogTaskCounter AS nvarchar)+' measures for refresh: '+ISNULL(@LogMeasureList,'ERROR! could not get measure codes'));
		END;
		ELSE BEGIN
			INSERT INTO [tdq].[alpha_Log](LogSource, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), 'No measures need to be refreshed.');
		END;
	END TRY
	BEGIN CATCH
		PRINT 'Log fatal error';
		IF CURSOR_STATUS('local','NewBatch') > -1 CLOSE NewBatch;
		IF CURSOR_STATUS('local','NewBatch') > -2 DEALLOCATE NewBatch;
		INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, ERROR_MESSAGE());
	END CATCH;
END;