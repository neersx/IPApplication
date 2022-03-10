-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesEVENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesEVENTCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesEVENTCONTROL.'
	drop procedure dbo.ip_RulesEVENTCONTROL
	print '**** Creating procedure dbo.ip_RulesEVENTCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesEVENTCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesEVENTCONTROL
-- VERSION :	17
-- DESCRIPTION:	The comparison/display and merging of imported data for the EVENTCONTROL table

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove EVENTCONTROL rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 06 Sep 2004	MF	10443	3	Include IMPORTANCELEVEL in the data comparison.
-- 22 Feb 2006	MF	12360	4	Internal SQLServer Error occurring on Delete.  This is a bug in
--					MS SQLServer which can be overcome by recoding the Delete.
-- 28 Mar 2006	MF	12500	5	Do not replace the description
-- 23 Aug 2006	MF	13299	6	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 31 Aug 2006	MF	13338	7	Do not overwrite ImportanceLevel
-- 21-Feb-2007	MF	14398	8	New column RECALCEVENTDATE to be included.
-- 22 May 2007	MF	14110	9	Difference in SaveDueDate is not being displayed.
-- 15 Jan 2010	MF	18150	10	Status changes within the Law Update Sevice will not be updated on existing rules.
-- 21 Jan 2011	MF	19321	11	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 11 Mar 2011	MF	19321	12	Revisit to include additional columns that do not need to be shown as a difference.
-- 11 Jun 2013	MF	S21404	13	New column SUPPRESSCALCULATION to be delivered for new row but is not to be updated.
-- 12 Jul 2013	MF	R13596	14	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	15	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 06 Nov 2013	MF	R28125	16	Create Index on imported table to improve performance.
-- 01 May 2017	MF	71205	3	Add new column RENEWALSTATUS
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 		(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the IMPORTED_EVENTCONTROL table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString1		varchar(8000)
Declare @sSQLString2		varchar(8000)
Declare @sSQLString3		varchar(8000)
Declare @sSQLString4		varchar(8000)
Declare @sSQLString5		varchar(8000)
Declare @sSQLString6		varchar(8000)

Declare	@ErrorCode			int
Declare @sUserName			nvarchar(40)
Declare	@hDocument	 		int 			-- handle to the XML parameter
Declare @bOriginalKeyColumnExists	bit

Set @ErrorCode=0
Set @bOriginalKeyColumnExists = 0
Set @sUserName	= @psUserName
--------------------------------------
-- Create and load CRITERIAALLOWED if
-- it does not exist already
--------------------------------------
If @ErrorCode=0
and not exists(	SELECT 1 
		from sysobjects 
		where id = object_id(@sUserName+'.CRITERIAALLOWED'))
Begin
	---------------------------------------------------
	-- Create an interim table to hold the criteria
	-- that are allowed to be imported for the purpose
	-- of creating or update laws on the receiving
	-- database
	---------------------------------------------------
	Set @sSQLString="CREATE TABLE "+@sUserName+".CRITERIAALLOWED (CRITERIANO int not null PRIMARY KEY)"
	exec @ErrorCode=sp_executesql @sSQLString
	
	If @ErrorCode=0
	Begin
		-----------------------------------------
		-- Load the CRITERIA that are candidates
		-- to be imported into a temporary table.
		-- This allows rules defined by a firm to
		-- block or allow criteria.
		-----------------------------------------
		set @sSQLString="
		insert into "+@sUserName+".CRITERIAALLOWED (CRITERIANO)
		select distinct C.CRITERIANO
		from "+@sUserName+".Imported_CRITERIA C
		left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
												    C.ACTION,
												    C.PROPERTYTYPE,
												    C.COUNTRYCODE,
												    C.CASECATEGORY,
												    C.SUBTYPE,
												    C.BASIS,
												    C.DATEOFACT) )
		where isnull(C1.RULEINUSE,0)=0"
		
		exec @ErrorCode=sp_executesql @sSQLString
	End
end

-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison

If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_EVENTCONTROL
		SET STATUSCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_EVENTCONTROL C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='STATUS'
				and M.MAPCOLUMN  ='STATUSCODE'
				and M.SOURCEVALUE=C.STATUSCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_EVENTCONTROL
		SET RENEWALSTATUS = M.MAPVALUE
		FROM "+@sUserName+".Imported_EVENTCONTROL C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='STATUS'
				and M.MAPCOLUMN  ='STATUS'
				and M.SOURCEVALUE=C.RENEWALSTATUS)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET EVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.EVENTNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET PARENTEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.PARENTEVENTNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET CREATEACTION = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ACTIONS'
					and M.MAPCOLUMN  ='ACTION'
					and M.SOURCEVALUE=C.CREATEACTION)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET CLOSEACTION = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ACTIONS'
					and M.MAPCOLUMN  ='ACTION'
					and M.SOURCEVALUE=C.CLOSEACTION)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET UPDATEFROMEVENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.UPDATEFROMEVENT)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET FROMRELATIONSHIP = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='CASERELATION'
					and M.MAPCOLUMN  ='RELATIONSHIP'
					and M.SOURCEVALUE=C.FROMRELATIONSHIP)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_EVENTCONTROL
			SET ADJUSTMENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_EVENTCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ADJUSTMENT'
					and M.MAPCOLUMN  ='ADJUSTMENT'
					and M.SOURCEVALUE=C.ADJUSTMENT)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end
End


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3			as 'Comparison',
			NULL			as Match,
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Imported Criteria',
			I.EVENTNO		as 'Imported Event No',
			C.EVENTDESCRIPTION	as 'Imported Event Description',
			I.NUMCYCLESALLOWED	as 'Imported No. Cycles',
			CASE(I.WHICHDUEDATE) WHEN('E') THEN 'Earliest' WHEN('L') THEN 'Latest' END
						as 'Imported Which Due Date',
			CASE(I.COMPAREBOOLEAN) WHEN(0) THEN 'Any' WHEN(1) THEN 'All' END
						as 'Imported Compares to Match',
			CF.FLAGNAME		as 'Imported Designated Country Status',
			CASE(I.SAVEDUEDATE)
				WHEN(1) THEN 'Save Due Date'
				WHEN(2) THEN 'Update Event Immediately'
				WHEN(3) THEN 'Save Due & Update Event'
				WHEN(4) THEN 'Update When Due'
				WHEN(5) THEN 'Save Due & Update When Due'
			END			as 'Imported Save Due Date',
			dbo.fn_DisplayBoolean(I.SETTHIRDPARTYON,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported CPA Flag On',
			AO.ACTIONNAME		as 'Imported Create Action',
			AC.ACTIONNAME		as 'Imported Close Action',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Current'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
				WHEN(5) THEN 'All'
				WHEN(6) THEN 'All Lower'
				WHEN(7) THEN 'All Higher'
			END			as 'Imported Relative Cycle',
			E.EVENTDESCRIPTION	as 'Imported Update from Event',
			CX.RELATIONSHIPDESC	as 'Imported From Relationship',
			dbo.fn_DisplayBoolean(I.FROMANCESTOR,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported From Ancestor',
			AJ.ADJUSTMENTDESC	as 'Imported Adjustment',
			CASE(I.PTADELAY) WHEN(1) THEN 'IP Office Delay' WHEN(2) THEN 'Applicant Delay' END
						as 'Imported Term Adjustment',
			dbo.fn_DisplayBoolean(I.RECALCEVENTDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Recalc Flag',
			dbo.fn_DisplayBoolean(I.SUPPRESSCALCULATION,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Suppress Calc Flag',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			C.EVENTNO		as 'Event No',
			C.EVENTDESCRIPTION	as 'Event Description',
			C.NUMCYCLESALLOWED	as 'No. Cycles',
			CASE(C.WHICHDUEDATE) WHEN('E') THEN 'Earliest' WHEN('L') THEN 'Latest' END
						as 'Which Due Date',
			CASE(C.COMPAREBOOLEAN) WHEN(0) THEN 'Any' WHEN(1) THEN 'All' END
						as 'Compares to Match',
			CF.FLAGNAME		as 'Designated Country Status',
			CASE(C.SAVEDUEDATE)
				WHEN(1) THEN 'Save Due Date'
				WHEN(2) THEN 'Update Event Immediately'
				WHEN(3) THEN 'Save Due & Update Event'
				WHEN(4) THEN 'Update When Due'
				WHEN(5) THEN 'Save Due & Update When Due'
			END			as 'Save Due Date',
			dbo.fn_DisplayBoolean(C.SETTHIRDPARTYON,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'CPA Flag On',
			AO.ACTIONNAME		as 'Create Action',
			AC.ACTIONNAME		as 'Close Action',
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Current'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
				WHEN(5) THEN 'All'
				WHEN(6) THEN 'All Lower'
				WHEN(7) THEN 'All Higher'
			END			as 'Relative Cycle',
			E.EVENTDESCRIPTION	as 'Update from Event',
			CX.RELATIONSHIPDESC	as 'From Relationship',
			dbo.fn_DisplayBoolean(C.FROMANCESTOR,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'From Ancestor',
			AJ.ADJUSTMENTDESC	as 'Adjustment',
			CASE(C.PTADELAY) WHEN(1) THEN 'IP Office Delay' WHEN(2) THEN 'Applicant Delay' END
						as 'Term Adjustment',
			dbo.fn_DisplayBoolean(C.RECALCEVENTDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Recalc Flag',
			dbo.fn_DisplayBoolean(C.SUPPRESSCALCULATION,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Suppress Calc Flag'"
		Set @sSQLString2="
		from "+@sUserName+".Imported_EVENTCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_COUNTRYFLAGS CF on (CF.COUNTRYCODE=CR.COUNTRYCODE
							 and CF.FLAGNUMBER=I.CHECKCOUNTRYFLAG)
		left join "+@sUserName+".Imported_ACTIONS AO on (AO.ACTION=I.CREATEACTION)
		left join "+@sUserName+".Imported_ACTIONS AC on (AC.ACTION=I.CLOSEACTION)
		left join "+@sUserName+".Imported_EVENTS E on (E.EVENTNO=I.UPDATEFROMEVENT)
		left join "+@sUserName+".Imported_CASERELATION CX on (CX.RELATIONSHIP=I.FROMRELATIONSHIP)
		left join "+@sUserName+".Imported_ADJUSTMENT AJ on (AJ.ADJUSTMENT=I.ADJUSTMENT)
		join EVENTCONTROL C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO)
		where	(I.NUMCYCLESALLOWED=C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is null))
		and	(I.WHICHDUEDATE=C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is null))
		and	(I.COMPAREBOOLEAN=C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is null))
		and	(I.CHECKCOUNTRYFLAG=C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is null))
		and	(I.SAVEDUEDATE=C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is null))
		and	(I.CREATEACTION=C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is null))
		and	(I.CLOSEACTION=C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is null))
		and	(I.UPDATEFROMEVENT=C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is null))
		and	(I.FROMRELATIONSHIP=C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is null))
		and	(I.FROMANCESTOR=C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is null))
		and	(I.ADJUSTMENT=C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
		and	(I.SETTHIRDPARTYON=C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is null))
		and	(I.RELATIVECYCLE=C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
		and	(I.PTADELAY=C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is null))
		and	(isnull(I.RECALCEVENTDATE,0)=isnull(C.RECALCEVENTDATE,0))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			I.EVENTNO,
			C.EVENTDESCRIPTION,
			I.NUMCYCLESALLOWED,
			CASE(I.WHICHDUEDATE) WHEN('E') THEN 'Earliest' WHEN('L') THEN 'Latest' END,
			CASE(I.COMPAREBOOLEAN) WHEN(0) THEN 'Any' WHEN(1) THEN 'All' END,
			CF.FLAGNAME,
			CASE(I.SAVEDUEDATE)
				WHEN(1) THEN 'Save Due Date'
				WHEN(2) THEN 'Update Event Immediately'
				WHEN(3) THEN 'Save Due & Update Event'
				WHEN(4) THEN 'Update When Due'
				WHEN(5) THEN 'Save Due & Update When Due'
			END,
			dbo.fn_DisplayBoolean(I.SETTHIRDPARTYON,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AO.ACTIONNAME,
			AC.ACTIONNAME,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Current'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
				WHEN(5) THEN 'All'
				WHEN(6) THEN 'All Lower'
				WHEN(7) THEN 'All Higher'
			END,
			E.EVENTDESCRIPTION,
			CX.RELATIONSHIPDESC,
			dbo.fn_DisplayBoolean(I.FROMANCESTOR,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AJ.ADJUSTMENTDESC,
			CASE(I.PTADELAY) WHEN(1) THEN 'IP Office Delay' WHEN(2) THEN 'Applicant Delay' END,
			dbo.fn_DisplayBoolean(I.RECALCEVENTDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.SUPPRESSCALCULATION,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			C.EVENTNO,
			C.EVENTDESCRIPTION,
			C.NUMCYCLESALLOWED,
			CASE(C.WHICHDUEDATE) WHEN('E') THEN 'Earliest' WHEN('L') THEN 'Latest' END,
			CASE(C.COMPAREBOOLEAN) WHEN(0) THEN 'Any' WHEN(1) THEN 'All' END,
			CF1.FLAGNAME,
			CASE(C.SAVEDUEDATE)
				WHEN(1) THEN 'Save Due Date'
				WHEN(2) THEN 'Update Event Immediately'
				WHEN(3) THEN 'Save Due & Update Event'
				WHEN(4) THEN 'Update When Due'
				WHEN(5) THEN 'Save Due & Update When Due'
			END,
			dbo.fn_DisplayBoolean(C.SETTHIRDPARTYON,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AO1.ACTIONNAME,
			AC1.ACTIONNAME,
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Current'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
				WHEN(5) THEN 'All'
				WHEN(6) THEN 'All Lower'
				WHEN(7) THEN 'All Higher'
			END,
			E1.EVENTDESCRIPTION,
			CX1.RELATIONSHIPDESC,
			dbo.fn_DisplayBoolean(C.FROMANCESTOR,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AJ1.ADJUSTMENTDESC,
			CASE(C.PTADELAY) WHEN(1) THEN 'IP Office Delay' WHEN(2) THEN 'Applicant Delay' END,
			dbo.fn_DisplayBoolean(C.RECALCEVENTDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.SUPPRESSCALCULATION,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)"
		Set @sSQLString4="
		from "+@sUserName+".Imported_EVENTCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_COUNTRYFLAGS CF on (CF.COUNTRYCODE=CR.COUNTRYCODE
							 and CF.FLAGNUMBER=I.CHECKCOUNTRYFLAG)
		left join "+@sUserName+".Imported_ACTIONS AO on (AO.ACTION=I.CREATEACTION)
		left join "+@sUserName+".Imported_ACTIONS AC on (AC.ACTION=I.CLOSEACTION)
		left join "+@sUserName+".Imported_EVENTS E on (E.EVENTNO=I.UPDATEFROMEVENT)
		left join "+@sUserName+".Imported_CASERELATION CX on (CX.RELATIONSHIP=I.FROMRELATIONSHIP)
		left join "+@sUserName+".Imported_ADJUSTMENT AJ on (AJ.ADJUSTMENT=I.ADJUSTMENT)
		join EVENTCONTROL C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO)
		join CRITERIA CR1 on (CR1.CRITERIANO=I.CRITERIANO)
		left join COUNTRYFLAGS CF1 on (CF1.COUNTRYCODE=CR1.COUNTRYCODE
					   and CF1.FLAGNUMBER=I.CHECKCOUNTRYFLAG)
		left join ACTIONS AO1 on (AO1.ACTION=C.CREATEACTION)
		left join ACTIONS AC1 on (AC1.ACTION=C.CLOSEACTION)
		left join EVENTS E1 on (E1.EVENTNO=C.UPDATEFROMEVENT)
		left join CASERELATION CX1 on (CX1.RELATIONSHIP=C.FROMRELATIONSHIP)
		left join ADJUSTMENT AJ1 on (AJ1.ADJUSTMENT=C.ADJUSTMENT)"
		Set @sSQLString5="
		where 	I.NUMCYCLESALLOWED<>C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null)
		OR	I.WHICHDUEDATE<>C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is not null) OR (I.WHICHDUEDATE is not null and C.WHICHDUEDATE is null)
		OR	I.COMPAREBOOLEAN<>C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is not null) OR (I.COMPAREBOOLEAN is not null and C.COMPAREBOOLEAN is null)
		OR	I.CHECKCOUNTRYFLAG<>C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is not null) OR (I.CHECKCOUNTRYFLAG is not null and C.CHECKCOUNTRYFLAG is null)
		OR	I.SAVEDUEDATE<>C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is not null) OR (I.SAVEDUEDATE is not null and C.SAVEDUEDATE is null)
		OR	I.CREATEACTION<>C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null) OR (I.CREATEACTION is not null and C.CREATEACTION is null)
		OR	I.CLOSEACTION<>C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is not null) OR (I.CLOSEACTION is not null and C.CLOSEACTION is null)
		OR	I.UPDATEFROMEVENT<>C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is not null) OR (I.UPDATEFROMEVENT is not null and C.UPDATEFROMEVENT is null)
		OR	I.FROMRELATIONSHIP<>C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is not null) OR (I.FROMRELATIONSHIP is not null and C.FROMRELATIONSHIP is null)
		OR	I.FROMANCESTOR<>C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is not null) OR (I.FROMANCESTOR is not null and C.FROMANCESTOR is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.SETTHIRDPARTYON<>C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is not null) OR (I.SETTHIRDPARTYON is not null and C.SETTHIRDPARTYON is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.PTADELAY<>C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is not null) OR (I.PTADELAY is not null and C.PTADELAY is null)
		OR	isnull(I.RECALCEVENTDATE,0)<>isnull(C.RECALCEVENTDATE,0)"
		Set @sSQLString6="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			I.EVENTNO,
			I.EVENTDESCRIPTION,
			I.NUMCYCLESALLOWED,
			CASE(I.WHICHDUEDATE) WHEN('E') THEN 'Earliest' WHEN('L') THEN 'Latest' END,
			CASE(I.COMPAREBOOLEAN) WHEN(0) THEN 'Any' WHEN(1) THEN 'All' END,
			CF.FLAGNAME,
			CASE(I.SAVEDUEDATE)
				WHEN(1) THEN 'Save Due Date'
				WHEN(2) THEN 'Update Event Immediately'
				WHEN(3) THEN 'Save Due & Update Event'
				WHEN(4) THEN 'Update When Due'
				WHEN(5) THEN 'Save Due & Update When Due'
			END,
			dbo.fn_DisplayBoolean(I.SETTHIRDPARTYON,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AO.ACTIONNAME,
			AC.ACTIONNAME,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Current'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
				WHEN(5) THEN 'All'
				WHEN(6) THEN 'All Lower'
				WHEN(7) THEN 'All Higher'
			END,
			E.EVENTDESCRIPTION,
			CX.RELATIONSHIPDESC,
			dbo.fn_DisplayBoolean(I.FROMANCESTOR,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AJ.ADJUSTMENTDESC,
			CASE(I.PTADELAY) WHEN(1) THEN 'IP Office Delay' WHEN(2) THEN 'Applicant Delay' END,
			dbo.fn_DisplayBoolean(I.RECALCEVENTDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.SUPPRESSCALCULATION,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_EVENTCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_COUNTRYFLAGS CF on (CF.COUNTRYCODE=CR.COUNTRYCODE
							 and CF.FLAGNUMBER=I.CHECKCOUNTRYFLAG)
		left join "+@sUserName+".Imported_ACTIONS AO on (AO.ACTION=I.CREATEACTION)
		left join "+@sUserName+".Imported_ACTIONS AC on (AC.ACTION=I.CLOSEACTION)
		left join "+@sUserName+".Imported_EVENTS E on (E.EVENTNO=I.UPDATEFROMEVENT)
		left join "+@sUserName+".Imported_CASERELATION CX on (CX.RELATIONSHIP=I.FROMRELATIONSHIP)
		left join "+@sUserName+".Imported_ADJUSTMENT AJ on (AJ.ADJUSTMENT=I.ADJUSTMENT)
		left join EVENTCONTROL C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,6,5" ELSE "3,6,5" END
	
		select @sSQLString1,@sSQLString2,@sSQLString3,@sSQLString4,@sSQLString5,@sSQLString6
		
		Select	@ErrorCode=@@Error,
			@pnRowCount=@@rowcount
	End
End

-- Data Update from temporary table
-- Merge the imported data
-- @pnFunction = 2 describes the update of the system data from the temporary table
If  @ErrorCode=0
and @pnFunction=2
Begin
	-- RFC28125
	-- Load Index on on Imported_EVENTCONTROL to improve performance on DELETE
	If NOT EXISTS(	SELECT 1 FROM sys.indexes 
			WHERE name='XAK1Imported_EVENTCONTROL' AND object_id = OBJECT_ID(@sUserName+'.Imported_EVENTCONTROL') )
	Begin
		Set @sSQLString="
		CREATE  CLUSTERED INDEX XAK1Imported_EVENTCONTROL ON "+@sUserName+".Imported_EVENTCONTROL
		(
			CRITERIANO  ASC,
			EVENTNO	    ASC
		)"

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Remove any EVENTCONTROL rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete EVENTCONTROL
		From EVENTCONTROL EC
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=EC.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Where not exists
		(select 1
		 from "+@sUserName+".Imported_EVENTCONTROL I
		 where I.CRITERIANO=EC.CRITERIANO
		 and I.EVENTNO=EC.EVENTNO)"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any EVENTCONTROL rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete EVENTCONTROL
		From EVENTCONTROL EC
		Join CRITERIA CR on (CR.CRITERIANO=EC.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_EVENTCONTROL I on (I.CRITERIANO=C.CRITERIANO
								 and I.EVENTNO=EC.EVENTNO)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and EC.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString1="
		Update EVENTCONTROL
		set	PARENTCRITERIANO=I.PARENTCRITERIANO,
			PARENTEVENTNO=I.PARENTEVENTNO,
			NUMCYCLESALLOWED=I.NUMCYCLESALLOWED,
			WHICHDUEDATE=I.WHICHDUEDATE,
			COMPAREBOOLEAN=I.COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG=I.CHECKCOUNTRYFLAG,
			SAVEDUEDATE=I.SAVEDUEDATE,
			SPECIALFUNCTION=I.SPECIALFUNCTION,
			INITIALFEE=I.INITIALFEE,
			PAYFEECODE=I.PAYFEECODE,
			CREATEACTION=I.CREATEACTION,
			CLOSEACTION=I.CLOSEACTION,
			UPDATEFROMEVENT=I.UPDATEFROMEVENT,
			FROMRELATIONSHIP=I.FROMRELATIONSHIP,
			FROMANCESTOR=I.FROMANCESTOR,
			UPDATEMANUALLY=I.UPDATEMANUALLY,
			ADJUSTMENT=I.ADJUSTMENT,
			DOCUMENTNO=I.DOCUMENTNO,
			NOOFDOCS=I.NOOFDOCS,
			MANDATORYDOCS=I.MANDATORYDOCS,
			INHERITED=I.INHERITED,
			INSTRUCTIONTYPE=I.INSTRUCTIONTYPE,
			FLAGNUMBER=I.FLAGNUMBER,
			SETTHIRDPARTYON=I.SETTHIRDPARTYON,
			RELATIVECYCLE=I.RELATIVECYCLE,
			CREATECYCLE=I.CREATECYCLE,
			ESTIMATEFLAG=I.ESTIMATEFLAG,
			EXTENDPERIOD=I.EXTENDPERIOD,
			EXTENDPERIODTYPE=I.EXTENDPERIODTYPE,
			INITIALFEE2=I.INITIALFEE2,
			PAYFEECODE2=I.PAYFEECODE2,
			ESTIMATEFLAG2=I.ESTIMATEFLAG2,
			PTADELAY=I.PTADELAY,
			RECALCEVENTDATE=I.RECALCEVENTDATE
		from	EVENTCONTROL C
		join	"+@sUserName+".Imported_EVENTCONTROL I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO)
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"

		Set @sSQLString2="
		where 	I.NUMCYCLESALLOWED<>C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null)
		OR	I.WHICHDUEDATE<>C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is not null) OR (I.WHICHDUEDATE is not null and C.WHICHDUEDATE is null)
		OR	I.COMPAREBOOLEAN<>C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is not null) OR (I.COMPAREBOOLEAN is not null and C.COMPAREBOOLEAN is null)
		OR	I.CHECKCOUNTRYFLAG<>C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is not null) OR (I.CHECKCOUNTRYFLAG is not null and C.CHECKCOUNTRYFLAG is null)
		OR	I.SAVEDUEDATE<>C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is not null) OR (I.SAVEDUEDATE is not null and C.SAVEDUEDATE is null)
		OR	I.CREATEACTION<>C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null) OR (I.CREATEACTION is not null and C.CREATEACTION is null)
		OR	I.CLOSEACTION<>C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is not null) OR (I.CLOSEACTION is not null and C.CLOSEACTION is null)
		OR	I.UPDATEFROMEVENT<>C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is not null) OR (I.UPDATEFROMEVENT is not null and C.UPDATEFROMEVENT is null)
		OR	I.FROMRELATIONSHIP<>C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is not null) OR (I.FROMRELATIONSHIP is not null and C.FROMRELATIONSHIP is null)
		OR	I.FROMANCESTOR<>C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is not null) OR (I.FROMANCESTOR is not null and C.FROMANCESTOR is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.SETTHIRDPARTYON<>C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is not null) OR (I.SETTHIRDPARTYON is not null and C.SETTHIRDPARTYON is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.PTADELAY<>C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is not null) OR (I.PTADELAY is not null and C.PTADELAY is null)
		OR	isnull(I.RECALCEVENTDATE,0)<>isnull(C.RECALCEVENTDATE,0)"

		exec (@sSQLString1+@sSQLString2)

		Select	@ErrorCode=@@error,
			@pnRowCount=@@rowcount
	End 

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString1="
		Update EVENTCONTROL
		set	PARENTCRITERIANO=I.PARENTCRITERIANO,
			PARENTEVENTNO=I.PARENTEVENTNO,
			NUMCYCLESALLOWED=I.NUMCYCLESALLOWED,
			WHICHDUEDATE=I.WHICHDUEDATE,
			COMPAREBOOLEAN=I.COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG=I.CHECKCOUNTRYFLAG,
			SAVEDUEDATE=I.SAVEDUEDATE,
			SPECIALFUNCTION=I.SPECIALFUNCTION,
			INITIALFEE=I.INITIALFEE,
			PAYFEECODE=I.PAYFEECODE,
			CREATEACTION=I.CREATEACTION,
			CLOSEACTION=I.CLOSEACTION,
			UPDATEFROMEVENT=I.UPDATEFROMEVENT,
			FROMRELATIONSHIP=I.FROMRELATIONSHIP,
			FROMANCESTOR=I.FROMANCESTOR,
			UPDATEMANUALLY=I.UPDATEMANUALLY,
			ADJUSTMENT=I.ADJUSTMENT,
			DOCUMENTNO=I.DOCUMENTNO,
			NOOFDOCS=I.NOOFDOCS,
			MANDATORYDOCS=I.MANDATORYDOCS,
			INSTRUCTIONTYPE=I.INSTRUCTIONTYPE,
			FLAGNUMBER=I.FLAGNUMBER,
			SETTHIRDPARTYON=I.SETTHIRDPARTYON,
			RELATIVECYCLE=I.RELATIVECYCLE,
			CREATECYCLE=I.CREATECYCLE,
			ESTIMATEFLAG=I.ESTIMATEFLAG,
			EXTENDPERIOD=I.EXTENDPERIOD,
			EXTENDPERIODTYPE=I.EXTENDPERIODTYPE,
			INITIALFEE2=I.INITIALFEE2,
			PAYFEECODE2=I.PAYFEECODE2,
			ESTIMATEFLAG2=I.ESTIMATEFLAG2,
			PTADELAY=I.PTADELAY,
			RECALCEVENTDATE=I.RECALCEVENTDATE
		from	EVENTCONTROL C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_EVENTCONTROL I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO)
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"

		Set @sSQLString2="
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1
		AND    (I.NUMCYCLESALLOWED<>C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null)
		OR	I.WHICHDUEDATE<>C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is not null) OR (I.WHICHDUEDATE is not null and C.WHICHDUEDATE is null)
		OR	I.COMPAREBOOLEAN<>C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is not null) OR (I.COMPAREBOOLEAN is not null and C.COMPAREBOOLEAN is null)
		OR	I.CHECKCOUNTRYFLAG<>C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is not null) OR (I.CHECKCOUNTRYFLAG is not null and C.CHECKCOUNTRYFLAG is null)
		OR	I.SAVEDUEDATE<>C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is not null) OR (I.SAVEDUEDATE is not null and C.SAVEDUEDATE is null)
		OR	I.CREATEACTION<>C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null) OR (I.CREATEACTION is not null and C.CREATEACTION is null)
		OR	I.CLOSEACTION<>C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is not null) OR (I.CLOSEACTION is not null and C.CLOSEACTION is null)
		OR	I.UPDATEFROMEVENT<>C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is not null) OR (I.UPDATEFROMEVENT is not null and C.UPDATEFROMEVENT is null)
		OR	I.FROMRELATIONSHIP<>C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is not null) OR (I.FROMRELATIONSHIP is not null and C.FROMRELATIONSHIP is null)
		OR	I.FROMANCESTOR<>C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is not null) OR (I.FROMANCESTOR is not null and C.FROMANCESTOR is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.SETTHIRDPARTYON<>C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is not null) OR (I.SETTHIRDPARTYON is not null and C.SETTHIRDPARTYON is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.PTADELAY<>C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is not null) OR (I.PTADELAY is not null and C.PTADELAY is null)
		OR	isnull(I.RECALCEVENTDATE,0)=isnull(C.RECALCEVENTDATE,0) )"

		exec (@sSQLString1+@sSQLString2)

		Select	@ErrorCode=@@error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into EVENTCONTROL(
			CRITERIANO,
			EVENTNO,
			EVENTDESCRIPTION,
			DISPLAYSEQUENCE,
			PARENTCRITERIANO,
			PARENTEVENTNO,
			NUMCYCLESALLOWED,
			IMPORTANCELEVEL,
			WHICHDUEDATE,
			COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG,
			SAVEDUEDATE,
			STATUSCODE,
			RENEWALSTATUS,
			SPECIALFUNCTION,
			INITIALFEE,
			PAYFEECODE,
			CREATEACTION,
			STATUSDESC,
			CLOSEACTION,
			UPDATEFROMEVENT,
			FROMRELATIONSHIP,
			FROMANCESTOR,
			UPDATEMANUALLY,
			ADJUSTMENT,
			DOCUMENTNO,
			NOOFDOCS,
			MANDATORYDOCS,
			INHERITED,
			INSTRUCTIONTYPE,
			FLAGNUMBER,
			SETTHIRDPARTYON,
			RELATIVECYCLE,
			CREATECYCLE,
			ESTIMATEFLAG,
			EXTENDPERIOD,
			EXTENDPERIODTYPE,
			INITIALFEE2,
			PAYFEECODE2,
			ESTIMATEFLAG2,
			PTADELAY,
			RECALCEVENTDATE,
			SUPPRESSCALCULATION)
		select	I.CRITERIANO,
			I.EVENTNO,
			I.EVENTDESCRIPTION,
			I.DISPLAYSEQUENCE,
			I.PARENTCRITERIANO,
			I.PARENTEVENTNO,
			I.NUMCYCLESALLOWED,
			I.IMPORTANCELEVEL,
			I.WHICHDUEDATE,
			I.COMPAREBOOLEAN,
			I.CHECKCOUNTRYFLAG,
			I.SAVEDUEDATE,
			I.STATUSCODE,
			I.RENEWALSTATUS,
			I.SPECIALFUNCTION,
			I.INITIALFEE,
			I.PAYFEECODE,
			I.CREATEACTION,
			I.STATUSDESC,
			I.CLOSEACTION,
			I.UPDATEFROMEVENT,
			I.FROMRELATIONSHIP,
			I.FROMANCESTOR,
			I.UPDATEMANUALLY,
			I.ADJUSTMENT,
			I.DOCUMENTNO,
			I.NOOFDOCS,
			I.MANDATORYDOCS,
			I.INHERITED,
			I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.SETTHIRDPARTYON,
			I.RELATIVECYCLE,
			I.CREATECYCLE,
			I.ESTIMATEFLAG,
			I.EXTENDPERIOD,
			I.EXTENDPERIODTYPE,
			I.INITIALFEE2,
			I.PAYFEECODE2,
			I.ESTIMATEFLAG2,
			I.PTADELAY,
			I.RECALCEVENTDATE,
			I.SUPPRESSCALCULATION
		from "+@sUserName+".Imported_EVENTCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T		on (T.CRITERIANO=I.CRITERIANO)
		left join EVENTCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin

		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into EVENTCONTROL(
			CRITERIANO,
			EVENTNO,
			EVENTDESCRIPTION,
			DISPLAYSEQUENCE,
			PARENTCRITERIANO,
			PARENTEVENTNO,
			NUMCYCLESALLOWED,
			IMPORTANCELEVEL,
			WHICHDUEDATE,
			COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG,
			SAVEDUEDATE,
			STATUSCODE,
			RENEWALSTATUS,
			SPECIALFUNCTION,
			INITIALFEE,
			PAYFEECODE,
			CREATEACTION,
			STATUSDESC,
			CLOSEACTION,
			UPDATEFROMEVENT,
			FROMRELATIONSHIP,
			FROMANCESTOR,
			UPDATEMANUALLY,
			ADJUSTMENT,
			DOCUMENTNO,
			NOOFDOCS,
			MANDATORYDOCS,
			INHERITED,
			INSTRUCTIONTYPE,
			FLAGNUMBER,
			SETTHIRDPARTYON,
			RELATIVECYCLE,
			CREATECYCLE,
			ESTIMATEFLAG,
			EXTENDPERIOD,
			EXTENDPERIODTYPE,
			INITIALFEE2,
			PAYFEECODE2,
			ESTIMATEFLAG2,
			PTADELAY,
			RECALCEVENTDATE,
			SUPPRESSCALCULATION)
		select	IH.CRITERIANO,
			I.EVENTNO,
			I.EVENTDESCRIPTION,
			I.DISPLAYSEQUENCE,
			I.PARENTCRITERIANO,
			I.PARENTEVENTNO,
			I.NUMCYCLESALLOWED,
			I.IMPORTANCELEVEL,
			I.WHICHDUEDATE,
			I.COMPAREBOOLEAN,
			I.CHECKCOUNTRYFLAG,
			I.SAVEDUEDATE,
			I.STATUSCODE,
			I.RENEWALSTATUS,
			I.SPECIALFUNCTION,
			I.INITIALFEE,
			I.PAYFEECODE,
			I.CREATEACTION,
			I.STATUSDESC,
			I.CLOSEACTION,
			I.UPDATEFROMEVENT,
			I.FROMRELATIONSHIP,
			I.FROMANCESTOR,
			I.UPDATEMANUALLY,
			I.ADJUSTMENT,
			I.DOCUMENTNO,
			I.NOOFDOCS,
			I.MANDATORYDOCS,
			1,
			I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.SETTHIRDPARTYON,
			I.RELATIVECYCLE,
			I.CREATECYCLE,
			I.ESTIMATEFLAG,
			I.EXTENDPERIOD,
			I.EXTENDPERIODTYPE,
			I.INITIALFEE2,
			I.PAYFEECODE2,
			I.ESTIMATEFLAG2,
			I.PTADELAY,
			I.RECALCEVENTDATE,
			I.SUPPRESSCALCULATION
		from "+@sUserName+".Imported_EVENTCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join EVENTCONTROL C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.EVENTNO=I.EVENTNO)
		where C.CRITERIANO is null
		AND CR.USERDEFINEDRULE=1"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End
End

-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- (if no mapping is allowed return null)
If  @ErrorCode=0
and @pnFunction=3
Begin
	Set @sSQLString=null

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesEVENTCONTROL  to public
go

