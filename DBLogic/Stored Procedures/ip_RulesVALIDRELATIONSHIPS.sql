-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDRELATIONSHIPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDRELATIONSHIPS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDRELATIONSHIPS.'
	drop procedure dbo.ip_RulesVALIDRELATIONSHIPS
end
print '**** Creating procedure dbo.ip_RulesVALIDRELATIONSHIPS...'
print ''
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesVALIDRELATIONSHIPS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDRELATIONSHIPS
-- VERSION :	8
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDRELATIONSHIPS table
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 04 Aug 2004	MF	10225	2	Correction.  Ensure default valid combinations are not lost.
-- 13 Apr 2006	MF	12562	3	Problem with back filling VALID table with missing default country details.
-- 03 May 2006	MF	12562	4	Revisit to also consider Property Type.
-- 10 Mar 2005	MF	16068	5	If the rule being imported for a specific Country is identical to
--					the rule that would default from country ZZZ and there are no other
--					country specific rules for the country being imported then do not load
--					the rule.
-- 24 Jan 2011	MF	19320	6	Introduce a Site Control "Law Update Valid Tables" to allow firms to determine how 
--					they want Valid tables to receive imported data when the explicit country does
--					not already exist on the receiving database. 
--					The options are: 0 - Create the explicit country and backfill from Default (ZZZ)
--							 1 - Deliver against the Default country if explicit country does not exist.
--							 2 - Only load imported data if explicit country already exists in Valid table.
-- 26 Sep 2011	MF	R11337	7	Remove the updating of Reciprocal Relationship from existing ValidRelationship
-- 14 Jan 2014	MF	R30039	8	Load default country (ZZZ) rows before any explicit countries that can fall back to using the
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

CREATE TABLE #TEMPVALIDRELATIONSHIPS
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL,
 	RELATIONSHIP		nvarchar(3)	collate database_default NOT NULL ,
 	RECIPRELATIONSHIP	nvarchar(3)	collate database_default NULL 
 )

-- Prerequisite that the IMPORTED_VALIDRELATIONSHIPS table has been loaded

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

If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_VALIDRELATIONSHIPS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDRELATIONSHIPS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDRELATIONSHIPS
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDRELATIONSHIPS C
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
			"UPDATE "+@sUserName+".Imported_VALIDRELATIONSHIPS
			SET RELATIONSHIP = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDRELATIONSHIPS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='CASERELATION'
					and M.MAPCOLUMN  ='RELATIONSHIP'
					and M.SOURCEVALUE=C.RELATIONSHIP)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDRELATIONSHIPS
			SET RECIPRELATIONSHIP = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDRELATIONSHIPS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='CASERELATION'
					and M.MAPCOLUMN  ='RELATIONSHIP'
					and M.SOURCEVALUE=C.RECIPRELATIONSHIP)
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
			CR.RELATIONSHIPDESC	as 'Imported Relationship',
			RR.RELATIONSHIPDESC	as 'Imported Reciprocal',
			C.COUNTRYCODE		as 'Country',
			P.PROPERTYNAME		as 'Property',
			CR.RELATIONSHIPDESC	as 'Relationship',
			RR.RELATIONSHIPDESC	as 'Reciprocal'
		from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		join "+@sUserName+".Imported_CASERELATION CR	on (CR.RELATIONSHIP=I.RELATIONSHIP)
		left join "+@sUserName+".Imported_CASERELATION RR on (RR.RELATIONSHIP=I.RECIPRELATIONSHIP)"
		Set @sSQLString2="	join VALIDRELATIONSHIPS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.RELATIONSHIP=I.RELATIONSHIP)
		where	(I.RECIPRELATIONSHIP=C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			CR.RELATIONSHIPDESC,
			RR.RELATIONSHIPDESC,
			C.COUNTRYCODE,
			P.PROPERTYNAME,
			CR.RELATIONSHIPDESC,
			RR1.RELATIONSHIPDESC
		from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		join "+@sUserName+".Imported_CASERELATION CR	on (CR.RELATIONSHIP=I.RELATIONSHIP)
		left join "+@sUserName+".Imported_CASERELATION RR on (RR.RELATIONSHIP=I.RECIPRELATIONSHIP)"
		Set @sSQLString4="	join VALIDRELATIONSHIPS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.RELATIONSHIP=I.RELATIONSHIP)
		left join CASERELATION RR1 on (RR1.RELATIONSHIP=C.RECIPRELATIONSHIP)
		where 	I.RECIPRELATIONSHIP<>C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is not null) OR (I.RECIPRELATIONSHIP is not null and C.RECIPRELATIONSHIP is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			CR.RELATIONSHIPDESC,
			RR.RELATIONSHIPDESC,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		join "+@sUserName+".Imported_CASERELATION CR	on (CR.RELATIONSHIP=I.RELATIONSHIP)
		left join "+@sUserName+".Imported_CASERELATION RR on (RR.RELATIONSHIP=I.RECIPRELATIONSHIP)"
		Set @sSQLString6="	left join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
					 and C.PROPERTYTYPE=I.PROPERTYTYPE
					 and C.RELATIONSHIP=I.RELATIONSHIP)
		left join VALIDRELATIONSHIPS C1 on (C1.COUNTRYCODE='ZZZ'
						and C1.PROPERTYTYPE=I.PROPERTYTYPE
						and C1.RELATIONSHIP=I.RELATIONSHIP)
		left join (select distinct COUNTRYCODE, PROPERTYTYPE
			   from VALIDRELATIONSHIPS) C2
						on (C2.COUNTRYCODE=I.COUNTRYCODE
						and C2.PROPERTYTYPE=I.PROPERTYTYPE)
		left join (select distinct I.COUNTRYCODE, I.PROPERTYTYPE
			   from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
			   left join VALIDRELATIONSHIPS C on (C.COUNTRYCODE='ZZZ'
							  and C.PROPERTYTYPE=I.PROPERTYTYPE
							  and C.RELATIONSHIP=I.RELATIONSHIP)
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

/********** RFC11337 Remove the updating of Reciprocal Relationship from existing ValidRelationship
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update VALIDRELATIONSHIPS
		set	RECIPRELATIONSHIP=I.RECIPRELATIONSHIP
		from	VALIDRELATIONSHIPS C
		join	"+@sUserName+".Imported_VALIDRELATIONSHIPS I	on ( I.COUNTRYCODE=C.COUNTRYCODE
						and I.PROPERTYTYPE=C.PROPERTYTYPE
						and I.RELATIONSHIP=C.RELATIONSHIP)
		where 	I.RECIPRELATIONSHIP<>C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is not null) OR (I.RECIPRELATIONSHIP is not null and C.RECIPRELATIONSHIP is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 
 ***************************** RFC11337 ***/
	
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

		-- Load into a temporary table the VALIDRELATIONSHIPS keys that are eligible to
		-- be loaded from the imported rules.  This is required to help determine
		-- where the default country VALIDRELATIONSHIP might be able to be used.
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPVALIDRELATIONSHIPS(COUNTRYCODE, PROPERTYTYPE, RELATIONSHIP, RECIPRELATIONSHIP)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.RELATIONSHIP,
				I.RECIPRELATIONSHIP
			from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
			left join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
						 and C.PROPERTYTYPE=I.PROPERTYTYPE
						 and C.RELATIONSHIP=I.RELATIONSHIP)
			-- No identical VALIDRELATIONSHIPS row for the default country
			left join VALIDRELATIONSHIPS C1 on (C1.COUNTRYCODE='ZZZ'
							and C1.PROPERTYTYPE=I.PROPERTYTYPE
							and C1.RELATIONSHIP=I.RELATIONSHIP)
			left join (select distinct COUNTRYCODE, PROPERTYTYPE
				   from VALIDRELATIONSHIPS) C2
							on (C2.COUNTRYCODE=I.COUNTRYCODE
							and C2.PROPERTYTYPE=I.PROPERTYTYPE)
			left join (select distinct I.COUNTRYCODE, I.PROPERTYTYPE
				   from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
				   left join VALIDRELATIONSHIPS C on (C.COUNTRYCODE='ZZZ'
								  and C.PROPERTYTYPE=I.PROPERTYTYPE
								  and C.RELATIONSHIP=I.RELATIONSHIP)
				   where C.COUNTRYCODE is null) C3
						on (C3.COUNTRYCODE=I.COUNTRYCODE
						and C3.PROPERTYTYPE=I.PROPERTYTYPE)
			where C.COUNTRYCODE is null
			and (C1.COUNTRYCODE is null
			 OR  C2.COUNTRYCODE is not NULL
			 OR  C3.COUNTRYCODE is not NULL)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- If a VALIDRELATIONSHIPS is to be loaded for a COUNTRY that previously did not
		-- have any VALIDRELATIONSHIPS rows then we need to copy across any VALIDRELATIONSHIPS
		-- rows that existed against the Default Country ('ZZZ') rule for this database.
		-- This is required so that we do not lose any entries that the Inprotech installation
		-- had set up to apply for all generic countries.

		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDRELATIONSHIPS(
				COUNTRYCODE,
				PROPERTYTYPE,
				RELATIONSHIP,
				RECIPRELATIONSHIP)
			select	I.COUNTRYCODE,
				C1.PROPERTYTYPE,
				C1.RELATIONSHIP,
				C1.RECIPRELATIONSHIP
			-- Get a distinct list of Countries/PropertyTypes that are being imported
			from (	select distinct COUNTRYCODE, PROPERTYTYPE
				from #TEMPVALIDRELATIONSHIPS) I
			-- Now get a distinct list of Country/PropertyTypes already in the database
			-- so we can identify those  being imported that have
			-- no existing entry in the database
			left join
			     (	select distinct COUNTRYCODE, PROPERTYTYPE
				from VALIDRELATIONSHIPS) C	on ( C.COUNTRYCODE=I.COUNTRYCODE
								and  C.PROPERTYTYPE=I.PROPERTYTYPE)
			join VALIDRELATIONSHIPS C1		on (C1.COUNTRYCODE='ZZZ'
								and C1.PROPERTYTYPE=I.PROPERTYTYPE)
			left join #TEMPVALIDRELATIONSHIPS I1
							on (I1.COUNTRYCODE =I.COUNTRYCODE
							and I1.PROPERTYTYPE=C1.PROPERTYTYPE
							and I1.RELATIONSHIP=C1.RELATIONSHIP)
			where C.COUNTRYCODE  is null
			and  I1.COUNTRYCODE  is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End

		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDRELATIONSHIPS(
				COUNTRYCODE,
				PROPERTYTYPE,
				RELATIONSHIP,
				RECIPRELATIONSHIP)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.RELATIONSHIP,
				I.RECIPRELATIONSHIP
			from #TEMPVALIDRELATIONSHIPS I
			left join VALIDRELATIONSHIPS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
							and C.PROPERTYTYPE=I.PROPERTYTYPE
							and C.RELATIONSHIP=I.RELATIONSHIP)
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
		-- attempt to load new Validation against the
		-- the default country.
		---------------------------------------------
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDRELATIONSHIPS(
				COUNTRYCODE,
				PROPERTYTYPE,
				RELATIONSHIP,
				RECIPRELATIONSHIP)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.RELATIONSHIP,
				I.RECIPRELATIONSHIP
			from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
			left join VALIDRELATIONSHIPS R	
						on ( R.COUNTRYCODE =I.COUNTRYCODE
						and  R.PROPERTYTYPE=I.PROPERTYTYPE
						and  R.RELATIONSHIP=I.RELATIONSHIP)
			where R.COUNTRYCODE is null
			and   I.COUNTRYCODE = 'ZZZ'"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
		
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDRELATIONSHIPS(
				COUNTRYCODE,
				PROPERTYTYPE,
				RELATIONSHIP,
				RECIPRELATIONSHIP)
			select	distinct
				isnull(VR.COUNTRYCODE,'ZZZ'), -- Use default Country if explicit country does not exist
				I.PROPERTYTYPE,
				I.RELATIONSHIP,
				I.RECIPRELATIONSHIP
			from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
			left join (select distinct COUNTRYCODE, PROPERTYTYPE
				   from VALIDRELATIONSHIPS) VR
						on (VR.COUNTRYCODE =I.COUNTRYCODE
						and VR.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDRELATIONSHIPS R	
						on ( R.COUNTRYCODE =isnull(VR.COUNTRYCODE,'ZZZ')
						and  R.PROPERTYTYPE=I.PROPERTYTYPE
						and  R.RELATIONSHIP=I.RELATIONSHIP)
			where R.COUNTRYCODE is null
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
			Insert into VALIDRELATIONSHIPS(
				COUNTRYCODE,
				PROPERTYTYPE,
				RELATIONSHIP,
				RECIPRELATIONSHIP)
			select	I.COUNTRYCODE, 
				I.PROPERTYTYPE,
				I.RELATIONSHIP,
				I.RECIPRELATIONSHIP
			from "+@sUserName+".Imported_VALIDRELATIONSHIPS I
			-- Explicit Country being imported Must already exist
			join (	select distinct COUNTRYCODE, PROPERTYTYPE
				from VALIDRELATIONSHIPS) VR
						on (VR.COUNTRYCODE =I.COUNTRYCODE
						and VR.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDRELATIONSHIPS R
						on ( R.COUNTRYCODE =I.COUNTRYCODE
						and  R.PROPERTYTYPE=I.PROPERTYTYPE
						and  R.RELATIONSHIP=I.RELATIONSHIP)
			where R.COUNTRYCODE is null"

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
grant execute on dbo.ip_RulesVALIDRELATIONSHIPS  to public
go
