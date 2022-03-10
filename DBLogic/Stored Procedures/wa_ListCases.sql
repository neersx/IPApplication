-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCases'
	drop procedure [dbo].[wa_ListCases]
end
print '**** Creating procedure dbo.wa_ListCases...'
print ''
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListCases]
	@iRowCount		int output, 		-- the number of rows available 
	@iPage			int,
	@iPageSize		int,
	@sAnySearch 		varchar(254) = NULL,	-- search through any of the important fields
	-- other search criteria to include
	@sIrn 			varchar(20) = NULL,
	@sOfficialNo 		varchar(36) = NULL,
	@nNameNo	 	int	    = NULL,
	@sName			varchar(20) = NULL,	-- Find Cases linked to any Name that matches this parameter
	@sNameType	 	varchar(20) = NULL,
	@sPropertyType 		varchar(20) = NULL,
	@sFamily	 	varchar(20) = NULL,
	@sCountry	 	varchar(20) = NULL,
	@sKeyword	 	varchar(20) = NULL,
	@sTitle		 	varchar(254)= NULL,
	@nStatus	 	int         = NULL,
	@nEvent		 	int 	    = NULL,
	@sFromEventDate		varchar(20) = NULL,
	@sToEventDate		varchar(20) = NULL,
	@bSearchByDueDate 	tinyint     = NULL,
	@sCaseType		varchar(20) = NULL,
	@sCaseCategory		varchar(20) = NULL,
	@sReferenceNo		varchar(80) = NULL,
	@bPending		tinyint     = NULL,
	@bRegistered		tinyint     = NULL,
	@bDead			tinyint     = NULL,
	@bRenewalFlag		tinyint     = NULL,

	-- Display Options
	@bSortByNextDueDate	tinyint     = NULL,
	@bDebug			bit	    = NULL

AS
-- PROCEDURE :	wa_ListCases
-- VERSION :	17
-- DESCRIPTION:	Constructs a SELECT statement based on the parameters passed and returns
--		a list of Cases after executing the SELECT.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	MF			Procedure created
-- 28/07/2001	MF			Change SELECT to improve performance when external user doing an Any Search.
--					Change SELECT to restrict external user by Name Types.
-- 31/07/2001	MF			Remove the search of Client Reference from Any Search to improve performance.
-- 02/08/2001	MF			Correct error.  If ReferenceNo is not being used as a search criteria then 
--					get the client reference once you have the cases to be displayed as a page.
-- 14/08/2001	MF			Allow an option to sort the returned rows by the date of the next due date also
--					return the Event Description and date when any of these date functions are required.
-- 16/08/2001	MF			Allow all rows to be returned if @iPageSize is zero.
--					Allow a NAME to be passed as a parameter and return cases that are linked to the Name
-- 17/08/2001	MF			Make the Any Search case insensitive
-- 20/08/2001	MF			Correct error when Any Search is used return NULLs for EventDate, Criteirano and EventNo.
-- 21/08/2001	MF			Allow 4 new search variables: @bPending, @bRegistered, @bDead and @bRenewalFlag.
--					Return a new column RENEWALSTATUS.
--					Change the column InternalDesc to CASESTATUS and change the content depending on 
--					if the user is external or internal.
-- 23/08/2001	MF			Increase the size of @sWhere to avoid truncation of generated Select.
--					Create a new generic status column called LIVEORDEAD that returns "Pending; 
--					Registered or Dead".
-- 27/08/2001	MF			Add CaseCategory as a selection criteria
-- 31/08/2001	MF			Found a way to get the row count back using sp_executesql without needing a
--					temporary table.
-- 26/09/2001	MF			Add row level security checks.
-- 05/10/2001	MF			When searching for cases by a Name, NameNo or Nametype the EXPIRYDATE against
--					the CASENAME must be null.
-- 24/11/2001	MF			The final select that returns the data was not returning the LIVEORDEAD and 
--					the EVENT details when the Client's Reference was in the selection criteria.
-- 25/11/2001	MF	7231		Restrict the Events displayed to any restriction of Action that may exist for 
--					the user.  Due Date searches should only consider events that belong to an
--					Open Action.
-- 04/12/2001	MF	7261		Change 'Client Action' and 'Enquiry Action' to 'Client PublishAction' and
--					'Publish Action' respectively.
-- 31/03/2003	JB	8588		Standardised the length of OFFICIALNUMBER to 36 to match the OFFICIALNUMBERS table
-- 02/04/2003	JB	8148		Added budget and billed to date.
-- 18/06/2003	MF	8917		Rework of 8148 to improve performance.  Use derived table instead of sub select.
-- 08/07/2003	JB	8148		Bug fix - order should have stayed as EVENTDATE (changed to BILLEDTODATE by mistake)
-- 23/10/2003	JB	8883		Now searching on the CASEINDEXES table when using @sAnySearch 
-- 06/08/2004	AB	8035		Add collate database_default to temp table definitions
-- 23/08/2004	VL	10149		change REFERENCENO column to varchar(80)
-- 15 Dec 2008	MF	17136	15	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 04 Jun 2010	MF	18703	16	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be null here
-- 17 Aug 2017	MF	72177	17	Allow Related Cases to be suppressed from the Quick Search (AnySearch).

begin
	-- disable row counts
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	-- declare variables
	declare @iStart			int,	-- start record
		@iEnd			int,	-- end record
		@iPageCount		int,	-- total number of pages
		@sSQLString		nvarchar(4000), -- SQL String to execute
		@sSql			nvarchar(4000),	-- the SQL to execute
		@sSelectList		nvarchar(4000),  -- the SQL list of columns to return
		@sFrom			nvarchar(4000), -- the SQL to list tables and joins
		@sWhere			nvarchar(4000),	-- the SQL to filter
		@sOrder			nvarchar(500),	-- the SQL to order
		@ParmDefinition		nvarchar(500),	-- details of parameters passed with dynamic SQL
		@sCaseTypes		nvarchar(254),	-- list of CaseTypes to restrict query to
		@sNameTypes		nvarchar(254),	-- list of NameTypes to restrict query to
		@nImportanceLevel	int,		-- the level of importance of Events to be searched
		@sDisplayAction		nvarchar(3),	-- the default action allowed to be seen by the user
		@bSuppressRelatedCase	bit


	-- create the temporary table and populate it
	create table #pagedCases
	(
		ID		int		IDENTITY,
		IRN		varchar(20)	collate database_default NOT NULL,
		CASEID		int		NOT NULL,
		OFFICIALNO 	varchar(36)	collate database_default,
		TITLE		varchar(254)	collate database_default,
		LIVEORDEAD	varchar(20)	collate database_default,
		CASESTATUS	varchar(50)	collate database_default,
		RENEWALSTATUS	varchar(50)	collate database_default,
		PROPERTYTYPE	varchar(2)	collate database_default,
		COUNTRYCODE	varchar(3)	collate database_default,
		REFERENCENO	varchar(80)	collate database_default,
		EVENTDATE	datetime,
		CRITERIANO	int,
		EVENTNO		int,
		BUDGETAMOUNT	decimal(11,2), --8148
		BILLEDTODATE	decimal(11,2), --8148
		TOTALWIP	decimal(11,2), --8148
		BILLEDPERCENT	decimal(7,2) --8148
	)
	

	set @sSql = "insert into #pagedCases (IRN, CASEID, OFFICIALNO, TITLE, PROPERTYTYPE, COUNTRYCODE, LIVEORDEAD, BUDGETAMOUNT, BILLEDTODATE, TOTALWIP, REFERENCENO, EVENTDATE, CRITERIANO, EVENTNO, CASESTATUS, RENEWALSTATUS)
	SELECT distinct	"
	set @sSelectList= " C.IRN, C.CASEID, C.CURRENTOFFICIALNO, C.TITLE, PROPERTYTYPE, C.COUNTRYCODE, "
			+char(10)+"	CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 'Dead'"
			+char(10)+"	     WHEN(ST.REGISTEREDFLAG=1)            Then 'Registered'"
			+char(10)+"	                                          Else 'Pending'"
			+char(10)+"	END,"
			+char(10)+" C.BUDGETAMOUNT, BILL.BILLEDAMOUNT, WIP.WIPAMOUNT"

 	set @sFrom= char(10)+"	FROM      CASES C
	left join (Select sum(-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) as BILLEDAMOUNT, WH.CASEID as CASEID
	           from OPENITEM OI 
	           join WORKHISTORY WH on (WH.REFENTITYNO=OI.ITEMENTITYNO 
	                               and WH.REFTRANSNO =OI.ITEMTRANSNO
	                               and WH.MOVEMENTCLASS = 2)
	           where OI.STATUS = 1 
	           group by WH.CASEID) BILL on (BILL.CASEID = C.CASEID)
	left join (Select sum(LOCALVALUE) as WIPAMOUNT, CASEID
	           from WORKINPROGRESS
	           group by CASEID) WIP on (WIP.CASEID = C.CASEID)
	left join STATUS ST	on (ST.STATUSCODE = C.STATUSCODE)
	left join PROPERTY P	on (P.CASEID      = C.CASEID)
	left join STATUS RS	on (RS.STATUSCODE = P.RENEWALSTATUS)"

	If @bSortByNextDueDate=1 
	begin
		set @sOrder = char(10)+"	order by 12"
	end
	Else 
	begin
		set @sOrder = char(10)+"	order by C.IRN"
	end
	set @sWhere = NULL

	if (@sAnySearch is not NULL)
	begin
		-- Check the Site Control to see if Related Case details
		-- are to be suppressed from the quick search
		Select @bSuppressRelatedCase=COLBOOLEAN
		from SITECONTROL
		where CONTROLID='Related Case Quick Search Suppressed'

		set @sSelectList=@sSelectList+", NULL, null, null, null"
		set @sFrom = @sFrom + char(10)+" join CASEINDEXES CR on (CR.CASEID = C.CASEID)"
		set @sWhere = 	char(10)+" where CR.GENERICINDEX like '" + @sAnySearch + "%'"

		If @bSuppressRelatedCase=1
			Set @sWhere = @sWhere + char(10)+" and CR.SOURCE<>7"
	end
	else begin
		if @sIrn is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.IRN LIKE '" + @sIrn +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.IRN LIKE '" + @sIrn +"%'"
		end

		if @sOfficialNo is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join OFFICIALNUMBERS O
				on (O.CASEID      = C.CASEID)"
		
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	O.OFFICIALNUMBER='" + @sOfficialNo +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	O.OFFICIALNUMBER='" + @sOfficialNo +"'"
		end

		if @nNameNo   is not NULL
		or @sNameType is not NULL
		or @sName     is not NULL
		begin
			if @sName is not NULL
			begin
				set @sFrom = @sFrom+char(10)+"	     join NAME N	on (N.NAME LIKE '" + @sName + "%'"
						   +char(10)+"	     			or  N.NAMECODE    LIKE '" + @sName + "%'"
						   +char(10)+"	     			or  N.SEARCHKEY1  LIKE '" + @sName + "%')"
						   +char(10)+"	     join CASENAME CN	on (CN.CASEID     = C.CASEID"
						   +char(10)+"	     			and CN.EXPIRYDATE is NULL"
						   +char(10)+"	     			and CN.NAMENO     = N.NAMENO)"
			end
			else begin
				set @sFrom = @sFrom+char(10)+"	     join CASENAME CN	on (CN.CASEID     = C.CASEID"
						   +char(10)+"	     			and CN.EXPIRYDATE is NULL)"
			end

			if @nNameNo is not NULL
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	CN.NAMENO=" + convert(varchar,@nNameNo)
				else
					set @sWhere = @sWhere+char(10)+"	and	CN.NAMENO=" + convert(varchar,@nNameNo)
			end

			if @sNameType is not NULL
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	CN.NAMETYPE='" + @sNameType +"'"
				else
					set @sWhere = @sWhere+char(10)+"	and	CN.NAMETYPE='" + @sNameType +"'"
			end
		end

		if @sPropertyType is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.PROPERTYTYPE='" + @sPropertyType +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.PROPERTYTYPE='" + @sPropertyType +"'"
		end

		if @sFamily is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.FAMILY='" + @sFamily +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.FAMILY='" + @sFamily +"'"
		end

		if @sCountry is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.COUNTRYCODE='" + @sCountry +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.COUNTRYCODE='" + @sCountry +"'"
		end

		if @sTitle is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.TITLE LIKE '%" + @sTitle +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.TITLE LIKE '%" + @sTitle +"%'"
		end

		-- When a specific status is being filtered on check to see if it is a Renewal Status and if so
		-- then also join on the RenewalStatus

		if @nStatus is not NULL
		begin
			if exists (select * from STATUS where STATUSCODE=@nStatus and RENEWALFLAG=1)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	RS.STATUSCODE = "+convert(varchar,@nStatus)
				else
					set @sWhere = @sWhere+char(10)+"	and	RS.STATUSCODE = "+convert(varchar,@nStatus)
			end
			else begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	ST.STATUSCODE = "+convert(varchar,@nStatus)
				else
					set @sWhere = @sWhere+char(10)+"	and	ST.STATUSCODE = "+convert(varchar,@nStatus)
			end
		end
		else begin
			-- If the RenewalFlag is set on then there must be a RenewalStatus
			if @bRenewalFlag=1
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where	P.RENEWALSTATUS is not null" 
				else
					set @sWhere = @sWhere+char(10)+"and    	P.RENEWALSTATUS is not null"
			end

			-- Dead cases only
			If   @bDead      =1
			and (@bRegistered=0 or @bRegistered is null)
			and (@bPending   =0 or @bPending    is null)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where  (ST.LIVEFLAG=0 OR RS.LIVEFLAG=0)" 
				else
					set @sWhere = @sWhere+char(10)+"and    (ST.LIVEFLAG=0 OR RS.LIVEFLAG=0)"
			end
	
			-- Registered cases only
			else
			if  (@bDead      =0 or @bDead       is null)
			and (@bRegistered=1)
			and (@bPending   =0 or @bPending    is null)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where	ST.LIVEFLAG=1"
						     +char(10)+"and	ST.REGISTEREDFLAG=1"
						     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
				else
					set @sWhere = @sWhere+char(10)+"and	ST.LIVEFLAG=1"
						    	     +char(10)+"and	ST.REGISTEREDFLAG=1"
						     	     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
				
			end

			-- Pending cases only
			else
			if  (@bDead      =0 or @bDead       is null)
			and (@bRegistered=0 or @bRegistered is null)
			and (@bPending   =1)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where	ST.LIVEFLAG=1"
						     +char(10)+"and	ST.REGISTEREDFLAG=0"
						     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
				else
					set @sWhere = @sWhere+char(10)+"and	ST.LIVEFLAG=1"
						    	     +char(10)+"and	ST.REGISTEREDFLAG=0"
						     	     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
			end

			-- Pending cases or Registed cases only (not dead)
			else
			if  (@bDead      =0 or @bDead       is null)
			and (@bRegistered=1)
			and (@bPending   =1)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where	ST.LIVEFLAG=1"
						     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
				else
					set @sWhere = @sWhere+char(10)+"and	ST.LIVEFLAG=1"
						     	     +char(10)+"and    (RS.LIVEFLAG=1 or RS.STATUSCODE is null)"
			end

			-- Registered cases or Dead cases
			else
			if  (@bDead      =1)
			and (@bRegistered=1)
			and (@bPending   =0 or @bPending is null)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where ((ST.LIVEFLAG=1 and ST.REGISTEREDFLAG=1) OR ST.LIVEFLAG =0 OR RS.LIVEFLAG=0)"
				else
					set @sWhere = @sWhere+char(10)+"and   ((ST.LIVEFLAG=1 and ST.REGISTEREDFLAG=1) OR ST.LIVEFLAG =0 OR RS.LIVEFLAG=0)"
			end

			-- Pending cases or Dead cases
			else
			if  (@bDead      =1)
			and (@bRegistered=0 or @bRegistered is null)
			and (@bPending   =1)
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"where ((ST.LIVEFLAG=1 and ST.REGISTEREDFLAG=0) OR ST.LIVEFLAG =0 OR RS.LIVEFLAG=0)"
				else
					set @sWhere = @sWhere+char(10)+"and   ((ST.LIVEFLAG=1 and ST.REGISTEREDFLAG=0) OR ST.LIVEFLAG =0 OR RS.LIVEFLAG=0)"
	
			end
		end

		if @sKeyword is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join CASEWORDS CW	on (CW.CASEID     = C.CASEID)"
				           +char(10)+"	     join KEYWORDS KW	on (KW.KEYWORDNO  = CW.KEYWORDNO)"
		
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	KW.KEYWORD='" + @sKeyword +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	KW.KEYWORD='" + @sKeyword +"'"
		end

		if @sCaseType is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.CASETYPE='"+@sCaseType+"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.CASETYPE='"+@sCaseType+"'"
		end

		if @sCaseCategory is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	C.CASECATEGORY='"+@sCaseCategory+"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	C.CASECATEGORY='"+@sCaseCategory+"'"
		end
		
		if @sReferenceNo is NULL
		begin
			set @sSelectList=@sSelectList+", NULL"
		end
		else begin
			set @sSelectList=@sSelectList+", REF.REFERENCENO"
			set @sFrom = @sFrom+char(10)+"	left join CASENAME REF	on (REF.CASEID    = C.CASEID"
					   +char(10)+"				and REF.NAMETYPE  ='I'"
					   +char(10)+"				and REF.EXPIRYDATE is null)"
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	REF.REFERENCENO like '"+@sReferenceNo+"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	REF.REFERENCENO like '"+@sReferenceNo+"%'"
		end

		If @bSortByNextDueDate=1
		begin
			set @sFrom = @sFrom+char(10)+"	     join OPENACTION OA on (OA.CASEID     = C.CASEID"
					   +char(10)+"				and OA.POLICEEVENTS=1)"
					   +char(10)+"	     join EVENTCONTROL EC on (EC.CRITERIANO= OA.CRITERIANO)"
					   +char(10)+"	     join CASEEVENT CE	on (CE.CASEID     = C.CASEID"
					   +char(10)+"				and CE.EVENTNO    = EC.EVENTNO"
					   +char(10)+"				and convert(char(8),CE.EVENTDUEDATE,112)+convert(char(11), CE.EVENTNO)+convert(char(3),CE.CYCLE)"
					   +char(10)+"				    = (select min(convert(char(8),CE1.EVENTDUEDATE,112)+convert(char(11), CE1.EVENTNO)+convert(char(3),CE1.CYCLE))"
					   +char(10)+"				       from  CASEEVENT CE1"
					   +char(10)+"				       where CE1.CASEID =C.CASEID"
					   +char(10)+"				       and   CE1.OCCURREDFLAG=0"
			set @sSelectList=@sSelectList+", CE.EVENTDUEDATE, CE.CREATEDBYCRITERIA, CE.EVENTNO"

			if @nEvent is not NULL
			begin
				set  @sFrom = @sFrom+char(10)+"				       and   CE1.EVENTNO="+convert(varchar, @nEvent)
			end

			if  @sFromEventDate is not NULL
			and @sToEventDate   is not NULL
			begin
				set @sFrom = @sFrom+char(10)+"				       and   CE1.EVENTDUEDATE between '"+@sFromEventDate+"' and '"+@sToEventDate+"'"
			end
			else if  @sFromEventDate is not NULL
			begin
				set @sFrom = @sFrom+char(10)+"				       and   CE1.EVENTDUEDATE >='"+@sFromEventDate+"'"
			end
			else if @sToEventDate is not NULL
			begin
				set @sFrom = @sFrom+char(10)+"				       and   CE1.EVENTDUEDATE <='"+@sToEventDate+"'"
			end

			set @sFrom = @sFrom+"))"

		end
		else 
		if @nEvent         is not NULL
		or @sFromEventDate is not NULL
		or @sToEventDate   is not NULL
		begin
			-- If the Case search is restricted to Event Due Dates then the events to be considered
			-- must be attached to an open action.
			set @sFrom = @sFrom+char(10)+"	     join OPENACTION OA on (OA.CASEID     = C.CASEID"
					   +char(10)+"				and OA.POLICEEVENTS="+CASE WHEN(@bSearchByDueDate=1) THEN "1)" ELSE "OA.POLICEEVENTS)" END
					   +char(10)+"	     join ACTIONS A	on (A.ACTION      = OA.ACTION)"
					   +char(10)+"	     join EVENTCONTROL EC on(EC.CRITERIANO= OA.CRITERIANO)"
					   +char(10)+"	     join CASEEVENT CE	on (CE.CASEID     = C.CASEID"
					   +char(10)+"				and CE.EVENTNO    = EC.EVENTNO"
					   +char(10)+"				and CE.CYCLE      = CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END)"

			set @sSelectList=@sSelectList+", isnull(CE.EVENTDATE,CE.EVENTDUEDATE), CE.CREATEDBYCRITERIA, CE.EVENTNO"

			if @nEvent is not NULL
			begin
				if @sWhere is NULL
				begin
					set @sWhere = char(10)+"	where	EC.EVENTNO="+convert(varchar,@nEvent)
				end
				else begin
					set @sWhere = @sWhere+char(10)+"	and	EC.EVENTNO="+convert(varchar,@nEvent)
				end
			end

			if @bSearchByDueDate=1
			begin
				if @sWhere is null
				begin
					set @sWhere = char(10)+"	where	CE.OCCURREDFLAG=0"
				end
				else begin
					set @sWhere = @sWhere+char(10)+"	and	CE.OCCURREDFLAG=0"
				end

				if  @sFromEventDate is not NULL
				and @sToEventDate   is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDUEDATE between '"+@sFromEventDate+"' and '"+@sToEventDate+"'"
				end
				else if  @sFromEventDate is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDUEDATE >='"+@sFromEventDate+"'"
				end
				else if @sToEventDate is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDUEDATE <='"+@sToEventDate+"'"
				end
			end
			else begin
				if @sWhere is null
				begin
					set @sWhere = char(10)+"	where	CE.OCCURREDFLAG between 1 and 8"
				end
				else begin
					set @sWhere = @sWhere+char(10)+"	and	CE.OCCURREDFLAG between 1 and 8"
				end

				if  @sFromEventDate is not NULL
				and @sToEventDate   is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDATE between '"+@sFromEventDate+"' and '"+@sToEventDate+"'"
				end
				else if @sFromEventDate is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDATE >='"+@sFromEventDate+"'"
				end
				else if @sToEventDate is not NULL
				begin
					set @sWhere =  @sWhere+char(10)+"	and	CE.EVENTDATE <='"+@sToEventDate+"'"
				end
			end
		end
		else begin
			set @sSelectList=@sSelectList+", NULL, NULL, NULL"
		end

		-- If Events are included in the search then restrict the events to those within the 
		-- importance level range depending on whether the user is external or not.
		-- Where there is a default Action then also restrict the Events by that Action

		if @nEvent         is not NULL
		or @sFromEventDate is not NULL
		or @sToEventDate   is not NULL
		or @bSortByNextDueDate=1
		begin
			select	@nImportanceLevel=
					CASE WHEN(EXTERNALUSERFLAG > 1)	THEN isnull(S1.COLINTEGER,0)
									ELSE isnull(S2.COLINTEGER,0)
					END,
				@sDisplayAction  =	
					CASE WHEN(EXTERNALUSERFLAG > 1) THEN S3.COLCHARACTER 
									ELSE S4.COLCHARACTER
					END
			from USERS U
			left join SITECONTROL S1	on (S1.CONTROLID='Client Importance')
			left join SITECONTROL S2	on (S2.CONTROLID='Events Displayed')
			left join SITECONTROL S3	on (S3.CONTROLID='Client PublishAction')
			left join SITECONTROL S4	on (S4.CONTROLID='Publish Action')
			where U.USERID=user

			If  @nImportanceLevel is not null
			begin
				if  @sWhere is null
				begin
					set @sWhere = char(10)+"	where	EC.IMPORTANCELEVEL>="+convert(varchar,@nImportanceLevel)
				end
				else begin
					set @sWhere = @sWhere+char(10)+"	and	EC.IMPORTANCELEVEL>"+convert(varchar,@nImportanceLevel)
				end
			end

			If  @sDisplayAction is not null
			begin
				if  @sWhere is null
				begin
					set @sWhere = char(10)+"	where	OA.ACTION='"+@sDisplayAction+"'"
				end
				else begin
					set @sWhere = @sWhere+char(10)+"	and	OA.ACTION='"+@sDisplayAction+"'"
				end
			end
		end
	end

	if (exists (	select * from USERS
			where USERID = user
			AND EXTERNALUSERFLAG > 1))
	begin
		-- For performance reasons we are going to get the list of available Case Types and Name Types
		-- to limit the search to those that match. Each list is comma separated however we require each
		-- value to be surrounded by quotes as well
		set @sSQLString="Select @sCaseTypes=replace(replace(S.COLCHARACTER,' ',''),',',char(39)+','+char(39)),"+char(10)+
				"       @sNameTypes=replace(replace(T.COLCHARACTER,' ',''),',',char(39)+','+char(39))"+char(10)+
				"from SITECONTROL S"+char(10)+
				"join SITECONTROL T on (T.CONTROLID='Client Name Types')"+char(10)+
				"where S.CONTROLID='Client Case Types'"

		exec sp_executesql @sSQLString,
					N'@sCaseTypes	nvarchar(254)	OUTPUT,
					  @sNameTypes	nvarchar(254)	OUTPUT',
					  @sCaseTypes	=@sCaseTypes	OUTPUT,
					  @sNameTypes	=@sNameTypes	OUTPUT

		
		set @sSelectList = @sSelectList + ", ST.EXTERNALDESC, RS.EXTERNALDESC"

		set @sFrom = @sFrom+char(10)+"	     join NAMEALIAS NA  on (NA.ALIAS=user"
				   +char(10)+"				and NA.ALIASTYPE='IU'"
				   +char(10)+"				and NA.COUNTRYCODE  is null"
				   +char(10)+"				and NA.PROPERTYTYPE is null)"
				   +char(10)+"	     join CASENAME CN1	on (CN1.CASEID=C.CASEID"
				   +char(10)+"				and CN1.NAMENO=NA.NAMENO)"

		If @sCaseTypes is not null
		begin
			If @sWhere is NULL
			begin
				set @sWhere = char(10)+"	where C.CASETYPE in ('"+@sCaseTypes+"')"
			end
			else begin
				set @sWhere = @sWhere+char(10)+"	and	C.CASETYPE in ('"+@sCaseTypes+"')"
			end
		end

		If @sNameTypes is not null
		begin
			If @sWhere is NULL
			begin	
				set @sWhere="	where"
			end

			if @nNameNo   is not NULL
			or @sNameType is not NULL
			begin
				set @sWhere = @sWhere 	+char(10)+"	and	CN.NAMETYPE in ('"+@sNameTypes+"')"
			end
			else begin
				set @sWhere = @sWhere 	+char(10)+"	and	CN1.NAMETYPE in ('"+@sNameTypes+"')"
			end
		End

	end
	Else begin
		set @sSelectList = @sSelectList + ", ST.INTERNALDESC, RS.INTERNALDESC"
	end

	-- If Row level security is in use for Cases then add a further restriction to ensure that
	-- only the Cases the user may see is returned.

	if exists (	SELECT *
			FROM USERROWACCESS U
			join ROWACCESSDETAIL R	on (R.ACCESSNAME=U.ACCESSNAME)
			WHERE RECORDTYPE = 'C')
	Begin
		If @sWhere is NULL
		begin
			set @sWhere = @sWhere 	+char(10)+"	where	Substring("
		end
		else begin
			set @sWhere = @sWhere 	+char(10)+"	and	Substring("
		end

          	set @sWhere = @sWhere	+char(10)+"		(select MAX (   CASE WHEN OFFICE       IS NULL THEN '0' ELSE '1' END +"
          				+char(10)+"				CASE WHEN CASETYPE     IS NULL THEN '0' ELSE '1' END +"
          				+char(10)+"				CASE WHEN PROPERTYTYPE IS NULL THEN '0' ELSE '1' END +"
          				+char(10)+"				CASE WHEN SECURITYFLAG < 10    THEN '0' END +"
          				+char(10)+"				convert(nvarchar,SECURITYFLAG))"
          				+char(10)+"		 from USERROWACCESS UA"
          				+char(10)+"		 left join TABLEATTRIBUTES TA 	on (TA.PARENTTABLE='CASES'"
          				+char(10)+"						and TA.TABLETYPE=44"
          				+char(10)+"						and TA.GENERICINDEX=convert(nvarchar, C.CASEID))"
          				+char(10)+"		 left join ROWACCESSDETAIL RAD 	on  (RAD.ACCESSNAME   =UA.ACCESSNAME"
          				+char(10)+"						and (RAD.OFFICE       = TA.TABLECODE   or RAD.OFFICE       is NULL)"
          				+char(10)+"						and (RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)"
          				+char(10)+"						and (RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)"
          				+char(10)+"						and  RAD.RECORDTYPE = 'C')"
          				+char(10)+"		 where UA.USERID= user   ),   4,2)"
          				+char(10)+"			in (  '01','03','05','07','09','11','13','15' ) "
	End

	-- check the page number
	IF @iPage < 1
		set @iPage = 1

	-- Only extract the number of rows required to get the specific page requested
	
	If @iPageSize>0
	Begin
		set @sSql = @sSql + 'TOP '+
		    convert(varchar, @iPageSize * @iPage) +
		    @sSelectList + @sFrom + @sWhere + @sOrder
	End
	Else Begin
		set @sSql = @sSql + @sSelectList + @sFrom + @sWhere + @sOrder
	End
	If @bDebug is not null Print @sSql
	exec sp_executesql @sSql

	-- get the number of rows the full query would return

	set @sSql  ='SELECT @iRowCountOUT=COUNT(distinct C.CASEID)'+ @sFrom + @sWhere
	set @ParmDefinition='@iRowCountOUT int OUTPUT'

	If @bDebug is not null Print @sSql
	exec sp_executesql @sSql, @ParmDefinition, @iRowCountOUT=@iRowCount OUTPUT
	

	-- work out how many pages there are in total

	If @iPageSize>0
	Begin
		SELECT @iPageCount = CEILING(@iRowCount / @iPageSize) + 1
	End
	Else Begin
		If @iRowCount>0
		begin
		 	SELECT @iPageCount=1
		end
		else begin
			SELECT @iPageCount=0
		end
	End

	IF @iPage > @iPageCount
		SELECT @iPage = @iPageCount

	-- calculate the start and end records
	If @iPageSize>0
	Begin
		SELECT @iStart = (@iPage - 1) * @iPageSize
		SELECT @iEnd = @iStart + @iPageSize + 1
	End
	Else Begin
		SELECT @iStart=0
		SELECT @iEnd  =@iRowCount
	End

	-- SQA8148
	Update #pagedCases
		Set BILLEDPERCENT = isnull(BILLEDTODATE/BUDGETAMOUNT,0) * 100
		where BUDGETAMOUNT > 0

	-- select only those records that fall within our page
	-- If the Clients Reference was not part of the selection critieria then extract it now (done for performance)
	
	if @sReferenceNo is NULL
	Begin
		SELECT	C.IRN, C.CASEID, C.OFFICIALNO, C.TITLE, C.LIVEORDEAD, C.CASESTATUS, C.RENEWALSTATUS, VP.PROPERTYNAME, CO.COUNTRY, REF.REFERENCENO, 
			C.EVENTDATE, isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) as EVENTDESCRIPTION, BUDGETAMOUNT, BILLEDTODATE, BILLEDPERCENT, TOTALWIP
		FROM	#pagedCases C
		left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
						and VP.COUNTRYCODE  = (	select min(COUNTRYCODE)
									from  VALIDPROPERTY VP1
									where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
									and   VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
		left join CASENAME REF		on (REF.CASEID    = C.CASEID
						and REF.NAMETYPE  ='I'
						and REF.EXPIRYDATE is null)
		left join COUNTRY CO		on (CO.COUNTRYCODE = C.COUNTRYCODE)
		left join EVENTCONTROL EC	on (EC.CRITERIANO  = C.CRITERIANO
						and EC.EVENTNO     = C.EVENTNO)
		left join EVENTS E		on (E.EVENTNO=C.EVENTNO)
		WHERE	ID > @iStart
		AND	ID < @iEnd
		order by ID
	End
	Else Begin
		SELECT	C.IRN, C.CASEID, C.OFFICIALNO, C.TITLE, C.LIVEORDEAD, C.CASESTATUS, C.RENEWALSTATUS, VP.PROPERTYNAME, CO.COUNTRY, C.REFERENCENO, 
			C.EVENTDATE, isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) as EVENTDESCRIPTION, BILLEDTODATE, BILLEDPERCENT, TOTALWIP
		FROM	#pagedCases C
		left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
						and VP.COUNTRYCODE  = (	select min(COUNTRYCODE)
									from  VALIDPROPERTY VP1
									where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
									and   VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
		left join COUNTRY CO		on (CO.COUNTRYCODE = C.COUNTRYCODE)
		left join EVENTCONTROL EC	on (EC.CRITERIANO  = C.CRITERIANO
						and EC.EVENTNO     = C.EVENTNO)
		left join EVENTS E		on (E.EVENTNO=C.EVENTNO)
		WHERE	ID > @iStart
		AND	ID < @iEnd
		order by ID
	End

	DROP TABLE #pagedCases

	-- Return the number of records left
	RETURN @iPageCount
end
go 

grant execute on [dbo].[wa_ListCases] to public
go

