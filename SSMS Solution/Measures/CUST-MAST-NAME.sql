CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-NAME] AS
/*<measure>
	<code>CUST-MAST-NAME</code>
	<id>CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7</id>
	<description>Invalid customer names.</description>
	<details>Customer names that are incorrectly formatted.</details>
	<refreshPolicy>Hourly</refreshPolicy>
	<refreshTimeOffset>00:05</refreshTimeOffset>
	<reportFields>
		<businessOwner name="Business Owner">John Doe</businessOwner>
		<businessUnit name="Business Unit">Sales</businessUnit>
		<status>Pending</status>
	</reportFields>
</measure>*/
SELECT
	CustomerID
	,CustomerName
FROM WorldWideImporters.Sales.Customers
WHERE
	CustomerName LIKE '% - %'
	OR (
		CustomerName LIKE '%, %'
		AND CustomerName NOT LIKE '%(%,%)%'
	);
GO
SELECT * FROM [tdq].[alpha_measure_CUST-MAST-NAME];