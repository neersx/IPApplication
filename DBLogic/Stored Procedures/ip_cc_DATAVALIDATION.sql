-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_DATAVALIDATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_DATAVALIDATION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_DATAVALIDATION.'
	drop procedure dbo.ip_cc_DATAVALIDATION
	print '**** Creating procedure dbo.ip_cc_DATAVALIDATION...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_DATAVALIDATION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_DATAVALIDATION
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the DATAVALIDATION table
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


-- Prerequisite that the CCImport_DATAVALIDATION table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_DATAVALIDATION('"+@psUserName+"')
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
		Delete DATAVALIDATION
		from CCImport_DATAVALIDATION I
		right join DATAVALIDATION C	on ( C.VALIDATIONID=I.VALIDATIONID)
		where I.VALIDATIONID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DATAVALIDATION
		set	INUSEFLAG= I.INUSEFLAG,
			DEFERREDFLAG= I.DEFERREDFLAG,
			OFFICEID= I.OFFICEID,
			FUNCTIONALAREA= I.FUNCTIONALAREA,
			CASETYPE= I.CASETYPE,
			COUNTRYCODE= I.COUNTRYCODE,
			PROPERTYTYPE= I.PROPERTYTYPE,
			CASECATEGORY= I.CASECATEGORY,
			SUBTYPE= I.SUBTYPE,
			BASIS= I.BASIS,
			EVENTNO= I.EVENTNO,
			EVENTDATEFLAG= I.EVENTDATEFLAG,
			STATUSFLAG= I.STATUSFLAG,
			FAMILYNO= I.FAMILYNO,
			LOCALCLIENTFLAG= I.LOCALCLIENTFLAG,
			USEDASFLAG= I.USEDASFLAG,
			SUPPLIERFLAG= I.SUPPLIERFLAG,
			CATEGORY= I.CATEGORY,
			NAMENO= I.NAMENO,
			NAMETYPE= I.NAMETYPE,
			INSTRUCTIONTYPE= I.INSTRUCTIONTYPE,
			FLAGNUMBER= I.FLAGNUMBER,
			COLUMNNAME= I.COLUMNNAME,
			RULEDESCRIPTION=replace( I.RULEDESCRIPTION,char(10),char(13)+char(10)),
			ITEM_ID= I.ITEM_ID,
			ROLEID= I.ROLEID,
			PROGRAMCONTEXT= I.PROGRAMCONTEXT,
			WARNINGFLAG= I.WARNINGFLAG,
			DISPLAYMESSAGE= I.DISPLAYMESSAGE,
			NOTES= I.NOTES,
			NOTCASETYPE= I.NOTCASETYPE,
			NOTCOUNTRYCODE= I.NOTCOUNTRYCODE,
			NOTPROPERTYTYPE= I.NOTPROPERTYTYPE,
			NOTCASECATEGORY= I.NOTCASECATEGORY,
			NOTSUBTYPE= I.NOTSUBTYPE,
			NOTBASIS= I.NOTBASIS
		from	DATAVALIDATION C
		join	CCImport_DATAVALIDATION I	on ( I.VALIDATIONID=C.VALIDATIONID)
" Set @sSQLString1="
		where 		( I.INUSEFLAG <>  C.INUSEFLAG)
		OR 		( I.DEFERREDFLAG <>  C.DEFERREDFLAG)
		OR 		( I.OFFICEID <>  C.OFFICEID OR (I.OFFICEID is null and C.OFFICEID is not null )
 OR (I.OFFICEID is not null and C.OFFICEID is null))
		OR 		( I.FUNCTIONALAREA <>  C.FUNCTIONALAREA OR (I.FUNCTIONALAREA is null and C.FUNCTIONALAREA is not null )
 OR (I.FUNCTIONALAREA is not null and C.FUNCTIONALAREA is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null )
 OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
		OR 		( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null )
 OR (I.SUBTYPE is not null and C.SUBTYPE is null))
		OR 		( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null )
 OR (I.BASIS is not null and C.BASIS is null))
		OR 		( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null )
 OR (I.EVENTNO is not null and C.EVENTNO is null))
		OR 		( I.EVENTDATEFLAG <>  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null )
 OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null))
		OR 		( I.STATUSFLAG <>  C.STATUSFLAG OR (I.STATUSFLAG is null and C.STATUSFLAG is not null )
 OR (I.STATUSFLAG is not null and C.STATUSFLAG is null))
		OR 		( I.FAMILYNO <>  C.FAMILYNO OR (I.FAMILYNO is null and C.FAMILYNO is not null )
 OR (I.FAMILYNO is not null and C.FAMILYNO is null))
		OR 		( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null )
 OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
		OR 		( I.USEDASFLAG <>  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is not null )
 OR (I.USEDASFLAG is not null and C.USEDASFLAG is null))
		OR 		( I.SUPPLIERFLAG <>  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is not null )
 OR (I.SUPPLIERFLAG is not null and C.SUPPLIERFLAG is null))
" Set @sSQLString2="
		OR 		( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null) 
OR (I.CATEGORY is not null and C.CATEGORY is null))
		OR 		( I.NAMENO <>  C.NAMENO OR (I.NAMENO is null and C.NAMENO is not null) 
OR (I.NAMENO is not null and C.NAMENO is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
		OR 		( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
		OR 		( I.COLUMNNAME <>  C.COLUMNNAME OR (I.COLUMNNAME is null and C.COLUMNNAME is not null) 
OR (I.COLUMNNAME is not null and C.COLUMNNAME is null))
		OR 		(replace( I.RULEDESCRIPTION,char(10),char(13)+char(10)) <>  C.RULEDESCRIPTION OR (I.RULEDESCRIPTION is null and C.RULEDESCRIPTION is not null) 
OR (I.RULEDESCRIPTION is not null and C.RULEDESCRIPTION is null))
		OR 		( I.ITEM_ID <>  C.ITEM_ID OR (I.ITEM_ID is null and C.ITEM_ID is not null) 
OR (I.ITEM_ID is not null and C.ITEM_ID is null))
		OR 		( I.ROLEID <>  C.ROLEID OR (I.ROLEID is null and C.ROLEID is not null) 
OR (I.ROLEID is not null and C.ROLEID is null))
		OR 		( I.PROGRAMCONTEXT <>  C.PROGRAMCONTEXT OR (I.PROGRAMCONTEXT is null and C.PROGRAMCONTEXT is not null) 
OR (I.PROGRAMCONTEXT is not null and C.PROGRAMCONTEXT is null))
		OR 		( I.WARNINGFLAG <>  C.WARNINGFLAG OR (I.WARNINGFLAG is null and C.WARNINGFLAG is not null) 
OR (I.WARNINGFLAG is not null and C.WARNINGFLAG is null))
		OR 		( I.DISPLAYMESSAGE <>  C.DISPLAYMESSAGE OR (I.DISPLAYMESSAGE is null and C.DISPLAYMESSAGE is not null) 
OR (I.DISPLAYMESSAGE is not null and C.DISPLAYMESSAGE is null))
		OR 		( I.NOTES <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
		OR 		( I.NOTCASETYPE <>  C.NOTCASETYPE OR (I.NOTCASETYPE is null and C.NOTCASETYPE is not null) 
OR (I.NOTCASETYPE is not null and C.NOTCASETYPE is null))
		OR 		( I.NOTCOUNTRYCODE <>  C.NOTCOUNTRYCODE OR (I.NOTCOUNTRYCODE is null and C.NOTCOUNTRYCODE is not null) 
OR (I.NOTCOUNTRYCODE is not null and C.NOTCOUNTRYCODE is null))
		OR 		( I.NOTPROPERTYTYPE <>  C.NOTPROPERTYTYPE OR (I.NOTPROPERTYTYPE is null and C.NOTPROPERTYTYPE is not null) 
OR (I.NOTPROPERTYTYPE is not null and C.NOTPROPERTYTYPE is null))
		OR 		( I.NOTCASECATEGORY <>  C.NOTCASECATEGORY OR (I.NOTCASECATEGORY is null and C.NOTCASECATEGORY is not null) 
OR (I.NOTCASECATEGORY is not null and C.NOTCASECATEGORY is null))
		OR 		( I.NOTSUBTYPE <>  C.NOTSUBTYPE OR (I.NOTSUBTYPE is null and C.NOTSUBTYPE is not null) 
OR (I.NOTSUBTYPE is not null and C.NOTSUBTYPE is null))
" Set @sSQLString3="
		OR 		( I.NOTBASIS <>  C.NOTBASIS OR (I.NOTBASIS is null and C.NOTBASIS is not null ) 
OR (I.NOTBASIS is not null and C.NOTBASIS is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT DATAVALIDATION ON

		-- Insert the rows where existing key not found.
		Insert into DATAVALIDATION(
			VALIDATIONID,
			INUSEFLAG,
			DEFERREDFLAG,
			OFFICEID,
			FUNCTIONALAREA,
			CASETYPE,
			COUNTRYCODE,
			PROPERTYTYPE,
			CASECATEGORY,
			SUBTYPE,
			BASIS,
			EVENTNO,
			EVENTDATEFLAG,
			STATUSFLAG,
			FAMILYNO,
			LOCALCLIENTFLAG,
			USEDASFLAG,
			SUPPLIERFLAG,
			CATEGORY,
			NAMENO,
			NAMETYPE,
			INSTRUCTIONTYPE,
			FLAGNUMBER,
			COLUMNNAME,
			RULEDESCRIPTION,
			ITEM_ID,
			ROLEID,
			PROGRAMCONTEXT,
			WARNINGFLAG,
			DISPLAYMESSAGE,
			NOTES,
			NOTCASETYPE,
			NOTCOUNTRYCODE,
			NOTPROPERTYTYPE,
			NOTCASECATEGORY,
			NOTSUBTYPE,
			NOTBASIS)
		select
			I.VALIDATIONID,
			I.INUSEFLAG,
			I.DEFERREDFLAG,
			I.OFFICEID,
			I.FUNCTIONALAREA,
			I.CASETYPE,
			I.COUNTRYCODE,
			I.PROPERTYTYPE,
			I.CASECATEGORY,
			I.SUBTYPE,
			I.BASIS,
			I.EVENTNO,
			I.EVENTDATEFLAG,
			I.STATUSFLAG,
			I.FAMILYNO,
			I.LOCALCLIENTFLAG,
			I.USEDASFLAG,
			I.SUPPLIERFLAG,
			I.CATEGORY,
			I.NAMENO,
			I.NAMETYPE,
			I.INSTRUCTIONTYPE,
			I.FLAGNUMBER,
			I.COLUMNNAME,
			replace( I.RULEDESCRIPTION,char(10),char(13)+char(10)),
			I.ITEM_ID,
			I.ROLEID,
			I.PROGRAMCONTEXT,
			I.WARNINGFLAG,
			I.DISPLAYMESSAGE,
			I.NOTES,
			I.NOTCASETYPE,
			I.NOTCOUNTRYCODE,
			I.NOTPROPERTYTYPE,
			I.NOTCASECATEGORY,
			I.NOTSUBTYPE,
			I.NOTBASIS
		from CCImport_DATAVALIDATION I
		left join DATAVALIDATION C	on ( C.VALIDATIONID=I.VALIDATIONID)
		where C.VALIDATIONID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT DATAVALIDATION OFF
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
grant execute on dbo.ip_cc_DATAVALIDATION  to public
go
