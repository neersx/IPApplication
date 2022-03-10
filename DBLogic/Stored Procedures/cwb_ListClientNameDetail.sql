-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.cwb_ListClientNameDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListClientNameDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListClientNameDetail.'
	Drop procedure [dbo].[cwb_ListClientNameDetail]
End
Print '**** Creating Stored Procedure dbo.cwb_ListClientNameDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListClientNameDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psResultsetsRequired	nvarchar(4000)	= null		-- comma seperated list to describe which resultset to return
)
AS
-- PROCEDURE:	cwb_ListClientNameDetail
-- VERSION:	33
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates ClientNameDetailData dataset. Returns full details regarding a
--		single client name. 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 04-Sep-2003  TM		1	Procedure created
-- 01-Oct-2003	TM		2	RFC332 Client Name Web Part. Use ISNULL instead of COALESCE
--					if the number of arguments is equal to two. Remove 'X' prefix 
--					from the correlation names in the "Count Case details" section.
-- 07-Oct-2003	MF	RFC519	3	Performance improvements to fn_FilterUserNames
-- 29-Oct-2003	TM	RFC495	4	Subset site control implementation with patindex. Enhance the 
--					existing logic that implements patindex to find the matching item 
--					in the following manner:
--					before change: "where patindex('%'+CL.NAMETYPE+'%',S.COLCHARACTER) > 0"
--					after change:  "where patindex('%'+','+CL.NAMETYPE+','+'%',',' + 
--								       replace(S.COLCHARACTER, ' ', '') + ',')>0
-- 04-Nov-2003	TM	RFC581	5	Design an approach for displaying an image using data from database.
--					IMAGEID is returned instead of IMAGEDATA as ImageKey.
-- 05-Nov-2003	TM	RFC581	6	Design an approach for displaying an image using data from database.
--					Remove join to the IMAGE table.
-- 25-Nov-2003	TM	RFC621	7	Implement the ac_GetAgeingBrackets to return the number of days in each ageing 
--					bracket, and the base date for calculation. 
-- 06-Nov-2003	JEK	RFC406	8	Implement topic level security.
-- 10-Dec-2003	JEK	RFC717	9	Don't return street address if its the same as postal address.
-- 29-Dec-2003	TM	RFC884	10	Use 'derived table' and 'the best fit' approaches to eliminate duplicated 
--					rows when retrieving OurContact. Extract 'OurContactKey', 'OurContactName' and 
--					'OurContactRole' separately to avoid SQL to overflow.   
-- 03-Feb-2004	TM	RFC884	11	Implement Mike's feedback. Implement 'select min(ASN1.RELATEDNAME)' subquery
--					instead of the 'derived table' and 'the best fit' approaches.  
-- 19-Feb-2004	TM	RFC976	12	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC1032	13	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 10-Mar-2004	TM	RFC868	14	Modify the logic extracting the 'MainEmail' and 'EmailAddress' columns in 
--					the Name Result Set to use new Name.MainEmail column. 
-- 20 Sep 2004	JEK	RFC886	3	Implement translation.
-- 06 Oct 2004	TM	RFC1806	15	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 15 May 2005	JEK	RFC2508	16	Extract @sLookupCulture and pass to translation instead of @psCulture
--					Also pass @sLookupCulture to child procedures that are known not to need the original @psCulture
-- 16 Jan 2006	TM	RFC1659	17	Add new NameVariants result set.
-- 02 Mar 2006	LP	RFC3216	18	Implement call to naw_ListNameAlias to populate the new Alias result set.
-- 06 Mar 2006	TM	RFC3215	19	Implement a call to the new procedure naw_ListStandingInstructions to produce the new result set.
--					In the naw_ListNameAlias, cater for situation when @pnNameKey is null.
--					Also, in the cwb_ListClientNameDetail, minimize the call to the fn_FilterUserNames.
-- 10 Mar 2006	IB	RFC3325	20	Adjust the procedure to return all the names in the scope of 
--					the new fn_FilterUserViewNames function rather than just fn_FilterUserNames.  
--					However, only Access Names (those identified via fn_FilterUserNames) are to have access to all details.
--					If the name is an Access Name, the stored procedure should continue to behave as it does currently.
--					If the requested name key is not an Access Name, then various data should not be returned.  
-- 14 Jul 2006	SW	RFC3828	21	Pass getdate() to fn_Permission..
-- 25 Aug 2006	SF	RFC4214 22	Implement @psResultsetsRequired, reorganise result set and remove Billing Instructions resultset
-- 13 Sep 2006 	SF	RFC4326	23	Optionally Filter out dead cases
-- 23 Apr 2007	SW	RFC4345	24	Exclude Draft Cases from CASECOUNTS result set.
-- 29 May 2007	SW	RFC4345	25	Define Draft Cases as ACTUALCASETYPE IS NULL
-- 22 Jul 2008	AT	RFC5788	26	Return CRM Only flag.
-- 11 Dec 2008	MF	17136	27	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Sep 2011	ASH	R11032 28	Change logic to get Image ID where image order is minimum.
-- 24 Oct 2011	ASH	R11460  29	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	30	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	31	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 10 Nov 2015	KR	R53910	32	Adjust formatted names logic (DR-15543)
-- 14 Nov 2018  AV  75198/DR-45358	33   Date conversion errors when creating cases and opening names in Chinese DB     



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Declare	@nAge0			smallint
Declare	@nAge1			smallint
Declare	@nAge2			smallint
Declare @dtBaseDate 		datetime -- the end date of the current period

Declare @dtTransDate		datetime
Declare @sCurrency		nvarchar(3)
Declare @nReceiptAmount		decimal(11,2)
Declare @bIsBalanceRequired	bit
Declare @nFilterNameKey		int
Declare @nFilterViewNameKey	int

Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint

Declare	@bExcludeDeadCases	bit

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @dtToday		datetime

Set 	@nErrorCode 		= 0
Set	@nRowCount		= 0
Set	@dtTransDate		= null
Set	@sCurrency		= null
Set	@nReceiptAmount		= null
Set 	@bIsBalanceRequired 	= 0
Set	@dtToday		= getdate()

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

-- Populating ClientNamesIncludedData dataset 

-- Check whether the name information is required
If @nErrorCode = 0
Begin
	-- Is the Receivable Items topic available?
	Set @sSQLString = "
	select @nFilterNameKey = NAMENO
	from   dbo.fn_FilterUserNames(@pnUserIdentityId, 1) 
	where  NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterNameKey	int			OUTPUT,
					  @pnNameKey		int,
					  @pnUserIdentityId	int',
					  @nFilterNameKey	= @nFilterNameKey 	OUTPUT,
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Check whether any name information is required
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @nFilterViewNameKey = NAMENO
	from   dbo.fn_FilterUserViewNames(@pnUserIdentityId) 
	where  NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterViewNameKey	int			OUTPUT,
					  @pnNameKey		int,
					  @pnUserIdentityId	int',
					  @nFilterViewNameKey	= @nFilterViewNameKey 	OUTPUT,
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Check whether the outstanding balance information is required
-- Topic security for non Access Names is not available for any financial topics
If @nErrorCode = 0
and @nFilterNameKey is not null
and (   @psResultsetsRequired = ','
    or CHARINDEX('OUTSTANDINGBALANCE,', @psResultsetsRequired) <> 0 
    or CHARINDEX('LASTRECEIPT,', @psResultsetsRequired) <> 0)
Begin
	-- Is the Receivable Items topic available?
	Set @sSQLString = "
	select @bIsBalanceRequired = IsAvailable
	from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @bIsBalanceRequired	bit			OUTPUT,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bIsBalanceRequired	= @bIsBalanceRequired	OUTPUT,
					  @dtToday		= @dtToday

End

-- Populating Name Result Set
-- For Access Names all required columns are returned
-- The following columns for non Access Names should be null: WelcomeMessage and EmailSubject.	

If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('NAME,', @psResultsetsRequired) <> 0)
Begin
	-- check if the name is CRM Only
	declare @sCRMNameTypes nvarchar(1000)
	declare @bIsCRMOnly bit

	set @sSQLString = "
		select @sCRMNameTypes = isnull(@sCRMNameTypes,'') +
			case when (@sCRMNameTypes is not null) then ',' else '' end + ''''+NAMETYPE+''''
			from NAMETYPE WHERE PICKLISTFLAGS&32=32"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sCRMNameTypes 	nvarchar(1000) output',
				  @sCRMNameTypes	= @sCRMNameTypes output

	if (@sCRMNameTypes is not null and @nErrorCode=0)
	Begin
	set @sSQLString = "	
		select @bIsCRMOnly =
			case when (
				exists(Select 1
				from NAMETYPECLASSIFICATION 
				WHERE NAMENO=@pnNameKey
				and NAMETYPE IN (" + @sCRMNameTypes + ")
				and ALLOW=1)
				  and
				not exists(Select 1
				from NAMETYPECLASSIFICATION 
				WHERE NAMENO=@pnNameKey
				and NAMETYPE NOT IN (" + @sCRMNameTypes + ")
				and ALLOW=1)
			) then 1 else 0 end"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey	int,
				  @bIsCRMOnly 	bit output',
				  @pnNameKey	= @pnNameKey,
				  @bIsCRMOnly	= @bIsCRMOnly output
	End

	If  @nErrorCode = 0
	Begin	
		Set @sSQLString = 
		"Select N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'Name',"+CHAR(10)+  
		"N.NAMECODE		as 'NameCode',"+CHAR(10) 
		If @nFilterNameKey is not null
		Begin
			Set @sSQLString = @sSQLString + 
				"N2.NAMENO		as 'OurContactKey',"+CHAR(10)+
				"dbo.fn_FormatNameUsingNameNo(N2.NAMENO, COALESCE(N2.NAMESTYLE, NN2.NAMESTYLE, 7101))"+CHAR(10)+ 	
				"			as 'OurContactName',"+CHAR(10)+
				"TBC.DESCRIPTION 	as 'OurContactRole',"+CHAR(10)
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + 
				"NULL	as 'OurContactKey',"+CHAR(10)+ 
				"NULL	as 'OurContactName',"+CHAR(10)+  
				"NULL	as 'OurContactRole',"+CHAR(10) 
		End
		Set @sSQLString = @sSQLString + 		
		"I.IMAGEID		as 'ImageKey',"
		If @nFilterNameKey is not null
			Set @sSQLString = @sSQLString + 
				dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP',@sLookupCulture,@pbCalledFromCentura)
				+" as 'WelcomeMessage',"+CHAR(10)
		Else
			Set @sSQLString = @sSQLString + " null as 'WelcomeMessage',"+CHAR(10)
		Set @sSQLString = @sSQLString + 
		"N1.NAMENO		as 'YourContactKey',"+CHAR(10)+ 
		"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101))"+CHAR(10)+ 	
		"			as 'YourContactName',"+CHAR(10)+ 
		"dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE)"+CHAR(10)+ 
		"			as 'StreetAddress',"+CHAR(10)+ 
		"dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PC.POSTALNAME, PC.POSTCODEFIRST, PC.STATEABBREVIATED, PC.POSTCODELITERAL, PC.ADDRESSSTYLE)"+CHAR(10)+ 
		"			as 'PostalAddress',"+CHAR(10)+ 
		"dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)"+CHAR(10)+ 
		"			as 'MainPhone',"+CHAR(10)+ 
		"dbo.fn_FormatTelecom(FX.TELECOMTYPE, FX.ISD, FX.AREACODE, FX.TELECOMNUMBER, FX.EXTENSION)"+CHAR(10)+ 
		"			as 'MainFax',"+CHAR(10)+ 
		"dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION)"+CHAR(10)+ 
		"			as 'MainEmail',"+CHAR(10)
		If @nFilterNameKey is not null
		Begin
			Set @sSQLString = @sSQLString + 
				"dbo.fn_FormatTelecom(M1.TELECOMTYPE, M1.ISD, M1.AREACODE, M1.TELECOMNUMBER, M1.EXTENSION) as 'EmailAddress',"+CHAR(10)+
				"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+ 
				"+ ' ' + N.NAMECODE	as 'EmailSubject',"+CHAR(10)+ 
				" 1	as 'IsAccessName',"+CHAR(10)
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + 
				" null	as 'EmailAddress',"+CHAR(10)+
				" null	as 'EmailSubject',"+CHAR(10)+
				" 0	as 'IsAccessName',"+CHAR(10)
		End
		Set @sSQLString = @sSQLString + "isnull(@bIsCRMOnly,0)	as 'IsCRMOnly',"+CHAR(10)+
		"CAST(N.NAMENO as nvarchar(11)) as 'RowKey'"+CHAR(10)+   	
    		"from NAME N"+CHAR(10)+   	
		"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
		"left join TELECOMMUNICATION M  on (M.TELECODE = N.MAINEMAIL)"+CHAR(10)+
		-- Street Address details
		-- Only show the street address when its different to the postal address
		"left join ADDRESS SA 		on (SA.ADDRESSCODE = N.STREETADDRESS"+CHAR(10)+ 
		"				and N.STREETADDRESS <> N.POSTALADDRESS)"+CHAR(10)+ 
		"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+ 
		"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+ 
		" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+ 
		-- Postal Address details 
		"left join ADDRESS PA 		on (PA.ADDRESSCODE = N.POSTALADDRESS)"+CHAR(10)+ 
		"left join COUNTRY PC		on (PC.COUNTRYCODE = PA.COUNTRYCODE)"+CHAR(10)+ 
		"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE"+CHAR(10)+ 
		" 	           	 	and PS.STATE = PA.STATE)"+CHAR(10)+ 
		-- For 'YourContactName' use Name.MainContact
		"left join NAME N1		on (N1.NAMENO  = N.MAINCONTACT)"+CHAR(10)+ 
		"left join COUNTRY NN1		on (NN1.COUNTRYCODE = N1.NATIONALITY)"+CHAR(10)+
		-- For 'OurContactName' AssociatedName.RelatedName is used where AssociatedName.Relationship
		-- = 'RES' (NamyType.Description = 'Staff Member') whith no PropertyType
		"left join ASSOCIATEDNAME ASN	on (ASN.NAMENO  = N.NAMENO"+CHAR(10)+
		"				and ASN.RELATIONSHIP = 'RES'"+CHAR(10)+
		"				and ASN.PROPERTYTYPE IS NULL)"+CHAR(10)+
		"				and   ASN.RELATEDNAME =(select min(ASN1.RELATEDNAME)"+CHAR(10)+
		"							from ASSOCIATEDNAME ASN1"+CHAR(10)+
		"							where ASN1.NAMENO=ASN.NAMENO"+CHAR(10)+
		"							and ASN1.RELATIONSHIP='RES'"+CHAR(10)+
		"							and ASN1.PROPERTYTYPE is null)"+CHAR(10)+
		"left join NAME N2 		on (N2.NAMENO = ASN.RELATEDNAME)"+CHAR(10)+
		"left join COUNTRY NN2		on (NN2.COUNTRYCODE = N2.NATIONALITY)"+CHAR(10)+
		-- 'OurContactRole' is found on the TableCodes.Description where
		-- TableCodes.TableCode = AssociatedName.JobRole of 'OurContactName'
		"left join TABLECODES TBC	on (TBC.TABLECODE = ASN.JOBROLE)"+CHAR(10)
		If @nFilterNameKey is not null
		Begin
			Set @sSQLString = @sSQLString + 
				"left join TELECOMMUNICATION M1 on (M1.TELECODE = N2.MAINEMAIL)"+CHAR(10)+
				"left join SITECONTROL SCR	on (SCR.CONTROLID = 'Welcome Message - External')"+CHAR(10)+ 
				"left join NAMETEXT NTP		on (NTP.NAMENO = N.NAMENO"+CHAR(10)+ 
				"				and SCR.COLCHARACTER = NTP.TEXTTYPE)"+CHAR(10)+ 
				dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTP',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)
		End    		
	     	Set @sSQLString = @sSQLString + 
		"left join NAMEIMAGE I		on (I.IMAGEID = "+CHAR(10)+ 
						"(select NI.IMAGEID "+CHAR(10)+ 
						"from  NAMEIMAGE NI "+CHAR(10)+ 
						"where NI.NAMENO = N.NAMENO "+CHAR(10)+ 
						" AND NI.IMAGESEQUENCE = "+CHAR(10)+ 
							"(SELECT MIN(NIM.IMAGESEQUENCE)"+CHAR(10)+  
							"from  NAMEIMAGE NIM "+CHAR(10)+ 
							"WHERE NIM.NAMENO = N.NAMENO)))"+CHAR(10)+ 
		"left join TELECOMMUNICATION PH  on (PH.TELECODE = N.MAINPHONE)"+CHAR(10)+ 
		"left join TELECOMMUNICATION FX	on (FX.TELECODE = N.FAX)"+CHAR(10)	

		If @nFilterNameKey is not null
		Begin
			Set @sSQLString = @sSQLString + "where N.NAMENO = @nFilterNameKey"
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nFilterNameKey	int,
							  @pnUserIdentityId	int,
							  @bIsCRMOnly		bit',
							  @nFilterNameKey	= @nFilterNameKey,
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @bIsCRMOnly		= @bIsCRMOnly
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + "where N.NAMENO = @nFilterViewNameKey"
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nFilterViewNameKey	int,
							  @pnUserIdentityId	int,
							  @bIsCRMOnly		bit',
							  @nFilterViewNameKey	= @nFilterViewNameKey,
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @bIsCRMOnly		= @bIsCRMOnly
		End
	End
End
	 	
-- Populating Language Result Set
-- Empty result set is returned for non Access Names

If @nErrorCode = 0
and @nFilterNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('LANGUAGE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	Select	CAST(NL.NAMENO as nvarchar(11)) + '^' + CAST(NL.SEQUENCENO as nvarchar(10)) as 'RowKey',
		N.NAMENO 	  as 'NameKey',
	       "+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PR',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyTypeDescription',
	       "+dbo.fn_SqlTranslatedColumn('VALIDACTION','ACTIONNAME',null,'AC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ActionDescription',
	       "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'LanguageDescription'
	from NAME N 
	join NAMELANGUAGE NL on (NL.NAMENO = N.NAMENO)
	left join PROPERTYTYPE PR on (PR.PROPERTYTYPE = NL.PROPERTYTYPE)	
	left join ACTIONS AC	  on (AC.ACTION = NL.ACTION)	
	left join TABLECODES TC	  on (TC.TABLECODE = NL.LANGUAGE)	
	where N.NAMENO = @nFilterNameKey
	order by 'PropertyTypeDescription' DESC, 'ActionDescription' DESC"	
 
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterNameKey	int,
					  @pnUserIdentityId	int',
					  @nFilterNameKey	= @nFilterNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId
End	
Else
If @nErrorCode = 0
and @nFilterViewNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('LANGUAGE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	Select null as 'RowKey',
	       null as 'NameKey',
	       null as 'PropertyTypeDescription',
	       null as 'ActionDescription',
	       null as 'LanguageDescription'
	where 1 = 2"	
 
	exec @nErrorCode=sp_executesql @sSQLString
End	

-- Determine the ageing periods to be used for the OutstandingBalance
-- Required for Access Names only
If @nErrorCode=0
and @bIsBalanceRequired = 1
and @nFilterNameKey is not null
and (   @psResultsetsRequired = ','
    or CHARINDEX('OUTSTANDINGBALANCE,', @psResultsetsRequired) <> 0 
    or CHARINDEX('PREPAYMENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.ac_GetAgeingBrackets
			@pdtBaseDate		= @dtBaseDate 	output, -- The date that all items to be aged must be compared to
			@pnBracket0Days		= @nAge0 	output,
			@pnBracket1Days		= @nAge1 	output,
			@pnBracket2Days		= @nAge2 	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture
End

-- Populating OutstandingBalance Result Set
-- Empty result set is returned for non Access Names

If @nErrorCode=0
and @nFilterNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('OUTSTANDINGBALANCE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	select
	CAST(O.ACCTDEBTORNO as nvarchar(11)) + '^' + CAST(O.ACCTENTITYNO as nvarchar(11)) + '^' + ISNULL(O.CURRENCY, SC.COLCHARACTER) as 'RowKey',
	O.ACCTDEBTORNO	as 'NameKey', 
	O.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	ISNULL(O.CURRENCY, SC.COLCHARACTER)
			as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0) 		    	THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2) 		    	THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket3Total',
	sum(ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE)) 
			as 'Total',
	sum(CASE WHEN(O.ITEMTYPE = 520) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END)
			as 'UnallocatedCash'
	from NAME FN 
	join OPENITEM O		on (O.ACCTDEBTORNO=FN.NAMENO
				and O.STATUS<>0
				and O.ITEMDATE<=getdate()
				and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112) )
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where FN.NAMENO = @nFilterNameKey 
	-- An empty result set is required if the user has insufficient security
	and   @bIsBalanceRequired = 1
	group by O.ACCTENTITYNO, N.NAME, O.CURRENCY, SC.COLCHARACTER,O.ACCTDEBTORNO 
	order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterNameKey	int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @bIsBalanceRequired	bit',
					  @nFilterNameKey	=@nFilterNameKey,
					  @pnUserIdentityId	=@pnUserIdentityId,
					  @nAge0         	=@nAge0,
					  @nAge1         	=@nAge1,
					  @nAge2         	=@nAge2,
					  @dtBaseDate		=@dtBaseDate,
					  @bIsBalanceRequired	=@bIsBalanceRequired
End	
Else
If @nErrorCode=0
and @nFilterViewNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('OUTSTANDINGBALANCE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	select
	null 	as 'RowKey',
	null	as 'NameKey', 
	null	as 'EntityKey',
	null	as 'EntityName',
	null	as 'CurrencyCode',
	null	as 'Bracket0Total',
	null	as 'Bracket1Total',
	null	as 'Bracket2Total',
	null	as 'Bracket3Total',
	null	as 'Total',
	null	as 'UnallocatedCash'
	where	1 = 2"

	exec @nErrorCode=sp_executesql @sSQLString
End	

-- Populating Prepayment Result Set
-- Empty result set is returned for non Access Names

If @nErrorCode=0
and @nFilterNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('PREPAYMENT,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	select
	CAST(O.ACCTDEBTORNO as nvarchar(11)) + '^' + CAST(O.ACCTENTITYNO as nvarchar(11)) + '^' + ISNULL(O.CURRENCY, SC.COLCHARACTER) as 'RowKey',
	O.ACCTDEBTORNO	as 'NameKey', 
	O.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	ISNULL(O.CURRENCY, SC.COLCHARACTER)
			as 'CurrencyCode',
	sum(ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE))*-1
			as 'AvailableBalance',
	-- Avoid 'divide by zero' by substituting 0 with 1
	convert(int,
	round(
	(sum(ISNULL(O.FOREIGNVALUE, O.LOCALVALUE) - ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE))/
	CASE WHEN sum(ISNULL(O.FOREIGNVALUE, O.LOCALVALUE))<>0 
	     THEN sum(ISNULL(O.FOREIGNVALUE, O.LOCALVALUE)) 
	     ELSE 1 
	END)*100, 0)) 	as 'UtilisedPercentage'
	from NAME FN
	-- An empty result set is required if the user does not have access to the Prepayments topic
	join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 201, default, @dtToday) TS on (TS.IsAvailable=1)
	join OPENITEM O		on (O.ACCTDEBTORNO=FN.NAMENO
				and O.STATUS in (1,2)
				and O.ITEMTYPE = 523
				and O.ITEMDATE<=getdate())
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where FN.NAMENO = @nFilterNameKey  
	group by O.ACCTENTITYNO, N.NAME, O.CURRENCY, SC.COLCHARACTER,O.ACCTDEBTORNO
	order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterNameKey	int,
					  @pnUserIdentityId	int,
					  @dtToday		datetime',
					  @nFilterNameKey	= @nFilterNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @dtToday		= @dtToday
End
Else
If @nErrorCode=0
and @nFilterViewNameKey is not null
and (   @psResultsetsRequired = ','
     or CHARINDEX('PREPAYMENT,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	select
	null	as 'RowKey',
	null	as 'NameKey', 
	null	as 'EntityKey',
	null	as 'EntityName',
	null	as 'CurrencyCode',
	null	as 'AvailableBalance',
	null 	as 'UtilisedPercentage'
	where	1 = 2"

	exec @nErrorCode=sp_executesql @sSQLString
End	


-- Populating NameVariants
If   @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('NAMEVARIANTS,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select 	CAST(NV.NAMENO as nvarchar(11)) + '^' + CAST(NV.NAMEVARIANTNO as nvarchar(11))	as RowKey,
		NV.NAMENO		as NameKey,
		NV.NAMEVARIANTNO	as NameVariantKey, 
		dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, null, null)
		 			as NameVariant,
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)
					+" as PropertyType, 
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
					+" as Reason
	from NAMEVARIANT NV  
	left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = NV.PROPERTYTYPE)
	left join TABLECODES TC		on (TC.TABLECODE = NV.VARIANTREASON)
	where NV.NAMENO = @nFilterViewNameKey
	order by NV.DISPLAYSEQUENCENO"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterViewNameKey	int',
					  @nFilterViewNameKey	= @nFilterViewNameKey
End

-- Populating Alias Result Set
If   @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('ALIAS,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.naw_ListNameAlias  
					@pnUserIdentityId 	= @pnUserIdentityId,
					@psCulture 	 	= @sLookupCulture,
					@pnNameKey 	 	= @nFilterViewNameKey,
					@pbCalledFromCentura 	= @pbCalledFromCentura
End

-- Populating Standing Instruction Result Set

If  @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('STANDINGINSTRUCTION,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode=dbo.naw_ListStandingInstructions
					@pnUserIdentityId	= @pnUserIdentityId,
					@pbIsExternalUser	= 1,
					@pnNameKey		= @nFilterViewNameKey,
					@psCulture		= @sLookupCulture,
					@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Populating OtherDetails
If   @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('NAMEOTHER,', @psResultsetsRequired) <> 0)
Begin
	-- Populating NameOther Result Set
	Set @sSQLString = 
	"Select cast(N.NAMENO as nvarchar(11)) 	as 'RowKey',"+CHAR(10)+ 
	"	N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'NN',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Nationality',"+CHAR(10)+ 
		"O.REGISTRATIONNO	as 'CompanyNo',"+CHAR(10)+ 
		dbo.fn_SqlTranslatedColumn('ORGANISATION','INCORPORATED',null,'O',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Incorporated',"+CHAR(10)+ 
		"N3.NAMENO		as 'ParentEntityKey',"+CHAR(10)+ 
		"dbo.fn_FormatNameUsingNameNo(N3.NAMENO, null)"+CHAR(10)+ 	
		"			as 'ParentEntityName'"+CHAR(10)+
     	"from NAME N"+CHAR(10)+   	
	"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left Join ORGANISATION O	on (O.NAMENO = N.NAMENO)"+CHAR(10)+   		
	"left join NAME N3		on (N3.NAMENO = O.PARENT)"+CHAR(10)
	If @nFilterNameKey is not null
	Begin
		Set @sSQLString = @sSQLString + "where N.NAMENO = @nFilterNameKey"
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nFilterNameKey	 int',
						  @nFilterNameKey	 = @nFilterNameKey
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "where N.NAMENO = @nFilterViewNameKey"
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nFilterViewNameKey	 int',
						  @nFilterViewNameKey	 = @nFilterViewNameKey
	End
End

If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('CASECOUNTS,', @psResultsetsRequired) <> 0)
Begin

	If @nErrorCode = 0
	Begin		
		If @nFilterNameKey is not null
		Begin

			Set @sSQLString = "
				select @bExcludeDeadCases = COLBOOLEAN
				from 	SITECONTROL SC 
				where 	CONTROLID ='Client Exclude Dead Case Stats'"
			
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@bExcludeDeadCases	bit			OUTPUT',
								  @bExcludeDeadCases	= @bExcludeDeadCases 	OUTPUT			
			If @nErrorCode = 0
			Begin
				Set @sSQLString =  
				"Select cast(@pnNameKey as nvarchar(11)) 	as 'RowKey',
					@pnNameKey 		as 'NameKey',
					SUM(CASE WHEN ((ST.LIVEFLAG = 1 and ST.REGISTEREDFLAG = 0) 
					        			    or ST.STATUSCODE is null) 
									    and (RS.LIVEFLAG = 1 or RS.STATUSCODE is null) THEN 1 ELSE 0 END) 
							as 'CaseCountPending',
			       	        SUM(CASE WHEN ST.LIVEFLAG = 1 and ST.REGISTEREDFLAG = 1
					      				  and (RS.LIVEFLAG = 1 or RS.STATUSCODE is null)   THEN 1 ELSE 0 END)
							as 'CaseCountRegistered',"+CHAR(10)	
				If @bExcludeDeadCases=1
					Set @sSQLString = @sSQLString + 
					"	null as 'CaseCountDead',"+CHAR(10)
				Else
					Set @sSQLString = @sSQLString + 
					"	SUM(CASE WHEN (ST.LIVEFLAG = 0 OR RS.LIVEFLAG = 0) 		   THEN 1 ELSE 0 END)
							as 'CaseCountDead',"+CHAR(10)
				Set @sSQLString = @sSQLString + "
				        COUNT(*) 	as 'CaseCountTotal'	
				from dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC
				join CASES C		on (C.CASEID=FC.CASEID)
				join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE
							and CT.ACTUALCASETYPE IS NULL)
				left join STATUS ST	on (ST.STATUSCODE = C.STATUSCODE)
				left join PROPERTY P	on (P.CASEID      = C.CASEID)
				left join STATUS RS	on (RS.STATUSCODE = P.RENEWALSTATUS)
				where   exists (select * 
				      		from CASENAME CL
			 	      		join SITECONTROL S on (S.CONTROLID = 'Client Name Types')
						-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
						-- will match on 'Z' but not on 'ZC'.
			 	      		where patindex('%'+','+CL.NAMETYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0
			 	      		and(CL.EXPIRYDATE is NULL or CL.EXPIRYDATE > getdate())
			 	      		and CL.NAMENO = @pnNameKey
				      		and CL.CASEID = C.CASEID)"
				If @bExcludeDeadCases=1
				Begin
					Set @sSQLString = @sSQLString + CHAR(10)+
					"and ISNULL(ST.LIVEFLAG,1)=1"+CHAR(10)+
					"and ISNULL(RS.LIVEFLAG,1)=1"
				End
				
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnNameKey		int,
								  @pnUserIdentityId	int',
								  @pnNameKey		= @pnNameKey,
								  @pnUserIdentityId	= @pnUserIdentityId
			End
		End
		Else
		Begin
			Set @sSQLString = 
			"Select null	as 'RowKey',"+CHAR(10)+ 
			"	null	as 'NameKey',"+CHAR(10)+ 		
			"	null	as 'CaseCountPending',"+CHAR(10)+ 
			"	null	as 'CaseCountRegistered',"+CHAR(10)+ 
			"	null	as 'CaseCountDead',"+CHAR(10)+ 
			"	null	as 'CaseCountTotal'"+CHAR(10)+ 
			"where 1=2"

			exec @nErrorCode=sp_executesql @sSQLString
		End
	End
End

-- Retrieve the Last Receipt details and store them into variables. The values stored 
-- in the variables are then used to populate the Name table 

If @nErrorCode = 0
and (   @psResultsetsRequired = ','
    or CHARINDEX('LASTRECEIPT,', @psResultsetsRequired) <> 0)
Begin
	If @bIsBalanceRequired = 1
	and @nFilterNameKey is not null
	Begin

		Set @sSQLString = "
		Select TOP 1 @dtTransDate    = DH.TRANSDATE,
			     @sCurrency      = ISNULL(DH.CURRENCY, SC.COLCHARACTER), 
			     @nReceiptAmount = ISNULL(DH.FOREIGNTRANVALUE,DH.LOCALVALUE)*-1 
		from DEBTORHISTORY DH 
		left join SITECONTROL SC on (SC.CONTROLID = 'CURRENCY') 
		where DH.ACCTDEBTORNO = @pnNameKey
		and DH.MOVEMENTCLASS = 2 
		and DH.STATUS = 1 
		and DH.TRANSTYPE = 520 
		order by DH.POSTDATE DESC, DH.TRANSDATE DESC" 
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int,
						  @dtTransDate		datetime		OUTPUT,
						  @sCurrency		nvarchar(3)		OUTPUT,
					    	  @nReceiptAmount	decimal(11,2)		OUTPUT',
						  @pnNameKey		= @pnNameKey,
						  @dtTransDate		= @dtTransDate		OUTPUT,
						  @sCurrency		= @sCurrency		OUTPUT,
		  				  @nReceiptAmount	= @nReceiptAmount 	OUTPUT	
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString = 
			"Select cast(N.NAMENO as nvarchar(11))	as 'RowKey',"+CHAR(10)+ 
			"N.NAMENO 		as 'NameKey',"+CHAR(10)+ 		
			"@sCurrency		as 'LastReceiptCurrencyCode',"+CHAR(10)+ 
			"@nReceiptAmount	as 'LastReceiptAmount',"+CHAR(10)+ 
			"@dtTransDate		as 'LastReceiptDate'"+CHAR(10)+ 
			"from NAME N"+CHAR(10)+
			"where N.NAMENO = @nFilterNameKey"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nFilterNameKey	 int,
							  @pnUserIdentityId	 int,
							  @dtTransDate		 datetime,
							  @sCurrency		 nvarchar(3),
						    	  @nReceiptAmount	 decimal(11,2)',					 
							  @nFilterNameKey	 = @nFilterNameKey,
							  @pnUserIdentityId	 = @pnUserIdentityId,
							  @dtTransDate		 = @dtTransDate,
							  @sCurrency		 = @sCurrency,
							  @nReceiptAmount	 = @nReceiptAmount
		End
	End
	Else
	Begin
		Set @sSQLString = 
			"Select null	as 'RowKey',"+CHAR(10)+ 
			"	null	as 'NameKey',"+CHAR(10)+ 		
			"	null	as 'LastReceiptCurrencyCode',"+CHAR(10)+ 
			"	null	as 'LastReceiptAmount',"+CHAR(10)+ 
			"	null	as 'LastReceiptDate'"+CHAR(10)+ 
			"where 1=2"

		exec @nErrorCode=sp_executesql @sSQLString
	End
End

Return @nErrorCode
GO

Grant execute on dbo.cwb_ListClientNameDetail to public
GO


