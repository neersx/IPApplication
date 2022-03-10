-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesSTATUS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesSTATUS.'
	drop procedure dbo.ip_RulesSTATUS
	print '**** Creating procedure dbo.ip_RulesSTATUS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesSTATUS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesSTATUS
-- VERSION :	4
-- DESCRIPTION:	The comparison/display and merging of imported data for the STATUS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 19 Jul 2004	MF		1	Procedure created
-- 27-Nov-2006	MF	13919	2	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
-- 23-Mar-2007	MF	14616	3	An existing Status should not have its settings modified 
-- 21 Jan 2011	MF	19321	4	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 		(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the IMPORTED_STATUS table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString1		varchar(8000)
Declare @sSQLString2		varchar(8000)
Declare @sSQLString3		varchar(8000)
Declare @sSQLString4		varchar(8000)
Declare @sSQLString5		varchar(8000)
Declare @sSQLString6		varchar(8000)

Declare	@ErrorCode			int
Declare @sUserName			nvarchar(40)
Declare	@hDocument	 		int 			-- handle to the XML parameter
Declare @bOriginalKeyColumnExists	bit

Set @ErrorCode=0
Set @bOriginalKeyColumnExists = 0
Set @sUserName	= @psUserName


-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison
If @ErrorCode=0 
and @pnFunction in (1,2)
Begin
	-- If mapping is allowed add an extra column to store the original key for update
	-- and update the key with the previously stored mappings.
	-- @pnFunction = 1 describes the set up and selection of the data comparison
	-- Exclude this section if tab does not support mapping.
	
	Set @sSQLString="select @bOriginalKeyColumnExists = 1 
                         from syscolumns 
			 where (name = 'ORIGINAL_KEY') and id = object_id('"+@sUserName+".Imported_STATUS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bOriginalKeyColumnExists	bit OUTPUT',
			  @bOriginalKeyColumnExists 	= @bOriginalKeyColumnExists OUTPUT

	If  @ErrorCode=0
	and @bOriginalKeyColumnExists=0
	Begin
		Set @sSQLString="ALTER TABLE "+@sUserName+".Imported_STATUS ADD ORIGINAL_KEY NVARCHAR(50)"
		exec @ErrorCode=sp_executesql @sSQLString

		-- Now save the original key value
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_STATUS
			SET ORIGINAL_KEY=RTRIM(STATUSCODE)"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_STATUS
			SET STATUSCODE = isnull(M.MAPVALUE, C.ORIGINAL_KEY)
			FROM "+@sUserName+".Imported_STATUS C
			LEFT JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
						and M.MAPTABLE   ='STATUS'
						and M.MAPCOLUMN  ='STATUSCODE'
						and M.SOURCEVALUE=C.ORIGINAL_KEY)"
		exec @ErrorCode=sp_executesql @sSQLString
	end
End


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3			as 'Comparison',
			NULL			as Match,
			I.STATUSCODE		as 'Imported Status Code',
			C.INTERNALDESC		as 'Imported Internal Desc',
			C.EXTERNALDESC		as 'Imported External Desc',
			dbo.fn_DisplayBoolean(I.LIVEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Live Flag',
			dbo.fn_DisplayBoolean(I.REGISTEREDFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Registered Flag',
			dbo.fn_DisplayBoolean(I.RENEWALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Renewal Flag',
			dbo.fn_DisplayBoolean(I.POLICERENEWALS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Police Renewals',
			dbo.fn_DisplayBoolean(I.POLICEEXAM,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Police Exam',
			dbo.fn_DisplayBoolean(I.POLICEOTHERACTIONS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Police Other Actions',
			dbo.fn_DisplayBoolean(I.LETTERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Letters Allowed',
			dbo.fn_DisplayBoolean(I.CHARGESALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Charges Allowed',
			dbo.fn_DisplayBoolean(I.REMINDERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Reminders Allowed',
			dbo.fn_DisplayBoolean(I.CONFIRMATIONREQ,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Confirmation Req',
			T.DESCRIPTION		as 'Imported Stop Pay Reason',
			C.STATUSCODE		as 'Status Code',
			C.INTERNALDESC		as 'Internal Desc',
			C.EXTERNALDESC		as 'External Desc',
			dbo.fn_DisplayBoolean(C.LIVEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Live Flag',
			dbo.fn_DisplayBoolean(C.REGISTEREDFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Registered Flag',
			dbo.fn_DisplayBoolean(C.RENEWALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Renewal Flag',
			dbo.fn_DisplayBoolean(C.POLICERENEWALS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Police Renewals',
			dbo.fn_DisplayBoolean(C.POLICEEXAM,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Police Exam',
			dbo.fn_DisplayBoolean(C.POLICEOTHERACTIONS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Police Other Actions',
			dbo.fn_DisplayBoolean(C.LETTERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Letters Allowed',
			dbo.fn_DisplayBoolean(C.CHARGESALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Charges Allowed',
			dbo.fn_DisplayBoolean(C.REMINDERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Reminders Allowed',
			dbo.fn_DisplayBoolean(C.CONFIRMATIONREQ,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Confirmation Req',
			T.DESCRIPTION		as 'Stop Pay Reason'
		from "+@sUserName+".Imported_STATUS I
		left join TABLECODES T	on (T.TABLETYPE=68
					and T.USERCODE=I.STOPPAYREASON)"+char(10)
		Set @sSQLString2="	join STATUS C	on( C.STATUSCODE=I.STATUSCODE)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.STATUSCODE,
			I.INTERNALDESC,
			I.EXTERNALDESC,
			dbo.fn_DisplayBoolean(I.LIVEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.REGISTEREDFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.RENEWALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.POLICERENEWALS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.POLICEEXAM,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.POLICEOTHERACTIONS,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.LETTERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CHARGESALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.REMINDERSALLOWED,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.CONFIRMATIONREQ,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			T.DESCRIPTION,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
		from "+@sUserName+".Imported_STATUS I
		left join TABLECODES T	on (T.TABLETYPE=68
					and T.USERCODE=I.STOPPAYREASON)"
		Set @sSQLString6="	left join STATUS C on( C.STATUSCODE=I.STATUSCODE)
		where C.STATUSCODE is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3" ELSE "3" END
	
		select @sSQLString1,@sSQLString2,@sSQLString3,@sSQLString4,@sSQLString5,@sSQLString6
		
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

/* SQA14616 ***********************************************
   Comment out STATUS Update

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update STATUS
		set	LIVEFLAG=I.LIVEFLAG,
			REGISTEREDFLAG=I.REGISTEREDFLAG,
			RENEWALFLAG=I.RENEWALFLAG,
			POLICERENEWALS=I.POLICERENEWALS,
			POLICEEXAM=I.POLICEEXAM,
			POLICEOTHERACTIONS=I.POLICEOTHERACTIONS,
			LETTERSALLOWED=I.LETTERSALLOWED,
			CHARGESALLOWED=I.CHARGESALLOWED,
			REMINDERSALLOWED=I.REMINDERSALLOWED,
			STOPPAYREASON=I.STOPPAYREASON
		from	STATUS C
		join	"+@sUserName+".Imported_STATUS I	on ( I.STATUSCODE=C.STATUSCODE)
		where 	I.LIVEFLAG<>C.LIVEFLAG OR (I.LIVEFLAG is null and C.LIVEFLAG is not null) OR (I.LIVEFLAG is not null and C.LIVEFLAG is null)
		OR	I.REGISTEREDFLAG<>C.REGISTEREDFLAG OR (I.REGISTEREDFLAG is null and C.REGISTEREDFLAG is not null) OR (I.REGISTEREDFLAG is not null and C.REGISTEREDFLAG is null)
		OR	I.RENEWALFLAG<>C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is not null) OR (I.RENEWALFLAG is not null and C.RENEWALFLAG is null)
		OR	I.POLICERENEWALS<>C.POLICERENEWALS OR (I.POLICERENEWALS is null and C.POLICERENEWALS is not null) OR (I.POLICERENEWALS is not null and C.POLICERENEWALS is null)
		OR	I.POLICEEXAM<>C.POLICEEXAM OR (I.POLICEEXAM is null and C.POLICEEXAM is not null) OR (I.POLICEEXAM is not null and C.POLICEEXAM is null)
		OR	I.POLICEOTHERACTIONS<>C.POLICEOTHERACTIONS OR (I.POLICEOTHERACTIONS is null and C.POLICEOTHERACTIONS is not null) OR (I.POLICEOTHERACTIONS is not null and C.POLICEOTHERACTIONS is null)
		OR	I.LETTERSALLOWED<>C.LETTERSALLOWED OR (I.LETTERSALLOWED is null and C.LETTERSALLOWED is not null) OR (I.LETTERSALLOWED is not null and C.LETTERSALLOWED is null)
		OR	I.CHARGESALLOWED<>C.CHARGESALLOWED OR (I.CHARGESALLOWED is null and C.CHARGESALLOWED is not null) OR (I.CHARGESALLOWED is not null and C.CHARGESALLOWED is null)
		OR	I.REMINDERSALLOWED<>C.REMINDERSALLOWED OR (I.REMINDERSALLOWED is null and C.REMINDERSALLOWED is not null) OR (I.REMINDERSALLOWED is not null and C.REMINDERSALLOWED is null)
		OR	I.CONFIRMATIONREQ<>C.CONFIRMATIONREQ OR (I.CONFIRMATIONREQ is null and C.CONFIRMATIONREQ is not null) OR (I.CONFIRMATIONREQ is not null and C.CONFIRMATIONREQ is null)
		OR	I.STOPPAYREASON<>C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is not null) OR (I.STOPPAYREASON is not null and C.STOPPAYREASON is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 
****************************/

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
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
			STOPPAYREASON)
		select	I.STATUSCODE,
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
			I.STOPPAYREASON
		from "+@sUserName+".Imported_STATUS I
		left join STATUS C	on ( C.STATUSCODE=I.STATUSCODE)
		where C.STATUSCODE is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End
End

-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- (if no mapping is allowed return null)
If  @ErrorCode=0
and @pnFunction=3
Begin
	Set @sSQLString="
	select STATUSCODE,'{'+convert(varchar,STATUSCODE)+'}'+INTERNALDESC
	from STATUS
	order by STATUSCODE"

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


-- @pnFunction = 4 supplies the statement to list the imported keys and any existing mapping.
If  @ErrorCode=0
and @pnFunction=4
Begin
	-- Mapping has already been done and stored in the table.
	Set @sSQLString1="
	select	I.ORIGINAL_KEY,
		I.INTERNALDESC,
		CASE WHEN (I.STATUSCODE = I.ORIGINAL_KEY)THEN NULL 
			ELSE I.STATUSCODE END
	from "+@sUserName+".Imported_STATUS I
	left join STATUS C on C.STATUSCODE = I.STATUSCODE
	order by 1"

	select @sSQLString1
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


-- @pnFunction = 5 add/updates the existing mapping based on the supplied XML

If  @ErrorCode=0
and @pnFunction=5
and @pnSourceNo is not null
and @psChangeList is not null

Begin
	-- First collect the data from the XML that has been passed as an XML parameter using 'OPENXML' functionality.
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psChangeList
	Set 	@ErrorCode = @@Error
	-- <DataMap><DataMapChange><SourceValue><StoredMapValue><NewMapValue><DataMapChange><DataMap>
	-- First delete any previous mappings for values being given new mappings.
	
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
			DELETE FROM DATAMAP
			WHERE SOURCENO = @pnSourceNo
			AND MAPTABLE = 'STATUS'
			AND MAPCOLUMN = 'STATUSCODE'
			AND SOURCEVALUE IN (
				SELECT SOURCEVALUE
				FROM  OPENXML(@hDocument, '//DataMapChange', 2)
				WITH (SOURCEVALUE nvarchar(50)'SourceValue/text()',
				      STOREDMAPVALUE nvarchar(50)'StoredMapValue/text()')
				WHERE STOREDMAPVALUE IS NOT NULL)"

		exec @ErrorCode=sp_executesql @sSQLString,
			N'@hDocument	int,
			  @pnSourceNo int',
			  @hDocument 	= @hDocument,
 			  @pnSourceNo   = @pnSourceNo

		Set @pnRowCount=@@rowcount
	End 


	If @ErrorCode=0
	Begin
		-- Now insert the new mappings (unless identical)
		Set @sSQLString= "
		Insert into DATAMAP(
			SOURCENO,
			SOURCEVALUE,
			MAPTABLE,
			MAPCOLUMN,
			MAPVALUE)
		select	
			@pnSourceNo,
			XDM.SOURCEVALUE,
			'STATUS',
			'STATUSCODE',
			XDM.NEWMAPVALUE
			from OPENXML(@hDocument, '//DataMapChange', 2)
			with (SOURCEVALUE nvarchar(50)'SourceValue/text()',
			      NEWMAPVALUE nvarchar(50)'NewMapValue/text()') XDM
			left join DATAMAP DM on (DM.SOURCENO = @pnSourceNo
					     and DM.SOURCEVALUE = XDM.SOURCEVALUE
					     and DM.MAPTABLE = 'STATUS'
					     and DM.MAPCOLUMN = 'STATUSCODE')
			where XDM.SOURCEVALUE != XDM.NEWMAPVALUE
			and DM.SOURCENO is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
			N'@hDocument	int,
			  @pnSourceNo int',
			  @hDocument 	= @hDocument,
 			  @pnSourceNo   = @pnSourceNo
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	Exec sp_xml_removedocument @hDocument
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesSTATUS  to public
go

