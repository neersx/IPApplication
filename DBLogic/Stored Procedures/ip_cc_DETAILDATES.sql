-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_DETAILDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_DETAILDATES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_DETAILDATES.'
	drop procedure dbo.ip_cc_DETAILDATES
	print '**** Creating procedure dbo.ip_cc_DETAILDATES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_DETAILDATES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_DETAILDATES
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the DETAILDATES table
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


-- Prerequisite that the CCImport_DETAILDATES table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_DETAILDATES('"+@psUserName+"')
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
		Update DETAILDATES
		set	OTHEREVENTNO= I.OTHEREVENTNO,
			DEFAULTFLAG= I.DEFAULTFLAG,
			EVENTATTRIBUTE= I.EVENTATTRIBUTE,
			DUEATTRIBUTE= I.DUEATTRIBUTE,
			POLICINGATTRIBUTE= I.POLICINGATTRIBUTE,
			PERIODATTRIBUTE= I.PERIODATTRIBUTE,
			OVREVENTATTRIBUTE= I.OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE= I.OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE= I.JOURNALATTRIBUTE,
			DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			INHERITED= I.INHERITED,
			DUEDATERESPATTRIBUTE= I.DUEDATERESPATTRIBUTE
		from	DETAILDATES C
		join	CCImport_DETAILDATES I	on ( I.CRITERIANO=C.CRITERIANO
						and I.ENTRYNUMBER=C.ENTRYNUMBER
						and I.EVENTNO=C.EVENTNO)
" Set @sSQLString1="
		where 		( I.OTHEREVENTNO <>  C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is not null )
 OR (I.OTHEREVENTNO is not null and C.OTHEREVENTNO is null))
		OR 		( I.DEFAULTFLAG <>  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is not null )
 OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null))
		OR 		( I.EVENTATTRIBUTE <>  C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is not null )
 OR (I.EVENTATTRIBUTE is not null and C.EVENTATTRIBUTE is null))
		OR 		( I.DUEATTRIBUTE <>  C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is not null )
 OR (I.DUEATTRIBUTE is not null and C.DUEATTRIBUTE is null))
		OR 		( I.POLICINGATTRIBUTE <>  C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is not null )
 OR (I.POLICINGATTRIBUTE is not null and C.POLICINGATTRIBUTE is null))
		OR 		( I.PERIODATTRIBUTE <>  C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is not null )
 OR (I.PERIODATTRIBUTE is not null and C.PERIODATTRIBUTE is null))
		OR 		( I.OVREVENTATTRIBUTE <>  C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is not null )
 OR (I.OVREVENTATTRIBUTE is not null and C.OVREVENTATTRIBUTE is null))
		OR 		( I.OVRDUEATTRIBUTE <>  C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is not null )
 OR (I.OVRDUEATTRIBUTE is not null and C.OVRDUEATTRIBUTE is null))
		OR 		( I.JOURNALATTRIBUTE <>  C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is not null )
 OR (I.JOURNALATTRIBUTE is not null and C.JOURNALATTRIBUTE is null))
		OR 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null )
 OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null )
 OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.DUEDATERESPATTRIBUTE <>  C.DUEDATERESPATTRIBUTE OR (I.DUEDATERESPATTRIBUTE is null and C.DUEDATERESPATTRIBUTE is not null )
 OR (I.DUEDATERESPATTRIBUTE is not null and C.DUEDATERESPATTRIBUTE is null))
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
		Insert into DETAILDATES(
			CRITERIANO,
			ENTRYNUMBER,
			EVENTNO,
			OTHEREVENTNO,
			DEFAULTFLAG,
			EVENTATTRIBUTE,
			DUEATTRIBUTE,
			POLICINGATTRIBUTE,
			PERIODATTRIBUTE,
			OVREVENTATTRIBUTE,
			OVRDUEATTRIBUTE,
			JOURNALATTRIBUTE,
			DISPLAYSEQUENCE,
			INHERITED,
			DUEDATERESPATTRIBUTE)
		select
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.EVENTNO,
	 I.OTHEREVENTNO,
	 I.DEFAULTFLAG,
	 I.EVENTATTRIBUTE,
	 I.DUEATTRIBUTE,
	 I.POLICINGATTRIBUTE,
	 I.PERIODATTRIBUTE,
	 I.OVREVENTATTRIBUTE,
	 I.OVRDUEATTRIBUTE,
	 I.JOURNALATTRIBUTE,
	 I.DISPLAYSEQUENCE,
	 I.INHERITED,
	 I.DUEDATERESPATTRIBUTE
		from CCImport_DETAILDATES I
		left join DETAILDATES C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER
						and C.EVENTNO=I.EVENTNO)
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
		Delete DETAILDATES
		from CCImport_DETAILDATES I
		right join DETAILDATES C	on ( C.CRITERIANO=I.CRITERIANO
						and C.ENTRYNUMBER=I.ENTRYNUMBER
						and C.EVENTNO=I.EVENTNO)
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
grant execute on dbo.ip_cc_DETAILDATES  to public
go
