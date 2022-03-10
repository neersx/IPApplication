-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_SendEmailViaCertificate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_SendEmailViaCertificate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ip_SendEmailViaCertificate.'
	Drop procedure [dbo].[ip_SendEmailViaCertificate]
end
print '**** Creating Stored Procedure dbo.ip_SendEmailViaCertificate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ip_SendEmailViaCertificate  
			@psProfileName			varchar(254)	= null,
			@psRecipients			nvarchar(254)	= null,
			@psCCRecipients			nvarchar(254)	= null,
			@psBCRecipients			nvarchar(254)	= null,
			@psSubject				nvarchar(100)	= null,
			@psMessage				nvarchar(254)	= null,
			@psAttachments			nvarchar(254)	= null,
			@pnErrorCode			int		output
WITH EXECUTE AS OWNER
as
-- PROCEDURE :	ip_SendEmailViaCertificate 
-- VERSION :	1
-- DESCRIPTION:	A wrapper for ip_SendMail to allow call to sp_send_dbmail directly instead of via a background task
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15/12/2010	DL		19181	1		Provide the ability to send email directly instead of background process.

set nocount on
set concat_null_yields_null off

DECLARE		@ErrorCode		int,
		@sSQLString		nvarchar(4000),
		@sCommand		varchar(4000), 
		@nFileExists		int,
		@nObject		int,
		@nObjectExist		tinyint,
		@bDBEmailViaCertificate		tinyint
		
-- Initialise
Set @ErrorCode = 0
select @pnErrorCode = 0
 
If @ErrorCode = 0
Begin
	-- SQA19181 intiate sending email synchronously via a certificate login.
	-- Call database mail stored proc msdb.dbo.sp_send_dbmail directly. 
	EXEC msdb.dbo.sp_send_dbmail 
		 @profile_name =		@psProfileName, 
		 @recipients =			@psRecipients, 
		 @copy_recipients=		@psCCRecipients,
		 @blind_copy_recipients=@psBCRecipients,
		 @body =				@psMessage ,
		 @subject =				@psSubject,
		 @file_attachments =	@psAttachments

	SET @ErrorCode = @@ERROR
	SELECT @pnErrorCode =  @ErrorCode
End

return @ErrorCode
go

grant execute on dbo.ip_SendEmailViaCertificate   to public
go
