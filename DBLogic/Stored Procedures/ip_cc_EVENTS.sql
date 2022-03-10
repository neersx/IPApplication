-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_EVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_EVENTS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_EVENTS.'
	drop procedure dbo.ip_cc_EVENTS
	print '**** Creating procedure dbo.ip_cc_EVENTS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_EVENTS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_EVENTS
-- VERSION :	3
-- DESCRIPTION:	The comparison/display and merging of imported data for the EVENTS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 11 Jun 2013	MF	S21404	2	New column SUPPRESSCALCULATION to be delivered.
-- 04 Oct 2016	MF	64418	3	New columns NOTEGROUP and NOTESSHAREDACROSSCYCLES
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


-- Prerequisite that the CCImport_EVENTS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_EVENTS('"+@psUserName+"')
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
		Update EVENTS
		set	EVENTCODE= I.EVENTCODE,
			EVENTDESCRIPTION= I.EVENTDESCRIPTION,
			NUMCYCLESALLOWED= I.NUMCYCLESALLOWED,
			IMPORTANCELEVEL= I.IMPORTANCELEVEL,
			CONTROLLINGACTION= I.CONTROLLINGACTION,
			DEFINITION=replace( I.DEFINITION,char(10),char(13)+char(10)),
			CLIENTIMPLEVEL= I.CLIENTIMPLEVEL,
			CATEGORYID= I.CATEGORYID,
			PROFILEREFNO= I.PROFILEREFNO,
			RECALCEVENTDATE= I.RECALCEVENTDATE,
			DRAFTEVENTNO= I.DRAFTEVENTNO,
			EVENTGROUP= I.EVENTGROUP,
			ACCOUNTINGEVENTFLAG= I.ACCOUNTINGEVENTFLAG,
			POLICINGIMMEDIATE= I.POLICINGIMMEDIATE,
			SUPPRESSCALCULATION= I.SUPPRESSCALCULATION,
			NOTEGROUP          = I.NOTEGROUP,
			NOTESSHAREDACROSSCYCLES= I.NOTESSHAREDACROSSCYCLES
		from	EVENTS C
		join	CCImport_EVENTS I	on ( I.EVENTNO=C.EVENTNO)
" Set @sSQLString1="
		where 		( I.EVENTCODE <>  C.EVENTCODE OR (I.EVENTCODE is null and C.EVENTCODE is not null )
 OR (I.EVENTCODE is not null and C.EVENTCODE is null))
		OR 		( I.EVENTDESCRIPTION <>  C.EVENTDESCRIPTION OR (I.EVENTDESCRIPTION is null and C.EVENTDESCRIPTION is not null )
 OR (I.EVENTDESCRIPTION is not null and C.EVENTDESCRIPTION is null))
		OR 		( I.NUMCYCLESALLOWED <>  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null )
 OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null))
		OR 		( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null )
 OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
		OR 		( I.CONTROLLINGACTION <>  C.CONTROLLINGACTION OR (I.CONTROLLINGACTION is null and C.CONTROLLINGACTION is not null )
 OR (I.CONTROLLINGACTION is not null and C.CONTROLLINGACTION is null))
		OR 		(replace( I.DEFINITION,char(10),char(13)+char(10)) <>  C.DEFINITION OR (I.DEFINITION is null and C.DEFINITION is not null )
 OR (I.DEFINITION is not null and C.DEFINITION is null))
		OR 		( I.CLIENTIMPLEVEL <>  C.CLIENTIMPLEVEL OR (I.CLIENTIMPLEVEL is null and C.CLIENTIMPLEVEL is not null )
 OR (I.CLIENTIMPLEVEL is not null and C.CLIENTIMPLEVEL is null))
		OR 		( I.CATEGORYID <>  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is not null )
 OR (I.CATEGORYID is not null and C.CATEGORYID is null))
		OR 		( I.PROFILEREFNO <>  C.PROFILEREFNO OR (I.PROFILEREFNO is null and C.PROFILEREFNO is not null )
 OR (I.PROFILEREFNO is not null and C.PROFILEREFNO is null))
		OR 		( I.RECALCEVENTDATE <>  C.RECALCEVENTDATE OR (I.RECALCEVENTDATE is null and C.RECALCEVENTDATE is not null )
 OR (I.RECALCEVENTDATE is not null and C.RECALCEVENTDATE is null))
		OR 		( I.DRAFTEVENTNO <>  C.DRAFTEVENTNO OR (I.DRAFTEVENTNO is null and C.DRAFTEVENTNO is not null )
 OR (I.DRAFTEVENTNO is not null and C.DRAFTEVENTNO is null))
		OR 		( I.EVENTGROUP <>  C.EVENTGROUP OR (I.EVENTGROUP is null and C.EVENTGROUP is not null )
 OR (I.EVENTGROUP is not null and C.EVENTGROUP is null))
		OR 		( I.ACCOUNTINGEVENTFLAG <>  C.ACCOUNTINGEVENTFLAG OR (I.ACCOUNTINGEVENTFLAG is null and C.ACCOUNTINGEVENTFLAG is not null )
 OR (I.ACCOUNTINGEVENTFLAG is not null and C.ACCOUNTINGEVENTFLAG is null))
		OR 		( I.POLICINGIMMEDIATE <>  C.POLICINGIMMEDIATE)
		OR 		( I.SUPPRESSCALCULATION <>  C.SUPPRESSCALCULATION OR (I.SUPPRESSCALCULATION is null and C.SUPPRESSCALCULATION is not null )
 OR (I.SUPPRESSCALCULATION is not null and C.SUPPRESSCALCULATION is null))
		OR 		( I.NOTEGROUP <>  C.NOTEGROUP OR (I.NOTEGROUP is null and C.NOTEGROUP is not null )
 OR (I.NOTEGROUP is not null and C.NOTEGROUP is null))
		OR 		( I.NOTESSHAREDACROSSCYCLES <>  C.NOTESSHAREDACROSSCYCLES OR (I.NOTESSHAREDACROSSCYCLES is null and C.NOTESSHAREDACROSSCYCLES is not null )
 OR (I.NOTESSHAREDACROSSCYCLES is not null and C.NOTESSHAREDACROSSCYCLES is null))
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
		Insert into EVENTS(
			EVENTNO,
			EVENTCODE,
			EVENTDESCRIPTION,
			NUMCYCLESALLOWED,
			IMPORTANCELEVEL,
			CONTROLLINGACTION,
			DEFINITION,
			CLIENTIMPLEVEL,
			CATEGORYID,
			PROFILEREFNO,
			RECALCEVENTDATE,
			DRAFTEVENTNO,
			EVENTGROUP,
			ACCOUNTINGEVENTFLAG,
			POLICINGIMMEDIATE,
			SUPPRESSCALCULATION,
			NOTEGROUP,
			NOTESSHAREDACROSSCYCLES)
		select
			 I.EVENTNO,
			 I.EVENTCODE,
			 I.EVENTDESCRIPTION,
			 I.NUMCYCLESALLOWED,
			 I.IMPORTANCELEVEL,
			 I.CONTROLLINGACTION,
			replace( I.DEFINITION,char(10),char(13)+char(10)),
			 I.CLIENTIMPLEVEL,
			 I.CATEGORYID,
			 I.PROFILEREFNO,
			 I.RECALCEVENTDATE,
			 I.DRAFTEVENTNO,
			 I.EVENTGROUP,
			 I.ACCOUNTINGEVENTFLAG,
			 I.POLICINGIMMEDIATE,
			 I.SUPPRESSCALCULATION,
			 I.NOTEGROUP,
			 I.NOTESSHAREDACROSSCYCLES
		from CCImport_EVENTS I
		left join EVENTS C	on ( C.EVENTNO=I.EVENTNO)
		where C.EVENTNO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete EVENTS
		from CCImport_EVENTS I
		right join EVENTS C	on ( C.EVENTNO=I.EVENTNO)
		where I.EVENTNO is null"

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
grant execute on dbo.ip_cc_EVENTS  to public
go
