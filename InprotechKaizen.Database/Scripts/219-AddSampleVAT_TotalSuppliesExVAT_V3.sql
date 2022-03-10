-----------------------------------------------------------------------------------------------------------------------------
-- Creation of VAT_TotalSuppliesExVAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[VAT_TotalSuppliesExVAT]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.VAT_TotalSuppliesExVAT.'
	drop procedure dbo.VAT_TotalSuppliesExVAT
end
print '**** Creating procedure dbo.VAT_TotalSuppliesExVAT...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.VAT_TotalSuppliesExVAT 
		@pnEntityNo			int,
		@pdTransDateStart	datetime = null,
		@pdTransDateEnd		datetime = null
as

-- PROCEDURE :	VAT_TotalSuppliesExVAT
-- VERSION :	3
-- DESCRIPTION:	Calculates TOTAL Value Goods Supplied Exclude VAT from sales and manual journals of specific account codes.
--				(BOX 8)
-- 
--				EXEC VAT_TotalSuppliesExVAT @pnEntityNo = -283575757, @pdTransDateStart = '2017-11-01', @pdTransDateEnd = '2017-11-30'
--				EXEC VAT_TotalSuppliesExVAT @pnEntityNo = -283575757, @pdTransDateStart = '2017-11-01'
--				EXEC VAT_TotalSuppliesExVAT @pnEntityNo = -283575757,  @pdTransDateEnd = '2017-11-30'
--				EXEC VAT_TotalSuppliesExVAT @pnEntityNo = -283575757
-- 
-- NOTE: User is to enter list of ledger account codes created for the manual journals to include as tax.  See TODO tag.
-- 
-- COPYRIGHT	Copyright 1993 - 2019 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 14/02/2019	DL		DR-46037	1		Procedure created
-- 18/03/2019	vql		DR-47211	2		Values returned by the Data Items are rounded to the nearest pound
-- 25/07/2019	KT		DR-47188	3		Calculated value for Group of entities

set nocount on


Declare @nTotalSaleAmountExclVAT		decimal(11,2)	
Declare @nErrorCode				int
Declare @sSQLString				nvarchar(max)
Declare @sGLJournalCodeList		nvarchar(4000)
Declare @sCountryGroup			nvarchar(6)
Declare @sTaxNumber				NVARCHAR(60)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: User optional parameters
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set @sCountryGroup = 'EU'								-- TODO: user enter the Country Group that contains list of EU countries excluding UK
set @sGLJournalCodeList ="''"							-- No extra journal data 
--set @sGLJournalCodeList ="'1111', '11105'"			-- TODO: user enter list of GL ACCOUNTCODE from LEDGERACCOUNT table.  eg. "'1111', '11105'" or No Account "''"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Set @nTotalSaleAmountExclVAT = 0
SELECT @sTaxNumber = TaxNo FROM NAME WHERE NAMENO = @pnEntityNo

-- AR sales exclude tax for countries in EU group only.
SELECT @nTotalSaleAmountExclVAT = SUM(ISNULL(TH.TAXABLEAMOUNT, 0))
FROM DEBTORHISTORY DH
JOIN TAXHISTORY TH		ON (TH.ITEMENTITYNO = DH.ITEMENTITYNO 
					and TH.ITEMTRANSNO = DH.ITEMTRANSNO 
					and TH.ACCTENTITYNO = DH.ACCTENTITYNO 
					and TH.ACCTDEBTORNO = DH.ACCTDEBTORNO 
					and TH.HISTORYLINENO = DH.HISTORYLINENO)
JOIN NAME N			ON (N.NAMENO = DH.ACCTDEBTORNO)
JOIN ADDRESS A		on (A.ADDRESSCODE=N.POSTALADDRESS)
JOIN COUNTRYGROUP CG ON (CG.MEMBERCOUNTRY = A.COUNTRYCODE
						AND (CG.DATECEASED IS NULL OR CG.DATECEASED > DH.TRANSDATE))
WHERE DH.ACCTENTITYNO IN ( SELECT NA.NAMENO FROM NAME NA INNER JOIN SPECIALNAME SN ON SN.NAMENO = NA.NAMENO WHERE NA.TAXNO = @sTaxNumber AND SN.ENTITYFLAG = 1) 
AND ( DH.TRANSDATE >=  @pdTransDateStart or @pdTransDateStart IS NULL )
AND ( DH.TRANSDATE <=  @pdTransDateEnd	 or @pdTransDateEnd IS NULL )
AND DH.STATUS <> 0 
AND CG.TREATYCODE = @sCountryGroup

select @nErrorCode = @@ERROR

-- Total manual journal for specific accounts
-- 810	Manual Journal Entry
-- 811	Manual Journal Entry Reversal
If @nErrorCode = 0
Begin
	Set @sSQLString="
	SELECT @nTotalSaleAmountExclVAT = isnull(@nTotalSaleAmountExclVAT,0) + isnull(SUM(isnull(LOCALAMOUNT, 0)),0) 
	FROM TRANSACTIONHEADER TH
	JOIN LEDGERJOURNALLINE JL ON JL.ENTITYNO = TH.ENTITYNO
								AND JL.TRANSNO = TH.TRANSNO
	JOIN LEDGERACCOUNT LA	ON LA.ACCOUNTID = JL.ACCOUNTID
	WHERE ACCTENTITYNO IN  ( SELECT N.NAMENO FROM NAME N INNER JOIN SPECIALNAME SN ON SN.NAMENO = N.NAMENO WHERE N.TAXNO = @sTaxNumber AND SN.ENTITYFLAG = 1)  
	AND ( TH.TRANSDATE >=  @pdTransDateStart or @pdTransDateStart IS NULL )
	AND ( TH.TRANSDATE <=  @pdTransDateEnd	 or @pdTransDateEnd IS NULL )
	AND TH.TRANSTYPE IN (810, 811)
	AND LA.ACCOUNTCODE IN (" + @sGLJournalCodeList + ")"				

    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@nTotalSaleAmountExclVAT		dec(11,2)	OUTPUT,
			  @sTaxNumber			nvarchar(60),
			  @pdTransDateStart		datetime,
			  @pdTransDateEnd		datetime,
			  @sGLJournalCodeList	nvarchar(max)',
		      @nTotalSaleAmountExclVAT		= @nTotalSaleAmountExclVAT	OUTPUT,
			  @sTaxNumber			= @sTaxNumber,
			  @pdTransDateStart		= @pdTransDateStart,
			  @pdTransDateEnd		= @pdTransDateEnd,
			  @sGLJournalCodeList	= @sGLJournalCodeList

End

-- return the total sale amount excluding TAX for EU countries
SELECT round(ISNULL(@nTotalSaleAmountExclVAT, 0), 0)

Return @nErrorCode
go

grant execute on dbo.VAT_TotalSuppliesExVAT to public
go
