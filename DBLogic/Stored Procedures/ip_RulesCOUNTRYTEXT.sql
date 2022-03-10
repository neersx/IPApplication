-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCOUNTRYTEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCOUNTRYTEXT]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCOUNTRYTEXT.'
	drop procedure dbo.ip_RulesCOUNTRYTEXT
	print '**** Creating procedure dbo.ip_RulesCOUNTRYTEXT...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCOUNTRYTEXT
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCOUNTRYTEXT
-- VERSION :	4
-- DESCRIPTION:	The comparison/display and merging of imported data for the COUNTRYTEXT table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 19 Jul 2004	MF		1	Procedure created
-- 29 Jul 2004	MF	10225	2	Correction.  Missing TEXTID on insert.
-- 21 Jan 2011	MF	19321	3	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 10 Mar 2011	MF	19463	4	Property Type was being shown through the Centura program as a diffence as the imported 
--					value was showing as null. This is being caused by the CountryText being returned with
--					more than 4000 characters.  For display purposes will only return the first 4000 characters.
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


-- Prerequisite that the IMPORTED_COUNTRYTEXT table has been loaded

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
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_COUNTRYTEXT
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_COUNTRYTEXT C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
	WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRYTEXT
			SET TEXTID = M.MAPVALUE
			FROM "+@sUserName+".Imported_COUNTRYTEXT C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.TEXTID)
		WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRYTEXT
			SET LANGUAGE = M.MAPVALUE
			FROM "+@sUserName+".Imported_COUNTRYTEXT C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.LANGUAGE)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_COUNTRYTEXT
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_COUNTRYTEXT C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='PROPERTYTYPE'
					and M.MAPCOLUMN  ='PROPERTYTYPE'
					and M.SOURCEVALUE=C.PROPERTYTYPE)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	End
End


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3		as 'Comparison',
			NULL		as Match,
			I.COUNTRYCODE	as 'Imported Country',
			T.DESCRIPTION	as 'Imported Text Type',
			I.PROPERTYTYPE	as 'Imported Property type',
			L.DESCRIPTION	as 'Imported Language',
			cast(C.COUNTRYTEXT as nvarchar(4000))
					as 'Imported Country Text',
			C.COUNTRYCODE	as 'Country',
			T.DESCRIPTION	as 'Text Type',
			C.PROPERTYTYPE	as 'Property Type',
			L.DESCRIPTION	as 'Language',
			cast(C.COUNTRYTEXT as nvarchar(4000))
					as 'Country Text'
		from "+@sUserName+".Imported_COUNTRYTEXT I
		     join TABLECODES T on (T.TABLECODE=I.TEXTID)
		left join TABLECODES L on (L.TABLECODE=I.LANGUAGE)"
		Set @sSQLString2="
		join COUNTRYTEXT C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.TEXTID=I.TEXTID
					and(C.LANGUAGE=I.LANGUAGE OR (C.LANGUAGE is null and I.LANGUAGE is null))
					and(C.PROPERTYTYPE=I.PROPERTYTYPE OR (C.PROPERTYTYPE is null and I.PROPERTYTYPE is null)))"
		Set @sSQLString3="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			T.DESCRIPTION,
			I.PROPERTYTYPE,
			L.DESCRIPTION,
			cast(I.COUNTRYTEXT as nvarchar(4000)),
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_COUNTRYTEXT I
		join "+@sUserName+".Imported_TABLECODES T on (T.TABLECODE=I.TEXTID)
		left join "+@sUserName+".Imported_TABLECODES L on (L.TABLECODE=I.LANGUAGE)"
		Set @sSQLString4="
		left join COUNTRYTEXT C on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.TEXTID=I.TEXTID
					and(C.LANGUAGE=I.LANGUAGE OR (C.LANGUAGE is null and I.LANGUAGE is null))
					and(C.PROPERTYTYPE=I.PROPERTYTYPE OR (C.PROPERTYTYPE is null and I.PROPERTYTYPE is null)))
		where C.COUNTRYCODE is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5,6" ELSE "3,4,5,6" END
	
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
	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into COUNTRYTEXT(
			COUNTRYCODE,
			TEXTID,
			SEQUENCE,
			PROPERTYTYPE,
			MODIFIEDDATE,
			LANGUAGE,
			USEFLAG)
		select	I.COUNTRYCODE,
			I.TEXTID,
			I.SEQUENCE,
			I.PROPERTYTYPE,
			I.MODIFIEDDATE,
			I.LANGUAGE,
			I.USEFLAG
		from "+@sUserName+".Imported_COUNTRYTEXT I
		left join COUNTRYTEXT C	on ( C.COUNTRYCODE=I.COUNTRYCODE
					and  C.TEXTID=I.TEXTID
					and C.SEQUENCE=I.SEQUENCE)
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
	Set @sSQLString=null

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesCOUNTRYTEXT  to public
go

