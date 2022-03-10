-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.apw_ListNamePayableItems 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[apw_ListNamePayableItems ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.apw_ListNamePayableItems.'
	Drop procedure [dbo].[apw_ListNamePayableItems ]
End
Print '**** Creating Stored Procedure dbo.apw_ListNamePayableItems ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.apw_ListNamePayableItems 
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEntityKey 		int		= null,
	@pnNameKey		int 		= null, 
	@pnGroupKey		smallint	= null,
	@psCurrencyCode		nvarchar(3)	= null,
	@pnAgeingBracketNo 	tinyint 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	apw_ListNamePayableItems 
-- VERSION:	17
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates NamePayableItems dataset. Returns a list of the outstanding 
--		payable items for a particular supplier name/group, entity and currency.  
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Jan 2005  TM		1	Procedure created
-- 17 Jan 2005	TM	RFC2141	2	Subject security for the items should use Payable Items (300).
--					Restriction and Reason are supposed to default to the Creditor 
--					if they are not found on CreditorItem.
-- 19 Jan 2005	TM	RFC1533	3	Make the existing @pnEntityKey and @pnNameKey parameters optional.  
--					Add a new @pnGroupKey int parameter which is also optional.
-- 20-Jan-2005	TM	RFC1533	4	Improve comments.  Format the entity name and debtor name in the items result 
--					set for reporting.
-- 02 Feb 2005	TM	RFC1533	5	Change the column name EntityCode to EntityNameCode.
-- 14 Feb 2005	TM	RFC2314	6	Suppress the 'Name...' columns if the @pnNameKey was not supplied.
-- 15 May 2005	JEK	RFC2508	7	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 20 May 2005	TM	RFC2594	8	Only perform one lookup of the PayableItems subject.
-- 24 Nov 2005	LP	RFC1017	9	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 13 Jul 2006	SW	RFC3828	10	Pass getdate() to fn_Permission..
-- 28 Sep 2006	AU	RFC4330	11	Return RowKey columns in Header and PayableItem tables.
-- 07 Feb 2011  LP	R10205	12	Use brackets in Order By statement for column literals.
--					Also corrected RequestedCurrencyCode and EntityNameCode column names.
-- 15 Apr 2013	DV	R13270	13	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	14	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).
-- 20 Apr 2016	LP	R60715	16	Fix GROUP BY issue.
-- 14 Nov 2018  AV  75198/DR-45358	17   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 			nvarchar(4000)
Declare @bIsExternalUser		bit
Declare @bIsPayableItemsRequired	bit


Declare @nErrorCode			int

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @sLookupCulture			nvarchar(10)
Declare @dtToday			datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

Set 	@nErrorCode 		= 0
Set	@pnRowCount		= 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- We need to determine if the user is external and 
-- check whether the Payable Items information is required

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=UI.ISEXTERNALUSER,
		@bIsPayableItemsRequired=CASE WHEN TS.IsAvailable = 1 THEN 1 ELSE 0 END
	from USERIDENTITY UI
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 300, default, @dtToday) TS
					on (TS.IsAvailable=1)
	where UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit			OUTPUT,
				  @bIsPayableItemsRequired	bit			OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @bIsExternalUser		=@bIsExternalUser	OUTPUT,
				  @bIsPayableItemsRequired	=@bIsPayableItemsRequired OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId,
				  @dtToday			=@dtToday

	If @bIsExternalUser is null
		Set @bIsExternalUser=1
End

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End

-- Populating Header Result Set

If @nErrorCode=0
Begin
	Set @sSQLString="
	select"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "CAST(@pnNameKey as nvarchar(11))"
		ELSE "CAST(@pnGroupKey as nvarchar(10))"
	END+char(10)+
	CASE	WHEN @pnEntityKey is not null
		THEN "+'^'+CAST(@pnEntityKey as nvarchar(11))"
	END+char(10)+
	CASE	WHEN @psCurrencyCode is not null
		THEN "+'^'+@psCurrencyCode"
	END+char(10)+
		" as 'RowKey',"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "C.ACCTCREDITORNO	as 'NameKey',"+char(10)+
		     "dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+char(10)+
		     "			as 'Name',"+char(10)+
		     "N.NAMECODE	as 'NameCode',"
	END+char(10)+
	-- Entity columns are populated in the Header result set only if the EntityKey was supplied:
	CASE	WHEN @pnEntityKey is not null
		THEN "C.ACCTENTITYNO		as 'EntityKey',"+CHAR(10)+
		     "dbo.fn_FormatNameUsingNameNo(EN.NAMENO, COALESCE(EN.NAMESTYLE, NN1.NAMESTYLE, 7101))"+char(10)+ 
	 	     "				as 'EntityName',"+CHAR(10)+
		     "EN.NAMECODE		as 'EntityNameCode',"
	END+char(10)+
	"sum(ISNULL(C.LOCALBALANCE, 0))	
				as 'LocalTotal',
	-- The 'ForeignTotal' should only be calculated if the @psCurrencyCode parameter
	-- is not null 
	CASE WHEN @psCurrencyCode IS NOT NULL 
	     THEN sum(ISNULL(C.FOREIGNBALANCE, 0))	
	     ELSE NULL 
	END			as 'ForeignTotal',
	@psCurrencyCode		as 'RequestedCurrencyCode',
	@sLocalCurrencyCode	as 'LocalCurrencyCode',
	@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
	from NAME N "+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END
	+"
	join CREDITORITEM C		on (C.ACCTCREDITORNO=N.NAMENO
					and C.STATUS in (1,2)
					and C.ITEMDATE<=getdate())"+char(10)+
	CASE	WHEN @pnEntityKey is not null
		THEN "join NAME EN 	 		on (EN.NAMENO = C.ACCTENTITYNO)"+char(10)+
		     "left join COUNTRY NN1		on (NN1.COUNTRYCODE = EN.NATIONALITY)"
	END+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"	 
	END+char(10)+
	-- Return an empty result set if the user does not have access to the Payable Items topic
	"where @bIsPayableItemsRequired = 1 
	 and (ISNULL(C.CURRENCY, @sLocalCurrencyCode) = @psCurrencyCode 
	   or @psCurrencyCode is null)"+char(10)+ 
	CASE	WHEN @pnNameKey is not null
		THEN "and  N.NAMENO = @pnNameKey"
	END+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "and  N.FAMILYNO = @pnGroupKey" 
	END+char(10)+
	CASE 	WHEN @pnEntityKey is not null	
		THEN "and C.ACCTENTITYNO = @pnEntityKey"
	END

	-- Allow drilling down on each aging bracket
	Set @sSQLString = @sSQLString + CHAR(10)+
			  CASE WHEN @pnAgeingBracketNo = 0 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) <  @nAge0"
			       WHEN @pnAgeingBracketNo = 1 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1"
			       WHEN @pnAgeingBracketNo = 2 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1"	
			       WHEN @pnAgeingBracketNo = 3 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) >= @nAge2"	
			  END		

	Set @sSQLString = @sSQLString + CHAR(10)+
	
	CASE	WHEN @pnNameKey is not null OR @pnEntityKey is not null
		THEN "group by" 

	END + char(10) +
	CASE	WHEN @pnNameKey is not null
		THEN "  C.ACCTCREDITORNO, N.NAMENO, N.FIRSTNAME,"+char(10)+
		     "  N.TITLE, N.NAMESTYLE, NN.NAMESTYLE, N.NAMECODE"
	END+char(10)+
	-- If the EntityKey is not supplied, entity columns are not
	-- populated in the Header result set.
	CASE	WHEN @pnEntityKey is not null
		THEN  CASE WHEN @pnNameKey is not null THEN "," END+
		     " C.ACCTENTITYNO, EN.NAMENO, EN.NAMECODE, EN.FIRSTNAME,"+char(10)+
	             "EN.TITLE, EN.NAMESTYLE, NN1.NAMESTYLE"
	END+char(10)+
	"order by " + 
	CASE WHEN @pnEntityKey is not null THEN "[EntityName], [EntityKey], " END 
	+ " [RequestedCurrencyCode]"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnGroupKey		smallint,
					  @pnUserIdentityId	int,
					  @psCurrencyCode	nvarchar(3),
					  @pnEntityKey		int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @bIsPayableItemsRequired bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',	
					  @pnNameKey		= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnEntityKey		= @pnEntityKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psCurrencyCode	= @psCurrencyCode,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
					  @bIsPayableItemsRequired = @bIsPayableItemsRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces	
End


-- Populating PayableItem Result Set
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select  CAST(C.ITEMENTITYNO as nvarchar(11))+'^'+
		CAST(C.ITEMTRANSNO as nvarchar(11))+'^'+
		CAST(C.ACCTENTITYNO as nvarchar(11))+'^'+
		CAST(C.ACCTCREDITORNO as nvarchar(11))	as 'RowKey',
		C.ITEMENTITYNO				as 'ItemEntityNo',
	        C.ITEMTRANSNO				as 'ItemTransNo',
		C.ACCTENTITYNO				as 'AcctEntityNo',
		C.ACCTCREDITORNO			as 'AcctCreditorNo',
		C.DOCUMENTREF				as 'DocumentRef',
		C.ITEMDATE				as 'ItemDate',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
						    + " as 'ItemTypeDescription',
		ISNULL(C.LONGDESCRIPTION,C.DESCRIPTION)	as 'Description',
		-- Avoid 'divide by zero' by substituting 0 with 1. 'PaidPercentage' should be 
		-- round to integer and it should be null for negative items
		CASE WHEN C.LOCALVALUE < 0 THEN NULL
		     ELSE convert(int,
			  round(
			  ((ISNULL(C.LOCALVALUE, C.FOREIGNVALUE) - ISNULL(C.LOCALBALANCE, C.FOREIGNBALANCE))/
			   CASE WHEN ISNULL(C.FOREIGNVALUE, C.LOCALVALUE)<>0 
	     	     	        THEN ISNULL(C.LOCALVALUE, C.FOREIGNVALUE) 
	     	     	        ELSE 1 
			   END)*100, 0)) 	
		END					as 'PaidPercentage',
		ISNULL(C.CURRENCY, @sLocalCurrencyCode)	as 'ItemCurrencyCode',
		C.LOCALBALANCE 				as 'LocalBalance',
		C.FOREIGNBALANCE			as 'ForeignBalance',
		"+dbo.fn_SqlTranslatedColumn('CRRESTRICTION','CRRESTRICTIONDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
						    + " as 'Restriction',
		CR.ACTIONFLAG				as 'RestrictionActionKey',
		"+dbo.fn_SqlTranslatedColumn('REASON','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)
						    + " as 'RestrictionReason'"+
		-- Entity and Creditor columns are populated in the Items result set only if the EntityKey was not supplied:
		CASE	WHEN @pnEntityKey is null
			THEN ","+char(10)+
			     "C.ACCTCREDITORNO		as 'NameKey',"+char(10)+
			     "dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)"+char(10)+ 
			     "				as 'Name',"+char(10)+
			     "N.NAMECODE		as 'NameCode',"+char(10)+
			     "C.ACCTENTITYNO		as 'EntityKey',"+CHAR(10)+
			     "dbo.fn_FormatNameUsingNameNo(EN.NAMENO, NULL)"+char(10)+ 
		 	     "				as 'EntityName',"+char(10)+
			     "EN.NAMECODE 		as 'EntityNameCode'"
		END+char(10)+		
	"From NAME N"+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END
	+"
	join CREDITOR CRT		on (CRT.NAMENO = N.NAMENO)
	join CREDITORITEM C		on (C.ACCTCREDITORNO=N.NAMENO
					and C.STATUS<>0
					and C.ITEMDATE<=getdate()
					and C.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112) )
	join TABLECODES TC 		on (TC.TABLECODE = C.ITEMTYPE)"+char(10)+
	CASE	WHEN @pnEntityKey is null
		THEN "join NAME EN 	 		on (EN.NAMENO = C.ACCTENTITYNO)"
	END+char(10)+
	"left join CRRESTRICTION CR	on (CR.CRRESTRICTIONID = ISNULL(C.RESTRICTIONID, CRT.RESTRICTIONID))
	left join REASON R		on (R.REASONCODE = ISNULL(C.RESTNREASONCODE, CRT.RESTNREASONCODE))
	-- Return an empty result set if the user does not have access to the Payable Items topic
	where @bIsPayableItemsRequired = 1 
	 and (ISNULL(C.CURRENCY, @sLocalCurrencyCode) = @psCurrencyCode 
	   or @psCurrencyCode is null)"+char(10)+ 
	CASE	WHEN @pnNameKey is not null
		THEN "and  N.NAMENO = @pnNameKey"
	END+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "and  N.FAMILYNO = @pnGroupKey" 
	END+char(10)+
	CASE 	WHEN @pnEntityKey IS NOT NULL	
		THEN "and C.ACCTENTITYNO = @pnEntityKey"
	END

	-- Allow drilling down on each aging bracket
	Set @sSQLString = @sSQLString + CHAR(10)+
			  CASE WHEN @pnAgeingBracketNo = 0 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) <  @nAge0"
			       WHEN @pnAgeingBracketNo = 1 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1"
			       WHEN @pnAgeingBracketNo = 2 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1"	
			       WHEN @pnAgeingBracketNo = 3 THEN "and datediff(day,C.ITEMDATE,@dtBaseDate) >= @nAge2"	
			  END		
	
	Set @sSQLString = @sSQLString + CHAR(10)+
	"order by  [ItemDate], [DocumentRef]"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnGroupKey		smallint,
					  @pnUserIdentityId	int,
					  @pnEntityKey		int,
					  @psCurrencyCode	nvarchar(3),
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @bIsPayableItemsRequired bit,
					  @sLocalCurrencyCode	nvarchar(3)',	
					  @pnNameKey		= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnEntityKey         	= @pnEntityKey,
					  @psCurrencyCode       = @psCurrencyCode,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
				   	  @bIsPayableItemsRequired = @bIsPayableItemsRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode
	Set @pnRowCount = @@Rowcount
End	


Return @nErrorCode
GO

Grant execute on dbo.apw_ListNamePayableItems  to public
GO
