-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListRelatedCase.'
	Drop procedure [dbo].[csw_ListRelatedCase]
End
Print '**** Creating Stored Procedure dbo.csw_ListRelatedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@pbIsExternalUser		bit,
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListRelatedCase
-- VERSION:	21
-- DESCRIPTION:	Lists all modifiable columns from the RelatedCase table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Dec 2005	TM		1	Procedure created
-- 09 Dec 2005	TM	RFC3254	2	Only return related cases with ShowFlag set 1.
-- 06 Jan 2006	TM	RFC3375	3	Modify the population of the CurrentOfficialNo column to use Application No 
--					instead of CURRENTOFFICIALNO for internal related cases.
-- 10 Jan 2006	TM	RFC3375	4	If Application Number does not exists then use Current Official Number
--					to populate CurrentOfficialNo column.
-- 17 Jan 2006	TM	RFC3375 5	For the CurrentOfficialNumber, use the following code:
--					coalesce(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
-- 20 Jan 2006	TM	RFC3254	6	Correct YourReference extraction logic.
-- 30 Aug 2006	AU	RFC4062	7	Correct YourReference extraction logic.
-- 27 Aug 2008	AT	RFC5712	8	Return CRM related information.
-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	10	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 15 Dec 2009	PS	RFC5607	11 	For External Related Cases RELATEDCASE.TITLE will be returned as Title.
-- 25 Aug 2010	LP	RFC9695	12	Apply Row Access Security when returning the related cases.
-- 17 Sep 2010	MF	RFC9777	13	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 29 Apr 2011	MF	RFC10535 14	Replace the StatusSummary with the full Status description of the related case.
-- 24 Oct 2011	ASH	R11460  15	Cast integer columns as nvarchar(11) data type.
-- 05 Dec 2013	vql	R28151  16	Return classes.
-- 02 Jan 2014  DV	R27003	17	Return LOGDATETIMESTAMP column
-- 10 Nov 2015	KR	R53910	18	Adjust formatted names logic (DR-15543)     
-- 25 May 2016 	SF	R60785	19	Include Country Code in result set
-- 31 May 2016	KR	R62274	20	Return official number with hyphen stripped
-- 07 Sep 2018	AV	74738	21	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @bSortByDate	bit

Declare @bIsCRMCaseType		bit

Declare @bHasRowAccessSecurity	bit	-- Indicates if Row Access Security exists for the user
Declare @nSecurityFlag		int	-- The security flag return via best fit
Declare @bUseOfficeSecurity	bit	-- Indicates if Row Access Security restricts by Case Office
Declare @sOfficeFilter		nvarchar(2000)
Declare @sRowSecurityFilter	nvarchar(max)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bSortByDate	= 0
Set @bHasRowAccessSecurity = 0	
Set @nSecurityFlag = 15		-- Set Security Flag to maximum row access level
Set @bUseOfficeSecurity = 0

if @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @bIsCRMCaseType = CT.CRMONLY
	from CASES C JOIN CASETYPE CT ON (CT.CASETYPE = C.CASETYPE)
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsCRMCaseType	bit output,
					@pnCaseKey		int',
					@bIsCRMCaseType		= @bIsCRMCaseType output,
					@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0
Begin
	Select @bHasRowAccessSecurity = 1,
	@bUseOfficeSecurity = ISNULL(SC.COLBOOLEAN, 0)
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	left join SITECONTROL SC WITH (NOLOCK) on (SC.CONTROLID = 'Row Security Uses Case Office')
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId
End

If @nErrorCode = 0 
and @bHasRowAccessSecurity = 1
Begin
	Set @sOfficeFilter = CASE when @bUseOfficeSecurity = 1 then    
								"left join CASENAME XCN 	on   XCN.CASEID = XC.CASEID
								 join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME
								 and (XRAD.OFFICE = XC.OFFICEID or   XRAD.OFFICE       is null)" 

				     	 		else	"left join TABLEATTRIBUTES XTA 	on (XTA.PARENTTABLE='CASES'
				           				and XTA.TABLETYPE=44
									and XTA.GENERICKEY=convert(varchar, XC.CASEID))
					   			 left join CASENAME XCN 	on XCN.CASEID = XC.CASEID
					   			 join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME
					   			 and (XRAD.OFFICE = XTA.TABLECODE or   XRAD.OFFICE       is null)"
	END 
	Set @sRowSecurityFilter = 
	" join (select Substring(
		(Select MAX (   CASE when XRAD.OFFICE       is null then '0' else '1' end +
				CASE when XRAD.CASETYPE     is null then '0' else '1' end +
				CASE when XRAD.PROPERTYTYPE is null then '0' else '1' end +				
				CASE when XRAD.SECURITYFLAG < 10    then '0' else ''  end +
				convert(nvarchar(2),XRAD.SECURITYFLAG)
			    )
			from IDENTITYROWACCESS XIA
			join CASES XC on XC.CASEID = @pnCaseKey 
			join USERIDENTITY XUI on XUI.IDENTITYID = XIA.IDENTITYID"
			+char(10)+ @sOfficeFilter +char(10)+	
			       "and (XRAD.CASETYPE     = XC.CASETYPE     or XRAD.CASETYPE     is null)
				and (XRAD.PROPERTYTYPE = XC.PROPERTYTYPE or XRAD.PROPERTYTYPE is null)				
				and  XRAD.RECORDTYPE = 'C')
			where XIA.IDENTITYID=@pnUserIdentityId
		),4,2) as SECURITYFLAG) SF on (SF.SECURITYFLAG > 0)"
End

if (@bIsCRMCaseType = 1)
Begin
	If @nErrorCode = 0
	and @pbIsExternalUser = 0
	Begin
Set @sSQLString = "
		Select 	RC.RELATEDCASEID	as CaseKey,
			null			as CurrentOfficialNumber,
			null			as EscapedCurrentOfficialNumber,
			C2.IRN			as CaseReference,
			null			as CountryName,
			null			as CountryCode,
			null			as Title,
			null 			as StatusSummary,
			"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
					    + " as RelationshipDescription,
			null			as EventDescription,
			null 			as EventDefinition,			
			null			as EventDate,						
			null			as Cycle,
			CAST(RC.CASEID as nvarchar(11))+'^'+CAST(RC.RELATIONSHIPNO as nvarchar(11)) 
						as RowKey,
			dbo.fn_FormatNameUsingNameNo(PRS.NAMENO, NULL)  as Prospect,
			PRS.NAMENO as ProspectNameKey,
			isnull(O.POTENTIALVALUE, O.POTENTIALVALUELOCAL)	as PotentialValue,
			CASE WHEN O.POTENTIALVALUE IS NULL THEN NULL ELSE O.POTENTIALVALCURRENCY END	as PotentialValCurrency,
			STATUS.DESCRIPTION		as StatusDescription,
			"+dbo.fn_SqlTranslatedColumn('OPPORTUNITY','NEXTSTEP',null,'O',
							@sLookupCulture,@pbCalledFromCentura)+
			" 		as NextStep,
			CE.EVENTDATE	as DateOfLastChange,
			null		as Classes,
			RC.LOGDATETIMESTAMP	as LastModifiedDate
		from RELATEDCASE RC
		join CASERELATION CR		on (CR.RELATIONSHIP = RC.RELATIONSHIP)
		left join CASES C2		on (C2.CASEID = RC.RELATEDCASEID)
		left join OPPORTUNITY O 	on (O.CASEID = C2.CASEID)
		left join 
			CASENAME CN ON (CN.CASEID = C2.CASEID
					and CN.NAMETYPE = '~PR')
		left join NAME PRS ON (PRS.NAMENO = CN.NAMENO)
		left join CASEEVENT CE on (CE.CASEID = C2.CASEID
						AND CE.EVENTNO = -14
						AND CE.CYCLE = 1)
		left join
			(SELECT CASEID, CRMCASESTATUS, TC.DESCRIPTION
			FROM CRMCASESTATUSHISTORY CSH
			JOIN (SELECT MAX(STATUSID) as STATUSID
				FROM CRMCASESTATUSHISTORY
				GROUP BY CASEID) MAXCSH ON MAXCSH.STATUSID = CSH.STATUSID
			JOIN TABLECODES TC ON TC.TABLECODE = CSH.CRMCASESTATUS)
			as STATUS on (STATUS.CASEID = C2.CASEID)" +
		CASE WHEN @bHasRowAccessSecurity = 1 THEN +char(10)+ @sRowSecurityFilter ELSE NULL END +char(10)+
		"where RC.CASEID = @pnCaseKey
		and   CR.SHOWFLAG = 1"+CHAR(10)+
		CASE 	WHEN @bSortByDate = 1
			THEN +CHAR(10)+"order by CaseReference"
		END
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					@pnUserIdentityId	int',
					@pnCaseKey		= @pnCaseKey,
					@pnUserIdentityId	= @pnUserIdentityId
	End
End
Else
Begin
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
and @pbIsExternalUser = 0
Begin
	Set @sSQLString = "
	Select 	DISTINCT
		RC.RELATEDCASEID	as CaseKey,
		COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
					as CurrentOfficialNumber,
		Replace(COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER), '-', '')
					as EscapedCurrentOfficialNumber,
		C2.IRN			as CaseReference,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNTR',@sLookupCulture,@pbCalledFromCentura)
				    + " as CountryName,
		CNTR.COUNTRYCODE as CountryCode,
		CASE WHEN RC.RELATEDCASEID is null
		THEN RC.TITLE
		ELSE"+char(10)+
		dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C2',@sLookupCulture,@pbCalledFromCentura)+char(10)+
		"END as Title,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
				    +"	as StatusSummary,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
				    + " as RelationshipDescription,
		COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
					as EventDescription,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)
			 	    +" as EventDefinition,			
		ISNULL(CE.EVENTDATE, RC.PRIORITYDATE)
					as EventDate,						
		RC.CYCLE		as Cycle,
		CAST(RC.CASEID 		as nvarchar(11))+'^'+
		CAST(RC.RELATIONSHIPNO 	as nvarchar(11))
						as RowKey,
			null	as Prospect,
			null	as ProspectNameKey,
			null	as PotentialValue,
			null	as PotentialValCurrency,
			null	as StatusDescription,
			null	as NextStep,
			null	as DateOfLastChange,
			case 
				when RC.RELATEDCASEID is not null then C2.LOCALCLASSES
				else RC.CLASS
			end as Classes,
			RC.LOGDATETIMESTAMP	as LastModifiedDate
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
	left join STATUS ST 		on (ST.STATUSCODE = C2.STATUSCODE)

	left join SITECONTROL SC 	on (SC.CONTROLID = 'Earliest Priority')
	left join OFFICIALNUMBERS O	on (O.CASEID = RC.RELATEDCASEID
					and O.NUMBERTYPE = N'A'  
					and O.ISCURRENT = 1
					and RC.RELATIONSHIP = SC.COLCHARACTER)"+
	CASE WHEN @bHasRowAccessSecurity = 1 THEN +char(10)+ @sRowSecurityFilter ELSE NULL END +char(10)+
	"where RC.CASEID = @pnCaseKey
	and   CR.SHOWFLAG = 1"+CHAR(10)+
	CASE 	WHEN @bSortByDate = 1
		THEN +CHAR(10)+"order by EventDate, RelationshipDescription, CaseReference, CurrentOfficialNumber"
	END
		
	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey		int,
					@pnUserIdentityId	int',
					@pnCaseKey		= @pnCaseKey,
					@pnUserIdentityId	= @pnUserIdentityId
End
Else If @nErrorCode = 0
and @pbIsExternalUser = 1
Begin
	Set @sSQLString = "
	Select 	RC.RELATEDCASEID	as CaseKey,
		COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
					as CurrentOfficialNumber,
		Replace(COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER), '-', '')
					as EscapedCurrentOfficialNumber,
		FC2.CLIENTREFERENCENO	as YourReference,
		C2.IRN			as OurReference,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNTR',@sLookupCulture,@pbCalledFromCentura)
				    + " as CountryName,
		CNTR.COUNTRYCODE as CountryCode,
		CASE WHEN RC.RELATEDCASEID is null
		THEN RC.TITLE
		ELSE"+char(10)+
		dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C2',@sLookupCulture,@pbCalledFromCentura)+char(10)+
		"END as Title,
		"+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
				    +"	as StatusSummary,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
				    + " as RelationshipDescription,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
				    + " as EventDescription,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)
			 	    +" as EventDefinition,			
		ISNULL(CE.EVENTDATE, RC.PRIORITYDATE)
					as EventDate,						
		CAST(RC.CASEID 		as nvarchar(11))+'^'+
		CAST(RC.RELATIONSHIPNO 	as nvarchar(11))
						as RowKey,
			null	as Prospect,
			null	as ProspectNameKey,
			null	as PotentialValue,
			null	as PotentialValCurrency,
			null	as StatusDescription,
			null	as NextStep,
			null	as DateOfLastChange,
			case 
				when RC.RELATEDCASEID is not null then C2.LOCALCLASSES
				else RC.CLASS
			end as Classes,
			RC.LOGDATETIMESTAMP	as LastModifiedDate
	from RELATEDCASE RC
	join fn_FilterUserCases(@pnUserIdentityId, 1, @pnCaseKey) FC	
					on (FC.CASEID = @pnCaseKey)
	join CASERELATION CR		on (CR.RELATIONSHIP = RC.RELATIONSHIP)
	left join CASES C2		on (C2.CASEID = RC.RELATEDCASEID)
	left join COUNTRY CNTR		on (CNTR.COUNTRYCODE = ISNULL(C2.COUNTRYCODE, RC.COUNTRYCODE))
	left join CASEEVENT CE		on (CE.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
					and CE.CYCLE = 1
					and CE.CASEID = RC.RELATEDCASEID)
	left join EVENTS E 		on (E.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO))
	left join STATUS ST 		on (ST.STATUSCODE = C2.STATUSCODE)
	left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FC2	
					on (FC2.CASEID = C2.CASEID)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'Earliest Priority')
	left join OFFICIALNUMBERS O	on (O.CASEID = RC.RELATEDCASEID
					and O.NUMBERTYPE = N'A'  
					and O.ISCURRENT = 1
					and RC.RELATIONSHIP = SC.COLCHARACTER)" +
	CASE WHEN @bHasRowAccessSecurity = 1 THEN +char(10)+ @sRowSecurityFilter ELSE NULL END +char(10)+
	"where RC.CASEID = @pnCaseKey	
	and   CR.SHOWFLAG = 1
	and   (FC2.CASEID = C2.CASEID or C2.CASEID is null)"+
	CASE 	WHEN @bSortByDate = 1
		THEN +CHAR(10)+"order by EventDate, RelationshipDescription, YourReference, CurrentOfficialNumber"
	END
		
	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey		int,
					@pnUserIdentityId	int',
					@pnCaseKey		= @pnCaseKey,
					@pnUserIdentityId	= @pnUserIdentityId
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListRelatedCase to public
GO