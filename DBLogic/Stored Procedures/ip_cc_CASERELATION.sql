-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_CASERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_CASERELATION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_CASERELATION.'
	drop procedure dbo.ip_cc_CASERELATION
	print '**** Creating procedure dbo.ip_cc_CASERELATION...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_CASERELATION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_CASERELATION
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the CASERELATION table
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


-- Prerequisite that the CCImport_CASERELATION table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_CASERELATION('"+@psUserName+"')
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
		Update CASERELATION
		set	EVENTNO= I.EVENTNO,
			EARLIESTDATEFLAG= I.EARLIESTDATEFLAG,
			SHOWFLAG= I.SHOWFLAG,
			RELATIONSHIPDESC= I.RELATIONSHIPDESC,
			POINTERTOPARENT= I.POINTERTOPARENT,
			DISPLAYEVENTONLY= I.DISPLAYEVENTONLY,
			FROMEVENTNO= I.FROMEVENTNO,
			DISPLAYEVENTNO= I.DISPLAYEVENTNO,
			PRIORARTFLAG= I.PRIORARTFLAG,
			NOTES= I.NOTES
		from	CASERELATION C
		join	CCImport_CASERELATION I	on ( I.RELATIONSHIP=C.RELATIONSHIP)
" Set @sSQLString1="
		where 		( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null )
 OR (I.EVENTNO is not null and C.EVENTNO is null))
		OR 		( I.EARLIESTDATEFLAG <>  C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is not null )
 OR (I.EARLIESTDATEFLAG is not null and C.EARLIESTDATEFLAG is null))
		OR 		( I.SHOWFLAG <>  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is not null )
 OR (I.SHOWFLAG is not null and C.SHOWFLAG is null))
		OR 		( I.RELATIONSHIPDESC <>  C.RELATIONSHIPDESC OR (I.RELATIONSHIPDESC is null and C.RELATIONSHIPDESC is not null )
 OR (I.RELATIONSHIPDESC is not null and C.RELATIONSHIPDESC is null))
		OR 		( I.POINTERTOPARENT <>  C.POINTERTOPARENT OR (I.POINTERTOPARENT is null and C.POINTERTOPARENT is not null )
 OR (I.POINTERTOPARENT is not null and C.POINTERTOPARENT is null))
		OR 		( I.DISPLAYEVENTONLY <>  C.DISPLAYEVENTONLY OR (I.DISPLAYEVENTONLY is null and C.DISPLAYEVENTONLY is not null )
 OR (I.DISPLAYEVENTONLY is not null and C.DISPLAYEVENTONLY is null))
		OR 		( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null )
 OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
		OR 		( I.DISPLAYEVENTNO <>  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is not null )
 OR (I.DISPLAYEVENTNO is not null and C.DISPLAYEVENTNO is null))
		OR 		( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null )
 OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
		OR 		( I.NOTES <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null )
 OR (I.NOTES is not null and C.NOTES is null))
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
		Insert into CASERELATION(
			RELATIONSHIP,
			EVENTNO,
			EARLIESTDATEFLAG,
			SHOWFLAG,
			RELATIONSHIPDESC,
			POINTERTOPARENT,
			DISPLAYEVENTONLY,
			FROMEVENTNO,
			DISPLAYEVENTNO,
			PRIORARTFLAG,
			NOTES)
		select
			 I.RELATIONSHIP,
			 I.EVENTNO,
			 I.EARLIESTDATEFLAG,
			 I.SHOWFLAG,
			 I.RELATIONSHIPDESC,
			 I.POINTERTOPARENT,
			 I.DISPLAYEVENTONLY,
			 I.FROMEVENTNO,
			 I.DISPLAYEVENTNO,
			 I.PRIORARTFLAG,
			 I.NOTES
		from CCImport_CASERELATION I
		left join CASERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
		where C.RELATIONSHIP is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete CASERELATION
		from CCImport_CASERELATION I
		right join CASERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
		where I.RELATIONSHIP is null"

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
grant execute on dbo.ip_cc_CASERELATION  to public
go
