CREATE OR ALTER VIEW [tdq].[alpha_PackTableDefinitions] AS
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>100</sequence></object>*/
SELECT
	TableName			=tables.name
	,TableDefinition	='CREATE TABLE ['+SCHEMA_NAME(tables.schema_id)+'].['+tables.name+']('
			+(
				SELECT STRING_AGG(
					all_columns.name
					+' '+CASE
						WHEN computed_columns.definition IS NULL THEN
							+TYPE_NAME(all_columns.user_type_id)
							+CASE TYPE_NAME(all_columns.user_type_id)
								WHEN 'nvarchar'			THEN '('+CAST(all_columns.max_length/2 AS nvarchar(4000))+')'
								WHEN 'varbinary'		THEN '('+CAST(all_columns.max_length AS nvarchar(4000))+')'
								WHEN 'char'				THEN '('+CAST(all_columns.max_length AS nvarchar(4000))+')'
								WHEN 'datetime2'		THEN '('+CAST(all_columns.scale AS nvarchar(4000))+')'
								WHEN 'datetimeoffset'	THEN '('+CAST(all_columns.scale AS nvarchar(4000))+')'
								WHEN 'decimal'			THEN '('+CAST(all_columns.precision AS nvarchar(4000))+','+CAST(all_columns.scale AS nvarchar(4000))+')'
								ELSE '' END
						ELSE 'AS '+computed_columns.definition END
					+ISNULL(' IDENTITY('+CAST(seed_value AS nvarchar(4000))+','+CAST(increment_value AS nvarchar(4000))+')','')
					+ISNULL(' GENERATED ALWAYS AS ROW '+CHOOSE(all_columns.generated_always_type,'START','END'),'')
					+IIF(all_columns.is_nullable = 0,' NOT NULL','')
					+ISNULL(' DEFAULT '+default_constraints.definition,'')
					+IIF(index_columns.object_id IS NOT NULL,' PRIMARY KEY','')
						,',')
				FROM
					sys.all_columns
					LEFT JOIN sys.computed_columns ON
						computed_columns.object_id = all_columns.object_id
						AND computed_columns.column_id = all_columns.column_id
					LEFT JOIN sys.identity_columns ON
						identity_columns.object_id = all_columns.object_id
						AND identity_columns.column_id = all_columns.column_id
					LEFT JOIN sys.default_constraints ON
						default_constraints.parent_object_id = all_columns.object_id
						AND default_constraints.parent_column_id = all_columns.column_id
					LEFT JOIN sys.index_columns
							JOIN sys.indexes ON
								indexes.object_id = index_columns.object_id
								AND indexes.index_id = index_columns.index_id
								AND indexes.is_primary_key = 1
						ON
							index_columns.object_id = all_columns.object_id
							AND index_columns.column_id = all_columns.column_id
				WHERE all_columns.object_id = tables.object_id
			)
			+ISNULL(', '+IndexStatement, '')
			+ISNULL((
				SELECT TOP 1 ',PERIOD FOR '+name+'(['+COL_NAME(object_id,start_column_id)+'],['+COL_NAME(object_id,end_column_id)+'])'
				FROM sys.periods 
				WHERE object_id = tables.object_id
			),'')
			+')'
			+ISNULL((
				SELECT TOP 1 'WITH(SYSTEM_VERSIONING=ON(HISTORY_TABLE=['+OBJECT_SCHEMA_NAME(history_table_id)+'].['+OBJECT_NAME(history_table_id)+']))'
				FROM sys.tables X
				WHERE X.object_id = tables.object_id AND temporal_type = 2
			),'')
FROM
	sys.tables
	LEFT JOIN (
			SELECT object_id, STRING_AGG(IndexStatement, ', ') IndexStatement
			FROM (
					SELECT
						indexes.object_id
						,'INDEX'
							+' ['+indexes.name+']'
							+' ('+(
								SELECT STRING_AGG('['+all_columns.name+'] '+IIF(index_columns.is_descending_key = 1,'DESC','ASC'),', ')
								FROM
									sys.index_columns
									JOIN sys.all_columns ON
										all_columns.object_id		=indexes.object_id
										AND all_columns.column_id	=index_columns.column_id
								WHERE
									index_columns.object_id		=indexes.object_id
									AND index_columns.index_id	=indexes.index_id
							)+')' IndexStatement
					FROM sys.indexes
					WHERE indexes.type = 2
				) Y
			GROUP BY object_id
		) AS IndexStatement ON IndexStatement.object_id = tables.object_id

WHERE
	SCHEMA_NAME(schema_id) = [tdq].[alpha_BoxText]('HomeSchema')
	AND name LIKE [tdq].[alpha_BoxText]('HomePrefix')+'%'
	AND temporal_type <> 1;
GO
SELECT * FROM [tdq].[alpha_PackTableDefinitions];

--SELECT 'WITH(SYSTEM_VERSIONING=ON( HISTORY_TABLE = ['+OBJECT_SCHEMA_NAME(history_table_id)+'].['+OBJECT_NAME(history_table_id)+']))'
--FROM sys.tables 
--WHERE object_id = 1086626914 AND temporal_type = 2

--select OBJECT_SCHEMA_NAME(1086626914)

--select * from sys.tempor

--'SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [tdq].[alpha_CasesResolved] )'