-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_NAMETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_NAMETYPE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_NAMETYPE.'
	drop procedure dbo.ip_cc_NAMETYPE
	print '**** Creating procedure dbo.ip_cc_NAMETYPE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE [dbo].[ip_cc_NAMETYPE]
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_NAMETYPE
-- VERSION :	6
-- DESCRIPTION:	The comparison/display and merging of imported data for the NAMETYPE table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 09 May 2014	MF	S22069	2	Where IDENTITY is used on a column, the rows missing from the incoming
--					data need to be removed before the Update and Inserts to avoid potential 
--					duplicate keys on alternate index.
-- 03 Apr 2017	MF	71020	3	New columns added.
-- 29 Apr 2019	MF	DR-41987 4	New Columns.
-- 29 Apr 2019	MF	DR-41987 5	New Column. NAMETYPE.NATIONALITYFLAG
-- 19 Dec 2019	MF	DR-55248 6	Looks like a merge problem.  Reimplemented NAMETYPE.NATIONALITYFLAG.
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


-- Prerequisite that the CCImport_NAMETYPE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_NAMETYPE('"+@psUserName+"')
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
		Delete NAMETYPE
		from CCImport_NAMETYPE I
		right join NAMETYPE C	on ( C.NAMETYPE=I.NAMETYPE)
		where I.NAMETYPE is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update NAMETYPE
		set	DESCRIPTION= I.DESCRIPTION,
			PATHNAMETYPE= I.PATHNAMETYPE,
			PATHRELATIONSHIP= I.PATHRELATIONSHIP,
			HIERARCHYFLAG= I.HIERARCHYFLAG,
			MANDATORYFLAG= I.MANDATORYFLAG,
			KEEPSTREETFLAG= I.KEEPSTREETFLAG,
			COLUMNFLAGS= I.COLUMNFLAGS,
			MAXIMUMALLOWED= I.MAXIMUMALLOWED,
			PICKLISTFLAGS= I.PICKLISTFLAGS,
			SHOWNAMECODE= I.SHOWNAMECODE,
			DEFAULTNAMENO= I.DEFAULTNAMENO,
			NAMERESTRICTFLAG= I.NAMERESTRICTFLAG,
			CHANGEEVENTNO= I.CHANGEEVENTNO,
			FUTURENAMETYPE= I.FUTURENAMETYPE,
			USEHOMENAMEREL= I.USEHOMENAMEREL,
			UPDATEFROMPARENT= I.UPDATEFROMPARENT,
			OLDNAMETYPE= I.OLDNAMETYPE,
			BULKENTRYFLAG= I.BULKENTRYFLAG,
			KOTTEXTTYPE= I.KOTTEXTTYPE,
			PROGRAM= I.PROGRAM,
			ETHICALWALL= I.ETHICALWALL,
			PRIORITYORDER= I.PRIORITYORDER,
			NATIONALITYFLAG= I.NATIONALITYFLAG
		from	NAMETYPE C
		join	CCImport_NAMETYPE I	on ( I.NAMETYPE=C.NAMETYPE)
" Set @sSQLString1="
		where 		( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.PATHNAMETYPE <>  C.PATHNAMETYPE OR (I.PATHNAMETYPE is null and C.PATHNAMETYPE is not null )
 OR (I.PATHNAMETYPE is not null and C.PATHNAMETYPE is null))
		OR 		( I.PATHRELATIONSHIP <>  C.PATHRELATIONSHIP OR (I.PATHRELATIONSHIP is null and C.PATHRELATIONSHIP is not null )
 OR (I.PATHRELATIONSHIP is not null and C.PATHRELATIONSHIP is null))
		OR 		( I.HIERARCHYFLAG <>  C.HIERARCHYFLAG OR (I.HIERARCHYFLAG is null and C.HIERARCHYFLAG is not null )
 OR (I.HIERARCHYFLAG is not null and C.HIERARCHYFLAG is null))
		OR 		( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null )
 OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
		OR 		( I.KEEPSTREETFLAG <>  C.KEEPSTREETFLAG OR (I.KEEPSTREETFLAG is null and C.KEEPSTREETFLAG is not null )
 OR (I.KEEPSTREETFLAG is not null and C.KEEPSTREETFLAG is null))
		OR 		( I.COLUMNFLAGS <>  C.COLUMNFLAGS OR (I.COLUMNFLAGS is null and C.COLUMNFLAGS is not null )
 OR (I.COLUMNFLAGS is not null and C.COLUMNFLAGS is null))
		OR 		( I.MAXIMUMALLOWED <>  C.MAXIMUMALLOWED OR (I.MAXIMUMALLOWED is null and C.MAXIMUMALLOWED is not null )
 OR (I.MAXIMUMALLOWED is not null and C.MAXIMUMALLOWED is null))
		OR 		( I.PICKLISTFLAGS <>  C.PICKLISTFLAGS OR (I.PICKLISTFLAGS is null and C.PICKLISTFLAGS is not null )
 OR (I.PICKLISTFLAGS is not null and C.PICKLISTFLAGS is null))
		OR 		( I.SHOWNAMECODE <>  C.SHOWNAMECODE OR (I.SHOWNAMECODE is null and C.SHOWNAMECODE is not null )
 OR (I.SHOWNAMECODE is not null and C.SHOWNAMECODE is null))
		OR 		( I.DEFAULTNAMENO <>  C.DEFAULTNAMENO OR (I.DEFAULTNAMENO is null and C.DEFAULTNAMENO is not null )
 OR (I.DEFAULTNAMENO is not null and C.DEFAULTNAMENO is null))
		OR 		( I.NAMERESTRICTFLAG <>  C.NAMERESTRICTFLAG OR (I.NAMERESTRICTFLAG is null and C.NAMERESTRICTFLAG is not null )
 OR (I.NAMERESTRICTFLAG is not null and C.NAMERESTRICTFLAG is null))
		OR 		( I.CHANGEEVENTNO <>  C.CHANGEEVENTNO OR (I.CHANGEEVENTNO is null and C.CHANGEEVENTNO is not null )
 OR (I.CHANGEEVENTNO is not null and C.CHANGEEVENTNO is null))
		OR 		( I.FUTURENAMETYPE <>  C.FUTURENAMETYPE OR (I.FUTURENAMETYPE is null and C.FUTURENAMETYPE is not null )
 OR (I.FUTURENAMETYPE is not null and C.FUTURENAMETYPE is null))
		OR 		( I.USEHOMENAMEREL <>  C.USEHOMENAMEREL)
		OR 		( I.UPDATEFROMPARENT <>  C.UPDATEFROMPARENT)
		OR 		( I.OLDNAMETYPE <>  C.OLDNAMETYPE OR (I.OLDNAMETYPE is null and C.OLDNAMETYPE is not null )
 OR (I.OLDNAMETYPE is not null and C.OLDNAMETYPE is null))
" Set @sSQLString2="
		OR 		( I.BULKENTRYFLAG <>  C.BULKENTRYFLAG OR (I.BULKENTRYFLAG is null and C.BULKENTRYFLAG is not null) 
OR (I.BULKENTRYFLAG is not null and C.BULKENTRYFLAG is null))
		OR 		( I.KOTTEXTTYPE <>  C.KOTTEXTTYPE OR (I.KOTTEXTTYPE is null and C.KOTTEXTTYPE is not null) 
OR (I.KOTTEXTTYPE is not null and C.KOTTEXTTYPE is null))
		OR 		( I.PROGRAM <>  C.PROGRAM OR (I.PROGRAM is null and C.PROGRAM is not null) 
OR (I.PROGRAM is not null and C.PROGRAM is null))
		OR 		( I.ETHICALWALL <>  C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is not null) 
OR (I.ETHICALWALL is not null and C.ETHICALWALL is null))
		OR 		( I.PRIORITYORDER <>  C.PRIORITYORDER OR (I.PRIORITYORDER is null and C.PRIORITYORDER is not null) 
OR (I.PRIORITYORDER is not null and C.PRIORITYORDER is null))
		OR 		( I.NATIONALITYFLAG <>  C.NATIONALITYFLAG OR (I.NATIONALITYFLAG is null and C.NATIONALITYFLAG is not null) 
OR (I.NATIONALITYFLAG is not null and C.NATIONALITYFLAG is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
	

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT NAMETYPE ON

		-- Insert the rows where existing key not found.
		Insert into NAMETYPE(
			NAMETYPE,
			DESCRIPTION,
			PATHNAMETYPE,
			PATHRELATIONSHIP,
			HIERARCHYFLAG,
			MANDATORYFLAG,
			KEEPSTREETFLAG,
			COLUMNFLAGS,
			MAXIMUMALLOWED,
			PICKLISTFLAGS,
			SHOWNAMECODE,
			DEFAULTNAMENO,
			NAMERESTRICTFLAG,
			CHANGEEVENTNO,
			FUTURENAMETYPE,
			USEHOMENAMEREL,
			UPDATEFROMPARENT,
			OLDNAMETYPE,
			BULKENTRYFLAG,
			NAMETYPEID,
			KOTTEXTTYPE,
			PROGRAM,
			ETHICALWALL,
			PRIORITYORDER,
			NATIONALITYFLAG)
		select
			I.NAMETYPE,
			I.DESCRIPTION,
			I.PATHNAMETYPE,
			I.PATHRELATIONSHIP,
			I.HIERARCHYFLAG,
			I.MANDATORYFLAG,
			I.KEEPSTREETFLAG,
			I.COLUMNFLAGS,
			I.MAXIMUMALLOWED,
			I.PICKLISTFLAGS,
			I.SHOWNAMECODE,
			I.DEFAULTNAMENO,
			I.NAMERESTRICTFLAG,
			I.CHANGEEVENTNO,
			I.FUTURENAMETYPE,
			I.USEHOMENAMEREL,
			I.UPDATEFROMPARENT,
			I.OLDNAMETYPE,
			I.BULKENTRYFLAG,
			I.NAMETYPEID,
			I.KOTTEXTTYPE,
			I.PROGRAM,
			I.ETHICALWALL,
			I.PRIORITYORDER,
			I.NATIONALITYFLAG
		from CCImport_NAMETYPE I
		left join NAMETYPE C	on ( C.NAMETYPE=I.NAMETYPE)
		where C.NAMETYPE is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT NAMETYPE OFF
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
grant execute on dbo.ip_cc_NAMETYPE  to public
go
