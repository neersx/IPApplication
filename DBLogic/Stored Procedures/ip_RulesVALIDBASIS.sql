-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDBASIS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDBASIS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDBASIS.'
	drop procedure dbo.ip_RulesVALIDBASIS
end
print '**** Creating procedure dbo.ip_RulesVALIDBASIS...'
print ''
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesVALIDBASIS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDBASIS
-- VERSION :	7
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDBASIS table
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- -----------  ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 04 Aug 2004	MF	10225	2	Correction.  Ensure default valid combinations are not lost.
-- 13 Apr 2006	MF	12562	3	Problem with back filling VALID table with missing default country details.
-- 03 May 2006	MF	12562	4	Revisit to also consider Property Type
-- 06 Mar 2005	MF	16068	5	If the rule being imported for a specific Country is identical to
--					the rule that would default from country ZZZ and there are no other
--					country specific rules for the country being imported then do not load
--					the rule.
-- 21 Jan 2011	MF	19321	6	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 24 Jan 2011	MF	19320	6	Introduce a Site Control "Law Update Valid Tables" to allow firms to determine how 
--					they want Valid tables to receive imported data when the explicit country does
--					not already exist on the receiving database. 
--					The options are: 0 - Create the explicit country and backfill from Default (ZZZ)
--							 1 - Deliver against the Default country if explicit country does not exist.
--							 2 - Only load imported data if explicit country already exists in Valid table.
-- 14 Jan 2014	MF	R30039	7	Load default country (ZZZ) rows before any explicit countries that can fall back to using the
--					default country.
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

CREATE TABLE #TEMPVALIDBASIS
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL,
 	BASIS			nvarchar(2)	collate database_default NOT NULL,
 	BASISDESCRIPTION	nvarchar(50)	collate database_default NULL
 )

-- Prerequisite that the IMPORTED_VALIDBASIS table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString1		varchar(8000)
Declare @sSQLString2		varchar(8000)
Declare @sSQLString3		varchar(8000)
Declare @sSQLString4		varchar(8000)
Declare @sSQLString5		varchar(8000)
Declare @sSQLString6		varchar(8000)

Declare	@ErrorCode			int
Declare @nLoadOption			int
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
		"UPDATE "+@sUserName+".Imported_VALIDBASIS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDBASIS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDBASIS
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDBASIS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='PROPERTYTYPE'
					and M.MAPCOLUMN  ='PROPERTYTYPE'
					and M.SOURCEVALUE=C.PROPERTYTYPE)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDBASIS
			SET BASIS = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDBASIS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='APPLICATIONBASIS'
					and M.MAPCOLUMN  ='BASIS'
					and M.SOURCEVALUE=C.BASIS)
			WHERE M.MAPVALUE is not null"

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
			I.COUNTRYCODE		as 'Imported Country',
			P.PROPERTYNAME		as 'Imported Property',
			C.BASISDESCRIPTION	as 'Imported Basis',
			C.COUNTRYCODE		as 'Country',
			P.PROPERTYNAME		as 'Property',
			C.BASISDESCRIPTION	as 'Basis'
		from "+@sUserName+".Imported_VALIDBASIS I
		join "+@sUserName+".Imported_PROPERTYTYPE P on (P.PROPERTYTYPE=I.PROPERTYTYPE)"
		Set @sSQLString2="
		join VALIDBASIS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.BASIS=I.BASIS)"
		Set @sSQLString3="
		UNION
		select	1,
			'X',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			I.BASISDESCRIPTION,
			C.COUNTRYCODE,
			P.PROPERTYNAME,
			C.BASISDESCRIPTION
		from "+@sUserName+".Imported_VALIDBASIS I
		join "+@sUserName+".Imported_PROPERTYTYPE P on (P.PROPERTYTYPE=I.PROPERTYTYPE)"
		Set @sSQLString4="	left join VALIDBASIS C on( C.COUNTRYCODE=I.COUNTRYCODE
					 and C.PROPERTYTYPE=I.PROPERTYTYPE
					 and C.BASIS=I.BASIS)
		left join VALIDBASIS C1 on (C1.COUNTRYCODE='ZZZ'
					and C1.PROPERTYTYPE=I.PROPERTYTYPE
					and C1.BASIS=I.BASIS)
		left join (select distinct COUNTRYCODE,PROPERTYTYPE
			   from VALIDBASIS) C2
					on (C2.COUNTRYCODE=I.COUNTRYCODE
					and C2.PROPERTYTYPE=I.PROPERTYTYPE)
		left join (select distinct I.COUNTRYCODE,I.PROPERTYTYPE
			   from "+@sUserName+".Imported_VALIDBASIS I
			   left join VALIDBASIS C on (C.COUNTRYCODE='ZZZ'
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.BASIS=I.BASIS)
			   where C.COUNTRYCODE is null) C3
					on (C3.COUNTRYCODE=I.COUNTRYCODE
					and C3.PROPERTYTYPE=I.PROPERTYTYPE)
		where C.COUNTRYCODE is null
		and (C1.COUNTRYCODE is null
		 OR  C2.COUNTRYCODE is not NULL
		 OR  C3.COUNTRYCODE is not NULL)
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5" ELSE "3,4,5" END
	
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
		----------------------------------------
		-- SQA19320
		-- Extract the Site Control to determine
		-- how the Valid table is to handle data
		-- for a country that does not already 
		-- have validaction entries in the table.
		----------------------------------------
		Set @sSQLString="
		Select @nLoadOption=COLINTEGER
		from SITECONTROL
		where CONTROLID='Law Update Valid Tables'"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nLoadOption		int	OUTPUT',
					  @nLoadOption=@nLoadOption	OUTPUT

		If @nLoadOption is null
			Set @nLoadOption=0
	End

	If @nLoadOption=0
	Begin

		-- Load into a temporary table the VALIDACTION keys that are eligible to
		-- be loaded from the imported rules.  This is required to help determine
		-- where the default country VALIDACTION might be able to be used.
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPVALIDBASIS(COUNTRYCODE,PROPERTYTYPE,BASIS,BASISDESCRIPTION)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.BASIS,
				I.BASISDESCRIPTION
			from "+@sUserName+".Imported_VALIDBASIS I
			left join VALIDBASIS C	on( C.COUNTRYCODE=I.COUNTRYCODE
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.BASIS=I.BASIS)
			-- No identical VALIDBASIS row for the default country
			left join VALIDBASIS C1 on (C1.COUNTRYCODE='ZZZ'
						and C1.PROPERTYTYPE=I.PROPERTYTYPE
						and C1.BASIS=I.BASIS)
			left join (select distinct COUNTRYCODE,PROPERTYTYPE
				   from VALIDBASIS) C2
						on (C2.COUNTRYCODE=I.COUNTRYCODE
						and C2.PROPERTYTYPE=I.PROPERTYTYPE)
			left join (select distinct I.COUNTRYCODE,I.PROPERTYTYPE
				   from "+@sUserName+".Imported_VALIDBASIS I
				   left join VALIDBASIS C on (C.COUNTRYCODE='ZZZ'
							and C.PROPERTYTYPE=I.PROPERTYTYPE
							and C.BASIS=I.BASIS)
				   where C.COUNTRYCODE is null) C3
						on (C3.COUNTRYCODE=I.COUNTRYCODE
						and C3.PROPERTYTYPE=I.PROPERTYTYPE)
			where C.COUNTRYCODE is null
			and (C1.COUNTRYCODE is null
			 OR  C2.COUNTRYCODE is not NULL
			 OR  C3.COUNTRYCODE is not NULL)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End
		-- If a VALIDBASIS is to be loaded for a COUNTRY that previously did not
		-- have any VALIDBASIS rows then we need to copy across any VALIDBASIS
		-- rows that existed against the Default Country ('ZZZ') rule for this database.
		-- This is required so that we do not lose any entries that the Inprotech installation
		-- had set up to apply for all generic countries.

		If @ErrorCode=0
		Begin

			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDBASIS(
				COUNTRYCODE,
				PROPERTYTYPE,
				BASIS,
				BASISDESCRIPTION)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				C1.BASIS,
				C1.BASISDESCRIPTION
			-- Get a distinct list of Countries/PropertyType that are being imported
			from (	select distinct COUNTRYCODE, PROPERTYTYPE
				from #TEMPVALIDBASIS) I
			-- Now get a distinct list of Countries/PropertyTypes already in the database
			-- so we can identify those Countries being imported that have
			-- no existing entry in the database
			left join
			     (	select distinct COUNTRYCODE, PROPERTYTYPE
				from VALIDBASIS) C	on ( C.COUNTRYCODE =I.COUNTRYCODE
							and  C.PROPERTYTYPE=I.PROPERTYTYPE)
			join VALIDBASIS C1		on (C1.COUNTRYCODE='ZZZ'
							and C1.PROPERTYTYPE=I.PROPERTYTYPE)
			left join #TEMPVALIDBASIS I1	on (I1.COUNTRYCODE =I.COUNTRYCODE
							and I1.PROPERTYTYPE=C1.PROPERTYTYPE
							and I1.BASIS       =C1.BASIS)
			where C.COUNTRYCODE  is null
			and  I1.COUNTRYCODE  is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End

		If @ErrorCode=0
		Begin

			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDBASIS(
				COUNTRYCODE,
				PROPERTYTYPE,
				BASIS,
				BASISDESCRIPTION)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.BASIS,
				I.BASISDESCRIPTION
			from #TEMPVALIDBASIS I
			left join VALIDBASIS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
							and C.PROPERTYTYPE=I.PROPERTYTYPE
							and C.BASIS=I.BASIS)
			where C.COUNTRYCODE is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
	End	-- @nLoadOption = 0 
	Else If @nLoadOption=1
	Begin
		---------------------------------------------
		-- If the explicit country to be loaded does
		-- not already exist in the Valid table then 
		-- attempt to load new ValidProperty against 
		-- the default country.
		---------------------------------------------
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDBASIS(
				COUNTRYCODE,
				PROPERTYTYPE,
				BASIS,
				BASISDESCRIPTION)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.BASIS,
				I.BASISDESCRIPTION
			from "+@sUserName+".Imported_VALIDBASIS I
			left join VALIDBASIS B	on ( B.COUNTRYCODE =I.COUNTRYCODE
						and  B.PROPERTYTYPE=I.PROPERTYTYPE
						and  B.BASIS       =I.BASIS)
			where B.COUNTRYCODE is null
			and   I.COUNTRYCODE = 'ZZZ'"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
		
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDBASIS(
				COUNTRYCODE,
				PROPERTYTYPE,
				BASIS,
				BASISDESCRIPTION)
			select	distinct
				isnull(VB.COUNTRYCODE,'ZZZ'), -- Use default Country if explicit country does not exist
				I.PROPERTYTYPE,
				I.BASIS,
				I.BASISDESCRIPTION
			from "+@sUserName+".Imported_VALIDBASIS I
			left join (select distinct COUNTRYCODE, PROPERTYTYPE
				   from VALIDBASIS) VB
						on (VB.COUNTRYCODE =I.COUNTRYCODE
						and VB.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDBASIS B	on ( B.COUNTRYCODE =isnull(VB.COUNTRYCODE,'ZZZ')
						and  B.PROPERTYTYPE=I.PROPERTYTYPE
						and  B.BASIS       =I.BASIS)
			where B.COUNTRYCODE is null
			and   I.COUNTRYCODE <>'ZZZ'"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
	End	-- @nLoadOption = 1
	Else If @nLoadOption=2
	Begin
		---------------------------------------------
		-- If the explicit country to be loaded does
		-- not already exist in the Valid table then 
		-- do not load the Valid table with the 
		-- imported data
		---------------------------------------------
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDBASIS(
				COUNTRYCODE,
				PROPERTYTYPE,
				BASIS,
				BASISDESCRIPTION)
			select	I.COUNTRYCODE, 
				I.PROPERTYTYPE,
				I.BASIS,
				I.BASISDESCRIPTION
			from "+@sUserName+".Imported_VALIDBASIS I
			-- Explicit Country being imported Must already exist
			join (	select distinct COUNTRYCODE, PROPERTYTYPE
				from VALIDBASIS) VB
						on (VB.COUNTRYCODE =I.COUNTRYCODE
						and VB.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDBASIS B
						on ( B.COUNTRYCODE =I.COUNTRYCODE
						and  B.PROPERTYTYPE=I.PROPERTYTYPE
						and  B.BASIS       =I.BASIS)
			where B.COUNTRYCODE is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
	End	-- @nLoadOption = 2
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
grant execute on dbo.ip_RulesVALIDBASIS  to public
go
