-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListCaseSearchResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListCaseSearchResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListCaseSearchResults.'
	Drop procedure [dbo].[prw_ListCaseSearchResults]
End
Print '**** Creating Stored Procedure dbo.prw_ListCaseSearchResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListCaseSearchResults
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnPriorArtKey		int				= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	prw_ListCaseSearchResults
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Cases for a particular Prior Art Key

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	CS.PRIORARTID			as PriorArtKey,
	CS.CASEID				as CaseKey,
	C.IRN					as CaseReference,
	C.CURRENTOFFICIALNO		as CurrentOfficialNumber,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName,
	CS.STATUS				as StatusKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			 +" as StatusDescription,
	max(cast(isnull(CS.CASEFIRSTLINKEDTO,0) as tinyint))	
							as CaseFirstLinkedTo,
	max(CS.UPDATEDDATE)		as LastModifiedDate,
	sum(CASE WHEN(CS.FAMILYPRIORARTID   is null) THEN 0 ELSE 1 END) as FamilyCount,
	sum(CASE WHEN(CS.CASELISTPRIORARTID is null) THEN 0 ELSE 1 END) as CaseListCount,
	sum(CASE WHEN(CS.NAMEPRIORARTID     is null) THEN 0 ELSE 1 END) as NameCount,
	sum(CASE WHEN(CS.ISCASERELATIONSHIP     is null) THEN 0 ELSE 1 END) as RelationshipCount,
	sum(CASE WHEN(CS.FAMILYPRIORARTID	is null and CS.CASELISTPRIORARTID is null and CS.NAMEPRIORARTID is null and isnull(ISCASERELATIONSHIP,0) = 0)
		THEN 1 ELSE 0 END) as SelfCount
	from CASESEARCHRESULT CS
	join CASES C			on (C.CASEID = CS.CASEID)
	left join COUNTRY CT	on (CT.COUNTRYCODE = C.COUNTRYCODE)
	left join TABLECODES TC	on (TC.TABLECODE = CS.STATUS)
	where CS.PRIORARTID = @pnPriorArtKey
	group by PRIORARTID, CS.CASEID, C.IRN, C.CURRENTOFFICIALNO, 
	         "+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+ ", 
		 CS.STATUS, 
		 "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+" 
	order by CaseReference"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@pnPriorArtKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_ListCaseSearchResults to public
GO