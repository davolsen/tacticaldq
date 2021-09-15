CREATE OR ALTER FUNCTION [tdq].[alpha_RefreshMergeStatement]
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<object><sequence>10</sequence></object>*/
(
	@TempCaseTableName		nvarchar(4000)
	,@MeasureID				uniqueidentifier
	,@RefreshID			int
)
RETURNS nvarchar(4000)
AS
BEGIN
	DECLARE @SQL AS nvarchar(4000)


	DECLARE
		@TempCaseTableObjectID	int				=OBJECT_ID('tempdb..'+@TempCaseTableName)
		,@InsertColumns			nvarchar(4000)
		,@SelectColumns			nvarchar(4000)
		,@MaxColumns			int				=9;
					
	WITH
		ColumnList AS (
			SELECT
				[name]
				,column_id
				,user_type_id
				,ColumnCount	=COUNT(*) OVER (PARTITION BY object_id)
			FROM tempdb.sys.columns
			WHERE [object_id] = @TempCaseTableObjectID
		)
		,Statements AS (
			SELECT
				InsertColumns	=CAST('CaseValue1' AS nvarchar(4000))
				,SelectColumns	='['+CAST(name AS nvarchar(4000))+']'
				,column_id
				,NextID			=column_id + 1
			FROM ColumnList
			WHERE column_id = 1

			UNION ALL SELECT
				Statements.InsertColumns
					+ CASE
						WHEN ColumnList.column_id <= @MaxColumns THEN
							',CaseValue'
							+CAST(ColumnList.column_id AS nvarchar)
						WHEN ColumnList.column_id = @MaxColumns + 1 THEN ',CaseValuesExtended'
						ELSE ''
					END
				,Statements.SelectColumns
					+CASE WHEN ColumnList.column_id > @MaxColumns THEN
						+IIF(ColumnList.column_id = @MaxColumns + 1,',CONCAT(',',')
						+''''
						+IIF(ColumnList.column_id > @MaxColumns + 1,';','')
						+IIF(ColumnList.column_id > @MaxColumns,name + '=','')
						+''''
							ELSE '' END
					+','
					+IIF(TYPE_NAME(user_type_id) IN ('sql_variant','xml','hierarchyid','geometry','geography'),'CAST([','')
					+'['+IIF(TYPE_NAME(user_type_id) NOT IN ('image', 'timestamp'),name,'CANNOT CONVERT IMAGE OR TIMESTAMP')+']'
					+IIF(TYPE_NAME(user_type_id) IN ('sql_variant','xml','hierarchyid','geometry','geography'),'] AS nvarchar(4000))','')
					+IIF(ColumnList.column_id > @MaxColumns AND ColumnList.column_id = ColumnList.ColumnCount,')','')
				,ColumnList.column_id
				,ColumnList.column_id + 1
			FROM
				Statements
				JOIN ColumnList ON ColumnList.column_id = Statements.NextID
		)
	SELECT
		@InsertColumns	=InsertColumns
		,@SelectColumns	=SelectColumns
	FROM Statements
	WHERE column_id = (SELECT MAX(column_id) FROM Statements);

	SET @SQL = '
		WITH NewCases AS (
			SELECT
				BINARY_CHECKSUM(*) CaseChecksum
				,*
			FROM '+@TempCaseTableName+')
		MERGE [tdq].[alpha_Cases] CurrentCases
		USING NewCases ON NewCases.CaseChecksum = CurrentCases.CaseChecksum AND EXISTS(SELECT 1 FROM [tdq].[alpha_Refreshes] WHERE RefreshID = CurrentCases.RefreshID AND MeasureID = '''+CAST(@MeasureID AS nvarchar(36))+''')
		WHEN NOT MATCHED THEN INSERT (RefreshID,CaseChecksum,'+@InsertColumns+') VALUES ('+CAST(@RefreshID AS nvarchar)+',CaseChecksum,'+@SelectColumns+')
		WHEN NOT MATCHED BY SOURCE AND EXISTS(SELECT 1 FROM [tdq].[alpha_Refreshes] WHERE RefreshID = CurrentCases.RefreshID AND MeasureID = '''+CAST(@MeasureID AS nvarchar(36))+''') THEN DELETE;
	'
	RETURN @SQL;
END;
GO
IF OBJECT_ID('tempdb..##test') IS NOT NULL DROP TABLE ##test;
SELECT TOP 1 * INTO ##test FROM WorldWideImporters.sales.Invoices;
PRINT [tdq].[alpha_RefreshMergeStatement]('##test',NEWID(),1337);
--IF OBJECT_ID('tempdb..##test') IS NOT NULL DROP TABLE ##test;