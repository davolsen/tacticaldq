CREATE OR ALTER VIEW [tdq].[alpha_ScheduleCurrent] AS
/*<object><sequence>42</sequence></object>*/
	WITH
		MeasurementJobs AS (
			SELECT
				queuing_order
				,CAST(message_body AS xml) AS Job
				,[status]
			FROM [tdq].[alpha_MeasurementJobs]
			WHERE message_type_name = 'DEFAULT'
	)
	SELECT
		*
		,TRY_CAST(Job.value('(/measurement/ObjectName/text())[1]', 'nvarchar(128)') AS nvarchar(128))	ObjectName
		,TRY_CAST(Job.value('(/measurement/code/text())[1]', 'nvarchar(128)') AS nvarchar(50))			MeasureCode
		,TRY_CAST(Job.value('(/measurement/id/text())[1]', 'nvarchar(128)') AS uniqueidentifier)		MeasureID
	FROM MeasurementJobs;
GO
SELECT * FROM [tdq].[alpha_ScheduleCurrent];