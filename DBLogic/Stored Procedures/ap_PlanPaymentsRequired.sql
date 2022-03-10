-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_PlanPaymentsRequired
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_PlanPaymentsRequired]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_PlanPaymentsRequired.'
	Drop procedure [dbo].[ap_PlanPaymentsRequired]
End
Print '**** Creating Stored Procedure dbo.ap_PlanPaymentsRequired...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_PlanPaymentsRequired
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnPaymentPlanKey	int
)
as
-- PROCEDURE:	ap_PlanPaymentsRequired
-- VERSION:	8
-- SCOPE:	Inprotech
-- DESCRIPTION:	Retrieve details that will be used to produce Bank Draft report,
--	 	a list of payments to be paid to different supplier.
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 07 NOV 2003	SFOO			1	Procedure created.
-- 27 NOV 2003	SFOO			2   Include Payment Method.
-- 12 DEC 2003	SFOO			3 	Change sorting order by Payment Method.
-- 13 MAR 2003	AT	SQA11987	4	Output BSB instead of Branch Name No.
-- 09 Dec 2008	MF	17136		5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 10 Sep 2009	CR	SQA8819		6	Updated joins to CREDITORITEM and CREDITORHISTORY to cater for
--									Unallocated Payments recorded using the Credit Card method 
--									(i.e. two Creditor Items created with the same TransId)
-- 16 May 2012	CR	16196		7	Consolidate System Defined Payment Methods - update references.
-- 02 Nov 2015	vql	R53910		8	Adjust formatted names logic (DR-15543).

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	Declare	@nErrorCode		int
	Declare @sSql			nvarchar(4000)
	Declare @IDC_PAYMENT_E_TRANSFER	int
	Declare @IDC_PAYMENT_BANKDRAFT	int
	Declare @nPaymentMethod		int
	
	-- Initialise variables
	Set @nErrorCode = 0
	Set @IDC_PAYMENT_E_TRANSFER = -5
	Set @IDC_PAYMENT_BANKDRAFT = -2
	
	Select @nPaymentMethod=PAYMENTMETHOD
	From PAYMENTPLAN
	Where PLANID = @pnPaymentPlanKey
	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin
		Set @sSql = N' Select
				PP.PLANID,
				PP.PLANNAME,
				CONVERT( nvarchar(254), dbo.fn_FormatNameUsingNameNo(EN.NAMENO, DEFAULT) ) AS ENTITY,
				CONVERT( nvarchar(254), dbo.fn_FormatNameUsingNameNo(CN.NAMENO, DEFAULT) ) AS PAYEE,
				CASE WHEN PPD.CURRENCY IS NULL THEN
					SCC.COLCHARACTER
				ELSE
					PPD.CURRENCY
				END AS CURRENCY,
				PPD.TOTALPAYMENTAMOUNT,
				PP.PAYMENTMETHOD,
				CASE WHEN PP.PAYMENTMETHOD = @IDC_PAYMENT_E_TRANSFER THEN
					CONVERT( nvarchar(254), dbo.fn_FormatNameUsingNameNo(CBN.NAMENO, DEFAULT) )
				ELSE
					NULL
				END AS CREDITORBANKNAME,
				CASE WHEN PP.PAYMENTMETHOD = @IDC_PAYMENT_E_TRANSFER THEN
					CBA.ACCOUNTNO
				ELSE
					NULL
				END AS CREDITORACCTNO,
				CASE WHEN PP.PAYMENTMETHOD = @IDC_PAYMENT_E_TRANSFER THEN
					CBA.BANKBRANCHNO
				ELSE
					NULL
				END AS CREDITORBRANCHNAMENO,
				CASE WHEN PP.PAYMENTMETHOD = @IDC_PAYMENT_E_TRANSFER THEN
					CBA.ACCOUNTNAME
				ELSE
					NULL
				END AS CREDITORACCTNAME,
				CONVERT( nvarchar(254), dbo.fn_FormatNameUsingNameNo(EBN.NAMENO, DEFAULT) ) AS ENTITYBANKNAME,
				EBA.ACCOUNTNO,
				EBA.BANKBRANCHNO,
				EBA.ACCOUNTNAME
			from
				PAYMENTPLAN PP
					INNER JOIN
				NAME EN ON (EN.NAMENO = PP.ENTITYNO)			-- Entity of the payment plan
					INNER JOIN
				(
					SELECT PPD.PLANID, PPD.ACCTCREDITORNO, CI.CURRENCY, SUM(PPD.PAYMENTAMOUNT) AS TOTALPAYMENTAMOUNT
					FROM PAYMENTPLANDETAIL PPD
					JOIN CREDITORITEM CI ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO AND
							    CI.ITEMTRANSNO = PPD.ITEMTRANSNO AND
								CI.ACCTENTITYNO = PPD.ACCTENTITYNO AND
								CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
					GROUP BY PPD.PLANID, PPD.ACCTCREDITORNO, CI.CURRENCY
				) PPD ON (PPD.PLANID = PP.PLANID)
					INNER JOIN
				CREDITOR C ON (C.NAMENO = PPD.ACCTCREDITORNO)
					INNER JOIN					-- Creditor name
				NAME CN ON (CN.NAMENO = C.NAMENO)
					LEFT OUTER JOIN 				-- Creditor bank account
				BANKACCOUNT CBA ON (CBA.ACCOUNTOWNER = C.BANKACCOUNTOWNER AND
						    CBA.BANKNAMENO = C.BANKNAMENO AND
						    CBA.SEQUENCENO = C.BANKSEQUENCENO)
					LEFT OUTER JOIN	        			-- Creditor Bank name
				NAME CBN ON (CBN.NAMENO = CBA.BANKNAMENO)
					INNER JOIN					-- Entity bank account
				BANKACCOUNT EBA ON (EBA.ACCOUNTOWNER = PP.ENTITYNO AND
						    EBA.BANKNAMENO = PP.BANKNAMENO AND
						    EBA.SEQUENCENO = PP.BANKSEQUENCENO)
					INNER JOIN	        			-- Entity Bank name
				NAME EBN ON (EBN.NAMENO = EBA.BANKNAMENO)
					CROSS JOIN					-- Local Currency
				(SELECT DISTINCT COLCHARACTER
				 FROM SITECONTROL
				 WHERE CONTROLID = ''CURRENCY'') SCC  -- delimit single quote
			where
				PP.PLANID = @pnPaymentPlanKey
			order by '
			
		If @nPaymentMethod = @IDC_PAYMENT_BANKDRAFT
			Set @sSql = @sSql + 'CURRENCY, PAYEE'
		Else
			Set @sSql = @sSql + 'PAYEE, CURRENCY'

		--print @sSql
		EXECUTE sp_executesql @sSql, 
			      N'@pnPaymentPlanKey          int,
			        @IDC_PAYMENT_E_TRANSFER int',
			        @pnPaymentPlanKey,
			        @IDC_PAYMENT_E_TRANSFER
		Set @nErrorCode = @@ERROR
	End
	
	Return @nErrorCode
End
GO

Grant execute on dbo.ap_PlanPaymentsRequired to public
GO
