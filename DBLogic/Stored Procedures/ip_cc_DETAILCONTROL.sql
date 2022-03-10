-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_DETAILCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_DETAILCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_DETAILCONTROL.'
	drop procedure dbo.ip_cc_DETAILCONTROL
	print '**** Creating procedure dbo.ip_cc_DETAILCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_DETAILCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_DETAILCONTROL
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the DETAILCONTROL table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 01 May 2017	MF	71205	2	Add new column ISSEPERATOR
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


-- Prerequisite that the CCImport_DETAILCONTROL table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_DETAILCONTROL('"+@psUserName+"')
		order by "+CASE WHEN(@pnOrderBy=1)THEN "1,3,4" ELSE "3,4" END 
		
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
		Update DETAILCONTROL
		set	ENTRYDESC= I.ENTRYDESC,
			TAKEOVERFLAG= I.TAKEOVERFLAG,
			DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			STATUSCODE= I.STATUSCODE,
			RENEWALSTATUS= I.RENEWALSTATUS,
			FILELOCATION= I.FILELOCATION,
			NUMBERTYPE= I.NUMBERTYPE,
			ATLEAST1FLAG= I.ATLEAST1FLAG,
			USERINSTRUCTION=replace( I.USERINSTRUCTION,char(10),char(13)+char(10)),
			INHERITED= I.INHERITED,
			ENTRYCODE= I.ENTRYCODE,
			CHARGEGENERATION= I.CHARGEGENERATION,
			DISPLAYEVENTNO= I.DISPLAYEVENTNO,
			HIDEEVENTNO= I.HIDEEVENTNO,
			DIMEVENTNO= I.DIMEVENTNO,
			SHOWTABS= I.SHOWTABS,
			SHOWMENUS= I.SHOWMENUS,
			SHOWTOOLBAR= I.SHOWTOOLBAR,
			PARENTCRITERIANO= I.PARENTCRITERIANO,
			PARENTENTRYNUMBER= I.PARENTENTRYNUMBER,
			POLICINGIMMEDIATE= I.POLICINGIMMEDIATE,
			ISSEPARATOR= I.ISSEPARATOR
		from	DETAILCONTROL C
		join	CCImport_DETAILCONTROL I	on ( I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=C.ENTRYNUMBER)
" Set @sSQLString1="
		where 		( I.ENTRYDESC <>  C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is not null )
 OR (I.ENTRYDESC is not null and C.ENTRYDESC is null))
		OR 		( I.TAKEOVERFLAG <>  C.TAKEOVERFLAG OR (I.TAKEOVERFLAG is null and C.TAKEOVERFLAG is not null )
 OR (I.TAKEOVERFLAG is not null and C.TAKEOVERFLAG is null))
		OR 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE)
		OR 		( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null )
 OR (I.STATUSCODE is not null and C.STATUSCODE is null))
		OR 		( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null )
 OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
		OR 		( I.FILELOCATION <>  C.FILELOCATION OR (I.FILELOCATION is null and C.FILELOCATION is not null )
 OR (I.FILELOCATION is not null and C.FILELOCATION is null))
		OR 		( I.NUMBERTYPE <>  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null )
 OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null))
		OR 		( I.ATLEAST1FLAG <>  C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is not null )
 OR (I.ATLEAST1FLAG is not null and C.ATLEAST1FLAG is null))
		OR 		(replace( I.USERINSTRUCTION,char(10),char(13)+char(10)) <>  C.USERINSTRUCTION OR (I.USERINSTRUCTION is null and C.USERINSTRUCTION is not null )
 OR (I.USERINSTRUCTION is not null and C.USERINSTRUCTION is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null )
 OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.ENTRYCODE <>  C.ENTRYCODE OR (I.ENTRYCODE is null and C.ENTRYCODE is not null )
 OR (I.ENTRYCODE is not null and C.ENTRYCODE is null))
		OR 		( I.CHARGEGENERATION <>  C.CHARGEGENERATION OR (I.CHARGEGENERATION is null and C.CHARGEGENERATION is not null )
 OR (I.CHARGEGENERATION is not null and C.CHARGEGENERATION is null))
		OR 		( I.DISPLAYEVENTNO <>  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is not null )
 OR (I.DISPLAYEVENTNO is not null and C.DISPLAYEVENTNO is null))
		OR 		( I.HIDEEVENTNO <>  C.HIDEEVENTNO OR (I.HIDEEVENTNO is null and C.HIDEEVENTNO is not null )
 OR (I.HIDEEVENTNO is not null and C.HIDEEVENTNO is null))
		OR 		( I.DIMEVENTNO <>  C.DIMEVENTNO OR (I.DIMEVENTNO is null and C.DIMEVENTNO is not null )
 OR (I.DIMEVENTNO is not null and C.DIMEVENTNO is null))
		OR 		( I.SHOWTABS <>  C.SHOWTABS OR (I.SHOWTABS is null and C.SHOWTABS is not null )
 OR (I.SHOWTABS is not null and C.SHOWTABS is null))
" Set @sSQLString2="
		OR 		( I.SHOWMENUS <>  C.SHOWMENUS OR (I.SHOWMENUS is null and C.SHOWMENUS is not null) 
OR (I.SHOWMENUS is not null and C.SHOWMENUS is null))
		OR 		( I.SHOWTOOLBAR <>  C.SHOWTOOLBAR OR (I.SHOWTOOLBAR is null and C.SHOWTOOLBAR is not null) 
OR (I.SHOWTOOLBAR is not null and C.SHOWTOOLBAR is null))
		OR 		( I.PARENTCRITERIANO <>  C.PARENTCRITERIANO OR (I.PARENTCRITERIANO is null and C.PARENTCRITERIANO is not null) 
OR (I.PARENTCRITERIANO is not null and C.PARENTCRITERIANO is null))
		OR 		( I.PARENTENTRYNUMBER <>  C.PARENTENTRYNUMBER OR (I.PARENTENTRYNUMBER is null and C.PARENTENTRYNUMBER is not null) 
OR (I.PARENTENTRYNUMBER is not null and C.PARENTENTRYNUMBER is null))
		OR 		( I.POLICINGIMMEDIATE <>  C.POLICINGIMMEDIATE)
		OR 		( I.ISSEPARATOR       <>  C.ISSEPARATOR)
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
			PARENTCRITERIANO,
			PARENTENTRYNUMBER,
			POLICINGIMMEDIATE,
			ISSEPARATOR)
		select
			 I.CRITERIANO,
			 I.ENTRYNUMBER,
			 I.ENTRYDESC,
			 I.TAKEOVERFLAG,
			 I.DISPLAYSEQUENCE,
			 I.STATUSCODE,
			 I.RENEWALSTATUS,
			 I.FILELOCATION,
			 I.NUMBERTYPE,
			 I.ATLEAST1FLAG,
			 replace( I.USERINSTRUCTION,char(10),char(13)+char(10)),
			 I.INHERITED,
			 I.ENTRYCODE,
			 I.CHARGEGENERATION,
			 I.DISPLAYEVENTNO,
			 I.HIDEEVENTNO,
			 I.DIMEVENTNO,
			 I.SHOWTABS,
			 I.SHOWMENUS,
			 I.SHOWTOOLBAR,
			 I.PARENTCRITERIANO,
			 I.PARENTENTRYNUMBER,
			 I.POLICINGIMMEDIATE,
			 I.ISSEPARATOR
		from CCImport_DETAILCONTROL I
		left join DETAILCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER)
		where C.CRITERIANO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete DETAILCONTROL
		from CCImport_DETAILCONTROL I
		right join DETAILCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER)
		where I.CRITERIANO is null"

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
grant execute on dbo.ip_cc_DETAILCONTROL  to public
go
