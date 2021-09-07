CREATE OR ALTER PROCEDURE [tdq].[alpha_Teardown](
	@PackFirst	bit	=1
	,@Confirm	bit	=0
) AS BEGIN
	/*<object><sequence>1</sequence></object>*/
	IF @Confirm		=0 THROW 50000, 'The confirm parameter must be set to 1', 1
	IF @PackFirst	=1 EXEC [tdq].[alpha_Pack]
	
	BEGIN TRY	
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
			EXEC @SQL;
			FETCH NEXT FROM ObjectList INTO @ObjectName, @ObjectType;
		END;

		PRINT 'Drop Agent Job';
		DECLARE @job_name nvarchar(4000) = [tdq].[alpha_BoxText]('AgentJobName');
		IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name) EXEC msdb.dbo.sp_delete_job @job_name = @job_name;

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