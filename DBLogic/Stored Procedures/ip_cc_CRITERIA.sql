-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_CRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_CRITERIA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_CRITERIA.'
	drop procedure dbo.ip_cc_CRITERIA
	print '**** Creating procedure dbo.ip_cc_CRITERIA...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_CRITERIA
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_CRITERIA
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the CRITERIA table
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
--
-- 23 Jul 2013	DL	S21395	2	Added NEWSUBTYPE to CRITERIA

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the CCImport_CRITERIA table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_CRITERIA('"+@psUserName+"')
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
		Update CRITERIA
		set	PURPOSECODE= I.PURPOSECODE,
			CASETYPE= I.CASETYPE,
			ACTION= I.ACTION,
			CHECKLISTTYPE= I.CHECKLISTTYPE,
			PROGRAMID= I.PROGRAMID,
			PROPERTYTYPE= I.PROPERTYTYPE,
			PROPERTYUNKNOWN= I.PROPERTYUNKNOWN,
			COUNTRYCODE= I.COUNTRYCODE,
			COUNTRYUNKNOWN= I.COUNTRYUNKNOWN,
			CASECATEGORY= I.CASECATEGORY,
			CATEGORYUNKNOWN= I.CATEGORYUNKNOWN,
			SUBTYPE= I.SUBTYPE,
			SUBTYPEUNKNOWN= I.SUBTYPEUNKNOWN,
			BASIS= I.BASIS,
			REGISTEREDUSERS= I.REGISTEREDUSERS,
			LOCALCLIENTFLAG= I.LOCALCLIENTFLAG,
			TABLECODE= I.TABLECODE,
			RATENO= I.RATENO,
			DATEOFACT= I.DATEOFACT,
			USERDEFINEDRULE= I.USERDEFINEDRULE,
			RULEINUSE= I.RULEINUSE,
			STARTDETAILENTRY= I.STARTDETAILENTRY,
			PARENTCRITERIA= I.PARENTCRITERIA,
			BELONGSTOGROUP= I.BELONGSTOGROUP,
			DESCRIPTION=replace( I.DESCRIPTION,char(10),char(13)+char(10)),
			TYPEOFMARK= I.TYPEOFMARK,
			RENEWALTYPE= I.RENEWALTYPE,
			CASEOFFICEID= I.CASEOFFICEID,
			LINKTITLE= I.LINKTITLE,
			LINKDESCRIPTION=replace( I.LINKDESCRIPTION,char(10),char(13)+char(10)),
			DOCITEMID= I.DOCITEMID,
			URL=replace( I.URL,char(10),char(13)+char(10)),
			ISPUBLIC= I.ISPUBLIC,
			GROUPID= I.GROUPID,
			PRODUCTCODE= I.PRODUCTCODE,
			NEWCASETYPE= I.NEWCASETYPE,
			NEWCOUNTRYCODE= I.NEWCOUNTRYCODE,
			NEWPROPERTYTYPE= I.NEWPROPERTYTYPE,
			NEWCASECATEGORY= I.NEWCASECATEGORY,
			NEWSUBTYPE= I.NEWSUBTYPE,
			PROFILENAME= I.PROFILENAME,
			SYSTEMID= I.SYSTEMID,
			DATAEXTRACTID= I.DATAEXTRACTID,
			RULETYPE= I.RULETYPE,
			REQUESTTYPE= I.REQUESTTYPE,
			DATASOURCETYPE= I.DATASOURCETYPE,
			DATASOURCENAMENO= I.DATASOURCENAMENO,
			RENEWALSTATUS= I.RENEWALSTATUS,
			STATUSCODE= I.STATUSCODE,
			PROFILEID= I.PROFILEID
		from	CRITERIA C
		join	CCImport_CRITERIA I	on ( I.CRITERIANO=C.CRITERIANO)
" Set @sSQLString1="
		where 		( I.PURPOSECODE <>  C.PURPOSECODE OR (I.PURPOSECODE is null and C.PURPOSECODE is not null )
 OR (I.PURPOSECODE is not null and C.PURPOSECODE is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null )
 OR (I.ACTION is not null and C.ACTION is null))
		OR 		( I.CHECKLISTTYPE <>  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is not null )
 OR (I.CHECKLISTTYPE is not null and C.CHECKLISTTYPE is null))
		OR 		( I.PROGRAMID <>  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is not null )
 OR (I.PROGRAMID is not null and C.PROGRAMID is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.PROPERTYUNKNOWN <>  C.PROPERTYUNKNOWN OR (I.PROPERTYUNKNOWN is null and C.PROPERTYUNKNOWN is not null )
 OR (I.PROPERTYUNKNOWN is not null and C.PROPERTYUNKNOWN is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.COUNTRYUNKNOWN <>  C.COUNTRYUNKNOWN OR (I.COUNTRYUNKNOWN is null and C.COUNTRYUNKNOWN is not null )
 OR (I.COUNTRYUNKNOWN is not null and C.COUNTRYUNKNOWN is null))
		OR 		( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null )
 OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
		OR 		( I.CATEGORYUNKNOWN <>  C.CATEGORYUNKNOWN OR (I.CATEGORYUNKNOWN is null and C.CATEGORYUNKNOWN is not null )
 OR (I.CATEGORYUNKNOWN is not null and C.CATEGORYUNKNOWN is null))
		OR 		( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null )
 OR (I.SUBTYPE is not null and C.SUBTYPE is null))
		OR 		( I.SUBTYPEUNKNOWN <>  C.SUBTYPEUNKNOWN OR (I.SUBTYPEUNKNOWN is null and C.SUBTYPEUNKNOWN is not null )
 OR (I.SUBTYPEUNKNOWN is not null and C.SUBTYPEUNKNOWN is null))
		OR 		( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null )
 OR (I.BASIS is not null and C.BASIS is null))
		OR 		( I.REGISTEREDUSERS <>  C.REGISTEREDUSERS OR (I.REGISTEREDUSERS is null and C.REGISTEREDUSERS is not null )
 OR (I.REGISTEREDUSERS is not null and C.REGISTEREDUSERS is null))
		OR 		( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null )
 OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
		OR 		( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null )
 OR (I.TABLECODE is not null and C.TABLECODE is null))
" Set @sSQLString2="
		OR 		( I.RATENO <>  C.RATENO OR (I.RATENO is null and C.RATENO is not null) 
OR (I.RATENO is not null and C.RATENO is null))
		OR 		( I.DATEOFACT <>  C.DATEOFACT OR (I.DATEOFACT is null and C.DATEOFACT is not null) 
OR (I.DATEOFACT is not null and C.DATEOFACT is null))
		OR 		( I.USERDEFINEDRULE <>  C.USERDEFINEDRULE OR (I.USERDEFINEDRULE is null and C.USERDEFINEDRULE is not null) 
OR (I.USERDEFINEDRULE is not null and C.USERDEFINEDRULE is null))
		OR 		( I.RULEINUSE <>  C.RULEINUSE OR (I.RULEINUSE is null and C.RULEINUSE is not null) 
OR (I.RULEINUSE is not null and C.RULEINUSE is null))
		OR 		( I.STARTDETAILENTRY <>  C.STARTDETAILENTRY OR (I.STARTDETAILENTRY is null and C.STARTDETAILENTRY is not null) 
OR (I.STARTDETAILENTRY is not null and C.STARTDETAILENTRY is null))
		OR 		( I.PARENTCRITERIA <>  C.PARENTCRITERIA OR (I.PARENTCRITERIA is null and C.PARENTCRITERIA is not null) 
OR (I.PARENTCRITERIA is not null and C.PARENTCRITERIA is null))
		OR 		( I.BELONGSTOGROUP <>  C.BELONGSTOGROUP OR (I.BELONGSTOGROUP is null and C.BELONGSTOGROUP is not null) 
OR (I.BELONGSTOGROUP is not null and C.BELONGSTOGROUP is null))
		OR 		(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null) 
OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
		OR 		( I.RENEWALTYPE <>  C.RENEWALTYPE OR (I.RENEWALTYPE is null and C.RENEWALTYPE is not null) 
OR (I.RENEWALTYPE is not null and C.RENEWALTYPE is null))
		OR 		( I.CASEOFFICEID <>  C.CASEOFFICEID OR (I.CASEOFFICEID is null and C.CASEOFFICEID is not null) 
OR (I.CASEOFFICEID is not null and C.CASEOFFICEID is null))
		OR 		( I.LINKTITLE <>  C.LINKTITLE OR (I.LINKTITLE is null and C.LINKTITLE is not null) 
OR (I.LINKTITLE is not null and C.LINKTITLE is null))
		OR 		(replace( I.LINKDESCRIPTION,char(10),char(13)+char(10)) <>  C.LINKDESCRIPTION OR (I.LINKDESCRIPTION is null and C.LINKDESCRIPTION is not null) 
OR (I.LINKDESCRIPTION is not null and C.LINKDESCRIPTION is null))
		OR 		( I.DOCITEMID <>  C.DOCITEMID OR (I.DOCITEMID is null and C.DOCITEMID is not null) 
OR (I.DOCITEMID is not null and C.DOCITEMID is null))
		OR 		(replace( I.URL,char(10),char(13)+char(10)) <>  C.URL OR (I.URL is null and C.URL is not null) 
OR (I.URL is not null and C.URL is null))
		OR 		( I.ISPUBLIC <>  C.ISPUBLIC)
		OR 		( I.GROUPID <>  C.GROUPID OR (I.GROUPID is null and C.GROUPID is not null) 
OR (I.GROUPID is not null and C.GROUPID is null))
		OR 		( I.PRODUCTCODE <>  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is not null) 
OR (I.PRODUCTCODE is not null and C.PRODUCTCODE is null))
" Set @sSQLString3="
		OR 		( I.NEWCASETYPE <>  C.NEWCASETYPE OR (I.NEWCASETYPE is null and C.NEWCASETYPE is not null ) 
OR (I.NEWCASETYPE is not null and C.NEWCASETYPE is null))
		OR 		( I.NEWCOUNTRYCODE <>  C.NEWCOUNTRYCODE OR (I.NEWCOUNTRYCODE is null and C.NEWCOUNTRYCODE is not null ) 
OR (I.NEWCOUNTRYCODE is not null and C.NEWCOUNTRYCODE is null))
		OR 		( I.NEWPROPERTYTYPE <>  C.NEWPROPERTYTYPE OR (I.NEWPROPERTYTYPE is null and C.NEWPROPERTYTYPE is not null ) 
OR (I.NEWPROPERTYTYPE is not null and C.NEWPROPERTYTYPE is null))
		OR 		( I.NEWCASECATEGORY <>  C.NEWCASECATEGORY OR (I.NEWCASECATEGORY is null and C.NEWCASECATEGORY is not null ) 
OR (I.NEWCASECATEGORY is not null and C.NEWCASECATEGORY is null))
		OR 		( I.NEWSUBTYPE <>  C.NEWSUBTYPE OR (I.NEWSUBTYPE is null and C.NEWSUBTYPE is not null )
 OR (I.NEWSUBTYPE is not null and C.NEWSUBTYPE is null))
		OR 		( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null ) 
OR (I.PROFILENAME is not null and C.PROFILENAME is null))
		OR 		( I.SYSTEMID <>  C.SYSTEMID OR (I.SYSTEMID is null and C.SYSTEMID is not null ) 
OR (I.SYSTEMID is not null and C.SYSTEMID is null))
		OR 		( I.DATAEXTRACTID <>  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is not null ) 
OR (I.DATAEXTRACTID is not null and C.DATAEXTRACTID is null))
		OR 		( I.RULETYPE <>  C.RULETYPE OR (I.RULETYPE is null and C.RULETYPE is not null ) 
OR (I.RULETYPE is not null and C.RULETYPE is null))
		OR 		( I.REQUESTTYPE <>  C.REQUESTTYPE OR (I.REQUESTTYPE is null and C.REQUESTTYPE is not null ) 
OR (I.REQUESTTYPE is not null and C.REQUESTTYPE is null))
		OR 		( I.DATASOURCETYPE <>  C.DATASOURCETYPE OR (I.DATASOURCETYPE is null and C.DATASOURCETYPE is not null ) 
OR (I.DATASOURCETYPE is not null and C.DATASOURCETYPE is null))
		OR 		( I.DATASOURCENAMENO <>  C.DATASOURCENAMENO OR (I.DATASOURCENAMENO is null and C.DATASOURCENAMENO is not null ) 
OR (I.DATASOURCENAMENO is not null and C.DATASOURCENAMENO is null))
		OR 		( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null ) 
OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
		OR 		( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null ) 
OR (I.STATUSCODE is not null and C.STATUSCODE is null))
		OR 		( I.PROFILEID <>  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is not null ) 
OR (I.PROFILEID is not null and C.PROFILEID is null))
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
		Insert into CRITERIA(
			CRITERIANO,
			PURPOSECODE,
			CASETYPE,
			ACTION,
			CHECKLISTTYPE,
			PROGRAMID,
			PROPERTYTYPE,
			PROPERTYUNKNOWN,
			COUNTRYCODE,
			COUNTRYUNKNOWN,
			CASECATEGORY,
			CATEGORYUNKNOWN,
			SUBTYPE,
			SUBTYPEUNKNOWN,
			BASIS,
			REGISTEREDUSERS,
			LOCALCLIENTFLAG,
			TABLECODE,
			RATENO,
			DATEOFACT,
			USERDEFINEDRULE,
			RULEINUSE,
			STARTDETAILENTRY,
			PARENTCRITERIA,
			BELONGSTOGROUP,
			DESCRIPTION,
			TYPEOFMARK,
			RENEWALTYPE,
			CASEOFFICEID,
			LINKTITLE,
			LINKDESCRIPTION,
			DOCITEMID,
			URL,
			ISPUBLIC,
			GROUPID,
			PRODUCTCODE,
			NEWCASETYPE,
			NEWCOUNTRYCODE,
			NEWPROPERTYTYPE,
			NEWCASECATEGORY,
			NEWSUBTYPE,
			PROFILENAME,
			SYSTEMID,
			DATAEXTRACTID,
			RULETYPE,
			REQUESTTYPE,
			DATASOURCETYPE,
			DATASOURCENAMENO,
			RENEWALSTATUS,
			STATUSCODE,
			PROFILEID)
		select
	 I.CRITERIANO,
	 I.PURPOSECODE,
	 I.CASETYPE,
	 I.ACTION,
	 I.CHECKLISTTYPE,
	 I.PROGRAMID,
	 I.PROPERTYTYPE,
	 I.PROPERTYUNKNOWN,
	 I.COUNTRYCODE,
	 I.COUNTRYUNKNOWN,
	 I.CASECATEGORY,
	 I.CATEGORYUNKNOWN,
	 I.SUBTYPE,
	 I.SUBTYPEUNKNOWN,
	 I.BASIS,
	 I.REGISTEREDUSERS,
	 I.LOCALCLIENTFLAG,
	 I.TABLECODE,
	 I.RATENO,
	 I.DATEOFACT,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	 I.STARTDETAILENTRY,
	 I.PARENTCRITERIA,
	 I.BELONGSTOGROUP,
	replace( I.DESCRIPTION,char(10),char(13)+char(10)),
	 I.TYPEOFMARK,
	 I.RENEWALTYPE,
	 I.CASEOFFICEID,
	 I.LINKTITLE,
	replace( I.LINKDESCRIPTION,char(10),char(13)+char(10)),
	 I.DOCITEMID,
	replace( I.URL,char(10),char(13)+char(10)),
	 I.ISPUBLIC,
	 I.GROUPID,
	 I.PRODUCTCODE,
	 I.NEWCASETYPE,
	 I.NEWCOUNTRYCODE,
	 I.NEWPROPERTYTYPE,
	 I.NEWCASECATEGORY,
	 I.NEWSUBTYPE,
	 I.PROFILENAME,
	 I.SYSTEMID,
	 I.DATAEXTRACTID,
	 I.RULETYPE,
	 I.REQUESTTYPE,
	 I.DATASOURCETYPE,
	 I.DATASOURCENAMENO,
	 I.RENEWALSTATUS,
	 I.STATUSCODE,
	 I.PROFILEID
		from CCImport_CRITERIA I
		left join CRITERIA C	on ( C.CRITERIANO=I.CRITERIANO)
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
		Delete CRITERIA
		from CCImport_CRITERIA I
		right join CRITERIA C	on ( C.CRITERIANO=I.CRITERIANO)
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
grant execute on dbo.ip_cc_CRITERIA  to public
go
