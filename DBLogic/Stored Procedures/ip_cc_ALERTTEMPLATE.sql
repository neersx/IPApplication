-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_ALERTTEMPLATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_ALERTTEMPLATE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_ALERTTEMPLATE.'
	drop procedure dbo.ip_cc_ALERTTEMPLATE
	print '**** Creating procedure dbo.ip_cc_ALERTTEMPLATE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_ALERTTEMPLATE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_ALERTTEMPLATE
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the ALERTTEMPLATE table
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


-- Prerequisite that the CCImport_ALERTTEMPLATE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_ALERTTEMPLATE('"+@psUserName+"')
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
		Update ALERTTEMPLATE
		set	ALERTMESSAGE=replace( I.ALERTMESSAGE,char(10),char(13)+char(10)),
			EMAILSUBJECT= I.EMAILSUBJECT,
			SENDELECTRONICALLY= I.SENDELECTRONICALLY,
			IMPORTANCELEVEL= I.IMPORTANCELEVEL,
			DAYSLEAD= I.DAYSLEAD,
			DAILYFREQUENCY= I.DAILYFREQUENCY,
			MONTHSLEAD= I.MONTHSLEAD,
			MONTHLYFREQUENCY= I.MONTHLYFREQUENCY,
			STOPALERT= I.STOPALERT,
			DELETEALERT= I.DELETEALERT,
			EMPLOYEEFLAG= I.EMPLOYEEFLAG,
			CRITICALFLAG= I.CRITICALFLAG,
			SIGNATORYFLAG= I.SIGNATORYFLAG,
			NAMETYPE= I.NAMETYPE,
			RELATIONSHIP= I.RELATIONSHIP,
			EMPLOYEENO= I.EMPLOYEENO
		from	ALERTTEMPLATE C
		join	CCImport_ALERTTEMPLATE I	on ( I.ALERTTEMPLATECODE=C.ALERTTEMPLATECODE)
" Set @sSQLString1="
		where 		(replace( I.ALERTMESSAGE,char(10),char(13)+char(10)) <>  C.ALERTMESSAGE)
		OR 		( I.EMAILSUBJECT <>  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null )
 OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null))
		OR 		( I.SENDELECTRONICALLY <>  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null )
 OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null))
		OR 		( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null )
 OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
		OR 		( I.DAYSLEAD <>  C.DAYSLEAD OR (I.DAYSLEAD is null and C.DAYSLEAD is not null )
 OR (I.DAYSLEAD is not null and C.DAYSLEAD is null))
		OR 		( I.DAILYFREQUENCY <>  C.DAILYFREQUENCY OR (I.DAILYFREQUENCY is null and C.DAILYFREQUENCY is not null )
 OR (I.DAILYFREQUENCY is not null and C.DAILYFREQUENCY is null))
		OR 		( I.MONTHSLEAD <>  C.MONTHSLEAD OR (I.MONTHSLEAD is null and C.MONTHSLEAD is not null )
 OR (I.MONTHSLEAD is not null and C.MONTHSLEAD is null))
		OR 		( I.MONTHLYFREQUENCY <>  C.MONTHLYFREQUENCY OR (I.MONTHLYFREQUENCY is null and C.MONTHLYFREQUENCY is not null )
 OR (I.MONTHLYFREQUENCY is not null and C.MONTHLYFREQUENCY is null))
		OR 		( I.STOPALERT <>  C.STOPALERT OR (I.STOPALERT is null and C.STOPALERT is not null )
 OR (I.STOPALERT is not null and C.STOPALERT is null))
		OR 		( I.DELETEALERT <>  C.DELETEALERT OR (I.DELETEALERT is null and C.DELETEALERT is not null )
 OR (I.DELETEALERT is not null and C.DELETEALERT is null))
		OR 		( I.EMPLOYEEFLAG <>  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null )
 OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null))
		OR 		( I.CRITICALFLAG <>  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null )
 OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null))
		OR 		( I.SIGNATORYFLAG <>  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null )
 OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null )
 OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null )
 OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
		OR 		( I.EMPLOYEENO <>  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is not null )
 OR (I.EMPLOYEENO is not null and C.EMPLOYEENO is null))
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
		Insert into ALERTTEMPLATE(
			ALERTTEMPLATECODE,
			ALERTMESSAGE,
			EMAILSUBJECT,
			SENDELECTRONICALLY,
			IMPORTANCELEVEL,
			DAYSLEAD,
			DAILYFREQUENCY,
			MONTHSLEAD,
			MONTHLYFREQUENCY,
			STOPALERT,
			DELETEALERT,
			EMPLOYEEFLAG,
			CRITICALFLAG,
			SIGNATORYFLAG,
			NAMETYPE,
			RELATIONSHIP,
			EMPLOYEENO)
		select
	 I.ALERTTEMPLATECODE,
	replace( I.ALERTMESSAGE,char(10),char(13)+char(10)),
	 I.EMAILSUBJECT,
	 I.SENDELECTRONICALLY,
	 I.IMPORTANCELEVEL,
	 I.DAYSLEAD,
	 I.DAILYFREQUENCY,
	 I.MONTHSLEAD,
	 I.MONTHLYFREQUENCY,
	 I.STOPALERT,
	 I.DELETEALERT,
	 I.EMPLOYEEFLAG,
	 I.CRITICALFLAG,
	 I.SIGNATORYFLAG,
	 I.NAMETYPE,
	 I.RELATIONSHIP,
	 I.EMPLOYEENO
		from CCImport_ALERTTEMPLATE I
		left join ALERTTEMPLATE C	on ( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
		where C.ALERTTEMPLATECODE is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete ALERTTEMPLATE
		from CCImport_ALERTTEMPLATE I
		right join ALERTTEMPLATE C	on ( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
		where I.ALERTTEMPLATECODE is null"

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
grant execute on dbo.ip_cc_ALERTTEMPLATE  to public
go
