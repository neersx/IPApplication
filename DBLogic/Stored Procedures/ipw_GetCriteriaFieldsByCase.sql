-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCriteriaFieldsByCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetCriteriaFieldsByCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetCriteriaFieldsByCase.'
	Drop procedure [dbo].[ipw_GetCriteriaFieldsByCase]
End
Print '**** Creating Stored Procedure dbo.ipw_GetCriteriaFieldsByCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetCriteriaFieldsByCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnUseCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	ipw_ListCriteria
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure will get the Case fields passing in Case Key as parameter.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Jan 2009	NG	6921	1	Procedure created
-- 08 May 2009	NG	7850	2	It will now return default ProgramID as well depending upon Case Type.
--					Also, logic has been updated to cater for default country.
-- 19 Jul 2017	MF	71968	3	When determining the default Case program, first consider the Profile of the User.
-- 14 Sep 2017	MF	71968	4	Rework after failed test.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sLookupCulture	nvarchar(10)
declare @sProgramId	nvarchar(8)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @sProgramId = left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
	from  SITECONTROL S
	join USERIDENTITY U             on (U.IDENTITYID= @pnUserIdentityId)
	join CASES C                    on (C.CASEID    = @pnUseCaseKey)
	join CASETYPE CT                on (C.CASETYPE  = CT.CASETYPE)
	left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
					and PA.ATTRIBUTEID=2)	-- Default Cases Program
	where S.CONTROLID = CASE WHEN CT.CRMONLY=1 THEN 'CRM Screen Control Program'
						   ELSE 'Case Screen Default Program' 
			    END"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@sProgramId		nvarchar(8)	OUTPUT,
				  @pnUseCaseKey		int,
				  @pnUserIdentityId	int',
				  @sProgramId		= @sProgramId	OUTPUT,
				  @pnUseCaseKey		= @pnUseCaseKey,
				  @pnUserIdentityId	= @pnUserIdentityId
End

If @nErrorCode = 0
and @pnUseCaseKey is not null
Begin
	Set @sSQLString="
	select	C.OFFICEID, " +dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0)+ " as CaseOfficeDesc,
		C.CASETYPE, " +dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)+ " as CaseTypeDesc,
		C.PROPERTYTYPE, "+ isnull(dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) ,
				    dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0))+" as PropertyTypeDesc,
		C.COUNTRYCODE, CO.COUNTRY as Country,
		C.CASECATEGORY, "+isnull(dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) ,
				    dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0))+" as CategoryDesc,
		C.SUBTYPE, "+ isnull(dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0),
				    dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0))+" as SubTypeDesc,
		P.BASIS, "+isnull(dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) ,
				    dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0))+" as BasisDesc,
		@sProgramId as ProgramID
	from CASES C
	left join PROPERTY P on (P.CASEID=C.CASEID)
	left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
	left join CASETYPE CT on (CT.CASETYPE=C.CASETYPE)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))   
								left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE=C.PROPERTYTYPE)
	left join COUNTRY CO on (CO.COUNTRYCODE=C.COUNTRYCODE)
	left join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=C.PROPERTYTYPE
					and VC.CASETYPE    =C.CASETYPE
					and VC.CASECATEGORY=C.CASECATEGORY
					and VC.COUNTRYCODE =(	select min(VC1.COUNTRYCODE)
								from VALIDCATEGORY VC1
								where VC1.CASETYPE=C.CASETYPE
								and VC1.PROPERTYTYPE=C.PROPERTYTYPE
								and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))   
								left join CASECATEGORY CC	on (CC.CASETYPE=C.CASETYPE
					and CC.CASECATEGORY=C.CASECATEGORY)
	left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE=C.PROPERTYTYPE
					and VS.CASETYPE    =C.CASETYPE
					and VS.CASECATEGORY=C.CASECATEGORY
					and VS.SUBTYPE     =C.SUBTYPE
					and VS.COUNTRYCODE =(	select min(VS1.COUNTRYCODE)
								from VALIDSUBTYPE VS1
								where VS1.CASETYPE=C.CASETYPE
								and VS1.PROPERTYTYPE=C.PROPERTYTYPE
								and VS1.CASECATEGORY=C.CASECATEGORY
								and VS1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join SUBTYPE S		on (S.SUBTYPE=C.SUBTYPE)
	left join VALIDBASIS VB		on (VB.PROPERTYTYPE=C.PROPERTYTYPE
					and VB.BASIS=P.BASIS
					and VB.COUNTRYCODE =(	select min(VB1.COUNTRYCODE)
								from VALIDBASIS VB1
								where VB1.PROPERTYTYPE=C.PROPERTYTYPE
								and VB1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join APPLICATIONBASIS B	on (B.BASIS=P.BASIS)
	where C.CASEID=@pnUseCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUseCaseKey		int,
					  @sProgramId		nvarchar(8),
					  @sLookupCulture	nvarchar(10)',
					  @pnUseCaseKey	 = @pnUseCaseKey,
					  @sProgramId = @sProgramId,
					  @sLookupCulture = @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetCriteriaFieldsByCase to public
GO
