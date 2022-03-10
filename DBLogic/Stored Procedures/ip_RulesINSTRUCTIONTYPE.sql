-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesINSTRUCTIONTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesINSTRUCTIONTYPE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesINSTRUCTIONTYPE.'
	drop procedure dbo.ip_RulesINSTRUCTIONTYPE
	print '**** Creating procedure dbo.ip_RulesINSTRUCTIONTYPE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesINSTRUCTIONTYPE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesINSTRUCTIONTYPE
-- VERSION :	5
-- DESCRIPTION:	The comparison/display and merging of imported data for the INSTRUCTIONTYPE table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 24 Oct 2006	MF		1	Procedure created
-- 27-Nov-2006	MF	13919	2	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
-- 23 Jul 2009	MF	17864	3	Updates of the INSTRUCTIONTYPE table should not change the RESTICTEDBY column.
-- 26 Oct 2010	MF	19140	4	Updates of the INSTRUCTIONTYPE table should not change the INSTRTYPEDESC column.
-- 21 Jan 2011	MF	19321	4	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 
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


-- Prerequisite that the IMPORTED_INSTRUCTIONTYPE table has been loaded

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
			 where (name = 'ORIGINAL_KEY') and id = object_id('"+@sUserName+".Imported_INSTRUCTIONTYPE')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bOriginalKeyColumnExists	bit OUTPUT',
			  @bOriginalKeyColumnExists 	= @bOriginalKeyColumnExists OUTPUT

	If  @ErrorCode=0
	and @bOriginalKeyColumnExists=0
	Begin
		Set @sSQLString="ALTER TABLE "+@sUserName+".Imported_INSTRUCTIONTYPE ADD ORIGINAL_KEY NVARCHAR(50)"
		exec @ErrorCode=sp_executesql @sSQLString

		-- Now save the original key value
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_INSTRUCTIONTYPE
			SET ORIGINAL_KEY=RTRIM(INSTRUCTIONTYPE)"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_INSTRUCTIONTYPE
			SET INSTRUCTIONTYPE = isnull(M.MAPVALUE, C.ORIGINAL_KEY)
			FROM "+@sUserName+".Imported_INSTRUCTIONTYPE C
			LEFT JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
						and M.MAPTABLE   ='INSTRUCTIONTYPE'
						and M.MAPCOLUMN  ='INSTRUCTIONTYPE'
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
			I.INSTRUCTIONTYPE	as 'Imported Instructiontype',
			I.NAMETYPE		as 'Imported Nametype',
			C.INSTRTYPEDESC		as 'Imported Instrtypedesc',
			C.RESTRICTEDBYTYPE	as 'Imported Restrictedbytype',
			C.INSTRUCTIONTYPE	as 'Instructiontype',
			C.NAMETYPE		as 'Nametype',
			C.INSTRTYPEDESC		as 'Instrtypedesc',
			C.RESTRICTEDBYTYPE	as 'Restrictedbytype'
		from "+@sUserName+".Imported_INSTRUCTIONTYPE I"+char(10)
		Set @sSQLString2="join INSTRUCTIONTYPE C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		where	(I.NAMETYPE=C.NAMETYPE)"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.INSTRUCTIONTYPE,
			I.NAMETYPE,
			C.INSTRTYPEDESC,
			C.RESTRICTEDBYTYPE,
			C.INSTRUCTIONTYPE,
			C.NAMETYPE,
			C.INSTRTYPEDESC,
			C.RESTRICTEDBYTYPE
		from "+@sUserName+".Imported_INSTRUCTIONTYPE I"
		Set @sSQLString4="	join INSTRUCTIONTYPE C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		where 	I.NAMETYPE<>C.NAMETYPE"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.INSTRUCTIONTYPE,
			I.NAMETYPE,
			I.INSTRTYPEDESC,
			I.RESTRICTEDBYTYPE,
			null,
			null,
			null,
			null
		from "+@sUserName+".Imported_INSTRUCTIONTYPE I"
		Set @sSQLString6="		left join INSTRUCTIONTYPE C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		where C.INSTRUCTIONTYPE is null
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
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update INSTRUCTIONTYPE
		set	NAMETYPE=I.NAMETYPE
		from	INSTRUCTIONTYPE C
		join	"+@sUserName+".Imported_INSTRUCTIONTYPE I	on ( I.INSTRUCTIONTYPE=C.INSTRUCTIONTYPE)
		where 	I.NAMETYPE<>C.NAMETYPE"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into INSTRUCTIONTYPE(
			INSTRUCTIONTYPE,
			NAMETYPE,
			INSTRTYPEDESC,
			RESTRICTEDBYTYPE)
		select	I.INSTRUCTIONTYPE,
			I.NAMETYPE,
			I.INSTRTYPEDESC,
			I.RESTRICTEDBYTYPE
		from "+@sUserName+".Imported_INSTRUCTIONTYPE I
		left join INSTRUCTIONTYPE C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		where C.INSTRUCTIONTYPE is null"

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
	select INSTRUCTIONTYPE,'{'+INSTRUCTIONTYPE+'}'+INSTRTYPEDESC
	from INSTRUCTIONTYPE
	order by INSTRUCTIONTYPE"

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
		I.INSTRTYPEDESC,
		CASE WHEN (I.INSTRUCTIONTYPE = I.ORIGINAL_KEY)THEN NULL 
			ELSE I.INSTRUCTIONTYPE END
	from "+@sUserName+".Imported_INSTRUCTIONTYPE I
	left join INSTRUCTIONTYPE C on C.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE
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
			AND MAPTABLE = 'INSTRUCTIONTYPE'
			AND MAPCOLUMN = 'INSTRUCTIONTYPE'
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
			'INSTRUCTIONTYPE',
			'INSTRUCTIONTYPE',
			XDM.NEWMAPVALUE
			from OPENXML(@hDocument, '//DataMapChange', 2)
			with (SOURCEVALUE nvarchar(50)'SourceValue/text()',
			      NEWMAPVALUE nvarchar(50)'NewMapValue/text()') XDM
			left join DATAMAP DM on (DM.SOURCENO = @pnSourceNo
					     and DM.SOURCEVALUE = XDM.SOURCEVALUE
					     and DM.MAPTABLE = 'INSTRUCTIONTYPE'
					     and DM.MAPCOLUMN = 'INSTRUCTIONTYPE')
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
grant execute on dbo.ip_RulesINSTRUCTIONTYPE  to public
go

