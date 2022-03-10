-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_FEESCALCULATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_FEESCALCULATION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_FEESCALCULATION.'
	drop procedure dbo.ip_cc_FEESCALCULATION
	print '**** Creating procedure dbo.ip_cc_FEESCALCULATION...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_FEESCALCULATION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_FEESCALCULATION
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the FEESCALCULATION table
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


-- Prerequisite that the CCImport_FEESCALCULATION table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_FEESCALCULATION('"+@psUserName+"')
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
		Update FEESCALCULATION
		set	AGENT= I.AGENT,
			DEBTORTYPE= I.DEBTORTYPE,
			DEBTOR= I.DEBTOR,
			CYCLENUMBER= I.CYCLENUMBER,
			VALIDFROMDATE= I.VALIDFROMDATE,
			DEBITNOTE= I.DEBITNOTE,
			COVERINGLETTER= I.COVERINGLETTER,
			GENERATECHARGES= I.GENERATECHARGES,
			FEETYPE= I.FEETYPE,
			IPOFFICEFEEFLAG= I.IPOFFICEFEEFLAG,
			DISBCURRENCY= I.DISBCURRENCY,
			DISBTAXCODE= I.DISBTAXCODE,
			DISBNARRATIVE= I.DISBNARRATIVE,
			DISBWIPCODE= I.DISBWIPCODE,
			DISBBASEFEE= I.DISBBASEFEE,
			DISBMINFEEFLAG= I.DISBMINFEEFLAG,
			DISBVARIABLEFEE= I.DISBVARIABLEFEE,
			DISBADDPERCENTAGE= I.DISBADDPERCENTAGE,
			DISBUNITSIZE= I.DISBUNITSIZE,
			DISBBASEUNITS= I.DISBBASEUNITS,
			SERVICECURRENCY= I.SERVICECURRENCY,
			SERVTAXCODE= I.SERVTAXCODE,
			SERVICENARRATIVE= I.SERVICENARRATIVE,
			SERVWIPCODE= I.SERVWIPCODE,
			SERVBASEFEE= I.SERVBASEFEE,
			SERVMINFEEFLAG= I.SERVMINFEEFLAG,
			SERVVARIABLEFEE= I.SERVVARIABLEFEE,
			SERVADDPERCENTAGE= I.SERVADDPERCENTAGE,
			SERVDISBPERCENTAGE= I.SERVDISBPERCENTAGE,
			SERVUNITSIZE= I.SERVUNITSIZE,
			SERVBASEUNITS= I.SERVBASEUNITS,
			INHERITED= I.INHERITED,
			PARAMETERSOURCE= I.PARAMETERSOURCE,
			DISBMAXUNITS= I.DISBMAXUNITS,
			SERVMAXUNITS= I.SERVMAXUNITS,
			DISBEMPLOYEENO= I.DISBEMPLOYEENO,
			SERVEMPLOYEENO= I.SERVEMPLOYEENO,
			VARBASEFEE= I.VARBASEFEE,
			VARBASEUNITS= I.VARBASEUNITS,
			VARVARIABLEFEE= I.VARVARIABLEFEE,
			VARUNITSIZE= I.VARUNITSIZE,
			VARMAXUNITS= I.VARMAXUNITS,
			VARMINFEEFLAG= I.VARMINFEEFLAG,
			WRITEUPREASON= I.WRITEUPREASON,
			VARWIPCODE= I.VARWIPCODE,
			VARFEEAPPLIES= I.VARFEEAPPLIES,
			OWNER= I.OWNER,
			INSTRUCTOR= I.INSTRUCTOR,
			PRODUCTCODE= I.PRODUCTCODE,
			PARAMETERSOURCE2= I.PARAMETERSOURCE2,
			FEETYPE2= I.FEETYPE2,
			FROMEVENTNO= I.FROMEVENTNO,
			DISBSTAFFNAMETYPE= I.DISBSTAFFNAMETYPE,
			SERVSTAFFNAMETYPE= I.SERVSTAFFNAMETYPE,
			DISBDISCFEEFLAG= I.DISBDISCFEEFLAG,
			SERVDISCFEEFLAG= I.SERVDISCFEEFLAG
		from	FEESCALCULATION C
		join	CCImport_FEESCALCULATION I	on ( I.CRITERIANO=C.CRITERIANO
						and I.UNIQUEID=C.UNIQUEID)
" Set @sSQLString1="
		where 		( I.AGENT <>  C.AGENT OR (I.AGENT is null and C.AGENT is not null )
 OR (I.AGENT is not null and C.AGENT is null))
		OR 		( I.DEBTORTYPE <>  C.DEBTORTYPE OR (I.DEBTORTYPE is null and C.DEBTORTYPE is not null )
 OR (I.DEBTORTYPE is not null and C.DEBTORTYPE is null))
		OR 		( I.DEBTOR <>  C.DEBTOR OR (I.DEBTOR is null and C.DEBTOR is not null )
 OR (I.DEBTOR is not null and C.DEBTOR is null))
		OR 		( I.CYCLENUMBER <>  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is not null )
 OR (I.CYCLENUMBER is not null and C.CYCLENUMBER is null))
		OR 		( I.VALIDFROMDATE <>  C.VALIDFROMDATE OR (I.VALIDFROMDATE is null and C.VALIDFROMDATE is not null )
 OR (I.VALIDFROMDATE is not null and C.VALIDFROMDATE is null))
		OR 		( I.DEBITNOTE <>  C.DEBITNOTE OR (I.DEBITNOTE is null and C.DEBITNOTE is not null )
 OR (I.DEBITNOTE is not null and C.DEBITNOTE is null))
		OR 		( I.COVERINGLETTER <>  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is not null )
 OR (I.COVERINGLETTER is not null and C.COVERINGLETTER is null))
		OR 		( I.GENERATECHARGES <>  C.GENERATECHARGES OR (I.GENERATECHARGES is null and C.GENERATECHARGES is not null )
 OR (I.GENERATECHARGES is not null and C.GENERATECHARGES is null))
		OR 		( I.FEETYPE <>  C.FEETYPE OR (I.FEETYPE is null and C.FEETYPE is not null )
 OR (I.FEETYPE is not null and C.FEETYPE is null))
		OR 		( I.IPOFFICEFEEFLAG <>  C.IPOFFICEFEEFLAG OR (I.IPOFFICEFEEFLAG is null and C.IPOFFICEFEEFLAG is not null )
 OR (I.IPOFFICEFEEFLAG is not null and C.IPOFFICEFEEFLAG is null))
		OR 		( I.DISBCURRENCY <>  C.DISBCURRENCY OR (I.DISBCURRENCY is null and C.DISBCURRENCY is not null )
 OR (I.DISBCURRENCY is not null and C.DISBCURRENCY is null))
		OR 		( I.DISBTAXCODE <>  C.DISBTAXCODE OR (I.DISBTAXCODE is null and C.DISBTAXCODE is not null )
 OR (I.DISBTAXCODE is not null and C.DISBTAXCODE is null))
		OR 		( I.DISBNARRATIVE <>  C.DISBNARRATIVE OR (I.DISBNARRATIVE is null and C.DISBNARRATIVE is not null )
 OR (I.DISBNARRATIVE is not null and C.DISBNARRATIVE is null))
		OR 		( I.DISBWIPCODE <>  C.DISBWIPCODE OR (I.DISBWIPCODE is null and C.DISBWIPCODE is not null )
 OR (I.DISBWIPCODE is not null and C.DISBWIPCODE is null))
		OR 		( I.DISBBASEFEE <>  C.DISBBASEFEE OR (I.DISBBASEFEE is null and C.DISBBASEFEE is not null )
 OR (I.DISBBASEFEE is not null and C.DISBBASEFEE is null))
		OR 		( I.DISBMINFEEFLAG <>  C.DISBMINFEEFLAG OR (I.DISBMINFEEFLAG is null and C.DISBMINFEEFLAG is not null )
 OR (I.DISBMINFEEFLAG is not null and C.DISBMINFEEFLAG is null))
" Set @sSQLString2="
		OR 		( I.DISBVARIABLEFEE <>  C.DISBVARIABLEFEE OR (I.DISBVARIABLEFEE is null and C.DISBVARIABLEFEE is not null) 
OR (I.DISBVARIABLEFEE is not null and C.DISBVARIABLEFEE is null))
		OR 		( I.DISBADDPERCENTAGE <>  C.DISBADDPERCENTAGE OR (I.DISBADDPERCENTAGE is null and C.DISBADDPERCENTAGE is not null) 
OR (I.DISBADDPERCENTAGE is not null and C.DISBADDPERCENTAGE is null))
		OR 		( I.DISBUNITSIZE <>  C.DISBUNITSIZE OR (I.DISBUNITSIZE is null and C.DISBUNITSIZE is not null) 
OR (I.DISBUNITSIZE is not null and C.DISBUNITSIZE is null))
		OR 		( I.DISBBASEUNITS <>  C.DISBBASEUNITS OR (I.DISBBASEUNITS is null and C.DISBBASEUNITS is not null) 
OR (I.DISBBASEUNITS is not null and C.DISBBASEUNITS is null))
		OR 		( I.SERVICECURRENCY <>  C.SERVICECURRENCY OR (I.SERVICECURRENCY is null and C.SERVICECURRENCY is not null) 
OR (I.SERVICECURRENCY is not null and C.SERVICECURRENCY is null))
		OR 		( I.SERVTAXCODE <>  C.SERVTAXCODE OR (I.SERVTAXCODE is null and C.SERVTAXCODE is not null) 
OR (I.SERVTAXCODE is not null and C.SERVTAXCODE is null))
		OR 		( I.SERVICENARRATIVE <>  C.SERVICENARRATIVE OR (I.SERVICENARRATIVE is null and C.SERVICENARRATIVE is not null) 
OR (I.SERVICENARRATIVE is not null and C.SERVICENARRATIVE is null))
		OR 		( I.SERVWIPCODE <>  C.SERVWIPCODE OR (I.SERVWIPCODE is null and C.SERVWIPCODE is not null) 
OR (I.SERVWIPCODE is not null and C.SERVWIPCODE is null))
		OR 		( I.SERVBASEFEE <>  C.SERVBASEFEE OR (I.SERVBASEFEE is null and C.SERVBASEFEE is not null) 
OR (I.SERVBASEFEE is not null and C.SERVBASEFEE is null))
		OR 		( I.SERVMINFEEFLAG <>  C.SERVMINFEEFLAG OR (I.SERVMINFEEFLAG is null and C.SERVMINFEEFLAG is not null) 
OR (I.SERVMINFEEFLAG is not null and C.SERVMINFEEFLAG is null))
		OR 		( I.SERVVARIABLEFEE <>  C.SERVVARIABLEFEE OR (I.SERVVARIABLEFEE is null and C.SERVVARIABLEFEE is not null) 
OR (I.SERVVARIABLEFEE is not null and C.SERVVARIABLEFEE is null))
		OR 		( I.SERVADDPERCENTAGE <>  C.SERVADDPERCENTAGE OR (I.SERVADDPERCENTAGE is null and C.SERVADDPERCENTAGE is not null) 
OR (I.SERVADDPERCENTAGE is not null and C.SERVADDPERCENTAGE is null))
		OR 		( I.SERVDISBPERCENTAGE <>  C.SERVDISBPERCENTAGE OR (I.SERVDISBPERCENTAGE is null and C.SERVDISBPERCENTAGE is not null) 
OR (I.SERVDISBPERCENTAGE is not null and C.SERVDISBPERCENTAGE is null))
		OR 		( I.SERVUNITSIZE <>  C.SERVUNITSIZE OR (I.SERVUNITSIZE is null and C.SERVUNITSIZE is not null) 
OR (I.SERVUNITSIZE is not null and C.SERVUNITSIZE is null))
		OR 		( I.SERVBASEUNITS <>  C.SERVBASEUNITS OR (I.SERVBASEUNITS is null and C.SERVBASEUNITS is not null) 
OR (I.SERVBASEUNITS is not null and C.SERVBASEUNITS is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.PARAMETERSOURCE <>  C.PARAMETERSOURCE OR (I.PARAMETERSOURCE is null and C.PARAMETERSOURCE is not null) 
OR (I.PARAMETERSOURCE is not null and C.PARAMETERSOURCE is null))
		OR 		( I.DISBMAXUNITS <>  C.DISBMAXUNITS OR (I.DISBMAXUNITS is null and C.DISBMAXUNITS is not null) 
OR (I.DISBMAXUNITS is not null and C.DISBMAXUNITS is null))
" Set @sSQLString3="
		OR 		( I.SERVMAXUNITS <>  C.SERVMAXUNITS OR (I.SERVMAXUNITS is null and C.SERVMAXUNITS is not null ) 
OR (I.SERVMAXUNITS is not null and C.SERVMAXUNITS is null))
		OR 		( I.DISBEMPLOYEENO <>  C.DISBEMPLOYEENO OR (I.DISBEMPLOYEENO is null and C.DISBEMPLOYEENO is not null ) 
OR (I.DISBEMPLOYEENO is not null and C.DISBEMPLOYEENO is null))
		OR 		( I.SERVEMPLOYEENO <>  C.SERVEMPLOYEENO OR (I.SERVEMPLOYEENO is null and C.SERVEMPLOYEENO is not null ) 
OR (I.SERVEMPLOYEENO is not null and C.SERVEMPLOYEENO is null))
		OR 		( I.VARBASEFEE <>  C.VARBASEFEE OR (I.VARBASEFEE is null and C.VARBASEFEE is not null ) 
OR (I.VARBASEFEE is not null and C.VARBASEFEE is null))
		OR 		( I.VARBASEUNITS <>  C.VARBASEUNITS OR (I.VARBASEUNITS is null and C.VARBASEUNITS is not null ) 
OR (I.VARBASEUNITS is not null and C.VARBASEUNITS is null))
		OR 		( I.VARVARIABLEFEE <>  C.VARVARIABLEFEE OR (I.VARVARIABLEFEE is null and C.VARVARIABLEFEE is not null ) 
OR (I.VARVARIABLEFEE is not null and C.VARVARIABLEFEE is null))
		OR 		( I.VARUNITSIZE <>  C.VARUNITSIZE OR (I.VARUNITSIZE is null and C.VARUNITSIZE is not null ) 
OR (I.VARUNITSIZE is not null and C.VARUNITSIZE is null))
		OR 		( I.VARMAXUNITS <>  C.VARMAXUNITS OR (I.VARMAXUNITS is null and C.VARMAXUNITS is not null ) 
OR (I.VARMAXUNITS is not null and C.VARMAXUNITS is null))
		OR 		( I.VARMINFEEFLAG <>  C.VARMINFEEFLAG OR (I.VARMINFEEFLAG is null and C.VARMINFEEFLAG is not null ) 
OR (I.VARMINFEEFLAG is not null and C.VARMINFEEFLAG is null))
		OR 		( I.WRITEUPREASON <>  C.WRITEUPREASON OR (I.WRITEUPREASON is null and C.WRITEUPREASON is not null ) 
OR (I.WRITEUPREASON is not null and C.WRITEUPREASON is null))
		OR 		( I.VARWIPCODE <>  C.VARWIPCODE OR (I.VARWIPCODE is null and C.VARWIPCODE is not null ) 
OR (I.VARWIPCODE is not null and C.VARWIPCODE is null))
		OR 		( I.VARFEEAPPLIES <>  C.VARFEEAPPLIES OR (I.VARFEEAPPLIES is null and C.VARFEEAPPLIES is not null ) 
OR (I.VARFEEAPPLIES is not null and C.VARFEEAPPLIES is null))
		OR 		( I.OWNER <>  C.OWNER OR (I.OWNER is null and C.OWNER is not null ) 
OR (I.OWNER is not null and C.OWNER is null))
		OR 		( I.INSTRUCTOR <>  C.INSTRUCTOR OR (I.INSTRUCTOR is null and C.INSTRUCTOR is not null ) 
OR (I.INSTRUCTOR is not null and C.INSTRUCTOR is null))
		OR 		( I.PRODUCTCODE <>  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is not null ) 
OR (I.PRODUCTCODE is not null and C.PRODUCTCODE is null))
		OR 		( I.PARAMETERSOURCE2 <>  C.PARAMETERSOURCE2 OR (I.PARAMETERSOURCE2 is null and C.PARAMETERSOURCE2 is not null ) 
OR (I.PARAMETERSOURCE2 is not null and C.PARAMETERSOURCE2 is null))
		OR 		( I.FEETYPE2 <>  C.FEETYPE2 OR (I.FEETYPE2 is null and C.FEETYPE2 is not null ) 
OR (I.FEETYPE2 is not null and C.FEETYPE2 is null))
		OR 		( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null ) 
OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
" Set @sSQLString4="
		OR 		( I.DISBSTAFFNAMETYPE <>  C.DISBSTAFFNAMETYPE OR (I.DISBSTAFFNAMETYPE is null and C.DISBSTAFFNAMETYPE is not null )
 OR (I.DISBSTAFFNAMETYPE is not null and C.DISBSTAFFNAMETYPE is null))
		OR 		( I.SERVSTAFFNAMETYPE <>  C.SERVSTAFFNAMETYPE OR (I.SERVSTAFFNAMETYPE is null and C.SERVSTAFFNAMETYPE is not null )
 OR (I.SERVSTAFFNAMETYPE is not null and C.SERVSTAFFNAMETYPE is null))
		OR 		( I.DISBDISCFEEFLAG <>  C.DISBDISCFEEFLAG OR (I.DISBDISCFEEFLAG is null and C.DISBDISCFEEFLAG is not null )
 OR (I.DISBDISCFEEFLAG is not null and C.DISBDISCFEEFLAG is null))
		OR 		( I.SERVDISCFEEFLAG <>  C.SERVDISCFEEFLAG OR (I.SERVDISCFEEFLAG is null and C.SERVDISCFEEFLAG is not null )
 OR (I.SERVDISCFEEFLAG is not null and C.SERVDISCFEEFLAG is null))
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
		Insert into FEESCALCULATION(
			CRITERIANO,
			UNIQUEID,
			AGENT,
			DEBTORTYPE,
			DEBTOR,
			CYCLENUMBER,
			VALIDFROMDATE,
			DEBITNOTE,
			COVERINGLETTER,
			GENERATECHARGES,
			FEETYPE,
			IPOFFICEFEEFLAG,
			DISBCURRENCY,
			DISBTAXCODE,
			DISBNARRATIVE,
			DISBWIPCODE,
			DISBBASEFEE,
			DISBMINFEEFLAG,
			DISBVARIABLEFEE,
			DISBADDPERCENTAGE,
			DISBUNITSIZE,
			DISBBASEUNITS,
			SERVICECURRENCY,
			SERVTAXCODE,
			SERVICENARRATIVE,
			SERVWIPCODE,
			SERVBASEFEE,
			SERVMINFEEFLAG,
			SERVVARIABLEFEE,
			SERVADDPERCENTAGE,
			SERVDISBPERCENTAGE,
			SERVUNITSIZE,
			SERVBASEUNITS,
			INHERITED,
			PARAMETERSOURCE,
			DISBMAXUNITS,
			SERVMAXUNITS,
			DISBEMPLOYEENO,
			SERVEMPLOYEENO,
			VARBASEFEE,
			VARBASEUNITS,
			VARVARIABLEFEE,
			VARUNITSIZE,
			VARMAXUNITS,
			VARMINFEEFLAG,
			WRITEUPREASON,
			VARWIPCODE,
			VARFEEAPPLIES,
			OWNER,
			INSTRUCTOR,
			PRODUCTCODE,
			PARAMETERSOURCE2,
			FEETYPE2,
			FROMEVENTNO,
			DISBSTAFFNAMETYPE,
			SERVSTAFFNAMETYPE,
			DISBDISCFEEFLAG,
			SERVDISCFEEFLAG)
		select
	 I.CRITERIANO,
	 I.UNIQUEID,
	 I.AGENT,
	 I.DEBTORTYPE,
	 I.DEBTOR,
	 I.CYCLENUMBER,
	 I.VALIDFROMDATE,
	 I.DEBITNOTE,
	 I.COVERINGLETTER,
	 I.GENERATECHARGES,
	 I.FEETYPE,
	 I.IPOFFICEFEEFLAG,
	 I.DISBCURRENCY,
	 I.DISBTAXCODE,
	 I.DISBNARRATIVE,
	 I.DISBWIPCODE,
	 I.DISBBASEFEE,
	 I.DISBMINFEEFLAG,
	 I.DISBVARIABLEFEE,
	 I.DISBADDPERCENTAGE,
	 I.DISBUNITSIZE,
	 I.DISBBASEUNITS,
	 I.SERVICECURRENCY,
	 I.SERVTAXCODE,
	 I.SERVICENARRATIVE,
	 I.SERVWIPCODE,
	 I.SERVBASEFEE,
	 I.SERVMINFEEFLAG,
	 I.SERVVARIABLEFEE,
	 I.SERVADDPERCENTAGE,
	 I.SERVDISBPERCENTAGE,
	 I.SERVUNITSIZE,
	 I.SERVBASEUNITS,
	 I.INHERITED,
	 I.PARAMETERSOURCE,
	 I.DISBMAXUNITS,
	 I.SERVMAXUNITS,
	 I.DISBEMPLOYEENO,
	 I.SERVEMPLOYEENO,
	 I.VARBASEFEE,
	 I.VARBASEUNITS,
	 I.VARVARIABLEFEE,
	 I.VARUNITSIZE,
	 I.VARMAXUNITS,
	 I.VARMINFEEFLAG,
	 I.WRITEUPREASON,
	 I.VARWIPCODE,
	 I.VARFEEAPPLIES,
	 I.OWNER,
	 I.INSTRUCTOR,
	 I.PRODUCTCODE,
	 I.PARAMETERSOURCE2,
	 I.FEETYPE2,
	 I.FROMEVENTNO,
	 I.DISBSTAFFNAMETYPE,
	 I.SERVSTAFFNAMETYPE,
	 I.DISBDISCFEEFLAG,
	 I.SERVDISCFEEFLAG
		from CCImport_FEESCALCULATION I
		left join FEESCALCULATION C	on ( C.CRITERIANO=I.CRITERIANO
						and C.UNIQUEID=I.UNIQUEID)
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
		Delete FEESCALCULATION
		from CCImport_FEESCALCULATION I
		right join FEESCALCULATION C	on ( C.CRITERIANO=I.CRITERIANO
						and C.UNIQUEID=I.UNIQUEID)
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
grant execute on dbo.ip_cc_FEESCALCULATION  to public
go
