-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_MAPPING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_MAPPING]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_MAPPING.'
	drop procedure dbo.ip_cc_MAPPING
	print '**** Creating procedure dbo.ip_cc_MAPPING...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_MAPPING
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_MAPPING
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the MAPPING table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 09 May 2014	MF	S22069	2	Where IDENTITY is used on a column, the rows missing from the incoming
--					data need to be removed before the Update and Inserts to avoid potential 
--					duplicate keys on alternate index.
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--
-- 18 Jan 2012 AvdA - for CopyConfig ignore mapping (3-5 unused here but skip to 6 if new value required)
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 		(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the CCImport_MAPPING table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString0		nvarchar(4000)
Declare @sSQLString1		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)
Declare @sSQLString3		nvarchar(4000)
Declare @sSQLString4		nvarchar(4000)
Declare @sSQLString5		nvarchar(4000)

Declare	@ErrorCode			int
Declare @sUserName			nvarchar(40)
Declare	@hDocument	 		int 			-- handle to the XML parameter
Declare @bOriginalKeyColumnExists	bit
Declare @nNewRows			int

Set @ErrorCode=0
Set @bOriginalKeyColumnExists = 0
Set @sUserName	= @psUserName


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString="SELECT * from dbo.fn_cc_MAPPING('"+@psUserName+"')
		order by "+CASE WHEN(@pnOrderBy=1)THEN "1,3" ELSE "3" END 
		
		select isnull(@sSQLString,''), isnull(@sSQLString1,''),isnull(@sSQLString2,''), isnull(@sSQLString3,''),isnull(@sSQLString4,''), isnull(@sSQLString5,'')
		
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


/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete MAPPING
		from CCImport_MAPPING I
		right join MAPPING C	on ( C.ENTRYID=I.ENTRYID)
		where I.ENTRYID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End
/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update MAPPING
		set	STRUCTUREID= I.STRUCTUREID,
			DATASOURCEID= I.DATASOURCEID,
			INPUTCODE= I.INPUTCODE,
			INPUTDESCRIPTION=replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)),
			INPUTCODEID= I.INPUTCODEID,
			OUTPUTCODEID= I.OUTPUTCODEID,
			OUTPUTVALUE= I.OUTPUTVALUE,
			ISNOTAPPLICABLE= I.ISNOTAPPLICABLE
		from	MAPPING C
		join	CCImport_MAPPING I	on ( I.ENTRYID=C.ENTRYID)
" Set @sSQLString1="
		where 		( I.STRUCTUREID <>  C.STRUCTUREID)
		OR 		( I.DATASOURCEID <>  C.DATASOURCEID OR (I.DATASOURCEID is null and C.DATASOURCEID is not null )
 OR (I.DATASOURCEID is not null and C.DATASOURCEID is null))
		OR 		( I.INPUTCODE <>  C.INPUTCODE OR (I.INPUTCODE is null and C.INPUTCODE is not null )
 OR (I.INPUTCODE is not null and C.INPUTCODE is null))
		OR 		(replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)) <>  C.INPUTDESCRIPTION OR (I.INPUTDESCRIPTION is null and C.INPUTDESCRIPTION is not null )
 OR (I.INPUTDESCRIPTION is not null and C.INPUTDESCRIPTION is null))
		OR 		( I.INPUTCODEID <>  C.INPUTCODEID OR (I.INPUTCODEID is null and C.INPUTCODEID is not null )
 OR (I.INPUTCODEID is not null and C.INPUTCODEID is null))
		OR 		( I.OUTPUTCODEID <>  C.OUTPUTCODEID OR (I.OUTPUTCODEID is null and C.OUTPUTCODEID is not null )
 OR (I.OUTPUTCODEID is not null and C.OUTPUTCODEID is null))
		OR 		( I.OUTPUTVALUE <>  C.OUTPUTVALUE OR (I.OUTPUTVALUE is null and C.OUTPUTVALUE is not null )
 OR (I.OUTPUTVALUE is not null and C.OUTPUTVALUE is null))
		OR 		( I.ISNOTAPPLICABLE <>  C.ISNOTAPPLICABLE)
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT MAPPING ON

		-- Insert the rows where existing key not found.
		Insert into MAPPING(
			ENTRYID,
			STRUCTUREID,
			DATASOURCEID,
			INPUTCODE,
			INPUTDESCRIPTION,
			INPUTCODEID,
			OUTPUTCODEID,
			OUTPUTVALUE,
			ISNOTAPPLICABLE)
		select
			I.ENTRYID,
			I.STRUCTUREID,
			I.DATASOURCEID,
			I.INPUTCODE,
			replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)),
			I.INPUTCODEID,
			I.OUTPUTCODEID,
			I.OUTPUTVALUE,
			I.ISNOTAPPLICABLE
		from CCImport_MAPPING I
		left join MAPPING C	on ( C.ENTRYID=I.ENTRYID)
		where C.ENTRYID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT MAPPING OFF
	End
End

-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- ( no mapping is allowed for CopyConfig - return null)
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
grant execute on dbo.ip_cc_MAPPING  to public
go
