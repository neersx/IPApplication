-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCase.'
	Drop procedure [dbo].[csw_FetchCase]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

Create PROCEDURE [dbo].[csw_FetchCase]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura	        bit		= 0,
	@pnCaseKey			int		= null,	-- The key of the case to be returned. Optional for a new case.
	@psCaseTypeCode			nchar(1)	= null,	-- The identifying code for the type of case. 
	@psPropertyTypeCode		nchar(1)	= null,	-- The identifying code for the property type of case. 
	@psLogicalProgramId		nvarchar(16) = null, -- The logical case program id
	@pbNewRow			bit		= 0	-- Indicates whether a template row containing default data is required.
)
as
-- PROCEDURE:	csw_FetchCase
-- VERSION:	31
-- DESCRIPTION:	Lists all modifiable columns from the Cases table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 23 Nov 2005	TM	RFC3200	2	Update stored procedure accordingly to the Case.doc
-- 09 Dec 2005	TM	RFC3200	3	Add new @pnNewRow parameter.
-- 09 Mar 2006	TM	RFC3651	4	Cast an integer variable or column as nvarchar(20) before comparing it to 
--					the TABLEATTRIBUTES.GENERICKEY column.
-- 27 Apr 2006	AU	RFC3791	5	Return IPOfficeDelay, ApplicantDelay, and IPOfficeAdjustment
-- 08 May 2006	SW	RFC3301	6	Add ScreenCriteriaKey
-- 12 May 2006	SW	RFC3301	7	Pass SITECONTROL to fn_GetCriteriaNo for ScreenCriteriaKey
-- 29 Sep 2006	SF	RFC3248	8	Return CreateReferenceOption and Stem. CreateReferenceOption determines by SiteControl.
-- 28 Nov 2007	AT	RFC3208	9	Return LocalClasses and IntClasses.
-- 19/03/2008	vql	SQA14773 10      Make PurchaseOrderNo nvarchar(80)
-- 18 Jul 2008	AT	RFC5749	11	Return screen criteria for CRM cases
-- 19 Aug 2008	AT	RFC6859	12	Return Case Profit Centre.
-- 27 Aug 2008	AT	RFC5712	13	Return Budget Amounts.
-- 23 Sep 2008	As	RFC6445 14	Add New Parameters for TypesOfMark ans Series.
-- 11 Dec 2008	MF	17136	15	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 09 Jan 2009	JC	RFC7362 16	Change PURPOSECODE for fn_GetCriteriaNo from 'S' to 'W'
-- 09 Jan 2009	JC	RFC7209 17	Return ScreenCriteriaKey for new Case
-- 19 Mar 2009	MS	RFC7732 18	Added CountryCodeField with value CountryCode in the result set.
-- 15 Apr 2009	JC	RFC7362 19	Added PropertyTypeCode as a new parameter for New Case
-- 14 Sep 2009  LP      RFC8047 20      Pass null as ProfileKey parameter for fn_GetCriteriaNo
-- 06 Jan 2010	KR	RFC8171 21	Pass LogicalProgramId as parameter so that it fetches the correct screen criteria key
-- 20 Oct 2011  DV      R11439  22      Modify the join for Valid Property, Category, Basis and Sub Type 
-- 24 Oct 2011	ASH	R11460 23	Cast integer column CaseId to nvarchar(11) data type.
-- 01 Dec 2011  ASH     R11597  24      Add default country ZZZ in case when Case Category does not exists in VALIDCATEGORY table for selected country for the Case. 
-- 15 Dec 2011	LP	R11711	25	ValidProperty and ValidCategory should fall-back to Default Country if not available for the
--					Country of the specific case.
-- 28 Apr 2012	SF	R11381	26	Return RenewalStatusKey and Description
-- 12-Jun-2012	LP	R12398	27	Consider CASECATEGORY when determining which VALIDSUBTYPE rule to use.
-- 15-May-2013	SF	R13490	28	4000 characters not enough when translation is turned on.
-- 11-Apr-2014  MS	R31303  29	Return LastModifiedDate for concurrency check
-- 13 Mar 2019	DV	DR44187	30	Set the default value for LOCALCLIENTFLAG.
-- 03 Sep 2019	vql	DR44472	31	When OfficeGetFromUser Site Control is set to False, it should not be populating Office for Staff Member.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture	nvarchar(10)
Declare @bExternalUser	bit

Declare @sSubType			nvarchar(4)
Declare @sSubTypeDescription 		nvarchar(50) 
Declare @sApplicationBasisDescription 	nvarchar(50)
Declare @sPurchaseOrderNo	 	nvarchar(80)
Declare @sTaxTreatment		 	nvarchar(30)
Declare @sApplicationBasisCode		nvarchar(2)

Declare @sFileCoverIRN			nvarchar(30)
Declare @sPredecessorIRN		nvarchar(30)
Declare @sEntitySizeDescription		nvarchar(80)
Declare @nNoOfClaims			smallint
Declare @sCaseStatusDescription		nvarchar(50)
Declare @sRenewalStatusDescription	nvarchar(50)
Declare @sCaseOffice			nvarchar(80)
Declare @bIsCRM				bit

Declare	@sProgramKey 		nvarchar(8)
Declare @bIsCRMCaseType		bit
Declare @nNewCaseCriteriaNo	int
Declare @bIsPropertyTypeUnknown	bit

Declare @nProfileKey            int
Declare @sDefaultProgram        nvarchar(508)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bExternalUser 	= 0
Set @bIsCRMCaseType	= 0
Set @bIsPropertyTypeUnknown = 1

-- Determine if the user is internal or external
If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser	= @bExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Get the ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @nErrorCode = @@ERROR
End
-- Get the Default Name Program of the user's profile
If @nErrorCode = 0
and @nProfileKey is not null
and (@psLogicalProgramId is null or @psLogicalProgramId = '')
Begin
        Select @sDefaultProgram = P.ATTRIBUTEVALUE
        from PROFILEATTRIBUTES P
        where P.PROFILEID = @nProfileKey
        and P.ATTRIBUTEID = 2 -- Default Case Program

        Set @nErrorCode = @@ERROR
End
Else If @psLogicalProgramId is not null
and @psLogicalProgramId <> ''
Begin
	Set @sDefaultProgram = @psLogicalProgramId
End
-- Retrieve some of the columns for the Case result set and store them
-- into variables. The values stored in the variables are then used 
-- to populate the Case table 

-- Existing Case
If  @nErrorCode = 0
and @pbNewRow = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"@sSubType = VS.SUBTYPE," +char(10)+
	"@sSubTypeDescription = "+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sApplicationBasisCode = VB.BASIS,"+char(10)+
	"@sApplicationBasisDescription 	= "+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sPurchaseOrderNo = C.PURCHASEORDERNO,"+char(10)+
	"@sTaxTreatment = TR.DESCRIPTION,"+char(10)+
	"@sFileCoverIRN	= C2.IRN,"+char(10)+
	"@sPredecessorIRN = C3.IRN,"+char(10)+
	"@sEntitySizeDescription = "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@nNoOfClaims = P.NOOFCLAIMS,"+char(10)+
	"@sCaseStatusDescription = "+CASE 	WHEN @bExternalUser = 0 
						THEN +dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
						ELSE dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
					END+","+char(10)+
	"@sRenewalStatusDescription = "+CASE 	WHEN @bExternalUser = 0 
						THEN +dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RST',@sLookupCulture,@pbCalledFromCentura)
						ELSE dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RST',@sLookupCulture,@pbCalledFromCentura)
					END+","+char(10)+					
	"@sCaseOffice = "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	", @bIsCRM = isnull(CT.CRMONLY,0)"+char(10)+
	
	"from CASES C"+char(10)+ 	
	"left join PROPERTY P		on (P.CASEID = C.CASEID)"+char(10)+
	"left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                               "and VS.CASETYPE     = C.CASETYPE"+char(10)+
	                               "and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                               "and VS.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     	       "and VS.COUNTRYCODE  = (select min(VS1.COUNTRYCODE)"+char(10)+
	                     	                              "from VALIDSUBTYPE VS1"+char(10)+
	                     	               	              "where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  	              "and   VS1.CASETYPE     = C.CASETYPE"+char(10)+
	                                  	              "and   VS1.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                     	                              "and   VS1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join VALIDBASIS VB		on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                         	       "and VB.BASIS        = P.BASIS"+char(10)+
	                    		       "and VB.COUNTRYCODE  = (select min(VB1.COUNTRYCODE)"+char(10)+
		                     	                              "from VALIDBASIS VB1"+char(10)+
		                     	                              "where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
		                     	                              "and   VB1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join TAXRATES TR		on (C.TAXCODE = TR.TAXCODE)"+char(10)+
	"left join CASES C2 		on (C2.CASEID=C.FILECOVER)"+char(10)+
	"left join CASES C3 		on (C3.CASEID=C.PREDECESSORID)"+char(10)+
	"left join TABLECODES TC2 	on (TC2.TABLECODE=C.ENTITYSIZE)"+char(10)+
	"left join STATUS ST 		on (ST.STATUSCODE=C.STATUSCODE)"+char(10)+
	"left join STATUS RST		on (RST.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"left join OFFICE OFC		on (OFC.OFFICEID=C.OFFICEID)"+char(10)+
	"left join CASETYPE CT		on (CT.CASETYPE=C.CASETYPE)"+char(10)+
	"where C.CASEID = @pnCaseKey" 

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @pnUserIdentityId		int,									 
					  @sSubTypeDescription	 	nvarchar(50)		  OUTPUT,
					  @sApplicationBasisDescription nvarchar(50)	  	  OUTPUT,
					  @sPurchaseOrderNo		nvarchar(80)		  OUTPUT,
					  @sTaxTreatment		nvarchar(30)		  OUTPUT,
					  @sFileCoverIRN		nvarchar(30)		  OUTPUT,
					  @sPredecessorIRN		nvarchar(30)		  OUTPUT,
					  @sEntitySizeDescription	nvarchar(80)		  OUTPUT,
					  @nNoOfClaims			smallint		  OUTPUT,
					  @sCaseStatusDescription	nvarchar(50)		  OUTPUT,
					  @sRenewalStatusDescription	nvarchar(50)		  OUTPUT,
					  @sCaseOffice			nvarchar(80)		  OUTPUT,
					  @sApplicationBasisCode	nvarchar(2)		  OUTPUT,
					  @bIsCRM			bit			  OUTPUT,
					  @sSubType			nvarchar(4)		  OUTPUT',
					  @pnCaseKey		 	= @pnCaseKey,
					  @pnUserIdentityId		= @pnUserIdentityId,					  
					  @sSubTypeDescription		= @sSubTypeDescription	  OUTPUT,
					  @sApplicationBasisDescription	= @sApplicationBasisDescription 	OUTPUT,
					  @sPurchaseOrderNo		= @sPurchaseOrderNo	  OUTPUT,
					  @sTaxTreatment		= @sTaxTreatment	  OUTPUT,
					  @sFileCoverIRN		= @sFileCoverIRN	  OUTPUT,
					  @sPredecessorIRN		= @sPredecessorIRN	  OUTPUT,
					  @sEntitySizeDescription	= @sEntitySizeDescription OUTPUT,
					  @nNoOfClaims			= @nNoOfClaims		  OUTPUT,
					  @sCaseStatusDescription	= @sCaseStatusDescription OUTPUT,
					  @sRenewalStatusDescription	= @sRenewalStatusDescription OUTPUT,
				          @sCaseOffice			= @sCaseOffice		  OUTPUT,
				   	  @sApplicationBasisCode	= @sApplicationBasisCode  OUTPUT,
					  @bIsCRM 			= @bIsCRM		  OUTPUT,
					  @sSubType			= @sSubType		  OUTPUT
					

	-- Case result set
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
		"Select"+char(10)+
		"cast(C.CASEID as nvarchar(11)) as RowKey,"+char(10)+					
		"C.CASEID as CaseKey,"+char(10)+
		"C.IRN as CaseReference,"+char(10)+
		"C.FAMILY as CaseFamilyReference,"+char(10)+
		dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as CaseFamilyTitle,"+char(10)+
		"C.STATUSCODE as CaseStatusKey,"+char(10)+
		"@sCaseStatusDescription as CaseStatusDescription,"+char(10)+
		"P.RENEWALSTATUS as RenewalStatusKey,"+char(10)+
		"@sRenewalStatusDescription as RenewalStatusDescription,"+char(10)+
		"C.CASETYPE as CaseTypeCode,"+char(10)+
		dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
		"VP.PROPERTYTYPE as PropertyTypeCode,"+char(10)+
		dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
		"C.COUNTRYCODE as CountryCode,"+char(10)+
		dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
		"C.COUNTRYCODE as CountryCodeField,"+char(10)+
		"CASE WHEN VP.PROPERTYTYPE is null THEN null ELSE VC.CASECATEGORY END as CaseCategoryCode,"+char(10)+
		"CASE WHEN VP.PROPERTYTYPE is null THEN null ELSE "+char(10)+
		dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" END as CaseCategoryDescription,"+char(10)+
		"CASE WHEN (VC.CASECATEGORY is null or VP.PROPERTYTYPE is null)  THEN null ELSE @sSubType END as SubTypeCode,"+char(10)+
		"CASE WHEN (VC.CASECATEGORY is null or VP.PROPERTYTYPE is null) THEN null ELSE @sSubTypeDescription END as SubTypeDescription,"+char(10)+
		"@sApplicationBasisCode as ApplicationBasisCode,"+char(10)+
		"@sApplicationBasisDescription as ApplicationBasisDescription,"+char(10)+	
		dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
		"ISNULL(C.LOCALCLIENTFLAG,0) as IsLocalClient,"+char(10)+
		"C.ENTITYSIZE as EntitySizeKey,"+char(10)+
		"@sEntitySizeDescription as EntitySizeDescription,"+char(10)+
		"C.PREDECESSORID as PredecessorCaseKey,"+char(10)+
		"@sPredecessorIRN as PredecessorCaseReference,"+char(10)+
		"C.FILECOVER as FileCoverCaseKey,"+char(10)+
		"@sFileCoverIRN as FileCoverCaseReference,"+char(10)+
		"@sPurchaseOrderNo as PurchaseOrderNo,"+char(10)+
		"C.CURRENTOFFICIALNO as CurrentOfficialNumber,"+char(10)+	
		"C.TAXCODE as TaxRateCode,"+char(10)+
		"@sTaxTreatment as TaxRateDescription,"+char(10)+
		"C.OFFICEID as CaseOfficeKey,"+char(10)+
		"@sCaseOffice as CaseOfficeDescription,"+char(10)+
		"@nNoOfClaims as NoOfClaims,"+char(10)+
		"C.IPODELAY as IPOfficeDelay,"+char(10)+
		"C.APPLICANTDELAY as ApplicantDelay,"+char(10)+
		"C.IPOPTA as IPOfficeAdjustment,"+char(10)+
		"dbo.fn_GetCriteriaNo(@pnCaseKey, 'W', case when CS.CRMONLY=1 then SCRM.COLCHARACTER else ISNULL(@sDefaultProgram,SC.COLCHARACTER) end, null, @nProfileKey) as ScreenCriteriaKey,"+char(10)+
		"CASE WHEN SCTEMPIR.COLBOOLEAN=1 THEN 'T'"+char(10)+
		"     WHEN SCGENIR.COLBOOLEAN=1 THEN 'G'"+char(10)+
		"     ELSE 'E' END as CreateReferenceOption,"+char(10)+
		"C.STEM as Stem,"+char(10)+
		"C.LOCALCLASSES as LocalClasses,"+char(10)+
		"C.INTCLASSES as IntClasses,"+char(10)+
		"C.PROFITCENTRECODE as ProfitCentreKey,"+char(10)+
		"PC.DESCRIPTION as ProfitCentreDescription,"+char(10)+
		"C.BUDGETAMOUNT as BudgetAmount,"+char(10)+
		"C.BUDGETREVISEDAMT as BudgetRevisedAmt,"+char(10)+
		"@bIsCRM	as IsCRM,"+char(10)+

		" C.TYPEOFMARK as TypeOfMarkKey,"+char(10)+
		" cast(C.NOINSERIES as smallint) as  NoInSeries, "+char(10)+
		"C.LOGDATETIMESTAMP as LastModifiedDate"+char(10)+
		"from CASES C"+char(10)+	
		"join CASETYPE CS 		on (CS.CASETYPE=C.CASETYPE)"+char(10)+
		"join COUNTRY CT 		on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
		"left join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
		"				and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)"+char(10)+
		"							from VALIDPROPERTY VP1"+char(10)+
		"							where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
		"							and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+	
		"left join VALIDCATEGORY VC 	on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
		"				and VC.CASETYPE=C.CASETYPE"+char(10)+
		"				and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
		"				and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
		"						    from VALIDCATEGORY VC1"+char(10)+
		"						    where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
		"						    and VC1.CASETYPE=C.CASETYPE"+char(10)+
		"						    and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
		"						    and VC1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
		"left join CASEFAMILY CF on (CF.FAMILY=C.FAMILY)"+char(10)+	
		"left join PROFITCENTRE PC 	on (PC.PROFITCENTRECODE=C.PROFITCENTRECODE)"+char(10)+
		"left join TABLECODES TM on (TM.TABLECODE=C.TYPEOFMARK)"+char(10)+
		"left join PROPERTY P on (P.CASEID = C.CASEID)"+char(10)+
		"left join SITECONTROL SC on (SC.CONTROLID = 'Case Screen Default Program')"+char(10)+
		"left join SITECONTROL SCTEMPIR on (SCTEMPIR.CONTROLID = 'Temporary IR')"+char(10)+
		"left join SITECONTROL SCGENIR  on (SCGENIR.CONTROLID = 'Generate IR')"+char(10)+
		"left join SITECONTROL SCRM on (SCRM.CONTROLID = 'CRM Screen Control Program')"+char(10)+
		"Where C.CASEID = @pnCaseKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCaseKey		 	int,					  	 	
						  @sSubTypeDescription	 	nvarchar(50),
						  @sApplicationBasisDescription nvarchar(50),
						  @sApplicationBasisCode	nvarchar(2),
						  @sPurchaseOrderNo		nvarchar(80),
						  @sTaxTreatment		nvarchar(30),
						  @sFileCoverIRN		nvarchar(30),
						  @sPredecessorIRN		nvarchar(30),
						  @sEntitySizeDescription	nvarchar(80),
						  @nNoOfClaims			smallint,
						  @sCaseStatusDescription	nvarchar(50),
						  @sRenewalStatusDescription	nvarchar(50),
						  @sCaseOffice			nvarchar(80),
						  @bIsCRM			bit,
						  @nProfileKey                  int,
						  @sDefaultProgram              nvarchar(508),
						  @sSubType			nvarchar(4)',
						  @pnCaseKey		 	= @pnCaseKey,					  					 
						  @sSubTypeDescription		= @sSubTypeDescription,
						  @sApplicationBasisDescription	= @sApplicationBasisDescription,
						  @sApplicationBasisCode	= @sApplicationBasisCode,
						  @sPurchaseOrderNo		= @sPurchaseOrderNo,
						  @sTaxTreatment		= @sTaxTreatment,
						  @sFileCoverIRN		= @sFileCoverIRN,
						  @sPredecessorIRN		= @sPredecessorIRN,
						  @sEntitySizeDescription	= @sEntitySizeDescription,
						  @nNoOfClaims			= @nNoOfClaims,
						  @sCaseStatusDescription	= @sCaseStatusDescription,
						  @sRenewalStatusDescription	= @sRenewalStatusDescription,
						  @sCaseOffice			= @sCaseOffice,
						  @bIsCRM			= @bIsCRM,
						  @nProfileKey                  = @nProfileKey,
						  @sDefaultProgram              = @sDefaultProgram,
						  @sSubType			= @sSubType
						
	End
End
-- New Case
Else If  @nErrorCode = 0
     and @pbNewRow = 1
Begin

	-- Get the appropriate program key
	If @nErrorCode = 0
	Begin
		Select @bIsCRMCaseType = isnull(CRMONLY,0)
		from CASETYPE 
		WHERE CASETYPE = @psCaseTypeCode

		Set @nErrorCode=@@ERROR
	End

	If @nErrorCode = 0
	Begin
		If @bIsCRMCaseType = 0
		Begin
			If @psLogicalProgramId is null
				Select 	@sProgramKey = ISNULL(@sDefaultProgram,COLCHARACTER) -- Default to User Profile
				from 	SITECONTROL 
				where 	CONTROLID = 'Case Screen Default Program'
			else
				set @sProgramKey = @psLogicalProgramId
		End
		Else
		Begin
				Select 	@sProgramKey = COLCHARACTER 
				from 	SITECONTROL 
				where 	CONTROLID = 'CRM Screen Control Program'				
		End
		Set @nErrorCode=@@ERROR
	End
	

	If @nErrorCode = 0
	Begin
		If @psPropertyTypeCode IS NOT NULL
		Begin
			set @bIsPropertyTypeUnknown = 0
		End
		Select top 1 @nNewCaseCriteriaNo=CRITERIANO
			from dbo.fn_GetCriteriaRows ( 'W',NULL,@psCaseTypeCode,NULL,NULL,@sProgramKey,NULL,@psPropertyTypeCode,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,null,1,@bIsPropertyTypeUnknown,1,1,1,NULL,NULL,NULL,NULL,
							null,		-- @pnRuleType		--SQA12298
							null,		-- @psRequestType	--SQA12298
							null,		-- @pnDataSourceType	--SQA12298
							null,		-- @pnDataSourceNameNo	--SQA12298
							null,		-- @pnRenewalStatus	--SQA12298
							null,		-- @pnStatusCode	--SQA12298,
							0,
							null            -- @pnProfileKey
						        )
			order by BESTFIT desc

		Set @nErrorCode=@@ERROR	
	End

	-- Case result set
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
			"Select"+char(10)+
			"NULL as RowKey,"+char(10)+					
			"NULL as CaseKey,"+char(10)+
			"NULL as CaseReference,"+char(10)+
			"NULL as CaseFamilyReference,"+char(10)+
			"NULL as CaseFamilyTitle,"+char(10)+
			"@nNewCaseCriteriaNo as ScreenCriteriaKey,"+char(10)+
			"NULL as CaseStatusKey,"+char(10)+
			"NULL as CaseStatusDescription,"+char(10)+
			"NULL as RenewalStatusKey,"+char(10)+
			"NULL as RenewalStatusDescription,"+char(10)+
			"@psCaseTypeCode as CaseTypeCode,"+char(10)+
			dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
			"NULL as PropertyTypeCode,"+char(10)+
			"NULL as PropertyTypeDescription,"+char(10)+
			"NULL as CountryCode,"+char(10)+
			"NULL as CountryName,"+char(10)+
			"NULL as CountryCodeField,"+char(10)+
			"NULL as CaseCategoryCode,"+char(10)+
			"NULL as CaseCategoryDescription,"+char(10)+
			"NULL as SubTypeCode,"+char(10)+
			"NULL as SubTypeDescription,"+char(10)+
			"NULL as ApplicationBasisCode,"+char(10)+
			"NULL as ApplicationBasisDescription,"+char(10)+	
			"NULL as Title,"+char(10)+
			"NULL as IsLocalClient,"+char(10)+
			"NULL as EntitySizeKey,"+char(10)+
			"NULL as EntitySizeDescription,"+char(10)+
			"NULL as PredecessorCaseKey,"+char(10)+
			"NULL as PredecessorCaseReference,"+char(10)+
			"NULL as FileCoverCaseKey,"+char(10)+
			"NULL as FileCoverCaseReference,"+char(10)+
			"NULL as PurchaseOrderNo,"+char(10)+
			"NULL as CurrentOfficialNumber,"+char(10)+	
			"NULL as TaxRateCode,"+char(10)+
			"NULL as TaxRateDescription,"+char(10)+
			"TA.TABLECODE as CaseOfficeKey,"+char(10)+
			dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura)+" as CaseOfficeDescription,"+char(10)+
			"NULL as NoOfClaims,"+char(10)+
			-- Applies for new cases only.
			"NULL as InstructionsReceivedDate,"+char(10)+
			"NULL as IPOfficeDelay,"+char(10)+
			"NULL as ApplicantDelay,"+char(10)+
			"NULL as IPOfficeAdjustment,"+char(10)+
			"CASE WHEN SCTEMPIR.COLBOOLEAN=1 THEN 'T'"+char(10)+
			"     WHEN SCGENIR.COLBOOLEAN=1 THEN 'G'"+char(10)+
			"     ELSE 'E' END as CreateReferenceOption,"+char(10)+
			"NULL as Stem,"+char(10)+
			"NULL as LocalClasses,"+char(10)+
			"NULL as IntClasses,"+char(10)+
			"NULL as BudgetAmount,"+char(10)+
			"NULL as BudgetRevisedAmt,"+char(10)+
			"CS.CRMONLY as IsCRM,"+char(10)+
			"NULL as TypeOfMarkKey,"+char(10)+
			"NULL as NoInSeries,"+char(10)+
			"NULL as LastModifiedDate"+char(10)+
			"from CASETYPE CS"+char(10)+
			"join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)"+char(10)+
			"left join SITECONTROL SC1 on (SC1.CONTROLID = 'OfficeGetFromUser')"+char(10)+
			"left join TABLEATTRIBUTES TA	on (SC1.COLBOOLEAN = 1
							and TA.PARENTTABLE = 'NAME'"+char(10)+
			"				and TA.GENERICKEY = cast(UI.NAMENO as nvarchar(20))"+char(10)+
			"				and TA.TABLETYPE = 44"+char(10)+
			"				and TA.TABLECODE = (	Select min(TA2.TABLECODE)"+char(10)+
			"							from  TABLEATTRIBUTES TA2"+char(10)+
			"							where TA2.PARENTTABLE = TA.PARENTTABLE"+char(10)+
			"							and   TA2.GENERICKEY = TA.GENERICKEY"+char(10)+
			"							and   TA2.TABLETYPE = TA.TABLETYPE))"+char(10)+
			"left join OFFICE OFC		on (OFC.OFFICEID = TA.TABLECODE)"+char(10)+
			"left join SITECONTROL SCTEMPIR on (SCTEMPIR.CONTROLID = 'Temporary IR')"+char(10)+
			"left join SITECONTROL SCGENIR on (SCGENIR.CONTROLID = 'Generate IR')"+char(10)+
			"where CS.CASETYPE = @psCaseTypeCode"		

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnCaseKey		int,
							  @psCaseTypeCode	nchar(1),
							  @nNewCaseCriteriaNo	int,
							  @pnUserIdentityId	int',
							  @pnCaseKey		= @pnCaseKey,
							  @psCaseTypeCode	= @psCaseTypeCode,
							  @nNewCaseCriteriaNo = @nNewCaseCriteriaNo,
							  @pnUserIdentityId	= @pnUserIdentityId
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCase to public
GO