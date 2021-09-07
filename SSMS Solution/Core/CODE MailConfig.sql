CREATE OR ALTER PROC [tdq].[alpha_MailConfig](
/*<object><sequence>40</sequence><autoExecute>true</autoExecute></object>*/
	@CheckOnly bit =0--Don't make changes, only check.
) AS BEGIN
	DECLARE
		@ReturnValue int = 0;--bitwise: 0=All good;1=mail not configured;2=profile doesn't existl4=profile account doesn't exist

	IF EXISTS (--from microsoft.com
		SELECT 1 FROM sys.configurations 
		WHERE NAME = 'Database Mail XPs' AND VALUE = 0
		) BEGIN
			SET @ReturnValue = 1;
			IF (@CheckOnly = 0) BEGIN
				PRINT 'Enabling Database Mail XPs';
				EXEC sp_configure 'show advanced options', 1;  
				RECONFIGURE;
				EXEC sp_configure 'Database Mail XPs', 1;  
				RECONFIGURE;
			END;
	END;
	ELSE PRINT 'Mail already enabled';

	DECLARE
		@profile_name	nvarchar(4000)	=DB_NAME()+'_[tdq].[alpha_Mail]'--needed for bootstrap/unpack scripting
		,@profile_id	int
	SET @profile_name					=REPLACE(REPLACE(REPLACE(REPLACE(@profile_name,'[',''),']',''),'.','_'),'dbo_','');
	SET @profile_id						=(SELECT TOP 1 profile_id FROM msdb.dbo.sysmail_profile WHERE name = @profile_name);
	IF @profile_id IS NOT NULL BEGIN
		PRINT 'Mail profile already exists';
		IF @CheckOnly = 0 EXEC msdb.dbo.sysmail_delete_profile_sp @profile_id = @profile_id, @force_delete = 1;
	END;

	DECLARE @account_id int =(SELECT TOP 1 account_id FROM msdb.dbo.sysmail_account WHERE name = @profile_name);
	IF @account_id IS NOT NULL BEGIN
		PRINT 'Mail account already exists';
		IF @CheckOnly = 0 EXEC msdb.dbo.sysmail_delete_account_sp @account_id = @account_id;
	END;

	ELSE SET @ReturnValue = @ReturnValue + 2
	IF EXISTS(SELECT 1 from msdb.dbo.sysmail_profileaccount WHERE profile_id = @profile_id AND account_id = @account_id) BEGIN
		PRINT 'Mail profile account already exists';
		IF @CheckOnly = 0 EXEC msdb.dbo.sysmail_delete_profileaccount_sp @profile_id = @profile_id;--, @account_id = @account_id;
	END;
	ELSE SET @ReturnValue = @ReturnValue + 4

	IF @CheckOnly = 0 BEGIN

		PRINT 'Creating mail profile ' + @profile_name;
		DECLARE @description nvarchar(128) = [tdq].[alpha_BoxText]('MailProfileDescription')
		EXEC msdb.dbo.sysmail_add_profile_sp
			@profile_id		=@profile_id OUTPUT
			,@profile_name	=@profile_name
			,@description	=@description;
		UPDATE [tdq].[alpha_Box] SET DefinitionText = @profile_name WHERE ObjectName = 'MailProfileName'

		PRINT 'Creating mail account ' + @profile_name;
		DECLARE
			@mailserver_type	nvarchar(128)	=[tdq].[alpha_BoxText]('MailServerType')
			,@mailserver_name	nvarchar(128)	=[tdq].[alpha_BoxText]('MailServerAddress')
			,@port				int				=[tdq].[alpha_BoxDec]('MailServerPort')
			,@enable_ssl 		bit				=[tdq].[alpha_BoxBit]('MailServerSSL')
			,@email_address		nvarchar(128)	=[tdq].[alpha_BoxText]('MailFromAddress')
			,@display_name		nvarchar(128)	=[tdq].[alpha_BoxText]('MailFromName');
		EXEC msdb.dbo.sysmail_add_account_sp
			@account_id					=@account_id OUTPUT
			,@account_name				=@profile_name 
			,@description				=@description
			,@mailserver_type			=@mailserver_type
			,@mailserver_name			=@mailserver_name
			,@port						=@port
			,@enable_ssl				=@enable_ssl
			,@email_address				=@email_address
			,@display_name				=@display_name
			,@use_default_credentials	=1;--use database credentrials. Storing a username and password in the box table is a bad idea. If this doesn't work, manually configure the database mail account.

		PRINT 'Creating mail profile account link'
		EXEC msdb.dbo.sysmail_add_profileaccount_sp @profile_id = @profile_id, @account_id = @account_id, @sequence_number = 0;

		EXEC msdb.dbo.sysmail_start_sp;
	END;
END;
GO
--EXEC [tdq].[alpha_Config];
DECLARE @ReturnCode int;
EXEC @ReturnCode = [tdq].[alpha_MailConfig]-- @CheckOnly = 1;
PRINT @ReturnCode;