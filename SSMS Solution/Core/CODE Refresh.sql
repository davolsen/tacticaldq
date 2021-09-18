CREATE OR ALTER PROC [tdq].[alpha_Refresh](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>31</Sequence></Object>*/
	@MeasureID		uniqueidentifier	= NULL--always overrides Code
	,@MeasureCode	nvarchar(50)		= NULL
) AS BEGIN
	PRINT 'Refresh a measure by ID or Code'
	SET NOCOUNT ON;
	DECLARE
		@SQL				nvarchar(4000)--holds dynamic SQL
		,@TempCaseTableName	nvarchar(128) ='##tdq_'+REPLACE(NEWID(),'-','_')--temporarily holds measure data
		,@RefreshID		int;--holds a new refresh ID

	BEGIN TRY
		PRINT 'Get measure details'
		DECLARE
			@ObjectName		nvarchar(128)
			,@MeasureOwner	nvarchar(254)
		SELECT TOP 1
			@MeasureID		=MeasureID
			,@MeasureCode	=MeasureCode
			,@ObjectName	=ObjectName
			,@MeasureOwner	=MeasureOwner
		FROM [tdq].[alpha_MeasuresActivity]
		WHERE
			MeasureID			= @MeasureID
			OR (
				@MeasureID		IS NULL
				AND MeasureCode	= @MeasureCode
			)

		IF @@ROWCOUNT = 1 BEGIN--Measure is valid
			PRINT 'Measure valid, start refresh';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, RefreshID, Code, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @RefreshID, @MeasureCode, 'Starting refresh of '+ISNULL(@ObjectName,'<UNEXPECTED: no object name>'));
				
			BEGIN TRAN;
				PRINT 'Create new refresh entry';
				DECLARE @RefreshIDTable TABLE(RefreshID int);
				INSERT INTO [tdq].[alpha_Refreshes](MeasureID)
				OUTPUT inserted.RefreshID INTO @RefreshIDTable
				VALUES (@MeasureID);
				SET @RefreshID =(SELECT TOP 1 RefreshID FROM @RefreshIDTable);

				PRINT 'Refresh measure'
				SET @SQL = 'SELECT * INTO '+@TempCaseTableName+' FROM '+@ObjectName;
				EXEC(@SQL);

				PRINT 'Check measure was refreshed';
				DECLARE @TempCaseTableObjectID int =OBJECT_ID('tempdb..'+@TempCaseTableName);
				IF @TempCaseTableObjectID IS NOT NULL BEGIN
					PRINT 'Refresh complete. Merge into case table';
					SET @SQL = [tdq].[alpha_RefreshMergeStatement](@TempCaseTableName,@MeasureID,@RefreshID);
					PRINT @SQL;
					EXECUTE(@SQL);
					PRINT 'Update refresh entry';
					UPDATE [tdq].[alpha_Refreshes]
					SET
						TimestampCompleted	=SYSDATETIMEOFFSET()
						,CaseColumns		=[tdq].[alpha_RefreshTempColumns](@TempCaseTableName)
					WHERE RefreshID		=@RefreshID;
				END;
			COMMIT;
			PRINT 'Log complete';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, RefreshID, Code, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @RefreshID, @MeasureCode, 'Completed measure refresh.');
		END;
		ELSE BEGIN
			PRINT 'Measure invalid, log failure';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, RefreshID, Code, Error, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @RefreshID, @MeasureCode, 1, 'Measure not found.');
		END;
	END TRY
	BEGIN CATCH
		PRINT 'Fatal error encountered';
		IF @@TRANCOUNT > 0 ROLLBACK;
		INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, RefreshID, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), @MeasureID, @RefreshID, ERROR_NUMBER(), 1, ERROR_MESSAGE());
		IF [tdq].[alpha_BoxBit]('MailErrorReporting') = 1 AND @MeasureOwner IS NOT NULL BEGIN
			PRINT 'Send an email'
			DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE()
			EXEC [tdq].[alpha_MailSend]
				@Receipients	=@MeasureOwner
				,@Subject		='Error refreshing measure.'
				,@TemplateName	='MailTemplateMeasureError'
				,@Parameter1	=@MeasureCode
				,@Parameter2	=@MeasureID
				,@Parameter3	=@RefreshID
				,@Parameter4	=@ErrorMessage
		END;
	END CATCH;

	IF OBJECT_ID('tempdb..'+@TempCaseTableName) IS NOT NULL BEGIN
		PRINT 'Tidy up';
		SET @SQL = 'DROP TABLE '+@TempCaseTableName;
		EXEC (@SQL);
	END;
END;