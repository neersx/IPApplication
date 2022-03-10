-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsAnyCaseRestrictedInBill
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsAnyCaseRestrictedInBill') and xtype='FN')
begin
	print '**** Drop function dbo.fn_IsAnyCaseRestrictedInBill.'
	drop function dbo.fn_IsAnyCaseRestrictedInBill
end
print '**** Creating function dbo.fn_IsAnyCaseRestrictedInBill...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_IsAnyCaseRestrictedInBill
	(
	        @pnItemTransNo		int,
	        @pnItemEntityNo		int
	)
RETURNS bit
as
-- FUNCTION :	fn_IsAnyCaseRestrictedInBill
-- VERSION  :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returns true if any case has restricted status in the bill
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2013	MS	R28045	1	Function created

Begin
	If exists (Select 1 from dbo.fn_GetBillCases(@pnItemTransNo,@pnItemEntityNo) BC
			join CASES C on (C.CASEID = BC.CASEID)
			left join STATUS S on (S.STATUSCODE = C.STATUSCODE)
			left join WORKINPROGRESS WIP on (WIP.CASEID = BC.CASEID) 
			where ISNULL(S.PREVENTBILLING,0) = 1 and WIP.CASEID is not null)
	Begin
		Return 1
	End
	
	Return 0
End
go

grant execute on dbo.fn_IsAnyCaseRestrictedInBill to public
GO


