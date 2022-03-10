SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UtilMonitorMailBox
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_UtilMonitorMailBox]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_UtilMonitorMailBox.'
	drop procedure dbo.ip_UtilMonitorMailBox
	print '**** Creating procedure dbo.ip_UtilMonitorMailBox...'
	print ''
end
go


CREATE PROCEDURE dbo.ip_UtilMonitorMailBox
(
	@pbDeleteMessage	bit		= 0, 	-- indicates message to be deleted after processing
	@pbAttachmentMustExist	bit		= 1,	-- indicates mail must have an Attachment
	@psOriginators		varchar(255)	= null,	-- '^' separated list of Originators to intercept 
	@psSubjects		varchar(255)	= null,	-- '^' separated list of Subject to intercept
	@psDirectoryAndFile	varchar(255)	= null,	-- directory and file name
	@psFileSuffix		varchar(10)	= null,	-- the suffix of the newly copied file
	@pnFunction		tinyint			-- Mandatory; 1=Update Document Import Queue (new functions may be created)
)

AS

-- PROCEDURE :	ip_UtilMonitorMailBox
-- VERSION :	2
-- DESCRIPTION:	Monitors email messages that match specific characteristics and moves attachment file
--              to specific directory.
--
--		***************************************************************************************
--		*** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ***
--		***************************************************************************************
--		The folowing exetended stored procedure are NOT supported from MS SQLServer 2012:
--			xp_readmail
--			xp_deletemail
--			xp_getnextmsg
--		There are no current SQLServer alternatives available to replace these procedures.
--		At this stage we plan to drop this stored procedure as we do not believe any of our
--		clients make active use of it.
--		***************************************************************************************
--		*** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ***
--		***************************************************************************************


-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	----------- -------	-----------------------------------------------------------
-- 19 Jan 2004	mf	9616	1	Procedure created from the procedure xml_MonitorB2BMail which
--					was written by Sjoerd Koneijnenburg.  Modified to make the 
--					procedure generic.
-- 30 May 2013	MF	R13540	2	Add comment about how the extended stored procedures called from 
--					this procedure are no longer supported in MS SQLServer 2012.
--					See WARNING above.


---------------------------------------------------------------------------------------------------
-----	Declaration of variables
---------------------------------------------------------------------------------------------------
-----	Declare internal work variables
Declare	@nErrorCode		int,
	@nValidMail		int,
	@sMsg_ID		varchar(255),
	@sSubject		varchar(255),		-- subject of e-mail
	@sOriginator		varchar(255),		-- returned mail address of sender
	@sDate_Received		varchar(255),		-- as 'yyyy/mm/dd hh:mm'
	@sAttachments		varchar(255),		-- filenames of attachments, separated by ;
	@sCMD			varchar(512),
	@sImportFile		varchar(512)


---------------------------------------------------------------------------------------------------
-----	Initialize for processing
---------------------------------------------------------------------------------------------------
-----	Set appropriate options
Set	nocount ON

-----	Initialize processing
Select	@nErrorCode = 0


---------------------------------------------------------------------------------------------------
-----	Process all unread messages one by one
---------------------------------------------------------------------------------------------------
-----	Get ID of first unread message
Exec	@nErrorCode = master..xp_findnextmsg
			@msg_id = @sMsg_ID OUTPUT,
			@unread_only = 'TRUE'

-----	Loop through all messages
While	@nErrorCode = 0
and	@sMsg_ID is not NULL
Begin
	-----	Intialize status flags and other variables
	Select	@nValidMail 		= 0

	-----	Retrieve message with specified Msg_ID (don't change its status)
	If	@nErrorCode = 0
	begin
		Exec @nErrorCode = master.dbo.xp_readmail
			@originator	= @sOriginator		OUTPUT,	-- name of the sender
			@date_received	= @sDate_Received	OUTPUT,	-- date received
			@subject	= @sSubject		OUTPUT,	-- subject of e-mail message
			@attachments	= @sAttachments		OUTPUT,	-- list of temporary files with attachments
			@msg_id		= @sMsg_ID,
			@peek		= 'TRUE',			-- Message will not be set to 'read' after reading
			@suppress_attach= 'FALSE'			-- files for attachments WILL be created
	end

	-----	Check if message is meant for us (based on originator, subject, and attachment)
	If	@nErrorCode = 0
	Begin
		Set	@nValidMail =1

		If	@pbAttachmentMustExist=1	-- if there's an attachment ...
		and	@sAttachments is NULL
			Set @nValidMail=0

		Else If	@sAttachments is not NULL	-- only 1 attachment is allowed
		and	charindex(@sAttachments,';') > 0
			Set @nValidMail=0

		Else If @psOriginators is not NULL	-- if we know the originator then ensure it matches
		and	@sOriginator not in (select Parameter from dbo.fn_Tokenise(@psOriginators, '^'))
			Set @nValidMail=0

		Else If @psSubjects is not NULL		-- check the Subject
		and     not exists(select * from dbo.fn_Tokenise(@psSubjects, ';') where @sSubject like '%'+Parameter+'%')
			Set @nValidMail=0
	End

	-----	Copy the attachment to our special directory
	If	@nErrorCode = 0
	and	@nValidMail = 1
	and	@psDirectoryAndFile is not NULL
	and	@sAttachments       is not NULL
	begin
		Set	@sImportFile = @psDirectoryAndFile+
			+ replace(replace(replace(replace(convert(varchar(30),@sDate_Received,121),'-',''),':',''),' ','_'),'.','')
			+ Case When(@psFileSuffix is not null) Then '.'+@psFileSuffix End
		Set	@sCMD = 'Copy ' + @sAttachments + ' ' + @sImportFile
		Exec	@nErrorCode = master..xp_cmdshell @sCMD
	end	

	If	@nErrorCode = 0
	and	@nValidMail = 1
	Begin
		-----	Push the attachment onto the Document Import Queue
		If	@pnFunction  = 1
		begin
			Insert	into	IMPORTQUEUE (IMPORTFILELOCATION, IMPORTMETHODNO, ONHOLDFLAG)
			values	(@sImportFile, 2, 0)
			Set	@nErrorCode = @@Error
		end
	End

	
	-----	Delete message if it was fully processed
	If	@nErrorCode      = 0
	and	@nValidMail      = 1
	Begin
		If @pbDeleteMessage = 1
			Exec	master..xp_deletemail @sMsg_ID	-- Message will be 'deleted'
		Else 
			Exec	@nErrorCode = master.dbo.xp_readmail
					@msg_id	= @sMsg_ID,
					@peek	= 'FALSE'	-- Message will be set to 'read'
	End

	-----	Clear field with message-id, otherwise findnextmsg will not return anything
	Select	@sMsg_ID = NULL

	-----	Get ID of next unread message
	If	@nErrorCode = 0
	begin
		Exec	@nErrorCode = master..xp_findnextmsg
				@msg_id = @sMsg_ID OUTPUT,
				@unread_only = 'TRUE'
	end

end /* end of 'Loop through all messages' */


Return @nErrorCode
go

grant execute on dbo.ip_UtilMonitorMailBox to public
go
