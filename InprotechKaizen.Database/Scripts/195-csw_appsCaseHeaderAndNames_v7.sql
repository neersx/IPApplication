-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_appsCaseHeaderAndNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_appsCaseHeaderAndNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_appsCaseHeaderAndNames.'
	Drop procedure [dbo].[csw_appsCaseHeaderAndNames]
	Print '**** Creating Stored Procedure dbo.csw_appsCaseHeaderAndNames...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_appsCaseHeaderAndNames
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int
)
AS 
-- PROCEDURE:	csw_appsCaseHeaderAndNames (based on csw_appsCaseHeaderAndNames v9)
-- VERSION:	7
-- DESCRIPTION:	Populates the CaseSummary result set.

-- MODIFICATIONS :
-- Date			Who		Number		Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 04 2018	SF		DR-40113	1			Created from csw_appsCaseHeaderAndNames v9
-- 16 01 2019	DV		DR-44520	2			Return Classes for Case
-- 25 03 2020   SW		DR-45459    3			Return ShowNameCode for NameType in Case Name resultset
-- 14 09 2020	MS		DR-63416	4			Return CaseNameReference, Basis and TotalClasses in the resultset
-- 20 08 2021	LS		DR-69150	5			Return email in the names resultset
-- 31 09 2021	AK		DR-75101	6			Added logic to consider Attention for Owner, Instructor and Agent.
-- 31 09 2021	AK		DR-75101	7			Modified null check.

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
Declare	@nShowNameCode	decimal(1,0)
Declare @sDisplayEmail	nvarchar(500)

Set     @nErrorCode = 0
Set 	@bExternalUser = 0
Set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

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
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,0)+" as Title,"+char(10)
	
	if @bExternalUser = 1
	Begin
		Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,0)+" as CaseStatusDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RS',@sLookupCulture,0)+" as RenewalStatusDescription,"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,0)+" as CaseStatusDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,0)+" as RenewalStatusDescription,"+char(10)
	End
	
	Set @sSQLString = @sSQLString + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,0)+" as CountryName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0)+" as PropertyTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0)+" as CaseCategoryDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0)+" as SubTypeDescription,"+char(10)+
	CASE WHEN @bExternalUser = 0 THEN +dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TF',@sLookupCulture,0)+" as FileLocation,"+char(10)+
							    dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,0)+" as CaseOffice,"+char(10)
	END+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0)+" as BasisDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,0)+" as RenewalInstruction,"+char(10)+
	"isnull(CTYPE.CRMONLY,0) as IsCRM,"+char(10)+
	"C.LOCALCLASSES as Classes,"+char(10)+
	"C.NOOFCLASSES as TotalClasses"+char(10)+
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
	"left join VALIDBASIS VB on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                         	       "and VB.BASIS = P.BASIS"+char(10)+
	                    		       "and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"+char(10)+
		                     	                              "from VALIDBASIS VB1"+char(10)+
		                     	                              "where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
		                     	                              "and VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
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
		   @sDisplayEmail = dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION),
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
	Left Join TELECOMMUNICATION ML on (ML.TELECODE=N.MAINEMAIL)
	join NAMERELATION NR on (NR.RELATIONSHIP='RES')
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @nNameNo		int		OUTPUT,
				  @sNameType		nvarchar(30)	OUTPUT,
				  @sName		nvarchar(255)	OUTPUT,
				  @sNameCode		nvarchar(20)	OUTPUT,
				  @sDisplayEmail	nvarchar(500)	OUTPUT,
				  @sRowKey		nvarchar(37)	OUTPUT',
				  @pnCaseKey		=@pnCaseKey,
				  @nNameNo		=@nNameNo	OUTPUT,
				  @sNameType		=@sNameType	OUTPUT,
				  @sName		=@sName		OUTPUT,
				  @sNameCode		=@sNameCode	OUTPUT,
				  @sDisplayEmail	=@sDisplayEmail output,
				  @sRowKey		=@sRowKey	OUTPUT
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
		   @sDisplayEmail = dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION),
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
	Left Join TELECOMMUNICATION ML on (ML.TELECODE=N.MAINEMAIL)
	join NAMERELATION NR on (NR.RELATIONSHIP='RES')"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @nNameNo		int		OUTPUT,
				  @sNameType		nvarchar(30)	OUTPUT,
				  @sName		nvarchar(255)	OUTPUT,
				  @sNameCode		nvarchar(20)	OUTPUT,
				  @sDisplayEmail	nvarchar(500)	OUTPUT,
				  @sRowKey		nvarchar(37)	OUTPUT',
				  @pnCaseKey		=@pnCaseKey,
				  @nNameNo		=@nNameNo	OUTPUT,
				  @sNameType		=@sNameType	OUTPUT,
				  @sName		=@sName		OUTPUT,
				  @sNameCode		=@sNameCode	OUTPUT,
				  @sDisplayEmail	=@sDisplayEmail	OUTPUT,
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
		NT.DESCRIPTION	as NameTypeDescription,
		NT.SHOWNAMECODE	as ShowNameCodeRaw,
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
		END			as NameDisplayOrder,
		CN.REFERENCENO  as NameReference,
		Case when CN.NAMETYPE in ('A', 'I', 'O') and CN.CORRESPONDNAME is not null and isnull(dbo.fn_FormatTelecom(AL.TELECOMTYPE, AL.ISD, AL.AREACODE, AL.TELECOMNUMBER, AL.EXTENSION), '') <> ''
		     then  dbo.fn_FormatTelecom(AL.TELECOMTYPE, AL.ISD, AL.AREACODE, AL.TELECOMNUMBER, AL.EXTENSION)
			 else  dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)
		end  as DisplayMainEmail
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,@bExternalUser,0) NT 
					on (NT.NAMETYPE = CN.NAMETYPE)
	join NAME N			on (N.NAMENO = CN.NAMENO)
	Left Join TELECOMMUNICATION ML		on (ML.TELECODE=N.MAINEMAIL)
	left join NAME AN	on (AN.NAMENO = CN.CORRESPONDNAME)
	Left Join TELECOMMUNICATION AL		on (AL.TELECODE=AN.MAINEMAIL)
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
			@nShowNameCode,
			@sName,
			@sNameCode,
			@sRowKey,
			9,
			NULL,
			@sDisplayEmail"
			
	End
	
	-- Add the ORDER BY
	Set @sSQLString=@sSQLString+char(10)+"
	ORDER BY NameDisplayOrder, NameTypeKey, NameSequence"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @bExternalUser	bit,
					  @nNameNo		int,
					  @sNameType		nvarchar(30),
					  @sName		nvarchar(255),
					  @sNameCode		nvarchar(20),
					  @sRowKey		nvarchar(37),
					  @sDisplayEmail nvarchar(500),
					  @nShowNameCode decimal(1,0)',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @sLookupCulture	= @sLookupCulture,
					  @bExternalUser	= @bExternalUser,
					  @nNameNo		= @nNameNo,
					  @sNameType		= @sNameType,
					  @sName		= @sName,
					  @sNameCode		= @sNameCode,
					  @sRowKey		= @sRowKey,
					  @sDisplayEmail = @sDisplayEmail,
					  @nShowNameCode = @nShowNameCode
End


Return @nErrorCode
GO

Grant execute on dbo.csw_appsCaseHeaderAndNames to public
GO
