-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_DUEDATECALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_DUEDATECALC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_DUEDATECALC.'
	drop procedure dbo.ip_cc_DUEDATECALC
	print '**** Creating procedure dbo.ip_cc_DUEDATECALC...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_DUEDATECALC
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_DUEDATECALC
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the DUEDATECALC table
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


-- Prerequisite that the CCImport_DUEDATECALC table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_DUEDATECALC('"+@psUserName+"')
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
		Update DUEDATECALC
		set	CYCLENUMBER= I.CYCLENUMBER,
			COUNTRYCODE= I.COUNTRYCODE,
			FROMEVENT= I.FROMEVENT,
			RELATIVECYCLE= I.RELATIVECYCLE,
			OPERATOR= I.OPERATOR,
			DEADLINEPERIOD= I.DEADLINEPERIOD,
			PERIODTYPE= I.PERIODTYPE,
			EVENTDATEFLAG= I.EVENTDATEFLAG,
			ADJUSTMENT= I.ADJUSTMENT,
			MUSTEXIST= I.MUSTEXIST,
			COMPARISON= I.COMPARISON,
			COMPAREEVENT= I.COMPAREEVENT,
			WORKDAY= I.WORKDAY,
			MESSAGE2FLAG= I.MESSAGE2FLAG,
			SUPPRESSREMINDERS= I.SUPPRESSREMINDERS,
			OVERRIDELETTER= I.OVERRIDELETTER,
			INHERITED= I.INHERITED,
			COMPAREEVENTFLAG= I.COMPAREEVENTFLAG,
			COMPARECYCLE= I.COMPARECYCLE,
			COMPARERELATIONSHIP= I.COMPARERELATIONSHIP,
			COMPAREDATE= I.COMPAREDATE,
			COMPARESYSTEMDATE= I.COMPARESYSTEMDATE
		from	DUEDATECALC C
		join	CCImport_DUEDATECALC I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.SEQUENCE=C.SEQUENCE)
" Set @sSQLString1="
		where 		( I.CYCLENUMBER <>  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is not null )
 OR (I.CYCLENUMBER is not null and C.CYCLENUMBER is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.FROMEVENT <>  C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null )
 OR (I.FROMEVENT is not null and C.FROMEVENT is null))
		OR 		( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null )
 OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
		OR 		( I.OPERATOR <>  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null )
 OR (I.OPERATOR is not null and C.OPERATOR is null))
		OR 		( I.DEADLINEPERIOD <>  C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is not null )
 OR (I.DEADLINEPERIOD is not null and C.DEADLINEPERIOD is null))
		OR 		( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null )
 OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))
		OR 		( I.EVENTDATEFLAG <>  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null )
 OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null))
		OR 		( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null )
 OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
		OR 		( I.MUSTEXIST <>  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null )
 OR (I.MUSTEXIST is not null and C.MUSTEXIST is null))
		OR 		( I.COMPARISON <>  C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is not null )
 OR (I.COMPARISON is not null and C.COMPARISON is null))
		OR 		( I.COMPAREEVENT <>  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null )
 OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null))
		OR 		( I.WORKDAY <>  C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is not null )
 OR (I.WORKDAY is not null and C.WORKDAY is null))
		OR 		( I.MESSAGE2FLAG <>  C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is not null )
 OR (I.MESSAGE2FLAG is not null and C.MESSAGE2FLAG is null))
		OR 		( I.SUPPRESSREMINDERS <>  C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is not null )
 OR (I.SUPPRESSREMINDERS is not null and C.SUPPRESSREMINDERS is null))
" Set @sSQLString2="
		OR 		( I.OVERRIDELETTER <>  C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is not null) 
OR (I.OVERRIDELETTER is not null and C.OVERRIDELETTER is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.COMPAREEVENTFLAG <>  C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is not null) 
OR (I.COMPAREEVENTFLAG is not null and C.COMPAREEVENTFLAG is null))
		OR 		( I.COMPARECYCLE <>  C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is not null) 
OR (I.COMPARECYCLE is not null and C.COMPARECYCLE is null))
		OR 		( I.COMPARERELATIONSHIP <>  C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is not null) 
OR (I.COMPARERELATIONSHIP is not null and C.COMPARERELATIONSHIP is null))
		OR 		( I.COMPAREDATE <>  C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is not null) 
OR (I.COMPAREDATE is not null and C.COMPAREDATE is null))
		OR 		( I.COMPARESYSTEMDATE <>  C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is not null) 
OR (I.COMPARESYSTEMDATE is not null and C.COMPARESYSTEMDATE is null))
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
		Insert into DUEDATECALC(
			CRITERIANO,
			EVENTNO,
			SEQUENCE,
			CYCLENUMBER,
			COUNTRYCODE,
			FROMEVENT,
			RELATIVECYCLE,
			OPERATOR,
			DEADLINEPERIOD,
			PERIODTYPE,
			EVENTDATEFLAG,
			ADJUSTMENT,
			MUSTEXIST,
			COMPARISON,
			COMPAREEVENT,
			WORKDAY,
			MESSAGE2FLAG,
			SUPPRESSREMINDERS,
			OVERRIDELETTER,
			INHERITED,
			COMPAREEVENTFLAG,
			COMPARECYCLE,
			COMPARERELATIONSHIP,
			COMPAREDATE,
			COMPARESYSTEMDATE)
		select
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCE,
	 I.CYCLENUMBER,
	 I.COUNTRYCODE,
	 I.FROMEVENT,
	 I.RELATIVECYCLE,
	 I.OPERATOR,
	 I.DEADLINEPERIOD,
	 I.PERIODTYPE,
	 I.EVENTDATEFLAG,
	 I.ADJUSTMENT,
	 I.MUSTEXIST,
	 I.COMPARISON,
	 I.COMPAREEVENT,
	 I.WORKDAY,
	 I.MESSAGE2FLAG,
	 I.SUPPRESSREMINDERS,
	 I.OVERRIDELETTER,
	 I.INHERITED,
	 I.COMPAREEVENTFLAG,
	 I.COMPARECYCLE,
	 I.COMPARERELATIONSHIP,
	 I.COMPAREDATE,
	 I.COMPARESYSTEMDATE
		from CCImport_DUEDATECALC I
		left join DUEDATECALC C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
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
		Delete DUEDATECALC
		from CCImport_DUEDATECALC I
		right join DUEDATECALC C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.SEQUENCE=I.SEQUENCE)
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
grant execute on dbo.ip_cc_DUEDATECALC  to public
go
