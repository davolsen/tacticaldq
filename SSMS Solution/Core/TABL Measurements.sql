CREATE TABLE [tdq].[alpha_Measurements](
/*<object><sequence>1</sequence></object>*/
	MeasurementID				int IDENTITY(1,1)	NOT NULL	PRIMARY KEY CLUSTERED
	,MeasureID					uniqueidentifier	NOT NULL
	,TimestampStarted			datetimeoffset(0)	NOT NULL	DEFAULT (sysdatetimeoffset())
	,TimestampCompleted			datetimeoffset(0)	NULL
	,OutputChecksum				int					NULL
	,CaseCount					int					NULL
	,LastChangedMeasurementID	int					NULL
);
CREATE INDEX [alpha_Measurements_MeasureID_TimestampCompleted_Desc] ON [tdq].[alpha_Measurements] (MeasureID, TimestampCompleted DESC);