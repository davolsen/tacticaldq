--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
CREATE TABLE tdq.alpha_Cases(
	CaseID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	MeasureID uniqueidentifier NOT NULL,
	RefreshID int NOT NULL,
	CaseValue1 nvarchar(4000) NULL,
	CaseValue2 nvarchar(4000) NULL,
	CaseValue3 nvarchar(4000) NULL,
	CaseValue4 nvarchar(4000) NULL,
	CaseValue5 nvarchar(4000) NULL,
	CaseValue6 nvarchar(4000) NULL,
	CaseValue7 nvarchar(4000) NULL,
	CaseValue8 nvarchar(4000) NULL,
	CaseValue9 nvarchar(4000) NULL,
	CaseValuesExtended nvarchar(4000) NULL,
	CaseChecksum int NOT NULL,
	Identified datetime2(0) GENERATED ALWAYS AS ROW START NOT NULL,
	Resolved datetime2(0) GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (Identified, Resolved)
) WITH(SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CasesResolved));
GO;
CREATE NONCLUSTERED INDEX IX_Cases_RefreshID_DESC_MeasureID ON tdq.alpha_Cases (
	RefreshID DESC,
	MeasureID ASC
);
/*
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE [tdq].[alpha_Cases] ADD PERIOD FOR SYSTEM_TIME (Identified, Resolved)
ALTER TABLE [tdq].[alpha_Cases] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = tdq.alpha_CasesResolved));
*/