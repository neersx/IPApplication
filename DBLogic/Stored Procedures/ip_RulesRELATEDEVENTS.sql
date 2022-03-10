-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesRELATEDEVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesRELATEDEVENTS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesRELATEDEVENTS.'
	drop procedure dbo.ip_RulesRELATEDEVENTS
	print '**** Creating procedure dbo.ip_RulesRELATEDEVENTS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesRELATEDEVENTS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesRELATEDEVENTS
-- VERSION :	9
-- DESCRIPTION:	The comparison/display and merging of imported data for the RELATEDEVENTS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove RELATEDEVENTS rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 09 Sep 2008	MF	16899	4	Two new columns added to RELATEDEVENTS (CLEAREVENTONDUECHANGE
--					and CLEARDUEONDUECHANGE)
-- 13 Nov 2008	MF	16899	5	Revisit.
-- 21 Jan 2011	MF	19321	6	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 12 Jul 2013	MF	R13596	7	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	8	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 31 Aug 2016	MF	65359	9	Some matching related events rows are not being returned. Problem with SQL Query when ADJUSTMENT is null.
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


-- Prerequisite that the IMPORTED_RELATEDEVENTS table has been loaded

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
		"UPDATE "+@sUserName+".Imported_RELATEDEVENTS
		SET EVENTNO = M.MAPVALUE
		FROM "+@sUserName+".Imported_RELATEDEVENTS C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='EVENTS'
				and M.MAPCOLUMN  ='EVENTNO'
				and M.SOURCEVALUE=C.EVENTNO)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_RELATEDEVENTS
			SET RELATEDEVENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_RELATEDEVENTS C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.RELATEDEVENT)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_RELATEDEVENTS
			SET ADJUSTMENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_RELATEDEVENTS C
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
			EC.EVENTDESCRIPTION	as 'Imported Event',
			E.EVENTDESCRIPTION	as 'Imported Related Event',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Imported Cycle',
			dbo.fn_DisplayBoolean(I.CLEAREVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Clear Event',
			dbo.fn_DisplayBoolean(I.CLEARDUE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Clear Due',
			dbo.fn_DisplayBoolean(I.CLEAREVENTONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Clear Event from Due',
			dbo.fn_DisplayBoolean(I.CLEARDUEONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Clear Due from Due',
			dbo.fn_DisplayBoolean(I.SATISFYEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Satisfy Event',
			dbo.fn_DisplayBoolean(I.UPDATEEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Update Event',
			A.ADJUSTMENTDESC	as 'Imported Adjustment',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			EC.EVENTDESCRIPTION	as 'Event',
			E.EVENTDESCRIPTION	as 'Related Event',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Cycle',
			dbo.fn_DisplayBoolean(C.CLEAREVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Clear Event',
			dbo.fn_DisplayBoolean(C.CLEARDUE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Clear Due',
			dbo.fn_DisplayBoolean(C.CLEAREVENTONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Clear Event from Due',
			dbo.fn_DisplayBoolean(C.CLEARDUEONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Clear Due from Due',
			dbo.fn_DisplayBoolean(C.SATISFYEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Satisfy Event',
			dbo.fn_DisplayBoolean(C.UPDATEEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Update Event',
			A.ADJUSTMENTDESC	as 'Adjustment'
		from "+@sUserName+".Imported_RELATEDEVENTS I
		join "+@sUserName+".CRITERIAALLOWED T    on (T.CRITERIANO=I.CRITERIANO)
		join CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.RELATEDEVENT)
		left join "+@sUserName+".Imported_ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString2="
		join RELATEDEVENTS C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.RELATEDNO=I.RELATEDNO)
		where	(I.RELATEDEVENT=C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is null))
		and	(I.CLEAREVENT=C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is null))
		and	(I.CLEARDUE=C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is null))
		and	(I.CLEAREVENTONDUECHANGE=C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is null))
		and	(I.CLEARDUEONDUECHANGE=C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is null))
		and	(I.SATISFYEVENT=C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is null))
		and	(I.UPDATEEVENT=C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is null))
		and	(I.ADJUSTMENT=C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
		and	(I.RELATIVECYCLE=C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			E.EVENTDESCRIPTION,
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			dbo.fn_DisplayBoolean(I.CLEAREVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEARDUE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEAREVENTONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEARDUEONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.SATISFYEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.UPDATEEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			A.ADJUSTMENTDESC,
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			E1.EVENTDESCRIPTION,
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			dbo.fn_DisplayBoolean(C.CLEAREVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.CLEARDUE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.CLEAREVENTONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.CLEARDUEONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.SATISFYEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.UPDATEEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			A1.ADJUSTMENTDESC
		from "+@sUserName+".Imported_RELATEDEVENTS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.RELATEDEVENT)
		left join "+@sUserName+".Imported_ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString4="
		join RELATEDEVENTS C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.RELATEDNO=I.RELATEDNO)
		join CRITERIA CR1	on (CR1.CRITERIANO=C.CRITERIANO)
		join EVENTCONTROL EC1	on (EC1.CRITERIANO=C.CRITERIANO
					and EC1.EVENTNO=C.EVENTNO)
		join EVENTS E1	on (E1.EVENTNO=C.RELATEDEVENT)
		left join ADJUSTMENT A1	on (A1.ADJUSTMENT=C.ADJUSTMENT)
		where 	I.RELATEDEVENT<>C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is not null) OR (I.RELATEDEVENT is not null and C.RELATEDEVENT is null)
		OR	I.CLEAREVENT<>C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is not null) OR (I.CLEAREVENT is not null and C.CLEAREVENT is null)
		OR	I.CLEARDUE<>C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is not null) OR (I.CLEARDUE is not null and C.CLEARDUE is null)
		OR	I.CLEAREVENTONDUECHANGE<>C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is not null) OR (I.CLEAREVENTONDUECHANGE is not null and C.CLEAREVENTONDUECHANGE is null)
		OR	I.CLEARDUEONDUECHANGE<>C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is not null) OR (I.CLEARDUEONDUECHANGE is not null and C.CLEARDUEONDUECHANGE is null)
		OR	I.SATISFYEVENT<>C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is not null) OR (I.SATISFYEVENT is not null and C.SATISFYEVENT is null)
		OR	I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)"
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
			dbo.fn_DisplayBoolean(I.CLEAREVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEARDUE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEAREVENTONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CLEARDUEONDUECHANGE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.SATISFYEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.UPDATEEVENT,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			A.ADJUSTMENTDESC,
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
		from "+@sUserName+".Imported_RELATEDEVENTS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.RELATEDEVENT)
		left join "+@sUserName+".Imported_ADJUSTMENT A	on (A.ADJUSTMENT=I.ADJUSTMENT)"
		Set @sSQLString6="
		left join RELATEDEVENTS C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO
					 and C.RELATEDNO=I.RELATEDNO)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5" ELSE "3,4,5" END
	
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
	-- Remove any RELATEDEVENTS rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete RELATEDEVENTS
		From RELATEDEVENTS RE
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=RE.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_RELATEDEVENTS I	on (I.CRITERIANO=RE.CRITERIANO
						and I.EVENTNO=RE.EVENTNO
						and I.RELATEDNO=RE.RELATEDNO)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any RELATEDEVENTS rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete RELATEDEVENTS
		From RELATEDEVENTS RE
		Join CRITERIA CR on (CR.CRITERIANO=RE.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_RELATEDEVENTS I	on (I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=RE.EVENTNO
						and I.RELATEDNO=RE.RELATEDNO)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and RE.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update RELATEDEVENTS
		set	RELATEDEVENT=I.RELATEDEVENT,
			CLEAREVENT=I.CLEAREVENT,
			CLEARDUE=I.CLEARDUE,
			CLEAREVENTONDUECHANGE=I.CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE=I.CLEARDUEONDUECHANGE,
			SATISFYEVENT=I.SATISFYEVENT,
			UPDATEEVENT=I.UPDATEEVENT,
			CREATENEXTCYCLE=I.CREATENEXTCYCLE,
			ADJUSTMENT=I.ADJUSTMENT,
			INHERITED=I.INHERITED,
			RELATIVECYCLE=I.RELATIVECYCLE
		from	RELATEDEVENTS C
		join	"+@sUserName+".Imported_RELATEDEVENTS I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.RELATEDNO=C.RELATEDNO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where 	I.RELATEDEVENT<>C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is not null) OR (I.RELATEDEVENT is not null and C.RELATEDEVENT is null)
		OR	I.CLEAREVENT<>C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is not null) OR (I.CLEAREVENT is not null and C.CLEAREVENT is null)
		OR	I.CLEARDUE<>C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is not null) OR (I.CLEARDUE is not null and C.CLEARDUE is null)
		OR	I.CLEAREVENTONDUECHANGE<>C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is not null) OR (I.CLEAREVENTONDUECHANGE is not null and C.CLEAREVENTONDUECHANGE is null)
		OR	I.CLEARDUEONDUECHANGE<>C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is not null) OR (I.CLEARDUEONDUECHANGE is not null and C.CLEARDUEONDUECHANGE is null)
		OR	I.SATISFYEVENT<>C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is not null) OR (I.SATISFYEVENT is not null and C.SATISFYEVENT is null)
		OR	I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update RELATEDEVENTS
		set	RELATEDEVENT=I.RELATEDEVENT,
			CLEAREVENT=I.CLEAREVENT,
			CLEARDUE=I.CLEARDUE,
			CLEAREVENTONDUECHANGE=I.CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE=I.CLEARDUEONDUECHANGE,
			SATISFYEVENT=I.SATISFYEVENT,
			UPDATEEVENT=I.UPDATEEVENT,
			CREATENEXTCYCLE=I.CREATENEXTCYCLE,
			ADJUSTMENT=I.ADJUSTMENT,
			RELATIVECYCLE=I.RELATIVECYCLE
		from	RELATEDEVENTS C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_RELATEDEVENTS I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO
						and I.RELATEDNO=C.RELATEDNO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1 
		AND    (I.RELATEDEVENT<>C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is not null) OR (I.RELATEDEVENT is not null and C.RELATEDEVENT is null)
		OR	I.CLEAREVENT<>C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is not null) OR (I.CLEAREVENT is not null and C.CLEAREVENT is null)
		OR	I.CLEARDUE<>C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is not null) OR (I.CLEARDUE is not null and C.CLEARDUE is null)
		OR	I.CLEAREVENTONDUECHANGE<>C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is not null) OR (I.CLEAREVENTONDUECHANGE is not null and C.CLEAREVENTONDUECHANGE is null)
		OR	I.CLEARDUEONDUECHANGE<>C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is not null) OR (I.CLEARDUEONDUECHANGE is not null and C.CLEARDUEONDUECHANGE is null)
		OR	I.SATISFYEVENT<>C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is not null) OR (I.SATISFYEVENT is not null and C.SATISFYEVENT is null)
		OR	I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR	I.ADJUSTMENT<>C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null)
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into RELATEDEVENTS(
			CRITERIANO,
			EVENTNO,
			RELATEDNO,
			RELATEDEVENT,
			CLEAREVENT,
			CLEARDUE,
			CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE,
			SATISFYEVENT,
			UPDATEEVENT,
			CREATENEXTCYCLE,
			ADJUSTMENT,
			INHERITED,
			RELATIVECYCLE)
		select	I.CRITERIANO,
			I.EVENTNO,
			I.RELATEDNO,
			I.RELATEDEVENT,
			I.CLEAREVENT,
			I.CLEARDUE,
			I.CLEAREVENTONDUECHANGE,
			I.CLEARDUEONDUECHANGE,
			I.SATISFYEVENT,
			I.UPDATEEVENT,
			I.CREATENEXTCYCLE,
			I.ADJUSTMENT,
			I.INHERITED,
			I.RELATIVECYCLE
		from "+@sUserName+".Imported_RELATEDEVENTS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join RELATEDEVENTS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.RELATEDNO=I.RELATEDNO)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin

		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into RELATEDEVENTS(
			CRITERIANO,
			EVENTNO,
			RELATEDNO,
			RELATEDEVENT,
			CLEAREVENT,
			CLEARDUE,
			CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE,
			SATISFYEVENT,
			UPDATEEVENT,
			CREATENEXTCYCLE,
			ADJUSTMENT,
			INHERITED,
			RELATIVECYCLE)
		select	IH.CRITERIANO,
			I.EVENTNO,
			I.RELATEDNO,
			I.RELATEDEVENT,
			I.CLEAREVENT,
			I.CLEARDUE,
			I.CLEAREVENTONDUECHANGE,
			I.CLEARDUEONDUECHANGE,
			I.SATISFYEVENT,
			I.UPDATEEVENT,
			I.CREATENEXTCYCLE,
			I.ADJUSTMENT,
			1,
			I.RELATIVECYCLE
		from "+@sUserName+".Imported_RELATEDEVENTS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join RELATEDEVENTS C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.RELATEDNO=I.RELATEDNO)
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
grant execute on dbo.ip_RulesRELATEDEVENTS  to public
go

