-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseExceptions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ListCaseExceptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ListCaseExceptions.'
	drop procedure dbo.cs_ListCaseExceptions
end
print '**** Creating procedure dbo.cs_ListCaseExceptions...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_ListCaseExceptions
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psGlobalTempTable		nvarchar(32)	= null, -- optional name of temporary table of CASEIDs to be reported on.
	@pbCPACasesOnly			tinyint		= 0,	-- Report names tagged as CPA clients
	@pbMissingAgent			tinyint		= 0,
	@pbMissingApplicationDetails	tinyint		= 0,
	@pbMissingGrantDetails		tinyint		= 0,
	@pbMissingPublicationDetails	tinyint		= 0,
	@pbMissingPriorityDetails	tinyint		= 0,
	@pbMissingEntitySize		tinyint		= 0,
	@pbMissingNumberOfClaims	tinyint		= 0,
	@pbMissingNumberOfDesigns	tinyint		= 0,
	@pbInvalidDateSequence		tinyint		= 0,
	@pbInvalidNumberFormat		tinyint		= 0,
	@pbOrderByErrorMessage		tinyint		= 0,	-- Order by ErrorMessage, PropertyType, IRN when ON otherwise PropertyType, IRN, ErrorMessage
	@pbDuplicateOfficialNumber	tinyint		= 0
	
AS
-- PROCEDURE :	cs_ListCaseExceptions
-- VERSION :	14
-- DESCRIPTION:	Report on data exceptions associated with Cases
--		The exceptions to check are :
--			Missing Agent Details
--			Missing Application Number and/or Application Date
--			Missing Registration Number and/or Registration Date
--			Missing Publication Number and/or Publication Date
--			Missing Priority Number and/or Priority Date
--			Missing Entity Size
--			Missing Number of Claims
--			Missing Number of Designs
--			Invalid Date Sequence
--			Invalid Official Number Format
--			Duplicate Official Number
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Jul 2002	MF			Procedure created
-- 03 Apr 2003	MF	8607		Restructure SQL on Event exceptions to improve performance.
-- 25 Jul 2003	MF	8988	3	If Event validation rules have been defined in the DATESLOGIC
--					table then use these rules rather than the hardcoded validations.
-- 31/07/2003	MF	6367	4	Allow a user defined stored procedure to be called as an additional
--					validation step.
-- 16 Jan 2004	MF	9621 	5	Increase EventDescription to 100 characters.
-- 05 Aug 2004	AB	8035	6	Add collate database_default to temp table definitions
-- 09 Jul 2006	MF	13327	7	New option to report when the same official number has been
--					used on more than one Case of the same CaseType, PropertyType & Country
-- 01 Feb 2007	PY	14224	8	T.IRN referenced in @sOrderBy, changed to 'C.IRN'
-- 29 May 2007	MF	14832	9	Increase the size of the IRN and COMPARISONEVENT columns in temp table.
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 16 Jun 2009  vql	13327	11	Provide an option within the exception reports to show duplicate official number (fix).
-- 24 Jul 2009	MF	16548	12	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 08 Sep 2010	MF	RFC9762	13	Refinement of exception tests. In particular test on existence of EVENTDATE and not just CASEEVENT row.
-- 19 May 2020	DL	DR-58943 14	Ability to enter up to 3 characters for Number type code via client server	

	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	-- We will need a unique set of Case characteristics for each debtor that potentially
	-- could have different fee calcualtions associated with them.

	create table #TEMPCASEEXCEPTIONS
			(	CASEID			int		not null,
				ERRORMESSAGE		nvarchar(255)	collate database_default null,
				NUMBERTYPE		nvarchar(3)	collate database_default null,
				OFFICIALNUMBER		nvarchar(36)	collate database_default null
			)

	-- A table is required to hold the details of any Event validation errors
	create table #TEMPDATEVALIDATIONERRORS (
			PROPERTYTYPE		nchar(1) 	collate database_default ,
			COUNTRYCODE		nvarchar(3)	collate database_default null,
			IRN			nvarchar(30)	collate database_default null,
			EVENTNO			int		null,
			CYCLE			smallint	null,
			EVENTDESCRIPTION	nvarchar(100)	collate database_default null,
			DATETOCOMPARE           datetime	null,
			COMPARISONEVENT		nvarchar(100)	collate database_default null,
			COMPARISONDATE		datetime	null,
			DISPLAYERRORFLAG	smallint	null,
			ERRORMESSAGE		nvarchar(255)	collate database_default NULL
			)



	DECLARE	@ErrorCode		int,
		@sSQLString		nvarchar(4000),
		@sSelect		nvarchar(2000),
		@sFrom			nvarchar(1000),
		@sFrom2			nvarchar(3000),
		@sWhere			nvarchar(1000),
		@sWhere2		nvarchar(3000),
		@sOrderBy		nvarchar(100),
		@sCurrentRow		nvarchar(31)

	-- Variables required for the Official number validation
	
	DECLARE	@nPatternError		int,
		@sErrorMessage		nvarchar(254),
		@nWarningFlag		tinyint,
		@nCaseId		int,
		@sNumberType		nvarchar(3),
		@sOfficialNumber	nvarchar(36)
	
	set @ErrorCode=0

	-- If no temporary table has been passed as a parameter then use CASES
	-- as the main table
	
	If @psGlobalTempTable is null
		set @sFrom='From CASES C'
	else
		set @sFrom='From '+@psGlobalTempTable+' T'+char(10)+
			   'join CASES C on (C.CASEID=T.CASEID)'

	-- Initialise the WHERE clause to get the Cases to be reported on.

	Set @sWhere	="Where C.CASETYPE='A'"

	-- Construct the WHERE clause depending upon the parameters passed.

	-- Restrict to only Cases that are marked as CPA Reportable

	If @pbCPACasesOnly=1
	begin
		set @sWhere =@sWhere+char(10)+"and C.REPORTTOTHIRDPARTY=1"
	end


	-- MISSING AGENT
	-- Report on Cases with no Agent details.
	-- Only report on the Cases filed in a Country where this firm does not
	-- act directly.  This can be determined by the absence of a TableAttribute
	-- against the Country.

	If  @pbMissingAgent=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "Select C.CASEID,'Missing Agent'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              and S.LIVEFLAG=1)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and not exists"+char(10)+
				 "(select * from TABLEATTRIBUTES TA"+char(10)+
				 " where TA.PARENTTABLE='COUNTRY'"+char(10)+
				 " and   TA.GENERICKEY =C.COUNTRYCODE"+char(10)+
				 " and   TA.TABLECODE  =5002)"+char(10)+
				 "and not exists"+char(10)+
				 "(select * from CASENAME CN"+char(10)+
				 " where CN.CASEID=C.CASEID"+char(10)+
				 " and   CN.NAMETYPE='A'"+char(10)+
				 " and   CN.EXPIRYDATE is null)"
		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End


	-- MISSING APPLICATION DETAILS
	-- Report on Cases where there is an Application No but no date or vice versa.
	-- Also report on any Registered or CPA Reportable cases where the Application Details are missing.

	If  @pbMissingApplicationDetails=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID,"+char(10)+
				 "CASE WHEN ( O.CASEID is null and CE.CASEID is NULL) THEN 'Missing Application Date and Number'"+char(10)+
				 "     WHEN ( O.CASEID is null )                      THEN 'Missing Application Number'"+char(10)+
				 "     WHEN (CE.CASEID is null )                      THEN 'Missing Application Date'"+char(10)+
				 "End"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join NUMBERTYPES NT 		on (NT.NUMBERTYPE='A')"+char(10)+
				 "left join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				 "				and O.NUMBERTYPE=NT.NUMBERTYPE"+char(10)+
				 "				and O.ISCURRENT =1)"+char(10)+
				 "left join CASEEVENT CE	on (CE.CASEID=C.CASEID"+char(10)+
				 "				and CE.EVENTNO=NT.RELATEDEVENTNO"+char(10)+
				 "				and CE.EVENTDATE is not null)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and (  (O.CASEID is not null   and CE.CASEID is null)"+char(10)+
				 "     or(O.CASEID is null       and CE.CASEID is not null)"+char(10)+
				 "     or(S.REGISTEREDFLAG=1     and (O.CASEID is null or CE.CASEID is null))"+char(10)+
				 "     or(C.REPORTTOTHIRDPARTY=1 and (O.CASEID is null or CE.CASEID is null)))"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING REGISTRATION DETAILS
	-- Report on Cases where there is a Registration No but no date or vice versa.
	-- Also report on any Case with a status indicating Registered where the Registered Details are missing.

	If  @pbMissingGrantDetails=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID,"+char(10)+
				 "CASE WHEN ( O.CASEID is null and CE.CASEID is NULL) THEN 'Missing Registration Date and Number'"+char(10)+
				 "     WHEN ( O.CASEID is null )                      THEN 'Missing Registration Number'"+char(10)+
				 "     WHEN (CE.CASEID is null )                      THEN 'Missing Registration Date'"+char(10)+
				 "End"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join NUMBERTYPES NT 		on (NT.NUMBERTYPE='R')"+char(10)+
				 "left join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				 "				and O.NUMBERTYPE=NT.NUMBERTYPE"+char(10)+
				 "				and O.ISCURRENT =1)"+char(10)+
				 "left join CASEEVENT CE	on (CE.CASEID=C.CASEID"+char(10)+
				 "				and CE.EVENTNO=NT.RELATEDEVENTNO"+char(10)+
				 "				and CE.EVENTDATE is not null)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and (  (O.CASEID is not null   and CE.CASEID is null)"+char(10)+
				 "     or(O.CASEID is null       and CE.CASEID is not null)"+char(10)+
				 "     or(S.REGISTEREDFLAG=1     and (O.CASEID is null or CE.CASEID is null))"+char(10)+
				 "     or(C.REPORTTOTHIRDPARTY=1 and (O.CASEID is null or CE.CASEID is null)))"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING PUBLICATION DETAILS
	-- Report on Cases where there is a Publication No but no date (do not do the reverse check).
	-- Only validate where the Country of the Case is flagged as requiring these details.
	-- Also report on any Registered cases (using status) where the Publication Details are missing.

	If  @pbMissingPublicationDetails=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID,"+char(10)+
				 "CASE WHEN ( O.CASEID is null and CE.CASEID is NULL) THEN 'Missing Publication Date and Number'"+char(10)+
				 "     WHEN ( O.CASEID is null )                      THEN 'Missing Publication Number'"+char(10)+
				 "     WHEN (CE.CASEID is null )                      THEN 'Missing Publication Date'"+char(10)+
				 "End"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join NUMBERTYPES NT 		on (NT.NUMBERTYPE='P')"+char(10)+
				 "join TABLEATTRIBUTES TA       on (TA.PARENTTABLE='COUNTRY'"+char(10)+
				 "                              and TA.GENERICKEY = C.COUNTRYCODE"+char(10)+
				 "                              and TA.TABLECODE=CASE C.PROPERTYTYPE WHEN('P') THEN 5003"+char(10)+
				 "                                                                   WHEN('U') THEN 5004"+char(10)+
				 "                                               END)"+char(10)+
				 "left join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				 "				and O.NUMBERTYPE=NT.NUMBERTYPE"+char(10)+
				 "				and O.ISCURRENT =1)"+char(10)+
				 "left join CASEEVENT CE	on (CE.CASEID=C.CASEID"+char(10)+
				 "				and CE.EVENTNO=NT.RELATEDEVENTNO"+char(10)+
				 "				and CE.EVENTDATE is not null)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and (  (O.CASEID is not null   and CE.CASEID is null)"+char(10)+
				 "     or(S.REGISTEREDFLAG=1     and CE.CASEID is null)"+char(10)+
				 "     or(C.REPORTTOTHIRDPARTY=1 and CE.CASEID is null))"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING PRIORITY DETAILS
	-- Report on Cases where the expected Priority details are missing.

	If  @pbMissingPriorityDetails=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID,"+char(10)+
				 "CASE WHEN (RC.CASEID is null and CE.CASEID is NULL) THEN 'Missing Priority Date and Number'"+char(10)+
				 "     WHEN (RC.CASEID is null )                      THEN 'Missing Priority Number'"+char(10)+
				 "     WHEN (CE.CASEID is null )                      THEN 'Missing Priority Date'"+char(10)+
				 "End"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join SITECONTROL SC		on (SC.CONTROLID='Earliest Priority')"+char(10)+
				 "join CASERELATION CR		on (CR.RELATIONSHIP=SC.COLCHARACTER)"+char(10)+
				 "join PROPERTY P               on (P.CASEID=C.CASEID)"+char(10)+
				 "left join APPLICATIONBASIS B  on (B.BASIS =P.BASIS)"+char(10)+
				 "left join RELATEDCASE RC	on (RC.CASEID=C.CASEID"+char(10)+
				 "				and RC.RELATIONSHIP=CR.RELATIONSHIP)"+char(10)+
				 "left join CASEEVENT CE	on (CE.CASEID=C.CASEID"+char(10)+
				 "				and CE.EVENTNO=isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)"+char(10)+
				"				and CE.EVENTDATE is not null)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and (B.CONVENTION=1 and (RC.CASEID is null or CE.CASEID is null))"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING ENTITY SIZE DETAILS
	-- Report on Cases where there is a requirement for an Entity Size but none has been recorded.

	If  @pbMissingEntitySize=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID, 'Entity size is required'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join TABLEATTRIBUTES TA       on (TA.PARENTTABLE='COUNTRY'"+char(10)+
				 "                              and TA.GENERICKEY = C.COUNTRYCODE"+char(10)+
				 "                              and TA.TABLECODE=5005)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and C.ENTITYSIZE is null"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING NUMBER OF CLAIMS
	-- Report on Cases where there is a requirement for the number of Claims to be recorded.

	If  @pbMissingNumberOfClaims=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID, 'Number of Claims is required'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join TABLEATTRIBUTES TA       on (TA.PARENTTABLE='COUNTRY'"+char(10)+
				 "                              and TA.GENERICKEY = C.COUNTRYCODE"+char(10)+
				 "                              and TA.TABLECODE=5006)"+char(10)+
				 "left join PROPERTY P          on (P.CASEID=C.CASEID)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and C.PROPERTYTYPE='P'"+char(10)+
				 "and P.NOOFCLAIMS is null"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- MISSING NUMBER OF DESIGNS
	-- Report on Cases where there is a requirement for the number of Designs to be recorded.

	If  @pbMissingNumberOfDesigns=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select C.CASEID, 'Number of Designs is required'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "join TABLEATTRIBUTES TA       on (TA.PARENTTABLE='COUNTRY'"+char(10)+
				 "                              and TA.GENERICKEY = C.COUNTRYCODE"+char(10)+
				 "                              and TA.TABLECODE=5007)"+char(10)+
				 "left join PROPERTY P          on (P.CASEID=C.CASEID)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and C.PROPERTYTYPE='D'"+char(10)+
				 "and P.NOOFCLAIMS is null"

		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- DUPLICATE OFFICIAL NUMBER
	-- Report on Cases where there are multiple Cases with the same Official Number
	-- that have the same CaseType, PropertyType and CountryCode

	If  @pbDuplicateOfficialNumber=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select distinct C.CASEID, 'Duplicate official number in this Case'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "left join PROPERTY P          on (P.CASEID=C.CASEID)"+char(10)+
				 "left join STATUS R 		on (R.STATUSCODE=C.STATUSCODE)"+char(10)+
				 "join NUMBERTYPES NT		on (NT.ISSUEDBYIPOFFICE=1)"+char(10)+
				 "join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				 "				and O.NUMBERTYPE=NT.NUMBERTYPE"+char(10)+
				 "				and O.ISCURRENT=1)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and isnull(R.LIVEFLAG,1)=1"+char(10)+
				 "and O.OFFICIALNUMBER in"+char(10)+
				 "(select OFFICIALNUMBER"+char(10)+
				 "from OFFICIALNUMBERS O1"+char(10)+
				 "where CASEID = C.CASEID"+char(10)+
				 "group by OFFICIALNUMBER"+char(10)+
				 "having count(OFFICIALNUMBER)>1"+char(10)+
				 ")"
		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If  @pbDuplicateOfficialNumber=1
	and @ErrorCode=0
	begin
		Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
				 "select distinct C.CASEID, 'Same official number on multiple Cases'"

		Set @sFrom2	=@sFrom+char(10)+
				 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "              		and S.LIVEFLAG=1)"+char(10)+
				 "left join PROPERTY P          on (P.CASEID=C.CASEID)"+char(10)+
				 "left join STATUS R 		on (R.STATUSCODE=C.STATUSCODE)"+char(10)+
				 "join NUMBERTYPES NT		on (NT.ISSUEDBYIPOFFICE=1)"+char(10)+
				 "join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				 "				and O.NUMBERTYPE=NT.NUMBERTYPE"+char(10)+
				 "				and O.ISCURRENT=1)"

		Set @sWhere2	=@sWhere+char(10)+
				 "and isnull(R.LIVEFLAG,1)=1"+char(10)+
				 "and O.OFFICIALNUMBER in"+char(10)+
				 "(select OFFICIALNUMBER"+char(10)+
				 "from OFFICIALNUMBERS O1"+char(10)+
				 "group by OFFICIALNUMBER"+char(10)+
				 "having count(OFFICIALNUMBER)>1"+char(10)+
				 ")"
		
		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString
	End


	-- INVALID DATE SEQUENCE
	-- Report on Cases where there is an illogical date progression for the major dates
	-- identified by the CPA pointers in Site Control.

	If  @pbInvalidDateSequence=1
	and @ErrorCode=0
	begin
		-- If specific user defined date logic has been defined then use these rules
		-- to validate the dates held against Cases otherwise use a number of hardcoded validation
		-- rules.
		If exists(select * from DATESLOGIC)
		Begin
			set @sSQLString="
			insert into #TEMPDATEVALIDATIONERRORS
			exec dbo.cs_GetCompareEventDates
				@pnRowCount=@pnRowCount OUTPUT,
				@psGlobalTempTable=@psGlobalTempTable"
			
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRowCount		int OUTPUT,
						  @psGlobalTempTable	nvarchar(32)',
						  @pnRowCount		OUTPUT,
						  @psGlobalTempTable

			-- If any rows are returned into the holding table then loade
			-- the #TEMPCASEEXCEPTIONS table.
			If @pnRowCount>0
			Begin
				set @sSQLString="
				insert into #TEMPCASEEXCEPTIONS(CASEID,ERRORMESSAGE)
				select C.CASEID,T.ERRORMESSAGE
				from #TEMPDATEVALIDATIONERRORS T
				join CASES C	on (C.IRN=T.IRN)"
	
				exec @ErrorCode=sp_executesql @sSQLString
			End
		End
		Else Begin
			Set @sSelect	="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE)"+char(10)+
					 "select C.CASEID, " + char(10)+
					 "       CASE WHEN(CE1.EVENTDATE>CE2.EVENTDATE or CE1.EVENTDATE>CE3.EVENTDATE or CE1.EVENTDATE>CE4.EVENTDATE or CE1.EVENTDATE>CE5.EVENTDATE or CE1.EVENTDATE>CE6.EVENTDATE or CE1.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - Priority Date'"+char(10)+
					 "            WHEN(CE2.EVENTDATE>CE3.EVENTDATE or CE2.EVENTDATE>CE4.EVENTDATE or CE2.EVENTDATE>CE5.EVENTDATE or CE2.EVENTDATE>CE6.EVENTDATE or CE2.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - Parent Date'"+char(10)+
					 "            WHEN(CE3.EVENTDATE>CE4.EVENTDATE or CE3.EVENTDATE>CE5.EVENTDATE or CE3.EVENTDATE>CE6.EVENTDATE or CE3.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - PCT Filing Date'"+char(10)+
					 "            WHEN(CE4.EVENTDATE>CE5.EVENTDATE or CE4.EVENTDATE>CE6.EVENTDATE or CE4.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - Application Filing'"+char(10)+
					 "            WHEN(CE5.EVENTDATE>CE6.EVENTDATE or CE5.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - Grant Date'"+char(10)+
					 "            WHEN(CE6.EVENTDATE>CE7.EVENTDATE) THEN 'Date Sequence Error - Publication Date'"+char(10)+
					 "       END"
	
			-- Note the unconventional use of derived tables has been done for performance reasons
			-- When the SQL was constructed with straight Left Joins on all of the tables performance 
			-- became slower and slower with each table pair added.  The derived table approach appears to
			-- fool the optimiser
	
			Set @sFrom2	=@sFrom+char(10)+
					 "join STATUS S 		on (S.STATUSCODE=C.STATUSCODE"+char(10)+
					 "              		and S.LIVEFLAG=1)"+char(10)++char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Priority') CE1	on CE1.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Parent') CE2		on CE2.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-PCT Filing') CE3	on CE3.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Filing') CE4		on CE4.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Registratn') CE5	on CE5.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Publication') CE6	on CE6.CASEID=C.CASEID"+char(10)+
					 "left join (	select CE.CASEID, CE.EVENTDATE"+char(10)+
					 "		from SITECONTROL S"+char(10)+
					 "		join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER"+char(10)+
					 "				  and CE.EVENTDATE is not null)"+char(10)+
					 "		where S.CONTROLID='CPA Date-Expiry') CE7	on CE7.CASEID=C.CASEID"
	
			Set @sWhere2	=@sWhere+char(10)+
					 "and ( (CE1.EVENTDATE>CE2.EVENTDATE or CE1.EVENTDATE>CE3.EVENTDATE or CE1.EVENTDATE>CE4.EVENTDATE or CE1.EVENTDATE>CE5.EVENTDATE or CE1.EVENTDATE>CE6.EVENTDATE or CE1.EVENTDATE>CE7.EVENTDATE)"+char(10)+
					 "    or(CE2.EVENTDATE>CE3.EVENTDATE or CE2.EVENTDATE>CE4.EVENTDATE or CE2.EVENTDATE>CE5.EVENTDATE or CE2.EVENTDATE>CE6.EVENTDATE or CE2.EVENTDATE>CE7.EVENTDATE)"+char(10)+
					 "    or(CE3.EVENTDATE>CE4.EVENTDATE or CE3.EVENTDATE>CE5.EVENTDATE or CE3.EVENTDATE>CE6.EVENTDATE or CE3.EVENTDATE>CE7.EVENTDATE)"+char(10)+
					 "    or(CE4.EVENTDATE>CE5.EVENTDATE or CE4.EVENTDATE>CE6.EVENTDATE or CE4.EVENTDATE>CE7.EVENTDATE)"+char(10)+
					 "    or(CE5.EVENTDATE>CE6.EVENTDATE or CE5.EVENTDATE>CE7.EVENTDATE)"+char(10)+
					 "    or(CE6.EVENTDATE>CE7.EVENTDATE) )"
			
			Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2
	
			exec @ErrorCode=sp_executesql @sSQLString
		End
	End

	-- INVALID OFFICIAL NUMBER FORMAT
	-- Report on Cases where any of its current official numbers fail the validation against
	-- a pattern previously defined for the Country, Property Type and Number Type.
	-- Note that this will require each row to be processed one at a time

	If  @pbInvalidNumberFormat=1
	and @ErrorCode=0
	begin
		-- Construct the SELECT to get the cases that have a validation
		-- pattern defined for the Number Type.

		Set @sSelect=	"select @sCurrentRowOUT=min(left( O.NUMBERTYPE + space(3), 3) +C.IRN)"					-- DR-58943 NUMBERTYPE can be upto 3 characters instead of 1

		Set @sFrom2 =	@sFrom+char(10)+
			 	"join OFFICIALNUMBERS O	on (O.CASEID=C.CASEID"+char(10)+
				"                       and O.ISCURRENT=1)"
		
		Set @sWhere2=	@sWhere+char(10)+
				"and exists"+char(10)+
				"(select * from VALIDATENUMBERS V"+char(10)+
				" where V.COUNTRYCODE=C.COUNTRYCODE"+char(10)+
				" and   V.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				" and   V.NUMBERTYPE  =O.NUMBERTYPE)"

		Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sCurrentRowOUT	nvarchar(31)	OUTPUT',
						  @sCurrentRowOUT=@sCurrentRow	OUTPUT

		-- Now loop through each row to validate it

		While @sCurrentRow is not null
		and   @ErrorCode=0
		begin

			-- Get the details to validate
			Set @sSQLString= "select @nCaseId        =max(O.CASEID),"+char(10)+
					 "       @sNumberType    =max(O.NUMBERTYPE),"+char(10)+
					 "       @sOfficialNumber=max(O.OFFICIALNUMBER)"+char(10)+
					 @sFrom2+char(10)+@sWhere2+char(10)+
					 "and C.IRN=substring(@sCurrentRow,4,30)"+char(10)+
					 "and O.NUMBERTYPE=rtrim(substring(@sCurrentRow,1,3))"				-- DR-58943 NUMBERTYPE can be upto 3 characters instead of 1

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseId         int			OUTPUT,
							  @sNumberType     nvarchar(3)		OUTPUT,
							  @sOfficialNumber nvarchar(36)		OUTPUT,
							  @sCurrentRow     nvarchar(31)',
							  @nCaseId        =@nCaseId		OUTPUT,
							  @sNumberType    =@sNumberType		OUTPUT,
							  @sOfficialNumber=@sOfficialNumber	OUTPUT,
							  @sCurrentRow    =@sCurrentRow

			-- Now perform the validation of the Official number

			If @ErrorCode=0
			begin
				exec @ErrorCode=dbo.cs_ValidateOfficialNumber	
							@pnPatternError  =@nPatternError OUTPUT,
							@psErrorMessage  =@sErrorMessage OUTPUT,
							@pnWarningFlag   =@nWarningFlag  OUTPUT,
							@pnCaseId        =@nCaseId,
							@psNumberType    =@sNumberType,
							@psOfficialNumber=@sOfficialNumber
			End

			-- If the Official Number is invalid insert a row to report
	
			If  @nPatternError <>0
			and @ErrorCode=0
			Begin
				Set @sSQLString="Insert into #TEMPCASEEXCEPTIONS(CASEID, ERRORMESSAGE, NUMBERTYPE, OFFICIALNUMBER)"+char(10)+
						"values("+convert(varchar,@nCaseId)+",'"+isnull(@sErrorMessage,'Official Number Validation Error')+"','"+@sNumberType+"','"+@sOfficialNumber+"')"
				
				exec @ErrorCode=sp_executesql @sSQLString

			End

			-- Now get the next Case and Official Number to check

			If @ErrorCode=0
			begin
				Set @sSQLString=@sSelect+char(10)+@sFrom2+char(10)+@sWhere2+char(10)+
						"and (left( O.NUMBERTYPE + space(3), 3)+C.IRN)>@sCurrentRow"			-- DR-58943 NUMBERTYPE can be upto 3 characters instead of 1

				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCurrentRowOUT	nvarchar(31)	OUTPUT,
								  @sCurrentRow		nvarchar(31)',
								  @sCurrentRowOUT=@sCurrentRow	OUTPUT,
								  @sCurrentRow   =@sCurrentRow
			End
		End -- While loop
	End -- Official Number Validation
		

	If @ErrorCode=0
	begin
		-- Set the sort order of the report

		If @pbOrderByErrorMessage=1
			Set @sOrderBy='Order by T.ERRORMESSAGE, C.PROPERTYTYPE, C.IRN'
		else
			Set @sOrderBy='Order by C.IRN, C.PROPERTYTYPE, T.ERRORMESSAGE'

		Set @sSQLString="
		select 	C.IRN		 as IRN,
			VP.PROPERTYNAME	 as PropertyName,
			CT.COUNTRY	 as Country,
			C.TITLE		 as Title,
			N.DESCRIPTION 	 as NumberType,
			T.OFFICIALNUMBER as OfficialNumber,
			S.INTERNALDESC	 as Status,
			T.ERRORMESSAGE	 as ErrorMessage
		from #TEMPCASEEXCEPTIONS T
		join CASES C		on (C.CASEID=T.CASEID)
		join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.PROPERTYTYPE=C.PROPERTYTYPE
								and   VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
		join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
		left join NUMBERTYPES N	on (N.NUMBERTYPE=T.NUMBERTYPE)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
		
		exec (@sSQLString+@sOrderBy)

		select  @pnRowCount=@@Rowcount,
			@ErrorCode=@@Error
	end

	RETURN @ErrorCode
go

grant execute on dbo.cs_ListCaseExceptions  to public
go

