-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesTABLEATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesTABLEATTRIBUTES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesTABLEATTRIBUTES.'
	drop procedure dbo.ip_RulesTABLEATTRIBUTES
	print '**** Creating procedure dbo.ip_RulesTABLEATTRIBUTES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesTABLEATTRIBUTES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesTABLEATTRIBUTES
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the TABLEATTRIBUTES table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 16 Aug 2007	MF	15018	1	Procedure created
-- 02 Sep 2008	MF	16886	2	When checking for the existence of the imported row in TABLEATTRIBUES,
--					the TABLETYPE column is not required in the join as this may be null.
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


-- Prerequisite that the IMPORTED_TABLEATTRIBUTES table has been loaded

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

	-- Apply the Mapping if it exists for the Country Code held as the
	-- generic key in the TableAttribute table.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_TABLEATTRIBUTES
		SET GENERICKEY = M.MAPVALUE
		FROM "+@sUserName+".Imported_TABLEATTRIBUTES C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.GENERICKEY)
		WHERE M.MAPVALUE is not null
		and C.PARENTTABLE='COUNTRY'"

	exec @ErrorCode=sp_executesql @sSQLString
	
	-- Apply the Mapping if it exists for TABLECODE
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_TABLEATTRIBUTES
			SET TABLECODE = M.MAPVALUE
			FROM "+@sUserName+".Imported_TABLEATTRIBUTES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.TABLECODE)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	-- Apply the Mapping if it exists for TABLETYPE
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_TABLEATTRIBUTES
			SET TABLETYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_TABLEATTRIBUTES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLETYPE'
					and M.MAPCOLUMN  ='TABLETYPE'
					and M.SOURCEVALUE=C.TABLETYPE)
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
			I.GENERICKEY		as 'Imported Country',
			TC.DESCRIPTION		as 'Imported Table Code',
			TT.TABLENAME		as 'Imported Table Type',
			C.GENERICKEY		as 'Country',
			TC.DESCRIPTION		as 'Table Code',
			TT.TABLENAME		as 'Table Typed'
		from "+@sUserName+".Imported_TABLEATTRIBUTES I"
		Set @sSQLString2="
		join "+@sUserName+".Imported_TABLECODES TC on (TC.TABLECODE=I.TABLECODE)
		join "+@sUserName+".Imported_TABLETYPE TT  on (TT.TABLETYPE=I.TABLETYPE)
		join TABLEATTRIBUTES C	on( C.PARENTTABLE=I.PARENTTABLE
					and C.GENERICKEY =I.GENERICKEY
					and C.TABLECODE  =I.TABLECODE)
		where	I.PARENTTABLE='COUNTRY'
		UNION ALL"
		Set @sSQLString3="
		select	1,
			'X',
			I.GENERICKEY,
			TC.DESCRIPTION,
			TT.TABLENAME,
			NULL,
			NULL,
			NULL
		from "+@sUserName+".Imported_TABLEATTRIBUTES I"
		Set @sSQLString4="
		join "+@sUserName+".Imported_TABLECODES TC on (TC.TABLECODE=I.TABLECODE)
		join "+@sUserName+".Imported_TABLETYPE TT  on (TT.TABLETYPE=I.TABLETYPE)
		left join TABLEATTRIBUTES C	on( C.PARENTTABLE=I.PARENTTABLE
					and C.GENERICKEY=I.GENERICKEY
					and C.TABLECODE=I.TABLECODE)
		where	I.PARENTTABLE='COUNTRY'
		and	C.PARENTTABLE is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,5" ELSE "3,5" END
	
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
	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into TABLEATTRIBUTES(
			PARENTTABLE,
			GENERICKEY,
			TABLECODE,
			TABLETYPE)
		select	I.PARENTTABLE,
			I.GENERICKEY,
			I.TABLECODE,
			I.TABLETYPE
		from "+@sUserName+".Imported_TABLEATTRIBUTES I
		left join TABLEATTRIBUTES C	on (C.PARENTTABLE=I.PARENTTABLE
						and C.GENERICKEY =I.GENERICKEY
						and C.TABLECODE  =I.TABLECODE)
		where I.PARENTTABLE='COUNTRY'
		and C.PARENTTABLE is null"

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
grant execute on dbo.ip_RulesTABLEATTRIBUTES  to public
go

