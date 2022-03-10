-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDefaultBillRefSingle] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDefaultBillRefSingle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDefaultBillRefSingle].'
	drop procedure dbo.[biw_GetDefaultBillRefSingle]
end
print '**** Creating procedure dbo.[biw_GetDefaultBillRefSingle]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDefaultBillRefSingle]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psMainCaseIRN			nvarchar(50),
				@psLanguageCode		nvarchar(5) = null,
				@psDebtorNameType	nvarchar(1) = null,
				@pnDebtorNo			int = null,
				@psOpenItemNo		nvarchar(12) = null
								
as
-- PROCEDURE :	biw_GetDefaultBillRefSingle
-- VERSION :	2
-- DESCRIPTION:	A procedure that returns the default Bill References
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605		1	Procedure created.
-- 17-Feb-2012	AT	RFC11307	2	Added new params to call to ipw_FetchDocItem for consistency.

set nocount on
set concat_null_yields_null off

Declare		@ErrorCode	int
Declare		@nRowCount	int
--Declare		@sSQLString	nvarchar(4000)

declare @sDebtorNo nvarchar(15)
Declare @sBillRefSingle nvarchar(40)
Declare @sStatementSingle nvarchar(40)

Set @sDebtorNo = cast(@pnDebtorNo as nvarchar(15))

/*:p1 - language code
:p2 - Debtor NameType - Renewal Debtor (Z) or Debtor (D)
:p3 - DebtorNo
:p4 - OpenItemNo*/

Set @ErrorCode = 0

If @ErrorCode = 0
Begin

	SELECT @sStatementSingle = COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Statement-Single'

	SELECT @sBillRefSingle = COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Bill Ref-Single'

	if (@sBillRefSingle is not null)
	Begin
		exec ipw_FetchDocItem @pnUserIdentityId=26,@psCulture=N'en-AU',@pbCalledFromCentura=NULL,
			@psDocItem=@sBillRefSingle,
			@psEntryPoint=@psMainCaseIRN,
			@psEntryPointP1=@psLanguageCode,
			@psEntryPointP2=@psDebtorNameType,
			@psEntryPointP3=@sDebtorNo,
			@psEntryPointP4=@psOpenItemNo,
			@bIsCSVEntryPoint=0,
			@pbOutputToVariable = 0,
			@psOutputString	= null
	End
	else
	Begin
		-- Return null in the first resultset
		Select null
	End

	if (@sStatementSingle is not null)
	Begin
		exec ipw_FetchDocItem @pnUserIdentityId=26,@psCulture=N'en-AU',@pbCalledFromCentura=NULL,
			@psDocItem=@sStatementSingle,
			@psEntryPoint=@psMainCaseIRN,
			@psEntryPointP1=@psLanguageCode,
			@psEntryPointP2=@psDebtorNameType,
			@psEntryPointP3=@sDebtorNo,
			@psEntryPointP4=@psOpenItemNo,
			@bIsCSVEntryPoint=0,
			@pbOutputToVariable = 0,
			@psOutputString	= null
	End
	Else
	Begin
		Select null
	End
End


return @ErrorCode
go

grant execute on dbo.[biw_GetDefaultBillRefSingle]  to public
go
