CREATE OR ALTER PROCEDURE [tdq].[alpha_Teardown](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>103</Sequence></Object>*/
	@PackFirst	bit	=1
	,@Confirm	bit	=0
) AS BEGIN
	/*<Object><Sequence>1</Sequence></Object>*/
	IF @Confirm		=0 THROW 50000, 'The confirm parameter must be set to 1', 1
	IF @PackFirst	=1 EXEC [tdq].[alpha_Pack]
	
	BEGIN TRY
		PRINT 'Turn off system versioning';
		ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);

		DECLARE @job_name nvarchar(4000) = [tdq].[alpha_BoxText]('AgentJobName');
		PRINT 'Stop and disable agent job';
		--EXEC msdb.dbo.sp_stop_job @Job_name = @job_name;
		EXEC msdb.dbo.sp_update_job @Job_name = @job_name, @enabled = 0;

		PRINT 'Get standard objects';
		DECLARE
			@ObjectName		nvarchar(128)
			,@ObjectType	char(2)
			,@HomeSchema	nvarchar(128)	=[tdq].[alpha_BoxText]('HomeSchema')
			,@SQL			nvarchar(4000)
		DECLARE ObjectList CURSOR FAST_FORWARD FOR
			SELECT name, type
			FROM
				sys.all_objects
				JOIN (
					SELECT
						ObjectName	=[tdq].[alpha_BoxText]('HomePrefix')+ObjectName
						,ObjectSequence
					FROM [tdq].[alpha_Box]
					WHERE ObjectType IN ('CODE','MESR','TABL')
				) AS BoxObjects ON BoxObjects.ObjectName = all_objects.name
			WHERE schema_id	=SCHEMA_ID(@HomeSchema)
			ORDER BY ObjectSequence DESC;
		OPEN ObjectList;
		FETCH NEXT FROM ObjectList INTO @ObjectName, @ObjectType;
		WHILE @@FETCH_STATUS = 0 BEGIN
			SET @SQL = 'DROP'
						+' '+CASE @ObjectType
							WHEN 'FN' THEN 'FUNCTION'
							WHEN 'IF' THEN 'FUNCTION'
							WHEN 'SQ' THEN 'QUEUE'
							WHEN 'U ' THEN 'TABLE'
							WHEN 'V ' THEN 'VIEW'
							WHEN 'P ' THEN 'PROC' END
						+' ['+@HomeSchema+'].['+@ObjectName+']'
			PRINT @SQL;
			EXEC (@SQL);
			FETCH NEXT FROM ObjectList INTO @ObjectName, @ObjectType;
		END;

		PRINT 'Delete Agent Job';
		IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name) EXEC msdb.dbo.sp_delete_job @job_name = @job_name;

		PRINT 'Delete mail profiles';
		DECLARE @profile_name	nvarchar(4000)	=[tdq].[alpha_BoxText]('MailProfileName')
		DECLARE @profile_id		int				=(SELECT TOP 1 profile_id FROM msdb.dbo.sysmail_profile WHERE name = @profile_name);
		IF @profile_id IS NOT NULL EXEC msdb.dbo.sysmail_delete_profile_sp @profile_id = @profile_id, @force_delete = 1;
		DECLARE @account_id int =(SELECT TOP 1 account_id FROM msdb.dbo.sysmail_account WHERE name = @profile_name);
		IF @account_id IS NOT NULL EXEC msdb.dbo.sysmail_delete_account_sp @account_id = @account_id;

	END TRY
	BEGIN CATCH
		INSERT [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, ERROR_MESSAGE());
	END CATCH;

	CLOSE ObjectList;
	DEALLOCATE ObjectList;
END;
GO
--EXEC [tdq].[alpha_Teardown] @PackFirst = 0, @Confirm = 1;

--select OBJECT_ID('[tdq].[alpha_Teardown]')
--print OBJECT_DEFINITION(1918629878);
--print TYPE)

/*
FN	FUNCTION
IF	FUNCTION
SQ	QUEUE
U 	TABLE
FS	FUNCTION
V 	VIEW
AF	FUNCTION
P 	PROC
*/