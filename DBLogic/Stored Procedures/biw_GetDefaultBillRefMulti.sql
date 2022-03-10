-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDefaultBillRefMulti] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDefaultBillRefMulti]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDefaultBillRefMulti].'
	drop procedure dbo.[biw_GetDefaultBillRefMulti]
end
print '**** Creating procedure dbo.[biw_GetDefaultBillRefMulti]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDefaultBillRefMulti]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psIRNCSV			nvarchar(500),
				@psLanguageCode		nvarchar(5) = null,
				@psDebtorNameType	nvarchar(1) = null,
				@pnDebtorNo			int = null,
				@psOpenItemNo		nvarchar(12) = null,
				@psControlIdLike		nvarchar(30) = null
								
as
-- PROCEDURE :	biw_GetDefaultBillRefMulti
-- VERSION :	2
-- DESCRIPTION:	A procedure that returns the default Bill References/Statement text for a multi-case bill
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 01-Mar-2009	AT	RFC3605		1	Procedure created.
-- 17-Feb-2012	AT	RFC11307	2	Added new params to call to ipw_FetchDocItem for consistency.

set nocount on
set concat_null_yields_null off

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare @sMainCaseIRN nvarchar(50)
declare @sDebtorNo nvarchar(15)
Declare @sBillRefDocItem nvarchar(40)
Declare @sControlId	nvarchar(50)

Set @sDebtorNo = cast(@pnDebtorNo as nvarchar(15))

/*:p1 - language code
:p2 - Debtor NameType - Renewal Debtor (Z) or Debtor (D)
:p3 - DebtorNo
:p4 - OpenItemNo*/

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	If (@psControlIdLike is null)
	Begin
		Set @psControlIdLike = 'Bill Ref-Multi%'
	End

/*
	-- If Multi 0 or 9, exec for main case only (first case)
	-- If Multi 1-8, scroll through all cases and exec doc item
*/

	DECLARE BillRef_Cursor CURSOR FOR 
		SELECT CONTROLID, COLCHARACTER 
		FROM SITECONTROL 
		WHERE CONTROLID like @psControlIdLike
		and COLCHARACTER IS NOT NULL
		ORDER BY 1

	Select @sMainCaseIRN = MC.Parameter from 
		(select top 1 Parameter from dbo.fn_Tokenise(@psIRNCSV,',') order by 1) as MC

	OPEN BillRef_Cursor

	FETCH NEXT FROM BillRef_Cursor 
	INTO @sControlId, @sBillRefDocItem

	WHILE (@ErrorCode = 0 and @@FETCH_STATUS = 0)
	Begin
		-- Process Doc Item for first case
		
		if (right(@sControlId,1) in ('0','9'))
		Begin
			-- Process only main case for first and last doc items
			exec @ErrorCode = ipw_FetchDocItem @pnUserIdentityId=26,@psCulture=N'en-AU',@pbCalledFromCentura=NULL,
								@psDocItem=@sBillRefDocItem,
								@psEntryPoint=@sMainCaseIRN,
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
			-- Process all items
			exec @ErrorCode = ipw_FetchDocItem @pnUserIdentityId=26,@psCulture=N'en-AU',@pbCalledFromCentura=NULL,
								@psDocItem=@sBillRefDocItem,
								@psEntryPoint=@psIRNCSV,
								@psEntryPointP1=@psLanguageCode,
								@psEntryPointP2=@psDebtorNameType,
								@psEntryPointP3=@sDebtorNo,
								@psEntryPointP4=@psOpenItemNo,
								@bIsCSVEntryPoint=1,
								@pbOutputToVariable = 0,
								@psOutputString	= null
		End

		FETCH NEXT FROM BillRef_Cursor 
		INTO @sControlId, @sBillRefDocItem
	End

	CLOSE BillRef_Cursor
	DEALLOCATE BillRef_Cursor

End

return @ErrorCode
go

grant execute on dbo.[biw_GetDefaultBillRefMulti]  to public
go
