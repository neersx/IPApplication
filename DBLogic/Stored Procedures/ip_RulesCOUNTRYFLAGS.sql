-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCOUNTRYFLAGS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCOUNTRYFLAGS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCOUNTRYFLAGS.'
	drop procedure dbo.ip_RulesCOUNTRYFLAGS
	print '**** Creating procedure dbo.ip_RulesCOUNTRYFLAGS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCOUNTRYFLAGS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCOUNTRYFLAGS
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the COUNTRYFLAGS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 02 May 2006	MF	12595	2	Do not overwrite the PROFILENAME
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


-- Prerequisite that the IMPORTED_COUNTRYFLAGS table has been loaded

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
	-- Apply the Mapping if it exists

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_COUNTRYFLAGS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_COUNTRYFLAGS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

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
		select	3			as 'Comparison',
			NULL			as Match,
			I.COUNTRYCODE		as 'Imported Country',
			I.FLAGNUMBER		as 'Imported Flag',
			I.FLAGNAME		as 'Imported Flag Name',
			dbo.fn_DisplayBoolean(I.NATIONALALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported National Allowed',
			dbo.fn_DisplayBoolean(I.RESTRICTREMOVALFLG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Restrict Removal Flag',
			CASE(I.STATUS)
				WHEN(0) Then 'Dead'
				WHEN(1) THEN 'Pending'
				WHEN(2) THEN 'Registered'
			END			as 'Imported Status',
			C.COUNTRYCODE		as 'Country',
			C.FLAGNUMBER		as 'Flag',
			C.FLAGNAME		as 'Flag Name',
			dbo.fn_DisplayBoolean(C.NATIONALALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'National Allowed',
			dbo.fn_DisplayBoolean(C.RESTRICTREMOVALFLG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Restrict Removal Flag',
			CASE(C.STATUS)
				WHEN(0) Then 'Dead'
				WHEN(1) THEN 'Pending'
				WHEN(2) THEN 'Registered'
			END			as 'Status'
		from "+@sUserName+".Imported_COUNTRYFLAGS I"
		Set @sSQLString2="	join COUNTRYFLAGS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.FLAGNUMBER=I.FLAGNUMBER)
		where	(I.FLAGNAME=C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is null))
		and	(I.NATIONALALLOWED=C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is null))
		and	(I.RESTRICTREMOVALFLG=C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is null))
		and	(I.STATUS=C.STATUS)"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			I.FLAGNUMBER,
			I.FLAGNAME,
			dbo.fn_DisplayBoolean(I.NATIONALALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.RESTRICTREMOVALFLG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(I.STATUS)
				WHEN(0) Then 'Dead'
				WHEN(1) THEN 'Pending'
				WHEN(2) THEN 'Registered'
			END,
			C.COUNTRYCODE,
			C.FLAGNUMBER,
			C.FLAGNAME,
			dbo.fn_DisplayBoolean(C.NATIONALALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.RESTRICTREMOVALFLG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(C.STATUS)
				WHEN(0) Then 'Dead'
				WHEN(1) THEN 'Pending'
				WHEN(2) THEN 'Registered'
			END
		from "+@sUserName+".Imported_COUNTRYFLAGS I"
		Set @sSQLString4="	join COUNTRYFLAGS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.FLAGNUMBER=I.FLAGNUMBER)
		where 	I.FLAGNAME<>C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is not null) OR (I.FLAGNAME is not null and C.FLAGNAME is null)
		OR	I.NATIONALALLOWED<>C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is not null) OR (I.NATIONALALLOWED is not null and C.NATIONALALLOWED is null)
		OR	I.RESTRICTREMOVALFLG<>C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is not null) OR (I.RESTRICTREMOVALFLG is not null and C.RESTRICTREMOVALFLG is null)
		OR	I.STATUS<>C.STATUS"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			I.FLAGNUMBER,
			I.FLAGNAME,
			dbo.fn_DisplayBoolean(I.NATIONALALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.RESTRICTREMOVALFLG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE(I.STATUS)
				WHEN(0) Then 'Dead'
				WHEN(1) THEN 'Pending'
				WHEN(2) THEN 'Registered'
			END,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_COUNTRYFLAGS I"
		Set @sSQLString6="	left join COUNTRYFLAGS C on( C.COUNTRYCODE=I.COUNTRYCODE
					 and C.FLAGNUMBER=I.FLAGNUMBER)
		where C.COUNTRYCODE is null
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
	
		Set @sSQLString="
		Update COUNTRYFLAGS
		set	NATIONALALLOWED=I.NATIONALALLOWED,
			RESTRICTREMOVALFLG=I.RESTRICTREMOVALFLG,
			STATUS=I.STATUS,
			FLAGNAME=I.FLAGNAME
		from	COUNTRYFLAGS C
		join	"+@sUserName+".Imported_COUNTRYFLAGS I	on ( I.COUNTRYCODE=C.COUNTRYCODE
						and I.FLAGNUMBER=C.FLAGNUMBER)
		where 	I.FLAGNAME<>C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is not null) OR (I.FLAGNAME is not null and C.FLAGNAME is null)
		OR	I.NATIONALALLOWED<>C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is not null) OR (I.NATIONALALLOWED is not null and C.NATIONALALLOWED is null)
		OR	I.RESTRICTREMOVALFLG<>C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is not null) OR (I.RESTRICTREMOVALFLG is not null and C.RESTRICTREMOVALFLG is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into COUNTRYFLAGS(
			COUNTRYCODE,
			FLAGNUMBER,
			FLAGNAME,
			NATIONALALLOWED,
			RESTRICTREMOVALFLG,
			PROFILENAME,
			STATUS)
		select	I.COUNTRYCODE,
			I.FLAGNUMBER,
			I.FLAGNAME,
			I.NATIONALALLOWED,
			I.RESTRICTREMOVALFLG,
			CP.PROFILENAME,
			I.STATUS
		from "+@sUserName+".Imported_COUNTRYFLAGS I
		left join COUNTRYFLAGS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
						and C.FLAGNUMBER=I.FLAGNUMBER)
		left join (select distinct PROFILENAME
			   from COPYPROFILE) CP	on (CP.PROFILENAME=I.PROFILENAME)
		where C.COUNTRYCODE is null"

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
grant execute on dbo.ip_RulesCOUNTRYFLAGS  to public
go

