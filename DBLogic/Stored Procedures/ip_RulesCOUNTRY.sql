-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCOUNTRY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCOUNTRY]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCOUNTRY.'
	drop procedure dbo.ip_RulesCOUNTRY
	print '**** Creating procedure dbo.ip_RulesCOUNTRY...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCOUNTRY
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCOUNTRY
-- VERSION :	5
-- DESCRIPTION:	The comparison/display and merging of imported data for the COUNTRY table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 16 Jul 2004	MF		1	Procedure created
-- 27-Nov-2006	MF	13919	2	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
-- 05-Feb-2007	MF	14231	3	Date Ceased and Date Commenced should be allowed in the Update
-- 25-Oct-2007	MF	15512	4	The ALTERNATECODE for the country is not to be overwritten
-- 21 Jan 2011	MF	19321	5	Data columns that are not to be replaced will now be reported with the client data 
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


-- Prerequisite that the IMPORTED_COUNTRY table has been loaded

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
			 where (name = 'ORIGINAL_KEY') and id = object_id('"+@sUserName+".Imported_COUNTRY')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bOriginalKeyColumnExists	bit OUTPUT',
			  @bOriginalKeyColumnExists 	= @bOriginalKeyColumnExists OUTPUT

	If  @ErrorCode=0
	and @bOriginalKeyColumnExists=0
	Begin
		Set @sSQLString="ALTER TABLE "+@sUserName+".Imported_COUNTRY ADD ORIGINAL_KEY NVARCHAR(50)"
		exec @ErrorCode=sp_executesql @sSQLString

		-- Now save the original key value
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRY
			SET ORIGINAL_KEY=RTRIM(COUNTRYCODE)"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRY
			SET COUNTRYCODE = isnull(M.MAPVALUE, C.ORIGINAL_KEY)
			FROM "+@sUserName+".Imported_COUNTRY C
			LEFT JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
						and M.MAPTABLE   ='COUNTRY'
						and M.MAPCOLUMN  ='COUNTRYCODE'
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
			I.COUNTRYCODE		as 'Imported Country Code',
			C.COUNTRY		as 'Imported Country',
			CASE(I.RECORDTYPE)
				WHEN(0)	THEN 'General Use'
				WHEN(1)	THEN 'Group Country'
					ELSE 'IP Only'
			END			as 'Imported Record Type',
			I.DATECOMMENCED		as 'Imported Commenced',
			I.DATECEASED		as 'Imported Ceased',
			C.COUNTRYCODE		as 'Country Code',
			C.COUNTRY		as 'Country',
			CASE(C.RECORDTYPE)
				WHEN(0)	THEN 'General Use'
				WHEN(1)	THEN 'Group Country'
					ELSE 'IP Only'
			END			as 'Record Type',
			C.DATECOMMENCED		as 'Commenced',
			C.DATECEASED		as 'Ceased'
		from "+@sUserName+".Imported_COUNTRY I"
		Set @sSQLString2="	join COUNTRY C	on( C.COUNTRYCODE=I.COUNTRYCODE)
		where	(I.RECORDTYPE=C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is null))
		and	(I.DATECOMMENCED=C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is null))
		and	(I.DATECEASED=C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			C.COUNTRY,
			CASE(I.RECORDTYPE)
				WHEN(0)	THEN 'General Use'
				WHEN(1)	THEN 'Group Country'
					ELSE 'IP Only'
			END,
			I.DATECOMMENCED,
			I.DATECEASED,
			C.COUNTRYCODE,
			C.COUNTRY,
			CASE(C.RECORDTYPE)
				WHEN(0)	THEN 'General Use'
				WHEN(1)	THEN 'Group Country'
					ELSE 'IP Only'
			END,
			C.DATECOMMENCED,
			C.DATECEASED
		from "+@sUserName+".Imported_COUNTRY I"
		Set @sSQLString4="	join COUNTRY C	on( C.COUNTRYCODE=I.COUNTRYCODE)
		where 	I.RECORDTYPE<>C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is not null) OR (I.RECORDTYPE is not null and C.RECORDTYPE is null)
		OR	I.DATECOMMENCED<>C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is not null) OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null)
		OR	I.DATECEASED<>C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is not null) OR (I.DATECEASED is not null and C.DATECEASED is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			I.COUNTRY,
			CASE(I.RECORDTYPE)
				WHEN(0)	THEN 'General Use'
				WHEN(1)	THEN 'Group Country'
					ELSE 'IP Only'
			END,
			I.DATECOMMENCED,
			I.DATECEASED,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
		from "+@sUserName+".Imported_COUNTRY I"
		Set @sSQLString6="	left join COUNTRY C on( C.COUNTRYCODE=I.COUNTRYCODE)
		where C.COUNTRYCODE is null
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
		Update COUNTRY
		set	RECORDTYPE=I.RECORDTYPE,
			DATECOMMENCED=I.DATECOMMENCED,
			DATECEASED=I.DATECEASED
		from	COUNTRY C
		join	"+@sUserName+".Imported_COUNTRY I	on ( I.COUNTRYCODE=C.COUNTRYCODE)
		where 	I.RECORDTYPE<>C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is not null) OR (I.RECORDTYPE is not null and C.RECORDTYPE is null)
		OR	I.DATECOMMENCED<>C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is not null) OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null)
		OR	I.DATECEASED<>C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is not null) OR (I.DATECEASED is not null and C.DATECEASED is null)"

		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into COUNTRY(
			COUNTRYCODE,
			ALTERNATECODE,
			COUNTRY,
			INFORMALNAME,
			COUNTRYABBREV,
			COUNTRYADJECTIVE,
			RECORDTYPE,
			ISD,
			STATELITERAL,
			POSTCODELITERAL,
			POSTCODEFIRST,
			WORKDAYFLAG,
			DATECOMMENCED,
			DATECEASED,
			NOTES,
			STATEABBREVIATED,
			ALLMEMBERSFLAG,
			NAMESTYLE,
			ADDRESSSTYLE,
			DEFAULTTAXCODE,
			REQUIREEXEMPTTAXNO,
			DEFAULTCURRENCY,
			POSTCODESEARCHCODE,
			POSTCODEAUTOFLAG)
		select	I.COUNTRYCODE,
			I.ALTERNATECODE,
			I.COUNTRY,
			I.INFORMALNAME,
			I.COUNTRYABBREV,
			I.COUNTRYADJECTIVE,
			I.RECORDTYPE,
			I.ISD,
			I.STATELITERAL,
			I.POSTCODELITERAL,
			I.POSTCODEFIRST,
			I.WORKDAYFLAG,
			I.DATECOMMENCED,
			I.DATECEASED,
			I.NOTES,
			I.STATEABBREVIATED,
			I.ALLMEMBERSFLAG,
			I.NAMESTYLE,
			I.ADDRESSSTYLE,
			I.DEFAULTTAXCODE,
			I.REQUIREEXEMPTTAXNO,
			I.DEFAULTCURRENCY,
			I.POSTCODESEARCHCODE,
			I.POSTCODEAUTOFLAG
		from "+@sUserName+".Imported_COUNTRY I
		left join COUNTRY C	on ( C.COUNTRYCODE=I.COUNTRYCODE)
		where C.COUNTRYCODE is null"

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
	select COUNTRYCODE,'{'+COUNTRYCODE+'}'+COUNTRY
	from COUNTRY
	order by COUNTRYCODE"

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
		I.COUNTRY,
		CASE WHEN (I.COUNTRYCODE = I.ORIGINAL_KEY)THEN NULL 
			ELSE I.COUNTRYCODE END
	from "+@sUserName+".Imported_COUNTRY I
	left join COUNTRY C on C.COUNTRYCODE = I.COUNTRYCODE
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
			AND MAPTABLE = 'COUNTRY'
			AND MAPCOLUMN = 'COUNTRYCODE'
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
			'COUNTRY',
			'COUNTRYCODE',
			XDM.NEWMAPVALUE
			from OPENXML(@hDocument, '//DataMapChange', 2)
			with (SOURCEVALUE nvarchar(50)'SourceValue/text()',
			      NEWMAPVALUE nvarchar(50)'NewMapValue/text()') XDM
			left join DATAMAP DM on (DM.SOURCENO = @pnSourceNo
					     and DM.SOURCEVALUE = XDM.SOURCEVALUE
					     and DM.MAPTABLE = 'COUNTRY'
					     and DM.MAPCOLUMN = 'COUNTRYCODE')
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
grant execute on dbo.ip_RulesCOUNTRY  to public
go

