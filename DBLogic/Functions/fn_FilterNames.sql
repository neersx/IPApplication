-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterNames') and xtype='FN')
begin
	print '**** Drop function dbo.fn_FilterNames.'
	drop function dbo.fn_FilterNames
	print '**** Creating function dbo.fn_FilterNames...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterNames 
			(	
			@pnUserIdentityId		int,			-- Mandatory
			@pbIsOrganisation		bit		= null,
			@pbIsIndividual			bit		= null,
			@pbIsClient			bit		= null,
			@pbIsStaff			bit		= null,
			@pbIsCurrent			bit		= null,
			@pbIsCeased			bit		= null,
			@psSearchKey			nvarchar(20)	= null,
			@pbUseSearchKey1		bit		= null,
			@pbUseSearchKey2		bit		= null,
			@pnSearchKeyOperator		int		= null,
			@pbSoundsLike			bit		= null,
			@psNameCode			nvarchar(10)	= null,
			@pnNameCodeOperator		tinyint		= null,
			@psName				nvarchar(254) 	= null,
			@pnNameOperator			tinyint 	= null,
			@psFirstName			nvarchar(50)	= null,
			@pnFirstNameOperator		tinyint		= null,
			@pdtLastChangedFromDate		datetime	= null,
			@pdtLastChangedToDate		datetime	= null,
			@pnLastChangedOperator		tinyint		= null,
			@psRemarks			nvarchar(254)	= null,
			@pnRemarksOperator		tinyint		= null,
			@psCountryKey			nvarchar(3)	= null,
			@pnCountryKeyOperator		tinyint		= null, 
			@psStateKey			nvarchar(20)	= null,
			@pnStateKeyOperator		tinyint		= null,
			@psCity				nvarchar(30)	= null,
			@pnCityOperator			tinyint		= null,
			@pnNameGroupKey			smallint	= null, 
			@pnNameGroupKeyOperator		tinyint		= null,
			@psNameTypeKey			nvarchar(3)	= null,
			@pnNameTypeKeyOperator		tinyint		= null,
			@psAirportKey			nvarchar(5)	= null,
			@pnAirportKeyOperator		tinyint		= null,
			@pnNameCategoryKey		int		= null,
			@pnNameCategoryKeyOperator	tinyint		= null,
			@pnBadDebtorKey			int		= null,
			@pnBadDebtorKeyOperator		tinyint		= null,
			@psFilesInKey			nvarchar(3)	= null,
			@pnFilesInKeyOperator		tinyint		= null,
			@psTextTypeKey			nvarchar(2)	= null,
			@psText				nvarchar(max)	= null,
			@pnTextOperator			tinyint		= null,
			@pnInstructionKey		int		= null,
			@pnInstructionKeyOperator	tinyint		= null,
			@pnParentNameKey		int		= null,
			@pnParentNameKeyOperator	tinyint		= null,
			@psRelationshipKey		nvarchar(3)	= null,
			@pnRelationshipKeyOperator	tinyint		= null,
			@pbIsReverseRelationship	bit		= null,
			@psAssociatedNameKeys		nvarchar(max)	= null,
			@pnAssociatedNameKeyOperator	tinyint		= null,
			@psMainPhoneNumber		nvarchar(50)	= null,
			@pnMainPhoneNumberOperator	tinyint		= null,
			@psMainPhoneAreaCode		nvarchar(5)	= null,
			@pnMainPhoneAreaCodeOperator	tinyint		= null,
			@pnAttributeTypeKey1		int		= null,
			@pnAttributeKey1		int		= null,
			@pnAttributeKey1Operator	tinyint		= null,
			@pnAttributeTypeKey2		int		= null,
			@pnAttributeKey2		int		= null,
			@pnAttributeKey2Operator	tinyint		= null,
			@psAliasTypeKey			nvarchar(2)	= null,
			@psAlias			nvarchar(20)	= null,
			@pnAliasOperator		tinyint		= null,
			@pnQuickIndexKey		int		= null,
			@pnQuickIndexKeyOperator	tinyint		= null,
			@psBillingCurrencyKey		nvarchar(3)	= null,
			@pnBillingCurrencyKeyOperator	tinyint		= null,
			@psTaxRateKey			nvarchar(3)	= null,
			@pnTaxRateKeyOperator		tinyint		= null,
			@pnDebtorTypeKey		int		= null,
			@pnDebtorTypeKeyOperator	tinyint		= null,
			@psPurchaseOrderNo		nvarchar(20)	= null,
			@pnPurchaseOrderNoOperator	tinyint		= null,
			@pnReceivableTermsFromDays	int		= null,
			@pnReceivableTermsToDays	int		= null,
			@pnReceivableTermsOperator	tinyint		= null,
			@pnBillingFrequencyKey		int		= null,
			@pnBillingFrequencyKeyOperator	tinyint		= null,
			@pbIsLocalClient		bit		= null,
			@pnIsLocalClientOperator	tinyint		= null)
Returns nvarchar(max)

-- FUNCTION :	fn_FilterNames
-- VERSION :	14
-- DESCRIPTION:	This function accepts the variables that may be used to filter Names and
--		constructs a JOIN and WHERE clause. 

-- MODIFICTION HISTORY
-- Date		Who	Number	Version	Change
-- ------------ ------- ------	------- ----------------------------------------------------------------
-- 10/09/2002	MF		1	Function created
-- 20/09/2002	MF		2	If the PicklistSearch returns no rows then it should default the
--					query to one that will return no rows.
-- 30/09/2002	JB		3	The alias XNA was being used twice.  Changed to XNA2
-- 15/10/2002	MF		4	If the PicklistSearch falls through to SEARCHKEY2 then it should
--					also check the Soundex of the name.
-- 24 Oct 2002	JEK		5	Names with UsedAsFlag = 0 being returned for IsIndividual, IsClient, IsStaff
--					Treat IsClient as an AND condition instead of an OR condition.
-- 06/11/2002	MF		6	Remove the searching on PickListSearch as this has been moved to the calling procedure.
-- 17/07/2003	TM	RFC76	9	Case Insensitive searching	
-- 07 Nov 2003	MF	RFC586	10	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 02 Sep 2004	JEK	RFC1377	10	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 30 Jan 2007	PY	SQA12521 11	Replace function call Soundex with fn_SoundsLike
-- 15 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Apr 2011	MF	RFC10475 13	Change nvarchar(4000) to nvarchar(max)
-- 16 Apr 2013	ASH	R13270 14	Change varchar(10) to varchar(11)

as
Begin
	-- declare variables
	declare @ErrorCode	int,
		@sSQLString	nvarchar(max),
		@sReturnClause	nvarchar(max),
		@sFrom		nvarchar(max),
		@sWhere		nvarchar(max),
		@sInOperator	nvarchar(6),
		@sOperator	nvarchar(6),
		@sOr		nvarchar(4),
		@nSaveOperator	tinyint

	-- declare some constants
	declare @String		nchar(1),
		@Date		nchar(2),
		@Numeric	nchar(1),
		@Text		nchar(1)

	Set	@String ='S'
	Set	@Date   ='DT'
	Set	@Numeric='N'
	Set	@Text   ='T'

	-- Case Insensitive searching

	set @psSearchKey 	= upper(@psSearchKey)
	set @psNameCode		= upper(@psNameCode)
	set @psRemarks 		= upper(@psRemarks)
	set @psCity		= upper(@psCity)
	set @psAlias 		= upper(@psAlias)
	set @psPurchaseOrderNo  = upper(@psPurchaseOrderNo)
	
	


	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"	WHERE 1=1"

 	set @sFrom  = char(10)+"	FROM      NAME XN"

	If @pbIsOrganisation=1
	or @pbIsIndividual  =1
	or @pbIsStaff       =1
	begin
		set @sWhere = @sWhere+char(10)+"	and ("
		
		If @pbIsOrganisation=1
		Begin
			set @sWhere=@sWhere+"XN.USEDASFLAG&1=0"
			set @sOr=' OR '
		End
		
		If @pbIsIndividual=1
		Begin
			set @sWhere=@sWhere+@sOr+"XN.USEDASFLAG&1=1"
			set @sOr=' OR '
		End
		
		If @pbIsStaff=1
		Begin
			set @sWhere=@sWhere+@sOr+"XN.USEDASFLAG&2=2"
			set @sOr=' OR '
		End

		set @sWhere = @sWhere+")"	
	end

	If @pbIsClient=1
	begin	
		set @sWhere = @sWhere+char(10)+"	and XN.USEDASFLAG&4=4"
	end

	If   @pbIsCurrent=1
	and (@pbIsCeased =0 or @pbIsCeased is NULL)
	begin
		set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED is null OR XN.DATECEASED>getdate())"
	End
	Else If   @pbIsCeased=1
	     and (@pbIsCurrent=0 or @pbIsCurrent is NULL)
	begin
		set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED <=getdate())"
	end

	If (@psSearchKey is not NULL
	 or @pnSearchKeyOperator between 2 and 6)
	AND(@pbUseSearchKey1=1 OR @pbUseSearchKey2=1)
	Begin
		Set @sWhere = @sWhere+char(10)+"	and ("
		Set @sOr    = NULL

		If @pbUseSearchKey1=1
		Begin
			set @sWhere = @sWhere+"upper(XN.SEARCHKEY1)"+dbo.fn_ConstructOperator(@pnSearchKeyOperator,@String,@psSearchKey, null,0)
			set @sOr    =' OR '
		End

		If @pbUseSearchKey2=1
		Begin
			set @sWhere = @sWhere+@sOr+"upper(XN.SEARCHKEY2)"+dbo.fn_ConstructOperator(@pnSearchKeyOperator,@String,@psSearchKey, null,0)
		End
	
		Set @sWhere=@sWhere+")"
	End

	If @pbSoundsLike=1
	and (@psName is not null OR @psSearchKey is not null)
	Begin
		If @psName is not null
			Set @sWhere=@sWhere+char(10)+"	and dbo.fn_SoundsLike(XN.NAME)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@psName,0,0)+")"
		Else
			Set @sWhere=@sWhere+char(10)+"	and dbo.fn_SoundsLike(XN.NAME)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@psSearchKey,0,0)+")"
	End

	If  @psNameCode is not NULL
	 or @pnNameCodeOperator between 2 and 6
	Begin
		If isnumeric(@psNameCode)=1
		Begin
			Select @psNameCode=Replicate('0',S.COLINTEGER-len(@psNameCode))+@psNameCode 
			From SITECONTROL S
			Where S.CONTROLID='NAMECODELENGTH'
		End

		set @sWhere=@sWhere+char(10)+"	and upper(XN.NAMECODE)"+dbo.fn_ConstructOperator(@pnNameCodeOperator,@String,@psNameCode, null,0)
	End

	If @psName is not NULL
	or @pnNameOperator between 2 and 6
	Begin
		set @sWhere=@sWhere+char(10)+"	and upper(XN.NAME)"+dbo.fn_ConstructOperator(@pnNameOperator,@String,upper(@psName), null,0)
	End

	If @psFirstName is not NULL
	or @pnFirstNameOperator between 2 and 6
	Begin
		set @sWhere=@sWhere+char(10)+"	and upper(XN.FIRSTNAME)"+dbo.fn_ConstructOperator(@pnFirstNameOperator,@String,upper(@psFirstName), null,0)
	End

	If @pdtLastChangedFromDate is not NULL
	or @pdtLastChangedToDate   is not NULL
	or @pnLastChangedOperator between 2 and 6
	Begin
		set @sWhere=@sWhere+char(10)+"	and isnull(XN.DATECHANGED, XN.DATEENTERED)"+dbo.fn_ConstructOperator(@pnLastChangedOperator,@Date,@pdtLastChangedFromDate, @pdtLastChangedToDate,0)
	End

	If @psRemarks is not NULL
	or @pnRemarksOperator between 2 and 6
	Begin
		set @sWhere=@sWhere+char(10)+"	and upper(XN.REMARKS)"+dbo.fn_ConstructOperator(@pnRemarksOperator,@String,@psRemarks, null,0)
	End
	
	if @psCountryKey is not null
	or @pnCountryKeyOperator between 2 and 6
	or @psStateKey   is not null
	or @pnStateKeyOperator between 2 and 6
	or @psCity       is not null
	or @pnCityOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join NAMEADDRESS XNA on (XNA.NAMENO=XN.NAMENO"
				   +char(10)+"	                          and(XNA.DATECEASED is null OR XNA.DATECEASED>getdate()))"
				   +char(10)+"	left join ADDRESS XA      on (XA.ADDRESSCODE=XNA.ADDRESSCODE)"

		if @psCountryKey is not null
		or @pnCountryKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XA.COUNTRYCODE"+dbo.fn_ConstructOperator(@pnCountryKeyOperator,@String,@psCountryKey, null,0)

		if @psStateKey is not null
		or @pnStateKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XA.STATE"+dbo.fn_ConstructOperator(@pnStateKeyOperator,@String,@psStateKey, null,0)

		if @psCity is not null
		or @pnCityOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	upper(XA.CITY)"+dbo.fn_ConstructOperator(@pnCityOperator,@String,@psCity, null,0)
	end

	If @pnNameGroupKey is not NULL
	or @pnNameGroupKeyOperator between 2 and 6
	Begin
		set @sWhere=@sWhere+char(10)+"	and XN.FAMILYNO"+dbo.fn_ConstructOperator(@pnNameGroupKeyOperator,@Numeric,@pnNameGroupKey, null,0)
	End
	
	if @psNameTypeKey is not null
	or @pnNameTypeKeyOperator between 2 and 6
	begin
		If @pnNameTypeKeyOperator in (0,2,3,4,5,7)
			set @sWhere =@sWhere+char(10)+" and exists"
		Else
			set @sWhere =@sWhere+char(10)+" and not exists"

		set @sWhere =@sWhere+char(10)+" (select * from CASENAME XCN"
				    +char(10)+"  where XCN.NAMENO=XN.NAMENO"
				    +char(10)+"  and  (XCN.EXPIRYDATE is null OR XCN.EXPIRYDATE>getdate())"

		If @pnNameTypeKeyOperator in (0,2,3,4,7)
			set @sWhere =@sWhere+char(10)+"	 and   XCN.NAMETYPE"+dbo.fn_ConstructOperator(@pnNameTypeKeyOperator,@String,@psNameTypeKey, null,0)+")"
		Else
			set @sWhere =@sWhere+")"
	end
	
	if @psAirportKey is not null
	or @pnAirportKeyOperator between 2 and 6
	or @pnNameCategoryKey is not null
	or @pnNameCategoryKeyOperator between 2 and 6
	or @pnBadDebtorKey is not null
	or @pnBadDebtorKeyOperator between 2 and 6
	or @psBillingCurrencyKey is not null
	or @pnBillingCurrencyKeyOperator between 2 and 6
	or @psTaxRateKey is not null
	or @pnTaxRateKeyOperator between 2 and 6
	or @pnDebtorTypeKey is not null
	or @pnDebtorTypeKeyOperator between 2 and 6
	or @psPurchaseOrderNo is not null
	or @pnPurchaseOrderNoOperator between 2 and 6
	or @pnReceivableTermsFromDays is not null
	or @pnReceivableTermsToDays is not null
	or @pnReceivableTermsOperator between 2 and 6
	or @pnBillingFrequencyKey is not null
	or @pnBillingFrequencyKeyOperator between 2 and 6
	or @pbIsLocalClient is not null
	or @pnIsLocalClientOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join IPNAME XIP on (XIP.NAMENO=XN.NAMENO)"

		if @pbIsLocalClient is not null
		or @pnIsLocalClientOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.LOCALCLIENTFLAG"+dbo.fn_ConstructOperator(@pnIsLocalClientOperator,@Numeric,@pbIsLocalClient, null,0)

		if @pnBillingFrequencyKey is not null
		or @pnBillingFrequencyKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.BILLINGFREQUENCY"+dbo.fn_ConstructOperator(@pnBillingFrequencyKeyOperator,@Numeric,@pnBillingFrequencyKey, null,0)

		if @pnReceivableTermsFromDays is not null
		or @pnReceivableTermsToDays is not null
		or @pnReceivableTermsOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.TRADINGTERMS"+dbo.fn_ConstructOperator(@pnReceivableTermsOperator,@Numeric,@pnReceivableTermsFromDays, @pnReceivableTermsToDays,0)

		if @psPurchaseOrderNo is not null
		or @pnPurchaseOrderNoOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	upper(XIP.PURCHASEORDERNO)"+dbo.fn_ConstructOperator(@pnPurchaseOrderNoOperator,@String,@psPurchaseOrderNo, null,0)

		if @pnDebtorTypeKey is not null
		or @pnDebtorTypeKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.DEBTORTYPE"+dbo.fn_ConstructOperator(@pnDebtorTypeKeyOperator,@Numeric,@pnDebtorTypeKey, null,0)

		if @psTaxRateKey is not null
		or @pnTaxRateKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.TAXCODE"+dbo.fn_ConstructOperator(@pnTaxRateKeyOperator,@String,@psTaxRateKey, null,0)

		if @psBillingCurrencyKey is not null
		or @pnBillingCurrencyKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.CURRENCY"+dbo.fn_ConstructOperator(@pnBillingCurrencyKeyOperator,@String,@psBillingCurrencyKey, null,0)

		if @psAirportKey is not null
		or @pnAirportKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.AIRPORTCODE"+dbo.fn_ConstructOperator(@pnAirportKeyOperator,@String,@psAirportKey, null,0)

		if @pnNameCategoryKey is not null
		or @pnNameCategoryKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.CATEGORY"+dbo.fn_ConstructOperator(@pnNameCategoryKeyOperator,@Numeric,@pnNameCategoryKey, null,0)

		if @pnBadDebtorKey is not null
		or @pnBadDebtorKeyOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XIP.BADDEBTOR"+dbo.fn_ConstructOperator(@pnBadDebtorKeyOperator,@Numeric,@pnBadDebtorKey, null,0)
	end
	
	if @psFilesInKey is not null
	or @pnFilesInKeyOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join FILESIN XFI on (XFI.NAMENO=XN.NAMENO)"

		set @sWhere =@sWhere+char(10)+"	and	XFI.COUNTRYCODE"+dbo.fn_ConstructOperator(@pnFilesInKeyOperator,@String,@psFilesInKey, null,0)
	end
		
	if @psTextTypeKey is not null
	or @psText        is not null
	or @pnTextOperator between 2 and 6
	begin
		If @pnTextOperator in (0,2,3,4,5,7)
			set @sWhere =@sWhere+char(10)+" and exists"
		Else
			set @sWhere =@sWhere+char(10)+" and not exists"

		set @sWhere =@sWhere+char(10)+" (select * from NAMETEXT XNT"
				    +char(10)+"  where XNT.NAMENO=XN.NAMENO"
		
		If @psTextTypeKey is not null
			set @sWhere =@sWhere+char(10)+"  and XNT.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey,0,0)

		-- If the Operator is 1 (not equal) then change to 0 (equal) because of the 
		-- NOT EXISTS clause
		If @pnTextOperator=1
			set @pnTextOperator=0

		If @pnTextOperator in (0,2,3,4,7)
			set @sWhere =@sWhere+char(10)+"  and XNT.TEXT"+dbo.fn_ConstructOperator(@pnTextOperator,@Text,@psText, null,0)+")"
		Else
			set @sWhere =@sWhere+")"
	end
	
	if @pnInstructionKey is not null
	or @pnInstructionKeyOperator between 2 and 6
	begin
		If @pnInstructionKeyOperator in (0,2,3,4,7,8)
		Begin
			set @sFrom = @sFrom+char(10)+"	left join NAMEINSTRUCTIONS XNI on (XNI.NAMENO=XN.NAMENO"
					   +char(10)+"	                               and XNI.CASEID is null)"

			set @sWhere =@sWhere+char(10)+"	and	XNI.INSTRUCTIONCODE"+dbo.fn_ConstructOperator(@pnInstructionKeyOperator,@Numeric,@pnInstructionKey, null,0)
		End
		Else Begin
			If @pnInstructionKeyOperator in (5)
				set @sWhere =@sWhere+char(10)+" and exists"
			Else
				set @sWhere =@sWhere+char(10)+" and not exists"

			set @sWhere =@sWhere+char(10)+" (select * from NAMEINSTRUCTIONS XNI"
					    +char(10)+"  where XNI.NAMENO=XN.NAMENO"

			-- If the Operator is 1 (not equal) then change to 0 (equal) because of the 
			-- NOT EXISTS clause
			If @pnInstructionKeyOperator=1
				set @sWhere=@sWhere+char(10)+"  and XNI.INSTRUCTIONCODE="+cast(@pnInstructionKey as varchar)

			set @sWhere =@sWhere+")"
		End
	end
	
	If @pnParentNameKey is not null
	or @pnParentNameKeyOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join ORGANISATION XO on (XO.NAMENO=XN.NAMENO)"

		set @sWhere =@sWhere+char(10)+"	and	XO.PARENT"+dbo.fn_ConstructOperator(@pnParentNameKeyOperator,@Numeric,@pnParentNameKey, null,0)
	end
	
	If @psRelationshipKey is not null
	or @pnRelationshipKeyOperator between 2 and 6
	or @psAssociatedNameKeys is not null
	or @pnAssociatedNameKeyOperator between 2 and 6
	Begin
		Set @nSaveOperator = null

		-- The test will be constructed as a subselect with either EXISTS or NOT EXISTS.
		-- This is because there is a one to many relationship between NAME and ASSOCIATEDNAME
		-- and we only want a single row returned if the result of the test is true.

		-- If either Operator is set to NOT NULL then use EXISTS
		If @pnRelationshipKeyOperator  =5
		or @pnAssociatedNameKeyOperator=5
		Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End

		-- If either Operator is set to IS NULL then use NOT EXISTS
		Else
		If @pnRelationshipKeyOperator  =6
		or @pnAssociatedNameKeyOperator=6
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"
		End

		-- If either Operator is set to EQUAL then use EXISTS
		Else 
		If @pnRelationshipKeyOperator  =0
		or @pnAssociatedNameKeyOperator=0
		Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End

		-- If either Operator is set to NOT EQUAL then use NOT EXISTS
		Else 
		If @pnRelationshipKeyOperator  =1
		or @pnAssociatedNameKeyOperator=1
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"
		End

		Else Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End

		set @sWhere=@sWhere+char(10)+"(select * from ASSOCIATEDNAME XAN"
				   +char(10)+" where XN.NAMENO="+CASE WHEN(@pbIsReverseRelationship=1) THEN "XAN.RELATEDNAME" ELSE "XAN.NAMENO" END

		If  @psRelationshipKey is not null
		Begin
			-- Change the Operator because of the NOT EXISTS clause under certain situations
			If  @pnRelationshipKeyOperator=1
			and(@pnAssociatedNameKeyOperator in (1,8) OR @pnAssociatedNameKeyOperator is NULL)
			Begin
				set @nSaveOperator=@pnRelationshipKeyOperator
				set @pnRelationshipKeyOperator=0
			End
			
			If @pnRelationshipKeyOperator not in (5,6)
				set @sWhere=@sWhere+char(10)+" and XAN.RELATIONSHIP"+dbo.fn_ConstructOperator(@pnRelationshipKeyOperator,@String,@psRelationshipKey, null,0)

			If @nSaveOperator is not null
				set @pnRelationshipKeyOperator=@nSaveOperator
		End

		If @psAssociatedNameKeys is not null
		Begin
			If  @pnAssociatedNameKeyOperator=1
			and @pnRelationshipKeyOperator  =5
			Begin
				set @pnAssociatedNameKeyOperator=0
				set @sWhere=@sWhere+")"
					   	   +char(10)+"and not exists"
						   +char(10)+"(select * from ASSOCIATEDNAME XAN1"
						   +char(10)+" where XN.NAMENO="+CASE WHEN(@pbIsReverseRelationship=1) THEN "XAN1.RELATEDNAME" ELSE "XAN1.NAMENO" END
						   +char(10)+CASE WHEN(@pbIsReverseRelationship=1)
								THEN " and XAN1.NAMENO"+dbo.fn_ConstructOperator(@pnAssociatedNameKeyOperator,@Numeric,@psAssociatedNameKeys, null,0)
								ELSE " and XAN1.RELATEDNAME"+dbo.fn_ConstructOperator(@pnAssociatedNameKeyOperator,@Numeric,@psAssociatedNameKeys, null,0)
							     END
			End

			Else Begin
				If  @pnAssociatedNameKeyOperator=1
				and(@pnRelationshipKeyOperator in (1, 5, 6, 8) or @pnRelationshipKeyOperator is NULL)
					set @pnAssociatedNameKeyOperator=0

				If @pnAssociatedNameKeyOperator not in (5,6)
				Begin
					If @pbIsReverseRelationship=1
						set @sWhere =@sWhere+char(10)+" and XAN.NAMENO"+dbo.fn_ConstructOperator(@pnAssociatedNameKeyOperator,@Numeric,@psAssociatedNameKeys, null,0)
					Else
						set @sWhere =@sWhere+char(10)+" and XAN.RELATEDNAME"+dbo.fn_ConstructOperator(@pnAssociatedNameKeyOperator,@Numeric,@psAssociatedNameKeys, null,0)
				End
			End
		End
		
		set @sWhere =@sWhere+")"
	End
	
	If @psMainPhoneNumber is not null
	or @pnMainPhoneNumberOperator between 2 and 6
	or @psMainPhoneAreaCode is not null
	or @pnMainPhoneAreaCodeOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join TELECOMMUNICATION XT on (XT.TELECODE=XN.MAINPHONE)"

		If @psMainPhoneNumber is not null
		or @pnMainPhoneNumberOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XT.TELECOMNUMBER"+dbo.fn_ConstructOperator(@pnMainPhoneNumberOperator,@String,@psMainPhoneNumber, null,0)

		If @psMainPhoneAreaCode is not null
		or @pnMainPhoneAreaCodeOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	XT.AREACODE"+dbo.fn_ConstructOperator(@pnMainPhoneAreaCodeOperator,@String,@psMainPhoneAreaCode, null,0)
	end
	
	if(@pnAttributeKey1 is not NULL and @pnAttributeKey1Operator is not null)
	or @pnAttributeKey1Operator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA1 on (XTA1.PARENTTABLE='NAME'"
				   +char(10)+"	                               and XTA1.TABLETYPE="+convert(varchar,@pnAttributeTypeKey1)
				   +char(10)+"	                               and XTA1.GENERICKEY=convert(varchar,XN.NAMENO))"
			set @sWhere =@sWhere+char(10)+"	and	XTA1.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey1Operator,@Numeric,@pnAttributeKey1, null,0)
	end
	
	if(@pnAttributeKey2 is not NULL and @pnAttributeKey2Operator is not null)
	or @pnAttributeKey2Operator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA2 on (XTA2.PARENTTABLE='NAME'"
				   +char(10)+"	                               and XTA2.TABLETYPE="+convert(varchar,@pnAttributeTypeKey2)
				   +char(10)+"	                               and XTA2.GENERICKEY=convert(varchar,XN.NAMENO))"
			set @sWhere =@sWhere+char(10)+"	and	XTA2.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey2Operator,@Numeric,@pnAttributeKey2, null,0)
	end
	
	If @psAliasTypeKey is not null
	or @psAlias        is not null
	or @pnAliasOperator between 2 and 6
	begin
		set @sFrom = @sFrom+char(10)+"	left join NAMEALIAS XNA2 on (XNA2.NAMENO=XN.NAMENO)"

		If @psAliasTypeKey is not null
			set @sWhere=@sWhere+char(10)+"	and	XNA2.ALIASTYPE="+dbo.fn_WrapQuotes(@psAliasTypeKey,0,0)

		If @psAlias is not null
		or @pnAliasOperator between 2 and 6
			set @sWhere =@sWhere+char(10)+"	and	upper(XNA2.ALIAS)"+dbo.fn_ConstructOperator(@pnAliasOperator,@String,@psAlias, null,0)
	end

	if  @pnQuickIndexKey is not NULL
	and @pnQuickIndexKeyOperator is not NULL
	begin
		set @sFrom = @sFrom+char(10)+"	     join IDENTITYINDEX IX	on (IX.IDENTITYID      = " + cast(@pnUserIdentityId as varchar(11)) +
				   +char(10)+"	                   	and  	IX.INDEXID      = " + cast(@pnQuickIndexKey as varchar(11)) + ")"
		set @sWhere = @sWhere+char(10)+"	and	XN.NAMENO = IX.COLINTEGER"
	end

	set @sReturnClause=@sFrom+char(10)+@sWhere
	Return ltrim(rtrim(@sReturnClause))
End
go

grant execute on dbo.fn_FilterNames to public
GO


				
			
				

