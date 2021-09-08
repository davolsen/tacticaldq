--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
CREATE TABLE tdq.alpha_Box(
	ObjectName nvarchar(128) NOT NULL PRIMARY KEY,
	ObjectType char(4) NOT NULL,
	ObjectSequence tinyint NOT NULL DEFAULT ((0)),
	DefinitionBinary varbinary(8000) NULL,
	DefinitionText nvarchar(4000) NULL,
	DefinitionDecimal decimal(19, 5) NULL,
	DefinitionDate datetimeoffset(0) NULL,
	DefinitionBit bit NULL
);
