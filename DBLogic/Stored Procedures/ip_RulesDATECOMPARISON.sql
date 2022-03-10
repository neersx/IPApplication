-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesDATECOMPARISON
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesDATECOMPARISON]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesDATECOMPARISON.'
	drop procedure dbo.ip_RulesDATECOMPARISON
	print '**** Creating procedure dbo.ip_RulesDATECOMPARISON...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesDATECOMPARISON
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesDATECOMPARISON
-- VERSION :	10
-- DESCRIPTION:	The comparison/display and merging of imported data for the DUEDATECALC table - Comparison rows
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove DUEDATECALC comparison rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 30 Aug 2004	MF	10421	3	Comparisons rows were not being returned due to error in SQL.
-- 23 Aug 2006	MF	13299	4	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 27 Jan 2009	MF	17312	5	Only returne rows if the COMPARISON column is not null. This is because the
--					COMPAREEVENT may now be null under some situations.
-- 17 Apr 2009	MF	16955	6	Export new columns on DUEDATECALC table for COMPARERELATIONSHIP,  COMPAREDATE,  COMPARESYSTEMDATE
-- 10 Dec 2012	MF	R13020	7	When checking for rows to update, now need to cater for situation where COMPARISON has a value but
--					COMPAREEVENT can be null (e.g. Not Exists, and Exists)
-- 12 Jul 2013	MF	R13596	8	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 21 Jun 2013	MF	R13434	9	Retrofit of above changes for SQA16955 and RFC13020
-- 06 Nov 2013	MF	R28126	10	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
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
		and C.COMPAREEVENT is not null"

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
			and C.COMPAREEVENT is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DUEDATECALC
			SET COMPAREEVENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_DUEDATECALC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.COMPAREEVENT)
			WHERE M.MAPVALUE is not null
			and C.COMPAREEVENT is not null"

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
			and C.COMPAREEVENT is not null"

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
		select	3		as 'Comparison',
			NULL		as Match,
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
					as 'Imported Criteria Description',
			EC.EVENTDESCRIPTION as 'Imported Event',
			E.EVENTDESCRIPTION as 'Imported From Event',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END		as 'Imported Relative Cycle',
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END		as 'Imported Event Date Flag',
			I.COMPARISON		as 'Imported Comparison',
			CE.EVENTDESCRIPTION 	as 'Imported Compare Event',
			CASE (I.COMPAREEVENTFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END			as 'Imported Compare Event Flag',
			CASE(I.COMPARECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Imported Compare Cycle',
			I.COMPARERELATIONSHIP as 'Imported Relationship',  
			I.COMPAREDATE	as 'Imported Compare Date',
			dbo.fn_DisplayBoolean(I.COMPARESYSTEMDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
					as 'Imported Compare System Date',
			CR.DESCRIPTION+' {'+convert(varchar,C.CRITERIANO)+'}'
					as 'Criteria Description',
			EC.EVENTDESCRIPTION as 'Event',
			E.EVENTDESCRIPTION as 'From Event',
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END		as 'Relative Cycle',
			CASE (C.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END		as 'Event Date Flag',
			I.COMPARISON		as 'Comparison',
			CE.EVENTDESCRIPTION 	as 'Compare Event',
			CASE (I.COMPAREEVENTFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END			as 'Compare Event Flag',
			CASE(I.COMPARECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Compare Cycle',
			C.COMPARERELATIONSHIP as 'Compare Relationship',  
			C.COMPAREDATE	as 'Compare Date',
			dbo.fn_DisplayBoolean(C.COMPARESYSTEMDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
					as 'Compare System Date'
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
								and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E		on (E.EVENTNO=I.FROMEVENT)
		left join "+@sUserName+".Imported_EVENTS CE	on (CE.EVENTNO=I.COMPAREEVENT)"
		Set @sSQLString2="
		join DUEDATECALC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and(C.CYCLENUMBER=I.CYCLENUMBER OR (C.CYCLENUMBER is null and I.CYCLENUMBER is null))
					and(C.COUNTRYCODE=I.COUNTRYCODE OR (C.COUNTRYCODE is null and I.COUNTRYCODE is null))
					and C.SEQUENCE=I.SEQUENCE)
		where	(I.FROMEVENT=C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is null))
		and	(I.RELATIVECYCLE=C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
		and	(I.EVENTDATEFLAG=C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is null))
		and	(I.COMPARISON=C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is null))
		and	(I.COMPAREEVENT=C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is null))
		and	(I.COMPAREEVENTFLAG=C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is null))
		and	(I.COMPARECYCLE=C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is null))
		and	(I.COMPAREDATE=C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is null))
		and	(I.COMPARERELATIONSHIP=C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is null))
		and	(I.COMPARESYSTEMDATE=C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			E.EVENTDESCRIPTION,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			I.COMPARISON,
			CE.EVENTDESCRIPTION,
			CASE (I.COMPAREEVENTFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			CASE(I.COMPARECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			I.COMPARERELATIONSHIP,  
			I.COMPAREDATE,
			dbo.fn_DisplayBoolean(I.COMPARESYSTEMDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CR1.DESCRIPTION+' {'+convert(varchar,C.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			E1.EVENTDESCRIPTION,
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (C.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			C.COMPARISON,
			CE1.EVENTDESCRIPTION,
			CASE (C.COMPAREEVENTFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			CASE(C.COMPARECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			C.COMPARERELATIONSHIP,  
			C.COMPAREDATE,
			dbo.fn_DisplayBoolean(C.COMPARESYSTEMDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
								and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E		on (E.EVENTNO=I.FROMEVENT)
		left join "+@sUserName+".Imported_EVENTS CE	on (CE.EVENTNO=I.COMPAREEVENT)"
		Set @sSQLString4="
		join DUEDATECALC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and(C.CYCLENUMBER=I.CYCLENUMBER OR (C.CYCLENUMBER is null and I.CYCLENUMBER is null))
					and(C.COUNTRYCODE=I.COUNTRYCODE OR (C.COUNTRYCODE is null and I.COUNTRYCODE is null))
					and C.SEQUENCE=I.SEQUENCE)
		join CRITERIA CR1	on (CR1.CRITERIANO=I.CRITERIANO)
		join EVENTCONTROL EC1	on (EC1.CRITERIANO=I.CRITERIANO
					and EC1.EVENTNO=I.EVENTNO)
		join EVENTS E1		on (E1.EVENTNO=C.FROMEVENT)
		left join EVENTS CE1	on (CE1.EVENTNO=C.COMPAREEVENT)
		where   I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.COMPARISON<>C.COMPARISON
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.COMPAREEVENTFLAG<>C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is not null) OR (I.COMPAREEVENTFLAG is not null and C.COMPAREEVENTFLAG is null)
		OR	I.COMPARECYCLE<>C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is not null) OR (I.COMPARECYCLE is not null and C.COMPARECYCLE is null)
		OR	I.COMPARERELATIONSHIP<>C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is not null) OR (I.COMPARERELATIONSHIP is not null and C.COMPARERELATIONSHIP is null)
		OR	I.COMPAREDATE<>C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is not null) OR (I.COMPAREDATE is not null and C.COMPAREDATE is null)
		OR	I.COMPARESYSTEMDATE<>C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is not null) OR (I.COMPARESYSTEMDATE is not null and C.COMPARESYSTEMDATE is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			E.EVENTDESCRIPTION,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (I.EVENTDATEFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			I.COMPARISON,
			CE.EVENTDESCRIPTION,
			CASE (I.COMPAREEVENTFLAG)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			CASE(I.COMPARECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			I.COMPARERELATIONSHIP,  
			I.COMPAREDATE,
			dbo.fn_DisplayBoolean(I.COMPARESYSTEMDATE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
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
		left join "+@sUserName+".Imported_EVENTS CE	on (CE.EVENTNO=I.COMPAREEVENT)"
		Set @sSQLString6="
		left join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO
					 and C.SEQUENCE=I.SEQUENCE)
		where C.CRITERIANO is null
		and I.COMPARISON is not null
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
	-- Remove any DUEDATECALC comparison rows that do not exist in the imported table
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
			COMPARISON=I.COMPARISON,
			COMPAREEVENT=I.COMPAREEVENT,
			WORKDAY=I.WORKDAY,
			MESSAGE2FLAG=I.MESSAGE2FLAG,
			SUPPRESSREMINDERS=I.SUPPRESSREMINDERS,
			OVERRIDELETTER=I.OVERRIDELETTER,
			INHERITED=I.INHERITED,
			COMPAREEVENTFLAG=I.COMPAREEVENTFLAG,
			COMPARECYCLE=I.COMPARECYCLE,
			COMPARERELATIONSHIP=I.COMPARERELATIONSHIP,
			COMPAREDATE=I.COMPAREDATE,
			COMPARESYSTEMDATE=I.COMPARESYSTEMDATE
		from	DUEDATECALC C
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		join	"+@sUserName+".Imported_DUEDATECALC I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and(I.CYCLENUMBER=C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
						and(I.COUNTRYCODE=C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
						and I.COMPARISON is not null
						and I.SEQUENCE=C.SEQUENCE)
		where	C.COMPARISON is not null
		and (   I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.COMPARISON<>C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is not null) OR (I.COMPARISON is not null and C.COMPARISON is null)
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.COMPAREEVENTFLAG<>C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is not null) OR (I.COMPAREEVENTFLAG is not null and C.COMPAREEVENTFLAG is null)
		OR	I.COMPARECYCLE<>C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is not null) OR (I.COMPARECYCLE is not null and C.COMPARECYCLE is null)
		OR	I.COMPARERELATIONSHIP<>C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is not null) OR (I.COMPARERELATIONSHIP is not null and C.COMPARERELATIONSHIP is null)
		OR	I.COMPAREDATE<>C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is not null) OR (I.COMPAREDATE is not null and C.COMPAREDATE is null)
		OR	I.COMPARESYSTEMDATE<>C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is not null) OR (I.COMPARESYSTEMDATE is not null and C.COMPARESYSTEMDATE is null))"
		
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
			COMPARISON=I.COMPARISON,
			COMPAREEVENT=I.COMPAREEVENT,
			WORKDAY=I.WORKDAY,
			MESSAGE2FLAG=I.MESSAGE2FLAG,
			SUPPRESSREMINDERS=I.SUPPRESSREMINDERS,
			OVERRIDELETTER=I.OVERRIDELETTER,
			COMPAREEVENTFLAG=I.COMPAREEVENTFLAG,
			COMPARECYCLE=I.COMPARECYCLE,
			COMPARERELATIONSHIP=I.COMPARERELATIONSHIP,
			COMPAREDATE=I.COMPAREDATE,
			COMPARESYSTEMDATE=I.COMPARESYSTEMDATE
		from	DUEDATECALC C
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_DUEDATECALC I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO
						and(I.CYCLENUMBER=C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
						and(I.COUNTRYCODE=C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
						and I.COMPARISON is not null
						and I.SEQUENCE=C.SEQUENCE)
		where	C.COMPARISON is not null
		AND	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1
		and (   I.FROMEVENT<>C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) OR (I.FROMEVENT is not null and C.FROMEVENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.EVENTDATEFLAG<>C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null)
		OR	I.COMPARISON<>C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is not null) OR (I.COMPARISON is not null and C.COMPARISON is null)
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.COMPAREEVENTFLAG<>C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is not null) OR (I.COMPAREEVENTFLAG is not null and C.COMPAREEVENTFLAG is null)
		OR	I.COMPARECYCLE<>C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is not null) OR (I.COMPARECYCLE is not null and C.COMPARECYCLE is null)
		OR	I.COMPARERELATIONSHIP<>C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is not null) OR (I.COMPARERELATIONSHIP is not null and C.COMPARERELATIONSHIP is null)
		OR	I.COMPAREDATE<>C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is not null) OR (I.COMPAREDATE is not null and C.COMPAREDATE is null)
		OR	I.COMPARESYSTEMDATE<>C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is not null) OR (I.COMPARESYSTEMDATE is not null and C.COMPARESYSTEMDATE is null))"
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
			COMPARECYCLE,
			COMPARERELATIONSHIP,
			COMPAREDATE,
			COMPARESYSTEMDATE)
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
			I.COMPARECYCLE,
			I.COMPARERELATIONSHIP,
			I.COMPAREDATE,
			I.COMPARESYSTEMDATE
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T    on ( T.CRITERIANO=I.CRITERIANO)
		left join DUEDATECALC C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
		where C.CRITERIANO is null
		and I.COMPARISON is not null"

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
			COMPARECYCLE,
			COMPARERELATIONSHIP,
			COMPAREDATE,
			COMPARESYSTEMDATE)
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
			I.COMPARISON,
			I.COMPAREEVENT,
			I.WORKDAY,
			I.MESSAGE2FLAG,
			I.SUPPRESSREMINDERS,
			I.OVERRIDELETTER,
			1,
			I.COMPAREEVENTFLAG,
			I.COMPARECYCLE,
			I.COMPARERELATIONSHIP,
			I.COMPAREDATE,
			I.COMPARESYSTEMDATE
		from "+@sUserName+".Imported_DUEDATECALC I
		join "+@sUserName+".CRITERIAALLOWED T on ( T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join DUEDATECALC C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
		where C.CRITERIANO is null
		and I.COMPARISON is not null
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
grant execute on dbo.ip_RulesDATECOMPARISON  to public
go

