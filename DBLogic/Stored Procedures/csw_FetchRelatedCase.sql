-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchRelatedCase.'
	Drop procedure [dbo].[csw_FetchRelatedCase]
End
Print '**** Creating Stored Procedure dbo.csw_FetchRelatedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_FetchRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchRelatedCase
-- VERSION:	17
-- DESCRIPTION:	Lists all modifiable columns from the RelatedCase table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 29 Nov 2005	TM	RFC3204	2	Update prototype to reflect the new design.
-- 30 Nov 2005	TM	RFC3204	3	Improve sorting.
-- 08 Dec 2005	TM	RFC3204	4	Add EventKey and removed EventDefinition.
-- 15 Dec 2005	TM	RFC3204	5	Add new IsExternalCase column.
-- 06 Jan 2006	TM	RFC3375	6	Modify the population of the OfficialNumber column to use Application No 
--					instead of CURRENTOFFICIALNO for internal related cases.
-- 10 Jan 2006	TM	RFC3375	7	If Application Number does not exists then use Current Official Number
--					to populate OfficialNumber column.
-- 17 Jan 2006	TM	RFC3375	8	For the OfficialNumber, use the following code:
--					coalesce(OFFICIALNUMBERS.OFFICIALNUMBER, CASES.CURRENTOFFICIALNO, 
--					RELATEDCASE.OFFICIALNUMBER).
-- 30 Aug 2006	AU	RFC4062	9	Check EARLIEST PRIORITY site control before returning application number as
--					OfficialNumber
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	11	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 15 Dec 2009	PS	RFC5607 12	Add Title coulm in the result set.
-- 17 Sep 2010	MF	RFC9777	13	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 24 Oct 2011	ASH	R11460 14	Cast integer columns as nvarchar(11) data type.
-- 09 Dec 2013	vql	R28149	15	Configure Classes Field in Screen Designer.
-- 02 Jan 2014  DV	R27003	16	Return LOGDATETIMESTAMP column
-- 28 Jan 2014  MS      R100847 17      Return Classes in the result set


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @bSortByDate	bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bSortByDate	= 0

-- If the Related Cases Sort Order site control = ‘DATE’, sort by EventDate.  
-- Otherwise there should be no sorting to ensure that the rows are returned 
-- in the order of entry
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @bSortByDate = 1
	from   SITECONTROL SC	
	where (SC.CONTROLID = 'Related Cases Sort Order'
	and upper(SC.COLCHARACTER) = 'DATE')"	

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@bSortByDate		bit		OUTPUT',
					@bSortByDate		= @bSortByDate	OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  DISTINCT
		CAST(RC.CASEID 		as nvarchar(11))+'^'+
		CAST(RC.RELATIONSHIPNO 	as nvarchar(10))
					as RowKey,
		RC.CASEID		as CaseKey,
		RC.RELATIONSHIPNO 	as [Sequence],							
		RC.RELATIONSHIP		as RelationshipCode,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
				    + " as RelationshipDescription,
		CASE 	WHEN RC.RELATEDCASEID is null 
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END			as IsExternalCase,
		CASE 	WHEN RC.RELATEDCASEID is null 
			THEN RC.TITLE
			ELSE"+char(10)+
		dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C2',@sLookupCulture,@pbCalledFromCentura)+char(10)+
		"END as Title,
		RC.RELATEDCASEID	as RelatedCaseKey,
		C2.IRN			as RelatedCaseReference,
		COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
					as OfficialNumber,
		ISNULL(C2.COUNTRYCODE, RC.COUNTRYCODE)
					as CountryCode,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNTR',@sLookupCulture,@pbCalledFromCentura)
				    + " as CountryName,
		ISNULL(CE.EVENTDATE, RC.PRIORITYDATE)
					as EventDate,
		isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO) as EventKey,
		COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
					as EventDescription,
		RC.CYCLE		as Cycle,		
                case 
                  when RC.RELATEDCASEID is not null then C2.LOCALCLASSES
                  else RC.CLASS
                end                     as Classes,
		RC.LOGDATETIMESTAMP     as LastModifiedDate
	from RELATEDCASE RC
	join CASERELATION CR		on (CR.RELATIONSHIP = RC.RELATIONSHIP)
	left join CASES C2		on (C2.CASEID = RC.RELATEDCASEID)
	left join COUNTRY CNTR		on (CNTR.COUNTRYCODE = ISNULL(C2.COUNTRYCODE, RC.COUNTRYCODE))
	left join CASEEVENT CE		on (CE.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
					and CE.CYCLE = 1
					and CE.CASEID = RC.RELATEDCASEID)
	left join EVENTS E 		on (E.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO))
	left join OPENACTION OA		on (OA.CASEID = CE.CASEID
					and OA.ACTION = E.CONTROLLINGACTION)
	left join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO   =CE.EVENTNO)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'Earliest Priority')
	left join OFFICIALNUMBERS O 	on (O.CASEID = RC.RELATEDCASEID
					and O.NUMBERTYPE = N'A'  
					and O.ISCURRENT = 1
					and RC.RELATIONSHIP = SC.COLCHARACTER)
	where RC.CASEID = @pnCaseKey
	and   CR.SHOWFLAG = 1"+
	CASE 	WHEN @bSortByDate = 1
		THEN +CHAR(10)+"order by EventDate, RelationshipDescription, RelatedCaseReference, OfficialNumber"
	END
		
	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey		int',
					@pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchRelatedCase to public
GO