-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesDUEDATECALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesDUEDATECALC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesDUEDATECALC.'
	drop procedure dbo.ip_RulesDUEDATECALC
	print '**** Creating procedure dbo.ip_RulesDUEDATECALC...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesDUEDATECALC
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesDUEDATECALC
-- VERSION : 10	
-- DESCRIPTION:	The comparison/display and merging of imported data for the DUEDATECALC table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove DUEDATECALC rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 21 Jan 2011	MF	19321	4	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 10 Dec 2012	MF	R13020	5	When checking for rows to update, now need to cater for situation where COMPARISON has a value but
--					COMPAREEVENT can be null (e.g. Not Exists, and Exists)
-- 12 Jul 2013	MF	R13596	6	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	7	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 06 Nov 2013	MF	R28125	8	Create Index on imported table to improve performance.
-- 17 Dec 2019	DL	DR-55255 9	XML File Not Importing All Updates on First Run
-- 07 Feb 2020	DL	DR-56253 10 LUS changes not appearing in comparison screens while using Law Update Tool
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


-- Prerequisite that the IMPORTED_DUEDATECALC table has been loaded

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
	-- Apply the Mapping if it exists

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_DUEDATECALC
		SET EVENTNO = M.MAPVALUE
		FROM "+@sUserName+".Imported_DUEDATECALC C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='EVENTS'
				and M.MAPCOLUMN  ='EVENTNO'
				and M.SOURCEVALUE=C.EVENTNO)
		WHERE M.MAPVALUE is not null
		and C.COMPAREEVENT is null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DUEDATECALC
			SET FROMEVENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_DUEDATECALC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.FROMEVENT)
			WHERE M.MAPVALUE is not null
			and C.COMPAREEVENT is null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DUEDATECALC
			SET ADJUSTMENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_DUEDATECALC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ADJUSTMENT'
					and M.MAPCOLUMN  ='ADJUSTMENT'
					and M.SOURCEVALUE=C.ADJUSTMENT)
			WHERE M.MAPVALUE is not null
			and C.COMPAREEVENT is null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DUEDATECALC
			SET OVERRIDELETTER = M.MAPVALUE
			FROM "+@sUserName+".Imported_DUEDATECALC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='LETTER'
					and M.MAPCOLUMN  ='LETTERNO'
					and M.SOURCEVALUE=C.OVERRIDELETTER)
			WHERE M.MAPVALUE is not null
			and C.COMPAREEVENT is null"

		exec @ErrorCode=sp_executesql @sSQLString
	end
End

-- RFC28125
-- Load Index on on Imported_EVENTCONTROL to improve performance on DELETE
If NOT EXISTS(	SELECT 1 FROM sys.indexes 
		WHERE name='XAK1Imported_DUEDATECALC' AND object_id = OBJECT_ID(@sUserName+'.Imported_DUEDATECALC') )
Begin
	Set @sSQLString="
	CREATE  CLUSTERED INDEX XAK1Imported_DUEDATECALC ON "+@sUserName+".Imported_DUEDATECALC
	(
		CRITERIANO  ASC,
		EVENTNO	    ASC, 
		CYCLENUMBER ASC,
		COUNTRYCODE ASC,
		COMPARISON  ASC,
		SEQUENCE    ASC
	)"

	exec @ErrorCode=sp_executesql @sSQLString
End


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3		as 'Comparison',
			NULL		as Match,
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
					as 'Imported Criteria Description',
			EC.EVENTDESCRIPTION as 'Imported Event',
			I.CYCLENUMBER	as 'Imported Cycle Number',
			I.COUNTRYCODE	as 'Imported Country Code',
			E.EVENTDESCRIPTION as 'Imported From Event',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END		as 'Imported Relative Cycle',
			CASE(I.OPERATOR)
				WHEN('S') THEN '-'
				WHEN('A') THEN '+'
			END		as 'Imported Operator',
			I.DEADLINEPERIOD as 'Imported Deadline Period',
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
				WHEN('E') THEN 'Entered'	
				WHEN('1') THEN 'Period 1'	
				WHEN('2') THEN 'Period 2'	
				WHEN('3') THEN 'Period 3'	
			END		as 'Imported Period Type',
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END		as 'Imported Event Date Flag',
			A.ADJUSTMENTDESC as 'Imported Adjustment',
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
					as 'Imported Must Exist',
			CASE (I.WORKDAY)
				WHEN(1) THEN 'Next'
				WHEN(2) THEN 'Last'
			END		as 'Imported Workday',
			CR.DESCRIPTION+' {'+convert(varchar,C.CRITERIANO)+'}'
					as 'Criteria Description',
			EC.EVENTDESCRIPTION as 'Event',
			C.CYCLENUMBER	as 'Cycle Number',
			C.COUNTRYCODE	as 'Country Code',
			E.EVENTDESCRIPTION as 'From Event',
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END		as 'Relative Cycle',
			CASE(C.OPERATOR)
				WHEN('S') THEN '-'
				WHEN('A') THEN '+'
			END		as 'Operator',
			C.DEADLINEPERIOD	as 'Deadline Period',
			CASE (C.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
				WHEN('E') THEN 'Entered'	
				WHEN('1') THEN 'Period 1'	
				WHEN('2') THEN 'Period 2'	
				WHEN('3') THEN 'Period 3'	
			END		as 'Period Type',
			CASE (C.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END		as 'Event Date Flag',
			A.ADJUSTMENTDESC as 'Adjustment',
			dbo.fn_DisplayBoolean(C.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
					as 'Must Exist',
			CASE (C.WORKDAY)
				WHEN(1) THEN 'Next'
				WHEN(2) THEN 'Last'
			END		as 'Imported Workday'
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
					and EC.EVENTNO=I.EVENTNO)
		left join EVENTS E	on (E.EVENTNO=I.FROMEVENT)
		left join ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString2="
		join DUEDATECALC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and(C.CYCLENUMBER=I.CYCLENUMBER OR (C.CYCLENUMBER is null and I.CYCLENUMBER is null))
					and(C.COUNTRYCODE=I.COUNTRYCODE OR (C.COUNTRYCODE is null and I.COUNTRYCODE is null))
					and C.SEQUENCE=I.SEQUENCE
					and C.COMPARISON is null)
		where	I.COMPARISON is null
		and	(I.FROMEVENT=C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is null))
		and	(I.RELATIVECYCLE=C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
		and	(I.OPERATOR=C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is null))
		and	(I.DEADLINEPERIOD=C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is null))
		and	(I.PERIODTYPE=C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is null))
		and	(I.EVENTDATEFLAG=C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is null))
		and	(I.ADJUSTMENT=C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
		and	(I.MUSTEXIST=C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is null))
		and	(I.WORKDAY=C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is null))
		and	(I.MESSAGE2FLAG=C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is null))
		and	(I.SUPPRESSREMINDERS=C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is null))
		and	(I.OVERRIDELETTER=C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is null))"

		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			I.CYCLENUMBER,
			I.COUNTRYCODE,
			E1.EVENTDESCRIPTION,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE(I.OPERATOR)
				WHEN('S') THEN '-'
				WHEN('A') THEN '+'
			END,
			I.DEADLINEPERIOD,
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
				WHEN('E') THEN 'Entered'	
				WHEN('1') THEN 'Period 1'	
				WHEN('2') THEN 'Period 2'	
				WHEN('3') THEN 'Period 3'	
			END,
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			A1.ADJUSTMENTDESC,
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE (I.WORKDAY)
				WHEN(1) THEN 'Next'
				WHEN(2) THEN 'Last'
			END,
			CR1.DESCRIPTION+' {'+convert(varchar,C.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			C.CYCLENUMBER,
			C.COUNTRYCODE,
			E1.EVENTDESCRIPTION,
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE(C.OPERATOR)
				WHEN('S') THEN '-'
				WHEN('A') THEN '+'
			END,
			C.DEADLINEPERIOD,
			CASE (C.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
				WHEN('E') THEN 'Entered'	
				WHEN('1') THEN 'Period 1'	
				WHEN('2') THEN 'Period 2'	
				WHEN('3') THEN 'Period 3'	
			END,
			CASE (C.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			A1.ADJUSTMENTDESC,
			dbo.fn_DisplayBoolean(C.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE (C.WORKDAY)
				WHEN(1) THEN 'Next'
				WHEN(2) THEN 'Last'
			END
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
								and EC.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.FROMEVENT)
		left join "+@sUserName+".Imported_ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString4="
		join DUEDATECALC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and(C.CYCLENUMBER=I.CYCLENUMBER OR (C.CYCLENUMBER is null and I.CYCLENUMBER is null))
					and(C.COUNTRYCODE=I.COUNTRYCODE OR (C.COUNTRYCODE is null and I.COUNTRYCODE is null))
					and C.SEQUENCE=I.SEQUENCE
					and C.COMPARISON is null)
		join CRITERIA CR1	on (CR1.CRITERIANO=I.CRITERIANO)
		join EVENTCONTROL EC1	on (EC1.CRITERIANO=I.CRITERIANO
					and EC1.EVENTNO=I.EVENTNO)
		left join EVENTS E1	on (E1.EVENTNO=C.FROMEVENT)
		left join ADJUSTMENT A1	on (A1.ADJUSTMENT=C.ADJUSTMENT)
		where   I.COMPARISON is null
		and ( 	I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.DEADLINEPERIOD<>C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is not null) OR (I.DEADLINEPERIOD is not null and C.DEADLINEPERIOD is null)
		OR	I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) OR (I.MUSTEXIST is not null and C.MUSTEXIST is null)
		OR	I.WORKDAY<>C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is not null) OR (I.WORKDAY is not null and C.WORKDAY is null)
		OR	I.MESSAGE2FLAG<>C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is not null) OR (I.MESSAGE2FLAG is not null and C.MESSAGE2FLAG is null)
		OR	I.SUPPRESSREMINDERS<>C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is not null) OR (I.SUPPRESSREMINDERS is not null and C.SUPPRESSREMINDERS is null)
		OR	I.OVERRIDELETTER<>C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is not null) OR (I.OVERRIDELETTER is not null and C.OVERRIDELETTER is null))"
		-- DR-56253 Add filter "and C.COMPARISON is null" so that report dislays new due date rule where the key matches comparison rule.
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			I.CYCLENUMBER,
			I.COUNTRYCODE,
			E.EVENTDESCRIPTION,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE(I.OPERATOR)
				WHEN('S') THEN '-'
				WHEN('A') THEN '+'
			END,
			I.DEADLINEPERIOD,
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
				WHEN('E') THEN 'Entered'	
				WHEN('1') THEN 'Period 1'	
				WHEN('2') THEN 'Period 2'	
				WHEN('3') THEN 'Period 3'	
			END,
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			A.ADJUSTMENTDESC,
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE (I.WORKDAY)
				WHEN(1) THEN 'Next'
				WHEN(2) THEN 'Last'
			END,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E		on (E.EVENTNO=I.FROMEVENT)
		left join "+@sUserName+".Imported_ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString6="
		left join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO
					 and C.SEQUENCE=I.SEQUENCE
					 and C.COMPARISON is null)
		where C.CRITERIANO is null
		and I.COMPARISON is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5,6" ELSE "3,4,5,6" END
	
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
	-- Remove any DUEDATECALC rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DUEDATECALC
		From DUEDATECALC DD
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=DD.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DUEDATECALC I	on (I.CRITERIANO=DD.CRITERIANO
						and I.EVENTNO=DD.EVENTNO
						and(I.CYCLENUMBER=DD.CYCLENUMBER OR (I.CYCLENUMBER is null and DD.CYCLENUMBER is null))
						and(I.COUNTRYCODE=DD.COUNTRYCODE OR (I.COUNTRYCODE is null and DD.COUNTRYCODE is null))
						and I.COMPARISON is null
						and I.SEQUENCE=DD.SEQUENCE)
		Where I.CRITERIANO is null
		and DD.COMPARISON is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End
	-- Remove any DUEDATECALC rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DUEDATECALC
		From DUEDATECALC DD
		Join CRITERIA CR on (CR.CRITERIANO=DD.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DUEDATECALC I	on (I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=DD.EVENTNO
						and(I.CYCLENUMBER=DD.CYCLENUMBER OR (I.CYCLENUMBER is null and DD.CYCLENUMBER is null))
						and(I.COUNTRYCODE=DD.COUNTRYCODE OR (I.COUNTRYCODE is null and DD.COUNTRYCODE is null))
						and I.COMPARISON is null
						and I.SEQUENCE=DD.SEQUENCE)
		Where I.CRITERIANO is null
		and DD.COMPARISON is null
		and CR.USERDEFINEDRULE=1
		and DD.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- DR-55255 XML File Not Importing All Updates on First Run
	-- Remove any DUEDATECALC comparison rows that do not exist in the imported table.
	-- Note: We do the remove of comparison rule here because they are stored in the same table as due date calc rule DUEDATECALC.
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DUEDATECALC
		From DUEDATECALC DD
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=DD.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DUEDATECALC I	on (I.CRITERIANO=DD.CRITERIANO
						and I.EVENTNO=DD.EVENTNO
						and(I.CYCLENUMBER=DD.CYCLENUMBER OR (I.CYCLENUMBER is null and DD.CYCLENUMBER is null))
						and(I.COUNTRYCODE=DD.COUNTRYCODE OR (I.COUNTRYCODE is null and DD.COUNTRYCODE is null))
						and I.COMPARISON is not null
						and I.SEQUENCE=DD.SEQUENCE)
		Where I.CRITERIANO is null
		and DD.COMPARISON is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- DR-55255 XML File Not Importing All Updates on First Run
	-- Remove any DUEDATECALC rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	-- Note: We do the remove of comparison rule here because they are stored in the same table as due date calc rule DUEDATECALC.
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DUEDATECALC
		From DUEDATECALC DD
		Join CRITERIA CR on (CR.CRITERIANO=DD.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DUEDATECALC I	on (I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=DD.EVENTNO
						and(I.CYCLENUMBER=DD.CYCLENUMBER OR (I.CYCLENUMBER is null and DD.CYCLENUMBER is null))
						and(I.COUNTRYCODE=DD.COUNTRYCODE OR (I.COUNTRYCODE is null and DD.COUNTRYCODE is null))
						and I.COMPARISON is not null
						and I.SEQUENCE=DD.SEQUENCE)
		Where I.CRITERIANO is null
		and DD.COMPARISON is not null
		and CR.USERDEFINEDRULE=1
		and DD.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End


	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DUEDATECALC
		set	FROMEVENT=I.FROMEVENT,
			RELATIVECYCLE=I.RELATIVECYCLE,
			OPERATOR=I.OPERATOR,
			DEADLINEPERIOD=I.DEADLINEPERIOD,
			PERIODTYPE=I.PERIODTYPE,
			EVENTDATEFLAG=I.EVENTDATEFLAG,
			ADJUSTMENT=I.ADJUSTMENT,
			MUSTEXIST=I.MUSTEXIST,
			WORKDAY=I.WORKDAY,
			MESSAGE2FLAG=I.MESSAGE2FLAG,
			SUPPRESSREMINDERS=I.SUPPRESSREMINDERS,
			OVERRIDELETTER=I.OVERRIDELETTER,
			INHERITED=I.INHERITED,
			COMPAREEVENTFLAG=I.COMPAREEVENTFLAG,
			COMPARECYCLE=I.COMPARECYCLE
		from	DUEDATECALC C
		join	"+@sUserName+".Imported_DUEDATECALC I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and(I.CYCLENUMBER=C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
						and(I.COUNTRYCODE=C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
						and I.COMPARISON is null
						and I.SEQUENCE=C.SEQUENCE)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where   C.COMPARISON is null
		and ( 	I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.DEADLINEPERIOD<>C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is not null) OR (I.DEADLINEPERIOD is not null and C.DEADLINEPERIOD is null)
		OR	I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) OR (I.MUSTEXIST is not null and C.MUSTEXIST is null)
		OR	I.WORKDAY<>C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is not null) OR (I.WORKDAY is not null and C.WORKDAY is null)
		OR	I.MESSAGE2FLAG<>C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is not null) OR (I.MESSAGE2FLAG is not null and C.MESSAGE2FLAG is null)
		OR	I.SUPPRESSREMINDERS<>C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is not null) OR (I.SUPPRESSREMINDERS is not null and C.SUPPRESSREMINDERS is null)
		OR	I.OVERRIDELETTER<>C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is not null) OR (I.OVERRIDELETTER is not null and C.OVERRIDELETTER is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DUEDATECALC
		set	FROMEVENT=I.FROMEVENT,
			RELATIVECYCLE=I.RELATIVECYCLE,
			OPERATOR=I.OPERATOR,
			DEADLINEPERIOD=I.DEADLINEPERIOD,
			PERIODTYPE=I.PERIODTYPE,
			EVENTDATEFLAG=I.EVENTDATEFLAG,
			ADJUSTMENT=I.ADJUSTMENT,
			MUSTEXIST=I.MUSTEXIST,
			WORKDAY=I.WORKDAY,
			MESSAGE2FLAG=I.MESSAGE2FLAG,
			SUPPRESSREMINDERS=I.SUPPRESSREMINDERS,
			OVERRIDELETTER=I.OVERRIDELETTER,
			COMPAREEVENTFLAG=I.COMPAREEVENTFLAG,
			COMPARECYCLE=I.COMPARECYCLE
		from	DUEDATECALC C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_DUEDATECALC I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO
						and(I.CYCLENUMBER=C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
						and(I.COUNTRYCODE=C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
						and I.COMPARISON is null
						and I.SEQUENCE=C.SEQUENCE)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1
		AND     C.COMPARISON is null
		and ( 	I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.DEADLINEPERIOD<>C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is not null) OR (I.DEADLINEPERIOD is not null and C.DEADLINEPERIOD is null)
		OR	I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) OR (I.MUSTEXIST is not null and C.MUSTEXIST is null)
		OR	I.WORKDAY<>C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is not null) OR (I.WORKDAY is not null and C.WORKDAY is null)
		OR	I.MESSAGE2FLAG<>C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is not null) OR (I.MESSAGE2FLAG is not null and C.MESSAGE2FLAG is null)
		OR	I.SUPPRESSREMINDERS<>C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is not null) OR (I.SUPPRESSREMINDERS is not null and C.SUPPRESSREMINDERS is null)
		OR	I.OVERRIDELETTER<>C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is not null) OR (I.OVERRIDELETTER is not null and C.OVERRIDELETTER is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into DUEDATECALC(
			CRITERIANO,
			EVENTNO,
			SEQUENCE,
			CYCLENUMBER,
			COUNTRYCODE,
			FROMEVENT,
			RELATIVECYCLE,
			OPERATOR,
			DEADLINEPERIOD,
			PERIODTYPE,
			EVENTDATEFLAG,
			ADJUSTMENT,
			MUSTEXIST,
			COMPARISON,
			COMPAREEVENT,
			WORKDAY,
			MESSAGE2FLAG,
			SUPPRESSREMINDERS,
			OVERRIDELETTER,
			INHERITED,
			COMPAREEVENTFLAG,
			COMPARECYCLE)
		select	I.CRITERIANO,
			I.EVENTNO,
			I.SEQUENCE,
			I.CYCLENUMBER,
			I.COUNTRYCODE,
			I.FROMEVENT,
			I.RELATIVECYCLE,
			I.OPERATOR,
			I.DEADLINEPERIOD,
			I.PERIODTYPE,
			I.EVENTDATEFLAG,
			I.ADJUSTMENT,
			I.MUSTEXIST,
			I.COMPARISON,
			I.COMPAREEVENT,
			I.WORKDAY,
			I.MESSAGE2FLAG,
			I.SUPPRESSREMINDERS,
			I.OVERRIDELETTER,
			I.INHERITED,
			I.COMPAREEVENTFLAG,
			I.COMPARECYCLE
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join DUEDATECALC C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
		where C.CRITERIANO is null
		and I.COMPARISON is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin
		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into DUEDATECALC(
			CRITERIANO,
			EVENTNO,
			SEQUENCE,
			CYCLENUMBER,
			COUNTRYCODE,
			FROMEVENT,
			RELATIVECYCLE,
			OPERATOR,
			DEADLINEPERIOD,
			PERIODTYPE,
			EVENTDATEFLAG,
			ADJUSTMENT,
			MUSTEXIST,
			WORKDAY,
			MESSAGE2FLAG,
			SUPPRESSREMINDERS,
			OVERRIDELETTER,
			INHERITED,
			COMPAREEVENTFLAG,
			COMPARECYCLE)
		select	IH.CRITERIANO,
			I.EVENTNO,
			I.SEQUENCE,
			I.CYCLENUMBER,
			I.COUNTRYCODE,
			I.FROMEVENT,
			I.RELATIVECYCLE,
			I.OPERATOR,
			I.DEADLINEPERIOD,
			I.PERIODTYPE,
			I.EVENTDATEFLAG,
			I.ADJUSTMENT,
			I.MUSTEXIST,
			I.WORKDAY,
			I.MESSAGE2FLAG,
			I.SUPPRESSREMINDERS,
			I.OVERRIDELETTER,
			1,
			I.COMPAREEVENTFLAG,
			I.COMPARECYCLE
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join DUEDATECALC C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
		where C.CRITERIANO is null
		and I.COMPARISON is null
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
grant execute on dbo.ip_RulesDUEDATECALC  to public
go

