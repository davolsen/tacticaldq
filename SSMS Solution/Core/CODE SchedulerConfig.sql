CREATE OR ALTER PROC [tdq].[alpha_SchedulerConfig](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>40</sequence><autoExecute>true</autoExecute></object>*/
	@CheckOnly bit = 0--Don't make changes, only check.
) AS BEGIN
	DECLARE	@ReturnValue int = 0;--bitwise: 0=All good;1=service broker disabled;2=Service missing;4=Queue missing;8=Agent job missing
	--Enable the service broker if it isn't enabled
	IF (SELECT TOP 1 is_broker_enabled FROM sys.databases WHERE name = DB_NAME()) = 0 BEGIN
		SET @ReturnValue = @ReturnValue + 1;
		IF @CheckOnly = 0 BEGIN
			PRINT 'Enabling Service Broker';
			ALTER DATABASE CURRENT 
			SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
		END;
	END;
	ELSE PRINT 'Service Broker already enabled';

	DECLARE
		@SQL						nvarchar(4000)--dynamic SQL
		,@SchedulerMaxParallelRefreshes	int				= [tdq].[alpha_BoxDec]('SchedulerMaxParallelRefreshes')--MAX_QUEUE_READERS
		,@ServiceName				nvarchar(4000)	= '[alpha_Scheduler]';--needed for bootstrap/unpack script

	IF EXISTS(SELECT 1 FROM sys.services WHERE Name = REPLACE(REPLACE(@ServiceName,'[',''),']','')) BEGIN
		PRINT 'Service Broker service already exists';
		IF @CheckOnly = 0 DROP SERVICE [alpha_Scheduler]
	END;
	ELSE SET @ReturnValue = @ReturnValue + 2;
	IF OBJECT_ID('[tdq].[alpha_RefreshesPending]') IS NOT NULL BEGIN
		PRINT 'Service Broker queue already exists';
		IF @CheckOnly = 0 DROP QUEUE [tdq].[alpha_RefreshesPending]
	END;
	ELSE SET @ReturnValue = @ReturnValue + 4;

	IF @CheckOnly = 0 BEGIN
		SET @SQL = '
			CREATE QUEUE [tdq].[alpha_RefreshesPending] WITH RETENTION = OFF, STATUS = ON, ACTIVATION (
				PROCEDURE_NAME = [tdq].[alpha_RefreshFromQueue]
				,MAX_QUEUE_READERS = ' + CAST(@SchedulerMaxParallelRefreshes AS nvarchar) + '
				,EXECUTE AS OWNER
			);';

		PRINT 'Creating queue';
		EXEC (@SQL);

		PRINT 'Creating service';
		SET @SQL = 'CREATE SERVICE '+@ServiceName+' AUTHORIZATION dbo ON QUEUE [tdq].[alpha_RefreshesPending]([DEFAULT]);';
		EXEC (@SQL);
	END;
	RETURN @ReturnValue;
END;
GO
--EXEC [tdq].[alpha_Config];
DECLARE @ReturnCode int;
EXEC @ReturnCode = [tdq].[alpha_SchedulerConfig] @CheckOnly = 0;
PRINT @ReturnCode;