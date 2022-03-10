-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_GetDebitNoteDetails 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[bi_GetDebitNoteDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.bi_GetDebitNoteDetails.'
	drop procedure dbo.bi_GetDebitNoteDetails
end
print '**** Creating procedure dbo.bi_GetDebitNoteDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.bi_GetDebitNoteDetails
				@pnEntityNo		int,
				@psOpenItemNo		nvarchar(12)
as
-- PROCEDURE :	bi_GetDebitNoteDetails
-- VERSION :	10
-- DESCRIPTION:	A procedure that returns all of the details required on a formatted
--		open item such as a Debit or Credit Note.
--
--		The following details will be returned :
--			asOpenItemNo
--			asAccountNo
--			asYourRef
--			adtDate
--			asRefText
--			anTaxLocal
--			anTaxForeign
--			asCurrencyL
--			anLocalValue
--			asCurrencyF
--			anCurrencyF
--			anForeignValue
--			anBillPercentage
--			asTaxLabel
--			anTax
--			asFmtName
--			asFmtAddress
--			asFmtAttention
--			asStatusText
--			asCopyToList
--			asCopyToAddress
--			asCopyToAttention
--			asOurRef
--			asPurchaseOrderNo
--			asSignOffName
--			asRegarding
--			asBillScope
--			anReductions
--			anCreditNoteF
--			anReductionsForeign
--			asTaxNo
--			asCopyLabel
--			Image
--			asForeignEquivCurrency
--			anForeignEquivExRate
--			anPenaltyInterestRate
--			asItemTypeAbbreviation
--			adtDueDate
--			anLocalTakenUp
--			anForeignTakenUp
--			
--			anTaxRate1
--			anTaxableAmount1
--			anTaxAmount1
--			asTaxDescription1
--			anTaxRate2
--			anTaxableAmount2
--			anTaxAmount2
--			asTaxDescription2
--			anTaxRate3
--			anTaxableAmount3
--			anTaxAmount3
--			asTaxDescription3
--			anTaxRate4
--			anTaxableAmount4
--			anTaxAmount4
--			asTaxDescription4
--			
--
--			anDisplaySequence
--			DetailChargeRate
--			DetailStaffName
--			DetailDate
--			DetailInternalRef
--			DetailTime
--			DetailWIPCode
--			DetailWIPTypeId
--			DetailCatDesc
--			DetailNarrative
--			DetailValue
--			DetailForeignValue
--			DetailChargeCurr
--			DetailCaseSequence

--			DetailRefDocItem1
--			DetailRefDocItem2
--			DetailRefDocItem3
--			DetailRefDocItem4
--			DetailRefDocItem5
--			DetailRefDocItem6
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	SQA	    Version Description
-- -----------	-------	------	    ------- ----------------------------------------------- 
-- 02/12/2003	MF		    	    Procedure created
-- 05/08/2004	AB	8035	    	    Add collate database_default to temp table definitions
-- 28/09/2004	TM	RFC1806	    2	    Pass the new parameter and to pass the country postal name instead of the country
--					    name to the fn_FormatAddress.
-- 15/01/2008	Dw	9782	    3	    Tax No moved from Organisation to Name table
-- 19/03/2008	vql	SQA14773    4	    Make PurchaseOrderNo nvarchar(80)
-- 11 Dec 2008	MF	17136	    5	    Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jul 2011	DL	RFC10830    6	    Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 29-Apr-2013	MS	RFC11732    7	    ReferenceNo is get from NAMEADDRESSSNAP is exists	    
-- 01-May-2013  MS      RFC11732    8       Return Cases from fn_GetBillCases	
-- 20 Oct 2015  MS      R53933      9       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE col
-- 02 Nov 2015	vql	R53910	    10      Adjust formatted names logic (DR-15543).

set nocount on

-- Store the Case details for each Case on the bill loaded from 
-- user defined queries and held in a Temporary Table (required because of dynamic SQL)
-- The size of the DocItem columns may need to be varied depending on 
-- the results to be loaded into these columns.
Create table #TEMPCASEDETAILS (
			CASEID			int		NOT NULL,
			IRN			nvarchar(30)	collate database_default NOT NULL,
			DOCITEM1		nvarchar(1000)	collate database_default NULL,
			DOCITEM2		nvarchar(1000)	collate database_default NULL,
			DOCITEM3		nvarchar(500)	collate database_default NULL,
			DOCITEM4		nvarchar(500)	collate database_default NULL,
			DOCITEM5		nvarchar(500)	collate database_default NULL,
			DOCITEM6		nvarchar(400)	collate database_default NULL
			)

-- Store the required information in a table variable
Declare @tbItemHeader table (
			OpenItemNo		nvarchar(12)	collate database_default NULL,
			AccountNo		nvarchar(60)	collate database_default NULL,
			YourRef			nvarchar(500)	collate database_default NULL,
			ItemDate		datetime	NULL,
			RefText			ntext		NULL,
			TaxLocal		decimal(11,2)	NULL,
			TaxForeign		decimal(11,2)	NULL,
			CurrencyLocal		nvarchar(3)	collate database_default NULL,
			LocalValue		decimal(11,2)	NULL,
			CurrencyForeign		nvarchar(3)	collate database_default NULL,
			CurrencyFlag		bit		NULL,
			ForeignValue		decimal(11,2)	NULL,
			BillPercentage		decimal(5,2)	NULL,
			TaxLabel		nvarchar(20)	collate database_default NULL,
			TaxFlag			bit		NULL,
			FmtName			nvarchar(254)	collate database_default NULL,
			FmtAddress		nvarchar(254)	collate database_default NULL,
			FmtAttention		nvarchar(254)	collate database_default NULL,
			StatusText		nvarchar(50)	collate database_default NULL,
			OurRef			nvarchar(500)	collate database_default NULL,
			PurchaseOrderNo		nvarchar(80)	collate database_default NULL,
			SignOffName		nvarchar(100)	collate database_default NULL,
			Regarding		ntext		NULL,
			BillScope		nvarchar(254)	collate database_default NULL,
			Reductions		decimal(11,2)	NULL,
			CreditNoteFlag		bit		NULL,
			ReductionsForeign	decimal(11,2)	NULL,
			TaxNo			nvarchar(30)	collate database_default NULL,
			ImageId			int		NULL,
			ForeignEquivCurrency	nvarchar(40)	collate database_default NULL,
			ForeignEquivExRate	decimal(11,4)	NULL,
			PenaltyInterestRate	decimal(5,2)	NULL,
			DueDate			datetime	NULL,
			LocalTakenUp		decimal(11,2)	NULL,
			ForeignTakenUp		decimal(11,2)	NULL
			)

Declare @tbBillLines table (
			DetailDisplaySequence	smallint	NULL,
			DetailChargeOutRate	decimal(11,2)	NULL,
			DetailStaffName		nvarchar(60)	collate database_default NULL,
			DetailDate		datetime	NULL,
			DetailIRN		nvarchar(30)	collate database_default NULL,	
			DetailTime		nvarchar(30)	collate database_default NULL,
			DetailWIPCode		nvarchar(6)	collate database_default NULL,
			DetailWIPTypeId		nvarchar(6)	collate database_default NULL,
			DetailCatDesc		nvarchar(50)	collate database_default NULL,
			DetailNarrative		nvarchar(3500)	collate database_default NULL,
			DetailValue		decimal(11,2)	NULL,
			DetailForeignValue	decimal(11,2)	NULL,
			DetailChargeCurr	nvarchar(3)	collate database_default NULL
			)

-- Store the tax summary information in a table variable
Declare @tbTaxDetails table (
			TaxRate			decimal(11,4)	NULL,
			TaxableAmount		decimal(11,2)	NULL,
			TaxAmount		decimal(11,2)	NULL,
			TaxDescription		nvarchar(30)	collate database_default NULL
			)

-- Store the tax summary information in a table variable
Declare @tbCopyToDetails table (
			CopyToName		nvarchar(500)	collate database_default NULL,
			CopyToAttention		nvarchar(500)	collate database_default NULL,
			CopyToAddress		nvarchar(254)	collate database_default NULL
			)

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare		@sSQLString	nvarchar(4000)
Declare		@sSQLDocItem	nvarchar(4000)
Declare		@sYourRef	nvarchar(1000)
Declare		@sOurRef	nvarchar(1000)
Declare		@sPurchaseNo	nvarchar(1000)

-- Initialise the errorcode and then set it after each SQL Statement
Set @ErrorCode = 0

-- Get the Clients Reference, Our Reference and Purchase Order Nos
-- for all Cases being billed separated by a comma
If @ErrorCode=0
Begin
	Set @sSQLString="
	select @sYourRef   = CASE WHEN CN.REFERENCENO is not null 
	                        THEN ISNULL(nullif(@sYourRef+', ',', '), '') + CN.REFERENCENO
	                        ELSE @sYourRef
	                        END,
	       @sOurRef    =nullif(@sOurRef+', ',', ')+C.IRN,
	       @sPurchaseNo=nullif(@sPurchaseNo+', ',', ')+C.PURCHASEORDERNO
	from OPENITEM O
	cross apply dbo.fn_GetBillCases(O.ITEMTRANSNO, O.ITEMENTITYNO) BC
	join CASES C		on (C.CASEID=BC.CASEID)
	join CASENAME CN	on (CN.CASEID=C.CASEID
				and CN.NAMENO=O.ACCTDEBTORNO
				and CN.NAMETYPE=(select min(NAMETYPE)
						 from CASENAME CN1
						 where CN1.CASEID=C.CASEID
						 and CN1.NAMENO=O.ACCTDEBTORNO
						 and CN1.NAMETYPE in ('D','R')))
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo
	order by C.IRN"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOpenItemNo		nvarchar(12),
					  @pnEntityNo		int,
					  @sYourRef		nvarchar(1000)	OUTPUT,
					  @sOurRef		nvarchar(1000)	OUTPUT,
					  @sPurchaseNo		nvarchar(1000)	OUTPUT',
					  @psOpenItemNo=@psOpenItemNo,
					  @pnEntityNo=@pnEntityNo,
					  @sYourRef=@sYourRef			OUTPUT,
					  @sOurRef=@sOurRef			OUTPUT,
					  @sPurchaseNo=@sPurchaseNo		OUTPUT
End 

If @ErrorCode=0
Begin
	insert into @tbItemHeader
	select 		O.OPENITEMNO,
			isnull(NA.ALIAS,N.NAMECODE),
			isnull(NS.FORMATTEDREFERENCE,@sYourRef),  -- Clients reference separated by semi colon
			O.ITEMDATE,
			O.REFERENCETEXT,
			O.LOCALTAXAMT,
			O.FOREIGNTAXAMT,
			S1.COLCHARACTER, -- Local Currency
			O.LOCALVALUE,
			O.CURRENCY,
			CASE WHEN(O.CURRENCY<>S1.COLCHARACTER) THEN 1 ELSE 0 END, -- Flag indicates foreign currency
			O.FOREIGNVALUE,
			O.BILLPERCENTAGE,
			S2.COLCHARACTER, -- Tax literal
			CASE WHEN(O.LOCALTAXAMT<>0) THEN 1 ELSE 0 END,
			NS.FORMATTEDNAME,
			NS.FORMATTEDADDRESS,
			NS.FORMATTEDATTENTION,
			CASE WHEN(O.STATUS=0) THEN 'DRAFT' END,
			@sOurRef,	-- IRNs separated by Semi Colon
			isnull(@sPurchaseNo,IP.PURCHASEORDERNO),-- Purchase Orders from Cases separated by Semicolon OR Purchase Order from IPNAME
			E.SIGNOFFNAME,
			CASE WHEN(datalength(O.LONGREGARDING)>0) THEN O.LONGREGARDING ELSE O.REGARDING END,
			O.SCOPE,
			Null,		-- Reductions
			CASE WHEN(O.ITEMTYPE=511) THEN 1 ELSE 0 END,
			Null,		-- ReductionsForeign
			N.TAXNO,
			O.IMAGEID,
			O.FOREIGNEQUIVCURRCY,
			O.FOREIGNEQUIVEXRATE,
			O.PENALTYINTEREST,
			O.ITEMDUEDATE,
			O.LOCALORIGTAKENUP,
			O.FOREIGNORIGTAKENUP
	from OPENITEM O
	join NAME N			on (N.NAMENO=O.ACCTDEBTORNO)
	left join IPNAME IP		on (IP.NAMENO=N.NAMENO)
	left join NAMEALIAS NA		on (NA.NAMENO=N.NAMENO
					and NA.ALIASTYPE='D')
	left join SITECONTROL S1	on (S1.CONTROLID='CURRENCY')
	left join SITECONTROL S2	on (S2.CONTROLID='TAXLITERAL')
	     join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO=O.NAMESNAPNO)
	left join EMPLOYEE E		on (E.EMPLOYEENO=O.EMPLOYEENO)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Set @ErrorCode=@@Error
End

-- Get the Bill Line Details
If @ErrorCode=0
Begin
	Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
				DetailStaffName, DetailDate, DetailIRN, DetailTime, 
				DetailWIPCode, DetailWIPTypeId, DetailCatDesc, 
				DetailNarrative, DetailValue, DetailForeignValue, 
				DetailChargeCurr)
	select 	B.DISPLAYSEQUENCE, 
		B.PRINTCHARGEOUTRATE,
		B.PRINTNAME, 
		B.PRINTDATE, 
		B.IRN, 
		B.PRINTTIME, 
		B.WIPCODE, 
		B.WIPTYPEID, 
		W.DESCRIPTION, 
		CASE WHEN(datalength(LONGNARRATIVE)>0) THEN convert(nvarchar(3500),LONGNARRATIVE) ELSE SHORTNARRATIVE END,
		B.VALUE, 
		B.FOREIGNVALUE, 
		B.PRINTCHARGECURRNCY
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Set @ErrorCode=@@Error
End

-- Get the total of the lines that reduce the overall
-- value of the Open Item.
If @ErrorCode=0
Begin
	If exists(select * from @tbItemHeader where CreditNoteFlag=0)
		update @tbItemHeader
		set Reductions=R.ReductionTotal,
		    ReductionsForeign=R.ReductionForeignTotal
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue<0) R on (1=1)
	Else
		update @tbItemHeader
		set Reductions=R.ReductionTotal,
		    ReductionsForeign=R.ReductionForeignTotal
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue>0) R on (1=1)

	set @ErrorCode=@@Error
End

-- Get the tax details
If @ErrorCode=0
Begin
	Insert into @tbTaxDetails (TaxRate, TaxableAmount, TaxAmount, TaxDescription)
	select OT.TAXRATE, OT.TAXABLEAMOUNT, OT.TAXAMOUNT, T.DESCRIPTION
	from OPENITEM O
	join OPENITEMTAX OT	on (OT.ITEMENTITYNO=O.ITEMENTITYNO
        			and OT.ITEMTRANSNO =O.ITEMTRANSNO
        			and OT.ACCTENTITYNO=O.ACCTENTITYNO
       				and OT.ACCTDEBTORNO=O.ACCTDEBTORNO)
	join TAXRATES T		on (T.TAXCODE=OT.TAXCODE)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Set @ErrorCode=@@Error
End

-- Get the user defined details associated with each Case.

If @ErrorCode=0
Begin
	insert into #TEMPCASEDETAILS(CASEID, IRN)
	Select distinct C.CASEID, C.IRN 
	from OPENITEM O
	join WORKHISTORY WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
      		  		and WH.REFTRANSNO =O.ITEMTRANSNO)
	join CASES C		on (C.CASEID=WH.CASEID)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Select	@ErrorCode=@@Error,
		@nRowCount=@@Rowcount

	-- If there are Cases against the Bill now see if any user defined
	-- Doc Items have been defined.
	If  @ErrorCode=0
	and @nRowCount>0
	Begin
		-- Get Doc Item 1
		Set @sSQLString="
		Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
		From SITECONTROL S
		join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
		Where S.CONTROLID='Bill Ref Doc Item 1'"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sSQLDocItem		nvarchar(4000)	Output',
					  @sSQLDocItem=@sSQLDocItem		Output
		set @nRowCount=@@Rowcount

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM1=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 2
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
			Where S.CONTROLID='Bill Ref Doc Item 2'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM2=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 3
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
			Where S.CONTROLID='Bill Ref Doc Item 3'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM3=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 4
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
			Where S.CONTROLID='Bill Ref Doc Item 4'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM4=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 5
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
			Where S.CONTROLID='Bill Ref Doc Item 5'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM5=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 6
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
			Where S.CONTROLID='Bill Ref Doc Item 6'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','T.IRN')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM6=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS T"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End
	End
End

-- Get the Copy To Details
If @ErrorCode=0
Begin
	insert into @tbCopyToDetails (CopyToName,CopyToAttention,CopyToAddress)
	select	distinct
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, C1.NAMESTYLE, 7101)),
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, COALESCE(N2.NAMESTYLE, C2.NAMESTYLE, 7101)),
		dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CA.POSTALNAME, CA.POSTCODEFIRST, CA.STATEABBREVIATED, CA.POSTCODELITERAL,CA.ADDRESSSTYLE)
	from #TEMPCASEDETAILS T
	join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE='CD'
				and CN.EXPIRYDATE is not null)
	join NAME N1		on (N1.NAMENO=CN.NAMENO)
	left join COUNTRY C1	on (C1.COUNTRYCODE=N1.NATIONALITY)
	left join ADDRESS A	on (A.ADDRESSCODE=N1.POSTALADDRESS)
	left join COUNTRY CA	on (CA.COUNTRYCODE=A.COUNTRYCODE)
	left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
				and S.STATE=A.STATE)
	left join NAME N2	on (N2.NAMENO=isnull(CN.CORRESPONDNAME,N1.MAINCONTACT))
	left join COUNTRY C2	on (C2.COUNTRYCODE=N2.NATIONALITY)
End

If @ErrorCode=0
Begin
	Select * from @tbItemHeader

	Select * from @tbBillLines
	order by DetailDisplaySequence

	Select * from @tbTaxDetails
	order by TaxRate, TaxDescription

	Select * from #TEMPCASEDETAILS
	order by IRN

	Select * from @tbCopyToDetails
	order by CopyToName
End

return @ErrorCode
go

grant execute on dbo.bi_GetDebitNoteDetails  to public
go
