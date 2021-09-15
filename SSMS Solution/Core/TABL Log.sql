--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
CREATE TABLE tdq.alpha_Log(
	LogEntryID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	LogTimestamp datetimeoffset(0) NOT NULL DEFAULT (sysdatetimeoffset()),
	LogSource nvarchar(128) NULL,
	MeasureID uniqueidentifier NULL,
	RefreshID int NULL,
	Code nvarchar(50) NULL,
	Error bit NOT NULL DEFAULT ((0)),
	LogMessage nvarchar(4000) NULL
);
GO
CREATE NONCLUSTERED INDEX IX_alpha_Log_Timestamp ON tdq.alpha_Log(LogTimestamp ASC);
