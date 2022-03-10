-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesINSTRUCTIONLABEL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesINSTRUCTIONLABEL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesINSTRUCTIONLABEL.'
	drop procedure dbo.ip_RulesINSTRUCTIONLABEL
	print '**** Creating procedure dbo.ip_RulesINSTRUCTIONLABEL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesINSTRUCTIONLABEL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesINSTRUCTIONLABEL
-- VERSION :	5
-- DESCRIPTION:	The comparison/display and merging of imported data for the INSTRUCTIONLABEL table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 24 Oct 2006	MF		1	Procedure created
-- 26 Oct 2010	MF	19140	2	Do not update the FLAGLITERAL if it is different to the imported value.
-- 05 Jan 2011	MF	RFC10149 3	Revisit of SQA19140. Allow differences in FLAGLITERAL value still to be displayed.
-- 20 Jan 2011	MF	19321	4	Do not show differences of FLAGLITERAL.
-- 21 Jan 2011	MF	19321	5	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
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


-- Prerequisite that the IMPORTED_INSTRUCTIONLABEL table has been loaded

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
If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_INSTRUCTIONLABEL
		SET INSTRUCTIONTYPE = M.MAPVALUE
		FROM "+@sUserName+".Imported_INSTRUCTIONLABEL C
		JOIN DATAMAP M		on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='INSTRUCTIONLABEL'
					and M.MAPCOLUMN  ='INSTRUCTIONTYPE'
					and M.SOURCEVALUE=C.INSTRUCTIONTYPE)
		where M.MAPVALUE is not null"

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
			I.INSTRUCTIONTYPE	as 'Imported Instructiontype',
			I.FLAGNUMBER		as 'Imported Flagnumber',
			C.FLAGLITERAL		as 'Imported Flagliteral',
			C.INSTRUCTIONTYPE	as 'Instructiontype',
			C.FLAGNUMBER		as 'Flagnumber',
			C.FLAGLITERAL		as 'Flagliteral'
		from "+@sUserName+".Imported_INSTRUCTIONLABEL I"+char(10)
		Set @sSQLString2="join INSTRUCTIONLABEL C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
					and C.FLAGNUMBER=I.FLAGNUMBER)
		where	(I.FLAGLITERAL=C.FLAGLITERAL OR (I.FLAGLITERAL is null and C.FLAGLITERAL is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.FLAGLITERAL,
			C.INSTRUCTIONTYPE,
			C.FLAGNUMBER,
			C.FLAGLITERAL
		from "+@sUserName+".Imported_INSTRUCTIONLABEL I"
		Set @sSQLString4="	join INSTRUCTIONLABEL C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
					and C.FLAGNUMBER=I.FLAGNUMBER)
		where 	I.FLAGLITERAL<>C.FLAGLITERAL OR (I.FLAGLITERAL is null and C.FLAGLITERAL is not null) OR (I.FLAGLITERAL is not null and C.FLAGLITERAL is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.FLAGLITERAL,
			null,
			null,
			null
		from "+@sUserName+".Imported_INSTRUCTIONLABEL I"
		Set @sSQLString6="		left join INSTRUCTIONLABEL C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
					 and C.FLAGNUMBER=I.FLAGNUMBER)
		where C.INSTRUCTIONTYPE is null
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
	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into INSTRUCTIONLABEL(
			INSTRUCTIONTYPE,
			FLAGNUMBER,
			FLAGLITERAL)
		select	I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.FLAGLITERAL
		from "+@sUserName+".Imported_INSTRUCTIONLABEL I
		left join INSTRUCTIONLABEL C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
						and C.FLAGNUMBER=I.FLAGNUMBER)
		where C.INSTRUCTIONTYPE is null"

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
grant execute on dbo.ip_RulesINSTRUCTIONLABEL  to public
go

