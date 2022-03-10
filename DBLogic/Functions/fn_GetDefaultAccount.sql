-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDefaultAccount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetDefaultAccount') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_GetDefaultAccount'
	Drop function [dbo].[fn_GetDefaultAccount]
End
Print '**** Creating Function dbo.fn_GetDefaultAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetDefaultAccount
(
	@pnPlanId		int
) 
RETURNS @tblOutputRequests 	TABLE
(
	 CONTROLACCTYPEID	int,
	 ENTITYNO		int,
	 ACCOUNTID 		int,
	 PROFITCENTRECODE 	nvarchar(6) collate database_default 
)
AS
-- Function :	fn_GetDefaultAccount
-- VERSION :	4
-- DESCRIPTION:	Return list of default accounts based on the supplied plan. 
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	----------------------------------------------- 
-- 23 July 2004	MB	SQA9735		1	Function created
-- 28 July 2004	MB	SQA9735		2	Change @pnPlanIn to @pnPlanId
-- 16 Oct 2008	CR	SQA10514	3	Tidy up logic and correct collation problem
-- 10 Nov 2009	CG	14697	4	Add collate database_default to temp table

Begin
Declare @nAccountId 		int
Declare @sProfitCentreCode	nvarchar(6)
Declare @nEntityNo 		int

if @pnPlanId is not null
Begin
	Set @nAccountId = null
	Set @sProfitCentreCode = null
	Set @nEntityNo = null

-- Ledger Account and Profit Centre to be used for the Bank Control Account Type
	Select @nAccountId = CABACCOUNTID ,
		@sProfitCentreCode = CABPROFITCENTRE ,
		@nEntityNo = B.ENTITYNO
	from BANKACCOUNT A 
	join PAYMENTPLAN B 	on (A.ACCOUNTOWNER = B.ENTITYNO 
				and A.BANKNAMENO = B.BANKNAMENO 
				and A.SEQUENCENO = B.BANKSEQUENCENO )
	where B.PLANID = @pnPlanId

	If @nAccountId is null
		select @nAccountId = ACCOUNTID,
			@sProfitCentreCode = PROFITCENTRECODE,
			@nEntityNo = A.ENTITYNO
		from DEFAULTACCOUNT A 
		join PAYMENTPLAN B	on A.ENTITYNO = B.ENTITYNO
		where CONTROLACCTYPEID = 8701
		and B.PLANID = @pnPlanId

	Insert into @tblOutputRequests ( CONTROLACCTYPEID, ENTITYNO, ACCOUNTID, PROFITCENTRECODE) 
	values (8701, @nEntityNo, @nAccountId, @sProfitCentreCode )

-- Ledger Account and Profit Centre to be used for the Bank Charges Control Account Type
	Select @nAccountId = CABCACCOUNTID ,
		@sProfitCentreCode = CABCPROFITCENTRE,
		@nEntityNo = B.ENTITYNO
	from BANKACCOUNT A 
	join PAYMENTPLAN B 	on (A.ACCOUNTOWNER = B.ENTITYNO 
				and A.BANKNAMENO = B.BANKNAMENO 
				and A.SEQUENCENO = B.BANKSEQUENCENO )
	where B.PLANID = @pnPlanId

	if @nAccountId is null
		select @nAccountId = ACCOUNTID,
			@sProfitCentreCode = PROFITCENTRECODE,
			@nEntityNo = A.ENTITYNO
		from 	DEFAULTACCOUNT A 
		join PAYMENTPLAN B	on A.ENTITYNO = B.ENTITYNO
		where CONTROLACCTYPEID = 8705
		and B.PLANID = @pnPlanId

	Insert into @tblOutputRequests ( CONTROLACCTYPEID, ENTITYNO, ACCOUNTID, PROFITCENTRECODE) 
	values(8705, @nEntityNo, @nAccountId, @sProfitCentreCode )


-- Ledger Account and Profit Centre to be used for the all other Control Account Types
	Insert into @tblOutputRequests ( CONTROLACCTYPEID, ENTITYNO, ACCOUNTID, PROFITCENTRECODE) 
	select A.CONTROLACCTYPEID, A.ENTITYNO, A.ACCOUNTID, A.PROFITCENTRECODE 
	from DEFAULTACCOUNT A 
	join PAYMENTPLAN B	on A.ENTITYNO = B.ENTITYNO 
	where B.PLANID = @pnPlanId
	and CONTROLACCTYPEID NOT IN ( 8701,8705)
End	
Return
End
GO

grant REFERENCES, SELECT on dbo.fn_GetDefaultAccount to public
go
