-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateAdHocTemplate									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateAdHocTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateAdHocTemplate.'
	Drop procedure [dbo].[ipw_UpdateAdHocTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateAdHocTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateAdHocTemplate
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psAlertCode			nvarchar(10),	-- Mandatory
	@psMessage			nvarchar(1000)	= null,
	@pnDaysDelete			smallint	= null,
	@pnDaysStopReminders		smallint	= null,
	@pnDaysLead			smallint	= null,
	@pnRepeatIntervalDays		smallint	= null,
	@pnMonthsLead			smallint	= null,
	@pnRepeatIntervalMonths		smallint	= null,
	@pbIsElectronicReminder		bit		= null,
	@psEmailSubject			nvarchar(100)	= null,
	@psImportanceLevelKey		nvarchar(2)	= null,
	@pbIsEmployee				bit		= null,
	@pbIsSignatory				bit		= null,
	@pbIsCriticalList			bit		= null,
	@psNameType				nvarchar(3)		= null,
	@psRelationship			nvarchar(3)		= null,
	@pnEmployeeNo				int		= null,
	@psOldMessage			nvarchar(1000)	= null,
	@pnOldDaysDelete		smallint	= null,
	@pnOldDaysStopReminders		smallint	= null,
	@pnOldDaysLead			smallint	= null,
	@pnOldRepeatIntervalDays	smallint	= null,
	@pnOldMonthsLead		smallint	= null,
	@pnOldRepeatIntervalMonths	smallint	= null,
	@pbOldIsElectronicReminder	bit		= null,
	@psOldEmailSubject		nvarchar(100)	= null,
	@psOldImportanceLevelKey	nvarchar(2)	= null,
	@pbOldIsEmployee			bit		= null,
	@pbOldIsSignatory			bit		= null,
	@pbOldIsCriticalList		bit		= null,
	@psOldNameType			nvarchar(3)		= null,
	@psOldRelationship		nvarchar(3)		= null,
	@pnOldEmployeeNo			int		= null
)
as
-- PROCEDURE:	ipw_UpdateAdHocTemplate
-- VERSION:	3
-- DESCRIPTION:	Update an Ad Hoc Template if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2005	TM		1	Procedure created
-- 18 Jul 2011	LP	RFC10992 2	Increase @psAlertMessage parameter to 1000 characters.
-- 02 Dec 2011	DV	RFC996	 3	Add logic to update additional fields in ALERTTEMPLATE table. 

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
	Update  ALERTTEMPLATE
	Set	ALERTMESSAGE		= @psMessage,
		DELETEALERT		= @pnDaysDelete,
		STOPALERT		= @pnDaysStopReminders,
		DAYSLEAD		= @pnDaysLead,
		DAILYFREQUENCY		= @pnRepeatIntervalDays,
		MONTHSLEAD		= @pnMonthsLead,
		MONTHLYFREQUENCY	= @pnRepeatIntervalMonths,
		SENDELECTRONICALLY	= @pbIsElectronicReminder,
		EMAILSUBJECT		= @psEmailSubject,
		IMPORTANCELEVEL		= @psImportanceLevelKey,
		EMPLOYEEFLAG		= @pbIsEmployee,
		SIGNATORYFLAG		= @pbIsSignatory,
		CRITICALFLAG		= @pbIsCriticalList,
		NAMETYPE			= @psNameType,
		RELATIONSHIP		= @psRelationship,
		EMPLOYEENO			= @pnEmployeeNo
	where 	ALERTTEMPLATECODE 	= @psAlertCode
	and ALERTMESSAGE		= @psOldMessage
	and	DELETEALERT		= @pnOldDaysDelete
	and	STOPALERT		= @pnOldDaysStopReminders
	and	DAYSLEAD		= @pnOldDaysLead
	and	DAILYFREQUENCY		= @pnOldRepeatIntervalDays
	and	MONTHSLEAD		= @pnOldMonthsLead
	and SENDELECTRONICALLY	= @pbOldIsElectronicReminder
	and	EMAILSUBJECT		= @psOldEmailSubject
	and EMPLOYEEFLAG		= @pbOldIsEmployee
	and	SIGNATORYFLAG		= @pbOldIsSignatory
	and	CRITICALFLAG		= @pbOldIsCriticalList
	and	NAMETYPE			= @psOldNameType
	and	RELATIONSHIP		= @psOldRelationship
	and	EMPLOYEENO			= @pnOldEmployeeNo"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psAlertCode			nvarchar(10),	
					@psMessage			nvarchar(1000),
					@pnDaysDelete			smallint,
					@pnDaysStopReminders		smallint,
					@pnDaysLead			smallint,
					@pnRepeatIntervalDays		smallint,
					@pnMonthsLead			smallint,
					@pnRepeatIntervalMonths		smallint,
					@pbIsElectronicReminder		bit,
					@psEmailSubject			nvarchar(100),
					@psImportanceLevelKey		nvarchar(2),
					@pbIsEmployee				bit,
					@pbIsSignatory				bit,
					@pbIsCriticalList			bit,
					@psNameType				nvarchar(3),
					@psRelationship			nvarchar(3),
					@pnEmployeeNo				int,
					@psOldMessage			nvarchar(1000),
					@pnOldDaysDelete		smallint,
					@pnOldDaysStopReminders		smallint,
					@pnOldDaysLead			smallint,
					@pnOldRepeatIntervalDays 	smallint,
					@pnOldMonthsLead		smallint,
					@pnOldRepeatIntervalMonths 	smallint,
					@pbOldIsElectronicReminder 	bit,
					@psOldEmailSubject		nvarchar(100),
					@psOldImportanceLevelKey 	nvarchar(2),
					@pbOldIsEmployee			bit,
					@pbOldIsSignatory			bit,
					@pbOldIsCriticalList		bit,
					@psOldNameType			nvarchar(3),
					@psOldRelationship		nvarchar(3),
					@pnOldEmployeeNo			int',
					@psAlertCode			= @psAlertCode,
					@psMessage			= @psMessage,
					@pnDaysDelete			= @pnDaysDelete,
					@pnDaysStopReminders		= @pnDaysStopReminders,
					@pnDaysLead			= @pnDaysLead,
					@pnRepeatIntervalDays		= @pnRepeatIntervalDays,
					@pnMonthsLead			= @pnMonthsLead,
					@pnRepeatIntervalMonths		= @pnRepeatIntervalMonths,
					@pbIsElectronicReminder		= @pbIsElectronicReminder,
					@psEmailSubject			= @psEmailSubject,
					@psImportanceLevelKey		= @psImportanceLevelKey,
					@pbIsEmployee				= @pbIsEmployee,
					@pbIsSignatory				= @pbIsSignatory,
					@pbIsCriticalList			= @pbIsCriticalList,
					@psNameType					= @psNameType,
					@psRelationship				= @psRelationship,
					@pnEmployeeNo				= @pnEmployeeNo,
					@psOldMessage			= @psOldMessage,
					@pnOldDaysDelete		= @pnOldDaysDelete,
					@pnOldDaysStopReminders		= @pnOldDaysStopReminders,
					@pnOldDaysLead			= @pnOldDaysLead,
					@pnOldRepeatIntervalDays	= @pnOldRepeatIntervalDays,
					@pnOldMonthsLead		= @pnOldMonthsLead,
					@pnOldRepeatIntervalMonths	= @pnOldRepeatIntervalMonths,
					@pbOldIsElectronicReminder	= @pbOldIsElectronicReminder,
					@psOldEmailSubject		= @psOldEmailSubject,
					@psOldImportanceLevelKey	= @psOldImportanceLevelKey,
					@pbOldIsEmployee			= @pbOldIsEmployee,
					@pbOldIsSignatory			= @pbOldIsSignatory,
					@pbOldIsCriticalList		= @pbOldIsCriticalList,
					@psOldNameType				= @psOldNameType,
					@psOldRelationship			= @psOldRelationship,
					@pnOldEmployeeNo			= @pnOldEmployeeNo
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateAdHocTemplate to public
GO