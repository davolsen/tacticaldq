CREATE OR ALTER PROCEDURE [tdq].[alpha_Pack] AS BEGIN
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>102</sequence></object>*/
	SET NOCOUNT ON;
	BEGIN TRAN
		BEGIN TRY
			PRINT 'Get object definitions';
			WITH Definitions AS (
				SELECT
					ObjectName		=SUBSTRING(OBJECT_NAME(sql_modules.object_id),LEN([tdq].[alpha_BoxText]('HomePrefix')) + 1,128)
					,DefinitionText	=REPLACE(REPLACE(definition,'['+[tdq].[alpha_BoxText]('HomeSchema')+']','[$schema$]'),'['+[tdq].[alpha_BoxText]('HomePrefix'),'[$prefix$')
					,ObjectType		=IIF(OBJECT_NAME(sql_modules.object_id) LIKE [tdq].[alpha_BoxText]('HomePrefix')
						+'%'
						+[tdq].[alpha_BoxText]('MeasureViewPattern'),'MESR','CODE')
				FROM
					sys.sql_modules
					JOIN sys.all_objects ON all_objects.object_id = sql_modules.object_id
				WHERE
					SCHEMA_NAME(all_objects.schema_id) = [tdq].[alpha_BoxText]('HomeSchema')
					AND OBJECT_NAME(sql_modules.object_id) LIKE [tdq].[alpha_BoxText]('HomePrefix')+'%'
			)
			SELECT
				*
				,MetaStart		=CHARINDEX('<object>',DefinitionText,1)
				,MetaEnd		=CHARINDEX('</object>',DefinitionText,1) + 10
			INTO #Definitions
			FROM Definitions;

			PRINT 'Check object definition lengths';
			IF (SELECT MAX(LEN(DefinitionText)) FROM #Definitions) > 4000 BEGIN
				DECLARE @ErrorMessage nvarchar(2048) = 'FATAL: definition too long (>4000 characters): ''' + (SELECT STRING_AGG(ObjectName+' ('+CAST(LEN(DefinitionText) AS nvarchar)+')', ''' and ''') FROM #Definitions WHERE LEN(DefinitionText) > 4000) + '''';
				THROW 50000, @ErrorMessage, 1;
			END;
			PRINT 'Delete old definitions from box then add new ones';
			DELETE FROM [tdq].[alpha_Box] WHERE ObjectType IN ('CODE','MESR');
			INSERT INTO [tdq].[alpha_Box](ObjectName, ObjectType, ObjectSequence, DefinitionBinary)
			SELECT
				ObjectName
				,ObjectType
				,ISNULL(NULLIF(TRY_CAST(XMLData.query('/object/sequence/text()') AS nvarchar(10)),''), 200) ObjectSequence
				,DefinitionBinary
			FROM (
				SELECT
					ObjectName
					,ObjectType
					,XMLData		=IIF(MetaStart > 0, TRY_CAST(SUBSTRING(DefinitionText,MetaStart,MetaEnd - MetaStart) AS xml), NULL)
					,DefinitionBinary	=COMPRESS(DefinitionText)
				FROM #Definitions
			) MetaData;
			PRINT 'Delete old table from box then add new ones';
			DELETE FROM [tdq].[alpha_Box] WHERE ObjectType = 'TABL';
			INSERT INTO [tdq].[alpha_Box](ObjectName, ObjectType, ObjectSequence, DefinitionBinary)
			SELECT
				SUBSTRING(TableName,LEN([tdq].[alpha_BoxText]('HomePrefix')) + 1,128)
				,'TABL'
				,IIF(RIGHT(TableName,3) = 'Box',0,1)
				,COMPRESS(REPLACE(REPLACE(TableDefinition,'['+[tdq].[alpha_BoxText]('HomeSchema')+']','[$schema$]'),'['+[tdq].[alpha_BoxText]('HomePrefix'),'[$prefix$'))
			FROM [tdq].[alpha_PackTableDefinitions];--view had to be split off for file size limitation
			
			PRINT 'Commit';
			COMMIT;

			PRINT 'Generate bootstrap script'+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+REPLICATE('-',100)+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);
			EXEC [tdq].[alpha_GenerateBootstrapScript];
			PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+REPLICATE('-',100) ;
		END TRY
		BEGIN CATCH
			PRINT 'Fatal erorr, rollback';
			IF @@TRANCOUNT > 0 ROLLBACK;
			THROW;
		END CATCH;
	PRINT 'Done.'
END;
GO
EXEC [tdq].[alpha_Pack];
