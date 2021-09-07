CREATE OR ALTER PROCEDURE [tdq].[alpha_Unpack] AS BEGIN
	/*<object><sequence>0</sequence></object>*/
	DECLARE
		@Prefix					nvarchar(128)	= LEFT(OBJECT_NAME(@@PROCID),CHARINDEX('Unpack',OBJECT_NAME(@@PROCID)) - 1)	--the prefix of this proc
		,@SchemaName			nvarchar(128)	= OBJECT_SCHEMA_NAME(@@PROCID)												--the schema for this proc
		,@SchemaToken			nvarchar(128)	='[/$schema/$]'																--to be replaced with schema. /$ MUST BE PRESERVED so it is not replaced during installation of this code
		,@PrefixToken			nvarchar(128)	='[/$prefix/$'																--to be replaced with schema. /$ MUST BE PRESERVED so it is not replaced during installation of this code
		,@SQL					nvarchar(4000);																				--holds dynamic SQL
	DECLARE @BoxTableName		nvarchar(128)	='[' + @SchemaName + '].[' + @Prefix + 'box]';
	DECLARE @CodeObjects		TABLE(
		ObjectName		nvarchar(128)
		,ObjectSequence	tinyint
		,DefinitionBinary	varbinary(8000)
	); -- will hold the object definition for the Unpack procedure
	
	IF OBJECT_ID(@BoxTableName) IS NULL THROW 50000, 'Box table does not exist.', 1;
	ELSE BEGIN
		BEGIN TRY	
			-- update the box with the schema and prefix
			SET @SQL ='
				MERGE INTO ' + @BoxTableName + ' AS Target
				USING (VALUES (''HomeSchema'', ''CONF'', ''' + @SchemaName + '''), (''HomePrefix'', ''CONF'', ''' + @Prefix + ''')) AS Source (ObjectName, ObjectType, DefinitionText)
				ON Target.ObjectName = Source.ObjectName
				WHEN MATCHED THEN
				UPDATE SET DefinitionText = Source.DefinitionText
				WHEN NOT MATCHED BY TARGET THEN
				INSERT (ObjectName, ObjectType, DefinitionText) VALUES (ObjectName, ObjectType, DefinitionText);';
			EXEC (@SQL);
			--Get tables, Views, stored procs, functions, except this one.
			SET @SQL = 'SELECT ObjectName, ObjectSequence, DefinitionBinary FROM ' + @BoxTableName + ' WHERE ObjectType IN (''TABL'',''CODE'',''MESR'') AND ObjectSequence > 0';
			INSERT INTO @CodeObjects(ObjectName, ObjectSequence, DefinitionBinary)
			EXEC (@SQL);
			IF @@ROWCOUNT = 0 THROW 50002, 'No objects were found in the box table.', 1;
			--Loop through the list and create the objects
			DECLARE
				@ObjectName		nvarchar(128)
				,@BinaryObject	varbinary(8000);
			DECLARE BuildCursor CURSOR FAST_FORWARD FOR SELECT ObjectName, DefinitionBinary FROM @CodeObjects ORDER BY ObjectSequence;
			OPEN BuildCursor;
			FETCH NEXT FROM BuildCursor INTO @ObjectName, @BinaryObject;
			WHILE @@FETCH_STATUS = 0 BEGIN
				PRINT 'Unpacking '+@ObjectName;
				SET @SQL = CAST(DECOMPRESS(@BinaryObject) AS nvarchar(4000))
				SET @SQL = REPLACE(REPLACE(@SQL, REPLACE(@SchemaToken,'/$','$'), '['+@SchemaName+']'), REPLACE(@PrefixToken,'/$','$'), '['+@Prefix); -- replace the schema and prefix

				EXEC (@SQL); -- create the object
				IF SUBSTRING(@SQL,CHARINDEX('<autoExecute>',@SQL)+13,4) = 'true' BEGIN--Auto Execute
					SET @SQL = 'EXEC ['+@SchemaName+'].['+@Prefix+@ObjectName+']'
					EXEC (@SQL);
				END;
				
				FETCH NEXT FROM BuildCursor INTO @ObjectName, @BinaryObject;
			END;
			CLOSE BuildCursor;
			DEALLOCATE BuildCursor;
		END TRY
		BEGIN CATCH
			PRINT @SQL;
			THROW;
		END CATCH;
	END;
END;


