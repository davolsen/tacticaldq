CREATE OR ALTER PROC [tdq].[alpha_AgentConfig](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>40</sequence><autoExecute>true</autoExecute></object>*/
	@CheckOnly			bit = 0--1=Don't make changes, only check.
	,@Enabled			bit	= 1--1=The job should be enabled
	,@StartImmediately	bit = 0--1=Start the job immediately after setup
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ReturnValue int = 0;--bitwise: 0=All good;1=service broker disabled;2=Service missing;4=Queue missing;8=Agent job missing
	BEGIN TRY
		--Add the SQL Job if it doesn't exist
		DECLARE @job_name nvarchar(4000)	=DB_NAME()+'_[tdq].[alpha_Scheduler]';--needed for bootstrap/unpack scripting
		SET @job_name						=REPLACE(REPLACE(REPLACE(REPLACE(@job_name,'[',''),']',''),'.','_'),'dbo_','');

		PRINT 'Check for Job';
		IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name) BEGIN
			PRINT 'SQL Agent job already exists';
			IF @CheckOnly = 0 EXEC msdb.dbo.sp_delete_job @job_name = @job_name
		END;
		ELSE SET @ReturnValue = @ReturnValue + 8; 
		IF @CheckOnly = 0 BEGIN
			print 'Adding server agent job';
			BEGIN TRANSACTION
				DECLARE
					@CurrentDatabase		nvarchar(128)	=DB_NAME()
					,@ErrorCode				int
					,@ErrorMessage			nvarchar(4000)
					,@AgentCategoryName		nvarchar(4000)	=[tdq].[alpha_BoxText]('AgentCategoryName')
					,@AgentIntervalMinutes	int				=[tdq].[alpha_BoxDec]('AgentIntervalMinutes')
				PRINT 'Add category';
				IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name = @AgentCategoryName AND category_class=1) EXEC msdb.dbo.sp_add_category
					@class	=	N'JOB'
					,@type	=	N'LOCAL'
					,@name	=	@AgentCategoryName;

				PRINT 'Add job';
				DECLARE @jobId binary(16);
				EXEC msdb.dbo.sp_add_job
					@job_name				=@job_name
					,@description			=N'Checks which measurements need to be refreshed and schedules refresh jobs.'
					,@category_name			=@AgentCategoryName
					,@job_id 				=@jobId OUTPUT
					,@Enabled				=@Enabled;
				PRINT 'Update Box config';
				UPDATE [tdq].[alpha_Box] SET DefinitionText = @job_name WHERE ObjectName = 'AgentJobName';

				PRINT 'Add step';
				EXEC msdb.dbo.sp_add_jobstep
					@job_id					= @jobId
					,@step_name				= N'Check and schedule measurement refresh jobs'
					,@command				= N'EXEC [tdq].[alpha_Schedule]'
					,@database_name			= @CurrentDatabase;

				PRINT 'Configure job starting step';
				EXEC msdb.dbo.sp_update_job
					@job_id			= @jobId
					,@start_step_id	= 1;

				PRINT 'Add schedule';
				DECLARE @schedule_uid uniqueidentifier = NEWID();
				EXEC msdb.dbo.sp_add_jobschedule
					@job_id						= @jobId
					,@name						= N'CheckInterval'
					,@freq_type					= 4
					,@freq_interval				= 1
					,@freq_subday_type			= 4
					,@freq_subday_interval		= @AgentIntervalMinutes;

				PRINT 'Target server';
				EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)';

				IF (@StartImmediately = 1 AND @Enabled = 1) BEGIN
					PRINT 'Start job immediately';
					DECLARE @ReturnCode int
					EXEC @ReturnCode = msdb.dbo.sp_start_job @job_id = @jobId;
					IF @ReturnCode = 1 THROW 50000, 'Agent Job successfully created, but failed to start.', 1;
				END;
			END;
	END TRY
	BEGIN CATCH
		SET @ErrorCode = ERROR_NUMBER();
		SET @ErrorMessage = ERROR_MESSAGE();
		PRINT ISNULL(@ErrorMessage,ERROR_MESSAGE());
	END CATCH;
	IF ((@ErrorCode <> 0 OR @@ERROR <> 0 OR @ReturnCode <> 0) AND @@TRANCOUNT > 0) ROLLBACK TRANSACTION;
	ELSE IF @@TRANCOUNT > 0 COMMIT TRANSACTION;

	RETURN @ReturnValue;
END;
GO
--EXEC [tdq].[alpha_Config];
DECLARE @ReturnCode int;
EXEC @ReturnCode = [tdq].[alpha_AgentConfig] @StartImmediately = 1-- @CheckOnly = 1;
PRINT @ReturnCode;