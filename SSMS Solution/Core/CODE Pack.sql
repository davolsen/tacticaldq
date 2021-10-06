CREATE OR ALTER PROCEDURE [tdq].[alpha_Pack](
	@GenerateBootstrapScript int = 1
) AS BEGIN
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>102</Sequence></Object>*/
	SET NOCOUNT ON;
	BEGIN TRAN
		BEGIN TRY
			PRINT 'Get object definitions';
			IF OBJECT_ID('tempdb..#Definitions') IS NOT NULL DROP TABLE #Definitions;
			WITH Definitions AS (
				SELECT
					ObjectName		=SUBSTRING(OBJECT_NAME(object_id),LEN([tdq].[alpha_BoxText]('HomePrefix')) + 1,128)
					,DefinitionText	=REPLACE(REPLACE(definition,'['+[tdq].[alpha_BoxText]('HomeSchema')+']','[$schema$]'),'['+[tdq].[alpha_BoxText]('HomePrefix'),'[$prefix$')
					,ObjectType		=IIF(OBJECT_NAME(object_id) LIKE [tdq].[alpha_BoxText]('HomePrefix')
										+'%'
										+[tdq].[alpha_BoxText]('MeasureViewPattern'),'MESR','CODE')
				FROM sys.sql_modules
				WHERE
					OBJECT_SCHEMA_NAME(object_id) = [tdq].[alpha_BoxText]('HomeSchema')
					AND OBJECT_NAME(object_id) LIKE [tdq].[alpha_BoxText]('HomePrefix')+'%'
			)
			SELECT
				*
				,ObjectSequence		=CAST(NULL AS tinyint)
				,MetaStart			=CHARINDEX('<Object>',DefinitionText,1)
				,MetaEnd			=CHARINDEX('</Object>',DefinitionText,1) + 10
				,DefinitionBinary	=COMPRESS(DefinitionText)
			INTO #Definitions
			FROM Definitions;
			
			PRINT 'Get table definitions';
			INSERT INTO #Definitions(ObjectName, ObjectType, ObjectSequence, DefinitionBinary)
			SELECT
				ObjectName			=SUBSTRING(TableName,LEN([tdq].[alpha_BoxText]('HomePrefix')) + 1,128)
				,ObjectType			='TABL'
				,ObjectSequence		=IIF(RIGHT(TableName,3) = 'Box',0,1)
				,DefinitionBinary	=COMPRESS(REPLACE(REPLACE(TableDefinition,'['+[tdq].[alpha_BoxText]('HomeSchema')+']','[$schema$]'),'['+[tdq].[alpha_BoxText]('HomePrefix'),'[$prefix$'))
			FROM [tdq].[alpha_PackTableDefinitions];--view had to be split off for file size limitation

			PRINT 'Check object definition lengths';
			IF (SELECT MAX(LEN(DefinitionBinary)) FROM #Definitions) > 4000 BEGIN
				DECLARE @ErrorMessage nvarchar(2048) = 'FATAL: compressed definition too long (>4000 bytes): ''' + (SELECT STRING_AGG(ObjectName+' ('+CAST(LEN(DefinitionText) AS nvarchar)+')', ''' and ''') FROM #Definitions WHERE LEN(DefinitionBinary) > 4000) + '''';
				THROW 50000, @ErrorMessage, 1;
			END;

			PRINT 'Delete old definitions from box then add new ones';
			DELETE FROM [tdq].[alpha_Box] WHERE ObjectType IN ('CODE','MESR', 'TABL');
			INSERT INTO [tdq].[alpha_Box](ObjectName, ObjectType, ObjectSequence, DefinitionBinary)
			SELECT
				ObjectName
				,ObjectType
				,ObjectSequence = COALESCE(ObjectSequence, TRY_CAST(XMLData.value('(/Object/Sequence/text())[1]','varchar(3)') AS tinyint), 200)
				,DefinitionBinary
			FROM (
				SELECT
					ObjectName
					,ObjectType
					,ObjectSequence
					,XMLData			=IIF(MetaStart > 0, TRY_CAST(SUBSTRING(DefinitionText,MetaStart,MetaEnd - MetaStart) AS xml), NULL)
					,DefinitionBinary
				FROM #Definitions
			) MetaData;
			
			PRINT 'Commit';
			COMMIT;

			PRINT 'Generate bootstrap script'+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+REPLICATE('-',100)+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);
			IF @GenerateBootstrapScript = 1 EXEC [tdq].[alpha_GenerateBootstrapScript];
			PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+REPLICATE('-',100) ;
		END TRY
		BEGIN CATCH
			PRINT 'Fatal erorr, rollback';
			IF @@TRANCOUNT > 0 ROLLBACK;
			THROW;
		END CATCH;
	IF OBJECT_ID('tempdb..#Definitions') IS NOT NULL DROP TABLE #Definitions;
	PRINT 'Done.'
END;
GO
EXEC [tdq].[alpha_Pack];
