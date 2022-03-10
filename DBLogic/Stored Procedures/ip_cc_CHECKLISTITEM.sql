-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_CHECKLISTITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_CHECKLISTITEM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_CHECKLISTITEM.'
	drop procedure dbo.ip_cc_CHECKLISTITEM
	print '**** Creating procedure dbo.ip_cc_CHECKLISTITEM...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_CHECKLISTITEM
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_CHECKLISTITEM
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the CHECKLISTITEM table
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


-- Prerequisite that the CCImport_CHECKLISTITEM table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_CHECKLISTITEM('"+@psUserName+"')
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
		Update CHECKLISTITEM
		set	SEQUENCENO= I.SEQUENCENO,
			QUESTION= I.QUESTION,
			YESNOREQUIRED= I.YESNOREQUIRED,
			COUNTREQUIRED= I.COUNTREQUIRED,
			PERIODTYPEREQUIRED= I.PERIODTYPEREQUIRED,
			AMOUNTREQUIRED= I.AMOUNTREQUIRED,
			DATEREQUIRED= I.DATEREQUIRED,
			EMPLOYEEREQUIRED= I.EMPLOYEEREQUIRED,
			TEXTREQUIRED= I.TEXTREQUIRED,
			PAYFEECODE= I.PAYFEECODE,
			UPDATEEVENTNO= I.UPDATEEVENTNO,
			DUEDATEFLAG= I.DUEDATEFLAG,
			YESRATENO= I.YESRATENO,
			NORATENO= I.NORATENO,
			YESCHECKLISTTYPE= I.YESCHECKLISTTYPE,
			NOCHECKLISTTYPE= I.NOCHECKLISTTYPE,
			INHERITED= I.INHERITED,
			NODUEDATEFLAG= I.NODUEDATEFLAG,
			NOEVENTNO= I.NOEVENTNO,
			ESTIMATEFLAG= I.ESTIMATEFLAG,
			DIRECTPAYFLAG= I.DIRECTPAYFLAG,
			SOURCEQUESTION= I.SOURCEQUESTION,
			ANSWERSOURCEYES= I.ANSWERSOURCEYES,
			ANSWERSOURCENO= I.ANSWERSOURCENO
		from	CHECKLISTITEM C
		join	CCImport_CHECKLISTITEM I	on ( I.CRITERIANO=C.CRITERIANO
						and I.QUESTIONNO=C.QUESTIONNO)
" Set @sSQLString1="
		where 		( I.SEQUENCENO <>  C.SEQUENCENO OR (I.SEQUENCENO is null and C.SEQUENCENO is not null )
 OR (I.SEQUENCENO is not null and C.SEQUENCENO is null))
		OR 		( I.QUESTION <>  C.QUESTION OR (I.QUESTION is null and C.QUESTION is not null )
 OR (I.QUESTION is not null and C.QUESTION is null))
		OR 		( I.YESNOREQUIRED <>  C.YESNOREQUIRED OR (I.YESNOREQUIRED is null and C.YESNOREQUIRED is not null )
 OR (I.YESNOREQUIRED is not null and C.YESNOREQUIRED is null))
		OR 		( I.COUNTREQUIRED <>  C.COUNTREQUIRED OR (I.COUNTREQUIRED is null and C.COUNTREQUIRED is not null )
 OR (I.COUNTREQUIRED is not null and C.COUNTREQUIRED is null))
		OR 		( I.PERIODTYPEREQUIRED <>  C.PERIODTYPEREQUIRED OR (I.PERIODTYPEREQUIRED is null and C.PERIODTYPEREQUIRED is not null )
 OR (I.PERIODTYPEREQUIRED is not null and C.PERIODTYPEREQUIRED is null))
		OR 		( I.AMOUNTREQUIRED <>  C.AMOUNTREQUIRED OR (I.AMOUNTREQUIRED is null and C.AMOUNTREQUIRED is not null )
 OR (I.AMOUNTREQUIRED is not null and C.AMOUNTREQUIRED is null))
		OR 		( I.DATEREQUIRED <>  C.DATEREQUIRED OR (I.DATEREQUIRED is null and C.DATEREQUIRED is not null )
 OR (I.DATEREQUIRED is not null and C.DATEREQUIRED is null))
		OR 		( I.EMPLOYEEREQUIRED <>  C.EMPLOYEEREQUIRED OR (I.EMPLOYEEREQUIRED is null and C.EMPLOYEEREQUIRED is not null )
 OR (I.EMPLOYEEREQUIRED is not null and C.EMPLOYEEREQUIRED is null))
		OR 		( I.TEXTREQUIRED <>  C.TEXTREQUIRED OR (I.TEXTREQUIRED is null and C.TEXTREQUIRED is not null )
 OR (I.TEXTREQUIRED is not null and C.TEXTREQUIRED is null))
		OR 		( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null )
 OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
		OR 		( I.UPDATEEVENTNO <>  C.UPDATEEVENTNO OR (I.UPDATEEVENTNO is null and C.UPDATEEVENTNO is not null )
 OR (I.UPDATEEVENTNO is not null and C.UPDATEEVENTNO is null))
		OR 		( I.DUEDATEFLAG <>  C.DUEDATEFLAG OR (I.DUEDATEFLAG is null and C.DUEDATEFLAG is not null )
 OR (I.DUEDATEFLAG is not null and C.DUEDATEFLAG is null))
		OR 		( I.YESRATENO <>  C.YESRATENO OR (I.YESRATENO is null and C.YESRATENO is not null )
 OR (I.YESRATENO is not null and C.YESRATENO is null))
		OR 		( I.NORATENO <>  C.NORATENO OR (I.NORATENO is null and C.NORATENO is not null )
 OR (I.NORATENO is not null and C.NORATENO is null))
		OR 		( I.YESCHECKLISTTYPE <>  C.YESCHECKLISTTYPE OR (I.YESCHECKLISTTYPE is null and C.YESCHECKLISTTYPE is not null )
 OR (I.YESCHECKLISTTYPE is not null and C.YESCHECKLISTTYPE is null))
		OR 		( I.NOCHECKLISTTYPE <>  C.NOCHECKLISTTYPE OR (I.NOCHECKLISTTYPE is null and C.NOCHECKLISTTYPE is not null )
 OR (I.NOCHECKLISTTYPE is not null and C.NOCHECKLISTTYPE is null))
" Set @sSQLString2="
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.NODUEDATEFLAG <>  C.NODUEDATEFLAG OR (I.NODUEDATEFLAG is null and C.NODUEDATEFLAG is not null) 
OR (I.NODUEDATEFLAG is not null and C.NODUEDATEFLAG is null))
		OR 		( I.NOEVENTNO <>  C.NOEVENTNO OR (I.NOEVENTNO is null and C.NOEVENTNO is not null) 
OR (I.NOEVENTNO is not null and C.NOEVENTNO is null))
		OR 		( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
		OR 		( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null) 
OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
		OR 		( I.SOURCEQUESTION <>  C.SOURCEQUESTION OR (I.SOURCEQUESTION is null and C.SOURCEQUESTION is not null) 
OR (I.SOURCEQUESTION is not null and C.SOURCEQUESTION is null))
		OR 		( I.ANSWERSOURCEYES <>  C.ANSWERSOURCEYES OR (I.ANSWERSOURCEYES is null and C.ANSWERSOURCEYES is not null) 
OR (I.ANSWERSOURCEYES is not null and C.ANSWERSOURCEYES is null))
		OR 		( I.ANSWERSOURCENO <>  C.ANSWERSOURCENO OR (I.ANSWERSOURCENO is null and C.ANSWERSOURCENO is not null) 
OR (I.ANSWERSOURCENO is not null and C.ANSWERSOURCENO is null))
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
		Insert into CHECKLISTITEM(
			CRITERIANO,
			QUESTIONNO,
			SEQUENCENO,
			QUESTION,
			YESNOREQUIRED,
			COUNTREQUIRED,
			PERIODTYPEREQUIRED,
			AMOUNTREQUIRED,
			DATEREQUIRED,
			EMPLOYEEREQUIRED,
			TEXTREQUIRED,
			PAYFEECODE,
			UPDATEEVENTNO,
			DUEDATEFLAG,
			YESRATENO,
			NORATENO,
			YESCHECKLISTTYPE,
			NOCHECKLISTTYPE,
			INHERITED,
			NODUEDATEFLAG,
			NOEVENTNO,
			ESTIMATEFLAG,
			DIRECTPAYFLAG,
			SOURCEQUESTION,
			ANSWERSOURCEYES,
			ANSWERSOURCENO)
		select
	 I.CRITERIANO,
	 I.QUESTIONNO,
	 I.SEQUENCENO,
	 I.QUESTION,
	 I.YESNOREQUIRED,
	 I.COUNTREQUIRED,
	 I.PERIODTYPEREQUIRED,
	 I.AMOUNTREQUIRED,
	 I.DATEREQUIRED,
	 I.EMPLOYEEREQUIRED,
	 I.TEXTREQUIRED,
	 I.PAYFEECODE,
	 I.UPDATEEVENTNO,
	 I.DUEDATEFLAG,
	 I.YESRATENO,
	 I.NORATENO,
	 I.YESCHECKLISTTYPE,
	 I.NOCHECKLISTTYPE,
	 I.INHERITED,
	 I.NODUEDATEFLAG,
	 I.NOEVENTNO,
	 I.ESTIMATEFLAG,
	 I.DIRECTPAYFLAG,
	 I.SOURCEQUESTION,
	 I.ANSWERSOURCEYES,
	 I.ANSWERSOURCENO
		from CCImport_CHECKLISTITEM I
		left join CHECKLISTITEM C	on ( C.CRITERIANO=I.CRITERIANO
						and C.QUESTIONNO=I.QUESTIONNO)
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
		Delete CHECKLISTITEM
		from CCImport_CHECKLISTITEM I
		right join CHECKLISTITEM C	on ( C.CRITERIANO=I.CRITERIANO
						and C.QUESTIONNO=I.QUESTIONNO)
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
grant execute on dbo.ip_cc_CHECKLISTITEM  to public
go
