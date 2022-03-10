-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesDATESLOGIC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesDATESLOGIC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesDATESLOGIC.'
	drop procedure dbo.ip_RulesDATESLOGIC
	print '**** Creating procedure dbo.ip_RulesDATESLOGIC...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesDATESLOGIC
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesDATESLOGIC
-- VERSION :	5
-- DESCRIPTION:	The comparison/display and merging of imported data for the DATESLOGIC table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove DATESLOGIC rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 12 Jul 2013	MF	R13596	4	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	5	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
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


-- Prerequisite that the IMPORTED_DATESLOGIC table has been loaded

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
		"UPDATE "+@sUserName+".Imported_DATESLOGIC
		SET EVENTNO = M.MAPVALUE
		FROM "+@sUserName+".Imported_DATESLOGIC C
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
			"UPDATE "+@sUserName+".Imported_DATESLOGIC
			SET COMPAREEVENT = M.MAPVALUE
			FROM "+@sUserName+".Imported_DATESLOGIC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.COMPAREEVENT)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DATESLOGIC
			SET CASERELATIONSHIP = M.MAPVALUE
			FROM "+@sUserName+".Imported_DATESLOGIC C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='CASERELATION'
					and M.MAPCOLUMN  ='RELATIONSHIP'
					and M.SOURCEVALUE=C.CASERELATIONSHIP)
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
			CASE (I.DATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
			END			as 'Imported Date Type',
			I.OPERATOR		as 'Imported Operator',
			E.EVENTDESCRIPTION	as 'Imported Compare Event',
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Must Exist',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Imported Cycle',
			CASE (I.COMPAREDATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END		as 'Imported Compare Date Type',
			R.RELATIONSHIPDESC	as 'Imported Relationship',
			CASE(I.DISPLAYERRORFLAG) WHEN(1) THEN 'Error' ELSE 'Warning' END
						as 'Imported Error/Warning',
			I.ERRORMESSAGE		as 'Imported Error Message',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			EC.EVENTDESCRIPTION	as 'Event',
			CASE (I.DATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
			END			as 'Date Type',
			C.OPERATOR		as 'Operator',
			E.EVENTDESCRIPTION	as 'Compare Event',
			dbo.fn_DisplayBoolean(C.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Must Exist',
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END			as 'Cycle',
			CASE (I.COMPAREDATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END			as 'Compare Date Type',
			R.RELATIONSHIPDESC	as 'Relationship',
			CASE(C.DISPLAYERRORFLAG) WHEN(1) THEN 'Error' ELSE 'Warning' END
						as 'Error/Warning',
			C.ERRORMESSAGE		as 'Error Message'
		from "+@sUserName+".Imported_DATESLOGIC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.COMPAREEVENT)
		left join "+@sUserName+".Imported_CASERELATION R on (R.RELATIONSHIP=I.CASERELATIONSHIP)"
		Set @sSQLString2="	join DATESLOGIC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.SEQUENCENO=I.SEQUENCENO)
		where	(I.DATETYPE=C.DATETYPE)
		and	(I.OPERATOR=C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is null))
		and	(I.COMPAREEVENT=C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is null))
		and	(I.MUSTEXIST=C.MUSTEXIST)
		and	(I.RELATIVECYCLE=C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
		and	(I.COMPAREDATETYPE=C.COMPAREDATETYPE)
		and	(I.CASERELATIONSHIP=C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			CASE (I.DATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
			END,
			I.OPERATOR,
			E.EVENTDESCRIPTION,
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (I.COMPAREDATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			R.RELATIONSHIPDESC,
			CASE(I.DISPLAYERRORFLAG) WHEN(1) THEN 'Error' ELSE 'Warning' END,
			I.ERRORMESSAGE,
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			CASE (C.DATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
			END,
			C.OPERATOR,
			E1.EVENTDESCRIPTION,
			dbo.fn_DisplayBoolean(C.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(C.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (C.COMPAREDATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			R1.RELATIONSHIPDESC,
			CASE(C.DISPLAYERRORFLAG) WHEN(1) THEN 'Error' ELSE 'Warning' END,
			C.ERRORMESSAGE
		from "+@sUserName+".Imported_DATESLOGIC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.COMPAREEVENT)
		left join "+@sUserName+".Imported_CASERELATION R on (R.RELATIONSHIP=I.CASERELATIONSHIP)"
		Set @sSQLString4="	join DATESLOGIC C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.SEQUENCENO=I.SEQUENCENO)
		join CRITERIA CR1	on (CR1.CRITERIANO=C.CRITERIANO)
		join EVENTCONTROL EC1	on (EC1.CRITERIANO=C.CRITERIANO
					and EC1.EVENTNO=C.EVENTNO)
		join EVENTS E1	on (E.EVENTNO=C.COMPAREEVENT)
		left join CASERELATION R1 on (R1.RELATIONSHIP=C.CASERELATIONSHIP)
		where 	I.DATETYPE<>C.DATETYPE
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.COMPAREDATETYPE<>C.COMPAREDATETYPE
		OR	I.CASERELATIONSHIP<>C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			CASE (I.DATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
			END,
			I.OPERATOR,
			E.EVENTDESCRIPTION,
			dbo.fn_DisplayBoolean(I.MUSTEXIST,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(I.RELATIVECYCLE)
				WHEN(0) THEN 'Same'
				WHEN(1) THEN 'Previous'
				WHEN(2) THEN 'Next'
				WHEN(3) THEN 'First'
				WHEN(4) THEN 'Latest'
			END,
			CASE (I.COMPAREDATETYPE)
				WHEN(1) THEN 'Event'
				WHEN(2) THEN 'Due'
				WHEN(3) THEN 'Event/Due'
			END,
			R.RELATIONSHIPDESC,
			CASE(I.DISPLAYERRORFLAG) WHEN(1) THEN 'Error' ELSE 'Warning' END,
			I.ERRORMESSAGE,
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
		from "+@sUserName+".Imported_DATESLOGIC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		join "+@sUserName+".Imported_EVENTS E	on (E.EVENTNO=I.COMPAREEVENT)
		left join "+@sUserName+".Imported_CASERELATION R on (R.RELATIONSHIP=I.CASERELATIONSHIP)"
		Set @sSQLString6="	left join DATESLOGIC C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO
					 and C.SEQUENCENO=I.SEQUENCENO)
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
	-- Remove any DATESLOGIC rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DATESLOGIC
		From DATESLOGIC DL
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=DL.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DATESLOGIC I	on (I.CRITERIANO=DL.CRITERIANO
						and I.EVENTNO=DL.EVENTNO
						and I.SEQUENCENO=DL.SEQUENCENO)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any DATESLOGIC rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DATESLOGIC
		From DATESLOGIC DL
		Join CRITERIA CR on (CR.CRITERIANO=DL.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DATESLOGIC I	on (I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=DL.EVENTNO
						and I.SEQUENCENO=DL.SEQUENCENO)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and DL.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DATESLOGIC
		set	DATETYPE=I.DATETYPE,
			OPERATOR=I.OPERATOR,
			COMPAREEVENT=I.COMPAREEVENT,
			RELATIVECYCLE=I.RELATIVECYCLE,
			COMPAREDATETYPE=I.COMPAREDATETYPE,
			CASERELATIONSHIP=I.CASERELATIONSHIP,
			INHERITED=I.INHERITED,
			MUSTEXIST=I.MUSTEXIST
		from	DATESLOGIC C
		join	"+@sUserName+".Imported_DATESLOGIC I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.SEQUENCENO=C.SEQUENCENO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where 	I.DATETYPE<>C.DATETYPE
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.COMPAREDATETYPE<>C.COMPAREDATETYPE
		OR	I.CASERELATIONSHIP<>C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DATESLOGIC
		set	DATETYPE=I.DATETYPE,
			OPERATOR=I.OPERATOR,
			COMPAREEVENT=I.COMPAREEVENT,
			RELATIVECYCLE=I.RELATIVECYCLE,
			COMPAREDATETYPE=I.COMPAREDATETYPE,
			CASERELATIONSHIP=I.CASERELATIONSHIP,
			MUSTEXIST=I.MUSTEXIST
		from	DATESLOGIC C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_DATESLOGIC I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO
						and I.SEQUENCENO=C.SEQUENCENO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1  
		AND    (I.DATETYPE<>C.DATETYPE
		OR	I.OPERATOR<>C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) OR (I.OPERATOR is not null and C.OPERATOR is null)
		OR	I.COMPAREEVENT<>C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null)
		OR	I.MUSTEXIST<>C.MUSTEXIST
		OR	I.RELATIVECYCLE<>C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null)
		OR	I.COMPAREDATETYPE<>C.COMPAREDATETYPE
		OR	I.CASERELATIONSHIP<>C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into DATESLOGIC(
			CRITERIANO,
			EVENTNO,
			SEQUENCENO,
			DATETYPE,
			OPERATOR,
			COMPAREEVENT,
			RELATIVECYCLE,
			COMPAREDATETYPE,
			CASERELATIONSHIP,
			ERRORMESSAGE,
			INHERITED,
			MUSTEXIST,
			DISPLAYERRORFLAG)
		select	I.CRITERIANO,
			I.EVENTNO,
			I.SEQUENCENO,
			I.DATETYPE,
			I.OPERATOR,
			I.COMPAREEVENT,
			I.RELATIVECYCLE,
			I.COMPAREDATETYPE,
			I.CASERELATIONSHIP,
			I.ERRORMESSAGE,
			I.INHERITED,
			I.MUSTEXIST,
			I.DISPLAYERRORFLAG
		from "+@sUserName+".Imported_DATESLOGIC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join DATESLOGIC C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCENO=I.SEQUENCENO)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin

		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into DATESLOGIC(
			CRITERIANO,
			EVENTNO,
			SEQUENCENO,
			DATETYPE,
			OPERATOR,
			COMPAREEVENT,
			RELATIVECYCLE,
			COMPAREDATETYPE,
			CASERELATIONSHIP,
			ERRORMESSAGE,
			INHERITED,
			MUSTEXIST,
			DISPLAYERRORFLAG)
		select	IH.CRITERIANO,
			I.EVENTNO,
			I.SEQUENCENO,
			I.DATETYPE,
			I.OPERATOR,
			I.COMPAREEVENT,
			I.RELATIVECYCLE,
			I.COMPAREDATETYPE,
			I.CASERELATIONSHIP,
			I.ERRORMESSAGE,
			1,
			I.MUSTEXIST,
			I.DISPLAYERRORFLAG
		from "+@sUserName+".Imported_DATESLOGIC I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join DATESLOGIC C	on (C.CRITERIANO=CR.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.SEQUENCENO=I.SEQUENCENO)
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
grant execute on dbo.ip_RulesDATESLOGIC  to public
go

