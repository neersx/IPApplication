-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchNameControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchNameControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchNameControlCriteria.'
	Drop procedure [dbo].[ipw_FetchNameControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchNameControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_FetchNameControlCriteria
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaNo		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
	
)
as
-- PROCEDURE:	ipw_FetchNameControlCriteria
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Fetches Name Control Criteria record based on the Criteria no.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2009	MS	RFC7085	1	Procedure created
-- 07 Aug 2009	MS	RFC7085	2	Added Data Unknown, Individual column
-- 11 Sep 2009	LP	RFC8047	3	Return ProfileKey and ProfileName columns

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare	@pnIsCriteriaInherited	decimal(1,0)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @pnIsCriteriaInherited = 0

If 	exists(select * from NAMECRITERIAINHERITS where FROMNAMECRITERIANO = @pnCriteriaNo) 
	or exists(select * from NAMECRITERIAINHERITS where NAMECRITERIANO = @pnCriteriaNo)
Begin
	Set @pnIsCriteriaInherited = 1
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select 
		N.NAMECRITERIANO as RowKey,
		N.NAMECRITERIANO as CriteriaNo,
		N.PROGRAMID as ProgramID,
		N.COUNTRYCODE as CountryCode, "+char(10)+
		dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura) +
		"	as CountryName,
		N.CATEGORY as CategoryCode, "+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+
		"	as CategoryDescription,
		N.NAMETYPE as NameTypeKey,"+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+
		"	as NameTypeDescription,
		N.RELATIONSHIP as RelationshipKey, "+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,@pbCalledFromCentura)+
		"	as RelationshipDescription,
		~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsOrganisation,
		cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsIndividual,
		cast((isnull(N.USEDASFLAG, 0) & 2) as bit)	as IsStaff,
		cast((isnull(N.USEDASFLAG, 0) & 4) as bit)	as IsClient,
		N.SUPPLIERFLAG as IsSupplier,		
		N.LOCALCLIENTFLAG as IsLocalClient,
		N.USERDEFINEDRULE as UserDefinedRule,
		N.RULEINUSE as RuleInUse,
		N.DATAUNKNOWN	as DataUnknown,
		N.DESCRIPTION as CriteriaName,
		N.PURPOSECODE as PurposeCode,
		@pnIsCriteriaInherited as IsCriteriaInherited,
		N.PROFILEID as ProfileKey,
		PR.PROFILENAME as ProfileName
	FROM NAMECRITERIA N
	left join COUNTRY CT on (CT.COUNTRYCODE=N.COUNTRYCODE)	
	left join TABLECODES TC on (TC.TABLECODE=N.CATEGORY)
	left join NAMETYPE NT on (NT.NAMETYPE = N.NAMETYPE)
	left join NAMERELATION NR on (NR.RELATIONSHIP = N.RELATIONSHIP)		
	left join PROFILES PR on (PR.PROFILEID = N.PROFILEID)
	where N.NAMECRITERIANO = @pnCriteriaNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCriteriaNo		int,
			@pnIsCriteriaInherited	decimal(1,0)',
			@pnCriteriaNo		= @pnCriteriaNo,
			@pnIsCriteriaInherited  = @pnIsCriteriaInherited	
	
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchNameControlCriteria to public
GO
