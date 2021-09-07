CREATE OR ALTER VIEW [tdq].[alpha_measure_CU001] AS
/*<measure>
	<code>CU001</code>
	<id>2AA29809-1C51-4398-9362-DF157DF5D629</id>
	<description>Invalid customer phone numbers.</description>
	<details>Checks that customer phone numbers conform to the E.164 format (https://www.itu.int/rec/T-REC-E.164/).</details>
</measure>*/
SELECT
	CustomerID
	,CustomerName
	,PhoneNumber
FROM WorldWideImporters.Sales.Customers
WHERE
	PhoneNumber NOT LIKE '([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	OR PhoneNumber = '(000) 000-0000';