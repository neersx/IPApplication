-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ConstructWipWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wp_ConstructWipWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.wp_ConstructWipWhere.'
	drop procedure dbo.wp_ConstructWipWhere
End
print '**** Creating procedure dbo.wp_ConstructWipWhere...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.wp_ConstructWipWhere
(
	@psWIPWhere			nvarchar(max)	= null	OUTPUT,
	@psCurrentCaseTable 		nvarchar(60)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLFilterCriteria		nvarchar(max)	= null,	-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)	
AS
-- PROCEDURE :	wp_ConstructWipWhere
-- VERSION :	36
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Work In Progress 
--		and constructs a Where clause.  
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21 Mar 2005  TM	RFC1896	1	Skeleton implementation.
-- 12 Apr 2005	TM	RFC1896	2	Implement more filter criteria and @psCurrentCaseTable as an output parameter.
-- 22 Apr 2005	TM	RFC1896	3	Implement Julie's feedback.
-- 22 Apr 2005	TM	RFC1896	4	Always use 'and XW.TRANSDATE <= getdate()' filtering if the AgedBalance filter 
--					criteria supplied.
-- 26 Apr 2005	TM	RFC1896	5	Cater for case/name only filtering. Move the EntityKey filter criteria in the 
--					general (not name/case specific) 'where' clause.
-- 29 Apr 2005	TM	RFC2554	6	Correct the DateRange filter criteria logic.
-- 02 May 2005	TM	RFC2554	7	If the CaseKey/WipNameKey are present in the WIP Overview filter criteria then
--					return only Case/Name related WIP.
-- 15 May 2005	JEK	RFC2508	8	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 18 May 2005	TM	RFC2582	9	Correct the 'Anyone in my group who performed the work' and 'Name-related WIP 
--					and Responsible Name' filtering logic. Correct the 'If' calling the csw_FilterCases. 
-- 20 Oct 2005	TM	RFC3024	10	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL (remove special logic 
--					from the BillingFrequency filter criteria).
-- 14 Dec 2005	TM	RFC2483	11	Add renewal/non-renewal WIP filter criteria.
-- 29 Mar 2007	SW	RFC4671	12	Additional filters required for WIP Overview Screen.
-- 15 Dec 2008	MF	17136	13	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Apr 2009	AT	RFC7440	14	Added support for WorkHistory searching for wpw_ListWorkHistory.
-- 18 May 2009	AT	RFC7440	15	Fixed support for WIP Balance filtering for WorkHistory report.
-- 25 May 2009	AT	RFC7440	16	Fixed support for debtor only WIP.
-- 03 Jun 2009	AT	RFC7440 17	Fixed Post date filtering.
-- 24 Mar 2011  KR	RFC7956 18	Made ResponsibleNameKey a nvarchar(1000) (instead of int) to allow for multi select name pick list
-- 24 Jan 2013  AK	RFC13000 19	Removed XW.TRANSDATE <= getdate() check to include wip item with future date
-- 15 Apr 2013	DV	R13270	20	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	21	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 21 Jul 2013	vql	DR-138	22	Filtering on transaction type added.
-- 18 Sep 2013  MS      DR-143  23      Handle split wip debtor items
-- 19 Sep 2013  MS      DR-1006 24      Fix the checks for Billing worksheet 
-- 22 Oct 2013	vql	R26273	25	Filter by allocated debtor
-- 04 Dec 2014	KR	R13821	26	Fix the WIP Overview search to use Multi Debtor Site control when Bill Frequency is used.
-- 11 Dec 2014	KR	R13821	27	Fixed the existing issue with the bill frequency filter where it was depending on the first debtor for unallocated wip
-- 16 Apr 2014	MF	R33427	28	Increase variables from nvarchar(4000) to nvarchar(max) to avoid truncation
--					of dynamic SQL.
-- 06 May 2014	vql	R29462	29	Fix the WIP Overview search to use Multi Debtor Site control when Debtor is used.
-- 08 Jul 2014	MF	R121522	30	When Name is specified in filter but Acting As has not been indicated then default to "EMP" to return
--					cases where the name is acting as the Staff member.
-- 30 May 2017	MF	R71553	31	Ethical Walls rules applied for logged on user.
-- 20 Jun 2017  DV	RFC70910 32	In WIP Overview Search, Responsible Name is not returning staff name
-- 05 Jul 2018	MF	74444	33	Revisit of RFC70910. When filtering of Case information was included the restriction by Responsible Name was ignoring the
--					filtering by Staff Responsible of Case WIP.
-- 31 Oct 2018	DL	DR-45102	34	Replace control character (word hyphen) with normal sql editor hyphen

-- 14 Nov 2018  AV  75198/DR-45358	35   Date conversion errors when creating cases and opening names in Chinese DB
-- 21 Jun 2019  MS      DR-48411 36     Added AnyNameType filter

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sAlertXML	 		nvarchar(400)

Declare @sSQLString			nvarchar(max)

Declare @sFrom				nvarchar(max)
Declare @sAcctClientNoWhere		nvarchar(max)	-- The part of the 'Where' clause used for the WIP recorded against the Name.
Declare @sCaseWhere			nvarchar(max)	-- The part of the 'Where' clause used for the WIP recorded against the Case.
Declare @sOfficeWhere			nvarchar(max)	-- The part of the 'Where' clause used for the WIP recorded against the Office.
Declare @sWhere				nvarchar(max)	-- General filter criteria.

Declare @sWhereFilter			nvarchar(max)	-- Used to hold filter criteria produced by the csw_FilterCases.

-- Filter Criteria

Declare @sStoredProcedure		nvarchar(30)

Declare @nEntityKey 			int		-- The entity the WIP was recorded against.
Declare @nEntityKeyOperator		tinyint		
Declare @sTransactionTypeKeys		nvarchar(254)	-- The type of transaction for this WIP record
Declare @nTransactionTypeKeysOperator	tinyint		
Declare @nDateRangeOperator		tinyint
Declare @dtDateRangeFrom		datetime	-- Return WIP with item dates between these dates. From and/or To value must be provided.
Declare @dtDateRangeTo			datetime
Declare @nPeriodRangeOperator		tinyint		-- A period range is converted to a date range by subtracting the from/to period from the current date. Returns the WIP with dates in the past over the resulting date range.
Declare @sPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @nPeriodRangeFrom		smallint	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @nPeriodRangeTo			smallint
Declare @bStaffKeyIsCurrentUser		bit		-- Indicates that the NameKey of the current user should be used as the StaffKey value.
Declare @nStaffKey			int		-- The key of the staff member that the WIP belongs to.
Declare @nStaffKeyOperator		tinyint		
Declare @nOriginalStaffKeyOperator	tinyint
Declare @nMemberOfGroupKey		smallint	-- The key of a name group (family). WIP belonging to any of the names that are members of the group are returned.
Declare @nMemberOfGroupKeyOperator	tinyint
Declare @nOriginalMemberOfGroupKeyOperator tinyint
Declare @bMemberOfGroupKeyIsCurrentUser bit		-- Indicates that the Name.FamilyNo of the current user should be used as the MemberOfGroupKey value.
Declare @bIsWIPStaff			bit		-- Indicates that WIP where the staff member(s) identified above are recorded on the WIP as the staff member should be returned.
Declare @bIsResponsibleFor		bit		-- Returns name-related WIP where the staff member(s) identified above are responsible for the Name the WIP was recorded against (AcctClientNo). 
Declare @nNullGroupNameKey		int		-- If the user does not belong to a group and 'MemberOfGroupKey for a current user' is selected use @nNullGroupNameKey to join to the Name table. 
Declare @sNameTypeKeys			nvarchar(4000)	-- The string that contains a list of passed Name Type Keys separated by a comma.
Declare @sList				nvarchar(4000)	-- Variable to prepare a comma separated list of values.
Declare @nRegionKey			int		-- The key of the region that the office belongs to.
Declare @nRegionKeyOperator		tinyint
Declare @bIsRenewalDebtor		bit		-- If true, the renewal debtor (NameTypeKey = 'Z' is used.  Otherwise the main Debtor (NameTypeKey='D') is used.
Declare @nBillFrequencyKey		int
Declare	@nBillFrequencyKeyOperator	tinyint
Declare @sCountryKey			nvarchar(3)
Declare @nCountryKeyOperator		tinyint
Declare @nOriginalBillFrequencyKeyOperator tinyint
Declare @nResponsibleNameKey		nvarchar(1000)		-- The (client) name that the WIP belongs to.
Declare @bIsInstructor			bit		-- Returns case-related WIP where the NameKey is the instructor for the case.
Declare @bIsDebtor			bit		-- Returns case-related WIP where the NameKey is the debtor for the case.
Declare @sResponsibleNameTypes 		nvarchar(100)	
Declare @bIsActiveWIPStatus		bit		-- Returns WIP that has a status of Active (1); i.e. neither draft nor locked on a draft bill.
Declare @bIsLockedWIPStatus		bit		-- Returns WIP that has a status of Locked (2).
Declare @bIsBilledWIPStatus		bit		-- Returns WorkHistory that is posted on an open item.
Declare @sWIPStatus			nvarchar(10)
Declare @nCaseKey			int		-- The case the WIP was recorded against.
Declare @nCaseKeyOperator		tinyint
Declare @nWipNameKey			int		-- The name the WIP was recorded against.
Declare @nWipNameKeyOperator		tinyint
Declare @sCurrencyCode			nvarchar(3)	-- The currency the WIP was recorded against.  This may be either the local currency, or a foreign currency.
Declare @nCurrencyCodeOperator		tinyint		
Declare @bIsTotalAgedBalance		bit		-- Indicates that only WIP items that fall within an aged balance calculation should be returned; i.e. no future WIP is shown.
Declare @nAgedBalanceBracketNumber	tinyint		-- The bracket number (0=current, 1, 2 etc.) that the WIP items must fall within.
Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime 	-- the end date of the current period
Declare @bIsRenewalWIP			bit		-- Returns WIP where the WIPTemplate has RenewalFlag =1.
Declare @bIsNonRenewalWIP		bit		-- Returns WIP where the WIPTemplate has RenewalFlag =0.
Declare @nAllocatedDebtorKey		nvarchar(100)	-- The namekey for the wip item allocated to this debtor.

-- Work History search related filters
Declare @bIsWIPSearch			bit
Declare @dtPostDateFrom			datetime
Declare @dtPostDateTo			datetime
Declare @dtPostDateOperator		tinyint
Declare @nAssociateKey			int
Declare @nAssociateOperator		tinyint
Declare @sSupplierInvoiceNo		nvarchar(20)
Declare @nSupplierInvoiceNoOperator	tinyint

Declare @nSumLocalBalanceFrom		decimal(11,2)
Declare @nSumLocalBalanceTo		decimal(11,2)
Declare @nSumLocalBalanceOperator	tinyint

Declare @bIsInternalWIP			bit

Declare @bIsClassWIP			bit
Declare @bIsClassBilling		bit
Declare @bIsClassWIPVariation		bit
Declare @bIsClassAdjustments		bit
Declare @bIsServiceFees			bit
Declare @bIsPaidDisbursements		bit
Declare @bIsRecoverables		bit
Declare @bIsSplitMultiDebtor		bit
Declare @bShowAllocatedDebtorWIP        bit
Declare @bIsStaffMemeberWithoutActingAs	bit -- RFC70910
Declare @bIsAnyNameType                 bit

-- Flags that indicate that the operators have been reset:
Declare @bIsResetStaffKeyOperator	bit
Declare @bIsReserMemberOfGroupKeyOperator bit

Declare @sMovementClassList nvarchar(20)
Declare @sWIPCategoriesList nvarchar(10)

Declare	@bExternalUser			bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr				nvarchar(10)

Declare @sComma				nvarchar(1)

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0
					
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @bIsSplitMultiDebtor = COLBOOLEAN
	from SITECONTROL 	
	where CONTROLID = 'WIP Split Multi Debtor'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsSplitMultiDebtor	bit	OUTPUT',
				  @bIsSplitMultiDebtor	= @bIsSplitMultiDebtor	OUTPUT
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML
	
	
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

if exists(Select 1 from OPENXML (@idoc, '//wp_ListWorkInProgress', 2))
Begin
	Set @sStoredProcedure = 'wp_ListWorkInProgress'
End
Else
Begin
	Set @sStoredProcedure = 'wpw_ListWorkHistory'
End

If @nErrorCode = 0 
Begin

	-- Retrieve the Filter elements using element-centric mapping
	Set @sSQLString = null
	Set @sSQLString = @sSQLString +
	"Select @nEntityKey		= EntityKey,"+CHAR(10)+	
	"	@nEntityKeyOperator	= EntityKeyOperator,"+CHAR(10)+
	"	@sTransactionTypeKeys	= TransactionTypeKeys,"+CHAR(10)+
	"	@nTransactionTypeKeysOperator=TransactionTypeKeysOperator,"+CHAR(10)+
	"	@nDateRangeOperator	= DateRangeOperator,"+CHAR(10)+	
	"	@dtDateRangeFrom	= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo		= DateRangeTo,"+CHAR(10)+
	"	@nPeriodRangeOperator	= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType	= CASE WHEN PeriodRangeType = 'D' THEN 'dd'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'W' THEN 'wk'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'M' THEN 'mm'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'Y' THEN 'yy'"+CHAR(10)+
	"				  END,"+CHAR(10)+
	"	@nPeriodRangeFrom	= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo		= PeriodRangeTo,"+CHAR(10)+
	"	@bStaffKeyIsCurrentUser = StaffKeyIsCurrentUser,"+CHAR(10)+
	"	@nStaffKey		= StaffKey,"+CHAR(10)+
	"	@nStaffKeyOperator	= StaffKeyOperator,"+CHAR(10)+
	"	@nMemberOfGroupKey	= MemberOfGroupKey,"+CHAR(10)+
	"	@nMemberOfGroupKeyOperator=MemberOfGroupKeyOperator,"+CHAR(10)+
	"	@bMemberOfGroupKeyIsCurrentUser=MemberOfGroupKeyIsCurrentUser,"+CHAR(10)+
	"	@bIsWIPStaff		= IsWIPStaff,"+CHAR(10)+
	"	@bIsResponsibleFor	= IsResponsibleFor,"+CHAR(10)+
	"	@nRegionKey		= RegionKey,"+CHAR(10)+
	"	@nRegionKeyOperator	= RegionKeyOperator,"+CHAR(10)+
	"	@bIsRenewalDebtor	= IsRenewalDebtor,"+CHAR(10)+
	"	@nBillFrequencyKey	= BillFrequencyKey,"+CHAR(10)+
	"	@nBillFrequencyKeyOperator=BillFrequencyKeyOperator,"+CHAR(10)+
	"	@sCountryKey		= CountryKey,"+CHAR(10)+
	"	@nCountryKeyOperator	= CountryKeyOperator,"+CHAR(10)+
	"	@nResponsibleNameKey	= ResponsibleNameKey,"+CHAR(10)+
	"	@bIsInstructor		= IsInstructor,"+CHAR(10)+
	"	@bIsDebtor		= IsDebtor,"+CHAR(10)+
	"	@bIsActiveWIPStatus	= IsActiveWIPStatus,"+CHAR(10)+
	"	@bIsLockedWIPStatus	= IsLockedWIPStatus,"+CHAR(10)+
	"	@bIsBilledWIPStatus	= IsBilledWIPStatus,"+CHAR(10)+
	"	@nCaseKey		= CaseKey,"+CHAR(10)+
	"	@nCaseKeyOperator	= CaseKeyOperator,"+CHAR(10)+
	"	@nAllocatedDebtorKey	= AllocatedDebtorKey,"+CHAR(10)+
        "       @bIsAnyNameType         = AnyNameType"+CHAR(10)+
	"from	OPENXML (@idoc, '//"+@sStoredProcedure+"/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      EntityKey			int		'EntityKey/text()',"+CHAR(10)+
	"	      EntityKeyOperator		tinyint		'EntityKey/@Operator/text()',"+CHAR(10)+
	"	      TransactionTypeKeys	nvarchar(254)	'TransactionTypeKeys/text()',"+CHAR(10)+
	"	      TransactionTypeKeysOperator tinyint	'TransactionTypeKeys/@Operator/text()',"+CHAR(10)+	
	"	      DateRangeOperator		tinyint		'ItemDate/DateRange/@Operator/text()',"+CHAR(10)+
	"	      DateRangeFrom		datetime	'ItemDate/DateRange/From/text()',"+CHAR(10)+
	"	      DateRangeTo		datetime	'ItemDate/DateRange/To/text()',"+CHAR(10)+
	"	      PeriodRangeOperator	tinyint		'ItemDate/PeriodRange/@Operator/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'ItemDate/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'ItemDate/PeriodRange/To/text()',"+CHAR(10)+
	"	      PeriodRangeType		nvarchar(2)	'ItemDate/PeriodRange/Type/text()',"+CHAR(10)+
	"	      StaffKeyIsCurrentUser	bit		'BelongsTo/StaffKey/@IsCurrentUser/text()',"+CHAR(10)+
	"	      StaffKey			int		'BelongsTo/StaffKey/text()',"+CHAR(10)+	
	"	      StaffKeyOperator		tinyint		'BelongsTo/StaffKey/@Operator/text()',"+CHAR(10)+	
	"	      MemberOfGroupKey		smallint	'BelongsTo/MemberOfGroupKey/text()',"+CHAR(10)+	
	"	      MemberOfGroupKeyOperator	tinyint		'BelongsTo/MemberOfGroupKey/@Operator/text()',"+CHAR(10)+	
	"	      MemberOfGroupKeyIsCurrentUser bit		'BelongsTo/MemberOfGroupKey/@IsCurrentUser/text()',"+CHAR(10)+	
	"	      IsWIPStaff		bit		'BelongsTo/ActingAs/IsWipStaff/text()',"+CHAR(10)+	
	"	      IsResponsibleFor		bit		'BelongsTo/ActingAs/AssociatedName/text()',"+CHAR(10)+	
	"	      RegionKey			int		'RegionKey/text()',"+CHAR(10)+
	"	      RegionKeyOperator		tinyint		'RegionKey/@Operator/text()',"+CHAR(10)+
	"	      IsRenewalDebtor		bit		'Debtor/@IsRenewalDebtor/text()',"+CHAR(10)+
	"	      BillFrequencyKey		int		'Debtor/BillFrequencyKey/text()',"+CHAR(10)+
	"	      BillFrequencyKeyOperator  tinyint		'Debtor/BillFrequencyKey/@Operator/text()',"+CHAR(10)+
	"	      CountryKey		nvarchar(3)	'Debtor/CountryKey/text()',"+CHAR(10)+
	"	      CountryKeyOperator	tinyint		'Debtor/CountryKey/@Operator/text()',"+CHAR(10)+
	"	      ResponsibleNameKey	nvarchar(1000)		'ResponsibleName/NameKey/text()',"+CHAR(10)+
	"	      IsInstructor		bit		'ResponsibleName/IsInstructor/text()',"+CHAR(10)+
	"	      IsDebtor			bit		'ResponsibleName/IsDebtor/text()',"+CHAR(10)+
	"	      IsActiveWIPStatus		bit		'WipStatus/IsActive/text()',"+CHAR(10)+
	"	      IsLockedWIPStatus		bit		'WipStatus/IsLocked/text()',"+CHAR(10)+
	"	      IsBilledWIPStatus		bit		'WipStatus/IsBilled/text()',"+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+
	"	      CaseKeyOperator		tinyint		'CaseKey/@Operator/text()',"+CHAR(10)+
	"	      AllocatedDebtorKey	nvarchar(100)	'AllocatedDebtor/NameKey/text()',"+CHAR(10)+	
        "             AnyNameType               bit             'BelongsTo/ActingAs/AnyNameType/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nEntityKey			int			output,
				  @nEntityKeyOperator		tinyint			output,
				  @sTransactionTypeKeys		nvarchar(254)		output,
				  @nTransactionTypeKeysOperator	tinyint			output,
				  @nDateRangeOperator		tinyint			output,
				  @dtDateRangeFrom		datetime		output,
				  @dtDateRangeTo 		datetime		output,
				  @nPeriodRangeOperator		tinyint			output,
				  @sPeriodRangeType		nvarchar(2)		output,
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bStaffKeyIsCurrentUser	bit			output,
				  @nStaffKey			int			output,
				  @nStaffKeyOperator		tinyint			output,
				  @nMemberOfGroupKey		smallint		output,
				  @nMemberOfGroupKeyOperator 	tinyint			output,
				  @bMemberOfGroupKeyIsCurrentUser bit			output,
				  @bIsWIPStaff			bit			output,
				  @bIsResponsibleFor		bit			output,
				  @nRegionKey			int			output,
				  @nRegionKeyOperator		tinyint			output,
				  @bIsRenewalDebtor		bit			output,
				  @nBillFrequencyKey		int			output,
				  @nBillFrequencyKeyOperator	tinyint			output,
				  @sCountryKey			nvarchar(3)		output,
				  @nCountryKeyOperator		tinyint			output,
				  @nResponsibleNameKey		nvarchar(1000)			output,
				  @bIsInstructor		bit			output,
				  @bIsDebtor			bit			output,
				  @bIsActiveWIPStatus		bit			output,
				  @bIsLockedWIPStatus		bit			output,
				  @bIsBilledWIPStatus		bit			output,
				  @nCaseKey			int			output,
				  @nCaseKeyOperator		tinyint			output,
				  @nAllocatedDebtorKey		nvarchar(100)		output,
                                  @bIsAnyNameType               bit                     output',
				  @idoc				= @idoc,
				  @nEntityKey			= @nEntityKey		output,
				  @nEntityKeyOperator		= @nEntityKeyOperator	output,
				  @sTransactionTypeKeys		= @sTransactionTypeKeys	output,
				  @nTransactionTypeKeysOperator	= @nTransactionTypeKeysOperator output,
				  @nDateRangeOperator		= @nDateRangeOperator	output,
				  @dtDateRangeFrom		= @dtDateRangeFrom	output,
				  @dtDateRangeTo 		= @dtDateRangeTo 	output,
				  @nPeriodRangeOperator		= @nPeriodRangeOperator output,
				  @sPeriodRangeType		= @sPeriodRangeType	output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom 	output,
				  @nPeriodRangeTo		= @nPeriodRangeTo	output,
				  @bStaffKeyIsCurrentUser	= @bStaffKeyIsCurrentUser output,
				  @nStaffKey			= @nStaffKey		output,
				  @nStaffKeyOperator		= @nStaffKeyOperator	output,
				  @nMemberOfGroupKey		= @nMemberOfGroupKey	output,
				  @nMemberOfGroupKeyOperator	= @nMemberOfGroupKeyOperator output,
				  @bMemberOfGroupKeyIsCurrentUser=@bMemberOfGroupKeyIsCurrentUser output,
				  @bIsWIPStaff			= @bIsWIPStaff		output,
				  @bIsResponsibleFor		= @bIsResponsibleFor	output,
				  @nRegionKey			= @nRegionKey		output,
				  @nRegionKeyOperator		= @nRegionKeyOperator	output,
				  @bIsRenewalDebtor		= @bIsRenewalDebtor	output,
				  @nBillFrequencyKey		= @nBillFrequencyKey	output,
				  @nBillFrequencyKeyOperator	= @nBillFrequencyKeyOperator output,
				  @sCountryKey			= @sCountryKey		output,
				  @nCountryKeyOperator		= @nCountryKeyOperator	output,
				  @nResponsibleNameKey		= @nResponsibleNameKey	output,
				  @bIsInstructor		= @bIsInstructor	output,
				  @bIsDebtor			= @bIsDebtor		output,
				  @bIsActiveWIPStatus		= @bIsActiveWIPStatus	output,
				  @bIsLockedWIPStatus		= @bIsLockedWIPStatus	output,
				  @bIsBilledWIPStatus		= @bIsBilledWIPStatus	output,
				  @nCaseKey			= @nCaseKey		output,
				  @nCaseKeyOperator		= @nCaseKeyOperator	output,
				  @nAllocatedDebtorKey		= @nAllocatedDebtorKey	output,
                                  @bIsAnyNameType               = @bIsAnyNameType       output

	-- Retrieve the Filter elements using element-centric mapping

	Set @sSQLString = 	
	"Select @nWipNameKey		= WipNameKey,"+CHAR(10)+
	"	@nWipNameKeyOperator	= WipNameKeyOperator,"+CHAR(10)+
	"	@sCurrencyCode		= CurrencyCode,"+CHAR(10)+
	"	@nCurrencyCodeOperator	= CurrencyCodeOperator,"+CHAR(10)+
	"	@bIsTotalAgedBalance	= IsTotalAgedBalance,"+CHAR(10)+
	"	@nAgedBalanceBracketNumber=AgedBalanceBracketNumber,"+CHAR(10)+
	"	@bIsRenewalWIP		= IsRenewalWIP,"+CHAR(10)+	
	"	@bIsNonRenewalWIP	= IsNonRenewalWIP,"+CHAR(10)+
	"       @bShowAllocatedDebtorWIP = ShowAllocatedDebtorWIP"+CHAR(10)+
	"from	OPENXML (@idoc, '//"+@sStoredProcedure+"/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      WipNameKey		int		'WipNameKey/text()',"+CHAR(10)+
	"	      WipNameKeyOperator	tinyint		'WipNameKey/@Operator',"+CHAR(10)+
	"	      CurrencyCode		nvarchar(3)	'CurrencyCode/text()',"+CHAR(10)+
	"	      CurrencyCodeOperator	tinyint		'CurrencyCode/@Operator/text()',"+CHAR(10)+
	"	      IsTotalAgedBalance	bit		'AgedBalance/IsTotal/text()',"+CHAR(10)+
	"	      AgedBalanceBracketNumber	tinyint		'AgedBalance/BracketNumber/text()',"+CHAR(10)+
	"	      IsRenewalWIP		bit		'RenewalWip/IsRenewal/text()',"+CHAR(10)+
	"	      IsNonRenewalWIP		bit		'RenewalWip/IsNonRenewal/text()',"+CHAR(10)+
	"	      ShowAllocatedDebtorWIP	bit		'ShowAllocatedDebtorWIP/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nWipNameKey			int			output,
				  @nWipNameKeyOperator		tinyint			output,
				  @sCurrencyCode		nvarchar(3)		output,
				  @nCurrencyCodeOperator	tinyint			output,
				  @bIsTotalAgedBalance		bit			output,
				  @nAgedBalanceBracketNumber	tinyint			output,
				  @bIsRenewalWIP		bit			output,
				  @bIsNonRenewalWIP		bit			output,
				  @bShowAllocatedDebtorWIP      bit                     output',
				  @idoc				= @idoc,
				  @nWipNameKey			= @nWipNameKey		output,
				  @nWipNameKeyOperator		= @nWipNameKeyOperator	output,
				  @sCurrencyCode		= @sCurrencyCode	output,
				  @nCurrencyCodeOperator	= @nCurrencyCodeOperator output,
				  @bIsTotalAgedBalance		= @bIsTotalAgedBalance	output,
				  @nAgedBalanceBracketNumber	= @nAgedBalanceBracketNumber output,
				  @bIsRenewalWIP		= @bIsRenewalWIP	output,
				  @bIsNonRenewalWIP		= @bIsNonRenewalWIP	output,
				  @bShowAllocatedDebtorWIP      = @bShowAllocatedDebtorWIP      output

	-- Retrieve Work History related Filters
	Set @sSQLString = 
		"Select @bIsWIPSearch		= IsWIPSearch,"+CHAR(10)+
		"@dtPostDateFrom		= PostDateFrom,"+CHAR(10)+
		"@dtPostDateTo			= PostDateTo,"+CHAR(10)+
		"@dtPostDateOperator		= PostDateOperator,"+CHAR(10)+
		"@nAssociateKey			= AssociateKey,"+CHAR(10)+
		"@nAssociateOperator		= AssociateOperator,"+CHAR(10)+
		"@sSupplierInvoiceNo		= SupplierInvoiceNo,"+CHAR(10)+
		"@nSupplierInvoiceNoOperator	= SupplierInvoiceNoOperator,"+CHAR(10)+
		"@bIsInternalWIP		= IsInternalWIP,"+CHAR(10)+
		"@bIsClassWIP			= IsClassWIP,"+CHAR(10)+
		"@bIsClassBilling		= IsClassBilling,"+CHAR(10)+
		"@bIsClassWIPVariation		= IsClassWIPVariation,"+CHAR(10)+
		"@bIsClassAdjustments		= IsClassAdjustments,"+CHAR(10)+
		"@bIsServiceFees		= IsServiceFees,"+CHAR(10)+
		"@bIsPaidDisbursements		= IsPaidDisbursements,"+CHAR(10)+
		"@bIsRecoverables		= IsRecoverables"+CHAR(10)+
		"from	OPENXML (@idoc, '//"+@sStoredProcedure+"/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"IsWIPSearch		bit		'IsWIPSearch/text()',"+char(10)+
		"PostDateFrom		datetime	'PostDate/DateRange/From/text()',"+CHAR(10)+
		"PostDateTo		datetime	'PostDate/DateRange/To/text()',"+CHAR(10)+
		"PostDateOperator	tinyint		'PostDate/DateRange/@Operator/text()',"+CHAR(10)+
		"AssociateKey		int		'AssociateKey/text()',"+CHAR(10)+
		"AssociateOperator	tinyint		'AssociateKey/@Operator/text()',"+CHAR(10)+
		"SupplierInvoiceNo	nvarchar(20)	'SupplierInvoiceNo/text()',"+CHAR(10)+
		"SupplierInvoiceNoOperator tinyint	'SupplierInvoiceNo/@Operator/text()',"+CHAR(10)+
		"IsInternalWIP		bit		'IsInternalWIP/text()',"+CHAR(10)+
		"IsClassWIP		bit		'IsClassWIP/text()',"+CHAR(10)+
		"IsClassBilling		bit		'IsClassBilling/text()',"+CHAR(10)+
		"IsClassWIPVariation	bit		'IsClassWIPVariation/text()',"+CHAR(10)+
		"IsClassAdjustments	bit		'IsClassAdjustments/text()',"+CHAR(10)+
		"IsServiceFees		bit		'IsServiceFees/text()',"+CHAR(10)+
		"IsPaidDisbursements	bit		'IsPaidDisbursements/text()',"+CHAR(10)+
		"IsRecoverables		bit		'IsRecoverables/text()'"+CHAR(10)+
	     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				@bIsWIPSearch			bit output,
				@dtPostDateFrom			datetime output,
				@dtPostDateTo			datetime output,
				@dtPostDateOperator		tinyint output,
				@nAssociateKey			int output,
				@nAssociateOperator		tinyint output,
				@sSupplierInvoiceNo		nvarchar(20) output,
				@nSupplierInvoiceNoOperator	tinyint output,
				@bIsInternalWIP			bit output,
				@bIsClassWIP			bit output,
				@bIsClassBilling		bit output,
				@bIsClassWIPVariation		bit output,
				@bIsClassAdjustments		bit output,
				@bIsServiceFees			bit output,
				@bIsPaidDisbursements		bit output,
				@bIsRecoverables		bit output',
				@idoc				= @idoc,
				@bIsWIPSearch			= @bIsWIPSearch output,
				@dtPostDateFrom			= @dtPostDateFrom output,
				@dtPostDateTo			= @dtPostDateTo output,
				@dtPostDateOperator		= @dtPostDateOperator output,
				@nAssociateKey			= @nAssociateKey output,
				@nAssociateOperator		= @nAssociateOperator output,
				@sSupplierInvoiceNo		= @sSupplierInvoiceNo output,
				@nSupplierInvoiceNoOperator	= @nSupplierInvoiceNoOperator output,
				@bIsInternalWIP			= @bIsInternalWIP output,
				@bIsClassWIP			= @bIsClassWIP output,
				@bIsClassBilling		= @bIsClassBilling output,
				@bIsClassWIPVariation		= @bIsClassWIPVariation output,
				@bIsClassAdjustments		= @bIsClassAdjustments output,
				@bIsServiceFees			= @bIsServiceFees output,
				@bIsPaidDisbursements		= @bIsPaidDisbursements output,
				@bIsRecoverables		= @bIsRecoverables output

	If (@nErrorCode = 0 and @bIsWIPSearch = 1)
	and PATINDEX ('%<AggregateFilterCriteria>%', @ptXMLFilterCriteria)>0 
	Begin
		Set @sSQLString = 	
		"Select @nSumLocalBalanceFrom		= SumLocalBalanceFrom,"+CHAR(10)+	
		"	@nSumLocalBalanceTo		= SumLocalBalanceTo,"+CHAR(10)+
		"	@nSumLocalBalanceOperator	= SumLocalBalanceOperator"+CHAR(10)+
		"from	OPENXML (@idoc, '//wpw_ListWorkHistory/AggregateFilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      SumLocalBalanceFrom	decimal(11,2)	'SumLocalBalance/From/text()',"+CHAR(10)+
		"	      SumLocalBalanceTo		decimal(11,2)	'SumLocalBalance/To/text()',"+CHAR(10)+
		"	      SumLocalBalanceOperator	tinyint		'SumLocalBalance/@Operator/text()'"+CHAR(10)+	
	     	"     	     )"
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @nSumLocalBalanceFrom		decimal(11,2)		output,
					  @nSumLocalBalanceTo		decimal(11,2)		output,
					  @nSumLocalBalanceOperator 	tinyint			output',
					  @idoc				= @idoc,
					  @nSumLocalBalanceFrom		= @nSumLocalBalanceFrom	output,
					  @nSumLocalBalanceTo		= @nSumLocalBalanceTo	output,
					  @nSumLocalBalanceOperator 	= @nSumLocalBalanceOperator output
	End


	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
			"Select @sNameTypeKeys = @sNameTypeKeys + nullif(',', ',' + @sNameTypeKeys) + dbo.fn_WrapQuotes(NameTypeKey,0,0)"+CHAR(10)+
			"from	OPENXML (@idoc, '//"+@sStoredProcedure+"/FilterCriteria/BelongsTo/ActingAs/CaseName/NameTypeKey', 2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			"      NameTypeKey	nvarchar(3)	'text()'"+CHAR(10)+
			"     )"+CHAR(10)+
			"where NameTypeKey is not null"

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc		int,
						@sNameTypeKeys	nvarchar(4000) output',
						@idoc		= @idoc,
						@sNameTypeKeys 	= @sNameTypeKeys output
	End
End

If @nErrorCode = 0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @sWhere = char(10)+"	WHERE 1=1"

	If (@sStoredProcedure = 'wp_ListWorkInProgress' or @bIsWIPSearch = 1)
	Begin
		Set @sFrom  = char(10)+"	FROM      WORKINPROGRESS XW"
		Set @bIsWIPSearch = 1
	End
	Else
	Begin
		Set @sFrom  = char(10)+"	FROM      WORKHISTORY XW"+char(10)+
					"	left join WORKINPROGRESS XWIP on (XWIP.ENTITYNO = XW.ENTITYNO"+CHAR(10)+
					"				and XWIP.TRANSNO = XW.TRANSNO"+CHAR(10)+
					"				and XWIP.WIPSEQNO = XW.WIPSEQNO)"
	End

	---------------------------------
	-- Check to see if Ethical Walls
	-- for Cases are being used.
	---------------------------------
	If exists (select 1 
		   from NAMETYPE NT
		   join CASENAME CN on (CN.NAMETYPE=NT.NAMETYPE)
		   where NT.ETHICALWALL>0)
	Begin
		Set @sFrom  = @sFrom  + char(10)+"	left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") EWC on (EWC.CASEID=XW.CASEID)"

		Set @sWhere = @sWhere + char(10)+"	and (EWC.CASEID is not null OR XW.CASEID       is null)"
	End

	---------------------------------
	-- Check to see if Ethical Walls
	-- for Names are being used.
	---------------------------------
	If exists (select 1
		   from NAMERELATION NR
		   join ASSOCIATEDNAME AN on (AN.RELATIONSHIP=NR.RELATIONSHIP)
		   where NR.ETHICALWALL>0)
	Begin
		Set @sFrom  = @sFrom  + char(10)+"	left join dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") EWN on (EWN.NAMENO=XW.ACCTCLIENTNO)"

		Set @sWhere = @sWhere + char(10)+"	and (EWN.NAMENO is not null OR XW.ACCTCLIENTNO is null)"
	End


End

-- Construction of the WIP recorded against the Name filter criteria:
If @nErrorCode = 0
Begin
	If @nEntityKey is not NULL
	or @nEntityKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"	and	XW.ENTITYNO"+dbo.fn_ConstructOperator(@nEntityKeyOperator,@Numeric,@nEntityKey, null,@pbCalledFromCentura)
	End
End

-- Contruction of the WIP of a transaction type:
If @nErrorCode = 0
Begin
	If @sTransactionTypeKeys is not null
	Begin
		If (@sStoredProcedure = 'wp_ListWorkInProgress' or @bIsWIPSearch = 1)
		Begin
			Set @sFrom  = @sFrom + char(10)+"	left join TRANSACTIONHEADER XTH on (XTH.TRANSNO = XW.TRANSNO and XTH.ENTITYNO = XW.ENTITYNO)"
			Set @sWhere = @sWhere + char(10)+"	and XTH.TRANSTYPE"+dbo.fn_ConstructOperator(@nTransactionTypeKeysOperator,@CommaString,@sTransactionTypeKeys,null,@pbCalledFromCentura)
		End
		Else
		Begin
			Set @sFrom  = @sFrom + char(10)+"	left join TRANSACTIONHEADER XTH on (XTH.TRANSNO = XWIP.TRANSNO and XTH.ENTITYNO = XWIP.ENTITYNO)"
			Set @sWhere = @sWhere + char(10)+"	and XTH.TRANSTYPE"+dbo.fn_ConstructOperator(@nTransactionTypeKeysOperator,@CommaString,@sTransactionTypeKeys,null,@pbCalledFromCentura)
		End
	End
End

-- Construction of the WIP recorded against the Case filter criteria:
If  @nErrorCode = 0
and exists(Select 1 from OPENXML (@idoc, '//csw_ListCase/*//FilterCriteria/*', 2))
Begin
	-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
	-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
	-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
	-- table that may hold the filtered list of cases.
	exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sCaseWhere	  	OUTPUT, 			
						@psTempTableName 	= @psCurrentCaseTable	OUTPUT,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= @pbCalledFromCentura		
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc	

-- Construction of the General filter criteria:
If @nErrorCode = 0
Begin
	-- If Period Range and Period Type are supplied, these are used to calculate WIP From date
	-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
	-- current date.  	

	If   @sPeriodRangeType is not null
	and (@nPeriodRangeFrom is not null
	 or  @nPeriodRangeTo   is not null)
	Begin		
		If @nPeriodRangeFrom is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodRangeType+", "+"-"+"@nPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeFrom	datetime 		output,
	 				  @sPeriodRangeType	nvarchar(2),
					  @nPeriodRangeFrom	smallint',
	  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
					  @sPeriodRangeType	= @sPeriodRangeType,
					  @nPeriodRangeFrom	= @nPeriodRangeFrom				  
		End
	
		If @nPeriodRangeTo is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodRangeType+", "+"-"+"@nPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeTo	datetime 		output,
	 				  @sPeriodRangeType	nvarchar(2),
					  @nPeriodRangeTo	smallint',
	  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
					  @sPeriodRangeType	= @sPeriodRangeType,
					  @nPeriodRangeTo	= @nPeriodRangeTo				
		End				  
	End		

	If  (@nDateRangeOperator is not null
	 or  @nPeriodRangeOperator is not null)
	and (@dtDateRangeFrom is not null
	or   @dtDateRangeTo is not null)
	Begin
		If @sPeriodRangeType is not null
		and (@nPeriodRangeFrom is not null
		or  @nPeriodRangeTo   is not null)
		Begin		
			-- For the PeriodRange filtering swap around @dtDateRangeFrom and @dtDateRangeTo:
			Set @sWhere = @sWhere+char(10)+" and XW.TRANSDATE "+dbo.fn_ConstructOperator(@nPeriodRangeOperator,@Date,convert(nvarchar,@dtDateRangeTo,112), convert(nvarchar,@dtDateRangeFrom,112),0)									
		End
		Else Begin
			Set @sWhere = @sWhere+char(10)+" and XW.TRANSDATE "+dbo.fn_ConstructOperator(@nDateRangeOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),0)									
		End
	End	

	-- Default the RenewalWip filter criteria
	Set @bIsRenewalWIP = isnull(@bIsRenewalWIP, 0)
	Set @bIsNonRenewalWIP = isnull(@bIsNonRenewalWIP, 0)

	If (@bIsRenewalWIP = 1 and @bIsNonRenewalWIP = 0)
	or (@bIsRenewalWIP = 0 and @bIsNonRenewalWIP = 1)
	Begin
		If charindex('join WIPTEMPLATE WTMP',@sFrom)=0	
		Begin
			Set @sFrom = @sFrom		+char(10)+"join WIPTEMPLATE WTMP	on (WTMP.WIPCODE = XW.WIPCODE)"							
		End

		If @bIsRenewalWIP = 1 and @bIsNonRenewalWIP = 0
		Begin	
			Set @sWhere = @sWhere+char(10)+"and WTMP.RENEWALFLAG = 1"
		End
		Else If @bIsRenewalWIP = 0 and @bIsNonRenewalWIP = 1
		Begin	
			Set @sWhere = @sWhere+char(10)+"and WTMP.RENEWALFLAG = 0"
		End
	End	

	If @bStaffKeyIsCurrentUser = 1
	or @bMemberOfGroupKeyIsCurrentUser = 1
	Begin
		-- Reduce the number of joins in the main statement.
	
		Set @sSQLString = "
		Select  @nStaffKey 	   = 	CASE 	WHEN @bStaffKeyIsCurrentUser = 1
					 		THEN U.NAMENO ELSE @nStaffKey END, 
			@nMemberOfGroupKey = 	CASE 	WHEN @bMemberOfGroupKeyIsCurrentUser = 1 
						  	THEN N.FAMILYNO ELSE @nMemberOfGroupKey END, 
			@nNullGroupNameKey = 	CASE 	WHEN @bMemberOfGroupKeyIsCurrentUser = 1 and N.FAMILYNO is null
						  	THEN U.NAMENO END
		from USERIDENTITY U
		join NAME N on (N.NAMENO = U.NAMENO)
		where IDENTITYID = @pnUserIdentityId"

		exec @nErrorCode=sp_executesql @sSQLString,
						      N'@nStaffKey			int			OUTPUT,
							@nMemberOfGroupKey		smallint		OUTPUT,
							@nNullGroupNameKey		int			OUTPUT,
							@pnUserIdentityId		int,
							@bStaffKeyIsCurrentUser		bit,
							@bMemberOfGroupKeyIsCurrentUser	bit',
							@nStaffKey 			= @nStaffKey 		OUTPUT,
							@nMemberOfGroupKey		= @nMemberOfGroupKey 	OUTPUT,
							@nNullGroupNameKey		= @nNullGroupNameKey	OUTPUT,
							@pnUserIdentityId		= @pnUserIdentityId,
							@bStaffKeyIsCurrentUser		= @bStaffKeyIsCurrentUser,
							@bMemberOfGroupKeyIsCurrentUser	= @bMemberOfGroupKeyIsCurrentUser								
	End			

	-- If staff members have been identified and no acting as information is provided, 
	-- assume NameTypeKey=’EMP’ and IsResponsibleFor is true:
	If @nErrorCode = 0
	and (@nStaffKey is not null
	 or  @nStaffKeyOperator in (5,6))
	and  isnull(@bIsWIPStaff,0) =0	--RFC121522
	and  isnull(@bIsResponsibleFor,0) = 0 
	and  @sNameTypeKeys is null
        and  isnull(@bIsAnyNameType, 0) = 0 
	Begin
		if(@nStaffKey is not null)
		Begin
			Set @sNameTypeKeys = "'D','Z'" -- To check for debtor and renewal debtor
			Set @bIsStaffMemeberWithoutActingAs = 1
		End
		else
		begin
			Set @sNameTypeKeys = dbo.fn_WrapQuotes('EMP',0,0)
		end
		Set @bIsResponsibleFor = 1
	End	

	-- RFC121522
	-- If Anyone In My Group is in filter and no acting as information is provided, 
	-- assume NameTypeKey=’EMP’ and IsResponsibleFor is true:
	If @nErrorCode = 0
	and  @bMemberOfGroupKeyIsCurrentUser = 1
	and  isnull(@bIsWIPStaff,0) = 0
	and  isnull(@bIsResponsibleFor,0) = 0 
    and  isnull(@bIsAnyNameType, 0) = 0
	and  @sNameTypeKeys is null
	Begin
		Set @sNameTypeKeys = dbo.fn_WrapQuotes('EMP',0,0)
		Set @bIsResponsibleFor = 1
	End

	-- If the user does not belong to a group and 'Belonging to Anyone in my group'
	-- we should return an empty  result set:
	If   @bMemberOfGroupKeyIsCurrentUser = 1
	and  @nMemberOfGroupKey is null
	and  @nMemberOfGroupKeyOperator is not null
	Begin
		Set @sFrom = @sFrom   +char(10)+" join NAME NULF	on (NULF.NAMENO = "+CAST(@nNullGroupNameKey  as varchar(11))
				      +char(10)+"		 	and NULF.FAMILYNO is not null)"								 
	End

	-- Keep the values of the Staff and Group member operators for 
	-- the future processing logic:
	Set @nOriginalStaffKeyOperator = @nStaffKeyOperator
	Set @nOriginalMemberOfGroupKeyOperator = @nMemberOfGroupKeyOperator

	If  @nStaffKey is not null 
	or  @nStaffKeyOperator between 2 and 6		
	or  @nMemberOfGroupKey is not null
	or  @nMemberOfGroupKeyOperator between 2 and 6	
	Begin
		-- Any WIP where the name is the the staff member 
		-- recorded against the WIP item.	
		If  @sNameTypeKeys is null
		and isnull(@bIsResponsibleFor,0) = 0 
                and isnull(@bIsAnyNameType, 0) = 0
		and @bIsWIPStaff = 1
		and (@nStaffKey is not null 
		 or  @nStaffKeyOperator between 2 and 6)
		Begin
			Set @sWhere = @sWhere+char(10)+" and XW.EMPLOYEENO"+dbo.fn_ConstructOperator(@nStaffKeyOperator,@Numeric,@nStaffKey, null,0)
		End

		-- Any WIP where the group member is the the staff member 
		-- recorded against the WIP item.	
		If  @sNameTypeKeys is null
		and isnull(@bIsResponsibleFor,0) = 0 
                and  isnull(@bIsAnyNameType, 0) = 0
		and @bIsWIPStaff = 1
		and (@nMemberOfGroupKey is not null 
		 or  @nMemberOfGroupKeyOperator between 2 and 6)
		Begin
			If @nMemberOfGroupKeyOperator not in (5,6)
			and @nMemberOfGroupKey is not null
			Begin
				Set @sFrom = @sFrom		+char(10)+" join NAME N	on (N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
								+char(10)+"		and XW.EMPLOYEENO = N.NAMENO)"					
			End
	
        		Else If @nMemberOfGroupKeyOperator = 5
			Begin 
				Set @sFrom = @sFrom		+char(10)+" join NAME N	on (N.FAMILYNO is not null"
								+char(10)+"		and XW.EMPLOYEENO = N.NAMENO)"				
			End	
			Else If @nMemberOfGroupKeyOperator = 6
			Begin 
				Set @sFrom = @sFrom		+char(10)+" join NAME N	on (N.FAMILYNO is null"
								+char(10)+"		and XW.EMPLOYEENO = N.NAMENO)"										     		
			End	
		End

		-- Check if the WIP recorded against a case 
		-- is to be filtered:
		-- Construct the Cases WIP filtering:

		If  @sNameTypeKeys is not null or isnull(@bIsAnyNameType, 0) = 1
		Begin
			Set @sCaseWhere = @sCaseWhere+char(10)+"and ("
			Set @sOr    = NULL		
		
			-- If Operator is set to IS NULL then use NOT EXISTS
			If @nStaffKeyOperator in (1,6)			
			or @nMemberOfGroupKeyOperator in (1,6)
			Begin  				
				If @nStaffKeyOperator in (1,6)
				Begin
					-- Set operator to 0 as we use 'not exists':
					Set @nStaffKeyOperator = 0				
					-- Set the 'Reset' flags to 1 so the name filtering logic will be aware of 
					-- modified operators:
					Set @bIsResetStaffKeyOperator = 1  
				End
	
				If @nMemberOfGroupKeyOperator in (1,6)
				Begin
					-- Set operator to 0 as we use 'not exists':
					Set @nMemberOfGroupKeyOperator = 0		
						
					Set @bIsReserMemberOfGroupKeyOperator = 1
				End				
	
				Set @sCaseWhere=@sCaseWhere+char(10)+" not exists"
			End
			Else Begin  
				Set @sCaseWhere=@sCaseWhere+char(10)+" exists"
			End			
	
					Set @sCaseWhere = @sCaseWhere	+char(10)+"(Select * "  
					     				+char(10)+" from CASENAME CN"  							     
			if (@bIsStaffMemeberWithoutActingAs = 1)
			Begin 
				Set @sCaseWhere = @sCaseWhere	+char(10)+" join ASSOCIATEDNAME AN	on (AN.NAMENO = CN.NAMENO)"
			End						     
			If  @nMemberOfGroupKey is not null 
			or  @nMemberOfGroupKeyOperator is not null
			Begin			
				If @nMemberOfGroupKeyOperator not in (5,6)
				and @nMemberOfGroupKey is not null
				Begin
					Set @sCaseWhere = @sCaseWhere	+char(10)+" join NAME N	on (N.NAMENO = CN.NAMENO"
							     		+char(10)+" 		and N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)+")"			
				End
				Else
				Begin 
					Set @sCaseWhere = @sCaseWhere	+char(10)+" join NAME N	on (N.NAMENO = CN.NAMENO"
									+char(10)+" 		and N.FAMILYNO is not null)"		
				End						
			End
					     
			Set @sCaseWhere = @sCaseWhere+char(10)+" where CN.CASEID = XW.CASEID"					  
	
			-- Ensure that the filter criteria is limited to values the user may view
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NAMETYPE,0,@pbCalledFromCentura)
			From dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,@bExternalUser,@pbCalledFromCentura)
	
			Set @sCaseWhere= @sCaseWhere+char(10)+"	and CN.NAMETYPE IN ("+@sList+")"
	
                        If @sNameTypeKeys is not null
                        Begin
			        Set @sCaseWhere = @sCaseWhere + char(10)+"and CN.NAMETYPE in ("+@sNameTypeKeys+")"	
                        End

			If(@bIsStaffMemeberWithoutActingAs = 1)
			Begin
				Set @sCaseWhere = @sCaseWhere+char(10)+" and AN.RELATEDNAME = "+CAST(@nStaffKey as varchar(11))				  
										+char(10)+"   and AN.RELATIONSHIP = 'RES'"
			End
			else
			Begin
				If  @nStaffKeyOperator not in (5,6)
				and @nStaffKey is not null 
				Begin
					Set @sCaseWhere = @sCaseWhere+char(10)+" and CN.NAMENO "+dbo.fn_ConstructOperator(@nStaffKeyOperator,@Numeric,@nStaffKey, null,0)
				End						
				Else Begin
					Set @sCaseWhere = @sCaseWhere+char(10)+" and CN.NAMENO is not null"
				End
			End	
	
			Set @sCaseWhere = @sCaseWhere+char(10)+" and (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate()))"	

			-- If 'not exists' is used with subquery then 
			-- use 'AND' instead of 'OR':
			If @bIsReserMemberOfGroupKeyOperator = 1
			Begin
				Set @sOr    =' AND '
			End
			Else Begin
				Set @sOr    =' OR '
			End		
				
			If @bIsWIPStaff = 1
			and (@nStaffKey is not null 
			 or  @nOriginalStaffKeyOperator between 2 and 6)
			Begin
				Set @sCaseWhere = @sCaseWhere+@sOr+char(10)+"XW.EMPLOYEENO"+dbo.fn_ConstructOperator(@nOriginalStaffKeyOperator,@Numeric,@nStaffKey, null,0)
			End
			Else 	
			If @bIsWIPStaff = 1
			and (@nMemberOfGroupKey is not null 
			 or  @nOriginalMemberOfGroupKeyOperator between 2 and 6)
			Begin
				If charindex('N.FAMILYNO',@sFrom)=0	
				Begin
					Set @sFrom = @sFrom		+char(10)+"left join NAME N	on (N.FAMILYNO "+dbo.fn_ConstructOperator(@nOriginalMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
									+char(10)+"			and XW.EMPLOYEENO = N.NAMENO)"		
				End							

				Set @sCaseWhere = @sCaseWhere+@sOr+char(10)+"XW.EMPLOYEENO = N.NAMENO"
			End
	
			Set @sCaseWhere = @sCaseWhere+char(10)+")"				
		End

		-- RFC74444
		-- WIP recorded against a Case should also consider any filtering
		-- by staff member
		ELSE If @bIsWIPStaff = 1
			and (@nStaffKey is not null 
			 or  @nOriginalStaffKeyOperator between 2 and 6)
			Begin
				Set @sCaseWhere = @sCaseWhere+char(10)+"and XW.EMPLOYEENO"+dbo.fn_ConstructOperator(@nOriginalStaffKeyOperator,@Numeric,@nStaffKey, null,0)
			End
			Else 	
			If @bIsWIPStaff = 1
			and (@nMemberOfGroupKey is not null 
			 or  @nOriginalMemberOfGroupKeyOperator between 2 and 6)
			Begin
				If charindex('N.FAMILYNO',@sFrom)=0	
				Begin
					Set @sFrom = @sFrom		+char(10)+"left join NAME N	on (N.FAMILYNO "+dbo.fn_ConstructOperator(@nOriginalMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
									+char(10)+"			and XW.EMPLOYEENO = N.NAMENO)"	
				End								

				Set @sCaseWhere = @sCaseWhere+char(10)+"and XW.EMPLOYEENO = N.NAMENO" 
			End

		-- Check if the WIP recorded against a name 
		-- is to be filtered:
		If @bIsResponsibleFor = 1
		Begin
			-- Construct the Name WIP filtering:

			Set @sAcctClientNoWhere = @sAcctClientNoWhere+char(10)+"and ("
			Set @sOr    = NULL
	
			-- If Operator is set to IS NULL then use NOT EXISTS
			If (@nStaffKeyOperator in (1,6)			
			or @nMemberOfGroupKeyOperator in (1,6))
			or (@bIsResetStaffKeyOperator = 1
			or  @bIsReserMemberOfGroupKeyOperator= 1)
			Begin  				
				If @nStaffKeyOperator in (1,6)	
				or @bIsResetStaffKeyOperator = 1
				Begin
					-- Set operator to 0 as we use 'not exists':
					Set @nStaffKeyOperator = 0				
				End
	
				If @nMemberOfGroupKeyOperator in (1,6)
				or @bIsReserMemberOfGroupKeyOperator = 1
				Begin
					-- Set operator to 0 as we use 'not exists':
					Set @nMemberOfGroupKeyOperator = 0								
				End				
	
				Set @sAcctClientNoWhere=@sAcctClientNoWhere+char(10)+" not exists"
			End
			Else Begin  
				Set @sAcctClientNoWhere=@sAcctClientNoWhere+char(10)+" exists"
			End			
	
			Set @sAcctClientNoWhere = @sAcctClientNoWhere	+char(10)+"(Select * "  
					     						+char(10)+" from ASSOCIATEDNAME AN"  							     
	
			If  @nMemberOfGroupKey is not null 
			or  @nMemberOfGroupKeyOperator is not null
			Begin				
				If @nMemberOfGroupKeyOperator not in (5,6)
				and @nMemberOfGroupKey is not null
				Begin
					Set @sAcctClientNoWhere = @sAcctClientNoWhere	+char(10)+" join NAME N	on (N.NAMENO = AN.RELATEDNAME"
											+char(10)+" 		and N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)+")"			
				End
				Else
				Begin 
					Set @sAcctClientNoWhere = @sAcctClientNoWhere	+char(10)+" join NAME N	on (N.NAMENO = AN.RELATEDNAME"
											+char(10)+" 		and N.FAMILYNO is not null)"		
				End						
			End

			If  @nStaffKeyOperator not in (5,6)
			and @nStaffKey is not null 
			Begin					     
				Set @sAcctClientNoWhere = @sAcctClientNoWhere	+char(10)+" where AN.RELATEDNAME = "+CAST(@nStaffKey as varchar(11))				  
										+char(10)+"   and AN.NAMENO = XW.ACCTCLIENTNO"
										+char(10)+"   and AN.RELATIONSHIP = 'RES')"
			End
			Else Begin
				Set @sAcctClientNoWhere = @sAcctClientNoWhere	+char(10)+" where AN.RELATEDNAME is not null"			  
										+char(10)+"   and AN.NAMENO = XW.ACCTCLIENTNO"
										+char(10)+"   and AN.RELATIONSHIP = 'RES')"
			End
		
			-- If 'not exists' is used with subquery then 
			-- use 'AND' instead of 'OR':
			If @bIsReserMemberOfGroupKeyOperator = 1
			Begin
				Set @sOr    =' AND '
			End
			Else Begin
				Set @sOr    =' OR '
			End				
	
			If @bIsWIPStaff = 1
			and (@nStaffKey is not null 
			 or  @nOriginalStaffKeyOperator between 2 and 6)
			Begin
				Set @sAcctClientNoWhere = @sAcctClientNoWhere+@sOr+char(10)+"XW.EMPLOYEENO"+dbo.fn_ConstructOperator(@nOriginalStaffKeyOperator,@Numeric,@nStaffKey, null,0)
			End
			Else
			If @bIsWIPStaff = 1
			and (@nMemberOfGroupKey is not null 
			 or  @nOriginalMemberOfGroupKeyOperator between 2 and 6)
			Begin
				If charindex('N.FAMILYNO',@sFrom)=0	
				Begin
					Set @sFrom = @sFrom		+char(10)+"left join NAME N	on (N.FAMILYNO "+dbo.fn_ConstructOperator(@nOriginalMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
									+char(10)+"			and XW.EMPLOYEENO = N.NAMENO)"									
				End
				
				Set @sAcctClientNoWhere = @sAcctClientNoWhere+@sOr+char(10)+" XW.EMPLOYEENO=N.NAMENO"
			End
	
			Set @sAcctClientNoWhere = @sAcctClientNoWhere+char(10)+")"			
		End		
	End

	If @nRegionKey is not null
	or @nRegionKeyOperator between 2 and 6
	Begin
		If @nRegionKeyOperator in (1,6)
		Begin
			Set @sOfficeWhere=@sOfficeWhere+char(10)+" and not exists"
		End
		Else Begin
			Set @sOfficeWhere=@sOfficeWhere+char(10)+" and exists"
		End
		
		Set @sOfficeWhere = @sOfficeWhere	+char(10)+"(Select * "  
     							+char(10)+ "from CASES C"
							+char(10)+ "join OFFICE O on (O.OFFICEID = C.OFFICEID)"
							+char(10)+ "where C.CASEID = XW.CASEID"

		If @nRegionKey is not null
		and @nRegionKeyOperator in (0,1)
		Begin
			-- we always check equals because not exists may be set above
			Set @sOfficeWhere = @sOfficeWhere + char(10)+ " and O.REGION"+dbo.fn_ConstructOperator(0,@String,@nRegionKey, null,0)
		End
		Else Begin
			Set @sOfficeWhere = @sOfficeWhere + char(10)+ " and O.REGION is not null"
		End

		Set @sOfficeWhere = @sOfficeWhere + ")"
	End

	If @nBillFrequencyKey is not null
	or @nBillFrequencyKeyOperator between 2 and 6
	Begin 
		-- Save original value of the @nBillFrequencyKeyOperator for use
		-- in the name WIP filtering:
		Set @nOriginalBillFrequencyKeyOperator = @nBillFrequencyKeyOperator

		-- Filtering case WIP:
		-- If Operator is set to IS NULL then use NOT EXISTS
		If @nBillFrequencyKeyOperator in (1,6)			
		Begin  				
			Set @nBillFrequencyKeyOperator = 0				
			
			Set @sCaseWhere=@sCaseWhere+char(10)+"and not exists"
		End
		Else Begin  
			Set @sCaseWhere=@sCaseWhere+char(10)+"and exists"
		End			

		Set @sCaseWhere = @sCaseWhere	+char(10)+"(Select * "  
		     				+char(10)+" from CASENAME CN2"  
						+char(10)+" join IPNAME IP	on (IP.NAMENO = CN2.NAMENO)"
						+char(10)+" where CN2.CASEID = XW.CASEID"					  

		If @bIsRenewalDebtor =  1
		Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and CN2.NAMETYPE = 'Z'"
		End
		Else Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and CN2.NAMETYPE = 'D'"
		End
	
		If @nBillFrequencyKey is not null
		and @nBillFrequencyKeyOperator not in (5,6)
		Begin
			Set 	@sCaseWhere = @sCaseWhere + char(10)+ " and IP.BILLINGFREQUENCY "+dbo.fn_ConstructOperator(@nBillFrequencyKeyOperator,@Numeric,@nBillFrequencyKey, null,0)
		End
		Else Begin
			Set 	@sCaseWhere = @sCaseWhere + char(10)+ " and IP.BILLINGFREQUENCY is not null"
		End

		Set @sCaseWhere = @sCaseWhere	+char(10)+" and (CN2.EXPIRYDATE is NULL or CN2.EXPIRYDATE >getdate())"			
				+char(10)+" and CN2.SEQUENCE in (Select CN3.SEQUENCE from CASENAME CN3"
						+char(10)+"			where CN3.CASEID = CN2.CASEID"
						+char(10)+"			and CN3.NAMETYPE = CN2.NAMETYPE"
						+char(10)+"			and (CN3.EXPIRYDATE is null or CN3.EXPIRYDATE>getdate())))"							

		-- Filtering name WIP:
		Set @sFrom = @sFrom + char(10)+ "left join IPNAME IPN	on (IPN.NAMENO = XW.ACCTCLIENTNO)"

		If @nBillFrequencyKey is not null
		or @nOriginalBillFrequencyKeyOperator between 2 and 6
		Begin
			Set @sAcctClientNoWhere = @sAcctClientNoWhere+char(10)+" and IPN.BILLINGFREQUENCY"+dbo.fn_ConstructOperator(@nOriginalBillFrequencyKeyOperator,@Numeric,@nBillFrequencyKey, null,0)
		End
	End

	If @sCountryKey is not null
	or @nCountryKeyOperator between 2 and 6
	Begin
		-- Filtering case WIP:
		-- If Operator is set to IS NULL then use NOT EXISTS
		If @nCountryKeyOperator in (1,6)			
		Begin
			Set @sCaseWhere=@sCaseWhere+char(10)+"and (not exists"
		End
		Else Begin
			Set @sCaseWhere=@sCaseWhere+char(10)+"and (exists"
		End

		Set @sCaseWhere = @sCaseWhere	+char(10)+"(Select * "  
		     				+char(10)+" from CASENAME CN4"  
						+char(10)+" join NAME N		on (N.NAMENO = CN4.NAMENO)"
						+char(10)+" join ADDRESS A	on (A.ADDRESSCODE = N.POSTALADDRESS)"
						+char(10)+" where CN4.CASEID = XW.CASEID"

		If @bIsRenewalDebtor =  1
		Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and CN4.NAMETYPE = 'Z'"
		End
		Else Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and CN4.NAMETYPE = 'D'"
		End

		If @sCountryKey is not null
		and @nCountryKeyOperator in (0,1)
		Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and A.COUNTRYCODE"+dbo.fn_ConstructOperator(0,@String,@sCountryKey, null,0)
		End
		Else Begin
			Set @sCaseWhere = @sCaseWhere + char(10)+ " and A.COUNTRYCODE is not null"
		End
		
		Set @sCaseWhere = @sCaseWhere	+char(10)+" and (CN4.EXPIRYDATE is NULL or CN4.EXPIRYDATE >getdate())"			
						+char(10)+" and CN4.SEQUENCE in (Select CN3.SEQUENCE from CASENAME CN3"
						+char(10)+"			where CN3.CASEID = CN4.CASEID"
						+char(10)+"			and CN3.NAMETYPE = CN4.NAMETYPE"
						+char(10)+"			and (CN3.EXPIRYDATE is null or CN3.EXPIRYDATE>getdate())))"		

		-- Filtering name WIP address:
		Set @sFrom = @sFrom + char(10)+ "left join NAME NA1	on (NA1.NAMENO = XW.ACCTCLIENTNO)"
				    + char(10)+ "left join ADDRESS A1	on (A1.ADDRESSCODE = NA1.POSTALADDRESS)"
		
		If @sCountryKey is not null
		or @nCountryKeyOperator between 2 and 6
		Begin
			Set @sAcctClientNoWhere = @sAcctClientNoWhere+char(10)+" and A1.COUNTRYCODE"+dbo.fn_ConstructOperator(0,@String,@sCountryKey, null,0)
		End
	
		if (@sStoredProcedure = 'wpw_ListWorkHistory')
		Begin
			-- search the country on debtor-only wip also
			If @nCountryKeyOperator in (1,6)			
			Begin
				Set @sCaseWhere=@sCaseWhere+char(10)+" and not exists"
			End
			Else Begin  
				Set @sCaseWhere=@sCaseWhere+char(10)+" or exists"
			End

			Set @sCaseWhere = @sCaseWhere + char(10) + "(Select * from NAME SN"
							+char(10)+" join ADDRESS SA on (SA.ADDRESSCODE = SN.POSTALADDRESS)"
							+char(10)+" where XW.ACCTCLIENTNO = SN.NAMENO"

			If @sCountryKey is not null
			and @nCountryKeyOperator in (0,1)
			Begin		
				Set @sCaseWhere = @sCaseWhere + char(10)+ " and SA.COUNTRYCODE"+dbo.fn_ConstructOperator(0,@String,@sCountryKey, null,0)
			End
			Else Begin
				Set @sCaseWhere = @sCaseWhere + char(10)+ " and SA.COUNTRYCODE is not null"
			End

			Set @sCaseWhere = @sCaseWhere + ")"
		End

		Set @sCaseWhere = @sCaseWhere + ")"
	End

	-- Return WIP belonging to cases where the name is the instructor and/or the debtor:
	If @nResponsibleNameKey is not null
	Begin	
		If  @bIsInstructor is null
		and @bIsDebtor is null
		Begin
			Set @bIsInstructor = 1
			Set @bIsDebtor = 1
		End
		
		If @bIsInstructor = 1
		and @bIsDebtor = 1
		Begin
			Set @sResponsibleNameTypes = dbo.fn_WrapQuotes('I',0,@pbCalledFromCentura)  
						    + CASE 	WHEN @bIsRenewalDebtor =  1
								THEN ','+dbo.fn_WrapQuotes('Z',0,@pbCalledFromCentura) 
								ELSE ','+dbo.fn_WrapQuotes('D',0,@pbCalledFromCentura)  
						      END	
		End
		Else If @bIsInstructor = 1
		Begin
			Set @sResponsibleNameTypes = dbo.fn_WrapQuotes('I',0,@pbCalledFromCentura)  
		End
		Else If @bIsDebtor = 1
		Begin
			Set @sResponsibleNameTypes =  CASE 	WHEN @bIsRenewalDebtor =  1
								THEN dbo.fn_WrapQuotes('Z',0,@pbCalledFromCentura) 
								ELSE dbo.fn_WrapQuotes('D',0,@pbCalledFromCentura)  
						      END	
		End

		Set @sAcctClientNoWhere = @sAcctClientNoWhere + char(10) + " and XW.ACCTCLIENTNO in ( " + @nResponsibleNameKey  + ")"

                If @bIsSplitMultiDebtor = 1
                Begin   
                        Set @sCaseWhere = @sCaseWhere
				 	+ char(10)+ "and (exists(Select 1 from CASENAME CNR"
					+ char(10)+ "		where CNR.CASEID = XW.CASEID"
					+ char(10)+ "		and CNR.NAMETYPE IN ("+@sResponsibleNameTypes+")"
					+ char(10)+ " 		and CNR.NAMENO in ( " + @nResponsibleNameKey  +")"
					+ char(10)+ " 		and (CNR.EXPIRYDATE is NULL or CNR.EXPIRYDATE >getdate())"	
					+ char(10)+ "		and CNR.SEQUENCE in (Select SEQUENCE from CASENAME CNR2"
					+ char(10)+ "				    where CNR2.CASEID = CNR.CASEID"
					+ char(10)+ "				    and CNR2.NAMETYPE = CNR.NAMETYPE"
					+ char(10)+ "				    and (CNR2.EXPIRYDATE is null or CNR2.EXPIRYDATE>getdate()))"
					+ char(10)+ "		and XW.ACCTCLIENTNO is null)"
					+ char(10)+ "	or (XW.ACCTCLIENTNO in (" + @nResponsibleNameKey  + ")"
					+ char(10)+ " ))"		        
		End
		Else
		Begin
		Set @sCaseWhere = @sCaseWhere
				 	+ char(10)+ "and exists(Select 1 from CASENAME CNR"
					+ char(10)+ "		where CNR.CASEID = XW.CASEID"
					+ char(10)+ "		and CNR.NAMETYPE IN ("+@sResponsibleNameTypes+")"
					+ char(10)+ " 		and CNR.NAMENO in ( " + @nResponsibleNameKey  +")"
					+ char(10)+ " 		and (CNR.EXPIRYDATE is NULL or CNR.EXPIRYDATE >getdate())"	
					+ char(10)+ "		and CNR.SEQUENCE = (Select min(CNR2.SEQUENCE) from CASENAME CNR2"
					+ char(10)+ "				    where CNR2.CASEID = CNR.CASEID"
					+ char(10)+ "				    and CNR2.NAMENO = CNR.NAMENO" 
					+ char(10)+ "				    and CNR2.NAMETYPE = CNR.NAMETYPE"
					+ char(10)+ "				    and (CNR2.EXPIRYDATE is null or CNR2.EXPIRYDATE>getdate())))"
	End
	End

	-- Return only WIP items that are allocated to the selected debtor
	If @nAllocatedDebtorKey is not null
	Begin
		Set @sAcctClientNoWhere = @sAcctClientNoWhere + char(10) + " and XW.ACCTCLIENTNO in ( " + @nAllocatedDebtorKey  + ")"
	End

	-- WIP is returned that matches any of the WIPStatus options
	If  @bIsActiveWIPStatus is null
	and @bIsLockedWIPStatus is null
	Begin
		Set @bIsActiveWIPStatus = 1
		Set @bIsLockedWIPStatus = 1
	End	

	If @bIsActiveWIPStatus = 1 and @bIsLockedWIPStatus = 1
	Begin
		Set @sWIPStatus = '1,2'					    
	End
	Else If @bIsActiveWIPStatus = 1
	Begin
		Set @sWIPStatus = '1'
	End
	Else If @bIsLockedWIPStatus = 1
	Begin
		Set @sWIPStatus = '2'
	End

	If (@bIsWIPSearch = 0)
	Begin
		If (@bIsBilledWIPStatus = 1)
		Begin
			If (@bIsActiveWIPStatus = 0 and @bIsLockedWIPStatus = 0)
			Begin
				-- return only WIP that has been billed
				Set @sWhere = @sWhere+char(10)+" and XWIP.TRANSNO IS NULL"
			End
			Else If (@bIsActiveWIPStatus != 0 or @bIsLockedWIPStatus !=0)
			Begin
				-- Return Billed WIP or unbilled WIP with a particular status
				Set @sWhere = @sWhere+char(10)+" and (XWIP.TRANSNO IS NULL or XWIP.STATUS in ("+@sWIPStatus+"))"
			End
		End
		Else
		Begin
			-- Only return unbilled or partially billed WIP
			Set @sWhere = @sWhere+char(10)+" and XWIP.TRANSNO IS NOT NULL and  XWIP.STATUS in ("+@sWIPStatus+")"
		End

		Set @sWhere = @sWhere+char(10)+" and XW.STATUS in (1,9)"
	End
	Else
	Begin
		Set @sWhere = @sWhere+char(10)+" and XW.STATUS in ("+@sWIPStatus+")"
	End


	If @nCaseKey is not null
	or @nCaseKeyOperator between 2 and 6
	Begin
		Set @sCaseWhere = @sCaseWhere+char(10)+" and XW.CASEID"+dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)
	End

	If @nWipNameKey is not null
	or @nWipNameKeyOperator between 2 and 6
	Begin
		Set @sAcctClientNoWhere = @sAcctClientNoWhere+char(10)+" and XW.ACCTCLIENTNO"+dbo.fn_ConstructOperator(@nWipNameKeyOperator,@Numeric,@nWipNameKey, null,0)
		Set @sCaseWhere = @sCaseWhere+char(10)+" and XW.ACCTCLIENTNO"+dbo.fn_ConstructOperator(@nWipNameKeyOperator,@Numeric,@nWipNameKey, null,0)
	End
	Else if @nCaseKey is not null and ISNULL(@bShowAllocatedDebtorWIP,0) = 0
	Begin
	        Set @sCaseWhere = @sCaseWhere+char(10)+" and XW.ACCTCLIENTNO is null"
	End

	If @sCurrencyCode is not null
	or @nCurrencyCodeOperator between 2 and 6
	Begin
		Set @sFrom = @sFrom + char(10)+ "join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY')"
	
		Set @sWhere = @sWhere+char(10)+" and ISNULL(XW.FOREIGNCURRENCY, SC.COLCHARACTER)"+dbo.fn_ConstructOperator(@nCurrencyCodeOperator,@String,@sCurrencyCode, null,0)
	End

	If  @bIsTotalAgedBalance is not null
	or @nAgedBalanceBracketNumber is not null
	Begin

		If @nAgedBalanceBracketNumber is not null
		Begin
			-- Determine the ageing periods to be used for the aged balance calculations
			exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
								@pnBracket0Days   = @nAge0		OUTPUT,
								@pnBracket1Days   = @nAge1 		OUTPUT,
								@pnBracket2Days   = @nAge2		OUTPUT,
								@pnUserIdentityId = @pnUserIdentityId,
								@psCulture	  = @psCulture

			If @nErrorCode=0
			Begin
				Set @sWhere = @sWhere + CHAR(10)+
					  CASE WHEN @nAgedBalanceBracketNumber = 0 THEN "and datediff(day,XW.TRANSDATE,'"+convert(nvarchar,@dtBaseDate,112)+"') <  "+CAST(@nAge0 as varchar(5))
					       WHEN @nAgedBalanceBracketNumber = 1 THEN "and datediff(day,XW.TRANSDATE,'"+convert(nvarchar,@dtBaseDate,112)+"') between "+CAST(@nAge0 as varchar(5))+" and "+CAST(@nAge1 as varchar(5))+"-1"
					       WHEN @nAgedBalanceBracketNumber = 2 THEN "and datediff(day,XW.TRANSDATE,'"+convert(nvarchar,@dtBaseDate,112)+"') between "+CAST(@nAge1 as varchar(5))+" and "+CAST(@nAge2 as varchar(5))+"-1"	
					       WHEN @nAgedBalanceBracketNumber = 3 THEN "and datediff(day,XW.TRANSDATE,'"+convert(nvarchar,@dtBaseDate,112)+"') >= "+CAST(@nAge2 as varchar(5))	
					  END		
			End
		End
		
		
	End

	-- Construct Work History related filtering
	If  (@dtPostDateOperator is not null)
	and (@dtPostDateFrom is not null
	or   @dtPostDateTo is not null)
	Begin
		Set @sWhere = @sWhere+char(10)+" and XW.POSTDATE "+dbo.fn_ConstructOperator(@dtPostDateOperator,@Date,convert(nvarchar,@dtPostDateFrom,112), convert(nvarchar,@dtPostDateTo,112),0)
	End

	If @nAssociateKey is not null
	or @nAssociateOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+" and XW.ASSOCIATENO "+dbo.fn_ConstructOperator(@nAssociateOperator,@Numeric,@nAssociateKey, null,0)
	End

	If @sSupplierInvoiceNo is not null
	or @nSupplierInvoiceNoOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+" and XW.INVOICENUMBER "+dbo.fn_ConstructOperator(@nSupplierInvoiceNoOperator,@String,@sSupplierInvoiceNo, null,0)
	End

	If @bIsInternalWIP is not null
	Begin
		If (@bIsInternalWIP = 1)
		Begin
			Set @sWhere = @sWhere+char(10)+
					"and exists (Select 1 From CASES"+char(10)+
					"	Where CASETYPE = (select COLCHARACTER from SITECONTROL WHERE CONTROLID = 'Case Type Internal')"+char(10)+
					"	and CASEID = XW.CASEID)"
		End
	End

	-- If all boxes are ticked, don't bother filtering.
	If (@bIsWIPSearch = 0) 
		and 
		(@bIsClassWIP is not null
		or @bIsClassBilling is not null
		or @bIsClassWIPVariation is not null
		or @bIsClassAdjustments is not null)
		and
		(@bIsClassWIP != 1
		or @bIsClassBilling != 1
		or @bIsClassWIPVariation != 1
		or @bIsClassAdjustments != 1)
	Begin
		/*
			Movement classes:
			1 - Generate
			2 - Consume
			3 - Dispose
			9 - Equalise
			4 - Adjust Up
			5 - Adjust Down
		*/
		If (@bIsClassWIP = 1)
		Begin
			Set @sMovementClassList = "1"
			Set @sComma = ","
		End
		If (@bIsClassBilling = 1)
		Begin
			Set @sMovementClassList = @sMovementClassList + @sComma + "2"
			Set @sComma = ","
		End
		If (@bIsClassWIPVariation = 1)
		Begin
			Set @sMovementClassList = @sMovementClassList + @sComma + "3,9"
			Set @sComma = ","
		End
		If (@bIsClassAdjustments = 1)
		Begin
			Set @sMovementClassList = @sMovementClassList + @sComma + "4,5"
		End

		Set @sWhere = @sWhere+char(10)+"and XW.MOVEMENTCLASS in (" + @sMovementClassList + ")"
	End

	If (@bIsServiceFees is not null 
		or @bIsPaidDisbursements is not null
		or @bIsRecoverables is not null)
	and (@bIsServiceFees != 1
		or @bIsPaidDisbursements != 1
		or @bIsRecoverables != 1)
	Begin
		Set @sComma = ""

		If charindex('join WIPTEMPLATE WTMP',@sFrom)=0	
		Begin
			Set @sFrom = @sFrom		+char(10)+"join WIPTEMPLATE WTMP	on (WTMP.WIPCODE = XW.WIPCODE)"
		End
		If charindex('join WIPTYPE WTPE',@sFrom)=0
		Begin
			Set @sFrom = @sFrom		+char(10)+"join WIPTYPE WTPE	on (WTPE.WIPTYPEID = WTMP.WIPTYPEID)"
		End

		If (@bIsServiceFees = 1)
		Begin
			Set @sWIPCategoriesList = "'SC'"
			Set @sComma = ","
		End
		If (@bIsPaidDisbursements = 1)
		Begin
			Set @sWIPCategoriesList = @sWIPCategoriesList + @sComma + "'PD'"
			Set @sComma = ","
		End
		If (@bIsRecoverables = 1)
		Begin
			Set @sWIPCategoriesList = @sWIPCategoriesList + @sComma + "'OR'"
		End

		Set @sWhere = @sWhere+char(10)+"and WTPE.CATEGORYCODE in (" + @sWIPCategoriesList + ")"
	End

	If @nSumLocalBalanceFrom is not NULL
	or @nSumLocalBalanceTo is not NULL
	or @nSumLocalBalanceOperator is not null
	Begin
		Set @sWhere = @sWhere+char(10)+"and	W.BALANCE "+dbo.fn_ConstructOperator(@nSumLocalBalanceOperator,@Numeric,@nSumLocalBalanceFrom, @nSumLocalBalanceTo,@pbCalledFromCentura)
	End
End

-- Assemble the From and Where clause for use in the EXISTS clause.
If @nErrorCode = 0
Begin
	Set @psWIPWhere = ltrim(rtrim(@sFrom+char(10)+@sWhere))
				     -- When CaseKey is supplied then 
				     -- return only case related WIP
			+ char(10) + CASE WHEN @nCaseKey is not null
					  THEN " and (1=1 "
					+ char(10) + replace(@sCaseWhere, 'and XC.CASEID=C.CASEID', 'and XC.CASEID=XW.CASEID')				
					+ char(10) + ")"
					 -- When NameKey is supplied then 
				    	 -- return only name related WIP
					  WHEN @nWipNameKey is not null
					  THEN " and (1=1"
					+ char(10) + @sAcctClientNoWhere + " and XW.CASEID is null)"
		                          ELSE	    CASE WHEN @sCaseWhere is not null 
							  THEN "and (("+CASE 	WHEN @sAcctClientNoWhere is not null 
										THEN "XW.CASEID is null) or (1=1 "
										ELSE " 1=1 "
									END+
							+ char(10) + replace(@sCaseWhere, 'and XC.CASEID=C.CASEID', 'and XC.CASEID=XW.CASEID')				
							+ char(10) + "))"
						     END+ char(10) +
						     CASE WHEN @sAcctClientNoWhere is not null 
							  THEN "and (("+CASE	WHEN @sCaseWhere is not null
										THEN "XW.ACCTCLIENTNO is null) or (" + char(10)+"1=1 "
										ELSE " 1=1 "
									END
							+ char(10) + @sAcctClientNoWhere + "))"
						     END
				     END
			+ char(10) + CASE WHEN @sOfficeWhere is not null
					  THEN @sOfficeWhere
				     END

End

RETURN @nErrorCode
GO

Grant execute on dbo.wp_ConstructWipWhere  to public
GO

