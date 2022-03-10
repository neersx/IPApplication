-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_CreditBillValidation] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_CreditBillValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_CreditBillValidation].'
	drop procedure dbo.[biw_CreditBillValidation]
end
print '**** Creating procedure dbo.[biw_CreditBillValidation]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_CreditBillValidation]
				@pnUserIdentityId		int,				-- Mandatory
				@psCulture				nvarchar(10) 		= null,
				@pbCalledFromCentura	bit					= 0,
				@pnItemEntityNo			int,				-- Mandatory
				@pnItemTransNo			int,				-- Mandator
				@psOpenItemNo			nvarchar(12)			= null
				
				
as
-- PROCEDURE :	biw_CreditBillValidation
-- VERSION :	2
-- DESCRIPTION:	A procedure that validates the selected bill for reversal.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date			Who		RFC				Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 20/04/2010		KR		RFC8299		1		Procedure created
-- 24/07/2017		DV		RFC71743	2		Check if the bill does not contain a bill in advance WIP that is being used in a draft bill.

set nocount on

Declare		@ErrorCode		int
Declare		@sSQLString		nvarchar(4000)
Declare		@sAlertXML		nvarchar(400)
Declare		@nSumLocalValue		decimal(12,2)
Declare		@nSumLocalBalance	decimal(12,2)
Declare		@nCount			int
Declare		@nOpenItemNo	nvarchar(12)



Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	-- raise an error if the debit note has already been credited.
	If exists (Select * from OPENITEM Where OPENITEMNO = @psOpenItemNo and 
			ITEMENTITYNO = @pnItemEntityNo and ASSOCOPENITEMNO is not null)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC110', 'Debit Note has already been credited. Credit Note has been issued against this Debit Note. A second Credit Note cannot be issued.',null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @ErrorCode = @@ERROR
		
	End
	
	
	if (@ErrorCode = 0)
	Begin
		Set @sSQLString = 'Select  @nSumLocalValue = SUM(LOCALVALUE) , @nSumLocalBalance = SUM (LOCALBALANCE) 
		from OPENITEM where  ITEMENTITYNO = @pnItemEntityNo AND ITEMTRANSNO = @pnItemTransNo AND  ITEMTYPE = 510'
		
		exec	@ErrorCode = sp_executesql @sSQLString,
				N'@nSumLocalValue	decimal(12,2)		OUTPUT,
				@nSumLocalBalance	decimal(12,2)		OUTPUT,
				@pnItemEntityNo int,
				@pnItemTransNo int',
				@nSumLocalValue = @nSumLocalValue	OUTPUT,
				@nSumLocalBalance = @nSumLocalBalance	OUTPUT,
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo
				
		If (@nSumLocalValue != @nSumLocalBalance)
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC111', 'The amount and Balance of this bill differs.  Do you want to continue?',
								null, null, null, null, null)
			RAISERROR(@sAlertXML, 16, 1)
			Set @ErrorCode = @@ERROR
		End
	End
	
	If (@ErrorCode = 0)
	Begin
		Set @sSQLString =  'Select @nCount = count(*) from OPENITEM where ITEMTYPE IN (510,513) 
				and ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo
				group by ITEMENTITYNO, ITEMTRANSNO'
		exec	@ErrorCode = sp_executesql @sSQLString,
					N'@nCount int OUTPUT,
					@pnItemEntityNo int,
					@pnItemTransNo int',
					@nCount = @nCount OUTPUT,
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo
	End
	
	If ( @ErrorCode = 0 and @nCount > 1)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC112', 'The bill selected for credit is part of a multi debtor bill.  This process will raise credit notes for all bills that make up this multi debtor bill. Do you want to continue?',null, null, null, null, null)
		RAISERROR(@sAlertXML, 16, 1)
		Set @ErrorCode = @@ERROR

	End

	If (@ErrorCode = 0)
	Begin
		Set @sSQLString =  'SELECT @nOpenItemNo = OI.OPENITEMNO
								from OPENITEM OI
								join BILLEDITEM BI on (BI.ENTITYNO = OI.ITEMENTITYNO and BI.TRANSNO = OI.ITEMTRANSNO) 
								join WORKINPROGRESS W on (BI.WIPENTITYNO = W.ENTITYNO and BI.WIPTRANSNO = W.TRANSNO and BI.WIPSEQNO = W.WIPSEQNO) 
							where OI.STATUS = 0
								and OI.ITEMTYPE = 510 
								and W.TRANSNO = @pnItemTransNo
								and W.ENTITYNO = @pnItemEntityNo
								and W.GENERATEDINADVANCE = 1
								and W.STATUS = 2'
		exec	@ErrorCode = sp_executesql @sSQLString,
					N'@nOpenItemNo nvarchar(12) OUTPUT,
					@pnItemEntityNo int,
					@pnItemTransNo int',
					@nOpenItemNo = @nOpenItemNo OUTPUT,
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo
	End
	
	If ( @ErrorCode = 0 and @nOpenItemNo is not null)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC153', 'The selected bill cannot be credited as it includes a ''Bill in Advance'' item and the matching (credit) transaction is locked on the draft bill {0}.',@nOpenItemNo, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @ErrorCode = @@ERROR
	End

	
End

return @ErrorCode
go

grant execute on dbo.[biw_CreditBillValidation]  to public
go
