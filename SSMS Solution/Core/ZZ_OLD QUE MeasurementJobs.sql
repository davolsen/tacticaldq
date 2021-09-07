DECLARE
	@SQL						nvarchar(4000)--dynamic SQL
	,@MaxParallelMeasurements	int				= [tdq].[alpha_BoxDec]('MaxParallelMeasurements')--MAX_QUEUE_READERS
	,@ServiceName				nvarchar(4000)	= '[alpha_TDQScheduler]';--this needed because square brackets are required as part of deployment scripting
--if they exist, drop service, then queue
IF EXISTS(SELECT TOP 1 1 FROM sys.services WHERE Name = REPLACE(REPLACE(@ServiceName,'[',''),']','')) DROP SERVICE [alpha_TDQScheduler]
IF OBJECT_ID('[tdq].[alpha_MeasurementJobs]') IS NOT NULL DROP QUEUE [tdq].[alpha_MeasurementJobs];
--create queue dynamic SQL with MaxParallelMeasurements parameter
SET @SQL = '
	CREATE QUEUE [tdq].[alpha_MeasurementJobs] WITH RETENTION = OFF, STATUS = ON, ACTIVATION (
		PROCEDURE_NAME = [tdq].[alpha_MeasurementStartJob]
		,MAX_QUEUE_READERS = ' + CAST(@MaxParallelMeasurements AS nvarchar) + '
		,EXECUTE AS OWNER
	);';
--create queue
EXEC (@SQL);
--create service
CREATE SERVICE [alpha_TDQScheduler] AUTHORIZATION dbo ON QUEUE [tdq].[alpha_MeasurementJobs]([DEFAULT]);