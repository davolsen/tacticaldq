CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-PHNO] AS
/*<Measure>
	<Code>CUST-MAST-PHNO</Code>
	<ID>2AA29809-1C51-4398-9362-DF157DF5D629</ID>
	<Definition>Invalid customer phone numbers.</Definition>
	<Details>Checks that customer phone numbers conform to the E.164 format (https://www.itu.int/rec/T-REC-E.164/).</Details>
	<RefreshPolicy>Daily</RefreshPolicy>
	<RefreshTimeOffset>03:00</RefreshTimeOffset>
</Measure>*/
SELECT
	CustomerID
	,CustomerName
	,PhoneNumber
FROM WorldWideImporters.Sales.Customers
WHERE
	PhoneNumber NOT LIKE '([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	OR PhoneNumber = '(000) 000-0000';
GO
SELECT * FROM [tdq].[alpha_measure_CUST-MAST-PHNO];