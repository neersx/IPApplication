-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCasePriorArt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCasePriorArt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCasePriorArt.'
	Drop procedure [dbo].[csw_FetchCasePriorArt]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCasePriorArt...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchCasePriorArt
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnCaseId		int,
	@pnPriorArtId		int		= null,
	@pbCalledFromCentura	bit		= 0	-- Indicates that Centura called the stored procedure
)
as
-- PROCEDURE:	csw_FetchCasePriorArt
-- VERSION:	5
-- SCOPE:	WorkBenches
-- DESCRIPTION:	Returns Case Prior Art details for maintenance.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 27 Nov 2007	AT	RFC5670		1	Procedure created
-- 24 Mar 2009	KR	RFC7769		2	Extended select to include CITATION, PATENTRELATED and GRANTEDDATE columns.
-- 15 Mar 2011	JC	RFC6563		3	Only display a Case and Prior Art combination once.
-- 13 Oct 2011	KR	RFC10576	4	Added CASEFIRSTLINKEDTO column.
-- 07 Mar 2012	LP	RFC12036	5	Extend @sSQLString variable size to nvarchar(max). 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Begin
	Set @sSQLString = "
	Select  CSR.CASEID		as CaseKey,
		CSR.PRIORARTID		as PriorArtKey,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CR',@sLookupCulture,@pbCalledFromCentura)
			+ "		as Country,
		SR.OFFICIALNO		as OfficialNumber,
		SR.CITATION		as Citation,
		SR.PATENTRELATED	as IPDocument,
		SR.ISSUEDDATE		as IssuedDate,
		SR.RECEIVEDDATE		as ReceivedDate,
		SR.PUBLICATIONDATE	as PublicationDate,
		SR.PRIORITYDATE		as PriorityDate,
		SR.GRANTEDDATE		as GrantedDate,
		SR.PUBLICATION		as Publication,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CI',@sLookupCulture,@pbCalledFromCentura)
			+ "		as IssuingCountry,
		CSR.STATUS		as StatusKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			 +" as StatusDescription,
		max(CSR.UPDATEDDATE)	as UpdatedDate,
		cast(CSR.CASEID as nvarchar(12)) + '^' + cast(CSR.PRIORARTID as nvarchar(12)) as RowKey,
		cast(sum(CASE WHEN(CSR.FAMILYPRIORARTID is null and CSR.CASELISTPRIORARTID is null and CSR.NAMEPRIORARTID is null and isnull(CSR.ISCASERELATIONSHIP,0) = 0)
			THEN 0 ELSE 1 END) as bit)	as IsInherited,
		isnull(SR.ISSOURCEDOCUMENT, 0) as IsSourceDocument,
		isnull(CSR.CASEFIRSTLINKEDTO,0) as IsCaseFirstLinkedTo
	from CASESEARCHRESULT CSR
	join SEARCHRESULTS SR on (SR.PRIORARTID = CSR.PRIORARTID)
	left join TABLECODES TC on (TC.TABLECODE = CSR.STATUS)
	left join COUNTRY CR	on (CR.COUNTRYCODE = SR.COUNTRYCODE)
	left join COUNTRY CI	on (CI.COUNTRYCODE = SR.ISSUINGCOUNTRY)
	where CSR.CASEID = @pnCaseId"
	
	if (@pnPriorArtId is not null)
	Begin
		Set @sSQLString = @sSQLString + " and CSR.PRIORARTID = @pnPriorArtId"
	End
	
	Set @sSQLString = @sSQLString + " group by CSR.CASEID, CSR.PRIORARTID,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CR',@sLookupCulture,@pbCalledFromCentura) + ",
		SR.OFFICIALNO,
		SR.CITATION,
		SR.PATENTRELATED,
		SR.ISSUEDDATE,
		SR.RECEIVEDDATE,
		SR.PUBLICATIONDATE,
		SR.PRIORITYDATE,
		SR.GRANTEDDATE,
		SR.PUBLICATION,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CI',@sLookupCulture,@pbCalledFromCentura) + ",
		CSR.STATUS,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) +",
		cast(CSR.CASEID as nvarchar(12)) + '^' + cast(CSR.PRIORARTID as nvarchar(12)),
		SR.ISSOURCEDOCUMENT,
		CSR.CASEFIRSTLINKEDTO
	Order by Country, Publication, OfficialNumber"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnCaseId	int,
				@pnPriorArtId	int',
				@pnCaseId	= @pnCaseId,
				@pnPriorArtId	= @pnPriorArtId

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCasePriorArt to public
GO
