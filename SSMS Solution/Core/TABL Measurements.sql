--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
CREATE TABLE tdq.alpha_Measurements(
	MeasurementID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	MeasureID uniqueidentifier NOT NULL,
	TimestampStarted datetimeoffset(0) NOT NULL DEFAULT (sysdatetimeoffset()),
	TimestampCompleted datetimeoffset(0) NULL,
	Published bit NOT NULL DEFAULT ((0)),
	Unpublished bit NOT NULL DEFAULT ((0))
);
GO;
CREATE NONCLUSTERED INDEX IX_Measurements_MeasureID_TimestampCompleted_Desc ON tdq.alpha_Measurements(MeasureID ASC, TimestampCompleted DESC);
