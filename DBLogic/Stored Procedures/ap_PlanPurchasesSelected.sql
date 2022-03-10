-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_PlanPurchasesSelected
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ap_PlanPurchasesSelected]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop procedure dbo.ap_PlanPurchasesSelected.'
	Drop procedure dbo.ap_PlanPurchasesSelected
end
Print '**** Creating procedure dbo.ap_PlanPurchasesSelected...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ap_PlanPurchasesSelected
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnPlanId			int		= null
)
AS

-- PROCEDURE :	ap_PlanPurchasesSelected
-- VERSION :	7
-- DESCRIPTION:	the procedure is used by the Payment Plan Details report
-- SCOPE:	AP
-- CALLED BY :	Centura
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 24/04/2003	CR	1	Procedure created
-- 09/04/2003	CR	2	Updated to also return Name and NameNo of the entity.  Added Creditor Name to the Order by
-- 14/07/2003	CR	3	updated to include outstanding credit notes for the suppliers included.
-- 25/11/2003	SFOO	4	Updated to include Payment Currency and Outstanding Balance.
-- 17/03/2004	abell	5	Add grant execute statement.
-- 26/08/2009	CR	6	Modified Item Type filtering to include Unallocated Payments (7803)
--					Updated joins to CREDITORITEM and CREDITORHISTORY to cater for
--					Unallocated Payments recorded using the Credit Card method 
--					(i.e. two Creditor Items created with the same TransId)
-- 18/04/2016	vql	7	Accounts Payable Bulk Payment including credit notes shows duplication in Purchases Selected report (DR-19945).

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sWhereString	nvarchar(4000)

set @nErrorCode=0
Set @sWhereString = ''

if @pnPlanId is not null
	Set @sWhereString = @sWhereString + '.PLANID = ' + CAST (@pnPlanId as nvarchar)


if @nErrorCode = 0
begin
	Set @sSQLString="
	SELECT N.NAMENO,
 	       convert( nvarchar(254), 
 	       		N.NAME + 
 	       		CASE WHEN N.FIRSTNAME IS NOT NULL THEN 
 	       			', ' 
 	       		END + N.FIRSTNAME+SPACE(1) + 
 	       		CASE WHEN N.NAMECODE IS NOT NULL THEN 
 	       			'{' 
 	       		END + N.NAMECODE + 
 	       		CASE WHEN N.NAMECODE IS NOT NULL THEN 
 	       			'}' 
 	       		END ) AS CREDITOR, 
		E.NAMENO,
		convert( nvarchar(254), 
			 E.NAME + 
			 CASE WHEN E.FIRSTNAME IS NOT NULL THEN 
			 	', ' 
			 END + E.FIRSTNAME+SPACE(1) + 
			 CASE WHEN E.NAMECODE IS NOT NULL THEN 
			 	'{' 
			 END + E.NAMECODE + 
			 CASE WHEN E.NAMECODE IS NOT NULL THEN 
			 	'}' 
			 END ) AS ENTITY, 
		C.INSTRUCTIONS,
		CI.DOCUMENTREF,
		IT.USERCODE,
		CI.ITEMDATE,
		CI.ITEMDUEDATE,
		CI.CURRENCY,
		CASE WHEN CI.CURRENCY IS NULL THEN
			CI.LOCALBALANCE
		ELSE
			CI.FOREIGNBALANCE
		END AS OUTSTANDINGBALANCE,
		PPD.PAYMENTAMOUNT
	FROM PAYMENTPLAN PP
		JOIN
	     NAME E ON (E.NAMENO = PP.ENTITYNO)
	     	JOIN
	     PAYMENTPLANDETAIL PPD ON (PPD.PLANID = PP.PLANID)
		LEFT JOIN
	     CREDITORITEM CI ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO
				 AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO
				AND	CI.ACCTENTITYNO = PPD.ACCTENTITYNO 
				AND CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
		JOIN 
	     TABLECODES IT ON (IT.TABLECODE  = CI.ITEMTYPE)
		JOIN
	     NAME N ON (N.NAMENO = CI.ACCTCREDITORNO)
		LEFT JOIN
	     CREDITOR C	ON (C.NAMENO = N.NAMENO) 
	WHERE CI.ITEMTYPE not in (7802, 7803) AND PP" + @sWhereString + "

	UNION ALL

	SELECT N.NAMENO,
	       convert( nvarchar(254),
	       		N.NAME + 
	       		CASE WHEN N.FIRSTNAME IS NOT NULL THEN 
	       			', '
	       		END + 
		       		N.FIRSTNAME + SPACE(1) + 
	       		CASE WHEN N.NAMECODE IS NOT NULL THEN 
	       			'{' 
	       		END + N.NAMECODE + 
	       		CASE WHEN N.NAMECODE IS NOT NULL THEN 
	       			'}' 
	       		END ) AS CREDITOR, 
	       E.NAMENO,
	       convert( nvarchar(254), 
	       		E.NAME + 
	       		CASE WHEN E.FIRSTNAME IS NOT NULL THEN 
	       			', '
	       		END + E.FIRSTNAME + SPACE(1) + 
	       		CASE WHEN E.NAMECODE IS NOT NULL THEN 
	       			'{' 
	       		END + E.NAMECODE + 
	       		CASE WHEN E.NAMECODE IS NOT NULL THEN 
	       			'}' 
	       		END ) AS ENTITY, 
	       C.INSTRUCTIONS,
	       CI.DOCUMENTREF,
	       IT.USERCODE,
	       CI.ITEMDATE,
	       CI.ITEMDUEDATE,
	       CI.CURRENCY,
	       CASE WHEN CI.CURRENCY IS NULL THEN
	       		CI.LOCALBALANCE
	       ELSE
	       		CI.FOREIGNBALANCE
	       END AS OUTSTANDINGBALANCE,
	       PPD.PAYMENTAMOUNT
	FROM CREDITORITEM CI
	JOIN PAYMENTPLAN PP ON (PP.ENTITYNO = CI.ACCTENTITYNO)
	LEFT JOIN PAYMENTPLANDETAIL PPD ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO
			AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO
			AND CI.ACCTENTITYNO = PPD.ACCTENTITYNO
			AND CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO
			AND PPD.PLANID = PP.PLANID)
	JOIN NAME E ON (E.NAMENO = PP.ENTITYNO)
	JOIN TABLECODES IT ON (IT.TABLECODE  = CI.ITEMTYPE)
	JOIN NAME N ON (N.NAMENO = CI.ACCTCREDITORNO)
	LEFT JOIN CREDITOR C ON (C.NAMENO = N.NAMENO)
	WHERE PP" + @sWhereString + "
	AND CI.ITEMTYPE in (7802, 7803)
	AND CI.LOCALBALANCE <> 0
	AND CI.ACCTCREDITORNO IN (SELECT DISTINCT PPD.ACCTCREDITORNO
				  FROM PAYMENTPLANDETAIL PPD
				  WHERE PPD" + @sWhereString + ") 	
	ORDER BY CREDITOR, N.NAMENO, CI.CURRENCY, CI.ITEMDUEDATE, CI.ITEMDATE, CI.DOCUMENTREF" 

	exec (@sSQLString)

Set @nErrorCode =@@Error
Set @pnRowCount=@@Rowcount 
End

RETURN @nErrorCode	
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ap_PlanPurchasesSelected to public
go
