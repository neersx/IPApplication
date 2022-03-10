-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_REMINDERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_REMINDERS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_REMINDERS.'
	drop procedure dbo.ip_cc_REMINDERS
	print '**** Creating procedure dbo.ip_cc_REMINDERS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_REMINDERS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_REMINDERS
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the REMINDERS table
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


-- Prerequisite that the CCImport_REMINDERS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_REMINDERS('"+@psUserName+"')
		order by "+CASE WHEN(@pnOrderBy=1)THEN "1,3,4,5" ELSE "3,4,5" END 
		
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
		Update REMINDERS
		set	PERIODTYPE= I.PERIODTYPE,
			LEADTIME= I.LEADTIME,
			FREQUENCY= I.FREQUENCY,
			STOPTIME= I.STOPTIME,
			UPDATEEVENT= I.UPDATEEVENT,
			LETTERNO= I.LETTERNO,
			CHECKOVERRIDE= I.CHECKOVERRIDE,
			MAXLETTERS= I.MAXLETTERS,
			LETTERFEE= I.LETTERFEE,
			PAYFEECODE= I.PAYFEECODE,
			EMPLOYEEFLAG= I.EMPLOYEEFLAG,
			SIGNATORYFLAG= I.SIGNATORYFLAG,
			INSTRUCTORFLAG= I.INSTRUCTORFLAG,
			CRITICALFLAG= I.CRITICALFLAG,
			REMINDEMPLOYEE= I.REMINDEMPLOYEE,
			USEMESSAGE1= I.USEMESSAGE1,
			MESSAGE1= replace(CAST(I.MESSAGE1 as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			MESSAGE2= replace(CAST(I.MESSAGE2 as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			INHERITED= I.INHERITED,
			NAMETYPE= I.NAMETYPE,
			SENDELECTRONICALLY= I.SENDELECTRONICALLY,
			EMAILSUBJECT= I.EMAILSUBJECT,
			ESTIMATEFLAG= I.ESTIMATEFLAG,
			FREQPERIODTYPE= I.FREQPERIODTYPE,
			STOPTIMEPERIODTYPE= I.STOPTIMEPERIODTYPE,
			DIRECTPAYFLAG= I.DIRECTPAYFLAG,
			RELATIONSHIP= I.RELATIONSHIP,
			EXTENDEDNAMETYPE= I.EXTENDEDNAMETYPE
		from	REMINDERS C
		join	CCImport_REMINDERS I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.REMINDERNO=C.REMINDERNO)
" Set @sSQLString1="
		where 		( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null )
 OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))
		OR 		( I.LEADTIME <>  C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is not null )
 OR (I.LEADTIME is not null and C.LEADTIME is null))
		OR 		( I.FREQUENCY <>  C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is not null )
 OR (I.FREQUENCY is not null and C.FREQUENCY is null))
		OR 		( I.STOPTIME <>  C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is not null )
 OR (I.STOPTIME is not null and C.STOPTIME is null))
		OR 		( I.UPDATEEVENT <>  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null )
 OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null))
		OR 		( I.LETTERNO <>  C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null )
 OR (I.LETTERNO is not null and C.LETTERNO is null))
		OR 		( I.CHECKOVERRIDE <>  C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is not null )
 OR (I.CHECKOVERRIDE is not null and C.CHECKOVERRIDE is null))
		OR 		( I.MAXLETTERS <>  C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is not null )
 OR (I.MAXLETTERS is not null and C.MAXLETTERS is null))
		OR 		( I.LETTERFEE <>  C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is not null )
 OR (I.LETTERFEE is not null and C.LETTERFEE is null))
		OR 		( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null )
 OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
		OR 		( I.EMPLOYEEFLAG <>  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null )
 OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null))
		OR 		( I.SIGNATORYFLAG <>  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null )
 OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null))
		OR 		( I.INSTRUCTORFLAG <>  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null )
 OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null))
		OR 		( I.CRITICALFLAG <>  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null )
 OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null))
		OR 		( I.REMINDEMPLOYEE <>  C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is not null )
 OR (I.REMINDEMPLOYEE is not null and C.REMINDEMPLOYEE is null))
" Set @sSQLString2="
		OR 		( I.USEMESSAGE1 <>  C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is not null) 
OR (I.USEMESSAGE1 is not null and C.USEMESSAGE1 is null))
		OR 		( replace(CAST(I.MESSAGE1 as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.MESSAGE1 as NVARCHAR(MAX)) OR (I.MESSAGE1 is null and C.MESSAGE1 is not null) 
OR (I.MESSAGE1 is not null and C.MESSAGE1 is null))
		OR 		( replace(CAST(I.MESSAGE2 as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.MESSAGE2 as NVARCHAR(MAX)) OR (I.MESSAGE2 is null and C.MESSAGE2 is not null) 
OR (I.MESSAGE2 is not null and C.MESSAGE2 is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.SENDELECTRONICALLY <>  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) 
OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null))
		OR 		( I.EMAILSUBJECT <>  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) 
OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null))
		OR 		( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
		OR 		( I.FREQPERIODTYPE <>  C.FREQPERIODTYPE OR (I.FREQPERIODTYPE is null and C.FREQPERIODTYPE is not null) 
OR (I.FREQPERIODTYPE is not null and C.FREQPERIODTYPE is null))
		OR 		( I.STOPTIMEPERIODTYPE <>  C.STOPTIMEPERIODTYPE OR (I.STOPTIMEPERIODTYPE is null and C.STOPTIMEPERIODTYPE is not null) 
OR (I.STOPTIMEPERIODTYPE is not null and C.STOPTIMEPERIODTYPE is null))
		OR 		( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null) 
OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
		OR 		( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null) 
OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
		OR 		( I.EXTENDEDNAMETYPE <>  C.EXTENDEDNAMETYPE OR (I.EXTENDEDNAMETYPE is null and C.EXTENDEDNAMETYPE is not null) 
OR (I.EXTENDEDNAMETYPE is not null and C.EXTENDEDNAMETYPE is null))
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
		Insert into REMINDERS(
			CRITERIANO,
			EVENTNO,
			REMINDERNO,
			PERIODTYPE,
			LEADTIME,
			FREQUENCY,
			STOPTIME,
			UPDATEEVENT,
			LETTERNO,
			CHECKOVERRIDE,
			MAXLETTERS,
			LETTERFEE,
			PAYFEECODE,
			EMPLOYEEFLAG,
			SIGNATORYFLAG,
			INSTRUCTORFLAG,
			CRITICALFLAG,
			REMINDEMPLOYEE,
			USEMESSAGE1,
			MESSAGE1,
			MESSAGE2,
			INHERITED,
			NAMETYPE,
			SENDELECTRONICALLY,
			EMAILSUBJECT,
			ESTIMATEFLAG,
			FREQPERIODTYPE,
			STOPTIMEPERIODTYPE,
			DIRECTPAYFLAG,
			RELATIONSHIP,
			EXTENDEDNAMETYPE)
		select
			 I.CRITERIANO,
			 I.EVENTNO,
			 I.REMINDERNO,
			 I.PERIODTYPE,
			 I.LEADTIME,
			 I.FREQUENCY,
			 I.STOPTIME,
			 I.UPDATEEVENT,
			 I.LETTERNO,
			 I.CHECKOVERRIDE,
			 I.MAXLETTERS,
			 I.LETTERFEE,
			 I.PAYFEECODE,
			 I.EMPLOYEEFLAG,
			 I.SIGNATORYFLAG,
			 I.INSTRUCTORFLAG,
			 I.CRITICALFLAG,
			 I.REMINDEMPLOYEE,
			 I.USEMESSAGE1,
			 replace(CAST(I.MESSAGE1 as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			 replace(CAST(I.MESSAGE2 as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			 I.INHERITED,
			 I.NAMETYPE,
			 I.SENDELECTRONICALLY,
			 I.EMAILSUBJECT,
			 I.ESTIMATEFLAG,
			 I.FREQPERIODTYPE,
			 I.STOPTIMEPERIODTYPE,
			 I.DIRECTPAYFLAG,
			 I.RELATIONSHIP,
			 I.EXTENDEDNAMETYPE
		from CCImport_REMINDERS I
		left join REMINDERS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.REMINDERNO=I.REMINDERNO)
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
		Delete REMINDERS
		from CCImport_REMINDERS I
		right join REMINDERS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.REMINDERNO=I.REMINDERNO)
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
grant execute on dbo.ip_cc_REMINDERS  to public
go
