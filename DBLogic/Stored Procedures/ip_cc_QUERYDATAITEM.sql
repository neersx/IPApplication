-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_QUERYDATAITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_QUERYDATAITEM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_QUERYDATAITEM.'
	drop procedure dbo.ip_cc_QUERYDATAITEM
	print '**** Creating procedure dbo.ip_cc_QUERYDATAITEM...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_QUERYDATAITEM
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_QUERYDATAITEM
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the QUERYDATAITEM table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
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


-- Prerequisite that the CCImport_QUERYDATAITEM table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_QUERYDATAITEM('"+@psUserName+"')
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

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update QUERYDATAITEM
		set	PROCEDURENAME= I.PROCEDURENAME,
			PROCEDUREITEMID= I.PROCEDUREITEMID,
			QUALIFIERTYPE= I.QUALIFIERTYPE,
			SORTDIRECTION= I.SORTDIRECTION,
			DESCRIPTION=replace( I.DESCRIPTION,char(10),char(13)+char(10)),
			ISMULTIRESULT= I.ISMULTIRESULT,
			DATAFORMATID= I.DATAFORMATID,
			DECIMALPLACES= I.DECIMALPLACES,
			FORMATITEMID= I.FORMATITEMID,
			FILTERNODENAME= I.FILTERNODENAME,
			ISAGGREGATE= I.ISAGGREGATE
		from	QUERYDATAITEM C
		join	CCImport_QUERYDATAITEM I	on ( I.DATAITEMID=C.DATAITEMID)
" Set @sSQLString1="
		where 		( I.PROCEDURENAME <>  C.PROCEDURENAME)
		OR 		( I.PROCEDUREITEMID <>  C.PROCEDUREITEMID)
		OR 		( I.QUALIFIERTYPE <>  C.QUALIFIERTYPE OR (I.QUALIFIERTYPE is null and C.QUALIFIERTYPE is not null )
 OR (I.QUALIFIERTYPE is not null and C.QUALIFIERTYPE is null))
		OR 		( I.SORTDIRECTION <>  C.SORTDIRECTION OR (I.SORTDIRECTION is null and C.SORTDIRECTION is not null )
 OR (I.SORTDIRECTION is not null and C.SORTDIRECTION is null))
		OR 		(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.ISMULTIRESULT <>  C.ISMULTIRESULT)
		OR 		( I.DATAFORMATID <>  C.DATAFORMATID)
		OR 		( I.DECIMALPLACES <>  C.DECIMALPLACES OR (I.DECIMALPLACES is null and C.DECIMALPLACES is not null )
 OR (I.DECIMALPLACES is not null and C.DECIMALPLACES is null))
		OR 		( I.FORMATITEMID <>  C.FORMATITEMID OR (I.FORMATITEMID is null and C.FORMATITEMID is not null )
 OR (I.FORMATITEMID is not null and C.FORMATITEMID is null))
		OR 		( I.FILTERNODENAME <>  C.FILTERNODENAME OR (I.FILTERNODENAME is null and C.FILTERNODENAME is not null )
 OR (I.FILTERNODENAME is not null and C.FILTERNODENAME is null))
		OR 		( I.ISAGGREGATE <>  C.ISAGGREGATE)
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Set @ErrorCode=@@Error 
		Set @pnRowCount=@@rowcount
	End 

	/**************** Data Insert ***************************************/
		If @ErrorCode=0
		Begin
	

		-- Insert the rows where existing key not found.
		Set @sSQLString= "

		-- Insert the rows where existing key not found.
		Insert into QUERYDATAITEM(
			DATAITEMID,
			PROCEDURENAME,
			PROCEDUREITEMID,
			QUALIFIERTYPE,
			SORTDIRECTION,
			DESCRIPTION,
			ISMULTIRESULT,
			DATAFORMATID,
			DECIMALPLACES,
			FORMATITEMID,
			FILTERNODENAME,
			ISAGGREGATE)
		select
	 I.DATAITEMID,
	 I.PROCEDURENAME,
	 I.PROCEDUREITEMID,
	 I.QUALIFIERTYPE,
	 I.SORTDIRECTION,
	replace( I.DESCRIPTION,char(10),char(13)+char(10)),
	 I.ISMULTIRESULT,
	 I.DATAFORMATID,
	 I.DECIMALPLACES,
	 I.FORMATITEMID,
	 I.FILTERNODENAME,
	 I.ISAGGREGATE
		from CCImport_QUERYDATAITEM I
		left join QUERYDATAITEM C	on ( C.DATAITEMID=I.DATAITEMID)
		where C.DATAITEMID is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete QUERYDATAITEM
		from CCImport_QUERYDATAITEM I
		right join QUERYDATAITEM C	on ( C.DATAITEMID=I.DATAITEMID)
		where I.DATAITEMID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
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
grant execute on dbo.ip_cc_QUERYDATAITEM  to public
go
