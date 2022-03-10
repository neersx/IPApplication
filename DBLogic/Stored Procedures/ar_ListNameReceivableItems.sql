-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ar_ListNameReceivableItems 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ar_ListNameReceivableItems ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ar_ListNameReceivableItems.'
	Drop procedure [dbo].[ar_ListNameReceivableItems ]
End
Print '**** Creating Stored Procedure dbo.ar_ListNameReceivableItems ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ar_ListNameReceivableItems 
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEntityKey 		int		= null,		
	@pnNameKey		int		= null,
	@pnGroupKey		smallint	= null,
	@psCurrencyCode		nvarchar(3)	= null,
	@pnAgeingBracketNo 	tinyint 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ar_ListNameReceivableItems 
-- VERSION:	30
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates NameReceivableItemsData dataset. Returns a list of the outstanding 
--		receivable items for a particular client name/group, entity and currency.  
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited-- MODIFICTIONS :
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11-Sep-2003  TM		1	Procedure created
-- 01-Oct-2003	TM		2	RFC402 Outstanding Items web part. Default @psCurrencyCode
--					to null to make it optional. Return a count of the rows in 
--					the ReceivableItem result set (@pnRowCountItems).
-- 09-Oct-2003	MF	RFC519	3	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 13-Oct-2003	TM	RFC402	4	Outstanding Items web part. Make the row count the 
--					first parameter and name it @pnRowCount.
-- 13-Oct-2003	MF	RFC533	6	If the user is not on USERIDENTITY table then treat as if External User
-- 19-Nov-2003	TM	RFC402	7	Change ISNULL(O.CURRENCY, SC.COLCHARACTER) as 'LocalCurrencyCode' to
--					SC.COLCHARACTER as 'LocalCurrencyCode'
-- 21-Nov-2003	TM	RFC402	8	Remove O.CURRENCY from the "Group by"
-- 06-Dec-2003	JEK	RFC406	9	Implement topic level security.
-- 18-Feb-2004	TM	RFC976	10	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 10-Mar-2004	TM	RFC987	11	Sort Outstanding Items/Receivable Items by Date then by OpenItemNo.
-- 27-May-2004	TM	RFC912	12	Add new optional @pnAgeingBracketNo tinyint parameter. This is the number 
--					of an ageing bracket (i.e. 0-3). When provided, only items that appear in 
--					that ageing bracket will be reported. 
-- 13-Sep-2004	TM	RFC886	13	Implement Translation.
-- 19-Jan-2005	TM	RFC1533	14	Make the existing @pnEntityKey and @pnNameKey parameters optional.  
--					Add a new @pnGroupKey int parameter which is also optional.
-- 20-Jan-2005	TM	RFC1533	15	Improve comments.  Format the entity name and debtor name in the items result 
--					set for reporting.
-- 11-Feb-2005	TM	RFC2314	16	Suppress the 'Name...' columns if the @pnNameKey was not supplied.
-- 15 May 2005	JEK	RFC2508	17	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Nov 2005	LP	RFC1017	18	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 01-Dec-2005	LP	RFC3297	19	Fix the "GROUP BY" clause for the Header result set
--					ensuring commas are correctly added
-- 13 Jul 2006	SW	RFC3828	20	Pass getdate() to fn_Permission..
-- 14 Sep 2006	AU	RFC4267	21	Return RowKey column for Header and ReceivableItem tables.
-- 09 Nov 2006	AU	RFC4656	22	Fixed the following error - RowKey is null when @pnNameKey is null.
-- 28 Mar 2007	SF	RFC5244	23	Fixed first result set was ordered by a non-existent column and caused an error in SQL2005
-- 20 Oct 2011	ASH	R11441	24	Order By clause contains non-existent columns EntityName and EntityKey when @pnEntityKey is null.
-- 01 Dec 2011	ASH	R11576	25	Convert TRANSNO column to navarchar(11) data type
-- 15 Apr 2013	DV	R13270	26	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	27	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	28	Adjust formatted names logic (DR-15543).
-- 20 Apr 2016	LP	R60715	29	Fix GROUP BY issue.
-- 14 Nov 2018  AV  75198/DR-45358	30   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)

Declare @bIsExternalUser	bit

Declare @nErrorCode		int

Declare	@nAge0			smallint
Declare	@nAge1			smallint
Declare	@nAge2			smallint
Declare @dtBaseDate 		datetime -- the end date of the current period

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

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

-- We need to determine if the user is external

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId

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
		THEN "O.ACCTDEBTORNO		as 'NameKey',"+char(10)+
		     "dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+char(10)+
		     "				as 'Name',"
	END+char(10)+
	-- Entity columns are populated in the Header result set only if the EntityKey was supplied:
	CASE	WHEN @pnEntityKey is not null
		THEN "O.ACCTENTITYNO		as 'EntityKey',"+char(10)+
		     "dbo.fn_FormatNameUsingNameNo(EN.NAMENO, COALESCE(EN.NAMESTYLE, NN1.NAMESTYLE, 7101))"+char(10)+ 
	 	     "				as 'EntityName',"
	END+char(10)+
	"sum(ISNULL(O.LOCALBALANCE, 0))	
				as 'LocalTotal',
	-- The 'ForeignTotal' should only be calculated if the @psCurrencyCode parameter
	-- is not null 
	CASE WHEN @psCurrencyCode IS NOT NULL 
	     THEN sum(ISNULL(O.FOREIGNBALANCE, 0))	
	     ELSE NULL 
	END			as 'ForeignTotal',
	@psCurrencyCode		as 'RequestedCurrencyCode',
	@sLocalCurrencyCode	as 'LocalCurrencyCode',
	@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
	from NAME N
	join OPENITEM O 	on (O.ACCTDEBTORNO = N.NAMENO				
				and O.STATUS in (1,2)
				and O.ITEMDATE<=getdate())"+
	CASE 	WHEN @pnNameKey is not null
		THEN "left join COUNTRY NN	on (NN.COUNTRYCODE = N.NATIONALITY)"
	END+char(10)+
	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE 	WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END
	-- Return an empty result set if the user does not have access to the Receivable Items topic
	+"join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday) TS
					on (TS.IsAvailable=1)"+char(10)+				
	CASE	WHEN @pnEntityKey is not null
		THEN "join NAME EN 	 		on (EN.NAMENO = O.ACCTENTITYNO)"+char(10)+
		     "left join COUNTRY NN1		on (NN1.COUNTRYCODE = EN.NATIONALITY)"
	END+char(10)+
	"where (ISNULL(O.CURRENCY, @sLocalCurrencyCode) = @psCurrencyCode 
	   or @psCurrencyCode is null)"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "and  N.NAMENO = @pnNameKey"
	END+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "and  N.FAMILYNO = @pnGroupKey" 
	END+char(10)+
	CASE 	WHEN @pnEntityKey IS NOT NULL	
		THEN "and O.ACCTENTITYNO = @pnEntityKey"
	END
	

	-- Allow drilling down on each aging bracket
	Set @sSQLString = @sSQLString + CHAR(10)+
			  CASE WHEN @pnAgeingBracketNo = 0 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0"
			       WHEN @pnAgeingBracketNo = 1 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1"
			       WHEN @pnAgeingBracketNo = 2 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1"	
			       WHEN @pnAgeingBracketNo = 3 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2"	
			  END		

	Set @sSQLString = @sSQLString + CHAR(10)+
	CASE	WHEN @pnNameKey is not null OR @pnEntityKey is not null
		THEN "group by" 

	END + char(10) +
	CASE	WHEN @pnNameKey is not null
		THEN " O.ACCTDEBTORNO, N.NAMENO, N.FIRSTNAME,"+char(10)+
		     "N.TITLE, N.NAMESTYLE, NN.NAMESTYLE"
	END+char(10)+
	-- If the EntityKey is not supplied, entity columns are not
	-- populated in the Headre result set.
	CASE	WHEN @pnEntityKey is not null
		THEN CASE WHEN @pnNameKey is not null THEN "," END+
		     " O.ACCTENTITYNO, EN.NAMENO, EN.FIRSTNAME,"+char(10)+
	             "EN.TITLE, EN.NAMESTYLE, NN1.NAMESTYLE"
	END
	Set @sSQLString = @sSQLString + CHAR(10)+
	"order by  'LocalCurrencyCode'"
	Set @sSQLString = @sSQLString + CHAR(10)+
	 CASE WHEN @pnEntityKey is not null THEN ",'EntityName', 'EntityKey'" 
	END

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
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @dtToday		datetime',	
					  @pnNameKey		= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnEntityKey		= @pnEntityKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psCurrencyCode	= @psCurrencyCode,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
					  @sLocalCurrencyCode 	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces,
					  @dtToday		= @dtToday	
End


-- Populating ReceivableItem Result Set
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select  CAST(O.ITEMENTITYNO as nvarchar(11))+'^'+
		CAST(O.ITEMTRANSNO as nvarchar(11))+'^'+
		CAST(O.ACCTENTITYNO as nvarchar(11))+'^'+
		CAST(O.ACCTDEBTORNO as nvarchar(11))	as 'RowKey',
		O.ITEMENTITYNO				as 'ItemEntityNo',
	        O.ITEMTRANSNO				as 'ItemTransNo',
		O.ACCTENTITYNO				as 'AcctEntityNo',
		O.ACCTDEBTORNO				as 'AcctDebtorNo',
		O.OPENITEMNO				as 'OpenItemNo',
		O.ITEMDATE				as 'ItemDate',
		"+dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,'DIT',@sLookupCulture,@pbCalledFromCentura)
						    + " as 'ItemTypeDescription',
		datediff(dd,O.ITEMDATE,getdate()) 	as 'Age',
		ISNULL(O.STATEMENTREF,O.REFERENCETEXT)	as 'Description',
		-- Avoid 'divide by zero' by substituting 0 with 1. 'PaidPercentage' should be 
		-- round to integer and it should be null for negative items
		CASE WHEN O.LOCALVALUE < 0 THEN NULL
		     ELSE convert(int,
			  round(
			  ((ISNULL(O.LOCALVALUE, O.FOREIGNVALUE) - ISNULL(O.LOCALBALANCE, O.FOREIGNBALANCE))/
			   CASE WHEN ISNULL(O.FOREIGNVALUE, O.LOCALVALUE)<>0 
	     	     	        THEN ISNULL(O.LOCALVALUE, O.FOREIGNVALUE) 
	     	     	        ELSE 1 
			   END)*100, 0)) 	
		END					as 'PaidPercentage',
		ISNULL(O.CURRENCY, @sLocalCurrencyCode)	as 'ItemCurrencyCode',
		O.LOCALBALANCE 				as 'LocalBalance',
		O.FOREIGNBALANCE			as 'ForeignBalance'"+
		-- Entity and Debtor columns are populated in the Items result set only if the EntityKey was not supplied:
		CASE	WHEN @pnEntityKey is null
			THEN ","+char(10)+
			     "O.ACCTDEBTORNO		as 'NameKey',"+char(10)+
			     "dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)"+char(10)+ 
			     "				as 'Name',"+char(10)+
			     "N.NAMECODE		as 'NameCode',"+char(10)+
			     "O.ACCTENTITYNO		as 'EntityKey',"+CHAR(10)+
			     "dbo.fn_FormatNameUsingNameNo(EN.NAMENO, NULL)"+char(10)+ 
		 	     "				as 'EntityName',"+char(10)+
			     "EN.NAMECODE 		as 'EntityCode'"
		END+char(10)+		
	"From NAME N"+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END
	
	-- Return an empty result set if the user does not have access to the Receivable Items topic
	+"
	join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday) TS
					on (TS.IsAvailable=1)
	join OPENITEM O			on (O.ACCTDEBTORNO=N.NAMENO
					and O.STATUS<>0
					and O.ITEMDATE<=getdate()
					and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112) )
	join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)"+char(10)+
	CASE	WHEN @pnEntityKey is null
		THEN "join NAME EN 	 		on (EN.NAMENO = O.ACCTENTITYNO)"		   
	END+char(10)+
	"left join NAME EMP 		on (EMP.NAMENO = O.EMPLOYEENO)   
	where (ISNULL(O.CURRENCY, @sLocalCurrencyCode) = @psCurrencyCode 
	   or @psCurrencyCode is null)"+char(10)+ 
	CASE	WHEN @pnNameKey is not null
		THEN "and  N.NAMENO = @pnNameKey"
	END+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "and  N.FAMILYNO = @pnGroupKey" 
	END+char(10)+
	CASE 	WHEN @pnEntityKey IS NOT NULL	
		THEN "and O.ACCTENTITYNO = @pnEntityKey"
	END

	-- Allow drilling down on each aging bracket
	Set @sSQLString = @sSQLString + CHAR(10)+
			  CASE WHEN @pnAgeingBracketNo = 0 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0"
			       WHEN @pnAgeingBracketNo = 1 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1"
			       WHEN @pnAgeingBracketNo = 2 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1"	
			       WHEN @pnAgeingBracketNo = 3 THEN "and datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2"	
			  END		
	
	Set @sSQLString = @sSQLString + CHAR(10)+
	"order by  'ItemDate', 'OpenItemNo'"

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
					  @sLocalCurrencyCode	nvarchar(3),
					  @dtToday		datetime',	
					  @pnNameKey		= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnEntityKey         	= @pnEntityKey,
					  @psCurrencyCode       = @psCurrencyCode,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @dtToday		= @dtToday	

	Set @pnRowCount = @@Rowcount
End	


Return @nErrorCode
GO

Grant execute on dbo.ar_ListNameReceivableItems  to public
GO
