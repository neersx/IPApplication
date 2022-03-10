-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseSummary.'
	Drop procedure [dbo].[csw_ListCaseSummary]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseSummary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@pbCalledFromCentura	bit 		= 0
)
AS 
-- PROCEDURE:	csw_ListCaseSummary
-- VERSION:	9
-- DESCRIPTION:	Populates the CaseSummaryInternalData result set.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Aug 2005  TM	R2880	1	Procedure created based on the V5 of the csw_ListCaseSummaryInternal.
-- 24 Mar 2006	SF	R3264	2	Add RowKey to Case Name result set.
-- 19 Feb 2007	SF	R5012	3	Add NameCode to Name, Add RenewalInstruction and SubType to Case
-- 26 MAR 2008 	SF	R5790	4	Return renewal instruction in the culture specified.
-- 22 Jul 2008	AT	R5788	5	Return IsCRM flag.
-- 11 Dec 2008	MF	R17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Jan 2014	MF	R29971	7	Return the principal staff member associated with the first owner of the case.
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).
-- 11 Dec 2017	AT	R72944	9	Return external case status for external users

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)

Declare @sLookupCulture		nvarchar(10)
Declare @bExternalUser		bit

-- Variable used for the Principal
-- associated with first owner.
Declare	@nNameNo		int
Declare	@sNameType		nvarchar(30)
Declare	@sName			nvarchar(255)
Declare	@sNameCode		nvarchar(20)
Declare	@sRowKey		nvarchar(37)

Set     @nErrorCode = 0
Set 	@bExternalUser = 0
Set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @nErrorCode = sp_executesql @sSQLString,
				N'@bExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser	= @bExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)
	
	if @bExternalUser = 1
	Begin
		Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+" as CaseStatusDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+" as RenewalStatusDescription,"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+" as CaseStatusDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+" as RenewalStatusDescription,"+char(10)
	End
	
	Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" as CaseCategoryDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+" as SubTypeDescription,"+char(10)+
	CASE WHEN @bExternalUser = 0 THEN +dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TF',@sLookupCulture,@pbCalledFromCentura)+" as FileLocation,"+char(10)+
							    dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura)+" as CaseOffice,"+char(10)
	END+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)+" as RenewalInstruction,"+char(10)+
	"isnull(CTYPE.CRMONLY,0) as IsCRM"+char(10)+
	"from CASES C"+char(10)+
	"join CASETYPE CTYPE 		on (CTYPE.CASETYPE=C.CASETYPE)"+char(10)+
	"join COUNTRY CT 		on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"				and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)"+char(10)+
	"							from VALIDPROPERTY VP1"+char(10)+
	"							where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
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
	"							and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"							and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
									   "and VS.CASETYPE     = C.CASETYPE"+char(10)+
									   "and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
									   "and VS.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     			   "and VS.COUNTRYCODE  = (select min(VS1.COUNTRYCODE)"+char(10)+
	                     									  "from VALIDSUBTYPE VS1"+char(10)+
	                     	               					  "where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  					  "and   VS1.CASETYPE     = C.CASETYPE"+char(10)+
	                          							  "and   VS1.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                          							  "and   VS1.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     									  "and   VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	
	CASE 	WHEN @bExternalUser = 0 
	     	THEN 	"left join TABLECODES TF 	on TF.TABLECODE=(	Select CL.FILELOCATION"+char(10)+	
			"							from CASELOCATION CL"+char(10)+	
			"							where CL.CASEID=C.CASEID"+char(10)+	
			"				and CL.WHENMOVED=(	select max(CL.WHENMOVED)"+char(10)+	
			"							from CASELOCATION CL"+char(10)+	
			"							where CL.CASEID=C.CASEID))"+char(10)+		
			"left join OFFICE OFC		on (OFC.OFFICEID=C.OFFICEID)"+char(10)+
			"left join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction (@pnCaseKey, 'R'))"+char(10)
			WHEN @bExternalUser = 1
			THEN				
			-- RFC5012 only return Instruction if the Site Control contains the 'R' for clients, suppress value otherwise.
			"left join SITECONTROL S on (S.CONTROLID = 'Client Instruction Types')"+char(10)+
			"left join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction (@pnCaseKey, 'R')"+char(10)+
			"	and patindex('%R%',upper(S.COLCHARACTER))>0)"+char(10)
	END+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int',
					  @pnCaseKey		 	= @pnCaseKey
End

-------------------------------------------
-- If the connected user is internal then
-- get the Staff Member responsible for the 
-- the first Owner associated with the Case
-------------------------------------------
If  @nErrorCode = 0
and @bExternalUser = 0
Begin
	Set @sSQLString = "
	Select @nNameNo  =N.NAMENO,
	       @sNameType=NR.RELATIONDESCR,
	       @sName    =dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
	       @sNameCode=N.NAMECODE,
	       @sRowKey  =convert(nvarchar(11),@pnCaseKey)+'^'+
			  '~~~^'+
			  convert(nvarchar(11),N.NAMENO)+'^1'
		--------------------------------------
		-- Get Related Name where a property
		-- type specific relationship has been
		-- defined
		--------------------------------------
	from (	select AN.RELATEDNAME
		from CASES C
		join CASENAME CN on (CN.CASEID=C.CASEID
				 and CN.NAMETYPE = CASE C.CASETYPE
						       WHEN 'C' THEN 'P'
						       WHEN 'D' THEN 'G'
						       WHEN 'F' THEN 'H'
						       WHEN 'H' THEN 'V'
						       ELSE 'O'
						    END
				 and CN.SEQUENCE = (select min(CN1.SEQUENCE)
						    from CASENAME CN1
						    where CN1.CASEID=CN.CASEID
						    and   CN1.NAMETYPE=CN.NAMETYPE
						    and   CN1.EXPIRYDATE is null)
					)
		join ASSOCIATEDNAME AN on (AN.NAMENO=CN.NAMENO
				       and AN.RELATIONSHIP='RES'
				       and AN.PROPERTYTYPE=C.PROPERTYTYPE
				       and AN.SEQUENCE = 
						   (select min(AN1.SEQUENCE)
						    from ASSOCIATEDNAME AN1
						    where AN1.NAMENO=AN.NAMENO
						    and   AN1.RELATIONSHIP=AN.RELATIONSHIP
						    and   AN1.PROPERTYTYPE=AN.PROPERTYTYPE)
					)
		where C.CASEID=@pnCaseKey
		UNION ALL
		--------------------------------------
		-- Get Related Name where there is no
		-- property type specific relationship
		-- defined
		--------------------------------------
		select  AN.RELATEDNAME
		from CASES C
		join CASENAME CN on (CN.CASEID=C.CASEID
				 and CN.NAMETYPE = CASE C.CASETYPE
						       WHEN 'C' THEN 'P'
						       WHEN 'D' THEN 'G'
						       WHEN 'F' THEN 'H'
						       WHEN 'H' THEN 'V'
						       ELSE 'O'
						    END
				 and CN.SEQUENCE = (select min(CN1.SEQUENCE)
						    from CASENAME CN1
						    where CN1.CASEID=CN.CASEID
						    and   CN1.NAMETYPE=CN.NAMETYPE
						    and   CN1.EXPIRYDATE is null)
					)
		join ASSOCIATEDNAME AN on (AN.NAMENO=CN.NAMENO
				       and AN.RELATIONSHIP='RES'
				       and AN.PROPERTYTYPE is null
				       and AN.SEQUENCE = 
						   (select min(AN1.SEQUENCE)
						    from ASSOCIATEDNAME AN1
						    where AN1.NAMENO=AN.NAMENO
						    and   AN1.RELATIONSHIP=AN.RELATIONSHIP
						    and   AN1.PROPERTYTYPE is null)
					)
		left join ASSOCIATEDNAME AN2
				     on (AN2.NAMENO=CN.NAMENO
				     and AN2.RELATIONSHIP='RES'
				     and AN2.PROPERTYTYPE=C.PROPERTYTYPE)
		where C.CASEID=@pnCaseKey
		and AN2.NAMENO is null)	RES
	Join NAME N on (N.NAMENO=RES.RELATEDNAME)
	join NAMERELATION NR on (NR.RELATIONSHIP='RES')"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @nNameNo		int		OUTPUT,
				  @sNameType		nvarchar(30)	OUTPUT,
				  @sName		nvarchar(255)	OUTPUT,
				  @sNameCode		nvarchar(20)	OUTPUT,
				  @sRowKey		nvarchar(37)	OUTPUT',
				  @pnCaseKey		=@pnCaseKey,
				  @nNameNo		=@nNameNo	OUTPUT,
				  @sNameType		=@sNameType	OUTPUT,
				  @sName		=@sName		OUTPUT,
				  @sNameCode		=@sNameCode	OUTPUT,
				  @sRowKey		=@sRowKey	OUTPUT
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
		convert(nvarchar(11),CN.SEQUENCE) as RowKey,
		-- Generate a column to order the result
		-- based on the Name Type
		CASE CN.NAMETYPE
		  	WHEN 'I'	THEN 0	
		  	WHEN 'A'	THEN 1
		  	WHEN 'O'	THEN 2
		  	WHEN 'G'	THEN 3
		  	WHEN 'H'	THEN 4
		  	WHEN 'P'	THEN 5
		  	WHEN 'V'	THEN 6
			WHEN 'EMP'	THEN 7
			WHEN 'SIG'	THEN 8
			ELSE 9
		END			as NameDisplayOrder
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,@bExternalUser,@pbCalledFromCentura) NT 
					on (NT.NAMETYPE = CN.NAMETYPE)
	join NAME N			on (N.NAMENO = CN.NAMENO)		
	where CN.CASEID = @pnCaseKey"+char(10)+
	CASE 	WHEN @bExternalUser = 0 
		THEN   "and CN.NAMETYPE in ('I', 'A', 'O', 'SIG', 'EMP', 'P','G','H','V')"	
		-- External users have restricted list
		-- of Name Types
		ELSE "and CN.NAMETYPE in ('I', 'O', 'J')"	
	END

	If @nNameNo is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+"
		UNION ALL
		select	@pnCaseKey, 
			'RES',
			@nNameNo,
			1,
			@sNameType,
			@sName,
			@sNameCode,
			@sRowKey,
			9"
	End
	
	-- Add the ORDER BY
	Set @sSQLString=@sSQLString+char(10)+"
	ORDER BY NameDisplayOrder, NameTypeKey, NameSequence"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @bExternalUser	bit,
					  @nNameNo		int,
					  @sNameType		nvarchar(30),
					  @sName		nvarchar(255),
					  @sNameCode		nvarchar(20),
					  @sRowKey		nvarchar(37)',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @bExternalUser	= @bExternalUser,
					  @nNameNo		= @nNameNo,
					  @sNameType		= @sNameType,
					  @sName		= @sName,
					  @sNameCode		= @sNameCode,
					  @sRowKey		= @sRowKey	
End

-- Critical Dates result set
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.cs_ListCriticalDates
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= @bExternalUser,
		@psCulture		= @psCulture,
		@pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseSummary to public
GO
