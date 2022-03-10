-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_ForwardReminder
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_ForwardReminder]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_ForwardReminder.'
	Drop procedure [dbo].[rmw_ForwardReminder]
End
Print '**** Creating Stored Procedure dbo.rmw_ForwardReminder...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.rmw_ForwardReminder
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnReminderForKey		int,	  -- Mandatory
	@pdtReminderDateCreated	datetime, -- Mandatory,
	@pnNewRecipientKey		int	  -- Mandatory
)
as
-- PROCEDURE:	rmw_ForwardReminder
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure forward the Employee Reminder (ReminderForKey and ReminderDateCreated) to the new Recipient
--

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 AUG 2009	SF	RFC5803	1	Procedure created
-- 27 AUG 2009	SF	RFC5803	2	Procedure created
-- 20 APR 2011	MF	RFC10333 3	New column that indicates the source of Alert generated reminders is to be
--					copied to when an Employee Reminder is forwarded to another recipient.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @dtReminderDateCreated datetime
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Since DateTime is part of the key it is possible to
	-- get a duplicate key.  Keep trying until a unique DateTime
	-- is extracted.
	Set @dtReminderDateCreated = getdate()
	
	While exists
		(Select 1 from EMPLOYEEREMINDER
		where	EMPLOYEENO = @pnNewRecipientKey
		and		MESSAGESEQ = @dtReminderDateCreated)
	Begin
		-- millisecond are held to equivalent to 3.33, so need to add 3
		Set @dtReminderDateCreated = DateAdd(millisecond,3,@dtReminderDateCreated)
	End

	Set @sSQLString = "
		Insert	into EMPLOYEEREMINDER(
				EMPLOYEENO,
				MESSAGESEQ,
				CASEID,
				REFERENCE,
				EVENTNO,
				CYCLENO,
				DUEDATE,
				REMINDERDATE,
				READFLAG,
				SOURCE,
				HOLDUNTILDATE,
				DATEUPDATED,
				SHORTMESSAGE,
				LONGMESSAGE,
				COMMENTS,
				SEQUENCENO,
				NAMENO,
				ALERTNAMENO)
		Select	@pnNewRecipientKey,
				@dtReminderDateCreated,
				source.CASEID,
				source.REFERENCE,
				source.EVENTNO,
				source.CYCLENO,
				source.DUEDATE,
				source.REMINDERDATE,
				0,		
				source.SOURCE,
				source.HOLDUNTILDATE,
				source.DATEUPDATED,
				source.SHORTMESSAGE,
				source.LONGMESSAGE,
				NULL,	
				source.SEQUENCENO,
				source.NAMENO,
				source.ALERTNAMENO
		from	EMPLOYEEREMINDER source
		left	join EMPLOYEEREMINDER forwarded on (
							(forwarded.CASEID	= source.CASEID or (forwarded.CASEID is null and source.CASEID is null))
					and		(forwarded.REFERENCE = source.REFERENCE or (forwarded.REFERENCE is null and source.REFERENCE is null))
					and		(forwarded.EVENTNO	= source.EVENTNO or (forwarded.EVENTNO is null and source.EVENTNO is null))
					and		(forwarded.CYCLENO	= source.CYCLENO or (forwarded.CYCLENO is null and source.CYCLENO is null))
					and		(forwarded.SEQUENCENO = source.SEQUENCENO or (forwarded.SEQUENCENO is null and source.SEQUENCENO is null))
					and		forwarded.EMPLOYEENO = @pnNewRecipientKey
		)
		where	source.EMPLOYEENO = @pnReminderForKey 
		and		source.MESSAGESEQ = @pdtReminderDateCreated
		and		forwarded.EMPLOYEENO is null"

	/* read flag set to 0 deliberately, comments set to null deliberately */
	print @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnReminderForKey int,
				@pdtReminderDateCreated datetime,
				@pnNewRecipientKey int,
				@dtReminderDateCreated	datetime',
			@pnReminderForKey		= @pnReminderForKey,
			@pdtReminderDateCreated = @pdtReminderDateCreated,
			@pnNewRecipientKey		= @pnNewRecipientKey,
			@dtReminderDateCreated	= @dtReminderDateCreated
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_ForwardReminder to public
GO
