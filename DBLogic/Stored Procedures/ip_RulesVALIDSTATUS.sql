-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDSTATUS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDSTATUS.'
	drop procedure dbo.ip_RulesVALIDSTATUS
end
print '**** Creating procedure dbo.ip_RulesVALIDSTATUS...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.ip_RulesVALIDSTATUS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDSTATUS
-- VERSION :	7
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDSTATUS table
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 04 Aug 2004	MF	10225	2	Correction.  Ensure default valid combinations are not lost.
-- 13 Apr 2006	MF	12562	3	Problem with back filling VALID table with missing default country details.
-- 03 May 2006	MF	12562	4	Revisit to also consider Property Type
-- 10 Mar 2005	MF	16068	5	If the rule being imported for a specific Country is identical to
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


CREATE TABLE #TEMPVALIDSTATUS
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL,
 	CASETYPE		nchar(1)	collate database_default NOT NULL,
 	STATUSCODE		smallint	NOT NULL 
 )

-- Prerequisite that the IMPORTED_VALIDSTATUS table has been loaded

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
		"UPDATE "+@sUserName+".Imported_VALIDSTATUS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDSTATUS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='COUNTRY'
					and M.MAPCOLUMN  ='COUNTRYCODE'
					and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDSTATUS
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDSTATUS C
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
			"UPDATE "+@sUserName+".Imported_VALIDSTATUS
			SET STATUSCODE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDSTATUS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='STATUS'
					and M.MAPCOLUMN  ='STATUSCODE'
					and M.SOURCEVALUE=C.STATUSCODE)
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
		select	3		as 'Comparison',
			NULL		as Match,
			I.COUNTRYCODE	as 'Imported Country',
			P.PROPERTYNAME	as 'Imported Property',
			CT.CASETYPEDESC	as 'Imported Case Type',
			S.INTERNALDESC	as 'Imported Status',
			C.COUNTRYCODE	as 'Country',
			P.PROPERTYNAME	as 'Property',
			CT.CASETYPEDESC	as 'Case Type',
			S.INTERNALDESC	as 'Status'
		from "+@sUserName+".Imported_VALIDSTATUS I
		join STATUS S	 on (S.STATUSCODE=I.STATUSCODE)
		join CASETYPE CT on (CT.CASETYPE=I.CASETYPE)
		join PROPERTYTYPE P  on (P.PROPERTYTYPE=I.PROPERTYTYPE)"
		Set @sSQLString2="
		join VALIDSTATUS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.CASETYPE=I.CASETYPE
					and C.STATUSCODE=I.STATUSCODE)"
		Set @sSQLString3="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			CT.CASETYPEDESC,
			S.INTERNALDESC,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_VALIDSTATUS I
		join "+@sUserName+".Imported_STATUS S	on (S.STATUSCODE=I.STATUSCODE)
		join CASETYPE CT on (CT.CASETYPE=I.CASETYPE)
		join "+@sUserName+".Imported_PROPERTYTYPE P  on (P.PROPERTYTYPE=I.PROPERTYTYPE)"
		Set @sSQLString4="
		left join VALIDSTATUS C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.CASETYPE=I.CASETYPE
					and C.STATUSCODE=I.STATUSCODE)
		left join VALIDSTATUS C1 on (C1.COUNTRYCODE='ZZZ'
					and C1.PROPERTYTYPE=I.PROPERTYTYPE
					and C1.CASETYPE=I.CASETYPE
					and C1.STATUSCODE=I.STATUSCODE)
		left join (select distinct COUNTRYCODE,PROPERTYTYPE,CASETYPE
			   from VALIDSTATUS) C2
					on (C2.COUNTRYCODE=I.COUNTRYCODE
					and C2.PROPERTYTYPE=I.PROPERTYTYPE
					and C2.CASETYPE=I.CASETYPE)
		left join (select distinct I.COUNTRYCODE, I.PROPERTYTYPE, I.CASETYPE
			   from "+@sUserName+".Imported_VALIDSTATUS I
			   left join VALIDSTATUS C on (C.COUNTRYCODE='ZZZ'
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.CASETYPE=I.CASETYPE
						and C.STATUSCODE=I.STATUSCODE)
			   where C.COUNTRYCODE is null) C3
					on (C3.COUNTRYCODE=I.COUNTRYCODE
					and C3.PROPERTYTYPE=I.PROPERTYTYPE
					and C3.CASETYPE=I.CASETYPE)
		where C.COUNTRYCODE is null
		and (C1.COUNTRYCODE is null
		 OR  C2.COUNTRYCODE is not NULL
		 OR  C3.COUNTRYCODE is not NULL)
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
		-- Load into a temporary table the VALIDPROPERTY keys that are eligible to
		-- be loaded from the imported rules.  This is required to help determine
		-- where the default country VALIDPROPERTY might be able to be used.
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPVALIDSTATUS(COUNTRYCODE,PROPERTYTYPE,CASETYPE,STATUSCODE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
 				I.CASETYPE,
 				I.STATUSCODE
			from "+@sUserName+".Imported_VALIDSTATUS I
			left join VALIDSTATUS C	on( C.COUNTRYCODE=I.COUNTRYCODE
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.CASETYPE=I.CASETYPE
						and C.STATUSCODE=I.STATUSCODE)
			-- No identical VALIDSTATUS row for the default country
			left join VALIDSTATUS C1 on (C1.COUNTRYCODE='ZZZ'
						and C1.PROPERTYTYPE=I.PROPERTYTYPE
						and C1.CASETYPE=I.CASETYPE
						and C1.STATUSCODE=I.STATUSCODE)
			left join (select distinct COUNTRYCODE,PROPERTYTYPE,CASETYPE
				   from VALIDSTATUS) C2
						on (C2.COUNTRYCODE=I.COUNTRYCODE
						and C2.PROPERTYTYPE=I.PROPERTYTYPE
						and C2.CASETYPE=I.CASETYPE)
			left join (select distinct I.COUNTRYCODE, I.PROPERTYTYPE, I.CASETYPE
				   from "+@sUserName+".Imported_VALIDSTATUS I
				   left join VALIDSTATUS C on (C.COUNTRYCODE='ZZZ'
							and C.PROPERTYTYPE=I.PROPERTYTYPE
							and C.CASETYPE=I.CASETYPE
							and C.STATUSCODE=I.STATUSCODE)
				   where C.COUNTRYCODE is null) C3
						on (C3.COUNTRYCODE=I.COUNTRYCODE
						and C3.PROPERTYTYPE=I.PROPERTYTYPE
						and C3.CASETYPE=I.CASETYPE)
			where C.COUNTRYCODE is null
			and (C1.COUNTRYCODE is null
			 OR  C2.COUNTRYCODE is not NULL
			 OR  C3.COUNTRYCODE is not NULL)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End
		-- If a VALIDSTATUS is to be loaded for a COUNTRY that previously did not
		-- have any VALIDSTATUS rows then we need to copy across any VALIDSTATUS
		-- rows that existed against the Default Country ('ZZZ') rule for this database.
		-- This is required so that we do not lose any entries that the Inprotech installation
		-- had set up to apply for all generic countries.

		If @ErrorCode=0
		Begin

			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDSTATUS(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				STATUSCODE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				C1.STATUSCODE
			-- Get a distinct list of Countries/PropertyTypes/CaseTypes that are being imported
			from (	select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				from #TEMPVALIDSTATUS) I
			-- Now get a distinct list of Countries/PropertyTypes/CaseTypes already in the database
			-- so we can identify those being imported that have
			-- no existing entry in the database
			left join
			     (	select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				from VALIDSTATUS) C	on ( C.COUNTRYCODE =I.COUNTRYCODE
							and  C.PROPERTYTYPE=I.PROPERTYTYPE
							and  C.CASETYPE    =I.CASETYPE)
			join VALIDSTATUS C1		on (C1.COUNTRYCODE='ZZZ'
							and C1.PROPERTYTYPE=I.PROPERTYTYPE
							and C1.CASETYPE    =I.CASETYPE)
			left join #TEMPVALIDSTATUS I1	on (I1.COUNTRYCODE =I.COUNTRYCODE
							and I1.PROPERTYTYPE=C1.PROPERTYTYPE
							and I1.CASETYPE    =C1.CASETYPE
							and I1.STATUSCODE  =C1.STATUSCODE)
			where C.COUNTRYCODE  is null
			and  I1.COUNTRYCODE  is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End

		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDSTATUS(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				STATUSCODE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.STATUSCODE
			from #TEMPVALIDSTATUS I
			left join VALIDSTATUS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.CASETYPE=I.CASETYPE
						and C.STATUSCODE=I.STATUSCODE)
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
			Insert into VALIDSTATUS(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				STATUSCODE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.STATUSCODE
			from "+@sUserName+".Imported_VALIDSTATUS I
			left join VALIDSTATUS S
						on ( S.COUNTRYCODE =I.COUNTRYCODE
						and  S.PROPERTYTYPE=I.PROPERTYTYPE
						and  S.STATUSCODE  =I.STATUSCODE)
			where S.COUNTRYCODE is null
			and   I.COUNTRYCODE = 'ZZZ'"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
		
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDSTATUS(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				STATUSCODE)
			select	distinct
				isnull(VS.COUNTRYCODE,'ZZZ'), -- Use default Country if explicit country does not exist
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.STATUSCODE
			from "+@sUserName+".Imported_VALIDSTATUS I
			left join (select distinct COUNTRYCODE, PROPERTYTYPE
				   from VALIDSTATUS) VS
						on (VS.COUNTRYCODE =I.COUNTRYCODE
						and VS.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDSTATUS S
						on ( S.COUNTRYCODE =isnull(VS.COUNTRYCODE,'ZZZ')
						and  S.PROPERTYTYPE=I.PROPERTYTYPE
						and  S.STATUSCODE  =I.STATUSCODE)
			where S.COUNTRYCODE is null
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
			Insert into VALIDSTATUS(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				STATUSCODE)
			select	I.COUNTRYCODE, 
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.STATUSCODE
			from "+@sUserName+".Imported_VALIDSTATUS I
			-- Explicit Country being imported Must already exist
			join (	select distinct COUNTRYCODE, PROPERTYTYPE
				from VALIDSTATUS) VS
						on (VS.COUNTRYCODE =I.COUNTRYCODE
						and VS.PROPERTYTYPE=I.PROPERTYTYPE)
			left join VALIDSTATUS S
						on ( S.COUNTRYCODE =I.COUNTRYCODE
						and  S.PROPERTYTYPE=I.PROPERTYTYPE
						and  S.STATUSCODE  =I.STATUSCODE)
			where S.COUNTRYCODE is null"

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
	Set @sSQLString=NULL

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesVALIDSTATUS  to public
go
