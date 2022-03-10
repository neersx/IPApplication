-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_LETTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_LETTER]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_LETTER.'
	drop procedure dbo.ip_cc_LETTER
	print '**** Creating procedure dbo.ip_cc_LETTER...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_LETTER
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_LETTER
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the LETTER table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 03 Apr 2017	MF	71020	2	New columns added.
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


-- Prerequisite that the CCImport_LETTER table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_LETTER('"+@psUserName+"')
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
		Update LETTER
		set	LETTERNAME=replace( I.LETTERNAME,char(10),char(13)+char(10)),
			DOCUMENTCODE= I.DOCUMENTCODE,
			CORRESPONDTYPE= I.CORRESPONDTYPE,
			COPIESALLOWEDFLAG= I.COPIESALLOWEDFLAG,
			COVERINGLETTER= I.COVERINGLETTER,
			EXTRACOPIES= I.EXTRACOPIES,
			MULTICASEFLAG= I.MULTICASEFLAG,
			MACRO=replace( I.MACRO,char(10),char(13)+char(10)),
			SINGLECASELETTERNO= I.SINGLECASELETTERNO,
			INSTRUCTIONTYPE= I.INSTRUCTIONTYPE,
			ENVELOPE= I.ENVELOPE,
			COUNTRYCODE= I.COUNTRYCODE,
			DELIVERYID= I.DELIVERYID,
			PROPERTYTYPE= I.PROPERTYTYPE,
			HOLDFLAG= I.HOLDFLAG,
			NOTES=replace( I.NOTES,char(10),char(13)+char(10)),
			DOCUMENTTYPE= I.DOCUMENTTYPE,
			USEDBY= I.USEDBY,
			FORPRIMECASESONLY= I.FORPRIMECASESONLY,
			GENERATEASANSI= I.GENERATEASANSI,
			ADDATTACHMENTFLAG= I.ADDATTACHMENTFLAG,
			ACTIVITYTYPE= I.ACTIVITYTYPE,
			ACTIVITYCATEGORY= I.ACTIVITYCATEGORY,
			ENTRYPOINTTYPE= I.ENTRYPOINTTYPE,
			SOURCEFILE=replace( I.SOURCEFILE,char(10),char(13)+char(10)),
			EXTERNALUSAGE= I.EXTERNALUSAGE,
			DELIVERLETTER= I.DELIVERLETTER,
			DOCITEMMAILBOX= I.DOCITEMMAILBOX,
			DOCITEMSUBJECT= I.DOCITEMSUBJECT,
			DOCITEMBODY= I.DOCITEMBODY,
			PROTECTEDFLAG= I.PROTECTEDFLAG
		from	LETTER C
		join	CCImport_LETTER I	on ( I.LETTERNO=C.LETTERNO)
" Set @sSQLString1="
		where 		(replace( I.LETTERNAME,char(10),char(13)+char(10)) <>  C.LETTERNAME OR (I.LETTERNAME is null and C.LETTERNAME is not null )
 OR (I.LETTERNAME is not null and C.LETTERNAME is null))
		OR 		( I.DOCUMENTCODE <>  C.DOCUMENTCODE OR (I.DOCUMENTCODE is null and C.DOCUMENTCODE is not null )
 OR (I.DOCUMENTCODE is not null and C.DOCUMENTCODE is null))
		OR 		( I.CORRESPONDTYPE <>  C.CORRESPONDTYPE OR (I.CORRESPONDTYPE is null and C.CORRESPONDTYPE is not null )
 OR (I.CORRESPONDTYPE is not null and C.CORRESPONDTYPE is null))
		OR 		( I.COPIESALLOWEDFLAG <>  C.COPIESALLOWEDFLAG OR (I.COPIESALLOWEDFLAG is null and C.COPIESALLOWEDFLAG is not null )
 OR (I.COPIESALLOWEDFLAG is not null and C.COPIESALLOWEDFLAG is null))
		OR 		( I.COVERINGLETTER <>  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is not null )
 OR (I.COVERINGLETTER is not null and C.COVERINGLETTER is null))
		OR 		( I.EXTRACOPIES <>  C.EXTRACOPIES OR (I.EXTRACOPIES is null and C.EXTRACOPIES is not null )
 OR (I.EXTRACOPIES is not null and C.EXTRACOPIES is null))
		OR 		( I.MULTICASEFLAG <>  C.MULTICASEFLAG OR (I.MULTICASEFLAG is null and C.MULTICASEFLAG is not null )
 OR (I.MULTICASEFLAG is not null and C.MULTICASEFLAG is null))
		OR 		(replace( I.MACRO,char(10),char(13)+char(10)) <>  C.MACRO OR (I.MACRO is null and C.MACRO is not null )
 OR (I.MACRO is not null and C.MACRO is null))
		OR 		( I.SINGLECASELETTERNO <>  C.SINGLECASELETTERNO OR (I.SINGLECASELETTERNO is null and C.SINGLECASELETTERNO is not null )
 OR (I.SINGLECASELETTERNO is not null and C.SINGLECASELETTERNO is null))
		OR 		( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null )
 OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
		OR 		( I.ENVELOPE <>  C.ENVELOPE OR (I.ENVELOPE is null and C.ENVELOPE is not null )
 OR (I.ENVELOPE is not null and C.ENVELOPE is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.DELIVERYID <>  C.DELIVERYID OR (I.DELIVERYID is null and C.DELIVERYID is not null )
 OR (I.DELIVERYID is not null and C.DELIVERYID is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.HOLDFLAG <>  C.HOLDFLAG OR (I.HOLDFLAG is null and C.HOLDFLAG is not null )
 OR (I.HOLDFLAG is not null and C.HOLDFLAG is null))
		OR 		(replace( I.NOTES,char(10),char(13)+char(10)) <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null )
 OR (I.NOTES is not null and C.NOTES is null))
		OR 		( I.DOCUMENTTYPE <>  C.DOCUMENTTYPE)
" Set @sSQLString2="
		OR 		( I.USEDBY <>  C.USEDBY)
		OR 		( I.FORPRIMECASESONLY <>  C.FORPRIMECASESONLY)
		OR 		( I.GENERATEASANSI <>  C.GENERATEASANSI OR (I.GENERATEASANSI is null and C.GENERATEASANSI is not null) 
OR (I.GENERATEASANSI is not null and C.GENERATEASANSI is null))
		OR 		( I.ADDATTACHMENTFLAG <>  C.ADDATTACHMENTFLAG OR (I.ADDATTACHMENTFLAG is null and C.ADDATTACHMENTFLAG is not null) 
OR (I.ADDATTACHMENTFLAG is not null and C.ADDATTACHMENTFLAG is null))
		OR 		( I.ACTIVITYTYPE <>  C.ACTIVITYTYPE OR (I.ACTIVITYTYPE is null and C.ACTIVITYTYPE is not null) 
OR (I.ACTIVITYTYPE is not null and C.ACTIVITYTYPE is null))
		OR 		( I.ACTIVITYCATEGORY <>  C.ACTIVITYCATEGORY OR (I.ACTIVITYCATEGORY is null and C.ACTIVITYCATEGORY is not null) 
OR (I.ACTIVITYCATEGORY is not null and C.ACTIVITYCATEGORY is null))
		OR 		( I.ENTRYPOINTTYPE <>  C.ENTRYPOINTTYPE OR (I.ENTRYPOINTTYPE is null and C.ENTRYPOINTTYPE is not null) 
OR (I.ENTRYPOINTTYPE is not null and C.ENTRYPOINTTYPE is null))
		OR 		(replace( I.SOURCEFILE,char(10),char(13)+char(10)) <>  C.SOURCEFILE OR (I.SOURCEFILE is null and C.SOURCEFILE is not null) 
OR (I.SOURCEFILE is not null and C.SOURCEFILE is null))
		OR 		( I.EXTERNALUSAGE <>  C.EXTERNALUSAGE)
		OR 		( I.DELIVERLETTER <>  C.DELIVERLETTER OR (I.DELIVERLETTER is null and C.DELIVERLETTER is not null) 
OR (I.DELIVERLETTER is not null and C.DELIVERLETTER is null))
		OR 		( I.DOCITEMMAILBOX <>  C.DOCITEMMAILBOX OR (I.DOCITEMMAILBOX is null and C.DOCITEMMAILBOX is not null) 
OR (I.DOCITEMMAILBOX is not null and C.DOCITEMMAILBOX is null))
		OR 		( I.DOCITEMSUBJECT <>  C.DOCITEMSUBJECT OR (I.DOCITEMSUBJECT is null and C.DOCITEMSUBJECT is not null) 
OR (I.DOCITEMSUBJECT is not null and C.DOCITEMSUBJECT is null))
		OR 		( I.DOCITEMBODY <>  C.DOCITEMBODY OR (I.DOCITEMBODY is null and C.DOCITEMBODY is not null) 
OR (I.DOCITEMBODY is not null and C.DOCITEMBODY is null))
		OR 		( I.PROTECTEDFLAG <>  C.PROTECTEDFLAG OR (I.PROTECTEDFLAG is null and C.PROTECTEDFLAG is not null) 
OR (I.PROTECTEDFLAG is not null and C.PROTECTEDFLAG is null))
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
		Insert into LETTER(
			LETTERNO,
			LETTERNAME,
			DOCUMENTCODE,
			CORRESPONDTYPE,
			COPIESALLOWEDFLAG,
			COVERINGLETTER,
			EXTRACOPIES,
			MULTICASEFLAG,
			MACRO,
			SINGLECASELETTERNO,
			INSTRUCTIONTYPE,
			ENVELOPE,
			COUNTRYCODE,
			DELIVERYID,
			PROPERTYTYPE,
			HOLDFLAG,
			NOTES,
			DOCUMENTTYPE,
			USEDBY,
			FORPRIMECASESONLY,
			GENERATEASANSI,
			ADDATTACHMENTFLAG,
			ACTIVITYTYPE,
			ACTIVITYCATEGORY,
			ENTRYPOINTTYPE,
			SOURCEFILE,
			EXTERNALUSAGE,
			DELIVERLETTER,
			DOCITEMMAILBOX,
			DOCITEMSUBJECT,
			DOCITEMBODY,
			PROTECTEDFLAG)
		select
			I.LETTERNO,
			replace( I.LETTERNAME,char(10),char(13)+char(10)),
			I.DOCUMENTCODE,
			I.CORRESPONDTYPE,
			I.COPIESALLOWEDFLAG,
			I.COVERINGLETTER,
			I.EXTRACOPIES,
			I.MULTICASEFLAG,
			replace( I.MACRO,char(10),char(13)+char(10)),
			I.SINGLECASELETTERNO,
			I.INSTRUCTIONTYPE,
			I.ENVELOPE,
			I.COUNTRYCODE,
			I.DELIVERYID,
			I.PROPERTYTYPE,
			I.HOLDFLAG,
			replace( I.NOTES,char(10),char(13)+char(10)),
			I.DOCUMENTTYPE,
			I.USEDBY,
			I.FORPRIMECASESONLY,
			I.GENERATEASANSI,
			I.ADDATTACHMENTFLAG,
			I.ACTIVITYTYPE,
			I.ACTIVITYCATEGORY,
			I.ENTRYPOINTTYPE,
			replace( I.SOURCEFILE,char(10),char(13)+char(10)),
			I.EXTERNALUSAGE,
			I.DELIVERLETTER,
			I.DOCITEMMAILBOX,
			I.DOCITEMSUBJECT,
			I.DOCITEMBODY,
			I.PROTECTEDFLAG
		from CCImport_LETTER I
		left join LETTER C	on ( C.LETTERNO=I.LETTERNO)
		where C.LETTERNO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete LETTER
		from CCImport_LETTER I
		right join LETTER C	on ( C.LETTERNO=I.LETTERNO)
		where I.LETTERNO is null"

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
grant execute on dbo.ip_cc_LETTER  to public
go
