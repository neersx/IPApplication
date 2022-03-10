-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBillCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetBillCases') and xtype='TF')
begin
	print '**** Drop function dbo.fn_GetBillCases.'
	drop function dbo.fn_GetBillCases
end
print '**** Creating function dbo.fn_GetBillCases...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetBillCases
	(
	        @pnItemTransNo		int,
	        @pnItemEntityNo		int
	)
Returns @tbCases TABLE
   (      
	CASEID  		int		NOT NULL
   )

as
-- FUNCTION :	fn_GetBillCases
-- VERSION  :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returns CASES associated with the bill
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 May 2013	MS	R11732	1	Function created
-- 01 May 2013	vql	R11732	2	Add with (nolock) keyword.

Begin
        Declare	@bBillStatus	bit
        
        Select @bBillStatus = STATUS 
	From OPENITEM with (nolock)
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo 
	
	If  (@bBillStatus = 1 or @bBillStatus = 9)
	Begin
	        Insert into @tbCases
	        Select distinct C.CASEID
	        From OPENITEM OI with (nolock)
	        Join WORKHISTORY WH with (nolock) on (WH.REFTRANSNO = OI.ITEMTRANSNO and WH.REFENTITYNO = OI.ITEMENTITYNO)
		Join CASES C on (WH.CASEID = C.CASEID)
		Where OI.ITEMENTITYNO = @pnItemEntityNo
		and OI.ITEMTRANSNO = @pnItemTransNo
	End
	Else
	Begin
	        Insert into @tbCases
	        Select distinct C.CASEID
	        From OPENITEM OI with (nolock)
	        Join BILLEDITEM BI with (nolock) on (OI.ITEMTRANSNO = BI.ITEMTRANSNO and OI.ITEMENTITYNO = BI.ITEMENTITYNO)	
		Join WORKINPROGRESS WIP with (nolock) on (WIP.ENTITYNO = BI.WIPENTITYNO
						and WIP.TRANSNO = BI.WIPTRANSNO
						and WIP.WIPSEQNO = BI.WIPSEQNO)					
		Join CASES C on (WIP.CASEID = C.CASEID)
		Where OI.ITEMENTITYNO = @pnItemEntityNo
		and OI.ITEMTRANSNO = @pnItemTransNo
	End
	
	Return
End
go

grant REFERENCES, SELECT on dbo.fn_GetBillCases to public
GO