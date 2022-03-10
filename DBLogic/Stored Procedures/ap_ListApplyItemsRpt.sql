-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListApplyItemsRpt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ListApplyItemsRpt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ListApplyItemsRpt.'
	Drop procedure [dbo].[ap_ListApplyItemsRpt]
End
Print '**** Creating Stored Procedure dbo.ap_ListApplyItemsRpt...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_ListApplyItemsRpt
(
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnEntityNo			int,
	@psIncludeTransNos		nvarchar(100),		-- The filtering to be performed on the result set
	@pbPayableOffsetMode		bit,
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)
as
-- PROCEDURE:	ap_ListApplyItemsRpt
-- VERSION:	6
-- SCOPE:	InPro
-- DESCRIPTION:	Returns Apply Items Report details based on a string of comma separated RefTransNos
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 May 2005	AT	9716	1	Procedure created
-- 08 Jun 2005	AT	9716	2	Fixed bugs
-- 27 Jun 2005	AT	11506	3	Fixed bugs
-- 17 Mar 2008	AT	14523	4	Return negative amounts for supplier receipts.
-- 12 May 2014	DL	21847	5	Apply Item Report doubles the debtor invoice amount
-- 23 Jul 2015	DL	48744	6	Incorrect journal entries created for AR/AP offset transactions

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSql	nvarchar(4000)
-- Initialise variables
Set @nErrorCode = 0

Begin
	If @pbPayableOffsetMode = 1
	Begin
		--Get the Credit Notes
		Set @sSql= "Select ED.SUPPLIERACCOUNTNO,
			N.NAMECODE, 
			cast(dbo.fn_GetMailingLabel(N.NAMENO, 'PAY') as nvarchar(254)) as MAILINGLABEL,
			cast(dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION) as nvarchar(50)) as FAXNO,
			ISNULL(CHAI.POSTDATE, CHAI.TRANSDATE),
			CHAI.REFTRANSNO,
			ISNULL(CHAI.DESCRIPTION, CHAI.LONGDESCRIPTION),
			CHAI.STATUS,
			CHAI.TRANSDATE, CHAI.DOCUMENTREF,
			ISNULL(CDESC.DESCRIPTION, CDESC.LONGDESCRIPTION),
			CT.LOCALVALUE, CT.LOCALBALANCE,
			CT.FOREIGNTRANVALUE, CT.FOREIGNBALANCE,
			CT.EXCHVARIANCE, CT.CURRENCY, CT.TRANSTYPE
			FROM CREDITORHISTORY CHAI JOIN
			(SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTCREDITORNO, TRANSTYPE, REFTRANSNO,
				ABS(SUM(LOCALVALUE)) AS LOCALVALUE, ABS(SUM(LOCALBALANCE) - SUM(LOCALVALUE)) AS LOCALBALANCE,
				ABS(SUM(FOREIGNTRANVALUE)) AS FOREIGNTRANVALUE, ABS(SUM(FOREIGNBALANCE) - SUM(FOREIGNTRANVALUE)) AS FOREIGNBALANCE,
				ABS(SUM(EXCHVARIANCE)) AS EXCHVARIANCE, CURRENCY
				FROM CREDITORHISTORY
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTCREDITORNO, TRANSTYPE, REFTRANSNO, CURRENCY
				HAVING TRANSTYPE = 706) AS CT on ( CT.ITEMENTITYNO = CHAI.ITEMENTITYNO
								AND CT.ITEMTRANSNO = CHAI.ITEMTRANSNO
								AND CT.ACCTCREDITORNO = CHAI.ACCTCREDITORNO
								)
									
			join CREDITORHISTORY CDESC 	on (CDESC.ITEMTRANSNO = CT.ITEMTRANSNO
								and CDESC.ACCTCREDITORNO = CT.ACCTCREDITORNO
								and CDESC.TRANSTYPE = 706)
			join NAME N			on (N.NAMENO = CHAI.ACCTCREDITORNO)
			left join 
				(	SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION
					FROM NAME NT	
					join TELECOMMUNICATION T on (T.TELECODE = NT.FAX
										AND T.TELECOMTYPE = 1902)) as TC 
							On (TC.NAMENO = N.NAMENO)
			left join CRENTITYDETAIL ED	on (ED.NAMENO = N.NAMENO 
								and ED.ENTITYNAMENO = CHAI.ACCTENTITYNO)
			WHERE CHAI.REFTRANSNO in (" + @psIncludeTransNos + ")
			and CHAI.REFENTITYNO = " + cast(@pnEntityNo as nvarchar(15))
	End
	Else If @pbPayableOffsetMode = 0
	Begin
		-- AR/AP offset
		Set @sSql = "Select ED.SUPPLIERACCOUNTNO,
			N.NAMECODE, 
			cast(dbo.fn_GetMailingLabel(N.NAMENO, 'PAY') as nvarchar(254)) as MAILINGLABEL,
			cast(dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION) as nvarchar(50)) AS FAXNO,
			ISNULL(DHAI.POSTDATE, DHAI.TRANSDATE),
			DHAI.REFTRANSNO,
			DHAI.REFERENCETEXT,
			DHAI.STATUS,
			DHAI.TRANSDATE, O.OPENITEMNO,
			O.REFERENCETEXT,
			CT.LOCALVALUE, DHAI.LOCALBALANCE,
			CT.FOREIGNTRANVALUE, DHAI.FOREIGNBALANCE,
			CT.EXCHVARIANCE, CT.CURRENCY, CT.TRANSTYPE
			FROM DEBTORHISTORY DHAI JOIN
			(SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTDEBTORNO, TRANSTYPE, REFTRANSNO,
				(SUM(LOCALVALUE)*-1) AS LOCALVALUE, ((SUM(LOCALBALANCE) - SUM(LOCALVALUE))*-1) AS LOCALBALANCE,
				(SUM(FOREIGNTRANVALUE)*-1) AS FOREIGNTRANVALUE, ((SUM(FOREIGNBALANCE) - SUM(FOREIGNTRANVALUE))*-1) AS FOREIGNBALANCE,
				(SUM(EXCHVARIANCE)*-1) AS EXCHVARIANCE, CURRENCY
				FROM DEBTORHISTORY
				WHERE STATUS <> 9		-- excludes reverse items
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTDEBTORNO, TRANSTYPE, REFTRANSNO, CURRENCY
				HAVING TRANSTYPE = 710) AS CT on	(CT.ITEMENTITYNO = DHAI.ITEMENTITYNO
									AND CT.ITEMTRANSNO = DHAI.ITEMTRANSNO
									AND CT.ACCTDEBTORNO = DHAI.ACCTDEBTORNO
									AND CT.REFTRANSNO = DHAI.REFTRANSNO )
			join OPENITEM O			on (O.ITEMTRANSNO = CT.ITEMTRANSNO
								AND O.ACCTDEBTORNO = CT.ACCTDEBTORNO)
								
			join NAME N			on (N.NAMENO = DHAI.ACCTDEBTORNO)
			left join 
				(	SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION
					FROM NAME NT	
					join TELECOMMUNICATION T on (T.TELECODE = NT.FAX
										AND T.TELECOMTYPE = 1902)) TC 
							on (TC.NAMENO = N.NAMENO)
			left join CRENTITYDETAIL ED	on (ED.NAMENO = N.NAMENO 
							and ED.ENTITYNAMENO = DHAI.ACCTENTITYNO)
			WHERE DHAI.REFTRANSNO IN (" + @psIncludeTransNos + ")
			and DHAI.REFENTITYNO = " + cast(@pnEntityNo as nvarchar(15))
	End
	--Now get the invoices attached

	If @nErrorCode = 0
	Begin
		Set @sSql = @sSql + "
 
			UNION
	
			Select ED.SUPPLIERACCOUNTNO,
			N.NAMECODE, 
			cast(dbo.fn_GetMailingLabel(N.NAMENO, 'PAY') as nvarchar(254)) as MAILINGLABEL,
			cast(dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION) as nvarchar(254)) AS FAXNO,
			ISNULL(CHAI.POSTDATE, CHAI.TRANSDATE),
			CHAI.REFTRANSNO,
			ISNULL(CHAI.DESCRIPTION, CHAI.LONGDESCRIPTION),
			CHAI.STATUS,
			CHO.TRANSDATE, CHO.DOCUMENTREF,
			ISNULL(CHO.DESCRIPTION, CHO.LONGDESCRIPTION),
			(CHAI.LOCALVALUE*-1), 
			(CASE WHEN CHAI.LOCALBALANCE IS NULL THEN 0 ELSE (CHAI.LOCALBALANCE*-1) END),
			(CHAI.FOREIGNTRANVALUE*-1),
			(CASE WHEN CHAI.FOREIGNBALANCE IS NULL THEN 0 ELSE (CHAI.FOREIGNBALANCE*-1) END),
			(CHAI.EXCHVARIANCE*-1), CHAI.CURRENCY, CHO.TRANSTYPE
			FROM CREDITORHISTORY CHAI
			join CREDITORHISTORY CHO on (CHO.ITEMTRANSNO = CHAI.ITEMTRANSNO
							AND CHO.ITEMENTITYNO = CHAI.ITEMENTITYNO)
	
			join NAME N			on (N.NAMENO = CHAI.ACCTCREDITORNO)
			left join 
				(	SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION
					FROM NAME NT	
					join TELECOMMUNICATION T	on (T.TELECODE = NT.FAX
										AND T.TELECOMTYPE = 1902)) TC 
				On (TC.NAMENO = N.NAMENO)
			left join CRENTITYDETAIL ED	on (ED.NAMENO = N.NAMENO 
							and ED.ENTITYNAMENO = CHAI.ACCTENTITYNO)
			WHERE  CHO.TRANSTYPE in (700"

		If @pbPayableOffsetMode = 0 
		Begin
			Set @sSql = @sSql + ", 706"
		End
		
		Set @sSql = @sSql + ")
			AND CHAI.REFTRANSNO IN (" + @psIncludeTransNos + ")
			AND CHAI.REFENTITYNO = " + cast(@pnEntityNo as nvarchar(15)) + "
			order by 6, 18 desc"
	End

	EXEC @nErrorCode=sp_executesql @sSql
	set @pnRowCount=@@Rowcount

End

Return @nErrorCode
GO

Grant execute on dbo.ap_ListApplyItemsRpt to public
GO
