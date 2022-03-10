-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetAgentInvoiceStatus
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetAgentInvoiceStatus') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetAgentInvoiceStatus.'
	drop function dbo.fn_GetAgentInvoiceStatus
end
print '**** Creating function dbo.fn_GetAgentInvoiceStatus...'
print ''
go

set QUOTED_IDENTIFIER off
go



Create Function dbo.fn_GetAgentInvoiceStatus
			(
			@pnEntityNo	int,
			@pnTransNo	int
			)
Returns int

-- FUNCTION :	fn_GetAgentInvoiceStatus
-- VERSION :	2
-- DESCRIPTION:	This function determines whether WIP disbursed from agent's invoices have 
--		been billed or paid.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version Description
-- -----------	-------	--------	------- ----------------------------------------------- 
-- 15 Jun 2010	DL	SQA17110	1	Function created.
-- 13 Jul 2011	DL	SQA19566	2	Cater for Credit Full Bill invoices.

as
Begin
	Declare @bFullyBilled		bit
	Declare @bPartiallyBilled	bit
	Declare @bFullyPaid		bit
	Declare @bPartiallyPaid		bit
	Declare @nStatus		int


	Select 	@bPartiallyBilled=case when (BILLED <> 0 and UNBILLED <> 0 )then 1 else 0 end,  
	@bFullyBilled = case when BILLED <> 0 and UNBILLED = 0 then 1 else 0 end,				
	@bPartiallyPaid = case when O_LOCALBALANCE <> O_LOCALVALUE  and O_LOCALBALANCE <> 0 then 1 else 0 end, 
	@bFullyPaid = case when O_LOCALBALANCE = 0 and O_LOCALVALUE <> 0 then 1 else 0 end 
	from (
		Select 	SUM(BILLED) AS BILLED,
		SUM(UNBILLED) AS UNBILLED,
		SUM(O_LOCALVALUE) AS O_LOCALVALUE,
		SUM(O_LOCALBALANCE) AS O_LOCALBALANCE
		from (
			-- Get total billed and unbilled amount
			Select WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO,
			sum(case when WH.TRANSTYPE in (510, 512, 511, 513) then WH.LOCALTRANSVALUE else 0 end) BILLED,
			SUM(WH.LOCALTRANSVALUE) UNBILLED,
			0 O_LOCALVALUE,
			0 O_LOCALBALANCE
			from WORKHISTORY WH
			where WH.ENTITYNO = @pnEntityNo
			AND WH.TRANSNO = @pnTransNo
			group by WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO

			Union all

			-- Get item value and balance of billed transactions to determine paid status
			Select WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO,
			0 BILLED,
			0 UNBILLED,
			sum(O.LOCALVALUE) O_LOCALVALUE,
			sum(O.LOCALBALANCE) O_LOCALBALANCE
			from WORKHISTORY WH
			LEFT JOIN OPENITEM O ON O.ITEMTRANSNO = WH.REFTRANSNO AND O.STATUS = 1 -- POSTED
			where WH.ENTITYNO = @pnEntityNo
			AND WH.TRANSNO = @pnTransNo
			AND WH.TRANSTYPE in (510, 512, 511, 513) --(510,512=Billed); (511,513=Credit Full Bill)
			group by WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO
		) TEMP
	) TEMP2

	If @bFullyPaid = 1
		set @nStatus = 4
	Else if @bPartiallyPaid = 1
		set @nStatus = 3
	Else if @bFullyBilled = 1
		set @nStatus = 2
	Else if @bPartiallyBilled = 1
		set @nStatus = 1
	Else 
		set @nStatus = 0 -- associated WIPs are not billed.

	Return @nStatus		
End
go

grant execute on dbo.fn_GetAgentInvoiceStatus to public
go
