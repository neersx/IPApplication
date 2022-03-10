-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesTMCLASS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesTMCLASS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesTMCLASS.'
	drop procedure dbo.ip_RulesTMCLASS
	print '**** Creating procedure dbo.ip_RulesTMCLASS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesTMCLASS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesTMCLASS
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the TMCLASS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 19 Jul 2004	MF		1	Procedure created
-- 20 Jan 2011	MF	19331	2	Apply changes to standard class headings. Currently only new headings are delivered.
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


-- Prerequisite that the IMPORTED_TMCLASS table has been loaded

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
	-- Apply the Mapping if it exists.
	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_TMCLASS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_TMCLASS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_TMCLASS
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_TMCLASS C
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
		select	3			as 'Comparison',
			NULL			as Match,
			I.COUNTRYCODE		as 'Imported Country',
			I.CLASS			as 'Imported Class',
			I.PROPERTYTYPE		as 'Imported Property Type',
			I.EFFECTIVEDATE		as 'Imported Effective Date',
			I.GOODSSERVICES		as 'Imported Goods Services',
			I.INTERNATIONALCLASS	as 'Imported International Class',
			I.ASSOCIATEDCLASSES	as 'Imported Associated Classes',
			I.SUBCLASS		as 'Imported Subclass',
			cast(I.CLASSHEADING as nvarchar(max)) as 'Imported Class Heading',
			C.COUNTRYCODE		as 'Country',
			C.CLASS			as 'Class',
			C.PROPERTYTYPE		as 'Property Type',
			C.EFFECTIVEDATE		as 'Effective Date',
			C.GOODSSERVICES		as 'Goods Services',
			C.INTERNATIONALCLASS	as 'International Class',
			C.ASSOCIATEDCLASSES	as 'Associated Classes',
			C.SUBCLASS		as 'Subclass',
			cast(C.CLASSHEADING as nvarchar(max)) as 'Class Heading'
		from "+@sUserName+".Imported_TMCLASS I"
		Set @sSQLString2="
		join TMCLASS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.CLASS=I.CLASS
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.SEQUENCENO=I.SEQUENCENO)
		where(I.EFFECTIVEDATE=C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is null))
		and  (I.GOODSSERVICES=C.GOODSSERVICES OR (I.GOODSSERVICES is null and C.GOODSSERVICES is null))
		and  (I.INTERNATIONALCLASS=C.INTERNATIONALCLASS OR (I.INTERNATIONALCLASS is null and C.INTERNATIONALCLASS is null))
		and  (I.ASSOCIATEDCLASSES=C.ASSOCIATEDCLASSES OR (I.ASSOCIATEDCLASSES is null and C.ASSOCIATEDCLASSES is null))
		and  (I.SUBCLASS=C.SUBCLASS OR (I.SUBCLASS is null and C.SUBCLASS is null))
		and   I.CLASSHEADING like C.CLASSHEADING"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			I.CLASS,
			I.PROPERTYTYPE,
			I.EFFECTIVEDATE,
			I.GOODSSERVICES,
			I.INTERNATIONALCLASS,
			I.ASSOCIATEDCLASSES,
			I.SUBCLASS,
			cast(I.CLASSHEADING as nvarchar(max)),
			C.COUNTRYCODE,
			C.CLASS,
			C.PROPERTYTYPE,
			C.EFFECTIVEDATE,
			C.GOODSSERVICES,
			C.INTERNATIONALCLASS,
			C.ASSOCIATEDCLASSES,
			C.SUBCLASS,
			cast(C.CLASSHEADING as nvarchar(max))
		from "+@sUserName+".Imported_TMCLASS I"
		Set @sSQLString4="
		join TMCLASS C		on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.CLASS=I.CLASS
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.SEQUENCENO=I.SEQUENCENO)
		where 		I.EFFECTIVEDATE<>C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is not null) OR (I.EFFECTIVEDATE is not null and C.EFFECTIVEDATE is null)
		OR		I.GOODSSERVICES<>C.GOODSSERVICES OR (I.GOODSSERVICES is null and C.GOODSSERVICES is not null) OR (I.GOODSSERVICES is not null and C.GOODSSERVICES is null)
		OR		I.INTERNATIONALCLASS<>C.INTERNATIONALCLASS OR (I.INTERNATIONALCLASS is null and C.INTERNATIONALCLASS is not null) OR (I.INTERNATIONALCLASS is not null and C.INTERNATIONALCLASS is null)
		OR		I.ASSOCIATEDCLASSES<>C.ASSOCIATEDCLASSES OR (I.ASSOCIATEDCLASSES is null and C.ASSOCIATEDCLASSES is not null) OR (I.ASSOCIATEDCLASSES is not null and C.ASSOCIATEDCLASSES is null)
		OR		I.SUBCLASS<>C.SUBCLASS OR (I.SUBCLASS is null and C.SUBCLASS is not null) OR (I.SUBCLASS is not null and C.SUBCLASS is null)
		OR		I.CLASSHEADING not like C.CLASSHEADING"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			I.CLASS,
			I.PROPERTYTYPE,
			I.EFFECTIVEDATE,
			I.GOODSSERVICES,
			I.INTERNATIONALCLASS,
			I.ASSOCIATEDCLASSES,
			I.SUBCLASS,
			cast(I.CLASSHEADING as nvarchar(max)),
			C.COUNTRYCODE,
			C.CLASS,
			C.PROPERTYTYPE,
			C.EFFECTIVEDATE,
			C.GOODSSERVICES,
			C.INTERNATIONALCLASS,
			C.ASSOCIATEDCLASSES,
			C.SUBCLASS,
			cast(C.CLASSHEADING as nvarchar(max))
		from "+@sUserName+".Imported_TMCLASS I"
		Set @sSQLString6="
		left join TMCLASS C 	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.CLASS=I.CLASS
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.SEQUENCENO=I.SEQUENCENO)
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
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update TMCLASS
		set	EFFECTIVEDATE=I.EFFECTIVEDATE,
			GOODSSERVICES=I.GOODSSERVICES,
			INTERNATIONALCLASS=I.INTERNATIONALCLASS,
			ASSOCIATEDCLASSES=I.ASSOCIATEDCLASSES,
			SUBCLASS=I.SUBCLASS,
			CLASSHEADING=I.CLASSHEADING
		from	TMCLASS C
		join	"+@sUserName+".Imported_TMCLASS I	on ( I.COUNTRYCODE=C.COUNTRYCODE
						and I.CLASS=C.CLASS
						and I.PROPERTYTYPE=C.PROPERTYTYPE
						and I.SEQUENCENO=C.SEQUENCENO)
		where 	I.EFFECTIVEDATE<>C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is not null) OR (I.EFFECTIVEDATE is not null and C.EFFECTIVEDATE is null)
		OR	I.GOODSSERVICES<>C.GOODSSERVICES OR (I.GOODSSERVICES is null and C.GOODSSERVICES is not null) OR (I.GOODSSERVICES is not null and C.GOODSSERVICES is null)
		OR	I.INTERNATIONALCLASS<>C.INTERNATIONALCLASS OR (I.INTERNATIONALCLASS is null and C.INTERNATIONALCLASS is not null) OR (I.INTERNATIONALCLASS is not null and C.INTERNATIONALCLASS is null)
		OR	I.ASSOCIATEDCLASSES<>C.ASSOCIATEDCLASSES OR (I.ASSOCIATEDCLASSES is null and C.ASSOCIATEDCLASSES is not null) OR (I.ASSOCIATEDCLASSES is not null and C.ASSOCIATEDCLASSES is null)
		OR	I.SUBCLASS<>C.SUBCLASS OR (I.SUBCLASS is null and C.SUBCLASS is not null) OR (I.SUBCLASS is not null and C.SUBCLASS is null)
		OR	I.CLASSHEADING not like C.CLASSHEADING"

		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into TMCLASS(
			COUNTRYCODE,
			CLASS,
			PROPERTYTYPE,
			SEQUENCENO,
			EFFECTIVEDATE,
			GOODSSERVICES,
			INTERNATIONALCLASS,
			ASSOCIATEDCLASSES,
			SUBCLASS,
			CLASSHEADING,
			CLASSNOTES)
		select	I.COUNTRYCODE,
			I.CLASS,
			I.PROPERTYTYPE,
			I.SEQUENCENO,
			I.EFFECTIVEDATE,
			I.GOODSSERVICES,
			I.INTERNATIONALCLASS,
			I.ASSOCIATEDCLASSES,
			I.SUBCLASS,
			I.CLASSHEADING,
			I.CLASSNOTES
		from "+@sUserName+".Imported_TMCLASS I
		left join TMCLASS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
						and C.CLASS=I.CLASS
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.SEQUENCENO=I.SEQUENCENO)
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
grant execute on dbo.ip_RulesTMCLASS  to public
go

