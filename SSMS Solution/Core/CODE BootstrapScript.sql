CREATE OR ALTER PROCEDURE [tdq].[alpha_BootstrapScript] AS BEGIN
/*<object><sequence>101</sequence></object>*/
	SET NOCOUNT ON;
	--Bootstrap script
	PRINT '/*';
	PRINT REPLACE([tdq].[alpha_BoxText]('License'),'\n',CHAR(13)+CHAR(10));
	PRINT '*/';
	PRINT '--Execute on Microsoft SQL Server 2016 or later, with sysadmin priviledges';
	PRINT 'DECLARE';
	PRINT '	@SchemaName AS nvarchar(128) = ''tdq'' -- All objects will be created in this schema';
	PRINT '	,@Prefix AS nvarchar(128) = ''''; -- All objects will be prefixed with this in their name';
	PRINT '';
	PRINT '';
	PRINT 'SET NOCOUNT ON;';
	PRINT 'DECLARE @SQL AS nvarchar(4000);';
	PRINT 'SET @SQL = ''SELECT OBJECT_ID(''''['' + @SchemaName + ''].['' + @Prefix + ''Box]'''')'';';
	PRINT 'DECLARE @ObjectIDTable AS TABLE(ObjectID int);';
	PRINT 'INSERT INTO @ObjectIDTable';
	PRINT 'EXEC (@SQL);';
	PRINT 'IF (SELECT TOP 1 ObjectID FROM @ObjectIDTable) IS NOT NULL THROW 50000, ''Box table already exists. Did you already run bootstrap? You can execute the unpack procedure, or drop the Box table, or change schema or prefix'', 1';
	PRINT 'IF OBJECT_ID(''tempdb..#BoxTable'') IS NOT NULL DROP TABLE #BoxTable'
	PRINT 'SELECT ObjectName,ObjectType,ObjectSequence,CAST('''' AS xml).value(''xs:base64Binary(sql:column("DefinitionBinary"))'',''varbinary(max)'')DefinitionBinary,DefinitionText,DefinitionDecimal,DefinitionDate,DefinitionBit INTO #BoxTable FROM (VALUES';
	DECLARE
		@RowCount		int				=0
		,@ObjectName	nvarchar(128)
		,@Output		nvarchar(4000);
	DECLARE BoxRows		CURSOR FAST_FORWARD FOR SELECT ObjectName FROM [tdq].[alpha_Box] ORDER BY CASE ObjectType WHEN 'CONF' THEN 1 WHEN 'TABL' THEN 2 WHEN 'CODE' THEN 3 WHEN 'MSR' THEN 4 ELSE 9 END, ObjectName;
	OPEN BoxRows;
	FETCH NEXT FROM BoxRows INTO @ObjectName;
	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @RowCount	=@RowCount+1
		SET @Output		=(
			SELECT TOP 1
				IIF(@RowCount > 1,',','')
				+'(N'''+ObjectName+''''
				+','''+ObjectType+''''
				+','+CAST(ObjectSequence AS varchar(3))
				+','+ISNULL(NULLIF(''''+(SELECT TOP 1 * FROM (SELECT DefinitionBinary AS '*' FROM [tdq].[alpha_Box] WHERE ObjectName =@ObjectName) X FOR XML PATH(''))+'''',''''''),'NULL')
				+','+ISNULL('N'''+DefinitionText+'''','NULL')
				+','+ISNULL(CAST(DefinitionDecimal AS varchar(19)),'NULL')
				+','
					+IIF(@RowCount = 1,'CAST(','')
					+ISNULL(''''+CAST(DefinitionDate AS varchar(38))+'''','NULL')
					+IIF(@RowCount = 1,' AS datetimeoffset)','')
				+','
					+IIF(@RowCount = 1,'CAST(','')
					+ISNULL(''''+CAST(DefinitionBit AS varchar(3))+'''','NULL')
					+IIF(@RowCount = 1,' AS bit)','')
				+')'
			FROM [tdq].[alpha_Box]
			WHERE ObjectName = @ObjectName
		);
		PRINT @Output;
		FETCH NEXT FROM BoxRows INTO @ObjectName;
	END;
	CLOSE		BoxRows;
	DEALLOCATE	BoxRows;
	PRINT ')Box(ObjectName,ObjectType,ObjectSequence,DefinitionBinary,DefinitionText,DefinitionDecimal,DefinitionDate,DefinitionBit)';
	PRINT 'SET @SQL =REPLACE(REPLACE((SELECT CAST(DECOMPRESS(DefinitionBinary) AS nvarchar(4000)) FROM #BoxTable WHERE ObjectName = ''Box''),''[$schema$]'',''[''+@SchemaName+'']''),''[$prefix$'',''[''+@Prefix);';
	PRINT 'EXEC (@SQL);';
	PRINT 'SET @SQL =''INSERT INTO [''+@SchemaName+''].[''+@Prefix+''Box] SELECT ObjectName,ObjectType,ObjectSequence,DefinitionBinary,DefinitionText,DefinitionDecimal,DefinitionDate,DefinitionBit FROM #BoxTable'';';
	PRINT 'EXEC (@SQL);';
	PRINT 'SET @SQL =REPLACE(REPLACE((SELECT CAST(DECOMPRESS(DefinitionBinary) AS nvarchar(4000)) FROM #BoxTable WHERE ObjectName = ''Unpack''),''[$schema$]'',''[''+@SchemaName+'']''),''[$prefix$'',''[''+@Prefix);';
	PRINT 'SET @SQL =REPLACE(REPLACE(@SQL,''[/$schema/$]'',''[$schema$]''),''[/$prefix/$'',''[$prefix$'');';
	PRINT 'EXEC (@SQL);';
	PRINT 'SET @SQL =''EXEC [''+@SchemaName+''].[''+@Prefix+''Unpack]''';
	PRINT 'EXEC (@SQL);';
	PRINT 'IF OBJECT_ID(''tempdb..#BoxTable'') IS NOT NULL DROP TABLE #BoxTable;';
END;
GO
EXEC [tdq].[alpha_BootstrapScript];