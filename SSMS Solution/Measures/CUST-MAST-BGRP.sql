CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-BGRP] AS
/*<measure>
	<code>CUST-MAST-BGRP</code>
	<id>3A4F8C51-31B9-4612-AD70-FF6CFD5A0E9E</id>
	<description>Customer name and buying group do not match.</description>
	<details>The buying group must be the same as the start of the customer name, and if there is a buying group that matches the start of the customer name it should be set.</details>
	<refreshPolicy>Continuous</refreshPolicy>
	<owner>dj@olsen.gen.nz</owner>
	<category>CUST</category>
	<reportFields>
		<businessOwner name="Business Owner">Jane Doe</businessOwner>
		<businessUnit name="Business Unit">Sales</businessUnit>
	</reportFields>
</measure>*/
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