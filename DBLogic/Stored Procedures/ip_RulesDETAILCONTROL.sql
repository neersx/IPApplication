-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesDETAILCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesDETAILCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesDETAILCONTROL.'
	drop procedure dbo.ip_RulesDETAILCONTROL
	print '**** Creating procedure dbo.ip_RulesDETAILCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesDETAILCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesDETAILCONTROL
-- VERSION :	8
-- DESCRIPTION:	The comparison/display and merging of imported data for the DETAILCONTROL table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove DETAILCONTROL rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 15 Jan 2010	MF	18150	4	Status changes within the Law Update Sevice will not be updated on existing rules.
-- 11 Mar 2011	MF	19321	5	Revisit to include additional columns that do not need to be shown as a difference.
-- 12 Jul 2013	MF	R13596	6	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	7	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 01 May 2017	MF	71205	8	New column added ISSEPARATOR.
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


-- Prerequisite that the IMPORTED_DETAILCONTROL table has been loaded

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
		"UPDATE "+@sUserName+".Imported_DETAILCONTROL
		SET STATUSCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_DETAILCONTROL C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='STATUS'
				and M.MAPCOLUMN  ='STATUSCODE'
				and M.SOURCEVALUE=C.STATUSCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DETAILCONTROL
			SET RENEWALSTATUS = M.MAPVALUE
			FROM "+@sUserName+".Imported_DETAILCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='STATUS'
					and M.MAPCOLUMN  ='STATUSCODE'
					and M.SOURCEVALUE=C.RENEWALSTATUS)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DETAILCONTROL
			SET FILELOCATION = M.MAPVALUE
			FROM "+@sUserName+".Imported_DETAILCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.FILELOCATION)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_DETAILCONTROL
			SET NUMBERTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_DETAILCONTROL C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='NUMBERTYPES'
					and M.MAPCOLUMN  ='NUMBERTYPE'
					and M.SOURCEVALUE=C.NUMBERTYPE)
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
			I.ENTRYDESC		as 'Imported Entry',
			N.DESCRIPTION		as 'Imported Number Type',
			dbo.fn_DisplayBoolean(I.ATLEAST1FLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported At Least 1',
			dbo.fn_DisplayBoolean(I.ISSEPARATOR," +CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Is Separator',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			C.ENTRYDESC		as 'Entry',
			N.DESCRIPTION		as 'Number Type',
			dbo.fn_DisplayBoolean(C.ATLEAST1FLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'At Least 1',
			dbo.fn_DisplayBoolean(C.ISSEPARATOR," +CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Is Separator'
		from "+@sUserName+".Imported_DETAILCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_NUMBERTYPES N on (N.NUMBERTYPE=I.NUMBERTYPE)"
		Set @sSQLString2="	join DETAILCONTROL C	on( C.CRITERIANO=I.CRITERIANO
					and C.ENTRYNUMBER=I.ENTRYNUMBER)
		where	(I.ENTRYDESC=C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is null))
		and	(I.NUMBERTYPE=C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is null))
		and	(I.ATLEAST1FLAG=C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is null))
		and	(I.ISSEPARATOR=C.ISSEPARATOR OR (I.ISSEPARATOR is null and C.ISSEPARATOR is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			I.ENTRYDESC,
			N.DESCRIPTION,
			dbo.fn_DisplayBoolean(I.ATLEAST1FLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.ISSEPARATOR," +CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			C.ENTRYDESC,
			N1.DESCRIPTION,
			dbo.fn_DisplayBoolean(C.ATLEAST1FLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.ISSEPARATOR," +CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
		from "+@sUserName+".Imported_DETAILCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_NUMBERTYPES N on (N.NUMBERTYPE=I.NUMBERTYPE)"
		Set @sSQLString4="	join DETAILCONTROL C	on( C.CRITERIANO=I.CRITERIANO
					and C.ENTRYNUMBER=I.ENTRYNUMBER)
		join CRITERIA CR1 on (CR1.CRITERIANO=C.CRITERIANO)
		left join NUMBERTYPES N1 on (N1.NUMBERTYPE=C.NUMBERTYPE)
		where 	I.ENTRYDESC<>C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is not null) OR (I.ENTRYDESC is not null and C.ENTRYDESC is null)
		OR	I.NUMBERTYPE<>C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null)
		OR	I.ATLEAST1FLAG<>C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is not null) OR (I.ATLEAST1FLAG is not null and C.ATLEAST1FLAG is null)
		OR	I.ISSEPARATOR <>C.ISSEPARATOR  OR (I.ISSEPARATOR  is null and C.ISSEPARATOR  is not null) OR (I.ISSEPARATOR  is not null and C.ISSEPARATOR  is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			I.ENTRYDESC,
			N.DESCRIPTION,
			dbo.fn_DisplayBoolean(I.ATLEAST1FLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.ISSEPARATOR," +CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_DETAILCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR on (CR.CRITERIANO=I.CRITERIANO)
		left join "+@sUserName+".Imported_NUMBERTYPES N on (N.NUMBERTYPE=I.NUMBERTYPE)"
		Set @sSQLString6="	left join DETAILCONTROL C on( C.CRITERIANO=I.CRITERIANO
					 and C.ENTRYNUMBER=I.ENTRYNUMBER)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,5,4" ELSE "3,5,4" END
	
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
	-- Remove any DETAILCONTROL rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DETAILCONTROL
		From DETAILCONTROL DC
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=DC.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_DETAILCONTROL I	on (I.CRITERIANO=DC.CRITERIANO
						and I.ENTRYNUMBER=DC.ENTRYNUMBER)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any DETAILCONTROL rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete DETAILCONTROL
		From DETAILCONTROL DC
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=DC.CRITERIANO)
		Join CRITERIA CR     on (CR.CRITERIANO=DC.CRITERIANO)
		Join INHERITS IH     on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		Left Join "+@sUserName+".Imported_DETAILCONTROL I	on (I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=DC.ENTRYNUMBER)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and DC.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DETAILCONTROL
		set	ENTRYDESC=I.ENTRYDESC,
			TAKEOVERFLAG=I.TAKEOVERFLAG,
			DISPLAYSEQUENCE=I.DISPLAYSEQUENCE,
			FILELOCATION=I.FILELOCATION,
			NUMBERTYPE=I.NUMBERTYPE,
			ATLEAST1FLAG=I.ATLEAST1FLAG,
			USERINSTRUCTION=I.USERINSTRUCTION,
			INHERITED=I.INHERITED,
			ENTRYCODE=I.ENTRYCODE,
			CHARGEGENERATION=I.CHARGEGENERATION,
			DISPLAYEVENTNO=I.DISPLAYEVENTNO,
			HIDEEVENTNO=I.HIDEEVENTNO,
			DIMEVENTNO=I.DIMEVENTNO,
			SHOWTABS=I.SHOWTABS,
			SHOWMENUS=I.SHOWMENUS,
			SHOWTOOLBAR=I.SHOWTOOLBAR,
			ISSEPARATOR=isnull(I.ISSEPARATOR,0)
		from	DETAILCONTROL C
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		join	"+@sUserName+".Imported_DETAILCONTROL I	on ( I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=C.ENTRYNUMBER)
		where 	I.ENTRYDESC<>C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is not null) OR (I.ENTRYDESC is not null and C.ENTRYDESC is null)
		OR	I.DISPLAYSEQUENCE<>C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null)
		OR	I.NUMBERTYPE<>C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null)
		OR	I.ATLEAST1FLAG<>C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is not null) OR (I.ATLEAST1FLAG is not null and C.ATLEAST1FLAG is null)
		OR	I.ISSEPARATOR <>C.ISSEPARATOR  OR (I.ISSEPARATOR  is null and C.ISSEPARATOR  is not null) OR (I.ISSEPARATOR  is not null and C.ISSEPARATOR  is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DETAILCONTROL
		set	ENTRYDESC=I.ENTRYDESC,
			TAKEOVERFLAG=I.TAKEOVERFLAG,
			DISPLAYSEQUENCE=I.DISPLAYSEQUENCE,
			FILELOCATION=I.FILELOCATION,
			NUMBERTYPE=I.NUMBERTYPE,
			ATLEAST1FLAG=I.ATLEAST1FLAG,
			USERINSTRUCTION=I.USERINSTRUCTION,
			ENTRYCODE=I.ENTRYCODE,
			CHARGEGENERATION=I.CHARGEGENERATION,
			DISPLAYEVENTNO=I.DISPLAYEVENTNO,
			HIDEEVENTNO=I.HIDEEVENTNO,
			DIMEVENTNO=I.DIMEVENTNO,
			SHOWTABS=I.SHOWTABS,
			SHOWMENUS=I.SHOWMENUS,
			SHOWTOOLBAR=I.SHOWTOOLBAR,
			ISSEPARATOR=isnull(I.ISSEPARATOR,0)
		from	DETAILCONTROL C
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_DETAILCONTROL I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.ENTRYNUMBER=C.ENTRYNUMBER)
		where	CR.USERDEFINEDRULE=1
		AND	C.INHERITED=1 
		AND    (I.ENTRYDESC<>C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is not null) OR (I.ENTRYDESC is not null and C.ENTRYDESC is null)
		OR	I.DISPLAYSEQUENCE<>C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null)
		OR	I.NUMBERTYPE<>C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null)
		OR	I.ATLEAST1FLAG<>C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is not null) OR (I.ATLEAST1FLAG is not null and C.ATLEAST1FLAG is null)
		OR	I.ISSEPARATOR <>C.ISSEPARATOR  OR (I.ISSEPARATOR  is null and C.ISSEPARATOR  is not null) OR (I.ISSEPARATOR  is not null and C.ISSEPARATOR  is null))"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into DETAILCONTROL(
			CRITERIANO,
			ENTRYNUMBER,
			ENTRYDESC,
			TAKEOVERFLAG,
			DISPLAYSEQUENCE,
			STATUSCODE,
			RENEWALSTATUS,
			FILELOCATION,
			NUMBERTYPE,
			ATLEAST1FLAG,
			USERINSTRUCTION,
			INHERITED,
			ENTRYCODE,
			CHARGEGENERATION,
			DISPLAYEVENTNO,
			HIDEEVENTNO,
			DIMEVENTNO,
			SHOWTABS,
			SHOWMENUS,
			SHOWTOOLBAR,
			ISSEPARATOR)
		select	I.CRITERIANO,
			I.ENTRYNUMBER,
			I.ENTRYDESC,
			I.TAKEOVERFLAG,
			I.DISPLAYSEQUENCE,
			I.STATUSCODE,
			I.RENEWALSTATUS,
			I.FILELOCATION,
			I.NUMBERTYPE,
			I.ATLEAST1FLAG,
			I.USERINSTRUCTION,
			I.INHERITED,
			I.ENTRYCODE,
			I.CHARGEGENERATION,
			I.DISPLAYEVENTNO,
			I.HIDEEVENTNO,
			I.DIMEVENTNO,
			I.SHOWTABS,
			I.SHOWMENUS,
			I.SHOWTOOLBAR,
			isnull(I.ISSEPARATOR,0)
		from "+@sUserName+".Imported_DETAILCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join DETAILCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin
		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into DETAILCONTROL(
			CRITERIANO,
			ENTRYNUMBER,
			ENTRYDESC,
			TAKEOVERFLAG,
			DISPLAYSEQUENCE,
			STATUSCODE,
			RENEWALSTATUS,
			FILELOCATION,
			NUMBERTYPE,
			ATLEAST1FLAG,
			USERINSTRUCTION,
			INHERITED,
			ENTRYCODE,
			CHARGEGENERATION,
			DISPLAYEVENTNO,
			HIDEEVENTNO,
			DIMEVENTNO,
			SHOWTABS,
			SHOWMENUS,
			SHOWTOOLBAR,
			ISSEPARATOR)
		select	IH.CRITERIANO,
			I.ENTRYNUMBER,
			I.ENTRYDESC,
			I.TAKEOVERFLAG,
			I.DISPLAYSEQUENCE,
			I.STATUSCODE,
			I.RENEWALSTATUS,
			I.FILELOCATION,
			I.NUMBERTYPE,
			I.ATLEAST1FLAG,
			I.USERINSTRUCTION,
			1,
			I.ENTRYCODE,
			I.CHARGEGENERATION,
			I.DISPLAYEVENTNO,
			I.HIDEEVENTNO,
			I.DIMEVENTNO,
			I.SHOWTABS,
			I.SHOWMENUS,
			I.SHOWTOOLBAR,
			isnull(I.ISSEPARATOR,0)
		from "+@sUserName+".Imported_DETAILCONTROL I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join DETAILCONTROL C	on ( C.CRITERIANO=CR.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER)
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
grant execute on dbo.ip_RulesDETAILCONTROL  to public
go

