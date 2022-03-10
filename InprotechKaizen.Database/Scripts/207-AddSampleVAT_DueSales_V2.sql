-----------------------------------------------------------------------------------------------------------------------------
-- Creation of VAT_DueSales
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[VAT_DueSales]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.VAT_DueSales.'
	drop procedure dbo.VAT_DueSales
end
print '**** Creating procedure dbo.VAT_DueSales...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.VAT_DueSales 
		@pnEntityNo			int,
		@pdTransDateStart	datetime = null,
		@pdTransDateEnd		datetime = null
as

-- PROCEDURE :	VAT_DueSales
-- VERSION :	2
-- DESCRIPTION:	Calculates TOTAL Tax from sales and manual journals of specific account codes
-- 
--				EXEC VAT_DueSales @pnEntityNo = -283575757, @pdTransDateStart = '2017-11-01', @pdTransDateEnd = '2017-11-30'
--				EXEC VAT_DueSales @pnEntityNo = -283575757, @pdTransDateStart = '2017-11-01'
--				EXEC VAT_DueSales @pnEntityNo = -283575757,  @pdTransDateEnd = '2017-11-30'
--				EXEC VAT_DueSales @pnEntityNo = -283575757
-- 
-- NOTE: User is to enter list of ledger account codes created for the manual journals to include as tax.  See TODO tag.
-- 
-- COPYRIGHT	Copyright 1993 - 2019 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 22/01/2019	DL		DR-46022	1		Procedure created
-- 25/07/2019	KT		DR-47188	2		Calculated value for Group of entities

set nocount on


Declare @nTotalTaxAmount		decimal(11,2)	
Declare @nErrorCode				int
Declare @sSQLString				nvarchar(max)
Declare @sGLJournalCodeList		nvarchar(4000)
Declare @sTaxNumber				NVARCHAR(60)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: User optional parameters
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set @sGLJournalCodeList ="'', ''"					-- TODO: user enter list of GL ACCOUNTCODE from LEDGERACCOUNT table.  eg. "'1111', '11105'" or No Account "''"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Set @nTotalTaxAmount = 0
SELECT @sTaxNumber = TaxNo FROM NAME WHERE NAMENO = @pnEntityNo

-- AR sales Tax
SELECT @nTotalTaxAmount = SUM(ISNULL(TH.TAXAMOUNT, 0))
FROM DEBTORHISTORY DH
JOIN TAXHISTORY TH		ON (TH.ITEMENTITYNO = DH.ITEMENTITYNO 
					and TH.ITEMTRANSNO = DH.ITEMTRANSNO 
					and TH.ACCTENTITYNO = DH.ACCTENTITYNO 
					and TH.ACCTDEBTORNO = DH.ACCTDEBTORNO 
					and TH.HISTORYLINENO = DH.HISTORYLINENO)
WHERE DH.ACCTENTITYNO  IN ( SELECT N.NAMENO FROM NAME N INNER JOIN SPECIALNAME SN ON SN.NAMENO = N.NAMENO WHERE N.TAXNO = @sTaxNumber AND SN.ENTITYFLAG = 1) 
AND ( DH.TRANSDATE >=  @pdTransDateStart or @pdTransDateStart IS NULL )
AND ( DH.TRANSDATE <=  @pdTransDateEnd	 or @pdTransDateEnd IS NULL )
AND DH.STATUS <> 0 

select @nErrorCode = @@ERROR

-- Total manual journal for specific accounts
-- 810	Manual Journal Entry
-- 811	Manual Journal Entry Reversal
If @nErrorCode = 0
Begin
	Set @sSQLString="
	SELECT @nTotalTaxAmount = isnull(@nTotalTaxAmount,0) + isnull(SUM(isnull(LOCALAMOUNT, 0)),0) 
	FROM TRANSACTIONHEADER TH
	JOIN LEDGERJOURNALLINE JL ON JL.ENTITYNO = TH.ENTITYNO
								AND JL.TRANSNO = TH.TRANSNO
	JOIN LEDGERACCOUNT LA	ON LA.ACCOUNTID = JL.ACCOUNTID
	WHERE ACCTENTITYNO  IN  ( SELECT N.NAMENO FROM NAME N INNER JOIN SPECIALNAME SN ON SN.NAMENO = N.NAMENO WHERE N.TAXNO = @sTaxNumber AND SN.ENTITYFLAG = 1)   
	AND ( TH.TRANSDATE >=  @pdTransDateStart or @pdTransDateStart IS NULL )
	AND ( TH.TRANSDATE <=  @pdTransDateEnd	 or @pdTransDateEnd IS NULL )
	AND TH.TRANSTYPE IN (810, 811)
	AND LA.ACCOUNTCODE IN (" + @sGLJournalCodeList + ")"				

    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@nTotalTaxAmount		dec(11,2)	OUTPUT,
			  @sTaxNumber			nvarchar(60),
			  @pdTransDateStart		datetime,
			  @pdTransDateEnd		datetime,
			  @sGLJournalCodeList	nvarchar(max)',
		      @nTotalTaxAmount		= @nTotalTaxAmount	OUTPUT,
			  @sTaxNumber			= @sTaxNumber,
			  @pdTransDateStart		= @pdTransDateStart,
			  @pdTransDateEnd		= @pdTransDateEnd,
			  @sGLJournalCodeList	= @sGLJournalCodeList

End

-- return the tax amount
SELECT ISNULL(@nTotalTaxAmount, 0)

Return @nErrorCode
go

grant execute on dbo.VAT_DueSales to public
go
