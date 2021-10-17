CREATE OR ALTER PROC [tdq].[alpha_Refresh](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>31</Sequence></Object>*/
	@MeasureID		uniqueidentifier	= NULL--always overrides Code
	,@MeasureCode	nvarchar(50)		= NULL
	,@NextFromQueue	bit					= NULL
) AS BEGIN
	PRINT 'Refresh a measure by ID or Code'
	SET NOCOUNT ON;
	DECLARE
		@SQL				nvarchar(max)--holds dynamic SQL
		,@TempCaseTableName	nvarchar(128) ='##tdq_'+REPLACE(NEWID(),'-','_')--temporarily holds measure data
		,@RefreshID		int;--holds a new refresh ID

	BEGIN TRY
		IF @NextFromQueue = 1 BEGIN
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
				SET @MeasureCode	=@Message.value('(/Refresh/Code/text())[1]', 'nvarchar(100)')
				SET @MeasureID		=@Message.value('(/Refresh/ID/text())[1]', 'nchar(36)')
				PRINT 'Log job and start a refresh';
				INSERT [tdq].[alpha_Log](LogSource, MeasureID, Code, LogMessage)
				VALUES (OBJECT_NAME(@@PROCID), @MeasureID, @MeasureCode, 'Fetched refresh task from queue');
			END;
			ELSE IF @ResultCount = 0 BEGIN--no job
				PRINT 'No measure refresh tasks in queue';
				INSERT INTO [tdq].[alpha_Log](LogSource, LogMessage)
				VALUES (OBJECT_NAME(@@PROCID), 'No refresh tasks waiting in queue');
			END;
		END;

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
					DECLARE
						@InsertColumns			nvarchar(max)
						,@SelectColumns			nvarchar(max)
						,@MaxColumns			int				=9;
					WITH
						ColumnList AS (
							SELECT
								[name]
								,column_id
								,user_type_id
								,ColumnCount	=COUNT(*) OVER (PARTITION BY object_id)
							FROM tempdb.sys.columns
							WHERE [object_id] = @TempCaseTableObjectID
						)
						,Statements AS (
							SELECT
								InsertColumns	=CAST('CaseValue1' AS nvarchar(max))
								,SelectColumns	='['+CAST(name AS nvarchar(max))+']'
								,column_id
								,NextID			=column_id + 1
							FROM ColumnList
							WHERE column_id = 1

							UNION ALL SELECT
								Statements.InsertColumns
									+ CASE
										WHEN ColumnList.column_id <= @MaxColumns THEN
											',CaseValue'
											+CAST(ColumnList.column_id AS nvarchar)
										WHEN ColumnList.column_id = @MaxColumns + 1 THEN ',CaseValuesExtended'
										ELSE ''
									END
								,Statements.SelectColumns
									+CASE WHEN ColumnList.column_id > @MaxColumns THEN
										+IIF(ColumnList.column_id = @MaxColumns + 1,',CONCAT(',',')
										+''''
										+IIF(ColumnList.column_id > @MaxColumns + 1,';','')
										+IIF(ColumnList.column_id > @MaxColumns,name + '=','')
										+''''
											ELSE '' END
									+','
									+IIF(TYPE_NAME(user_type_id) IN ('sql_variant','xml','hierarchyid','geometry','geography'),'CAST(','')
									+'['+IIF(TYPE_NAME(user_type_id) NOT IN ('image', 'timestamp'),name,'CANNOT CONVERT IMAGE OR TIMESTAMP')+']'
									+IIF(TYPE_NAME(user_type_id) IN ('sql_variant','xml','hierarchyid','geometry','geography'),' AS nvarchar(4000))','')
									+IIF(ColumnList.column_id > @MaxColumns AND ColumnList.column_id = ColumnList.ColumnCount,')','')
								,ColumnList.column_id
								,ColumnList.column_id + 1
							FROM
								Statements
								JOIN ColumnList ON ColumnList.column_id = Statements.NextID
						)
					SELECT
						@InsertColumns	=InsertColumns
						,@SelectColumns	=SelectColumns
					FROM Statements
					WHERE column_id = (SELECT MAX(column_id) FROM Statements);

					SET @SQL = '
						WITH NewCases AS (SELECT CaseChecksum=BINARY_CHECKSUM(*),* FROM '+@TempCaseTableName+')
						MERGE [tdq].[alpha_Cases] CurrentCases
						USING NewCases ON NewCases.CaseChecksum = CurrentCases.CaseChecksum AND MeasureID = '''+CAST(@MeasureID AS nvarchar(36))+'''
						WHEN NOT MATCHED THEN INSERT (RefreshID,MeasureID,CaseChecksum,'+@InsertColumns+') VALUES ('+CAST(@RefreshID AS nvarchar)+','''+CAST(@MeasureID AS nvarchar(36))+''',CaseChecksum,'+@SelectColumns+')
						WHEN NOT MATCHED BY SOURCE AND MeasureID = '''+CAST(@MeasureID AS nvarchar(36))+''' THEN DELETE;
					'

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