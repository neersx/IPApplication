-----------------------------------------------------------------------------------------------------------------------------
-- Creation of VAT_DueAcquisitions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[VAT_DueAcquisitions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.VAT_DueAcquisitions.'
	drop procedure dbo.VAT_DueAcquisitions
end
print '**** Creating procedure dbo.VAT_DueAcquisitions...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.VAT_DueAcquisitions 
		@pnEntityNo			int,
		@pdTransDateStart	datetime = null,
		@pdTransDateEnd		datetime = null
as

-- PROCEDURE :	VAT_DueAcquisitions
-- VERSION :	2
-- DESCRIPTION:	Calculates TOTAL Tax of creditors invoices (purchases) and credit notes from creditors in EU country group and manual journals of specific account codes
--				(BOX 2)
-- 
--				EXEC VAT_DueAcquisitions @pnEntityNo = -283575757, @pdTransDateStart = '2011-12-01', @pdTransDateEnd = '2011-12-31'
--				EXEC VAT_DueAcquisitions @pnEntityNo = -283575757, @pdTransDateStart = '2011-12-01'
--				EXEC VAT_DueAcquisitions @pnEntityNo = -283575757, @pdTransDateEnd = '2011-12-31'
--				EXEC VAT_DueAcquisitions @pnEntityNo = -283575757
-- 
-- NOTE: User is to enter list of ledger account codes created for the manual journals to include as tax.  See TODO tag.
-- 
-- COPYRIGHT	Copyright 1993 - 2019 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 14/02/2019	DL		DR-46023	1		Procedure created
-- 25/07/2019	KT		DR-47188	2		Calculated value for Group of entities

set nocount on


Declare @nTotalTaxAmount		decimal(11,2)	
Declare @nErrorCode				int
Declare @sSQLString				nvarchar(max)
Declare @sCountryGroup			nvarchar(6)
Declare @sGLJournalCodeList		nvarchar(4000)
Declare @sTaxNumber				NVARCHAR(60)	

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: User optional parameters
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set @sCountryGroup = 'EU'									-- TODO: user enter the Country Group that contains list of EU countries excluding UK
--set @sGLJournalCodeList ="'1111', '11105'"					-- TODO: user enter list of GL ACCOUNTCODE from LEDGERACCOUNT table.  eg. "'1111', '11105'" or No Account "''"
set @sGLJournalCodeList ="''"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Set @nTotalTaxAmount = 0
SELECT @sTaxNumber = TaxNo FROM NAME WHERE NAMENO = @pnEntityNo

-- AP sales Tax for countries in EU country group 
SELECT @nTotalTaxAmount = SUM(ISNULL(TPH.TAXAMOUNT, 0))
FROM TAXPAIDHISTORY TPH
JOIN TRANSACTIONHEADER TH	ON (TH.ENTITYNO = TPH.REFENTITYNO
							and TH.TRANSNO = TPH.REFTRANSNO)
JOIN NAME N			ON (N.NAMENO = TPH.ACCTCREDITORNO)
JOIN ADDRESS A		on (A.ADDRESSCODE=N.POSTALADDRESS)
JOIN COUNTRYGROUP CG ON (CG.MEMBERCOUNTRY = A.COUNTRYCODE
						AND (CG.DATECEASED IS NULL OR CG.DATECEASED > TH.TRANSDATE))
WHERE TH.ENTITYNO IN ( SELECT N.NAMENO FROM NAME N INNER JOIN SPECIALNAME SN ON SN.NAMENO = N.NAMENO WHERE N.TAXNO = @sTaxNumber AND SN.ENTITYFLAG = 1) 
AND ( TH.TRANSDATE >=  @pdTransDateStart or @pdTransDateStart IS NULL )
AND ( TH.TRANSDATE <=  @pdTransDateEnd	 or @pdTransDateEnd IS NULL )
AND TH.TRANSTATUS <> 0 
AND CG.TREATYCODE = @sCountryGroup

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

grant execute on dbo.VAT_DueAcquisitions to public
go
