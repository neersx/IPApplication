-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCOUNTRYGROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCOUNTRYGROUP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCOUNTRYGROUP.'
	drop procedure dbo.ip_RulesCOUNTRYGROUP
	print '**** Creating procedure dbo.ip_RulesCOUNTRYGROUP...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCOUNTRYGROUP
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCOUNTRYGROUP
-- VERSION :	4
-- DESCRIPTION:	The comparison/display and merging of imported data for the COUNTRYGROUP table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 19 Jul 2004	MF		1	Procedure created
-- 16 Apr 2009	MF	17472	2	New column PREVENTNATPHASE needs to be catered for.
-- 06 Aug 2015	MF	50897	3	New column FULLMEMBERDATE added.
-- 03 Jan 2017	MF	70323	4	When updating an existing row, do not set to NULL a column that already has a value.
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


-- Prerequisite that the IMPORTED_COUNTRYGROUP table has been loaded

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


-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison
If  @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin

	-- Apply the Mapping if it exists for the Treaty Code

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_COUNTRYGROUP
		SET TREATYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_COUNTRYGROUP C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.TREATYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	-- Apply the Mapping if it exists for the Member Country
	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRYGROUP
			SET MEMBERCOUNTRY = M.MAPVALUE
			FROM "+@sUserName+".Imported_COUNTRYGROUP C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='COUNTRY'
					and M.MAPCOLUMN  ='COUNTRYCODE'
					and M.SOURCEVALUE=C.MEMBERCOUNTRY)
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
			I.TREATYCODE		as 'Imported Treaty',
			I.MEMBERCOUNTRY		as 'Imported Country',
			I.FULLMEMBERDATE	as 'Imported Full Member Date',
			I.DATECOMMENCED		as 'Imported Commenced',
			I.DATECEASED		as 'Imported Ceased',
			dbo.fn_DisplayBoolean(I.ASSOCIATEMEMBER,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Associate Member',
			dbo.fn_DisplayBoolean(I.DEFAULTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Default Flag',
			dbo.fn_DisplayBoolean(I.PREVENTNATPHASE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported No National Phase',
			C.TREATYCODE		as 'Treaty',
			C.MEMBERCOUNTRY		as 'Country',
			C.FULLMEMBERDATE	as 'Full Member Date',
			C.DATECOMMENCED		as 'Commenced',
			C.DATECEASED		as 'Ceased',
			dbo.fn_DisplayBoolean(C.ASSOCIATEMEMBER,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Associate Member',
			dbo.fn_DisplayBoolean(C.DEFAULTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Default Flag',
			dbo.fn_DisplayBoolean(C.PREVENTNATPHASE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'No National Phase'
		from "+@sUserName+".Imported_COUNTRYGROUP I"
		Set @sSQLString2="	join COUNTRYGROUP C	on( C.TREATYCODE=I.TREATYCODE
					and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
		where	(I.DATECOMMENCED=C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is null))
		and	(I.DATECEASED=C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is null))
		and	(I.FULLMEMBERDATE=C.FULLMEMBERDATE OR (I.FULLMEMBERDATE is null and C.FULLMEMBERDATE is null))
		and	(I.ASSOCIATEMEMBER=C.ASSOCIATEMEMBER OR (I.ASSOCIATEMEMBER is null and C.ASSOCIATEMEMBER is null))
		and	(I.DEFAULTFLAG=C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is null))
		and	(I.PREVENTNATPHASE=C.PREVENTNATPHASE OR (I.PREVENTNATPHASE is null and C.PREVENTNATPHASE is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.TREATYCODE,
			I.MEMBERCOUNTRY,
			I.FULLMEMBERDATE,
			I.DATECOMMENCED,
			I.DATECEASED,
			dbo.fn_DisplayBoolean(I.ASSOCIATEMEMBER,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.DEFAULTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.PREVENTNATPHASE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			C.TREATYCODE,
			C.MEMBERCOUNTRY,
			C.FULLMEMBERDATE,
			C.DATECOMMENCED,
			C.DATECEASED,
			dbo.fn_DisplayBoolean(C.ASSOCIATEMEMBER,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.DEFAULTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.PREVENTNATPHASE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
		from "+@sUserName+".Imported_COUNTRYGROUP I"
		Set @sSQLString4="	join COUNTRYGROUP C	on( C.TREATYCODE=I.TREATYCODE
					and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
		where 	I.DATECOMMENCED<>C.DATECOMMENCED OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null)
		OR	I.DATECEASED<>C.DATECEASED OR (I.DATECEASED is not null and C.DATECEASED is null)
		OR	I.FULLMEMBERDATE<>C.FULLMEMBERDATE OR (I.FULLMEMBERDATE is not null and C.FULLMEMBERDATE is null)
		OR	I.ASSOCIATEMEMBER<>C.ASSOCIATEMEMBER OR (I.ASSOCIATEMEMBER is not null and C.ASSOCIATEMEMBER is null)
		OR	I.DEFAULTFLAG<>C.DEFAULTFLAG OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null)
		OR	I.PREVENTNATPHASE<>C.PREVENTNATPHASE OR (I.PREVENTNATPHASE is not null and C.PREVENTNATPHASE is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.TREATYCODE,
			I.MEMBERCOUNTRY,
			I.FULLMEMBERDATE,
			I.DATECOMMENCED,
			I.DATECEASED,
			dbo.fn_DisplayBoolean(I.ASSOCIATEMEMBER,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.DEFAULTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.PREVENTNATPHASE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_COUNTRYGROUP I"
		Set @sSQLString6="	left join COUNTRYGROUP C on( C.TREATYCODE=I.TREATYCODE
					 and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
		where C.TREATYCODE is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4" ELSE "3,4" END
	
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
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
		
		-- The update will not set to NULL a column that already exists.
	
		Set @sSQLString="
		Update COUNTRYGROUP
		set	DATECOMMENCED  =isnull(I.DATECOMMENCED,  C.DATECOMMENCED),
			DATECEASED     =isnull(I.DATECEASED,     C.DATECEASED),
			FULLMEMBERDATE =isnull(I.FULLMEMBERDATE, C.FULLMEMBERDATE),
			ASSOCIATEMEMBER=isnull(I.ASSOCIATEMEMBER,C.ASSOCIATEMEMBER),
			PREVENTNATPHASE=isnull(I.PREVENTNATPHASE,C.PREVENTNATPHASE)
		from	COUNTRYGROUP C
		join	"+@sUserName+".Imported_COUNTRYGROUP I	on ( I.TREATYCODE=C.TREATYCODE
						and I.MEMBERCOUNTRY=C.MEMBERCOUNTRY)
		where 	I.DATECOMMENCED<>C.DATECOMMENCED     OR (I.DATECOMMENCED   is not null and C.DATECOMMENCED   is null)
		OR	I.DATECEASED<>C.DATECEASED           OR (I.DATECEASED      is not null and C.DATECEASED      is null)
		OR	I.FULLMEMBERDATE<>C.FULLMEMBERDATE   OR (I.FULLMEMBERDATE  is not null and C.FULLMEMBERDATE  is null)
		OR	I.ASSOCIATEMEMBER<>C.ASSOCIATEMEMBER OR (I.ASSOCIATEMEMBER is not null and C.ASSOCIATEMEMBER is null)
		OR	I.PREVENTNATPHASE<>C.PREVENTNATPHASE OR (I.PREVENTNATPHASE is not null and C.PREVENTNATPHASE is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into COUNTRYGROUP(
			TREATYCODE,
			MEMBERCOUNTRY,
			FULLMEMBERDATE,
			DATECOMMENCED,
			DATECEASED,
			ASSOCIATEMEMBER,
			DEFAULTFLAG,
			PREVENTNATPHASE)
		select	I.TREATYCODE,
			I.MEMBERCOUNTRY,
			I.FULLMEMBERDATE,
			I.DATECOMMENCED,
			I.DATECEASED,
			I.ASSOCIATEMEMBER,
			I.DEFAULTFLAG,
			I.PREVENTNATPHASE
		from "+@sUserName+".Imported_COUNTRYGROUP I
		left join COUNTRYGROUP C	on ( C.TREATYCODE=I.TREATYCODE
						and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
		where C.TREATYCODE is null"

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
	Set @sSQLString=NULL

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesCOUNTRYGROUP  to public
go

