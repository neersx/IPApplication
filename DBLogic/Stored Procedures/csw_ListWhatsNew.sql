-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListWhatsNew
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListWhatsNew]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListWhatsNew.'
	Drop procedure [dbo].[csw_ListWhatsNew]
	Print '**** Creating Stored Procedure dbo.csw_ListWhatsNew...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListWhatsNew
(
	@pnRowCountCases	int		= null output, 
	@pnRowCountEvents	int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPeriod		smallint	= null,		
	@psPeriodType		nvarchar(1)	= null, 
	@psNameTypeKey 		nvarchar(3)   	= 'EMP',	-- the name type relationships that are valid for staff.  
	@psImportanceLevel	nvarchar(2) 	= null,		-- the events with an importance level greater than or equal to the value selected. 
	@pbCalledFromCentura	bit		= 0	
)
as
-- PROCEDURE:	csw_ListWhatsNew
-- VERSION:	19
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events that have occurred recently for internal user.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 30 Mar 2004  TM	RFC951	1	Procedure created
-- 07 Apr 2004	TM	RFC1321	2	Pass IsExtermalUser = 0 instead of 1 to all the 'Filter User' functions.
-- 23 Apr 2004	TM	RFC1348	3	Use Internal Description instead of External for Case Status and Case 
--					Renewal Status
-- 16 Jul 2004	TM	RFC1325	4	Add a new FileLocationDescription field to the Case result set.
-- 01 Sep 2004	TM	RFC1732	5	Return a single Event and Official Number combination. Choose the number 
--					type and official number that match the following criteria: 1) Official 
--					number exists, 2) Number type with minimum DisplayPriority.
-- 02 Sep 2004	TM	RFC1732	5	Implement Mike's feedback.
-- 02 Sep 2004	JEK	RFC1377	6	Pass new Centura parameter to fn_WrapQuotes
-- 09 Sep 2004	JEK	RFC886	7	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 Sep 2004	TM	RFC886	8	Implement translation.
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Apr 2007	SW	RFC4345	10	Exclude entries that relate to Draft Cases.
-- 30 May 2007	SW	RFC4345	11	Define Draft Cases as ACTUALCASETYPE IS NULL
-- 12 Dec 2008	AT	RFC7365	12	Added date to Case Type filter for license check.
-- 17 Sep 2010	MF	RFC9777	13	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 29 Apr 2014  SW      R32796  14      Added left join on OpenAction when Case Data result set is retrieved to align it with 
--                                      Query executed when Case Event data result set is retrieved.
-- 25 Sep 2014	MF	R39651	15	Improve performance problem caused by slow access against VALIDPROPERTY table.
-- 10 Dec 2014	LP	R40437	16	Remove second result set, which is now handled via csw_ListWhatsNewEvents (see RFC4887).
-- 10 Nov 2015	KR	R53910	17	Adjust formatted names logic (DR-15543)    
-- 17 May 2016	MF	13471	18	Apply ethical wall rules to the Cases being returned for the current user. 
-- 07 Sep 2018	AV	74738	19	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare	@sFromDate		nchar(11)
Declare @dtToday		datetime

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @dtToday = getdate()

Set	@ErrorCode=0
Set 	@pnRowCountCases=0
Set 	@pnRowCountEvents=0

If @pnPeriod is null
	Set @pnPeriod=1

If @psPeriodType is null
or @psPeriodType not in ('D','W','M','Y')
	Set @psPeriodType='W'

-- Calculate the starting date range

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFromDate=
		CASE @psPeriodType
			WHEN('D') THEN convert(varchar, dateadd(day,   -1*@pnPeriod, getdate()),112)
			WHEN('W') THEN convert(varchar, dateadd(week,  -1*@pnPeriod, getdate()),112)
			WHEN('M') THEN convert(varchar, dateadd(month, -1*@pnPeriod, getdate()),112)
			WHEN('Y') THEN convert(varchar, dateadd(year,  -1*@pnPeriod, getdate()),112)
		END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sFromDate	nchar(11)	OUTPUT,
				  @psPeriodType	nchar(1),
				  @pnPeriod	smallint',
				  @sFromDate   =@sFromDate	OUTPUT,
				  @psPeriodType=@psPeriodType,
				  @pnPeriod    =@pnPeriod
End

-- A separate result set is required for the Cases that have events within the date
-- range as well as a separate result set to the actual Events themselves.
-- Two separate queries allow to use sp_executesql and more efficient than loading 
-- a table variable with a single result and then SELECTing from the table variable.  
-- (Table variable cannot be used with sp_executesql unless that table variable is declared 
-- inside the executed SQL string).

-- Get the Cases that have Events that have occurred within the date range as long as 
-- the user has access to the Case Type
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	-----------------------------------------------
	-- RFC39651 CTE included to improve performance
	-----------------------------------------------
	With PropertyDescription (COUNTRYCODE, PROPERTYTYPE, PROPERTYNAME)
	as (Select distinct CT.COUNTRYCODE, P.PROPERTYTYPE, VP.PROPERTYNAME
	    from COUNTRY CT
	    cross join PROPERTYTYPE P
	    join VALIDPROPERTY VP on (VP.PROPERTYTYPE=P.PROPERTYTYPE)
	    where VP.COUNTRYCODE =(SELECT MIN(VP1.COUNTRYCODE)
	                           from VALIDPROPERTY VP1 
	                           where VP1.PROPERTYTYPE=P.PROPERTYTYPE
	                           and VP1.COUNTRYCODE in (CT.COUNTRYCODE, 'ZZZ'))
	    )
	Select	distinct
		C.CASEID 		as CaseKey,		
		C.IRN 			as CaseReference,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as InstructorName,
		N.NAMECODE		as InstructorNameCode,
		CNI.NAMENO 		as InstructorNameKey,
		"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+
			 	      " as Title,		
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+
			 	      " as CaseStatusDescription,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)+
			 	      "	as RenewalStatusDescription,
		C.CASETYPE		as CaseType,
		FCT.CASETYPEDESC 	as CaseTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+
			 	      " as PropertyTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+
			 	      " as CountryName,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TL',@sLookupCulture,@pbCalledFromCentura)+
			 	      " as FileLocationDescription
	from dbo.fn_CasesEthicalWall(@pnUserIdentityId) C	
	     join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura, @dtToday) FCT
					on (FCT.CASETYPE = C.CASETYPE)
	     join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	     join CASETYPE CTYPE	on (CTYPE.CASETYPE = C.CASETYPE
					and CTYPE.ACTUALCASETYPE IS NULL)
	     join CASEEVENT CE		on (CE.CASEID=C.CASEID
					and CE.EVENTDATE is not null
					and CE.OCCURREDFLAG between 1 and 8)
	     join PropertyDescription VP on(VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=C.COUNTRYCODE)
	     join EVENTS E		on (E.EVENTNO=CE.EVENTNO)
	     left join OPENACTION OA	on (OA.CASEID=CE.CASEID
					and OA.ACTION=E.CONTROLLINGACTION
					and OA.CYCLE=(	select max(OA1.CYCLE)
							from OPENACTION OA1
							where OA1.CASEID=OA.CASEID
							and OA1.ACTION=OA.ACTION))
	left join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO
					and EC.CRITERIANO=isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA))
	-- Show Instructor only if current user has access to the 'I' name type.
	left join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura) CNIF 
					on (CNIF.NAMETYPE='I')
	-- There is only one Instrucgtor pure Case so there is no need to choose min(SEQUENCE): 
	left Join CASENAME CNI		on (CNI.CASEID=C.CASEID
                         		and CNI.NAMETYPE=CNIF.NAMETYPE
                         		and(CNI.EXPIRYDATE is null or CNI.EXPIRYDATE>getdate()))                         							
	left join NAME N		on (N.NAMENO = CNI.NAMENO)
	left join PROPERTY P		on (P.CASEID=C.CASEID)
	left join STATUS S		on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS R		on (R.STATUSCODE=P.RENEWALSTATUS)	
	left join CASELOCATION CL	on (CL.CASEID=C.CASEID
					and CL.WHENMOVED=(select max(WHENMOVED)
							  from CASELOCATION CL1
							  where CL1.CASEID=CL.CASEID))
	left join TABLECODES TL		on (TL.TABLECODE=CL.FILELOCATION)
	Where CE.EVENTDATE between @sFromDate and getdate()
	-- Filter my Cases for me as for an Emlpoyee (or Signatory, or other relationships configured at the site): 
	and exists
	(Select * 
 	 from CASENAME CN
	 join USERIDENTITY UI		on (UI.NAMENO = CN.NAMENO
				        and UI.IDENTITYID = @pnUserIdentityId)
 	 join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,0,@pbCalledFromCentura) FUN 
					on (FUN.NAMETYPE=CN.NAMETYPE)	
	 where CN.NAMETYPE   = " + dbo.fn_WrapQuotes(@psNameTypeKey,0,0) + "
	 and  (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE > getdate())
	 and   CN.CASEID = C.CASEID)"

	If @psImportanceLevel is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + "	and ISNULL(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL) >= '"+@psImportanceLevel+"'" + char(10)
	End	
	
	Set @sSQLString = @sSQLString + char(10) + "	order by C.IRN"

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit,
				  @sFromDate		nchar(11),
				  @psNameTypeKey	nvarchar(3),
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura,
				  @sFromDate       	= @sFromDate,
				  @psNameTypeKey	= @psNameTypeKey,
				  @dtToday		= @dtToday

	Set @pnRowCountCases=@@Rowcount
End

Return @ErrorCode
GO

Grant execute on dbo.csw_ListWhatsNew to public
GO
