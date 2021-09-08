CREATE OR ALTER PROC [tdq].[alpha_Refresh](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>31</sequence></object>*/
	@MeasureID		uniqueidentifier	= NULL--always overrides Code
	,@MeasureCode	nvarchar(50)		= NULL
) AS BEGIN
	PRINT 'Refresh a measure by ID or Code'
	SET NOCOUNT ON;
	DECLARE
		@SQL				nvarchar(4000)--holds dynamic SQL
		,@TempCaseTableName	nvarchar(128) ='##tdq_'+REPLACE(NEWID(),'-','_')--temporarily holds measurement data
		,@MeasurementID		int;--holds a new measurement ID

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
		FROM [tdq].[alpha_Measures]
		WHERE
			MeasureID			= @MeasureID
			OR (
				@MeasureID		IS NULL
				AND MeasureCode	= @MeasureCode
			)

		IF @@ROWCOUNT = 1 BEGIN--Measure is valid
			PRINT 'Measure valid, start refresh';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, MeasurementID, Code, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @MeasurementID, @MeasureCode, 'Starting measurement refresh from '+ISNULL(@ObjectName,'<UNEXPECTED: no object name>'));

			PRINT 'Create new measurement entry';
			DECLARE @MeasurementIDTable TABLE(MeasurementID int);
			INSERT INTO [tdq].[alpha_Measurements](MeasureID)
			OUTPUT inserted.MeasurementID INTO @MeasurementIDTable
			VALUES (@MeasureID);
			SET @MeasurementID =(SELECT TOP 1 MeasurementID FROM @MeasurementIDTable);

			PRINT 'Take measurement'
			SET @SQL = 'SELECT * INTO '+@TempCaseTableName+' FROM '+@ObjectName;
			EXEC(@SQL);

			PRINT 'Check measurement was taken';
			DECLARE @TempCaseTableObjectID int =OBJECT_ID('tempdb..'+@TempCaseTableName);
			IF @TempCaseTableObjectID IS NOT NULL BEGIN
				PRINT 'Measurement taken. Merge into case table';
				SET @SQL = [tdq].[alpha_CasesMergeStatement](@TempCaseTableName,@MeasureID,@MeasurementID);
			PRINT @SQL;
				EXECUTE(@SQL);

				PRINT 'Update measurement entry';
				UPDATE [tdq].[alpha_Measurements]
				SET TimestampCompleted	=SYSDATETIMEOFFSET()
				WHERE MeasurementID		=@MeasurementID;
			END;

			PRINT 'Log complete';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, MeasurementID, Code, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @MeasurementID, @MeasureCode, 'Completed measurement refresh.');
		END;
		ELSE BEGIN
			PRINT 'Measure invalid, log failure';
			INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, MeasurementID, Code, Error, LogMessage)
			VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @MeasurementID, @MeasureCode, 1, 'Measure not found.');
		END;
	END TRY
	BEGIN CATCH
		PRINT 'Fatal error encountered';
		IF @MeasurementID IS NOT NULL BEGIN
			PRINT 'Delete any data captured';
			DELETE FROM [tdq].[alpha_Measurements] WHERE MeasurementID = @MeasurementID;
			DELETE FROM [tdq].[alpha_Cases] WHERE MeasurementID = @MeasurementID;
		END;
		INSERT INTO [tdq].[alpha_Log](LogSource, MeasureID, MeasurementID, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), @MeasureID, @MeasurementID, ERROR_NUMBER(), 1, ERROR_MESSAGE());
		IF [tdq].[alpha_BoxBit]('MailErrorReporting') = 1 AND @MeasureOwner IS NOT NULL BEGIN
			PRINT 'Send an email'
			DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE()
			EXEC [tdq].[alpha_MailSend]
				@Receipients	=@MeasureOwner
				,@Subject		='Error taking measurement.'
				,@TemplateName	='MailTemplateMeasureError'
				,@Parameter1	=@MeasureCode
				,@Parameter2	=@MeasureID
				,@Parameter3	=@MeasurementID
				,@Parameter4	=@ErrorMessage
		END;
	END CATCH;

	IF OBJECT_ID('tempdb..'+@TempCaseTableName) IS NOT NULL BEGIN
		PRINT 'Tidy up';
		SET @SQL = 'DROP TABLE '+@TempCaseTableName;
		EXEC (@SQL);
	END;
END;