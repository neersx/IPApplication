-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_EFTTrustTransfer
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.xml_EFTTrustTransfer') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xml_EFTTrustTransfer.'
	Drop procedure dbo.xml_EFTTrustTransfer
End
Print '**** Creating Stored Procedure dbo.xml_EFTTrustTransfer...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE    PROCEDURE dbo.xml_EFTTrustTransfer
	@psXMLCashItemKey	ntext,
	@pbDebug		bit = 0		
AS
-- PROCEDURE :	xml_EFTTrustTransfer
-- VERSION :	2
-- COPYRIGHT: 	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Collects EFT details about Trust Transfers 

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 11/09/2008	CR 	16387	1  	Procedure created
-- 27/09/2011	CR	20011	2	Remove redundant joins in SWIFT logic and guard against divide by 0 errors

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode 		int,
	@sSQLString 		nvarchar(4000),
	@hDocument 		int, 			-- handle to the XML parameter
	@nEntityNo		int,
	@nBankNameNo		int,
	@nBankSequenceNo	int,
	@nEFTFileFormat		int,
	@nEFTFileFormatABA	int,
	@nEFTFileFormatSWIFT	int,
	@nTotalBankAmount	decimal (13,2),
	@nTotalLocalAmount	decimal (13,2),
	@nTotalCount		int,
	@nTotalNetAmount	decimal (13,2),
	@nTotalDebit		decimal (13,2),
	@bSelfBalancing		bit

Set @nErrorCode = 0
Set @nEFTFileFormatSWIFT = 9301
Set @nEFTFileFormatABA = 9302


If @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLCashItemKey
	Set 	@nErrorCode = @@Error
End

If @pbDebug = 1
begin
	select @psXMLCashItemKey
end

-- Now select the key from the xml, at the same time joining it to the CashItem table.
If @nErrorCode = 0
Begin
	Set @sSQLString="
	select	DISTINCT @nEntityNo = CASHITEM.ENTITYNO,
		@nBankNameNo = CASHITEM.BANKNAMENO,
		@nBankSequenceNo = CASHITEM.SEQUENCENO,
		@nEFTFileFormat= CASHITEM.EFTFILEFORMAT,
		@bSelfBalancing = EFTDETAIL.SELFBALANCING
		FROM CASHITEM
		join  	OPENXML(@hDocument, '//CASHITEM', 2)
		WITH (TRANSENTITYNO int 'TRANSENTITYNO/text()', TRANSNO INT 'TRANSNO/text()') XC
	 	on ( XC.TRANSENTITYNO=CASHITEM.TRANSENTITYNO AND XC.TRANSNO = CASHITEM.TRANSNO)
		LEFT JOIN BANKACCOUNT HEADER		on (HEADER.ACCOUNTOWNER = CASHITEM.ENTITYNO
						and HEADER.BANKNAMENO = CASHITEM.BANKNAMENO
						and HEADER.SEQUENCENO = CASHITEM.SEQUENCENO)
		LEFT JOIN EFTDETAIL			on (EFTDETAIL.ACCOUNTOWNER = HEADER.ACCOUNTOWNER
						and EFTDETAIL.BANKNAMENO = HEADER.BANKNAMENO
						and EFTDETAIL.SEQUENCENO = HEADER.SEQUENCENO)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nEntityNo		int			OUTPUT,
		  @nBankNameNo		int			OUTPUT,
		  @nBankSequenceNo	int			OUTPUT,
		  @nEFTFileFormat	int			OUTPUT,
		  @bSelfBalancing	bit			OUTPUT,
		  @hDocument		int',
		  @nEntityNo		= @nEntityNo		OUTPUT,
		  @nBankNameNo		= @nBankNameNo		OUTPUT,
		  @nBankSequenceNo	= @nBankSequenceNo	OUTPUT,
		  @nEFTFileFormat	= @nEFTFileFormat	OUTPUT,
		  @bSelfBalancing 	= @bSelfBalancing	OUTPUT,
		  @hDocument 		= @hDocument


	If @pbDebug = 1
	begin
		print @sSQLString
		select @nEntityNo, @nBankNameNo, @nBankSequenceNo, @nEFTFileFormat, @bSelfBalancing
	end

End

If @nErrorCode = 0
Begin
	Set @sSQLString="
	select	@nTotalLocalAmount = SUM(ABS(CASHITEM.LOCALAMOUNT)),
		@nTotalCount = COUNT(CASHITEM.TRANSNO),
		@nTotalBankAmount = SUM(ABS(CASHITEM.BANKAMOUNT))
		FROM CASHITEM
		join  	OPENXML(@hDocument, '//CASHITEM', 2)
		WITH (TRANSENTITYNO int 'TRANSENTITYNO/text()', TRANSNO INT 'TRANSNO/text()') XC
	 	on ( XC.TRANSENTITYNO=CASHITEM.TRANSENTITYNO AND XC.TRANSNO = CASHITEM.TRANSNO)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nTotalLocalAmount	decimal (13,2)		OUTPUT,
	    	  @nTotalCount		int			OUTPUT,
		  @nTotalBankAmount	decimal (13,2)		OUTPUT,
		  @hDocument		int',
		  @nTotalLocalAmount	= @nTotalLocalAmount	OUTPUT,
	    	  @nTotalCount		= @nTotalCount		OUTPUT,
		  @nTotalBankAmount	= @nTotalBankAmount	OUTPUT,
		  @hDocument 		= @hDocument

	If @pbDebug = 1
	begin
		print @sSQLString
		select @nTotalLocalAmount, @nTotalCount, @nTotalBankAmount
	end

End


If @nErrorCode = 0
Begin

	set @sSQLString = "
		select 1 as TAG, 0 as PARENT,
		@nEFTFileFormat				AS [FileType!1!FILEFORMAT!element]
		for xml explicit"
	Exec @nErrorCode=sp_executesql @sSQLString,
	N'@nEFTFileFormat	int',
	@nEFTFileFormat

	If @pbDebug = 1
	begin
		print @sSQLString
		select @nEFTFileFormat
	end

End


If (@nEFTFileFormat = @nEFTFileFormatABA)
Begin

	If @nErrorCode = 0
	Begin
		-- ABA Header
		set @sSQLString = "
			select 1 as TAG, 0 as PARENT,
			'0' 					AS [Header!1!RECORDTYPE!element], 	-- FOLLOWED BY 17 BLANKS
			'01'					AS [Header!1!REELSEQNO!element], 	-- SQA10601 01 as there will always be only one file created at any given time. 
													-- FOLLOWED BY 7 BLANKS
			BANK.NAMECODE 				AS [Header!1!USERSBANK!element],	-- 3 CHARS
			ENTITY.NAME 				AS [Header!1!USERNAME!element], 	-- TRUNCATE TO 26 CHARS
			EFTDETAIL.USERREFNO 			AS [Header!1!USERNO!element],		-- RIGHT JUSTIFIED, 0 FILLED, 6 CHARS
			'Payment Data' 				AS [Header!1!DESCRIPTION!element], 	-- LEFT JUSTIFIED, BLANK FILLED
			CONVERT(DATETIME, GETDATE ( ), 126)	AS [Header!1!PAYMENTDATE!element] 	-- formatted as DD/MM/YY
													-- FOLLOWED BY 40 BLANKS
			FROM BANKACCOUNT HEADER
			JOIN NAME AS BANK 		ON (BANK.NAMENO = HEADER.BANKNAMENO)
			JOIN EFTDETAIL			on (EFTDETAIL.ACCOUNTOWNER = HEADER.ACCOUNTOWNER
							and EFTDETAIL.BANKNAMENO = HEADER.BANKNAMENO
							and EFTDETAIL.SEQUENCENO = HEADER.SEQUENCENO)
			JOIN NAME AS ENTITY 		ON (ENTITY.NAMENO = HEADER.ACCOUNTOWNER)
			WHERE HEADER.ACCOUNTOWNER = @nEntityNo
			AND HEADER.BANKNAMENO = @nBankNameNo
			AND HEADER.SEQUENCENO = @nBankSequenceNo
			for xml explicit"

		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nEntityNo		int,
		@nBankNameNo		int,
		@nBankSequenceNo	int',
		@nEntityNo,
		@nBankNameNo,
		@nBankSequenceNo

		If @pbDebug = 1
		begin
			print @sSQLString
			select @nEntityNo, @nBankNameNo, @nBankSequenceNo
		end
	End

	If @nErrorCode = 0
	Begin
		-- ABA Detail - for each payment
		set @sSQLString = "
			select 1 as TAG, 0 as PARENT,
			'1'					AS [Detail!1!RECORDTYPE!element],
			SUPPLIERBA.BANKBRANCHNO 		AS [Detail!1!SUPPLIERBSB!element], 		-- 7 CHARS
			SUPPLIERBA.ACCOUNTNO 			AS [Detail!1!SUPPLIERACCOUNTNO!element],	-- RIGHT JUSTIFIED, BLANK FILLED, 9 CHARS (IF OVER NINE REMOVE ANY HYPHENS)
														-- FOLLOWED BY 1 BLANK
			'50' 					AS [Detail!1!TRANSACTIONCODE!element],		-- SQA10601 changed from 53
			ABS(DETAIL.LOCALAMOUNT)			AS [Detail!1!LOCALAMOUNT!element], 		-- RIGHT JUSTIFIED, 0 FILLED, 1O CHRS, NO PUNCTUATION
			SUPPLIERBA.ACCOUNTNAME			AS [Detail!1!SUPPLIERACCOUNTTITLE!element],	-- LEFT JUSTIFIED, BLANK FILLED, 32 CHARS
			DETAIL.ITEMREFNO			AS [Detail!1!LODGEMENTREFNO!element], 		-- ?? LEFT JUSTIFIED, BLANK FILLED, 18 CHARS
			BANKACCOUNT.BANKBRANCHNO 		AS [Detail!1!TRACEBSB!element],			-- 7 CHARS
			BANKACCOUNT.ACCOUNTNO 			AS [Detail!1!TRACEACCOUNTNO!element],		-- RIGHT JUSTIFIED, BLANK FILLED, 9 CHARS
			EFTDETAIL.ALIAS				AS [Detail!1!NAMEOFREMITTER!element],		-- LEFT JUSTIFIED, BLANK FILLED, 16 CHARS
			'00000000'				AS [Detail!1!WITHHOLDINGTAX!element]
	
			FROM CASHITEM DETAIL
			join  	OPENXML(@hDocument, '//CASHITEM', 2)
			WITH (TRANSENTITYNO int 'TRANSENTITYNO/text()', TRANSNO INT 'TRANSNO/text()') XC
			on ( XC.TRANSENTITYNO=DETAIL.TRANSENTITYNO AND XC.TRANSNO = DETAIL.TRANSNO)
			JOIN BANKACCOUNT 		on (BANKACCOUNT.ACCOUNTOWNER = DETAIL.ENTITYNO
							and BANKACCOUNT.BANKNAMENO = DETAIL.BANKNAMENO
							and BANKACCOUNT.SEQUENCENO = DETAIL.SEQUENCENO)
			JOIN EFTDETAIL			on (EFTDETAIL.ACCOUNTOWNER = BANKACCOUNT.ACCOUNTOWNER
							and EFTDETAIL.BANKNAMENO = BANKACCOUNT.BANKNAMENO
							and EFTDETAIL.SEQUENCENO = BANKACCOUNT.SEQUENCENO)	
			JOIN CASHITEM AS PAYMENT	on ( PAYMENT.TRANSFERENTITYNO = DETAIL.TRANSENTITYNO 
							and PAYMENT.TRANSFERTRANSNO = DETAIL.TRANSNO)		
			LEFT JOIN BANKACCOUNT AS SUPPLIERBA 	on (SUPPLIERBA.ACCOUNTOWNER = PAYMENT.ENTITYNO
								and SUPPLIERBA.BANKNAMENO = PAYMENT.BANKNAMENO
								and SUPPLIERBA.SEQUENCENO = PAYMENT.SEQUENCENO)	 
			for xml explicit"

		Exec @nErrorCode=sp_executesql @sSQLString,
		N' @hDocument	int',
		   @hDocument 	= @hDocument

		If @pbDebug = 1
		begin
			print @sSQLString
		end
	End

	If @bSelfBalancing = 1
	Begin
		If @nErrorCode = 0
		Begin
			-- ABA Self-Balancing row - for all detail rows
			set @sSQLString = "
				select distinct 1 as TAG, 0 as PARENT,
				'1'					AS [Detail!1!RECORDTYPE!element],
				SUPPLIERBA.BANKBRANCHNO 		AS [Detail!1!SUPPLIERBSB!element], 		-- 7 CHARS
				SUPPLIERBA.ACCOUNTNO 			AS [Detail!1!SUPPLIERACCOUNTNO!element],	-- RIGHT JUSTIFIED, BLANK FILLED, 9 CHARS (IF OVER NINE REMOVE ANY HYPHENS)
															-- FOLLOWED BY 1 BLANK
				'13' 					AS [Detail!1!TRANSACTIONCODE!element],		-- SQA10601 changed from 53
				@nTotalLocalAmount			AS [Detail!1!LOCALAMOUNT!element], 		-- RIGHT JUSTIFIED, 0 FILLED, 1O CHRS, NO PUNCTUATION
				SUPPLIERBA.ACCOUNTNAME 			AS [Detail!1!SUPPLIERACCOUNTTITLE!element],	-- LEFT JUSTIFIED, BLANK FILLED, 32 CHARS
				EFTDETAIL.PAYMENTREFPREFIX		AS [Detail!1!LODGEMENTREFNO!element], 		-- ?? LEFT JUSTIFIED, BLANK FILLED, 18 CHARS
				BANKACCOUNT.BANKBRANCHNO 		AS [Detail!1!TRACEBSB!element],			-- 7 CHARS
				BANKACCOUNT.ACCOUNTNO 			AS [Detail!1!TRACEACCOUNTNO!element],		-- RIGHT JUSTIFIED, BLANK FILLED, 9 CHARS
				EFTDETAIL.ALIAS				AS [Detail!1!NAMEOFREMITTER!element],		-- LEFT JUSTIFIED, BLANK FILLED, 16 CHARS
				'00000000'				AS [Detail!1!WITHHOLDINGTAX!element]
		
				FROM CASHITEM DETAIL
				join  	OPENXML(@hDocument, '//CASHITEM', 2)
				WITH (TRANSENTITYNO int 'TRANSENTITYNO/text()', TRANSNO INT 'TRANSNO/text()') XC
				on ( XC.TRANSENTITYNO=DETAIL.TRANSENTITYNO AND XC.TRANSNO = DETAIL.TRANSNO)
		
				JOIN BANKACCOUNT 		on (BANKACCOUNT.ACCOUNTOWNER = DETAIL.ENTITYNO
								and BANKACCOUNT.BANKNAMENO = DETAIL.BANKNAMENO
								and BANKACCOUNT.SEQUENCENO = DETAIL.SEQUENCENO)
				JOIN EFTDETAIL			on (EFTDETAIL.ACCOUNTOWNER = BANKACCOUNT.ACCOUNTOWNER
								and EFTDETAIL.BANKNAMENO = BANKACCOUNT.BANKNAMENO
								and EFTDETAIL.SEQUENCENO = BANKACCOUNT.SEQUENCENO)	
				JOIN CASHITEM AS PAYMENT	on ( PAYMENT.TRANSFERENTITYNO = DETAIL.TRANSENTITYNO 
								and PAYMENT.TRANSFERTRANSNO = DETAIL.TRANSNO)		
				LEFT JOIN BANKACCOUNT AS SUPPLIERBA 	on (SUPPLIERBA.ACCOUNTOWNER = PAYMENT.ENTITYNO
								and SUPPLIERBA.BANKNAMENO = PAYMENT.BANKNAMENO
								and SUPPLIERBA.SEQUENCENO = PAYMENT.SEQUENCENO)		

				for xml explicit"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@hDocument	int,
				@nTotalLocalAmount	decimal (13,2)',
				@hDocument 		= @hDocument,
				@nTotalLocalAmount	= @nTotalLocalAmount

			If @pbDebug = 1
			begin
				print @sSQLString
				select @nTotalLocalAmount
			end
		End
	END

	--Set the Net total for the Trailer Row.
	If @nErrorCode = 0
	Begin		
		If @bSelfBalancing = 1
		Begin
			Set @nTotalNetAmount = 0
			Set @nTotalDebit = @nTotalLocalAmount
			Set @nTotalCount = @nTotalCount + 1
		End
		Else
		Begin
			Set @nTotalNetAmount = @nTotalLocalAmount
			Set @nTotalDebit = 0
		End
	End

	If @nErrorCode = 0
	Begin
		-- ABA trailer
		set @sSQLString = "
			select 1 as TAG, 0 as PARENT,
			'7'				AS [Trailer!1!RECORDTYPE!element],
			'999-999'			AS [Trailer!1!DUMMYBSB!element],
												-- FOLLOWED BY 12 BLANKS
			@nTotalNetAmount		AS [Trailer!1!FILENETTOTAL!element], 	-- RIGHT JUSTIFIED, 0 FILLED, 1OCHRS, NO PUNCTUATION
			@nTotalLocalAmount		AS [Trailer!1!FILECREDITTOTAL!element], -- RIGHT JUSTIFIED, 0 FILLED, 1OCHRS, NO PUNCTUATION
			@nTotalDebit			AS [Trailer!1!FILEDEBITTOTAL!element],	-- RIGHT JUSTIFIED, 0 FILLED, 1OCHRS, NO PUNCTUATION
												-- FOLLOWED BY 24 BLANKS
			@nTotalCount			AS [Trailer!1!TOTALCOUNT!element]	-- RIGHT JUSTIFIED, 0 FILLED, 6 CHARS
												-- FOLLOWED BY 40 BLANKS
			for xml explicit"

		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nTotalLocalAmount	decimal (13,2),
	    	  @nTotalCount		int,
		  @nTotalNetAmount	decimal (13,2),
		  @nTotalDebit		decimal (13,2)',
		  @nTotalLocalAmount,
	    	  @nTotalCount,
		  @nTotalNetAmount,
		  @nTotalDebit

		If @pbDebug = 1
		begin
			print @sSQLString
			select @nTotalLocalAmount,
			    	  @nTotalCount,
				  @nTotalNetAmount,
				  @nTotalDebit
		end
	End
End

Else
If (@nEFTFileFormat = @nEFTFileFormatSWIFT)
Begin

	If @nErrorCode = 0
	Begin
		-- SWIFT Detail - for each payment
			select 1 as TAG, 0 as PARENT,
			DETAIL.TRANSNO				AS [Detail!1!TRANSNO!element],
			DETAIL.ITEMREFNO			AS [Detail!1!SENDERSREF!element], 			-- :20: 16 CHARS
			DETAIL.FXDEALERREF			AS [Detail!1!FXDEALERREF!element],
			BOC.USERCODE				AS [Detail!1!BANKOPERATIONCODE!element],		-- :23B: 4 CHARS
			CONVERT(DATETIME, DETAIL.ITEMDATE, 126)	AS [Detail!1!DATE!element],				-- :32A: YYMMDD
			BANKACCOUNT.CURRENCY			AS [Detail!1!INSTRUCTEDCURRENCY!element],		-- :33B: 3 CHARS		
			ABS(DETAIL.BANKAMOUNT)			AS [Detail!1!INSTRUCTEDAMOUNT!element],			-- :33B: FORMATTED WITH A COMMA MAX 15 CHARS	
			ISNULL(DETAIL.PAYMENTCURRENCY, 
				BANKACCOUNT.CURRENCY)		AS [Detail!1!PAYMENTCURRENCY!element],			-- :32A: 3 CHARS
			ABS(ISNULL(DETAIL.PAYMENTAMOUNT, 
				DETAIL.BANKAMOUNT))		AS [Detail!1!PAYMENTAMOUNT!element],			-- :32A: FORMATTED WITH A COMMA MAX 15 CHARS
			
			CASE WHEN DETAIL.BANKAMOUNT = 0 THEN 0 ELSE
				ABS(ISNULL(DETAIL.PAYMENTAMOUNT, DETAIL.BANKAMOUNT)) / 
					ABS(DETAIL.BANKAMOUNT) 
			END					AS [Detail!1!EXCHANGERATE!element],			-- :36: FORMATTED WITH A COMMA MAX 12 CHARS
				
			BANKACCOUNT.ACCOUNTNO			AS [Detail!1!ORDERINGCUSTOMERACCT!element],		-- :50A: OR :50K: MAX 34 CHARS
			BANKACCOUNT.IBAN			AS [Detail!1!ODERINGCUSTOMERACCTIBAN!element],
			BANKACCOUNT.BANKBRANCHNO		AS [Detail!1!ODERINGCUSTOMERACCTBSB!element],
	
			EFTDETAIL.BANKCODE			AS [Detail!1!ORDERINGCUSTOMERACCTBC!element],		-- :50A:
			EFTDETAIL.COUNTRYCODE			AS [Detail!1!ORDERINGCUSTOMERACCTCC!element],		-- :50A:
			EFTDETAIL.LOCATIONCODE			AS [Detail!1!ORDERINGCUSTOMERACCTLC!element],		-- :50A:
			EFTDETAIL.BRANCHCODE			AS [Detail!1!ORDERINGCUSTOMERACCTBRC!element],		-- :50A:

			EFTDETAIL.APPLICATIONID			AS [Detail!1!ORDERINGCUSTOMERAPPID!element],
	
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(DETAIL.ACCTENTITYNO, 'PAY'),1) 
								AS [Detail!1!ORDERINGCUSTOMERADD1!element], 		-- :50K: MAX 4 LINES EACH OF MAX 35 CHARS
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(DETAIL.ACCTENTITYNO, 'PAY'),2) 
								AS [Detail!1!ORDERINGCUSTOMERADD2!element],
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(DETAIL.ACCTENTITYNO, 'PAY'),3) 
								AS [Detail!1!ORDERINGCUSTOMERADD3!element],
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(DETAIL.ACCTENTITYNO, 'PAY'),4) 
								AS [Detail!1!ORDERINGCUSTOMERADD4!element],
	
			SUPPLIERBA.ACCOUNTNO			AS [Detail!1!BENEFCUSTOMERACCT!element],		-- :59: OR :59A: MAX 34 CHARS
			SUPPLIERBA.IBAN				AS [Detail!1!BENEFCUSTOMERACCTIBAN!element],		-- :59: OR :59A: MAX 34 CHARS 
			SUPPLIERBA.BANKBRANCHNO			AS [Detail!1!BENEFCUSTOMERACCTBSB!element],
			
			SUPPLIEREFT.BANKCODE			AS [Detail!1!BENEFCUSTOMERACCTBC!element],		-- :59A:
			SUPPLIEREFT.COUNTRYCODE			AS [Detail!1!BENEFCUSTOMERACCTCC!element],		-- :59A:
			SUPPLIEREFT.LOCATIONCODE		AS [Detail!1!BENEFCUSTOMERACCTLC!element],		-- :59A:
			SUPPLIEREFT.BRANCHCODE			AS [Detail!1!BENEFCUSTOMERACCTBRC!element],		-- :59A:

			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(PAYMENT.ENTITYNO, 'PAY'),1) 
								AS [Detail!1!BENEFCUSTOMERADD1!element], 		-- :59:  -- MAX 4 LINES EACH OF MAX 35 CHARS NAME ADDRESS FOR THE SUPPLIER
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(PAYMENT.ENTITYNO, 'PAY'),2) 
								AS [Detail!1!BENEFCUSTOMERADD2!element],
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(PAYMENT.ENTITYNO, 'PAY'),3) 
								AS [Detail!1!BENEFCUSTOMERADD3!element],
			dbo.fn_SplitTextOnCarriageReturn(dbo.fn_GetMailingLabel(PAYMENT.ENTITYNO, 'PAY'),4) 
								AS [Detail!1!BENEFCUSTOMERADD4!element],
	
			DOC.USERCODE				AS [Detail!1!DETAILSOFCHARGES!element]			-- :71A: 3 CHARS
	
			FROM CASHITEM DETAIL
			join  	OPENXML(@hDocument, '//CASHITEM', 2)
			WITH (TRANSENTITYNO int 'TRANSENTITYNO/text()', TRANSNO INT 'TRANSNO/text()') XC
		 	on ( XC.TRANSENTITYNO=DETAIL.TRANSENTITYNO AND XC.TRANSNO = DETAIL.TRANSNO)
			JOIN BANKACCOUNT 			on (BANKACCOUNT.ACCOUNTOWNER = DETAIL.ENTITYNO
								and BANKACCOUNT.BANKNAMENO = DETAIL.BANKNAMENO
								and BANKACCOUNT.SEQUENCENO = DETAIL.SEQUENCENO)
			
			JOIN EFTDETAIL				on (EFTDETAIL.ACCOUNTOWNER = BANKACCOUNT.ACCOUNTOWNER
								and EFTDETAIL.BANKNAMENO = BANKACCOUNT.BANKNAMENO
								and EFTDETAIL.SEQUENCENO = BANKACCOUNT.SEQUENCENO)
			
			JOIN CASHITEM AS PAYMENT		on (PAYMENT.TRANSFERENTITYNO = DETAIL.TRANSENTITYNO 
								and PAYMENT.TRANSFERTRANSNO = DETAIL.TRANSNO)		
			LEFT JOIN BANKACCOUNT AS SUPPLIERBA 	on (SUPPLIERBA.ACCOUNTOWNER = PAYMENT.ENTITYNO
								and SUPPLIERBA.BANKNAMENO = PAYMENT.BANKNAMENO
								and SUPPLIERBA.SEQUENCENO = PAYMENT.SEQUENCENO)	
			LEFT JOIN EFTDETAIL	AS SUPPLIEREFT	ON (SUPPLIEREFT.ACCOUNTOWNER = SUPPLIERBA.ACCOUNTOWNER
								and SUPPLIEREFT.BANKNAMENO = SUPPLIERBA.BANKNAMENO
								and SUPPLIEREFT.SEQUENCENO = SUPPLIERBA.SEQUENCENO)
			LEFT JOIN TABLECODES AS BOC 		ON (BOC.TABLECODE = DETAIL.BANKOPERATIONCODE
								AND BOC.TABLETYPE = 96)
			LEFT JOIN TABLECODES AS DOC 		ON (DOC.TABLECODE = DETAIL.DETAILSOFCHARGES
								AND DOC.TABLETYPE = 97)
			WHERE DETAIL.BANKAMOUNT <> 0
			for xml explicit

	End


End

If @nErrorCode = 0	
Begin	
	Exec sp_xml_removedocument @hDocument 
	Set @nErrorCode	  = @@Error
End

Return @nErrorCode
go

Grant execute on dbo.xml_EFTTrustTransfer to public
GO
