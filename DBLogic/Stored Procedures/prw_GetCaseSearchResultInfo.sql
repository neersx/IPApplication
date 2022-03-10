-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_GetCaseSearchResultInfo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_GetCaseSearchResultInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_GetCaseSearchResultInfo.'
	Drop procedure [dbo].[prw_GetCaseSearchResultInfo]
End
Print '**** Creating Stored Procedure dbo.prw_GetCaseSearchResultInfo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_GetCaseSearchResultInfo
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pnCaseKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_GetCaseSearchResultInfo
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the details of a Case Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Apr 2011	JC	RFC6563	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select DISTINCT
	FS.FAMILY	as FamilyCode,
	"+dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura)
		+ " as FamilyTitle
	from CASESEARCHRESULT CS
	join FAMILYSEARCHRESULT FS	on (FS.FAMILYPRIORARTID = CS.FAMILYPRIORARTID)
	join CASEFAMILY CF		on (CF.FAMILY = FS.FAMILY)
	where CS.PRIORARTID = @pnPriorArtKey
	and CS.CASEID = @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnPriorArtKey		int,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey,
			@pnCaseKey		= @pnCaseKey

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select DISTINCT
	"+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)	
			 +" as CaseListCode,			
	"+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura)	
			 +" as CaseListDescription
	from CASESEARCHRESULT CS
	join CASELISTSEARCHRESULT CLS	on (CLS.CASELISTPRIORARTID = CS.CASELISTPRIORARTID)
	join CASELIST CL		on (CL.CASELISTNO = CLS.CASELISTNO)
	where CS.PRIORARTID = @pnPriorArtKey
	and CS.CASEID = @pnCaseKey
	order by CaseListCode"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnPriorArtKey		int,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey,
			@pnCaseKey		= @pnCaseKey

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select DISTINCT
	N.NAMECODE		as NameCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, default) as DisplayName,
	NS.NAMETYPE		as NameTypeCode,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
		+ " as NameTypeDescription
	from CASESEARCHRESULT CS
	join NAMESEARCHRESULT NS	on (NS.NAMEPRIORARTID = CS.NAMEPRIORARTID)
	join NAME N			on (N.NAMENO = NS.NAMENO)
	left join NAMETYPE NT		on (NT.NAMETYPE = NS.NAMETYPE)
	where CS.PRIORARTID = @pnPriorArtKey
	and CS.CASEID = @pnCaseKey
	order by DisplayName"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnPriorArtKey		int,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey,
			@pnCaseKey		= @pnCaseKey

End

If @nErrorCode = 0
Begin
Set @sSQLString = "Select DISTINCT
	cast(CS.ISCASERELATIONSHIP as bit)	as IsCaseRelationship
	from CASESEARCHRESULT CS
	where isnull(CS.ISCASERELATIONSHIP,0) = 1
	and CS.PRIORARTID = @pnPriorArtKey
	and CS.CASEID = @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnPriorArtKey		int,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey,
			@pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.prw_GetCaseSearchResultInfo to public
GO