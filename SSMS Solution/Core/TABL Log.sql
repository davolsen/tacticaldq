CREATE TABLE [tdq].[alpha_Log](
/*<object><sequence>1</sequence></object>*/
	LogEntryID			int IDENTITY(1,1)	NOT NULL	PRIMARY KEY CLUSTERED
	,LogTimestamp		datetimeoffset(0)	NOT NULL	DEFAULT (sysdatetimeoffset())
	,LogSource			nvarchar(128)		NULL
	,ID					uniqueidentifier	NULL
	,Code				nvarchar(50)		NULL
	,Error				bit					NOT NULL	DEFAULT ((0))
	,LogMessage			nvarchar(4000)		NULL
);