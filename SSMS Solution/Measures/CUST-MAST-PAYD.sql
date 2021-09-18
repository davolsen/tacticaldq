CREATE OR ALTER VIEW [tdq].[alpha_measure_CUST-MAST-PAYD] AS
/*<Measure>
	<Code>CUST-MAST-PAYD</Code>
	<ID>A9B9DA72-BDC2-4D65-93AC-8B0D59273977</ID>
	<Definition>Customers with zero payment days.</Definition>
	<Details>All customers should have greater than zero payment days</Details>
</Measure>*/
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