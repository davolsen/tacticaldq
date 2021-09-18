CREATE OR ALTER VIEW [tdq].[alpha_measure_SALE-TRAN-DELV] AS
/*<Measure>
	<Code>SALE-TRAN-DELV</Code>
	<ID>EE71C78F-34F2-4C30-AB81-16BF1C673FE0</ID>
	<Definition>Aged invoice with no delivery details.</Definition>
	<Details>in delivery data does not match Confirmed Recieved By.</Details>
	<RefreshPolicy>Wed</RefreshPolicy>
	<RefreshTimeOffset>01:00</RefreshTimeOffset>
</Measure>*/
SELECT
	DATEDIFF(DAY,InvoiceDate,'2016-05-31') AS AgeDays
	,InvoiceID
	,InvoiceDate
	,ConfirmedDeliveryTime
FROM WorldWideImporters.Sales.Invoices
WHERE DATEDIFF(DAY,InvoiceDate,'2016-05-31') > 28 AND ConfirmedDeliveryTime IS NULL;
GO
SELECT * FROM [tdq].[alpha_measure_SALE-TRAN-DELV];


--select * from WorldWideImporters.Sales.Invoices