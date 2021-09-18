CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-BGRP] AS
/*<Measure>
	<Code>CUST-MAST-BGRP</Code>
	<ID>3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E</ID>
	<Definition>Customer name and buying group do not match.</Definition>
	<Details>The buying group must be the same as the start of the customer name, and if there is a buying group that matches the start of the customer name it should be set.</Details>
	<RefreshPolicy>Continuous</RefreshPolicy>
	<Owner>dj@olsen.gen.nz</Owner>
	<Category>CUST</Category>
	<ReportFields>
		<businessOwner name="Business Owner">Jane Doe</businessOwner>
		<businessUnit name="Business Unit">Sales</businessUnit>
	</ReportFields>
</Measure>*/
SELECT
	CustomerID
	,CustomerName
	,BuyingGroupName
FROM
	WorldWideImporters.Sales.Customers
	LEFT JOIN WorldWideImporters.Sales.BuyingGroups ON BuyingGroups.BuyingGroupID = Customers.BuyingGroupID
WHERE
	LEFT(CustomerName,LEN(BuyingGroupName)) <> BuyingGroupName
	OR EXISTS (SELECT 1 FROM WorldWideImporters.Sales.BuyingGroups WHERE Customers.BuyingGroupID IS NULL AND LEFT(CustomerName,LEN(BuyingGroupName)) = BuyingGroupName);
GO
SELECT * FROM [tdq].[alpha_measure_CUST-MAST-BGRP] ;