-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetPostPeriod
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetPostPeriod') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetPostPeriod'
	Drop function [dbo].[fn_GetPostPeriod]
End
Print '**** Creating Function dbo.fn_GetPostPeriod...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetPostPeriod
(
	@pdtTransactionDate	datetime,
	@pnAccountingSystemID	int
--			1 - Inprotech (i.e. charge generation)
--			2 - Time and Billing
--			4 - Accounts Receivable
--			8 - Accounts Payable
--			16 - Cash Book
--			32 - General Ledger
) 
RETURNS int
AS
-- Function :	fn_GetPostPeriod
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the accounting period to which an accounting
--		transaction is to be posted.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2005	JEK	RFC2556		1	Function created
-- 31 Oct 2018	vql	DR-45102	2	remove control characters from functions.

Begin
	declare @nPeriodID	int

	select @nPeriodID = min(P.PERIODID)
	from PERIOD P
	where 	isnull(P.CLOSEDFOR,0)&@pnAccountingSystemID = 0
	-- ignore any time component by checking for > next day
	and	dateadd(d,1,P.ENDDATE) > @pdtTransactionDate

	return @nPeriodID
End
GO

grant execute on dbo.fn_GetPostPeriod to public
go
