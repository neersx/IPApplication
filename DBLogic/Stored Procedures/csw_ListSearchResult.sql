-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListSearchResult 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListSearchResult.'
	Drop procedure [dbo].[csw_ListSearchResult]
	Print '**** Creating Stored Procedure dbo.csw_ListSearchResult...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListSearchResult 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListSearchResult 
-- VERSION:	15
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates Prior Art datatable for displaying Case Details.

-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 15 Oct 2004  TM	RFC1156		1	Procedure created
-- 27 Oct 2004	TM	RFC1156		2	Add filtering on the @pnCaseKey.
-- 15 May 2005	JEK	RFC2508		3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 Jun 2006	SW	RFC4038		4	Add rowkey
-- 18 Feb 2008	AT	RFC5670		5	Return new columns from modified table structure.
-- 25 Mar 2009	KR	RFC7769		6	Extended select to include CITATION, PATENTRELATED and GRANTEDDATE columns.
-- 15 Mar 2011	MF	RFC6563		7	Only display a Case and Prior Art combination once.
-- 31 Mar 2011	KR	RFC10410	8	The description is returned by concatenating the fields for prior art and source documents.
-- 13 Oct 2011	KR	RFC10576	9	Added ICASEFIRSTLINKEDTO column.
-- 17 Sep 2012	KR	R11988		10	return KindCode as well.
-- 26 Sep 2012	KR	R11988		11	return CountryCode.
-- 26 Sep 2012	SF	R11988		12	Revert changes, return DiscoverSourceId instead.
-- 02 Jun 2015  SW      R45551          13      Remove DiscoverSourceId
-- 18 Oct 2015	KR	R51700		14	Change the SP to return only the description instead of using country code + coalece logic to determin the same
-- 07 Apr 2016	MF	R60190		15	Revist of RFC51700.  Need to keep the COALESCE logic for determining what to return as Description on screen. All
--						that we needed to remove was the concatenation of the COUNTRYCODE.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating Prior Art datatable
If @nErrorCode = 0
and @pnCaseKey is not null
Begin	

	Set @sSQLString = "
	Select  CSR.CASEID		as CaseKey,
		CSR.PRIORARTID		as PriorArtKey,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CR',@sLookupCulture,@pbCalledFromCentura)
			+ "		as CountryName,
		SR.OFFICIALNO		as OfficialNumber,
		case when (SR.ISSOURCEDOCUMENT = 1) then
			coalesce(" +
			dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'SR',@sLookupCulture,@pbCalledFromCentura) +",SR.PUBLICATION)
		else
			coalesce(" +
				dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','TITLE',null,'SR',@sLookupCulture,@pbCalledFromCentura) + "," +
				dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','CITATION',null,'SR',@sLookupCulture,@pbCalledFromCentura) + "," +
				dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'SR',@sLookupCulture,@pbCalledFromCentura) +")
		end	as Citation,
		SR.PATENTRELATED	as IPDocument,
		SR.ISSUEDDATE		as IssuedDate,
		SR.RECEIVEDDATE		as ReceivedDate,
		SR.PUBLICATIONDATE	as PublicationDate,
		SR.PRIORITYDATE		as PriorityDate,
		SR.GRANTEDDATE		as GrantedDate,
		SR.PUBLICATION		as Publication,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CI',@sLookupCulture,@pbCalledFromCentura)
			+ "		as IssuingCountryName,
		CSR.STATUS		as StatusKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			 +" as StatusDescription,
		max(CSR.UPDATEDDATE)	as UpdatedDate,
		cast(CSR.CASEID as nvarchar(12)) + '^' + cast(CSR.PRIORARTID as nvarchar(12)) as RowKey,
		cast(sum(CASE WHEN(CSR.FAMILYPRIORARTID is null and CSR.CASELISTPRIORARTID is null and CSR.NAMEPRIORARTID is null and isnull(CSR.ISCASERELATIONSHIP,0) = 0)
			THEN 0 ELSE 1 END) as bit)	as IsInherited,
		isnull(SR.ISSOURCEDOCUMENT, 0) as IsSourceDocument,
		isnull(CSR.CASEFIRSTLINKEDTO,0) as IsCaseFirstLinkedTo,
		case when SR.IMPORTEDFROM = 'DiscoverEvidenceFinder' THEN SR.CORRELATIONID ELSE null END as DiscoverSourceId
	from CASESEARCHRESULT CSR
	join SEARCHRESULTS SR on (SR.PRIORARTID = CSR.PRIORARTID)
	left join TABLECODES TC on (TC.TABLECODE = CSR.STATUS)
	left join COUNTRY CR	on (CR.COUNTRYCODE = SR.COUNTRYCODE)
	left join COUNTRY CI	on (CI.COUNTRYCODE = SR.ISSUINGCOUNTRY)
	where CSR.CASEID = @pnCaseKey
	group by CSR.CASEID, CSR.PRIORARTID,
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
		coalesce(" +
			dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'SR',@sLookupCulture,@pbCalledFromCentura) +",SR.PUBLICATION),
		coalesce(" +
			dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','TITLE',null,'SR',@sLookupCulture,@pbCalledFromCentura) + "," +
			dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','CITATION',null,'SR',@sLookupCulture,@pbCalledFromCentura) + "," +
			dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'SR',@sLookupCulture,@pbCalledFromCentura) +"),
		SR.ISSOURCEDOCUMENT,
		CSR.CASEFIRSTLINKEDTO,
		case when SR.IMPORTEDFROM = 'DiscoverEvidenceFinder' THEN SR.CORRELATIONID ELSE null END	
	Order by CountryName, Publication, OfficialNumber"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
	Set @pnRowCount = @@Rowcount
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin
	Select  null	as RowKey,
		null	as CaseKey,
		null	as CountryName,		
		null	as OfficialNumber,
		null	as IssuedDate,
		null	as ReceivedDate,
		null	as PublicationDate,
		null	as PriorityDate,
		null	as Publication,
		null	as IssuingCountryName,
		null 	as StatusKey,
		null	as StatusDescription,
		null	as UpdatedDate,
		null	as IsInherited
	where 1=0

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListSearchResult to public
GO
