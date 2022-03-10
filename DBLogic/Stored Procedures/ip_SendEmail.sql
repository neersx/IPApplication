-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_SendEmail
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_SendEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ip_SendEmail.'
	Drop procedure [dbo].[ip_SendEmail]
end
print '**** Creating Stored Procedure dbo.ip_SendEmail...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ip_SendEmail  
			@pnUserIdentityId		int,				-- Mandatory
			@psCulture			nvarchar(10) 	= null, 	-- the language in which output is to be expressed
			@psRecipients			nvarchar(254)	= null,
			@psCCRecipients			nvarchar(254)	= null,
			@psBCRecipients			nvarchar(254)	= null,
			@psSubject			nvarchar(100)	= null,
			@psMessage			nvarchar(254)	= null,
			@psAttachments			nvarchar(254)	= null,
			@pbUseNewDBMail			bit		= 0
as
-- PROCEDURE :	ip_SendEmail 
-- VERSION :	8
-- DESCRIPTION:	A wrapper for xp_sendmail / sp_send_dbmail to allow error messages to be accessed by Centura.
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Jun 2005	DW	9829	1	Procedure created
-- 24 Apr 2008	JS	16276	2	Extended to use SQLServer 2005 sp_send_dbmail if @pbUseNewDBMail = 1.
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 13 Dec 2010	DL	19181	4	Provide the ability to send email directly instead of background process.
-- 28 May 2013	MF	R13540	5	Removed reference to xp_SendMail which is unsupported from SQLServer 2012.
-- 28 May 2013	DL	10030	6	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 02/09/2013	DL	21585	7	Ignore the flag @pbUseNewDBMail and use DBMail if @sProfileName is not null.	
-- 14 Oct 2014	DL	R39102	8	Use service broker instead of OLE Automation to run the command asynchronoulsly

set nocount on
set concat_null_yields_null off

DECLARE		@ErrorCode		int,
		@sProfileName		varchar(254),
		@sSQLString		nvarchar(4000),
		@sCommand		varchar(4000), 
		@nFileExists		int,
		@nObject		int,
		@nObjectExist		tinyint,
		@bDBEmailViaCertificate		tinyint
		
-- Initialise
Set @ErrorCode = 0


-- Get the Database Mail Profile
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select  @sProfileName = COLCHARACTER
	From SITECONTROL
	Where CONTROLID = 'Database Email Profile'"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@sProfileName		varchar(254)		Output',
				  @sProfileName		= @sProfileName		Output

	if isnull(@sProfileName, '') = ''
	begin
		Raiserror ('Cannot send email using Database Mail.  Please set up Database Mail profile on the server and try again.',16,1)
		Return -1
	end		
End


-- is db mail stored proc enabled via a certificate?
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select  @bDBEmailViaCertificate = COLBOOLEAN
	From SITECONTROL
	Where CONTROLID = 'Database Email Via Certificate'"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@bDBEmailViaCertificate		tinyint		Output',
				  @bDBEmailViaCertificate		= @bDBEmailViaCertificate		Output
End

 
-- rfc39102 service broker can't send email with attachment.  Use the certificate method to send email instead.
If @ErrorCode = 0 and (@bDBEmailViaCertificate = 1 OR @psAttachments is not null)
Begin
	-- SQA19181 intiate sending email synchronously via a certificate login.
	-- Call database mail stored proc msdb.dbo.sp_send_dbmail directly.  
	EXEC dbo.ip_SendEmailViaCertificate 
		 @psProfileName =		@sProfileName, 
		 @psRecipients =		@psRecipients, 
		 @psCCRecipients=		@psCCRecipients,
		 @psBCRecipients=		@psBCRecipients,
		 @psMessage =			@psMessage ,
		 @psSubject =			@psSubject,
		 @psAttachments =		@psAttachments,
		 @pnErrorCode	=		@ErrorCode output

	SELECT @ErrorCode
	
End
Else if @ErrorCode = 0
Begin
	-- rfc39102 Change command to be executed asynchronously via service broker instead of OLE Automation.
	-- We need to execute sp_send_dbmail asynchronously so that it runs within a trusted connection
	-- otherwise the attachments do not work if the client is using a SQLServer Authenticated login.
	Set @sCommand = 'msdb.dbo.sp_send_dbmail ' +
			'@profile_name="' + @sProfileName + '"' 
	If @psRecipients is not null
		Set @sCommand = @sCommand + ',@recipients="' + @psRecipients + '"'
	If @psCCRecipients is not null
		Set @sCommand = @sCommand + ',@copy_recipients="' + @psCCRecipients + '"'
	If @psBCRecipients is not null
		Set @sCommand = @sCommand + ',@blind_copy_recipients="' + @psBCRecipients + '"'
	If @psSubject is not null
		Set @sCommand = @sCommand + ',@subject="' + @psSubject + '"'
	If @psMessage is not null
		Set @sCommand = @sCommand + ',@body="' + @psMessage + '"'
	If @psAttachments is not null
		Set @sCommand = @sCommand + ',@file_attachments="' + @psAttachments + '"'
	
	If @ErrorCode = 0
	Begin
		-- Execute sp_send_dbmail asynchronously within a trusted connection
		exec @ErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
	End	
	
	Select @ErrorCode				
end	


return @ErrorCode
go

grant execute on dbo.ip_SendEmail   to public
go
