-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_DisbursementSlip
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_DisbursementSlip]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_DisbursementSlip.'
	Drop procedure [dbo].[ap_DisbursementSlip]
End
Print '**** Creating Stored Procedure dbo.ap_DisbursementSlip...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_DisbursementSlip
(
	@psDisbSlipTempTable	nvarchar(30),	-- The name of the temporary table used
	@pnDisbSource		smallint	-- IDC_AD_MANUAL_PAYMENT=1; IDC_AD_PURCHASE=4
)

as
-- PROCEDURE:	ap_DisbursementSlip
-- VERSION:	2
-- SCOPE:	InProtech
-- DESCRIPTION:	Updates values in @psDisbSlipTempTable temporary table based on 
--		pre-populated Trans/Entity numbers. 
--		Returns results to Accounts Payable for Disbursement Slip Report.
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 08 Aug 2004	AT	SQA9691		1	Procedure created
-- 09 Jun 2010	DL	SQA17778	2	Cater for disbursement from manual payments.

Begin

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(3000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and @pnDisbSource = 1  -- Manual Payment
Begin
	-- Update rows already in the temporary table
	Set @sSQLString="
	UPDATE " + @psDisbSlipTempTable + "
	SET	ENTITYNAME = EN.NAME,
		TRANSNO = C.TRANSNO,
		WIPSEQNO = W.WIPSEQNO,
		CASEID = CA.CASEID,
		CASEIRN = CA.IRN,
		DEBTOR = CAST(DN.NAME + Case	when DN.NAMECODE is NULL then NULL
						else ' {' + DN.NAMECODE + '}' 
					end as NVARCHAR(254)),
		STAFF = SN.NAMECODE,
		WIPCODE = W.WIPCODE,
		WIPDESC = WT.DESCRIPTION,
		CURRENCY = 	Case 	when C.DISSECTIONCURRENCY is not null then C.DISSECTIONCURRENCY
					else SC.COLCHARACTER
				end,
		EXCHRATE = W.EXCHRATE,
		AMOUNT = Case 	when W.FOREIGNTRANVALUE is not null then W.FOREIGNTRANVALUE
				else W.LOCALTRANSVALUE
			 end,
		DOCUMENTNO = C.ITEMREFNO,
		DOCUMENTDATE = C.TRANSDATE,
		SUPPLIERNAME = SUPN.NAME,
		SUPPLIERNAMECODE = SUPN.NAMECODE
	from 	" + @psDisbSlipTempTable + " DTP

		left join CASHHISTORY C		on (C.ENTITYNO = DTP.ENTITYNO
						and C.TRANSNO = DTP.TRANSNO)

		join NAME EN 			on (C.ENTITYNO = EN.NAMENO)
		join WORKHISTORY W 		on (W.ENTITYNO = DTP.ENTITYNO
						and W.TRANSNO = DTP.TRANSNO
						and W.WIPSEQNO = DTP.WIPSEQNO)
		left join CASENAME CN 		on (CN.CASEID = W.CASEID
						and CN.NAMETYPE = 'D')
		join WIPTEMPLATE WT 		on (WT.WIPCODE = W.WIPCODE)
		left join CASES CA 		on (CA.CASEID = W.CASEID)
		left join NAME SN 		on (SN.NAMENO = W.EMPLOYEENO)
		left join NAME DN 		on (DN.NAMENO = Case 	when W.ACCTCLIENTNO is NULL 
									then CN.NAMENO 
									else W.ACCTCLIENTNO 
								end)
		join NAME SUPN 			on (SUPN.NAMENO = C.ACCTNAMENO)
		join SITECONTROL SC 		on (SC.CONTROLID = 'CURRENCY')"
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

Else If @nErrorCode = 0 and @pnDisbSource = 4  -- Purchase
Begin
	-- Update rows already in the temporary table
	Set @sSQLString="
	UPDATE " + @psDisbSlipTempTable + "
	SET	ENTITYNAME = EN.NAME,
		TRANSNO = C.ITEMTRANSNO,
		WIPSEQNO = W.WIPSEQNO,
		CASEID = CA.CASEID,
		CASEIRN = CA.IRN,
		DEBTOR = CAST(DN.NAME + Case	when DN.NAMECODE is NULL then NULL
						else ' {' + DN.NAMECODE + '}' 
					end as NVARCHAR(254)),
		STAFF = SN.NAMECODE,
		WIPCODE = W.WIPCODE,
		WIPDESC = WT.DESCRIPTION,
		CURRENCY = 	Case 	when C.CURRENCY is not null then C.CURRENCY
					else SC.COLCHARACTER
				end,
		EXCHRATE = W.EXCHRATE,
		AMOUNT = Case 	when W.FOREIGNTRANVALUE is not null then W.FOREIGNTRANVALUE
				else W.LOCALTRANSVALUE
			 end,
		DOCUMENTNO = C.DOCUMENTREF,
		DOCUMENTDATE = C.TRANSDATE,
		SUPPLIERNAME = SUPN.NAME,
		SUPPLIERNAMECODE = SUPN.NAMECODE
	from 	" + @psDisbSlipTempTable + " DTP
		left join CREDITORHISTORY C 	on (C.ITEMENTITYNO = DTP.ENTITYNO
						and C.ITEMTRANSNO = DTP.TRANSNO)
		join NAME EN 			on (C.ITEMENTITYNO = EN.NAMENO)
		join WORKHISTORY W 		on (W.ENTITYNO = DTP.ENTITYNO
						and W.TRANSNO = DTP.TRANSNO
						and W.WIPSEQNO = DTP.WIPSEQNO)
		left join CASENAME CN 		on (CN.CASEID = W.CASEID
						and CN.NAMETYPE = 'D')
		join WIPTEMPLATE WT 		on (WT.WIPCODE = W.WIPCODE)
		left join CASES CA 		on (CA.CASEID = W.CASEID)
		left join NAME SN 		on (SN.NAMENO = W.EMPLOYEENO)
		left join NAME DN 		on (DN.NAMENO = Case 	when W.ACCTCLIENTNO is NULL 
									then CN.NAMENO 
									else W.ACCTCLIENTNO 
								end)
		join NAME SUPN 			on (SUPN.NAMENO = C.ACCTCREDITORNO)
		join SITECONTROL SC 		on (SC.CONTROLID = 'CURRENCY')"
	
	Exec @nErrorCode=sp_executesql @sSQLString
End


If (@nErrorCode = 0)
Begin
-- Return the results
-- SQA17778 added subselect to eliminate duplicates as there are multiple CASHITEMHISTORY rows for the same transaction.
	Set @sSQLString = "
	Select 	ENTITYNAME,
		TRANSNO,
		CASEIRN,
		DEBTOR,
		STAFF,
		WIPDESC,
		CURRENCY,
		EXCHRATE,
		AMOUNT,
		DOCUMENTNO,
		DOCUMENTDATE,
		SUPPLIERNAME,
		SUPPLIERNAMECODE
	from		
		( Select distinct * 
		from " + @psDisbSlipTempTable +	") as temp
	order by TRANSNO, CASEID, DEBTOR, WIPCODE"

	Exec @nErrorCode=sp_executesql @sSQLString
End


Return @nErrorCode

End
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Grant execute on dbo.ap_DisbursementSlip to public
GO
