-----------------------------------------------------------------------------------------------------------------------------
-- Creation of eg_GetActivityRequestEmails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[eg_GetActivityRequestEmails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.eg_GetActivityRequestEmails.'
	Drop procedure [dbo].[eg_GetActivityRequestEmails]
	Print '**** Creating Stored Procedure dbo.eg_GetActivityRequestEmails...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF
GO

Create procedure [dbo].[eg_GetActivityRequestEmails]
(
	@pnActivityId		int			-- ACTIVITYREQUEST.ACTIVITYID of the letter request being processed by DocGen.
)
-- PROCEDURE :	eg_GetActivityRequestEmails
-- VERSION :	1
-- DESCRIPTION: This is a sample stored procedure to allows user to customise the email addresses and subject to be used for sending the document by email.
--		Enter this stored procedure name in the field 'e-Mail SP' on the 'Delivery Method' pick list for email delivery method.  
--		When a document is generated with the email delivery method, this stored procedure is called to retrieve the user customised email addresses
--		and subject. If the return subject is empty DocGen uses the letter name as subject.
--	
--		Note: DocGen calls eg_GetActivityRequestEmails by default to retrieve the email addresses if there is no stored procedure specified in
--		the field 'e-Mail SP'.
--
-- CALLED BY :	Document Generator
--
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30/09/2014	DL	39747	Procedure created

as
Begin

	declare @sRecipients nvarchar(1000)	
	declare @sCCRecipients nvarchar(1000)	
	declare @sBCCRecipients nvarchar(1000)	
	declare @sSubject nvarchar(1000)
	declare	@sSQLString	nvarchar(4000)
	declare @nErrorCode int

	-- Add your own logic to extract email addresses and subject
	set @sRecipients = N'TO1@EMAILTO.COM.AU;TO2@EMAILTO.COM.AU;TO3@EMAILTO.COM.AU'
	set @sCCRecipients = N'CC1@EMAILTO.COM.AU;CC2@EMAILTO.COM.AU;CC3@EMAILTO.COM.AU'
	set @sBCCRecipients = N'BCC1@EMAILTO.COM.AU;BCC2@EMAILTO.COM.AU;BCC3@EMAILTO.COM.AU'
	set @sSubject = N'Test Subject'

	-- The email details must be returned as XML strutur as below
	/*
	<eMailAddresses>
	  <Main>TO1@EMAILTO.COM.AU;TO2@EMAILTO.COM.AU;TO3@EMAILTO.COM.AU</Main>
	  <CC>CC1@EMAILTO.COM.AU;CC2@EMAILTO.COM.AU;CC3@EMAILTO.COM.AU</CC>
	  <BCC>BCC1@EMAILTO.COM.AU;BCC2@EMAILTO.COM.AU;BCC3@EMAILTO.COM.AU</BCC>
	  <EMAILSUBJECT>Test Subject</EMAILSUBJECT>
	</eMailAddresses>	
	*/
	Select @sRecipients as 'Main',
	@sCCRecipients as 'CC',
	@sBCCRecipients as 'BCC',
	@sSubject as 'EMAILSUBJECT'
        for XML PATH('eMailAddresses'), TYPE

	set @nErrorCode = @@error

end

return @nErrorCode
go

grant execute on dbo.eg_GetActivityRequestEmails to public
go
