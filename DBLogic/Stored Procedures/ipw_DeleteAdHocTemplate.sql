-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteAdHocTemplate									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteAdHocTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteAdHocTemplate.'
	Drop procedure [dbo].[ipw_DeleteAdHocTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteAdHocTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteAdHocTemplate
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psAlertCode			nvarchar(10),	-- Mandatory
	@psOldMessage			nvarchar(1000)	= null,
	@pnOldDaysDelete		smallint	= null,
	@pnOldDaysStopReminders		smallint	= null,
	@pnOldDaysLead			smallint	= null,
	@pnOldRepeatIntervalDays	smallint	= null,
	@pnOldMonthsLead		smallint	= null,
	@pnOldRepeatIntervalMonths	smallint	= null,
	@pbOldIsElectronicReminder	bit		= null,
	@psOldEmailSubject		nvarchar(100)	= null,
	@psOldImportanceLevelKey	nvarchar(2)	= null		
)
as
-- PROCEDURE:	ipw_DeleteAdHocTemplate
-- VERSION:	2
-- DESCRIPTION:	Delete an Ad Hoc Template if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2005	TM		1	Procedure created
-- 18 Jul 2011	LP	RFC10992 2	Increase @psAlertMessage parameter to 1000 characters.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete
	from  ALERTTEMPLATE
	where 	ALERTTEMPLATECODE 	= @psAlertCode
	and 	ALERTMESSAGE		= @psOldMessage
	and	DELETEALERT		= @pnOldDaysDelete
	and	STOPALERT		= @pnOldDaysStopReminders
	and	DAYSLEAD		= @pnOldDaysLead
	and	DAILYFREQUENCY		= @pnOldRepeatIntervalDays
	and	MONTHSLEAD		= @pnOldMonthsLead
	and 	SENDELECTRONICALLY	= @pbOldIsElectronicReminder
	and	EMAILSUBJECT		= @psOldEmailSubject"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psAlertCode			nvarchar(10),	
					@psOldMessage			nvarchar(1000),
					@pnOldDaysDelete		smallint,
					@pnOldDaysStopReminders		smallint,
					@pnOldDaysLead			smallint,
					@pnOldRepeatIntervalDays 	smallint,
					@pnOldMonthsLead		smallint,
					@pnOldRepeatIntervalMonths 	smallint,
					@pbOldIsElectronicReminder 	bit,
					@psOldEmailSubject		nvarchar(100),
					@psOldImportanceLevelKey 	nvarchar(2)',
					@psAlertCode			= @psAlertCode,
					@psOldMessage			= @psOldMessage,
					@pnOldDaysDelete		= @pnOldDaysDelete,
					@pnOldDaysStopReminders		= @pnOldDaysStopReminders,
					@pnOldDaysLead			= @pnOldDaysLead,
					@pnOldRepeatIntervalDays	= @pnOldRepeatIntervalDays,
					@pnOldMonthsLead		= @pnOldMonthsLead,
					@pnOldRepeatIntervalMonths	= @pnOldRepeatIntervalMonths,
					@pbOldIsElectronicReminder	= @pbOldIsElectronicReminder,
					@psOldEmailSubject		= @psOldEmailSubject,
					@psOldImportanceLevelKey	= @psOldImportanceLevelKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteAdHocTemplate to public
GO