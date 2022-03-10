-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesDETAILDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesDETAILDATES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesDETAILDATES.'
	drop procedure dbo.ip_RulesDETAILDATES
	print '**** Creating procedure dbo.ip_RulesDETAILDATES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesDETAILDATES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesDETAILDATES
-- VERSION :	6
-- DESCRIPTION:	The comparison/display and merging of imported data for the DETAILDATES table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove DETAILDATES rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 21 Jan 2011	MF	19321	4	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 12 Jul 2013	MF	R13596	5	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	6	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 	(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the IMPORTED_DETAILDATES table has been loaded

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
		"UPDATE "+@sUserName+".Imported_DETAILDATES
		SET EVENTNO = M.MAPVALUE
		FROM "+@sUserName+".Imported_DETAILDATES C
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
			"UPDATE "+@sUserName+".Imported_DETAILDATES
			SET OTHEREVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_DETAILDATES C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.OTHEREVENTNO)
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
			DC.ENTRYDESC		as 'Imported Entry',
			E.EVENTDESCRIPTION	as 'Imported Event',
			O.EVENTDESCRIPTION	as 'Imported Other Event',
			CASE (I.EVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Event Attribute',
			CASE (I.DUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Due Attribute',
			CASE (I.POLICINGATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Stop Police Attribute',
			CASE (I.PERIODATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Period Attribute',
			CASE (I.OVREVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Override Event Attribute',
			CASE (I.OVRDUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Override Due Attribute',
			CASE (I.JOURNALATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Imported Journal Attribute',
			I.DISPLAYSEQUENCE	as 'Imported Display Sequence',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			DC.ENTRYDESC		as 'Entry',
			E.EVENTDESCRIPTION	as 'Event',
			O.EVENTDESCRIPTION	as 'Other Event',
			CASE (C.EVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Event Attribute',
			CASE (C.DUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Due Attribute',
			CASE (C.POLICINGATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Stop Police Attribute',
			CASE (C.PERIODATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Period Attribute',
			CASE (C.OVREVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END	as 'Override Event Attribute',
			CASE (I.OVRDUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END			as 'Override Due Attribute',
			CASE (C.JOURNALATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END	as 'Journal Attribute',
			C.DISPLAYSEQUENCE	as 'Display Sequence'"
		Set @sSQLString2="
		from "+@sUserName+".Imported_DETAILDATES I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		join DETAILCONTROL DC 	on (DC.CRITERIANO=I.CRITERIANO
					and DC.ENTRYNUMBER=I.ENTRYNUMBER)
		     join EVENTS E on (E.EVENTNO=I.EVENTNO)
		left join EVENTS O on (O.EVENTNO=I.OTHEREVENTNO)
		join DETAILDATES C	on( C.CRITERIANO=I.CRITERIANO
					and C.ENTRYNUMBER=I.ENTRYNUMBER
					and C.EVENTNO=I.EVENTNO)
		where	(I.OTHEREVENTNO=C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is null))
		and	(I.EVENTATTRIBUTE=C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is null))
		and	(I.DUEATTRIBUTE=C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is null))
		and	(I.POLICINGATTRIBUTE=C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is null))
		and	(I.PERIODATTRIBUTE=C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is null))
		and	(I.OVREVENTATTRIBUTE=C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is null))
		and	(I.OVRDUEATTRIBUTE=C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is null))
		and	(I.JOURNALATTRIBUTE=C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			DC1.ENTRYDESC,
			E1.EVENTDESCRIPTION,
			O1.EVENTDESCRIPTION,
			CASE (I.EVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.DUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.POLICINGATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.PERIODATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.OVREVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.OVRDUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.JOURNALATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			I.DISPLAYSEQUENCE,
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			DC1.ENTRYDESC,
			E1.EVENTDESCRIPTION,
			O1.EVENTDESCRIPTION,
			CASE (C.EVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (C.DUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (C.POLICINGATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (C.PERIODATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (C.OVREVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (C.OVRDUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.JOURNALATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			C.DISPLAYSEQUENCE
		from "+@sUserName+".Imported_DETAILDATES I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_DETAILCONTROL DC 	on (DC.CRITERIANO=I.CRITERIANO
								and DC.ENTRYNUMBER=I.ENTRYNUMBER)
		join "+@sUserName+".Imported_EVENTS E on (E.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS O on (O.EVENTNO=I.OTHEREVENTNO)"
		Set @sSQLString4="	join DETAILDATES C	on( C.CRITERIANO=I.CRITERIANO
					and C.ENTRYNUMBER=I.ENTRYNUMBER
					and C.EVENTNO=I.EVENTNO)
		join CRITERIA CR1 on (CR1.CRITERIANO=C.CRITERIANO)
		join DETAILCONTROL DC1 	on (DC1.CRITERIANO=C.CRITERIANO
					and DC.ENTRYNUMBER=C.ENTRYNUMBER)
		join EVENTS E1 on (E1.EVENTNO=C.EVENTNO)
		left join EVENTS O1 on (O1.EVENTNO=C.OTHEREVENTNO)
		where 	I.OTHEREVENTNO<>C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is not null) OR (I.OTHEREVENTNO is not null and C.OTHEREVENTNO is null)
		OR	I.EVENTATTRIBUTE<>C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is not null) OR (I.EVENTATTRIBUTE is not null and C.EVENTATTRIBUTE is null)
		OR	I.DUEATTRIBUTE<>C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is not null) OR (I.DUEATTRIBUTE is not null and C.DUEATTRIBUTE is null)
		OR	I.POLICINGATTRIBUTE<>C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is not null) OR (I.POLICINGATTRIBUTE is not null and C.POLICINGATTRIBUTE is null)
		OR	I.PERIODATTRIBUTE<>C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is not null) OR (I.PERIODATTRIBUTE is not null and C.PERIODATTRIBUTE is null)
		OR	I.OVREVENTATTRIBUTE<>C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is not null) OR (I.OVREVENTATTRIBUTE is not null and C.OVREVENTATTRIBUTE is null)
		OR	I.OVRDUEATTRIBUTE<>C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is not null) OR (I.OVRDUEATTRIBUTE is not null and C.OVRDUEATTRIBUTE is null)
		OR	I.JOURNALATTRIBUTE<>C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is not null) OR (I.JOURNALATTRIBUTE is not null and C.JOURNALATTRIBUTE is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			DC.ENTRYDESC,
			E.EVENTDESCRIPTION,
			O.EVENTDESCRIPTION,
			CASE (I.EVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.DUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.POLICINGATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.PERIODATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.OVREVENTATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.OVRDUEATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			CASE (I.JOURNALATTRIBUTE)
				WHEN(0) THEN 'Display only'
				WHEN(1)	THEN 'Must enter'
				WHEN(2)	THEN 'Hide'
				WHEN(3)	THEN 'Optional entry'
				WHEN(4)	THEN 'Default to system date'
			END,
			I.DISPLAYSEQUENCE,
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
		from "+@sUserName+".Imported_DETAILDATES I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_DETAILCONTROL DC 	on (DC.CRITERIANO=I.CRITERIANO
								and DC.ENTRYNUMBER=I.ENTRYNUMBER)
		join "+@sUserName+".Imported_EVENTS E on (E.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS O on (O.EVENTNO=I.OTHEREVENTNO)"
		Set @sSQLString6="	left join DETAILDATES C on( C.CRITERIANO=I.CRITERIANO
					 and C.ENTRYNUMBER=I.ENTRYNUMBER
					 and C.EVENTNO=I.EVENTNO)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,8,5" ELSE "3,4,8,5" END
	
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
	-- Remove any DETAILDATES rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DETAILDATES
		From DETAILDATES DD
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=DD.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DETAILDATES I	on (I.CRITERIANO=DD.CRITERIANO
						and I.ENTRYNUMBER=DD.ENTRYNUMBER
						and I.EVENTNO=DD.EVENTNO)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any DETAILDATES rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DETAILDATES
		From DETAILDATES DD
		Join CRITERIA CR on (CR.CRITERIANO=DD.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=CR.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		Left Join "+@sUserName+".Imported_DETAILDATES I	on (I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=DD.ENTRYNUMBER
						and I.EVENTNO=DD.EVENTNO)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and DD.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DETAILDATES
		set	OTHEREVENTNO=I.OTHEREVENTNO,
			DEFAULTFLAG=I.DEFAULTFLAG,
			EVENTATTRIBUTE=I.EVENTATTRIBUTE,
			DUEATTRIBUTE=I.DUEATTRIBUTE,
			POLICINGATTRIBUTE=I.POLICINGATTRIBUTE,
			PERIODATTRIBUTE=I.PERIODATTRIBUTE,
			OVREVENTATTRIBUTE=I.OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE=I.OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE=I.JOURNALATTRIBUTE,
			DISPLAYSEQUENCE=I.DISPLAYSEQUENCE,
			INHERITED=I.INHERITED
		from	DETAILDATES C
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		join	"+@sUserName+".Imported_DETAILDATES I	on ( I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=C.ENTRYNUMBER
						and I.EVENTNO=C.EVENTNO)
		where 	I.OTHEREVENTNO<>C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is not null) OR (I.OTHEREVENTNO is not null and C.OTHEREVENTNO is null)
		OR	I.EVENTATTRIBUTE<>C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is not null) OR (I.EVENTATTRIBUTE is not null and C.EVENTATTRIBUTE is null)
		OR	I.DUEATTRIBUTE<>C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is not null) OR (I.DUEATTRIBUTE is not null and C.DUEATTRIBUTE is null)
		OR	I.POLICINGATTRIBUTE<>C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is not null) OR (I.POLICINGATTRIBUTE is not null and C.POLICINGATTRIBUTE is null)
		OR	I.PERIODATTRIBUTE<>C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is not null) OR (I.PERIODATTRIBUTE is not null and C.PERIODATTRIBUTE is null)
		OR	I.OVREVENTATTRIBUTE<>C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is not null) OR (I.OVREVENTATTRIBUTE is not null and C.OVREVENTATTRIBUTE is null)
		OR	I.OVRDUEATTRIBUTE<>C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is not null) OR (I.OVRDUEATTRIBUTE is not null and C.OVRDUEATTRIBUTE is null)
		OR	I.JOURNALATTRIBUTE<>C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is not null) OR (I.JOURNALATTRIBUTE is not null and C.JOURNALATTRIBUTE is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DETAILDATES
		set	OTHEREVENTNO=I.OTHEREVENTNO,
			DEFAULTFLAG=I.DEFAULTFLAG,
			EVENTATTRIBUTE=I.EVENTATTRIBUTE,
			DUEATTRIBUTE=I.DUEATTRIBUTE,
			POLICINGATTRIBUTE=I.POLICINGATTRIBUTE,
			PERIODATTRIBUTE=I.PERIODATTRIBUTE,
			OVREVENTATTRIBUTE=I.OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE=I.OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE=I.JOURNALATTRIBUTE,
			DISPLAYSEQUENCE=I.DISPLAYSEQUENCE,
			INHERITED=I.INHERITED
		from	DETAILDATES C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_DETAILDATES I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.ENTRYNUMBER=C.ENTRYNUMBER
						and I.EVENTNO=C.EVENTNO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1 
		AND    (I.OTHEREVENTNO<>C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is not null) OR (I.OTHEREVENTNO is not null and C.OTHEREVENTNO is null)
		OR	I.EVENTATTRIBUTE<>C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is not null) OR (I.EVENTATTRIBUTE is not null and C.EVENTATTRIBUTE is null)
		OR	I.DUEATTRIBUTE<>C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is not null) OR (I.DUEATTRIBUTE is not null and C.DUEATTRIBUTE is null)
		OR	I.POLICINGATTRIBUTE<>C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is not null) OR (I.POLICINGATTRIBUTE is not null and C.POLICINGATTRIBUTE is null)
		OR	I.PERIODATTRIBUTE<>C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is not null) OR (I.PERIODATTRIBUTE is not null and C.PERIODATTRIBUTE is null)
		OR	I.OVREVENTATTRIBUTE<>C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is not null) OR (I.OVREVENTATTRIBUTE is not null and C.OVREVENTATTRIBUTE is null)
		OR	I.OVRDUEATTRIBUTE<>C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is not null) OR (I.OVRDUEATTRIBUTE is not null and C.OVRDUEATTRIBUTE is null)
		OR	I.JOURNALATTRIBUTE<>C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is not null) OR (I.JOURNALATTRIBUTE is not null and C.JOURNALATTRIBUTE is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into DETAILDATES(
			CRITERIANO,
			ENTRYNUMBER,
			EVENTNO,
			OTHEREVENTNO,
			DEFAULTFLAG,
			EVENTATTRIBUTE,
			DUEATTRIBUTE,
			POLICINGATTRIBUTE,
			PERIODATTRIBUTE,
			OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE,
			DISPLAYSEQUENCE,
			INHERITED)
		select	I.CRITERIANO,
			I.ENTRYNUMBER,
			I.EVENTNO,
			I.OTHEREVENTNO,
			I.DEFAULTFLAG,
			I.EVENTATTRIBUTE,
			I.DUEATTRIBUTE,
			I.POLICINGATTRIBUTE,
			I.PERIODATTRIBUTE,
			I.OVREVENTATTRIBUTE,
			I.OVRDUEATTRIBUTE,
			I.JOURNALATTRIBUTE,
			I.DISPLAYSEQUENCE,
			I.INHERITED
		from "+@sUserName+".Imported_DETAILDATES I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join DETAILDATES C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER
						and C.EVENTNO=I.EVENTNO)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin
		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into DETAILDATES(
			CRITERIANO,
			ENTRYNUMBER,
			EVENTNO,
			OTHEREVENTNO,
			DEFAULTFLAG,
			EVENTATTRIBUTE,
			DUEATTRIBUTE,
			POLICINGATTRIBUTE,
			PERIODATTRIBUTE,
			OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE,
			DISPLAYSEQUENCE,
			INHERITED)
		select	IH.CRITERIANO,
			I.ENTRYNUMBER,
			I.EVENTNO,
			I.OTHEREVENTNO,
			I.DEFAULTFLAG,
			I.EVENTATTRIBUTE,
			I.DUEATTRIBUTE,
			I.POLICINGATTRIBUTE,
			I.PERIODATTRIBUTE,
			I.OVREVENTATTRIBUTE,
			I.OVRDUEATTRIBUTE,
			I.JOURNALATTRIBUTE,
			I.DISPLAYSEQUENCE,
			1
		from "+@sUserName+".Imported_DETAILDATES I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join DETAILDATES C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER
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
grant execute on dbo.ip_RulesDETAILDATES  to public
go

