# CatHerd Tactical DQ

Tactical DQ is a lightweight data quality monitoring framework fully contained within an instance of Microsoft SQL Server. The intended use case is where there is little to no existing master data management framework, and a simple low overhead throwaway tool is needed to start monitoring data quality. Typical scenarios are implementing a new reporting data store, or to support data migration as part of an ERP implementation. It is not intended to be a robust fully featured data quality solution.

## Key Features

- **Single script setup**: Uses a single [“bootstrap script”](Installation#Bootstrap-Script) to deploy into a SQL server. No file management required.
- **Easy redeployment across environments**: Generate a [“bootstrap script”](Installation#Bootstrap-Script) that mirrors the current environment, on demand.
- **Simple measure management**: Creating measures is simple and flexible, with embedded XML metadata for portability.
- **Parallel background job management**. Uses SQL Server’s native Message Queues and Service Broker to manage measurement tasks as parallel background jobs, in conjunction with SQL Server Agent for scheduling.
- **Point-in-time history**: Uses SQL Server’s native Temporal “System-Versioned” table features to allow detailed progress reporting while minimising storage requirements.
- **XML report generation**: Outputs XML formatted reporting and case lists for consumption directly into BI and reporting software, for storage as a file.
- **Email notifications**: Uses SQL Server’s native DB Mail to deliver notifications of changes to case lists and internal errors.
- **Built-in source code management**: Maintains its own code repository within the database

## Requirements

- **SQL Server 2016** or later
- **SQL Server Agent** and **Service Broker** enabled
- Email required **DB Mail** enabled with **Service Based Authentication** configured
- The TDQ maintainer will require **sysadmin** privileges on the SQL Server instance

## Installation

TDQ is installed by executing a [*Bootstrap Script*](Installation#Bootstrap-Script) on a Microsoft SQL Server database with sysadmin privilege. The current version of a clean [bootstrap script](Installation#Bootstrap-Script) can be [downloaded here](https://raw.githubusercontent.com/davolsen/tacticaldq/main/bootstrap.sql).

- **@SchemaName**: All TDQ objects will be created in this schema, except the Service Broker Service "Scheduler" and the SQL Agent "Scheduler". It’s recommended TDQ objects are isolated in their own schema, but `'dbo'` is an acceptable schema if this cannot be done.

- **@Prefix**: A prefix to the object name. All objects will have this text prefixed to their name. It’s not necessary to prefix TDQ objects if they are in their own schema, so an empty string is acceptable.

*Most* objects will take the name `{@SchemaName}.{@Prefix}{ObjectName}`
The Service Broker Service "Scheduler" will be named `{@Prefix}_{ObjectName}`
The SQL Agent Job "Scheduler" will be named `{Database Name}_{@SchemaName}_{@Prefix}_{ObjectName}`

### Examples:

| @SchemaName | @Prefix  | Object Name        |
|-------------|----------|--------------------|
| `'tdq'`     | `''`     | `tdq.Measures`     |
| `'dbo'`     | `'tdq\_'`| `dbo.tdq_Measures` |
| `'dbo'`     | `'dq'`   | `dbo.dqMeasures`   |

Once the variables have been set, the [bootstrap script](Installation#Bootstrap-Script) can be executed. This is detailed in the design section under `BootstrapScript` Procedure

## Configuration

TDQ is configured using the *Box Table*. Objects with `ObjectType = ‘CONF’` contain configuration values.

## Add a Measure

Measures are views in SQL, augmented with an embedded XML metadata block. Create a view with the following pattern:

    CREATE OR ALTER VIEW [{HomeSchema}].[{HomePrefix}{MeasureViewPattern}]{unique token} AS
    /*<measure>
    <id>{uniqueidentifier}</id>
    <code>{Measure Code}</code>
    <description>{Description of measure}</description>
    <refreshPolicy>{Continuous|Hourly|Daily|Mo|Tu|We|Th|Fr|Sa|Su}</description>
    <refreshTimeOffset>{HH:mm}</description>
    </measure>*/
    SELECT Column
    FROM Table
    WHERE Column=Value;

Where in the name of the view:

-  *{HomeSchema}*, *{HomePrefix}* and *{MeasureViewPattern}* are the configuration parameters in the Box table.

    > :warning: Warning
    > 
    > The schema, and the name of the view **must** be encapsulated with square brackets, such as \[schema\].\[full name of view\].
    > This is not strictly required for TSQL, but is required by the `Pack` Procedure and `Unpack` Procedure.
        
-   *{unique token}* is anything that makes the view name unique,
    such as a measure code. This has no impact on operation and reporting.

Take special note of the XML embedded in a comment. This is metadata that is required by TDQ:

> :warning: Warning
> 
> tags are `<caseSensitive>`

- `<id>{uniqueidentifier}</id>` stands for a GUID to track the measure even if the Measure Code changes. Use may the TSQL function `PRINT NEWID()` to generate one.

- `<code>{Measure Code}</code>` stands for the unique organisation meaningful measure code

- `<description>{Description of measure}</description>` stands for a organisation meaningful description of the data quality problem identified by the measure.

- `<refreshPolicy>` and `<refreshTimeOffset>` control the frequency and timing at which measurements are taken. See details below.

For details on configuration, detailed usage, and architecture, see the [Wiki](https://github.com/davolsen/tacticaldq/wiki)
