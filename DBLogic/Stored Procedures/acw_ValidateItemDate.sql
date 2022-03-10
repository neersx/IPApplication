-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_ValidateItemDate] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_ValidateItemDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_ValidateItemDate].'
	drop procedure dbo.[acw_ValidateItemDate]
end
print '**** Creating procedure dbo.[acw_ValidateItemDate]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_ValidateItemDate]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pdtItemDate		datetime,
				@pnContext		int -- the context of the validation
				
as
-- PROCEDURE :	acw_ValidateItemDate
-- VERSION :	3
-- DESCRIPTION:	A procedure that checks that a valid accounting period exists for a particular date
--				Contexts:
--				1 = Time/Billing
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 25/01/2010	AT	RFC3605		1	Procedure created.
-- 11/08/2011	AT	RFC10241	2	Validate Bill Dates Forward site control.
-- 12/11/2012   AK	RFC12544	3	Prevent finalize if bill date is future date
set nocount on

-- todo: VALIDATE AGAINST OPEN/CLOSED ACCOUNTING LEDGERS TOO

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
declare		@sAlertXML nvarchar(400)

declare @dtLastFinalisedDate datetime

Set @ErrorCode = 0

If (@pnContext = 1) -- Time/Billing
Begin
	If not exists (Select * from PERIOD WHERE dbo.fn_DateOnly(@pdtItemDate) BETWEEN STARTDATE AND ENDDATE)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC126', 'An accounting period could not be determined for the given date. Please check the period definitions and try again.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @ErrorCode = @@ERROR
	End
	
	If exists (select * from SITECONTROL WHERE CONTROLID = 'BillDatesForwardOnly' and COLBOOLEAN = 1)
	Begin
		-- Note the same code exists in biw_GetBillingSettings
		Set @sSQLString = "select @dtLastFinalisedDate = MAX(dbo.fn_DateOnly(ITEMDATE))
				from OPENITEM 
				WHERE STATUS = 1
				AND ITEMTYPE IN (510, 511, 513, 514)"
				
		exec @ErrorCode = sp_executesql @sSQLString,
					N'@dtLastFinalisedDate datetime output',
					@dtLastFinalisedDate = @dtLastFinalisedDate output
		
		if (dbo.fn_DateOnly(@dtLastFinalisedDate) > dbo.fn_DateOnly(@pdtItemDate))
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC207', 'The item date cannot be earlier than the last finalised item date.',
												null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @ErrorCode = @@ERROR
		End
	End
End


If (@ErrorCode=0 and dbo.fn_DateOnly(@pdtItemDate)> dbo.fn_DateOnly(getdate()))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('BI26', 'The item date cannot be in the future.',
										null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @ErrorCode = @@ERROR		
End

return @ErrorCode
go

grant execute on dbo.[acw_ValidateItemDate]  to public
go