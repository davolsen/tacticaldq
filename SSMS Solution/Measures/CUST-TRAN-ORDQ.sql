CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-TRAN-ORDQ] AS
/*<measure>
	<code>CUST-TRAN-ORDQ</code>
	<id>A3B06A15-8480-4787-99B8-5AB530F8900C</id>
	<description>Order quantity doesn't match invoiced quantity.</description>
	<details>The quantity for each order line must match the invoiced quanity for the related invoice line.</details>
	<refreshPolicy>Daily</refreshPolicy>
	<owner>dj@olsen.gen.nz</owner>
	<category>CUST</category>
	<reportFields>
		<businessOwner name="Business Owner">Jane Doe</businessOwner>
		<businessUnit name="Business Unit">Sales</businessUnit>
	</reportFields>
</measure>*/
SELECT
	Invoices.InvoiceID
	,InvoiceLineID
	,InvoiceLines.StockItemID
	,[Invoice Quantity]			=InvoiceLines.Quantity
	,Orders.OrderID
	,OrderLineID
	,[Order Quantity]			=OrderLines.Quantity
FROM
	WorldWideImporters.Sales.Invoices
	JOIN WorldWideImporters.Sales.InvoiceLines		ON InvoiceLines.InvoiceID	=Invoices.InvoiceID
	JOIN WorldWideImporters.Sales.Orders			ON Orders.OrderID			=Invoices.OrderID
	LEFT JOIN WorldWideImporters.Sales.OrderLines	ON
		OrderLines.OrderID = Orders.OrderID
		AND OrderLines.StockItemID = InvoiceLines.StockItemID
WHERE InvoiceLines.Quantity <> OrderLines.Quantity;
GO
SELECT * FROM [tdq].[alpha_measure_CUST-TRAN-ORDQ];