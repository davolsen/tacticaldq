CREATE OR ALTER FUNCTION [tdq].[alpha_CasesMergeStatement]
/*<object><sequence>10</sequence></object>*/
(
	@TempCaseTableName		nvarchar(4000)
	,@MeasureID				uniqueidentifier
	,@MeasurementID			int
)
RETURNS nvarchar(4000)
AS
BEGIN
	DECLARE @SQL AS nvarchar(4000)


	DECLARE
		@TempCaseTableObjectID int =OBJECT_ID('tempdb..'+@TempCaseTableName)
		,@InsertColumns	nvarchar(4000)
		,@SelectColumns	nvarchar(4000)
		,@MaxColumns	int				=9;
					
	WITH
		ColumnList AS (
			SELECT
				InsertColumns	=CAST('CaseProperty'
									+CAST(column_id AS nvarchar(128))
									+N',CaseValue'
									+CAST(column_id AS nvarchar(128))
										AS nvarchar(4000))				
				,SelectColumns	=CAST(N''''
									+name
									+N''' AS CaseProperty'
									+CAST(column_id AS nvarchar(128))
									+N',[' 
									+name
									+N'] AS CaseValue'
									+CAST(column_id AS nvarchar(128))
										AS nvarchar(4000))
				,[name]
				,column_id
				,user_type_id
				,ColumnCount	=COUNT(*) OVER (PARTITION BY object_id)
			FROM tempdb.sys.columns
			WHERE [object_id] = @TempCaseTableObjectID
		)
		,Statements AS (
			SELECT
				InsertColumns	=CAST('CaseProperty1,CaseValue1' AS nvarchar(4000))
				,SelectColumns	=CAST(''''+name+''','+name AS nvarchar(4000))
				,column_id
				,NextID			=column_id + 1
			FROM ColumnList
			WHERE column_id = 1

			UNION ALL SELECT
				Statements.InsertColumns
					+ CASE
						WHEN ColumnList.column_id <= @MaxColumns THEN
							',CaseProperty'
							+CAST(ColumnList.column_id AS nvarchar)
							+',CaseValue'
							+CAST(ColumnList.column_id AS nvarchar)
						WHEN ColumnList.column_id = @MaxColumns + 1 THEN ',CasePropertiesExtended'
						ELSE ''
					END
				,Statements.SelectColumns
					+','
					+IIF(ColumnList.column_id = @MaxColumns + 1,'CONCAT(','')
					+''''+IIF(ColumnList.column_id > @MaxColumns + 1,';','')
					+name
					+IIF(ColumnList.column_id > @MaxColumns,'=','')+''''
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
				'''+CAST(@MeasureID AS nvarchar(36))+''' MeasureID
				,'+CAST(@MeasurementID AS nvarchar)+' MeasurementID
				,BINARY_CHECKSUM(*) CaseChecksum
				,*
			FROM '+@TempCaseTableName+')
		MERGE [tdq].[alpha_Cases] CurrentCases
		USING NewCases ON NewCases.MeasureID = CurrentCases.MeasureID AND NewCases.CaseChecksum = CurrentCases.CaseChecksum
		WHEN NOT MATCHED THEN INSERT (MeasureID,MeasurementID,'+@InsertColumns+',CaseChecksum) VALUES (MeasureID,MeasurementID,'+@SelectColumns+',CaseChecksum)
		WHEN NOT MATCHED BY SOURCE AND MeasureID = '''+CAST(@MeasureID AS nvarchar(36))+''' THEN DELETE;
	'
	RETURN @SQL;
END;
GO
--DECLARE @SQL nvarchar(4000) = 'SELECT * INTO ##Test FROM [tdq].[alpha_measure_CUST-MAST-PAYD]';
--EXEC (@SQL);
--SELECT [tdq].[alpha_CasesMergeStatement]('##Test',NEWID(),1);
----DROP TABLE ##Test;
--     begin tran;

--	      WITH NewCases AS (     SELECT      '65555665-984B-4BDF-993E-332C39430625' MeasureID      ,1 MeasurementID      ,BINARY_CHECKSUM(*) CaseChecksum      ,*     FROM ##Test)    MERGE [tdq].[alpha_Cases] CurrentCases    USING NewCases ON NewCases.MeasureID = CurrentCases.MeasureID AND NewCases.CaseChecksum = CurrentCases.CaseChecksum    WHEN NOT MATCHED THEN INSERT (MeasureID,MeasurementID,CaseProperty1,CaseValue1,CaseProperty2,CaseValue2,CaseProperty3,CaseValue3,CaseProperty4,CaseValue4,CaseProperty5,CaseValue5,CaseProperty6,CaseValue6,CaseProperty7,CaseValue7,CaseProperty8,CaseValue8,CaseProperty9,CaseValue9,CasePropertiesExtended,CaseChecksum) VALUES (MeasureID,MeasurementID,'CustomerID',CustomerID,'CustomerName',CustomerName,'BillToCustomerID',BillToCustomerID,'CustomerCategoryID',CustomerCategoryID,'BuyingGroupID',BuyingGroupID,'PrimaryContactPersonID',PrimaryContactPersonID,'AlternateContactPersonID',AlternateContactPersonID,'DeliveryMethodID',DeliveryMethodID,'DeliveryCityID',DeliveryCityID,CONCAT('PostalCityID=',PostalCityID,';CreditLimit=',CreditLimit,';AccountOpenedDate=',AccountOpenedDate,';StandardDiscountPercentage=',StandardDiscountPercentage,';IsStatementSent=',IsStatementSent,';IsOnCreditHold=',IsOnCreditHold,';PaymentDays=',PaymentDays,';PhoneNumber=',PhoneNumber,';FaxNumber=',FaxNumber,';DeliveryRun=',DeliveryRun,';RunPosition=',RunPosition,';WebsiteURL=',WebsiteURL,';DeliveryAddressLine1=',DeliveryAddressLine1,';DeliveryAddressLine2=',DeliveryAddressLine2,';DeliveryPostalCode=',DeliveryPostalCode,';DeliveryLocation=',CAST([DeliveryLocation] AS nvarchar(4000)),';PostalAddressLine1=',PostalAddressLine1,';PostalAddressLine2=',PostalAddressLine2,';PostalPostalCode=',PostalPostalCode,';LastEditedBy=',LastEditedBy,';ValidFrom=',ValidFrom,';ValidTo=',ValidTo),CaseChecksum)    WHEN NOT MATCHED BY SOURCE THEN DELETE;    
	  
--	  select * from [tdq].[alpha_Cases] where MeasureID = '65555665-984B-4BDF-993E-332C39430625';
--	  select * from [tdq].[alpha_CaseHistory] where MeasureID = '65555665-984B-4BDF-993E-332C39430625';

--	   WITH NewCases AS (     SELECT  TOP 1    '65555665-984B-4BDF-993E-332C39430625' MeasureID      ,1 MeasurementID      ,BINARY_CHECKSUM(*) CaseChecksum      ,*     FROM ##Test)    MERGE [tdq].[alpha_Cases] CurrentCases    USING NewCases ON NewCases.MeasureID = CurrentCases.MeasureID AND NewCases.CaseChecksum = CurrentCases.CaseChecksum    WHEN NOT MATCHED THEN INSERT (MeasureID,MeasurementID,CaseProperty1,CaseValue1,CaseProperty2,CaseValue2,CaseProperty3,CaseValue3,CaseProperty4,CaseValue4,CaseProperty5,CaseValue5,CaseProperty6,CaseValue6,CaseProperty7,CaseValue7,CaseProperty8,CaseValue8,CaseProperty9,CaseValue9,CasePropertiesExtended,CaseChecksum) VALUES (MeasureID,MeasurementID,'CustomerID',CustomerID,'CustomerName',CustomerName,'BillToCustomerID',BillToCustomerID,'CustomerCategoryID',CustomerCategoryID,'BuyingGroupID',BuyingGroupID,'PrimaryContactPersonID',PrimaryContactPersonID,'AlternateContactPersonID',AlternateContactPersonID,'DeliveryMethodID',DeliveryMethodID,'DeliveryCityID',DeliveryCityID,CONCAT('PostalCityID=',PostalCityID,';CreditLimit=',CreditLimit,';AccountOpenedDate=',AccountOpenedDate,';StandardDiscountPercentage=',StandardDiscountPercentage,';IsStatementSent=',IsStatementSent,';IsOnCreditHold=',IsOnCreditHold,';PaymentDays=',PaymentDays,';PhoneNumber=',PhoneNumber,';FaxNumber=',FaxNumber,';DeliveryRun=',DeliveryRun,';RunPosition=',RunPosition,';WebsiteURL=',WebsiteURL,';DeliveryAddressLine1=',DeliveryAddressLine1,';DeliveryAddressLine2=',DeliveryAddressLine2,';DeliveryPostalCode=',DeliveryPostalCode,';DeliveryLocation=',CAST([DeliveryLocation] AS nvarchar(4000)),';PostalAddressLine1=',PostalAddressLine1,';PostalAddressLine2=',PostalAddressLine2,';PostalPostalCode=',PostalPostalCode,';LastEditedBy=',LastEditedBy,';ValidFrom=',ValidFrom,';ValidTo=',ValidTo),CaseChecksum)    WHEN NOT MATCHED BY SOURCE THEN DELETE;   
 
--  select * from [tdq].[alpha_Cases] where MeasureID = '65555665-984B-4BDF-993E-332C39430625';
--	  select * from [tdq].[alpha_CaseHistory] where MeasureID = '65555665-984B-4BDF-993E-332C39430625';


--		   rollback;

--		  WITH NewCases AS (     SELECT      '65555665-984B-4BDF-993E-332C39430625' MeasureID      ,1 MeasurementID      ,BINARY_CHECKSUM(*) CaseChecksum      ,*     FROM ##Test)     select * from NewCases;