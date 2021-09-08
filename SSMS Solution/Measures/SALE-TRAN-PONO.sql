CREATE OR ALTER VIEW [tdq].[alpha_measure_SALE-TRAN-PONO] AS
/*<measure>
	<code>SALE-TRAN-PONO</code>
	<id>E51BF70B-4C4D-4C53-9354-D0B3ED0A45E1</id>
	<description>Sales order with no customer PO.</description>
	<details>All sales orders must have a customer purchase order.</details>
	<refreshPolicy>Wed</refreshPolicy>
	<refreshTimeOffset>01:00</refreshTimeOffset>
</measure>*/
SELECT
	OrderID
FROM WorldWideImporters.Sales.Orders
WHERE CustomerPurchaseOrderNumber IS NULL;
GO
SELECT * FROM [tdq].[alpha_measure_SALE-TRAN-PONO];


--select * from WorldWideImporters.Sales.Invoices