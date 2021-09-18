CREATE OR ALTER VIEW [tdq].[alpha_ScheduleCurrent] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>42</Sequence></Object>*/
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
		,TRY_CAST(Job.value('(/Refresh/ObjectName/text())[1]', 'nvarchar(128)') AS nvarchar(128))	ObjectName
		,TRY_CAST(Job.value('(/Refresh/Code/text())[1]', 'nvarchar(100)') AS nvarchar(50))			MeasureCode
		,TRY_CAST(Job.value('(/Refresh/ID/text())[1]', 'nchar(36)') AS uniqueidentifier)		MeasureID
	FROM RefreshesPending;
GO
SELECT * FROM [tdq].[alpha_ScheduleCurrent];