CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-NAME] AS
/*<Measure>
	<Code>CUST-MAST-NAME</Code>
	<ID>CE85AD9E-6560-4CBF-A6FF-32A391FAE2B7</ID>
	<Definition>Invalid customer names.</Definition>
	<Details>Customer names that are incorrectly formatted.</Details>
	<RefreshPolicy>Hourly</RefreshPolicy>
	<RefreshTimeOffset>00:05</RefreshTimeOffset>
	<ReportFields>
		<businessOwner name="Business Owner">John Doe</businessOwner>
		<businessUnit name="Business Unit">Sales</businessUnit>
		<status>Pending</status>
	</ReportFields>
</Measure>*/
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