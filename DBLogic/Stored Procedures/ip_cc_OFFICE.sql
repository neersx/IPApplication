-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_OFFICE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_OFFICE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_OFFICE.'
	drop procedure dbo.ip_cc_OFFICE
	print '**** Creating procedure dbo.ip_cc_OFFICE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_OFFICE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_OFFICE
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the OFFICE table
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


-- Prerequisite that the CCImport_OFFICE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_OFFICE('"+@psUserName+"')
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
		Update OFFICE
		set	DESCRIPTION= I.DESCRIPTION,
			USERCODE= I.USERCODE,
			COUNTRYCODE= I.COUNTRYCODE,
			LANGUAGECODE= I.LANGUAGECODE,
			CPACODE= I.CPACODE,
			RESOURCENO= I.RESOURCENO,
			ITEMNOPREFIX= I.ITEMNOPREFIX,
			ITEMNOFROM= I.ITEMNOFROM,
			ITEMNOTO= I.ITEMNOTO,
			LASTITEMNO= I.LASTITEMNO,
			REGION= I.REGION,
			ORGNAMENO= I.ORGNAMENO,
			IRNCODE= I.IRNCODE
		from	OFFICE C
		join	CCImport_OFFICE I	on ( I.OFFICEID=C.OFFICEID)
" Set @sSQLString1="
		where 		( I.DESCRIPTION <>  C.DESCRIPTION)
		OR 		( I.USERCODE <>  C.USERCODE OR (I.USERCODE is null and C.USERCODE is not null )
 OR (I.USERCODE is not null and C.USERCODE is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.LANGUAGECODE <>  C.LANGUAGECODE OR (I.LANGUAGECODE is null and C.LANGUAGECODE is not null )
 OR (I.LANGUAGECODE is not null and C.LANGUAGECODE is null))
		OR 		( I.CPACODE <>  C.CPACODE OR (I.CPACODE is null and C.CPACODE is not null )
 OR (I.CPACODE is not null and C.CPACODE is null))
		OR 		( I.RESOURCENO <>  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is not null )
 OR (I.RESOURCENO is not null and C.RESOURCENO is null))
		OR 		( I.ITEMNOPREFIX <>  C.ITEMNOPREFIX OR (I.ITEMNOPREFIX is null and C.ITEMNOPREFIX is not null )
 OR (I.ITEMNOPREFIX is not null and C.ITEMNOPREFIX is null))
		OR 		( I.ITEMNOFROM <>  C.ITEMNOFROM OR (I.ITEMNOFROM is null and C.ITEMNOFROM is not null )
 OR (I.ITEMNOFROM is not null and C.ITEMNOFROM is null))
		OR 		( I.ITEMNOTO <>  C.ITEMNOTO OR (I.ITEMNOTO is null and C.ITEMNOTO is not null )
 OR (I.ITEMNOTO is not null and C.ITEMNOTO is null))
		OR 		( I.LASTITEMNO <>  C.LASTITEMNO OR (I.LASTITEMNO is null and C.LASTITEMNO is not null )
 OR (I.LASTITEMNO is not null and C.LASTITEMNO is null))
		OR 		( I.REGION <>  C.REGION OR (I.REGION is null and C.REGION is not null )
 OR (I.REGION is not null and C.REGION is null))
		OR 		( I.ORGNAMENO <>  C.ORGNAMENO OR (I.ORGNAMENO is null and C.ORGNAMENO is not null )
 OR (I.ORGNAMENO is not null and C.ORGNAMENO is null))
		OR 		( I.IRNCODE <>  C.IRNCODE OR (I.IRNCODE is null and C.IRNCODE is not null )
 OR (I.IRNCODE is not null and C.IRNCODE is null))
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
		Insert into OFFICE(
			OFFICEID,
			DESCRIPTION,
			USERCODE,
			COUNTRYCODE,
			LANGUAGECODE,
			CPACODE,
			RESOURCENO,
			ITEMNOPREFIX,
			ITEMNOFROM,
			ITEMNOTO,
			LASTITEMNO,
			REGION,
			ORGNAMENO,
			IRNCODE)
		select
	 I.OFFICEID,
	 I.DESCRIPTION,
	 I.USERCODE,
	 I.COUNTRYCODE,
	 I.LANGUAGECODE,
	 I.CPACODE,
	 I.RESOURCENO,
	 I.ITEMNOPREFIX,
	 I.ITEMNOFROM,
	 I.ITEMNOTO,
	 I.LASTITEMNO,
	 I.REGION,
	 I.ORGNAMENO,
	 I.IRNCODE
		from CCImport_OFFICE I
		left join OFFICE C	on ( C.OFFICEID=I.OFFICEID)
		where C.OFFICEID is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete OFFICE
		from CCImport_OFFICE I
		right join OFFICE C	on ( C.OFFICEID=I.OFFICEID)
		where I.OFFICEID is null"

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
grant execute on dbo.ip_cc_OFFICE  to public
go
