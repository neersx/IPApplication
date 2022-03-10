-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_ListDocketingWizardData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_ListDocketingWizardData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_ListDocketingWizardData.'
	Drop procedure [dbo].[dw_ListDocketingWizardData]
End
Print '**** Creating Stored Procedure dbo.dw_ListDocketingWizardData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dw_ListDocketingWizardData
(
	@pnRowCount		int output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,  
	@pnCaseKey		int,
	@pbCalledFromCentura	bit 		= 0
)
as
-- PROCEDURE:	dw_ListDocketingWizardData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns resultsets suitable for DocketingWizardData dataset.
--				Contains CaseSummary, CaseName, Critical Dates(editable) and original resultset from dw_ListCaseEventAlert

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 DEC 2007	SF	RFC5708	1	Procedure created
-- 26 MAR 2008 	SF	RFC5790	2	Return renewal instruction in the culture specified.
-- 30 Jan 2009	SF	RFC6693	3	Implement IsGlobalNameChangeOutstanding
-- 07 Nov 2011  DV      R11439  4       Modify the join for Valid Property, Category, Basis and Sub Type 
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare @bExternalUser		bit

-- Initialise variables
Set     @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)



If  @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser		bit	Output,
				  @pnUserIdentityId		int',
				  @bExternalUser=@bExternalUser	Output,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- not for external users.
If @nErrorCode = 0
and @bExternalUser = 1
Begin 
	Set @nErrorCode = -1
End

-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.IRN 		as CaseReference,"+char(10)+
	"	CASE 	WHEN POL.CASEID is not null"+char(10)+
	"		THEN cast(1 as bit)"+char(10)+
	"		ELSE cast(0 as bit)"+char(10)+
	"	END		as IsPolicingOutstanding,"+char(10)+
	"	CASE 	WHEN GNC.CASEID is not null"+char(10)+
	"		THEN cast(1 as bit)"+char(10)+
	"		ELSE cast(0 as bit)"+char(10)+
	"	END		as IsGlobalNameChangeOutstanding,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+" as CaseStatusDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+" as RenewalStatusDescription,"+char(10)+	
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
	"CASE WHEN VP.PROPERTYTYPE is null THEN NULL ELSE "+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" END as CaseCategoryDescription,"+char(10)+
	"CASE WHEN (VC.CASECATEGORY is null or VP.PROPERTYTYPE is null) THEN NULL ELSE "+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+" END as SubTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+" as ApplicationBasisDescription,"+char(10)+
	CASE WHEN @bExternalUser = 0 THEN +dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TF',@sLookupCulture,@pbCalledFromCentura)+" as FileLocation,"+char(10)+
							    dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura)+" as CaseOffice,"+char(10)
	END+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)+" as RenewalInstruction"+char(10)+
	"from CASES C"+char(10)+	
	"join COUNTRY CT 		on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"				and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)"+char(10)+
	"							from VALIDPROPERTY VP1"+char(10)+
	"							where VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join PROPERTY P 		on (P.CASEID=C.CASEID)"+char(10)+
	"left join STATUS RS 		on (RS.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"left join STATUS ST 		on (ST.STATUSCODE=C.STATUSCODE)"+char(10)+
	"left join VALIDCATEGORY VC 	on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"				and VC.CASETYPE=C.CASETYPE"+char(10)+
	"				and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"				and VC.COUNTRYCODE=(	select min(VC1.COUNTRYCODE)"+char(10)+
	"							from VALIDCATEGORY VC1"+char(10)+
	"							where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VC1.CASETYPE=C.CASETYPE"+char(10)+
	"							and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join VALIDBASIS VB	on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
					"and VB.BASIS        = P.BASIS"+char(10)+
					"and VB.COUNTRYCODE  = (	select min(VB1.COUNTRYCODE)"+char(10)+
								"from VALIDBASIS VB1"+char(10)+
								"where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
		                     	                        "and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	"left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
									   "and VS.CASETYPE     = C.CASETYPE"+char(10)+
									   "and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
									   "and VS.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     			   "and VS.COUNTRYCODE  = (select min(VS1.COUNTRYCODE)"+char(10)+
	                     									  "from VALIDSUBTYPE VS1"+char(10)+
	                     	               					  "where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  					  "and   VS1.CASETYPE     = C.CASETYPE"+char(10)+
	                     									  "and   VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	
	"left join TABLECODES TF 	on TF.TABLECODE=(	Select CL.FILELOCATION"+char(10)+	
	"							from CASELOCATION CL"+char(10)+	
	"							where CL.CASEID=C.CASEID"+char(10)+	
	"				and CL.WHENMOVED=(	select max(CL.WHENMOVED)"+char(10)+	
	"							from CASELOCATION CL"+char(10)+	
	"							where CL.CASEID=C.CASEID))"+char(10)+		
	"left join OFFICE OFC		on (OFC.OFFICEID=C.OFFICEID)"+char(10)+
	"left join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction (@pnCaseKey, 'R'))"+char(10)+
	-- IsPolicingOutstanding is true if there is a row in 
	-- the POLICING table for the CaseKey where SYSGENERATEDFLAG = 1:
	"left join (	Select distinct P2.CASEID"+char(10)+
	"	      	from POLICING P2"+char(10)+
	"		where P2.CASEID = @pnCaseKey"+char(10)+
	"		and   P2.SYSGENERATEDFLAG = 1) POL"+char(10)+
	"				on (POL.CASEID = C.CASEID)"+char(10)+
	-- IsGlobalNameChangeOutstanding is true if there is a row in 
	-- the CASENAMEREQUESTCASES table for the CaseKey
	"left join ( Select distinct CNREQ.CASEID"+char(10)+
	"			from CASENAMEREQUESTCASES CNREQ	"+char(10)+
	"			where CNREQ.CASEID      = @pnCaseKey) GNC "+char(10)+
	"				on (GNC.CASEID = C.CASEID)"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
						@pbCalledFromCentura	bit,
					@sLookupCulture			nvarchar(10)',
					  @pnCaseKey		 	= @pnCaseKey,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@sLookupCulture			= @sLookupCulture
End

-- CaseName result set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	CN.CASEID		as CaseKey,
		CN.NAMETYPE		as NameTypeKey,
		CN.NAMENO 		as NameKey,
		CN.SEQUENCE		as NameSequence,
		NT.DESCRIPTION		as NameTypeDescription,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as Name,
		N.NAMECODE	as NameCode,
		convert(nvarchar(11),CN.CASEID)+'^'+
		CN.NAMETYPE+'^'+
		convert(nvarchar(11),CN.NAMENO)+'^'+
		convert(nvarchar(11),CN.SEQUENCE) as RowKey
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,0,@pbCalledFromCentura) NT 
					on (NT.NAMETYPE = CN.NAMETYPE)
	join NAME N			on (N.NAMENO = CN.NAMENO)		
	where CN.CASEID = @pnCaseKey"+char(10)+
	"and CN.NAMETYPE in ('I', 'A', 'O', 'SIG', 'EMP')
	order by CASE	CN.NAMETYPE 			/* strictly only for orderby, not needed by CASEDATA */
			WHEN	'I'	THEN 0		/* Instructor */
			WHEN 	'A'	THEN 1		/* Agent */
			WHEN 	'O'	THEN 2		/* Owner */
			WHEN	'EMP'	THEN 3		/* Responsible Staff */
			WHEN	'SIG'	THEN 4		/* Signotory */
			ELSE 5				/* others, order by description and sequence */
		 END,
		NameSequence"	
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura
End


-- Critical Dates result set
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.cs_ListCriticalDates
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= @bExternalUser,
		@psCulture		= @psCulture,
		@pnCaseKey		= @pnCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura
End


-- DocketData Dates result set
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.dw_ListCaseEventAlert
		@pnRowCount			= @pnRowCount output,
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseId		= @pnCaseKey,
		@pbCalledByCentura	= @pbCalledFromCentura
End

Return @nErrorCode
GO

Grant execute on dbo.dw_ListDocketingWizardData to public
GO
