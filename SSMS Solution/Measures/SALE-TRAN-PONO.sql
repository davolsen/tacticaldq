CREATE OR ALTER VIEW [tdq].[alpha_measure_SALE-TRAN-PONO] AS
/*<Measure>
	<Code>SALE-TRAN-PONO</Code>
	<ID>E51BF70B-4C4D-4C53-9354-D0B3ED0A45E1</ID>
	<Definition>Sales order with no customer PO.</Definition>
	<Details>All sales orders must have a customer purchase order.</Details>
	<RefreshPolicy>Wed</RefreshPolicy>
	<RefreshTimeOffset>01:00</RefreshTimeOffset>
</Measure>*/
SELECT
	OrderID
FROM WorldWideImporters.Sales.Orders
WHERE CustomerPurchaseOrderNumber IS NULL;
GO
SELECT * FROM [tdq].[alpha_measure_SALE-TRAN-PONO];


--select * from WorldWideImporters.Sales.Invoices