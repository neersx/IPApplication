-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNameControlCriteriaTree
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].ipw_ListNameControlCriteriaTree') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNameControlCriteriaTree.'
	Drop procedure [dbo].ipw_ListNameControlCriteriaTree
End
Print '**** Creating Stored Procedure dbo.ipw_ListNameControlCriteriaTree...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ipw_ListNameControlCriteriaTree]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
	@pnCriteriaNo			int		-- Mandatory
)
as
-- PROCEDURE:	ipw_ListNameControlCriteriaTree
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Gets the inheritance hierarchy (ancestors and descendants) for a specific name criteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 27 Aug 2009  LP      RFC7580 1       Procedure created.
-- 14 Sep 2009	LP	RFC8047	3	Return ProfileName column.	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sLookupCulture	nvarchar(10)
declare	@pnIsCriteriaInherited	decimal(1,0)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @pnIsCriteriaInherited = 0

If 	exists(select 1 from NAMECRITERIAINHERITS where FROMNAMECRITERIANO = @pnCriteriaNo) 
	or exists(select 1 from NAMECRITERIAINHERITS where NAMECRITERIANO = @pnCriteriaNo)
Begin
	Set @pnIsCriteriaInherited = 1
End

If  @nErrorCode = 0
Begin
        Set @sSQLString = 
        "Select"+char(10)+
	"	N.NAMECRITERIANO as NameCriteriaNo,"+char(10)+
	"	N.PROGRAMID as Program,"+char(10)+	
	dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'P',@sLookupCulture,0)+" as ProgramDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMECRITERIA','DESCRIPTION',null,'N',@sLookupCulture,0)+" as CriteriaName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMECRITERIA','DESCRIPTION',null,'N',@sLookupCulture,0)+" as Description,"+char(10)+
	"N.DATAUNKNOWN as DataUnknown,"+char(10)+
	"N.USEDASFLAG as UsedAsFlag,"+char(10)+
	"cast(isnull(N.SUPPLIERFLAG,0) as bit) as Supplier,"+char(10)+
	"cast((isnull(N.USEDASFLAG, 0) & 2) as bit) as Staff,"+char(10)+
	"cast((isnull(N.USEDASFLAG, 0) & 4) as bit) as Client,"+char(10)+
	"~cast((isnull(N.USEDASFLAG, 0) & 1) as bit) as Organisation,"+char(10)+
	"cast((isnull(N.USEDASFLAG, 0) & 1) as bit) as Individual,"+char(10)+
	"N.COUNTRYCODE as CountryCode,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as Country,"+char(10)+
	"cast(isnull(N.LOCALCLIENTFLAG,0) as bit) as LocalClient,"+char(10)+
	"N.CATEGORY as Category,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+" as CategoryDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,@pbCalledFromCentura)+" as Relationship,"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+" as NameType,"+char(10)+
	"PR.PROFILENAME as ProfileName,"+char(10)+
	"0 as IsCriteriaShared,"+char(10)+
	"@pnIsCriteriaInherited as IsCriteriaInherited,"+char(10)+
	"ISNULL(XCC.DEPTH,0) as [Level]"+char(10)+
	"from NAMECRITERIA N"+char(10)+
	"left join PROFILES PR on (PR.PROFILEID=N.PROFILEID)"+char(10)+
	"left join COUNTRY CT on (CT.COUNTRYCODE=N.COUNTRYCODE)"+char(10)+
	"left join TABLECODES TC	on (TC.TABLECODE=N.CATEGORY)"+char(10)+
	"left join NAMERELATION NR	on (NR.RELATIONSHIP=N.RELATIONSHIP)"+char(10)+
	"left join NAMETYPE NT	on (NT.NAMETYPE=N.NAMETYPE)"+char(10)+
	"left join PROGRAM P	on (P.PROGRAMID=N.PROGRAMID)"+char(10)+
	"join (select * from dbo.fn_GetParentCriteria(@pnCriteriaNo,1)"+char(10)+
	"UNION"+char(10)+
	"select * from dbo.fn_GetChildCriteria(@pnCriteriaNo,1)) XCC on (XCC.DEPTH IS NOT NULL)"+char(10)+
	"where (N.NAMECRITERIANO = XCC.CRITERIANO and XCC.DEPTH > 0) or (N.NAMECRITERIANO = XCC.FROMCRITERIA and DEPTH < 1)"
	print @sSQLString
	exec @nErrorCode = sp_executesql @sSQLString,
	        N'@pnCriteriaNo		int,
	        @pnIsCriteriaInherited	decimal(1,0)',
	        @pnCriteriaNo		=	@pnCriteriaNo,
	        @pnIsCriteriaInherited = @pnIsCriteriaInherited	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListNameControlCriteriaTree to public
GO
