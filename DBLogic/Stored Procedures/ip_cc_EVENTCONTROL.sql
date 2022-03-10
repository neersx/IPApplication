-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_EVENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_EVENTCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_EVENTCONTROL.'
	drop procedure dbo.ip_cc_EVENTCONTROL
	print '**** Creating procedure dbo.ip_cc_EVENTCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_EVENTCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_EVENTCONTROL
-- VERSION :	3
-- DESCRIPTION:	The comparison/display and merging of imported data for the EVENTCONTROL table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 11 Jun 2013	MF	S21404	2	New column SUPPRESSCALCULATION to be delivered.
-- 01 May 2017	MF	71205	3	Add new column RENEWALSTATUS
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


-- Prerequisite that the CCImport_EVENTCONTROL table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_EVENTCONTROL('"+@psUserName+"')
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
		Update EVENTCONTROL
		set	EVENTDESCRIPTION= I.EVENTDESCRIPTION,
			DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			PARENTCRITERIANO= I.PARENTCRITERIANO,
			PARENTEVENTNO= I.PARENTEVENTNO,
			NUMCYCLESALLOWED= I.NUMCYCLESALLOWED,
			IMPORTANCELEVEL= I.IMPORTANCELEVEL,
			WHICHDUEDATE= I.WHICHDUEDATE,
			COMPAREBOOLEAN= I.COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG= I.CHECKCOUNTRYFLAG,
			SAVEDUEDATE= I.SAVEDUEDATE,
			STATUSCODE= I.STATUSCODE,
			SPECIALFUNCTION= I.SPECIALFUNCTION,
			INITIALFEE= I.INITIALFEE,
			PAYFEECODE= I.PAYFEECODE,
			CREATEACTION= I.CREATEACTION,
			STATUSDESC= I.STATUSDESC,
			CLOSEACTION= I.CLOSEACTION,
			UPDATEFROMEVENT= I.UPDATEFROMEVENT,
			FROMRELATIONSHIP= I.FROMRELATIONSHIP,
			FROMANCESTOR= I.FROMANCESTOR,
			UPDATEMANUALLY= I.UPDATEMANUALLY,
			ADJUSTMENT= I.ADJUSTMENT,
			DOCUMENTNO= I.DOCUMENTNO,
			NOOFDOCS= I.NOOFDOCS,
			MANDATORYDOCS= I.MANDATORYDOCS,
			NOTES= replace(CAST(I.NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			INHERITED= I.INHERITED,
			INSTRUCTIONTYPE= I.INSTRUCTIONTYPE,
			FLAGNUMBER= I.FLAGNUMBER,
			SETTHIRDPARTYON= I.SETTHIRDPARTYON,
			RELATIVECYCLE= I.RELATIVECYCLE,
			CREATECYCLE= I.CREATECYCLE,
			ESTIMATEFLAG= I.ESTIMATEFLAG,
			EXTENDPERIOD= I.EXTENDPERIOD,
			EXTENDPERIODTYPE= I.EXTENDPERIODTYPE,
			INITIALFEE2= I.INITIALFEE2,
			PAYFEECODE2= I.PAYFEECODE2,
			ESTIMATEFLAG2= I.ESTIMATEFLAG2,
			PTADELAY= I.PTADELAY,
			SETTHIRDPARTYOFF= I.SETTHIRDPARTYOFF,
			RECEIVINGCYCLEFLAG= I.RECEIVINGCYCLEFLAG,
			RECALCEVENTDATE= I.RECALCEVENTDATE,
			CHANGENAMETYPE= I.CHANGENAMETYPE,
			COPYFROMNAMETYPE= I.COPYFROMNAMETYPE,
			COPYTONAMETYPE= I.COPYTONAMETYPE,
			DELCOPYFROMNAME= I.DELCOPYFROMNAME,
			CASETYPE= I.CASETYPE,
			COUNTRYCODE= I.COUNTRYCODE,
			COUNTRYCODEISTHISCASE= I.COUNTRYCODEISTHISCASE,
			PROPERTYTYPE= I.PROPERTYTYPE,
			PROPERTYTYPEISTHISCASE= I.PROPERTYTYPEISTHISCASE,
			CASECATEGORY= I.CASECATEGORY,
			CATEGORYISTHISCASE= I.CATEGORYISTHISCASE,
			SUBTYPE= I.SUBTYPE,
			SUBTYPEISTHISCASE= I.SUBTYPEISTHISCASE,
			BASIS= I.BASIS,
			BASISISTHISCASE= I.BASISISTHISCASE,
			DIRECTPAYFLAG= I.DIRECTPAYFLAG,
			DIRECTPAYFLAG2= I.DIRECTPAYFLAG2,
			OFFICEID= I.OFFICEID,
			OFFICEIDISTHISCASE= I.OFFICEIDISTHISCASE,
			DUEDATERESPNAMETYPE= I.DUEDATERESPNAMETYPE,
			DUEDATERESPNAMENO= I.DUEDATERESPNAMENO,
			LOADNUMBERTYPE= I.LOADNUMBERTYPE,
			SUPPRESSCALCULATION= I.SUPPRESSCALCULATION,
			RENEWALSTATUS= I.RENEWALSTATUS
		from	EVENTCONTROL C
		join	CCImport_EVENTCONTROL I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO)
" Set @sSQLString1="
		where 		( I.EVENTDESCRIPTION <>  C.EVENTDESCRIPTION OR (I.EVENTDESCRIPTION is null and C.EVENTDESCRIPTION is not null )
 OR (I.EVENTDESCRIPTION is not null and C.EVENTDESCRIPTION is null))
		OR 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null )
 OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
		OR 		( I.PARENTCRITERIANO <>  C.PARENTCRITERIANO OR (I.PARENTCRITERIANO is null and C.PARENTCRITERIANO is not null )
 OR (I.PARENTCRITERIANO is not null and C.PARENTCRITERIANO is null))
		OR 		( I.PARENTEVENTNO <>  C.PARENTEVENTNO OR (I.PARENTEVENTNO is null and C.PARENTEVENTNO is not null )
 OR (I.PARENTEVENTNO is not null and C.PARENTEVENTNO is null))
		OR 		( I.NUMCYCLESALLOWED <>  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null )
 OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null))
		OR 		( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null )
 OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
		OR 		( I.WHICHDUEDATE <>  C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is not null )
 OR (I.WHICHDUEDATE is not null and C.WHICHDUEDATE is null))
		OR 		( I.COMPAREBOOLEAN <>  C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is not null )
 OR (I.COMPAREBOOLEAN is not null and C.COMPAREBOOLEAN is null))
		OR 		( I.CHECKCOUNTRYFLAG <>  C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is not null )
 OR (I.CHECKCOUNTRYFLAG is not null and C.CHECKCOUNTRYFLAG is null))
		OR 		( I.SAVEDUEDATE <>  C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is not null )
 OR (I.SAVEDUEDATE is not null and C.SAVEDUEDATE is null))
		OR 		( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null )
 OR (I.STATUSCODE is not null and C.STATUSCODE is null))
		OR 		( I.SPECIALFUNCTION <>  C.SPECIALFUNCTION OR (I.SPECIALFUNCTION is null and C.SPECIALFUNCTION is not null )
 OR (I.SPECIALFUNCTION is not null and C.SPECIALFUNCTION is null))
		OR 		( I.INITIALFEE <>  C.INITIALFEE OR (I.INITIALFEE is null and C.INITIALFEE is not null )
 OR (I.INITIALFEE is not null and C.INITIALFEE is null))
		OR 		( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null )
 OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
		OR 		( I.CREATEACTION <>  C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null )
 OR (I.CREATEACTION is not null and C.CREATEACTION is null))
		OR 		( I.STATUSDESC <>  C.STATUSDESC OR (I.STATUSDESC is null and C.STATUSDESC is not null )
 OR (I.STATUSDESC is not null and C.STATUSDESC is null))
" Set @sSQLString2="
		OR 		( I.CLOSEACTION <>  C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is not null) 
OR (I.CLOSEACTION is not null and C.CLOSEACTION is null))
		OR 		( I.UPDATEFROMEVENT <>  C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is not null) 
OR (I.UPDATEFROMEVENT is not null and C.UPDATEFROMEVENT is null))
		OR 		( I.FROMRELATIONSHIP <>  C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is not null) 
OR (I.FROMRELATIONSHIP is not null and C.FROMRELATIONSHIP is null))
		OR 		( I.FROMANCESTOR <>  C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is not null) 
OR (I.FROMANCESTOR is not null and C.FROMANCESTOR is null))
		OR 		( I.UPDATEMANUALLY <>  C.UPDATEMANUALLY OR (I.UPDATEMANUALLY is null and C.UPDATEMANUALLY is not null) 
OR (I.UPDATEMANUALLY is not null and C.UPDATEMANUALLY is null))
		OR 		( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
		OR 		( I.DOCUMENTNO <>  C.DOCUMENTNO OR (I.DOCUMENTNO is null and C.DOCUMENTNO is not null) 
OR (I.DOCUMENTNO is not null and C.DOCUMENTNO is null))
		OR 		( I.NOOFDOCS <>  C.NOOFDOCS OR (I.NOOFDOCS is null and C.NOOFDOCS is not null) 
OR (I.NOOFDOCS is not null and C.NOOFDOCS is null))
		OR 		( I.MANDATORYDOCS <>  C.MANDATORYDOCS OR (I.MANDATORYDOCS is null and C.MANDATORYDOCS is not null) 
OR (I.MANDATORYDOCS is not null and C.MANDATORYDOCS is null))
		OR 		( replace(CAST(I.NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.NOTES as NVARCHAR(MAX)) OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
		OR 		( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
		OR 		( I.SETTHIRDPARTYON <>  C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is not null) 
OR (I.SETTHIRDPARTYON is not null and C.SETTHIRDPARTYON is null))
		OR 		( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
		OR 		( I.CREATECYCLE <>  C.CREATECYCLE OR (I.CREATECYCLE is null and C.CREATECYCLE is not null) 
OR (I.CREATECYCLE is not null and C.CREATECYCLE is null))
		OR 		( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
		OR 		( I.EXTENDPERIOD <>  C.EXTENDPERIOD OR (I.EXTENDPERIOD is null and C.EXTENDPERIOD is not null) 
OR (I.EXTENDPERIOD is not null and C.EXTENDPERIOD is null))
" Set @sSQLString3="
		OR 		( I.EXTENDPERIODTYPE <>  C.EXTENDPERIODTYPE OR (I.EXTENDPERIODTYPE is null and C.EXTENDPERIODTYPE is not null ) 
OR (I.EXTENDPERIODTYPE is not null and C.EXTENDPERIODTYPE is null))
		OR 		( I.INITIALFEE2 <>  C.INITIALFEE2 OR (I.INITIALFEE2 is null and C.INITIALFEE2 is not null ) 
OR (I.INITIALFEE2 is not null and C.INITIALFEE2 is null))
		OR 		( I.PAYFEECODE2 <>  C.PAYFEECODE2 OR (I.PAYFEECODE2 is null and C.PAYFEECODE2 is not null ) 
OR (I.PAYFEECODE2 is not null and C.PAYFEECODE2 is null))
		OR 		( I.ESTIMATEFLAG2 <>  C.ESTIMATEFLAG2 OR (I.ESTIMATEFLAG2 is null and C.ESTIMATEFLAG2 is not null ) 
OR (I.ESTIMATEFLAG2 is not null and C.ESTIMATEFLAG2 is null))
		OR 		( I.PTADELAY <>  C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is not null ) 
OR (I.PTADELAY is not null and C.PTADELAY is null))
		OR 		( I.SETTHIRDPARTYOFF <>  C.SETTHIRDPARTYOFF OR (I.SETTHIRDPARTYOFF is null and C.SETTHIRDPARTYOFF is not null ) 
OR (I.SETTHIRDPARTYOFF is not null and C.SETTHIRDPARTYOFF is null))
		OR 		( I.RECEIVINGCYCLEFLAG <>  C.RECEIVINGCYCLEFLAG OR (I.RECEIVINGCYCLEFLAG is null and C.RECEIVINGCYCLEFLAG is not null ) 
OR (I.RECEIVINGCYCLEFLAG is not null and C.RECEIVINGCYCLEFLAG is null))
		OR 		( I.RECALCEVENTDATE <>  C.RECALCEVENTDATE OR (I.RECALCEVENTDATE is null and C.RECALCEVENTDATE is not null ) 
OR (I.RECALCEVENTDATE is not null and C.RECALCEVENTDATE is null))
		OR 		( I.CHANGENAMETYPE <>  C.CHANGENAMETYPE OR (I.CHANGENAMETYPE is null and C.CHANGENAMETYPE is not null ) 
OR (I.CHANGENAMETYPE is not null and C.CHANGENAMETYPE is null))
		OR 		( I.COPYFROMNAMETYPE <>  C.COPYFROMNAMETYPE OR (I.COPYFROMNAMETYPE is null and C.COPYFROMNAMETYPE is not null ) 
OR (I.COPYFROMNAMETYPE is not null and C.COPYFROMNAMETYPE is null))
		OR 		( I.COPYTONAMETYPE <>  C.COPYTONAMETYPE OR (I.COPYTONAMETYPE is null and C.COPYTONAMETYPE is not null ) 
OR (I.COPYTONAMETYPE is not null and C.COPYTONAMETYPE is null))
		OR 		( I.DELCOPYFROMNAME <>  C.DELCOPYFROMNAME OR (I.DELCOPYFROMNAME is null and C.DELCOPYFROMNAME is not null ) 
OR (I.DELCOPYFROMNAME is not null and C.DELCOPYFROMNAME is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null ) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null ) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.COUNTRYCODEISTHISCASE <>  C.COUNTRYCODEISTHISCASE OR (I.COUNTRYCODEISTHISCASE is null and C.COUNTRYCODEISTHISCASE is not null ) 
OR (I.COUNTRYCODEISTHISCASE is not null and C.COUNTRYCODEISTHISCASE is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null ) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.PROPERTYTYPEISTHISCASE <>  C.PROPERTYTYPEISTHISCASE OR (I.PROPERTYTYPEISTHISCASE is null and C.PROPERTYTYPEISTHISCASE is not null ) 
OR (I.PROPERTYTYPEISTHISCASE is not null and C.PROPERTYTYPEISTHISCASE is null))
		OR 		( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null ) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
" Set @sSQLString4="
		OR 		( I.CATEGORYISTHISCASE <>  C.CATEGORYISTHISCASE OR (I.CATEGORYISTHISCASE is null and C.CATEGORYISTHISCASE is not null )
 OR (I.CATEGORYISTHISCASE is not null and C.CATEGORYISTHISCASE is null))
		OR 		( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null )
 OR (I.SUBTYPE is not null and C.SUBTYPE is null))
		OR 		( I.SUBTYPEISTHISCASE <>  C.SUBTYPEISTHISCASE OR (I.SUBTYPEISTHISCASE is null and C.SUBTYPEISTHISCASE is not null )
 OR (I.SUBTYPEISTHISCASE is not null and C.SUBTYPEISTHISCASE is null))
		OR 		( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null )
 OR (I.BASIS is not null and C.BASIS is null))
		OR 		( I.BASISISTHISCASE <>  C.BASISISTHISCASE OR (I.BASISISTHISCASE is null and C.BASISISTHISCASE is not null )
 OR (I.BASISISTHISCASE is not null and C.BASISISTHISCASE is null))
		OR 		( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null )
 OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
		OR 		( I.DIRECTPAYFLAG2 <>  C.DIRECTPAYFLAG2 OR (I.DIRECTPAYFLAG2 is null and C.DIRECTPAYFLAG2 is not null )
 OR (I.DIRECTPAYFLAG2 is not null and C.DIRECTPAYFLAG2 is null))
		OR 		( I.OFFICEID <>  C.OFFICEID OR (I.OFFICEID is null and C.OFFICEID is not null )
 OR (I.OFFICEID is not null and C.OFFICEID is null))
		OR 		( I.OFFICEIDISTHISCASE <>  C.OFFICEIDISTHISCASE OR (I.OFFICEIDISTHISCASE is null and C.OFFICEIDISTHISCASE is not null )
 OR (I.OFFICEIDISTHISCASE is not null and C.OFFICEIDISTHISCASE is null))
		OR 		( I.DUEDATERESPNAMETYPE <>  C.DUEDATERESPNAMETYPE OR (I.DUEDATERESPNAMETYPE is null and C.DUEDATERESPNAMETYPE is not null )
 OR (I.DUEDATERESPNAMETYPE is not null and C.DUEDATERESPNAMETYPE is null))
		OR 		( I.DUEDATERESPNAMENO <>  C.DUEDATERESPNAMENO OR (I.DUEDATERESPNAMENO is null and C.DUEDATERESPNAMENO is not null )
 OR (I.DUEDATERESPNAMENO is not null and C.DUEDATERESPNAMENO is null))
		OR 		( I.LOADNUMBERTYPE <>  C.LOADNUMBERTYPE OR (I.LOADNUMBERTYPE is null and C.LOADNUMBERTYPE is not null )
 OR (I.LOADNUMBERTYPE is not null and C.LOADNUMBERTYPE is null))
		OR 		( I.SUPPRESSCALCULATION <>  C.SUPPRESSCALCULATION OR (I.SUPPRESSCALCULATION is null and C.SUPPRESSCALCULATION is not null )
 OR (I.SUPPRESSCALCULATION is not null and C.SUPPRESSCALCULATION is null))
		OR 		( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null )
 OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
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
		Insert into EVENTCONTROL(
			CRITERIANO,
			EVENTNO,
			EVENTDESCRIPTION,
			DISPLAYSEQUENCE,
			PARENTCRITERIANO,
			PARENTEVENTNO,
			NUMCYCLESALLOWED,
			IMPORTANCELEVEL,
			WHICHDUEDATE,
			COMPAREBOOLEAN,
			CHECKCOUNTRYFLAG,
			SAVEDUEDATE,
			STATUSCODE,
			SPECIALFUNCTION,
			INITIALFEE,
			PAYFEECODE,
			CREATEACTION,
			STATUSDESC,
			CLOSEACTION,
			UPDATEFROMEVENT,
			FROMRELATIONSHIP,
			FROMANCESTOR,
			UPDATEMANUALLY,
			ADJUSTMENT,
			DOCUMENTNO,
			NOOFDOCS,
			MANDATORYDOCS,
			NOTES,
			INHERITED,
			INSTRUCTIONTYPE,
			FLAGNUMBER,
			SETTHIRDPARTYON,
			RELATIVECYCLE,
			CREATECYCLE,
			ESTIMATEFLAG,
			EXTENDPERIOD,
			EXTENDPERIODTYPE,
			INITIALFEE2,
			PAYFEECODE2,
			ESTIMATEFLAG2,
			PTADELAY,
			SETTHIRDPARTYOFF,
			RECEIVINGCYCLEFLAG,
			RECALCEVENTDATE,
			CHANGENAMETYPE,
			COPYFROMNAMETYPE,
			COPYTONAMETYPE,
			DELCOPYFROMNAME,
			CASETYPE,
			COUNTRYCODE,
			COUNTRYCODEISTHISCASE,
			PROPERTYTYPE,
			PROPERTYTYPEISTHISCASE,
			CASECATEGORY,
			CATEGORYISTHISCASE,
			SUBTYPE,
			SUBTYPEISTHISCASE,
			BASIS,
			BASISISTHISCASE,
			DIRECTPAYFLAG,
			DIRECTPAYFLAG2,
			OFFICEID,
			OFFICEIDISTHISCASE,
			DUEDATERESPNAMETYPE,
			DUEDATERESPNAMENO,
			LOADNUMBERTYPE,
			SUPPRESSCALCULATION,
			RENEWALSTATUS)
		select
			 I.CRITERIANO,
			 I.EVENTNO,
			 I.EVENTDESCRIPTION,
			 I.DISPLAYSEQUENCE,
			 I.PARENTCRITERIANO,
			 I.PARENTEVENTNO,
			 I.NUMCYCLESALLOWED,
			 I.IMPORTANCELEVEL,
			 I.WHICHDUEDATE,
			 I.COMPAREBOOLEAN,
			 I.CHECKCOUNTRYFLAG,
			 I.SAVEDUEDATE,
			 I.STATUSCODE,
			 I.SPECIALFUNCTION,
			 I.INITIALFEE,
			 I.PAYFEECODE,
			 I.CREATEACTION,
			 I.STATUSDESC,
			 I.CLOSEACTION,
			 I.UPDATEFROMEVENT,
			 I.FROMRELATIONSHIP,
			 I.FROMANCESTOR,
			 I.UPDATEMANUALLY,
			 I.ADJUSTMENT,
			 I.DOCUMENTNO,
			 I.NOOFDOCS,
			 I.MANDATORYDOCS,
			 replace(CAST(I.NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			 I.INHERITED,
			 I.INSTRUCTIONTYPE,
			 I.FLAGNUMBER,
			 I.SETTHIRDPARTYON,
			 I.RELATIVECYCLE,
			 I.CREATECYCLE,
			 I.ESTIMATEFLAG,
			 I.EXTENDPERIOD,
			 I.EXTENDPERIODTYPE,
			 I.INITIALFEE2,
			 I.PAYFEECODE2,
			 I.ESTIMATEFLAG2,
			 I.PTADELAY,
			 I.SETTHIRDPARTYOFF,
			 I.RECEIVINGCYCLEFLAG,
			 I.RECALCEVENTDATE,
			 I.CHANGENAMETYPE,
			 I.COPYFROMNAMETYPE,
			 I.COPYTONAMETYPE,
			 I.DELCOPYFROMNAME,
			 I.CASETYPE,
			 I.COUNTRYCODE,
			 I.COUNTRYCODEISTHISCASE,
			 I.PROPERTYTYPE,
			 I.PROPERTYTYPEISTHISCASE,
			 I.CASECATEGORY,
			 I.CATEGORYISTHISCASE,
			 I.SUBTYPE,
			 I.SUBTYPEISTHISCASE,
			 I.BASIS,
			 I.BASISISTHISCASE,
			 I.DIRECTPAYFLAG,
			 I.DIRECTPAYFLAG2,
			 I.OFFICEID,
			 I.OFFICEIDISTHISCASE,
			 I.DUEDATERESPNAMETYPE,
			 I.DUEDATERESPNAMENO,
			 I.LOADNUMBERTYPE,
			 I.SUPPRESSCALCULATION,
			 I.RENEWALSTATUS
		from CCImport_EVENTCONTROL I
		left join EVENTCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
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
		Delete EVENTCONTROL
		from CCImport_EVENTCONTROL I
		right join EVENTCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
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
grant execute on dbo.ip_cc_EVENTCONTROL  to public
go
