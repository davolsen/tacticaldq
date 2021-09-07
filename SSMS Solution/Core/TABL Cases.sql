CREATE TABLE [tdq].[alpha_Cases](
/*<object><sequence>1</sequence></object>*/
	CaseID					int IDENTITY(1,1)	NOT NULL	PRIMARY KEY CLUSTERED
	,MeasureID				uniqueidentifier	NOT NULL
	,MeasurementID			int					NOT NULL
	,CaseProperty1			nvarchar(128)		NOT NULL
	,CaseValue1				nvarchar(4000)		NULL
	,CaseProperty2			nvarchar(128)		NULL
	,CaseValue2				nvarchar(4000)		NULL
	,CaseProperty3			nvarchar(128)		NULL
	,CaseValue3				nvarchar(4000)		NULL
	,CaseProperty4			nvarchar(128)		NULL
	,CaseValue4				nvarchar(4000)		NULL
	,CaseProperty5			nvarchar(128)		NULL
	,CaseValue5				nvarchar(4000)		NULL
	,CaseProperty6			nvarchar(128)		NULL
	,CaseValue6				nvarchar(4000)		NULL
	,CaseProperty7			nvarchar(128)		NULL
	,CaseValue7				nvarchar(4000)		NULL
	,CaseProperty8			nvarchar(128)		NULL
	,CaseValue8				nvarchar(4000)		NULL
	,CaseProperty9			nvarchar(128)		NULL
	,CaseValue9				nvarchar(4000)		NULL
	,CasePropertiesExtended	nvarchar(4000)		NULL
);