-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameSalesHighlights
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameSalesHighlights]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameSalesHighlights.'
	Drop procedure [dbo].[naw_ListNameSalesHighlights]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameSalesHighlights...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameSalesHighlights
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnSourceNameKey  		int		= null,
	@pnGroupKey			int		= null,
	@pbCanViewSalesHighlights	bit		= 0,
	@pbCanViewBillingHistory	bit		= 0,
	@pbCanViewReceivableItems	bit		= 0,
	@pbCanViewPayableItems		bit		= 0,
	@pbCanViewWIPItems		bit		= 0,
	@pbCalledFromCentura		bit		= 0,
	@psResultsetsRequired 		nvarchar(1000)	= null	 	-- Contains a comma separated list of topics required.  
									-- When null (the default), all topics are to be returned,
									-- e.g. 'Header,Receivable'.					
)
as
-- PROCEDURE:	naw_ListNameSalesHighlights
-- VERSION:	20
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the NameSalesHighlightsData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	--- -----------	-------	----------------------------------------------- 
-- 12 Jan 2005	TM	RFC1533	1	Procedure created
-- 11 Feb 2005	TM	RFC2309	2	For all of the balances, the stored procedure should return null if there is
--					no information, i.e. change ISNULL(SUM(ISNULL(O.LOCALVALUE,0)),0) to 
--					SUM(ISNULL(O.LOCALVALUE,0)) (RFC1533 feedback).
-- 14 Feb 2005	TM	RFC2309	3	In the WIP result set, change the column names as specified:
--					DaysWIPOutstanding -> DaysOutstanding,
--					DaysDisbursementOutstanding -> DisbursementDaysOutstanding.
-- 14 Feb 2005	TM	RFC2322	4	Suppress the Payable and WIP result sets if the correspondent topics 
--					are not available.
-- 15 May 2005	JEK	RFC2508	5	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 25 Nov 2005	LP	RFC1017	6	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 17 Jul 2006	SW	RFC3828	7	Pass getdate() to fn_Permission..
-- 25 Aug 2006	SF	RFC4214	8	Implement ResultSetRequired Parameter, Added RowKey
-- 24 Apr 2007	SW	RFC4345	9	Exlude Draft Cases from the number of live cases associated with the name.
-- 30 May 2007	SW	RFC4345	10	Define Draft Cases as ACTUALCASETYPE IS NULL
-- 11 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 14 Jun 2011	JC	100151	12	Improve performance by removing fn_GetTopicSecurity: authorisation is now given by the caller
-- 11 Apr 2013	DV	13270	13	Increase the length of nvarchar to 11 when casting or declaring integer
-- 25 Jun 2013	AT	13589	14	Fix error when no periods defined.
-- 05 Jul 2013	vql	13629	15	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	16	Adjust formatted names logic (DR-15543).
-- 25 Oct 2016	MF	69655	17	The billing YTD should exclude bills that have been reversed. Draft bills were already excluded because
--					they don't have a Post Date, but I have explicitly excluded them as well.
-- 15 Jun 2018  MS      72099   18      Show receivable balance details even if all bills are cleared
-- 14 Nov 2018  AV  75198/DR-45358	19   Date conversion errors when creating cases and opening names in Chinese DB
-- 06 Aug 2019  AK	DR-34873 20 logic changed to calculate Days outstanding


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sSQLString 				nvarchar(4000)

Declare @bIsStaff				bit
Declare @nUsedAsFlag				smallint
Declare @nNameKey				int	
Declare @sName					nvarchar(254)
Declare @nGroupKey				smallint
Declare @sGroup					nvarchar(50)
Declare @sLocalCurrencyCode			nvarchar(3)
Declare @nLocalDecimalPlaces			tinyint
Declare @nLiveCases				int
Declare @sWorkAnalysisDateRangeYTD		nvarchar(100)
Declare @nReceivableAverageValue		decimal(11,2)
Declare @nBilledYTDTotal			decimal(11,2) 
Declare @nBillingYtd				decimal(11,2)
Declare @nPayableTotal				decimal(11,2)
Declare @nDisbursementsOverAYearDebtorOnlyWIP	decimal(11,2)
Declare @nDisbursementsOverAYearCaseWIP		decimal(11,2)
Declare @nBalanceDebtorOnlyWIP			decimal(11,2)
Declare @nDisbursementsBalanceDebtorOnlyWIP 	decimal(11,2)
Declare @nBalanceForCaseWIP			decimal(11,2)
Declare @nDisbursementsBalanceForCaseWIP	decimal(11,2)

Declare @nBalanceDebtorOnlyWIPOsDays decimal(15,2)
Declare @nBalanceForCaseWIPOsDays	decimal(15,2)
Declare @nTotalBalanceWIP decimal(15,2)
Declare @nDisbursementsBalanceDebtorOnlyWIPOsDays	decimal(15,2)
Declare @nDisbursementsBalanceForCaseWIPOsDays decimal(15,2)
Declare @nTotalDisbursementsBalanceWIP decimal(15,2)
Declare @nReceivableOsDays decimal(15,2)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode 				= 0
Set @bIsStaff					= 0

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode = 0
and @pnSourceNameKey is not null
Begin	
	Set @sSQLString = "
	Select  @nUsedAsFlag 	= N.USEDASFLAG,
		@bIsStaff	= CASE WHEN N.USEDASFLAG&2 = 2 THEN 1 ELSE 0 END
	from NAME N		
	where N.NAMENO = @pnSourceNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nUsedAsFlag		smallint		OUTPUT,
					  @bIsStaff		bit			OUTPUT,
					  @pnSourceNameKey	int',			 
					  @nUsedAsFlag		= @nUsedAsFlag		OUTPUT,
					  @bIsStaff		= @bIsStaff		OUTPUT,
					  @pnSourceNameKey	= @pnSourceNameKey
End

-- If the @pnSourceNameKey was supplied, determine the appropriate name to report on 
-- and extract the required data to populate the Header result set:
If @nErrorCode = 0
and (@bIsStaff = 0 and @pbCanViewSalesHighlights = 1)
and @pnSourceNameKey is not null
Begin	
	-- If the name is an organisation (i.e. if UsedAsFlag&1<>1 and UsedAsFlag<>2), 
	-- the @pnSourceNameKey identifies the name directly.
	Set @nNameKey = CASE 	WHEN (@nUsedAsFlag&1<>1 and @nUsedAsFlag<>2)
				THEN  @pnSourceNameKey
				ELSE  NULL
			END

	-- If the name is an individual with an employing organisation, that organisation becomes 
	-- the name to be reported. If there is no employing organisation, check whether 
	-- the @pnSourceNameKey acts as an Instructor. If so, the @pnSourceNameKey identifies 
	-- the name directly.  
	If  @nNameKey is null
	and @nUsedAsFlag&1=1
	Begin
		-- Extract an appropriate NameKey to report on:
		Set @sSQLString = "
		Select @nNameKey	= ISNULL(ORG.NAMENO, CN.NAMENO)		
	     	from NAME N 	
		-- Organisation for the employed by relationship on AssociatedName.
		left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO
						and EMP.RELATIONSHIP = 'EMP') 
		left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)			 
		left join CASENAME CN		on (CN.NAMENO = N.NAMENO 
						and CN.NAMETYPE = 'I'
						and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		where N.NAMENO = @pnSourceNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameKey		int			OUTPUT,
						  @pnSourceNameKey	int',
						  @nNameKey		= @nNameKey		OUTPUT,
						  @pnSourceNameKey	= @pnSourceNameKey		
	End

	-- Extract the name, group and local currency information 
	-- into the local variables to be used in the Header result set.
	If  @nErrorCode = 0
	and @nNameKey is not null
	Begin
		Set @sSQLString = "
		Select @sName		= dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
		       @nGroupKey	= N.FAMILYNO,
		       @sGroup		= "+dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'F',@sLookupCulture,@pbCalledFromCentura)+"
	     	from NAME N 	
		left join NAMEFAMILY F		on (F.FAMILYNO = N.FAMILYNO)
		where N.NAMENO = @nNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sName		nvarchar(254)		OUTPUT,
						  @nGroupKey		smallint		OUTPUT,
						  @sGroup		nvarchar(50)		OUTPUT,
						  @nNameKey		int',
						  @sName		= @sName		OUTPUT,
						  @nGroupKey		= @nGroupKey		OUTPUT,
						  @sGroup		= @sGroup		OUTPUT,
						  @nNameKey		= @nNameKey			
	End
End
Else
-- If the @pnGroupKey is provided, the GroupKey is placed in NameOrGroupKey.
If @nErrorCode = 0
and (@bIsStaff = 0 and @pbCanViewSalesHighlights = 1)
and @pnGroupKey is not null
Begin	
	-- Extract Group information
	Set @sSQLString = "
	Select @nGroupKey	= @pnGroupKey,
	       @sGroup		= "+dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'F',@sLookupCulture,@pbCalledFromCentura)+"
     	from NAMEFAMILY F	
	where F.FAMILYNO = @pnGroupKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sGroup		nvarchar(50)	OUTPUT,
					  @nGroupKey		smallint	OUTPUT,
					  @pnGroupKey		smallint',
					  @sGroup		= @sGroup	OUTPUT,
					  @nGroupKey		= @nGroupKey	OUTPUT,
					  @pnGroupKey		= @pnGroupKey		
End

-- Return empty result sets if:
-- 1) the name is a staff member;
-- 2) apropriate name to report on was not found;
-- 3) the user does not have access to the Sales Highlights topic.
If  @nErrorCode = 0 
and (@bIsStaff = 1 or @pbCanViewSalesHighlights = 0)
or (@nNameKey is null
and @pnGroupKey is null)
Begin
	If (@psResultsetsRequired = ','
     	or CHARINDEX('HEADER,', @psResultsetsRequired) <> 0)
	Begin
		-- Header result set
		Select  null	as 'RowKey',
			null	as 'NameOrGroupKey',    
			null 	as 'Name',
			null	as 'NameKey',
			null	as 'Group',
			null	as 'GroupKey',		
			null	as 'LocalCurrencyCode'		
		where 1=2
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('CASECOUNT,', @psResultsetsRequired) <> 0)
	Begin
		-- CaseCount result set
		Select  null	as 'RowKey',
			null	as 'NameOrGroupKey',  
			null	as 'PropertyTypeKey',
			null	as 'PropertyType',
			null	as 'LiveCount',
			null	as 'LivePercent'
		where 1=2
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('BILLING,', @psResultsetsRequired) <> 0)
	Begin
		-- Billing result set
		Select  null	as 'RowKey',
			null	as 'NameOrGroupKey',
			null	as 'BillingYtd',
			null	as 'BillingPercent'
		where 1=2
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('RECEIVABLE,', @psResultsetsRequired) <> 0)
	Begin
		-- Receivable result set
		Select  null	as 'RowKey',
			null 	as 'NameOrGroupKey',
			null	as 'ReceivableBalance',
			null   	as 'DaysOutstanding',
			null	as 'DaysBeyondTerms'	
		where 1=2
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('PAYABLE,', @psResultsetsRequired) <> 0)
	Begin
		-- Payable rsult set
		Select  null	as 'RowKey',
			null	as 'NameOrGroupKey',
			null	as 'PayableBalance'
		where 1=2
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('WIP,', @psResultsetsRequired) <> 0)
	Begin
		-- WIP result set
		Select  null	as 'RowKey',
			null	as 'NameOrGroupKey',
			null	as 'WipBalance',
			null	as 'DaysOutstanding',
			null	as 'DisbursementDaysOutstanding'	
		where 1=2
	End
End
Else 
-- Populate the NameSalesHighlightsData dataset
If @nErrorCode = 0
Begin
	-- Header result set
	If (@psResultsetsRequired = ','
     	or CHARINDEX('HEADER,', @psResultsetsRequired) <> 0)
	Begin
		Select  cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11))
					as 'RowKey', 
			ISNULL(@nNameKey,@nGroupKey) 	
					as 'NameOrGroupKey',   
			@sName 		as 'Name',
			@nNameKey	as 'NameKey',
			@sGroup		as 'Group',
			@nGroupKey	as 'GroupKey',		
			@sLocalCurrencyCode 	as 'LocalCurrencyCode',
			@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
		where   @nNameKey is not null
		or	@nGroupKey is not null
		
		-- Find out total number of life cases for the Name/Group:
		Set @sSQLString = "
		Select @nLiveCases = COUNT(*)
		from CASES C
		join CASETYPE CT		on (CT.CASETYPE = C.CASETYPE
						and CT.ACTUALCASETYPE IS NULL)
		left join STATUS ST		on (ST.STATUSCODE = C.STATUSCODE)
		left join PROPERTY P		on (P.CASEID      = C.CASEID)
		left join STATUS RS		on (RS.STATUSCODE = P.RENEWALSTATUS)
		where  (ST.LIVEFLAG=1 or ST.STATUSCODE is null)
		and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)
		and   exists (	Select 1
				from CASENAME CN"+char(10)+
			        CASE 	WHEN @nNameKey is not null
					THEN "where CN.NAMENO = @nNameKey"+char(10)+				    
					     "and   CN.NAMETYPE = 'I'"+char(10)+
					     "and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
					     "and   CN.CASEID = C.CASEID)"
					WHEN @pnGroupKey is not null
					THEN "join NAME N 	on (N.FAMILYNO = @nGroupKey)"+char(10)+
					     "where CN.NAMENO = N.NAMENO"+char(10)+
					     "and   CN.NAMETYPE = 'I'"+char(10)+
					     "and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
					     "and   CN.CASEID = C.CASEID)"
				END
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nLiveCases	int		OUTPUT,
						  @nNameKey	int,					
						  @nGroupKey	smallint',
						  @nLiveCases	= @nLiveCases	OUTPUT,
						  @nNameKey	= @nNameKey,
						  @nGroupKey	= @nGroupKey	
	End

	If (@psResultsetsRequired = ','
     	or CHARINDEX('CASECOUNT,', @psResultsetsRequired) <> 0)
	Begin
		-- CaseCount Result set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select  cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11)) + '^' + C.PROPERTYTYPE
							as 'RowKey', 	
				ISNULL(@nNameKey,@nGroupKey) 	
							as 'NameOrGroupKey',  				
				C.PROPERTYTYPE		as 'PropertyTypeKey',
				"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)+"	
							as 'PropertyType',
				COUNT(*)		as 'LiveCount',
				CASE 	WHEN @nLiveCases = 0
					-- Avoid 'divide by 0' exeption
					THEN NULL
					ELSE convert(int,round((COUNT(*)*100)/@nLiveCases,0))
				END			as 'LivePercent'
			from CASES C
			join CASETYPE CT		on (CT.CASETYPE = C.CASETYPE
							and CT.ACTUALCASETYPE IS NULL)
			left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = C.PROPERTYTYPE)
			left join STATUS ST		on (ST.STATUSCODE = C.STATUSCODE)
			left join PROPERTY P		on (P.CASEID      = C.CASEID)
			left join STATUS RS		on (RS.STATUSCODE = P.RENEWALSTATUS)
			where  (ST.LIVEFLAG=1 or ST.STATUSCODE is null)
			and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)
			and   exists (	Select 1
					from CASENAME CN"+char(10)+
				        CASE 	WHEN @nNameKey is not null
						THEN "where CN.NAMENO = @nNameKey"+char(10)+
						     "and   CN.NAMETYPE = 'I'"+char(10)+
						     "and   CN.CASEID = C.CASEID)"
						WHEN @pnGroupKey is not null
						THEN "join NAME N 	on (N.FAMILYNO = @nGroupKey)"+char(10)+
						     "where CN.NAMENO = N.NAMENO"+char(10)+
						     "and   CN.NAMETYPE = 'I'"+char(10)+
						     "and   CN.CASEID = C.CASEID)"
					END+char(10)+
			"group by C.PROPERTYTYPE, "+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
			"order by 'PropertyType', 'PropertyTypeKey'"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nNameKey	int,					
							  @nGroupKey	smallint,
							  @nLiveCases	int',
							  @nNameKey	= @nNameKey,
							  @nGroupKey	= @nGroupKey,
							  @nLiveCases	= @nLiveCases	
		End	
	End
	

	If @nErrorCode = 0
	and (@psResultsetsRequired = ','
     	or CHARINDEX('BILLING,', @psResultsetsRequired) <> 0)
	Begin					 
		-- Find the Year to dateperiod of the financial year
		Set @sSQLString = 
		"Select @sWorkAnalysisDateRangeYTD  	= '   O.POSTPERIOD between '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '01'''+" +
									"'   and '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '99'''" + char(10)+ 
		"from PERIOD P" + char(10)+ 
		"where P.PERIODID =(	select (P1.PERIODID/100)*100+01" + char(10)+
					"from PERIOD P1"+char(10)+
					"where P1.STARTDATE=(	select max(STARTDATE)" + char(10)+ 
								"from PERIOD where STARTDATE<getdate()))"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sWorkAnalysisDateRangeYTD		nvarchar(100)			OUTPUT',					 
						  @sWorkAnalysisDateRangeYTD		= @sWorkAnalysisDateRangeYTD	OUTPUT
						  
		if (@sWorkAnalysisDateRangeYTD is not null)
		Begin
		-- Calculate the BilledYTDTotal
		If @nErrorCode = 0
		and @pbCanViewBillingHistory = 1
		Begin	
			Set @sSQLString = "
			Select @nBilledYTDTotal = SUM(ISNULL(O.LOCALVALUE,0))
			from OPENITEM O
			join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)
			where DIT.USEDBYBILLING = 1
			and O.STATUS not in (0,9)		-- exclude Reversed and Draft bills
			and "+@sWorkAnalysisDateRangeYTD
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBilledYTDTotal	decimal(11,2)		OUTPUT',					 
							  @nBilledYTDTotal	= @nBilledYTDTotal	OUTPUT
		End
	
		-- Calculate the BilledYtd
		If @nErrorCode = 0
		and @pbCanViewBillingHistory = 1
		Begin	
			Set @sSQLString = "
			Select  @nBillingYtd = SUM(ISNULL(O.LOCALVALUE,0))
			from OPENITEM O
			join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)"+char(10)+
			CASE 	WHEN @pnGroupKey is not null
				THEN "join NAME N	on (N.NAMENO = O.ACCTDEBTORNO"+char(10)+
				     "			and N.FAMILYNO = @nGroupKey)"
			END+char(10)+
			"where DIT.USEDBYBILLING = 1
			and O.STATUS not in (0,9)		-- exclude Reversed and Draft bills
			and "+@sWorkAnalysisDateRangeYTD+char(10)+
		        CASE	WHEN @nNameKey is not null
				THEN "and O.ACCTDEBTORNO = @nNameKey" 
			END

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBillingYtd	decimal(11,2)	OUTPUT,
							  @nNameKey	int,
							  @nGroupKey	smallint',					 
							  @nBillingYtd	= @nBillingYtd	OUTPUT,
							  @nNameKey	= @nNameKey,
						    	  @nGroupKey	= @nGroupKey		
		End
		End
		

		-- Billing result set	
		If  @nErrorCode = 0
		Begin	
			Select 	cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11))
						as 'RowKey',
				ISNULL(@nNameKey,@nGroupKey)
						as 'NameOrGroupKey',
				@nBillingYtd	as 'BillingYtd',
				CASE 	WHEN @nBilledYTDTotal = 0
					-- Avoide 'divide by 0' exception
					THEN NULL
					ELSE convert(int,round((@nBillingYtd*100)/@nBilledYTDTotal,0))
				END		as 'BillingPercent'
			where @pbCanViewBillingHistory = 1				
			and (@nBillingYtd is not null
			or   (@nBilledYTDTotal is not null
			and   @nBillingYtd is not null))		
		End	
	End
			
	If @nErrorCode = 0
	and (@psResultsetsRequired = ','
     	or CHARINDEX('RECEIVABLE,', @psResultsetsRequired) <> 0)
	Begin 
		-- Calculate the Average value added to receivables per day. This average is to be calculated 
		-- across DEBTORHISTORYs for the name/group and  posted in the past year as 
		-- sum(LOCALVALUE)/days in last year.
	
		If  @nErrorCode=0
		Begin 
			If @pbCanViewReceivableItems = 1
			Begin
				Set @sSQLString = "
				Select @nReceivableAverageValue = sum(isnull(DH.LOCALVALUE,0)),
				@nReceivableOsDays = SUM(ISNULL(DH.LOCALBALANCE,0)*(DATEDIFF(DAY, DH.TRANSDATE, getdate())))
				from DEBTORHISTORY DH"+char(10)+
				CASE	WHEN @pnGroupKey is not null
					THEN "join NAME N	on (N.NAMENO = DH.ACCTDEBTORNO"+char(10)+
					     "			and N.FAMILYNO = @nGroupKey)"
				END+char(10)+
				"where DH.MOVEMENTCLASS = 1
				and    DH.POSTDATE between  dateadd(yy,-1,getdate()) and getdate()"+char(10)+
				CASE	WHEN @nNameKey is not null
					THEN "and DH.ACCTDEBTORNO = @nNameKey"
				END
			
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@nReceivableAverageValue	decimal(11,2)	 		OUTPUT,
								  @nReceivableOsDays	decimal(15,2)	 		OUTPUT,
								  @nNameKey			int,
								  @nGroupKey			smallint',
								  @nReceivableAverageValue	= @nReceivableAverageValue 	OUTPUT,
								  @nReceivableOsDays	=	@nReceivableOsDays OUTPUT,
								  @nNameKey			= @nNameKey,
								  @nGroupKey			= @nGroupKey
			End
	
			-- Populating ReceivableTotal Result Set 
			If @nErrorCode=0
			Begin
				Set @sSQLString = "
				-- DaysOutstanding - calculated as the current outstanding balance (sum(LOCALBALANCE)) divided by the average value 
			 	-- added to receivables per day. 
				Select 	cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11))
						as 'RowKey',
					ISNULL(@nNameKey, @nGroupKey) 	
							as 'NameOrGroupKey',  
				SUM(ISNULL(O.LOCALBALANCE,0))
							as 'ReceivableBalance',
				convert(decimal(11,2),	       
				CASE WHEN @nReceivableAverageValue = 0 
				     -- Avoid 'divide by zero' exception and set DaysOutstanding to null.
				     THEN null
				     ELSE cast(@nReceivableOsDays as decimal)/@nReceivableAverageValue
				END)			as 'DaysOutstanding',
				-- DaysBeyondTerms is calculated as sum(ReceivableBalance x Days OverDue)/Total Receivable Balance. 
				-- It should return null if the Trading Terms site control is set to null.
				CASE WHEN SC.COLINTEGER is null
				     THEN null
				     ELSE convert(int,			  
					  CASE WHEN sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) = 0
					       -- Avoid 'divide by zero' exception and set DaysBeyondTerms to null.
					       THEN null 
				     	       ELSE sum(CASE WHEN O.LOCALBALANCE > 0 
							     THEN (O.LOCALBALANCE* CASE WHEN (datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())) < 0 
							 				THEN 0
							 				ELSE isnull((datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())),0)
						    				   END)
							     ELSE 0
				    	      		END)/sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) 	
					  END) 			  	
				END			as 'DaysBeyondTerms'		
				from OPENITEM O"+char(10)+
				CASE	WHEN @pnGroupKey is not null
					THEN "join NAME N	on (N.NAMENO = O.ACCTDEBTORNO"+char(10)+
					     "			and N.FAMILYNO = @nGroupKey)"
				END+char(10)+
				"left join SITECONTROL SC	on (SC.CONTROLID = 'Trading Terms')
				where O.STATUS<>0
				and O.ITEMDATE<=getdate()
				and @pbCanViewReceivableItems = 1"+char(10)+
				CASE	WHEN @nNameKey is not null
					THEN "and O.ACCTDEBTORNO = @nNameKey"
				END+char(10)+
				"group by SC.COLINTEGER"	
		
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@nNameKey			int,	
								  @nGroupKey			smallint,
								  @pbCanViewReceivableItems	bit,
								  @nReceivableOsDays decimal(15,2),
								  @nReceivableAverageValue	decimal(11,2)',
								  @nNameKey			= @nNameKey,
								  @nGroupKey			= @nGroupKey,
								  @pbCanViewReceivableItems	= @pbCanViewReceivableItems,
								  @nReceivableOsDays	=	@nReceivableOsDays,
								  @nReceivableAverageValue	= @nReceivableAverageValue
			End
		End	
	End
	
	If @nErrorCode = 0
	and (@psResultsetsRequired = ','
     	or CHARINDEX('PAYABLE,', @psResultsetsRequired) <> 0)
	Begin 				
		-- Extract the PayableBalance for the Payable result set
		If  @nErrorCode = 0
		and @pbCanViewPayableItems = 1
		Begin
			Set @sSQLString = "
			Select @nPayableTotal = SUM(ISNULL(C.LOCALBALANCE,0))	
			from CREDITORITEM C"+char(10)+
			CASE	WHEN @pnGroupKey is not null
				THEN "join NAME N 	on (N.NAMENO = C.ACCTCREDITORNO"+char(10)+
				     "			and N.FAMILYNO = @nGroupKey)"
			END+char(10)+
			"where C.STATUS <> 0
			and C.ITEMDATE <= getdate()
			and C.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day, 1, getdate()),112)"+char(10)+
			CASE	WHEN @nNameKey is not null
				THEN "and C.ACCTCREDITORNO = @nNameKey "
			END
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nPayableTotal	decimal(11,2)		OUTPUT,
							  @nNameKey		int,
							  @nGroupKey		smallint',	
							  @nPayableTotal	= @nPayableTotal 	OUTPUT,
							  @nNameKey		= @nNameKey,
							  @nGroupKey		= @nGroupKey
		End
		
		-- Populating the Payable result set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select  cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11))
						as 'RowKey',
				ISNULL(@nNameKey,@nGroupKey)
						as 'NameOrGroupKey',
				@nPayableTotal	as 'PayableBalance'
			where   @nPayableTotal is not null
			and 	@pbCanViewPayableItems = 1"	
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nGroupKey		smallint,
							  @nNameKey		int,
							  @nPayableTotal	decimal(11,2),
							  @pbCanViewPayableItems bit',
							  @nGroupKey		= @nGroupKey,
							  @nNameKey		= @nNameKey,
							  @nPayableTotal	= @nPayableTotal,
							  @pbCanViewPayableItems = @pbCanViewPayableItems
		End
	End
	   

	-- Populate the WIP result set
	If @nErrorCode = 0
	and (@psResultsetsRequired = ','
     	or CHARINDEX('WIP,', @psResultsetsRequired) <> 0)
	Begin 		
		If  @nErrorCode= 0 
		Begin
			If @pbCanViewWIPItems = 1
			Begin
				
				If @nErrorCode = 0
				Begin 
					-- Calculate any debtor only WIP recorded directly against the name:
					Set @sSQLString = "
					Select  @nBalanceDebtorOnlyWIP = 	SUM(ISNULL(W.BALANCE,0)),
						@nBalanceDebtorOnlyWIPOsDays = SUM(ISNULL(W.BALANCE,0)*(DATEDIFF(DAY, W.TRANSDATE, getdate()))),
						@nDisbursementsBalanceDebtorOnlyWIP	=	
										SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
										         THEN ISNULL(W.BALANCE,0) 	 
										    END),
						@nDisbursementsBalanceDebtorOnlyWIPOsDays = SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
										         THEN ISNULL(W.BALANCE,0)*(DATEDIFF(DAY, W.TRANSDATE, getdate())) 	 
										    END)
								
					from WORKINPROGRESS W
					join WIPTEMPLATE WIP	on (WIP.WIPCODE = W.WIPCODE)
					join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)"+char(10)+
					CASE	WHEN @pnGroupKey is not null
						THEN "join NAME N		on (N.NAMENO = W.ACCTCLIENTNO"+char(10)+
						     "				and N.FAMILYNO = @nGroupKey)"
					END+char(10)+
					"where W.STATUS <> 0
					and   W.TRANSDATE <= getdate()
					and   W.CASEID is null"+char(10)+
					CASE	WHEN @nNameKey is not null
						THEN "and   W.ACCTCLIENTNO = @nNameKey"
					END
	
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nBalanceDebtorOnlyWIP					decimal(11,2)			OUTPUT,
								  @nBalanceDebtorOnlyWIPOsDays				decimal(15,2)			OUTPUT,
								  @nDisbursementsBalanceDebtorOnlyWIP		decimal(15,2)			OUTPUT,
								  @nDisbursementsBalanceDebtorOnlyWIPOsDays	decimal(15,2)			OUTPUT,
								  @nNameKey				int,
								  @nGroupKey				smallint',
								  @nBalanceDebtorOnlyWIP					= @nBalanceDebtorOnlyWIP	OUTPUT,
								  @nBalanceDebtorOnlyWIPOsDays = @nBalanceDebtorOnlyWIPOsDays OUTPUT,
								  @nDisbursementsBalanceDebtorOnlyWIP 		= @nDisbursementsBalanceDebtorOnlyWIP OUTPUT,
								  @nDisbursementsBalanceDebtorOnlyWIPOsDays	= @nDisbursementsBalanceDebtorOnlyWIPOsDays OUTPUT,
								  @nNameKey									= @nNameKey,
								  @nGroupKey								= @nGroupKey	
	

					If @nErrorCode = 0
					Begin 
						-- Calculate WIP for Cases for which this name is the debtor:
						Set @sSQLString = "
						Select  @nBalanceForCaseWIP = 	SUM(ISNULL(W.BALANCE,0)*CN.BILLPERCENTAGE/100),
						@nBalanceForCaseWIPOsDays = SUM((ISNULL(W.BALANCE,0)*CN.BILLPERCENTAGE/100)*(DATEDIFF(DAY, W.TRANSDATE, getdate()))),
							@nDisbursementsBalanceForCaseWIP = 	
											       SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
											         	THEN ISNULL(W.BALANCE,0)*CN.BILLPERCENTAGE/100 	 
											    	   END),
						@nDisbursementsBalanceForCaseWIPOsDays = 
											       SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
											         	THEN (ISNULL(W.BALANCE,0)*CN.BILLPERCENTAGE/100)*(DATEDIFF(DAY, W.TRANSDATE, getdate())) 
											    	   END)
						from WORKINPROGRESS W
						join CASENAME CN	on (CN.CASEID = W.CASEID
									and CN.NAMETYPE = 'D' 
									and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
						join WIPTEMPLATE WIP	on (WIP.WIPCODE = W.WIPCODE)
						join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)"+char(10)+
						CASE	WHEN @pnGroupKey is not null
							THEN "join NAME N		on (N.NAMENO = CN.NAMENO"+char(10)+
							     "				and N.FAMILYNO = @nGroupKey)"
						END+char(10)+
						"where W.STATUS <> 0
						and W.TRANSDATE <= getdate()
						and W.CASEID is not null"+char(10)+
						CASE	WHEN @nNameKey is not null
							THEN "and CN.NAMENO = @nNameKey"
						END
		
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nBalanceForCaseWIP					 decimal(11,2)			OUTPUT,
									  @nBalanceForCaseWIPOsDays				decimal(15,2)			OUTPUT,
									  @nDisbursementsBalanceForCaseWIP		 decimal(11,2)			OUTPUT,
									  @nDisbursementsBalanceForCaseWIPOsDays	 decimal(15,2)		OUTPUT,
									  @nNameKey				int,
									  @nGroupKey			smallint',
									  @nBalanceForCaseWIP					 = @nBalanceForCaseWIP						OUTPUT,
									  @nBalanceForCaseWIPOsDays = @nBalanceForCaseWIPOsDays   OUTPUT,
									  @nDisbursementsBalanceForCaseWIP		 = @nDisbursementsBalanceForCaseWIP			OUTPUT,
									  @nDisbursementsBalanceForCaseWIPOsDays	 = @nDisbursementsBalanceForCaseWIPOsDays    OUTPUT,
									  @nNameKey				= @nNameKey,
									  @nGroupKey				= @nGroupKey	
					End
				End
			End

			If @nErrorCode = 0
			Begin 
				Set @nTotalBalanceWIP = ISNULL(@nBalanceDebtorOnlyWIP,0)+ISNULL(@nBalanceForCaseWIP,0)	
				Set @nTotalDisbursementsBalanceWIP = ISNULL(@nDisbursementsBalanceDebtorOnlyWIP,0)+ISNULL(@nDisbursementsBalanceForCaseWIP,0)
			End
					
		     
			-- Populate the WIP result set:
	
			If @nErrorCode=0
			Begin 
				Select
				cast(ISNULL(@nNameKey,@nGroupKey) as nvarchar(11))
						as 'RowKey',
				ISNULL(@nNameKey, @nGroupKey)
						as 'NameOrGroupKey',
				@nTotalBalanceWIP
						as 'WipBalance',
				CASE WHEN @nTotalBalanceWIP = 0 
				     -- Avoid 'divide by zero' exception and set DaysWIPOutstanding
				     -- to null.
				     THEN null 
				     ELSE CASE WHEN @nBalanceForCaseWIPOsDays is null
								and @nBalanceDebtorOnlyWIPOsDays is null
							   -- Return 'null' instead of '0' if both Debtor and Case
							   -- balances are null.
							   THEN null
						           ELSE dbo.fn_RoundLocalCurrency(cast((ISNULL(@nBalanceDebtorOnlyWIPOsDays,0)+ISNULL(@nBalanceForCaseWIPOsDays,0)) as decimal)
							        /@nTotalBalanceWIP)
						      	END
				
				END		as 'DaysOutstanding',
				CASE WHEN @nTotalDisbursementsBalanceWIP = 0 
				     	          -- Avoid 'divide by zero' exception and set @nTotalDisbursementsBalanceWIP to null.
				     		  THEN null
				     		  ELSE CASE WHEN @nDisbursementsBalanceDebtorOnlyWIPOsDays is null
								 and @nDisbursementsBalanceForCaseWIPOsDays is null
							    -- Return 'null' instead of '0' if both Debtor and Case
							    -- balances are null.
							    THEN null
							    ELSE dbo.fn_RoundLocalCurrency(cast((ISNULL(@nDisbursementsBalanceDebtorOnlyWIPOsDays,0)+ISNULL(@nDisbursementsBalanceForCaseWIPOsDays,0)) as decimal)
								 /@nTotalDisbursementsBalanceWIP)
						       END		
					     END
						as 'DisbursementDaysOutstanding'				
				where  @pbCanViewWIPItems = 1
				and   (@nBalanceDebtorOnlyWIP is not null or @nBalanceForCaseWIP is not null)
				or   ((@nTotalBalanceWIP <> 0 and (@nBalanceDebtorOnlyWIP is not null or @nBalanceForCaseWIP is not null))
				 or   (@nTotalDisbursementsBalanceWIP <> 0 and (@nBalanceDebtorOnlyWIP is not null or @nBalanceForCaseWIP is not null)))			
			End
		End	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameSalesHighlights to public
GO
