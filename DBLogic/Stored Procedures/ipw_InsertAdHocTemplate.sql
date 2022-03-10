-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertAdHocTemplate									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertAdHocTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertAdHocTemplate.'
	Drop procedure [dbo].[ipw_InsertAdHocTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertAdHocTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertAdHocTemplate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psAlertCode		nvarchar(10),	-- Mandatory
	@psMessage		nvarchar(1000)	= null,
	@pnDaysDelete		smallint	= null,
	@pnDaysStopReminders	smallint	= null,
	@pnDaysLead		smallint	= null,
	@pnRepeatIntervalDays	smallint	= null,
	@pnMonthsLead		smallint	= null,
	@pnRepeatIntervalMonths	smallint	= null,
	@pbIsElectronicReminder	bit		= null,
	@psEmailSubject		nvarchar(100)	= null,
	@psImportanceLevelKey	nvarchar(2)	= null,
	@pbIsEmployee				bit		= null,
	@pbIsSignatory				bit		= null,
	@pbIsCriticalList			bit		= null,
	@psNameType				nvarchar(3)		= null,
	@psRelationship			nvarchar(3)		= null,
	@pnEmployeeNo				int		= null
)
as
-- PROCEDURE:	ipw_InsertAdHocTemplate
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert AdHocTemplate.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Dec 2005		RFC2939	1	Procedure created
-- 18 Jul 2011	LP	RFC10992 2	Increase @psAlertMessage parameter to 1000 characters.
-- 02 Dec 2011	DV	RFC996	 3	Add logic to update additional fields in ALERTTEMPLATE table. 

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into ALERTTEMPLATE
		(ALERTTEMPLATECODE,
		ALERTMESSAGE,
		DELETEALERT,
		STOPALERT, 
		DAYSLEAD, 
		DAILYFREQUENCY, 
		MONTHSLEAD, 
		MONTHLYFREQUENCY, 	
		SENDELECTRONICALLY, 
		EMAILSUBJECT, 
		IMPORTANCELEVEL,
		EMPLOYEEFLAG,
		SIGNATORYFLAG,
		CRITICALFLAG,
		NAMETYPE,
		RELATIONSHIP,
		EMPLOYEENO)
	values	(@psAlertCode, 
		@psMessage,
		@pnDaysDelete,
		@pnDaysStopReminders,
		@pnDaysLead,
		@pnRepeatIntervalDays,
		@pnMonthsLead,
		@pnRepeatIntervalMonths,
		@pbIsElectronicReminder,
		@psEmailSubject,
		@psImportanceLevelKey,
		@pbIsEmployee,
		@pbIsSignatory,
		@pbIsCriticalList,
		@psNameType,
		@psRelationship,
		@pnEmployeeNo)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psAlertCode		nvarchar(10),	
					@psMessage		nvarchar(1000),
					@pnDaysDelete		smallint,
					@pnDaysStopReminders	smallint,
					@pnDaysLead		smallint,
					@pnRepeatIntervalDays	smallint,
					@pnMonthsLead		smallint,
					@pnRepeatIntervalMonths	smallint,
					@pbIsElectronicReminder	bit,
					@psEmailSubject		nvarchar(100),
					@psImportanceLevelKey	nvarchar(2),
					@pbIsEmployee		bit,
					@pbIsSignatory	bit,
					@pbIsCriticalList	bit,
					@psNameType		nvarchar(3),
					@psRelationship	nvarchar(3),
					@pnEmployeeNo		int',
					@psAlertCode		= @psAlertCode,
					@psMessage		= @psMessage,
					@pnDaysDelete		= @pnDaysDelete,
					@pnDaysStopReminders	= @pnDaysStopReminders,
					@pnDaysLead		= @pnDaysLead,
					@pnRepeatIntervalDays	= @pnRepeatIntervalDays,
					@pnMonthsLead		= @pnMonthsLead,
					@pnRepeatIntervalMonths	= @pnRepeatIntervalMonths,
					@pbIsElectronicReminder	= @pbIsElectronicReminder,
					@psEmailSubject		= @psEmailSubject,
					@psImportanceLevelKey	= @psImportanceLevelKey,
					@pbIsEmployee			= @pbIsEmployee,
				    @pbIsSignatory		= @pbIsSignatory,
					@pbIsCriticalList		= @pbIsCriticalList,
					@psNameType			= @psNameType,
					@psRelationship		= @psRelationship,
					@pnEmployeeNo		= @pnEmployeeNo
									 
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertAdHocTemplate to public
GO