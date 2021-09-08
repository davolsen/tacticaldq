CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-PAYD] AS
/*<measure>
	<code>CUST-MAST-PAYD</code>
	<id>A9B9DA72-BDC2-4D65-93AC-8B0D59273977</id>
	<description>Customers with zero payment days.</description>
	<details>All customers should have greater than zero payment days</details>
</measure>*/
SELECT
	[CustomerID]
      ,[CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
FROM WorldWideImporters.Sales.Customers
WHERE PaymentDays = 0;
GO
SELECT * FROM [tdq].[alpha_measure_CUST-MAST-PAYD]