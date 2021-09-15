CREATE OR ALTER VIEW [tdq].[alpha_ScheduleCurrent] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>42</sequence></object>*/
	WITH
		RefreshesPending AS (
			SELECT
				queuing_order
				,CAST(message_body AS xml) AS Job
				,[status]
			FROM [tdq].[alpha_RefreshesPending]
			WHERE message_type_name = 'DEFAULT'
	)
	SELECT
		*
		,TRY_CAST(Job.value('(/refresh/ObjectName/text())[1]', 'nvarchar(128)') AS nvarchar(128))	ObjectName
		,TRY_CAST(Job.value('(/refresh/code/text())[1]', 'nvarchar(128)') AS nvarchar(50))			MeasureCode
		,TRY_CAST(Job.value('(/refresh/id/text())[1]', 'nvarchar(128)') AS uniqueidentifier)		MeasureID
	FROM RefreshesPending;
GO
SELECT * FROM [tdq].[alpha_ScheduleCurrent];