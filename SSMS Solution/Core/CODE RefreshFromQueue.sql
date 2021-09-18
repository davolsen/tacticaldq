CREATE OR ALTER PROC [tdq].[alpha_RefreshFromQueue] AS BEGIN
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>32</Sequence></Object>*/
	DECLARE
		@SQL				nvarchar(4000)--holds dynamic SQL
		,@TempCaseTableName	nvarchar(128)	='##tdq_' + REPLACE(NEWID(),'-','_');

	BEGIN TRY
		SET NOCOUNT ON;
		PRINT 'Get next refresh task from queue';
		DECLARE
			@Message			xml--from the queue
			,@MessageTypeName	nvarchar(256);--from the queue
		RECEIVE TOP(1)
			@Message			=message_body
			,@MessageTypeName	=message_type_name
		FROM [tdq].[alpha_RefreshesPending];
		DECLARE @ResultCount int = @@ROWCOUNT;

		IF @MessageTypeName = 'DEFAULT' BEGIN--DFAULT is a job. Other message types are usually conversation statuses
			PRINT 'Get measure details';
			DECLARE
				@MeasureCode	nvarchar(50)		=@Message.value('(/Refresh/Code/text())[1]', 'nvarchar(100)')
				,@MeasureID		uniqueidentifier	=@Message.value('(/Refresh/ID/text())[1]', 'nchar(36)')
			PRINT 'Log job and start a refresh';
			INSERT [tdq].[alpha_Log](LogSource, MeasureID, Code, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @MeasureCode, 'Measure refresh started');
			EXEC [tdq].[alpha_Refresh] @MeasureID = @MeasureID
		END;
		ELSE IF @ResultCount = 0 BEGIN--no job
			PRINT 'No measure refresh tasks in queue';
			INSERT INTO [tdq].[alpha_Log](LogSource, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), 'No refresh tasks waiting in queue');
		END;
	END TRY
	BEGIN CATCH--log error
		PRINT 'Log fatal error';
		INSERT [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, ERROR_MESSAGE());
	END CATCH;
	PRINT 'Tidy up';
	IF OBJECT_ID('tempdb..' + @TempCaseTableName) IS NOT NULL BEGIN
		SET @SQL = 'DROP TABLE ' + @TempCaseTableName;
		EXEC (@SQL);
	END;
END;
GO

--EXEC [tdq].[alpha_RefreshFromQueue] ;