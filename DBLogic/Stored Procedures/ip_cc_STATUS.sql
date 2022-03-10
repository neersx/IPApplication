-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_STATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_STATUS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_STATUS.'
	drop procedure dbo.ip_cc_STATUS
	print '**** Creating procedure dbo.ip_cc_STATUS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_STATUS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_STATUS
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the STATUS table
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


-- Prerequisite that the CCImport_STATUS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_STATUS('"+@psUserName+"')
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
		Update STATUS
		set	DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			USERSTATUSCODE= I.USERSTATUSCODE,
			INTERNALDESC= I.INTERNALDESC,
			EXTERNALDESC= I.EXTERNALDESC,
			LIVEFLAG= I.LIVEFLAG,
			REGISTEREDFLAG= I.REGISTEREDFLAG,
			RENEWALFLAG= I.RENEWALFLAG,
			POLICERENEWALS= I.POLICERENEWALS,
			POLICEEXAM= I.POLICEEXAM,
			POLICEOTHERACTIONS= I.POLICEOTHERACTIONS,
			LETTERSALLOWED= I.LETTERSALLOWED,
			CHARGESALLOWED= I.CHARGESALLOWED,
			REMINDERSALLOWED= I.REMINDERSALLOWED,
			CONFIRMATIONREQ= I.CONFIRMATIONREQ,
			STOPPAYREASON= I.STOPPAYREASON,
			PREVENTWIP= I.PREVENTWIP,
			PREVENTBILLING= I.PREVENTBILLING,
			PREVENTPREPAYMENT= I.PREVENTPREPAYMENT,
			PRIORARTFLAG= I.PRIORARTFLAG
		from	STATUS C
		join	CCImport_STATUS I	on ( I.STATUSCODE=C.STATUSCODE)
" Set @sSQLString1="
		where 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null )
 OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
		OR 		( I.USERSTATUSCODE <>  C.USERSTATUSCODE OR (I.USERSTATUSCODE is null and C.USERSTATUSCODE is not null )
 OR (I.USERSTATUSCODE is not null and C.USERSTATUSCODE is null))
		OR 		( I.INTERNALDESC <>  C.INTERNALDESC OR (I.INTERNALDESC is null and C.INTERNALDESC is not null )
 OR (I.INTERNALDESC is not null and C.INTERNALDESC is null))
		OR 		( I.EXTERNALDESC <>  C.EXTERNALDESC OR (I.EXTERNALDESC is null and C.EXTERNALDESC is not null )
 OR (I.EXTERNALDESC is not null and C.EXTERNALDESC is null))
		OR 		( I.LIVEFLAG <>  C.LIVEFLAG OR (I.LIVEFLAG is null and C.LIVEFLAG is not null )
 OR (I.LIVEFLAG is not null and C.LIVEFLAG is null))
		OR 		( I.REGISTEREDFLAG <>  C.REGISTEREDFLAG OR (I.REGISTEREDFLAG is null and C.REGISTEREDFLAG is not null )
 OR (I.REGISTEREDFLAG is not null and C.REGISTEREDFLAG is null))
		OR 		( I.RENEWALFLAG <>  C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is not null )
 OR (I.RENEWALFLAG is not null and C.RENEWALFLAG is null))
		OR 		( I.POLICERENEWALS <>  C.POLICERENEWALS OR (I.POLICERENEWALS is null and C.POLICERENEWALS is not null )
 OR (I.POLICERENEWALS is not null and C.POLICERENEWALS is null))
		OR 		( I.POLICEEXAM <>  C.POLICEEXAM OR (I.POLICEEXAM is null and C.POLICEEXAM is not null )
 OR (I.POLICEEXAM is not null and C.POLICEEXAM is null))
		OR 		( I.POLICEOTHERACTIONS <>  C.POLICEOTHERACTIONS OR (I.POLICEOTHERACTIONS is null and C.POLICEOTHERACTIONS is not null )
 OR (I.POLICEOTHERACTIONS is not null and C.POLICEOTHERACTIONS is null))
		OR 		( I.LETTERSALLOWED <>  C.LETTERSALLOWED OR (I.LETTERSALLOWED is null and C.LETTERSALLOWED is not null )
 OR (I.LETTERSALLOWED is not null and C.LETTERSALLOWED is null))
		OR 		( I.CHARGESALLOWED <>  C.CHARGESALLOWED OR (I.CHARGESALLOWED is null and C.CHARGESALLOWED is not null )
 OR (I.CHARGESALLOWED is not null and C.CHARGESALLOWED is null))
		OR 		( I.REMINDERSALLOWED <>  C.REMINDERSALLOWED OR (I.REMINDERSALLOWED is null and C.REMINDERSALLOWED is not null )
 OR (I.REMINDERSALLOWED is not null and C.REMINDERSALLOWED is null))
		OR 		( I.CONFIRMATIONREQ <>  C.CONFIRMATIONREQ)
		OR 		( I.STOPPAYREASON <>  C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is not null )
 OR (I.STOPPAYREASON is not null and C.STOPPAYREASON is null))
		OR 		( I.PREVENTWIP <>  C.PREVENTWIP OR (I.PREVENTWIP is null and C.PREVENTWIP is not null )
 OR (I.PREVENTWIP is not null and C.PREVENTWIP is null))
		OR 		( I.PREVENTBILLING <>  C.PREVENTBILLING OR (I.PREVENTBILLING is null and C.PREVENTBILLING is not null )
 OR (I.PREVENTBILLING is not null and C.PREVENTBILLING is null))
" Set @sSQLString2="
		OR 		( I.PREVENTPREPAYMENT <>  C.PREVENTPREPAYMENT OR (I.PREVENTPREPAYMENT is null and C.PREVENTPREPAYMENT is not null) 
OR (I.PREVENTPREPAYMENT is not null and C.PREVENTPREPAYMENT is null))
		OR 		( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null) 
OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
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
		Insert into STATUS(
			STATUSCODE,
			DISPLAYSEQUENCE,
			USERSTATUSCODE,
			INTERNALDESC,
			EXTERNALDESC,
			LIVEFLAG,
			REGISTEREDFLAG,
			RENEWALFLAG,
			POLICERENEWALS,
			POLICEEXAM,
			POLICEOTHERACTIONS,
			LETTERSALLOWED,
			CHARGESALLOWED,
			REMINDERSALLOWED,
			CONFIRMATIONREQ,
			STOPPAYREASON,
			PREVENTWIP,
			PREVENTBILLING,
			PREVENTPREPAYMENT,
			PRIORARTFLAG)
		select
	 I.STATUSCODE,
	 I.DISPLAYSEQUENCE,
	 I.USERSTATUSCODE,
	 I.INTERNALDESC,
	 I.EXTERNALDESC,
	 I.LIVEFLAG,
	 I.REGISTEREDFLAG,
	 I.RENEWALFLAG,
	 I.POLICERENEWALS,
	 I.POLICEEXAM,
	 I.POLICEOTHERACTIONS,
	 I.LETTERSALLOWED,
	 I.CHARGESALLOWED,
	 I.REMINDERSALLOWED,
	 I.CONFIRMATIONREQ,
	 I.STOPPAYREASON,
	 I.PREVENTWIP,
	 I.PREVENTBILLING,
	 I.PREVENTPREPAYMENT,
	 I.PRIORARTFLAG
		from CCImport_STATUS I
		left join STATUS C	on ( C.STATUSCODE=I.STATUSCODE)
		where C.STATUSCODE is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete STATUS
		from CCImport_STATUS I
		right join STATUS C	on ( C.STATUSCODE=I.STATUSCODE)
		where I.STATUSCODE is null"

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
grant execute on dbo.ip_cc_STATUS  to public
go
