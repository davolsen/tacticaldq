CREATE OR ALTER PROC [tdq].[alpha_MailSend](
--TacticalDQ by DJ Olsen https://github.com/davolsen/tacticaldq
/*<Object><Sequence>10</Sequence></Object>*/
	@Receipients	varchar(8000)
	,@Subject		nvarchar(255)
	,@Body			nvarchar(4000)	=NULL
	,@TemplateName	nvarchar(128)	=NULL
	,@Parameter1	nvarchar(4000)	=NULL
	,@Parameter2	nvarchar(4000)	=NULL
	,@Parameter3	nvarchar(4000)	=NULL
	,@Parameter4	nvarchar(4000)	=NULL
	,@Parameter5	nvarchar(4000)	=NULL
) AS BEGIN
	DECLARE @profile_name nvarchar(128)	=[tdq].[alpha_BoxText]('MailProfileName');
	IF EXISTS(--check the profile is set up
		SELECT 1
		FROM
			msdb.dbo.sysmail_profileaccount
			JOIN msdb.dbo.sysmail_account ON sysmail_account.account_id	=sysmail_profileaccount.account_id
			JOIN msdb.dbo.sysmail_profile ON sysmail_profile.profile_id	=sysmail_profileaccount.profile_id
		WHERE
			sysmail_account.name		=@profile_name
			AND sysmail_profile.name	=@profile_name
	) BEGIN
		BEGIN TRY
			IF @TemplateName IS NOT NULL SET @Body = [tdq].[alpha_BoxText](@TemplateName);
			IF @Body IS NULL THROW 50000, 'Message body or valid template name not supplied.', 1;
			SET @Body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Body
				,'\$PARAMETER','$PARAMETER$ESCAPE$')
				,'$PARAMETER1$',ISNULL(@Parameter1,''))
				,'$PARAMETER2$',ISNULL(@Parameter2,''))
				,'$PARAMETER3$',ISNULL(@Parameter3,''))
				,'$PARAMETER4$',ISNULL(@Parameter4,''))
				,'\\','\$ESCAPE$')
				,'$PARAMETER5$',ISNULL(@Parameter5,''))
				,'\r\n',CHAR(13)+CHAR(10))
				,'\n',CHAR(13)+CHAR(10))
				,'\r',CHAR(13)+CHAR(10))
				,'\t',CHAR(9))
				,'$ESCAPE$','');
			
			EXEC msdb.dbo.sp_send_dbmail
				@profile_name					=@profile_name
				,@recipients					=@Receipients
				,@subject						=@Subject
				,@body							=@Body;

			INSERT INTO [tdq].[alpha_Log](LogSource, LogMessage)
			VALUES(OBJECT_NAME(@@PROCID), 'Sent an email to ' + @Receipients);
		END TRY
		BEGIN CATCH
			INSERT INTO [tdq].[alpha_Log](LogSource, Code, Error, LogMessage)
			VALUES(OBJECT_NAME(@@PROCID), ERROR_NUMBER(), 1, ERROR_MESSAGE());
		END CATCH;
	END;
	ELSE BEGIN
		INSERT INTO [tdq].[alpha_Log](LogSource, Error, LogMessage)
		VALUES(OBJECT_NAME(@@PROCID), 1, 'Couldn''t send an email because mail is not configured');
	END;
END;
GO
--EXEC [tdq].[alpha_Config];
DECLARE @ReturnCode int;
EXEC [tdq].[alpha_MailSend] @Receipients = 'dj@olsen.gen.nz', @Subject='Test', @Body = 'This is a test\rNew line\nNew line\r\n\r\nNew paragraph with escaped \\n';