/*
Adds faults to the World Wide Importers Dataset
*/
CREATE OR ALTER PROCEDURE Activity(
	@LowerBreakProportion	numeric(3,3)	=0
	,@UpperBreakProportion	numeric(3,3)	=.01
	,@LowerFixProportion	numeric(3,3)	=0
	,@UpperFixProportion	numeric(3,3)	=.025
	,@TestOnly				bit				=0
	,@Only					nvarchar(128)	=NULL
) AS BEGIN
	SET NOCOUNT ON;
		
	DECLARE
		@Index				int				=1
		,@TableName			nvarchar(128)
		,@KeyColumn			nvarchar(128)
		,@DataColumn		nvarchar(128)
		,@BadDataLogic		nvarchar(4000)
		,@Condition			nvarchar(4000)
		,@MeasureName		nvarchar(128)
		,@SQL				nvarchar(4000)
		,@BeforeCount		int
		,@AfterCount		int;

	DECLARE @Results TABLE(ResultCount int);
	DECLARE @Objects TABLE(TableName nvarchar(128),KeyColumn nvarchar(128),DataColumn nvarchar(128),BadDataLogic nvarchar(4000),Condition nvarchar(4000),MeasureName nvarchar(128), ID int identity(1,1));
	INSERT INTO @Objects VALUES
		('Sales.Customers','CustomerID','PhoneNumber','CHOOSE(Rnd%3+1,''TBA'',''(000) 000-0000'',REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber,''('',''''),'')'',''''),''-'',''''),'' '',''''),'''')',NULL,'[tdq].[alpha_measure_CUST-MAST-PHNO]')
		,('Sales.Customers','CustomerID','BuyingGroupID','CHOOSE(Rnd%3,1,2)',NULL,'[tdq].[alpha_measure_CUST-MAST-BGRP]')
		,('Sales.Customers','CustomerID','CustomerName','REPLACE(REPLACE(CustomerName,'' ('','' - ''),'')'','''')','CustomerName LIKE ''Tailspin Toys%'' OR CustomerName LIKE ''Wingtip Toys%''','[tdq].[alpha_measure_CUST-MAST-NAME]')
		,('Sales.Customers','CustomerID','CustomerName','LEFT(CustomerName,CHARINDEX('' '', CustomerName) - 1) + '', '' + SUBSTRING(CustomerName,CHARINDEX('' '', CustomerName) + 1,99)','CustomerName NOT LIKE ''Tailspin Toys%'' AND CustomerName NOT LIKE ''Wingtip Toys%''','[tdq].[alpha_measure_CUST-MAST-NAME]')
		,('Sales.Customers','CustomerID','PaymentDays','0',NULL,'[tdq].[alpha_measure_CUST-MAST-PAYD]')
		,('Sales.Invoices','InvoiceID','ReturnedDeliveryData','NULL',NULL,'[tdq].[alpha_measure_SALE-TRAN-DELV]')
		,('Sales.Orders','OrderID','CustomerPurchaseOrderNumber','NULL',NULL,'[tdq].[alpha_measure_SALE-TRAN-PONO]')
		,('Sales.OrderLines','OrderLineID','Quantity','Quantity + (Quantity*((CAST(Rnd%10 AS decimal)-5)/100))',NULL,'[tdq].[alpha_measure_CUST-TRAN-ORDQ]')

	DECLARE @BreakTemplate AS nvarchar(4000) = '
	UPDATE WorldWideImporters.$TableName$
	SET $DataColumn$ = BadData
	FROM
		WorldWideImporters.$TableName$ DataTable
		JOIN (
			SELECT
				$KeyColumn$
				,BadData	=$BadDataLogic$
				,Proportion	=CAST(ROW_NUMBER() OVER (ORDER BY NEWID()) AS decimal)/COUNT(*) OVER (PARTITION BY NULL)
			FROM WorldWideImporters.$TableName$,(SELECT Rnd=ABS(CHECKSUM(NEWID()))) Rnd
			$Condition$
		) CreateFaults ON CreateFaults.$KeyColumn$ = DataTable.$KeyColumn$
	WHERE Proportion < ('+CAST(@UpperBreakProportion AS nvarchar(4000))+'-'+CAST(@LowerBreakProportion AS nvarchar(4000))+')*RAND()+'+CAST(@LowerBreakProportion AS nvarchar(4000))+';';
	DECLARE @FixTemplate AS nvarchar(4000) = '
	UPDATE WorldWideImporters.$TableName$
	SET $DataColumn$ = Fix.$DataColumn$
	FROM
		WorldWideImporters.$TableName$ DataTable
		JOIN (
			SELECT
				Cases.$KeyColumn$
				,Fix.$DataColumn$
				,RowNum				=ROW_NUMBER() OVER (ORDER BY RAND(CHECKSUM(NEWID())))
			FROM
				$MeasureName$ Cases
				JOIN WorldWideImportersClean.$TableName$ Fix ON Fix.$KeyColumn$ = Cases.$KeyColumn$
		) AS Fix ON
			Fix.$KeyColumn$ = DataTable.$KeyColumn$
	WHERE RowNum < (SELECT COUNT(*) FROM WorldWideImporters.$TableName$)*(('+CAST(@UpperFixProportion AS nvarchar(4000))+'-'+CAST(@LowerFixProportion AS nvarchar(4000))+')*RAND()+'+CAST(@LowerFixProportion AS nvarchar(4000))+');';
	
	BEGIN TRAN
	BEGIN TRY

		WHILE @Index <= (SELECT COUNT(*) FROM @Objects) BEGIN
			SELECT
				@TableName		=TableName
				,@KeyColumn		=KeyColumn
				,@DataColumn	=DataColumn
				,@BadDataLogic	=BadDataLogic
				,@Condition		=Condition
				,@MeasureName	=MeasureName
			FROM @Objects
			WHERE ID = @Index;
			SET @Index = @Index + 1;

			IF @MeasureName <> ISNULL(@Only,@MeasureName) CONTINUE;

			DELETE FROM @Results
			SET @SQL = 'SELECT COUNT(*) FROM '+@MeasureName
			INSERT INTO @Results
			EXEC (@SQL);
			SET @BeforeCount = (SELECT ResultCount FROM @Results)
			SET @SQL = REPLACE(REPLACE(REPLACE(REPLACE(@BreakTemplate,'$TableName$',@TableName),'$KeyColumn$',@KeyColumn),'$DataColumn$',@DataColumn),'$BadDataLogic$',@BadDataLogic);
			SET @SQL = REPLACE(@SQL,'$CONDITION$',ISNULL('WHERE '+@Condition,''));
			--PRINT @SQL;
			EXEC (@SQL);
			SET @SQL = 'SELECT COUNT(*) FROM '+@MeasureName
			DELETE FROM @Results
			INSERT INTO @Results
			EXEC (@SQL);
			SET @AfterCount = (SELECT ResultCount FROM @Results)

			PRINT CONCAT('Broke ',@TableName,' ',@KeyColumn,' ',@DataColumn,' From ',@BeforeCount,' to ',@AfterCount);
		

			SET @SQL = REPLACE(REPLACE(REPLACE(REPLACE(@FixTemplate,'$TableName$',@TableName),'$KeyColumn$',@KeyColumn),'$DataColumn$',@DataColumn),'$MeasureName$',@MeasureName);
			EXEC (@SQL);
			SET @SQL = 'SELECT COUNT(*) FROM '+@MeasureName
			DELETE FROM @Results
			INSERT INTO @Results
			EXEC (@SQL);
			SET @BeforeCount = (SELECT ResultCount FROM @Results)

			PRINT CONCAT('Fixed ',@TableName,' ',@KeyColumn,' ',@DataColumn,' From ',@AfterCount,' to ',@BeforeCount);



		END;
	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK!';
		PRINT @SQL;
		ROLLBACK;
		THROW;
	END CATCH;

	IF @@TRANCOUNT > 0 BEGIN
		IF @TestOnly = 0 COMMIT;
		ELSE BEGIN
			PRINT 'ROLLBACK!';
			ROLLBACK;
		END;
	END;
END;
GO
EXEC Activity
	@LowerBreakProportion	=0
	,@UpperBreakProportion	=.1
	,@LowerFixProportion	=0
	,@UpperFixProportion	=.1
	,@TestOnly				=1
	--,@Only					='[tdq].[alpha_measure_CUST-MAST-BGRP]'
/*
EXEC Activity
	@LowerBreakProportion	=0
	,@UpperBreakProportion	=.1
	,@LowerFixProportion	=0
	,@UpperFixProportion	=0
	,@TestOnly				=0
*/

--BEGIN TRAN
--SELECT COUNT(*) FROM [tdq].[alpha_measure_CUST-MAST-PHNO]
----UPDATE WorldWideImporters.Sales.Customers
----SET PhoneNumber = BadData
----FROM
----	WorldWideImporters.Sales.Customers
----	JOIN (
----			SELECT
----				CustomerID
----				,BadData	=CHOOSE(Rnd%3+1,'TBA','(000) 000-0000',REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber,'(',''),')',''),'-',''),' ',''),'')
----				,Proportion	=CAST(ROW_NUMBER() OVER (ORDER BY RAND(CHECKSUM(NEWID()))) AS decimal)/COUNT(*) OVER (PARTITION BY NULL)
----			FROM WorldWideImporters.Sales.Customers,(SELECT Rnd=ABS(CHECKSUM(NEWID()))) Rnd
				
----		) CreateFaults ON CreateFaults.CustomerID = WorldWideImporters.Sales.Customers.CustomerID
----WHERE Proportion < (0.010-0.000)*RAND()+0.000;
--UPDATE WorldWideImporters.$TableName$
--SET $DataColumn$ = Fix.$DataColumn$
--FROM
--	WorldWideImporters.$TableName$ DataTable
--	JOIN (
--		SELECT
--			Cases.$KeyColumn$
--			,Fix.$DataColumn$
--				,Proportion	=CAST(ROW_NUMBER() OVER (ORDER BY RAND(CHECKSUM(NEWID()))) AS decimal)/COUNT(*) OVER (PARTITION BY NULL)
--		FROM
--			$MeasureName$ Cases
--			JOIN WorldWideImportersClean.$TableName$ Fix ON Fix.$KeyColumn$ = Cases.$KeyColumn$
--	) AS Fix ON
--		Fix.$KeyColumn$ = DataTable.$KeyColumn$
--		AND Proportion < (@UpperFixProportion-@LowerFixProportion)*RAND()+@LowerFixProportion
--SELECT COUNT(*) FROM [tdq].[alpha_measure_CUST-MAST-PHNO]
--ROLLBACK


--UPDATE WorldWideImporters.WorldWideImporters.Sales.Customers
--	SET PhoneNumber = Fix.PhoneNumber
--	FROM
--		WorldWideImporters.WorldWideImporters.Sales.Customers DataTable
--		JOIN (
--			SELECT
--				Cases.CustomerID
--				,Fix.PhoneNumber
--					,Proportion	=CAST(ROW_NUMBER() OVER (ORDER BY RAND(CHECKSUM(NEWID()))) AS decimal)/COUNT(*) OVER (PARTITION BY NULL)
--			FROM
--				[tdq].[alpha_measure_CUST-MAST-PHNO] Cases
--				JOIN WorldWideImportersClean.WorldWideImporters.Sales.Customers Fix ON Fix.CustomerID = Cases.CustomerID
--		) AS Fix ON
--			Fix.CustomerID = DataTable.CustomerID
--	WHERE Proportion < (0.100-0.000)*RAND()+0.000;

