-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDACTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDACTION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDACTION.'
	drop procedure dbo.ip_RulesVALIDACTION
end
print '**** Creating procedure dbo.ip_RulesVALIDACTION...'
print ''
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesVALIDACTION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDACTION
-- VERSION :	11
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDACTION table
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 04 Aug 2004	MF	10225	2	Correction.  Ensure default valid combinations are not lost.
-- 28 Mar 2006	MF	12500	3	Do not replace the description
-- 13 Apr 2006	MF	12562	4	Problem with back filling VALID table with missing default country details.
-- 02 May 2006	MF	12500	5	Use the description from the ACTION table so as to pick up the client version
--					when inserting a new VALIDACTION row
-- 03 May 2006	MF	12562	6	Revisit to also consider Property Type and CaseType.
-- 05 Mar 2005	MF	16068	7	If the rule being imported for a specific Country is identical to
--					the rule that would default from country ZZZ and there are no other
--					country specific rules for the country being imported then do not load
--					the rule.
-- 24 Jan 2011	MF	19320	8	Introduce a Site Control "Law Update Valid Tables" to allow firms to determine how 
--					they want Valid tables to receive imported data when the explicit country does
--					not already exist on the receiving database. 
--					The options are: 0 - Create the explicit country and backfill from Default (ZZZ)
--							 1 - Deliver against the Default country if explicit country does not exist.
--							 2 - Only load imported data if explicit country already exists in Valid table.
-- 14 Jan 2014	MF	R30039	9	Load default country (ZZZ) rows before any explicit countries that can fall back to using the
--					default country.
-- 29 May 2015	MF	R48057	10	Laws blocked from importing are still generating Policing requests. VALIDACTION needs to consider
--					the blocking rules to ensure that VALIDACTION rows to be imported are allowed.
-- 19 Aug 2015	MF	R51367	11	Revisit of RFC48057 as Centura crashing because it can't see temporary table.


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

CREATE TABLE #TEMPVALIDACTION
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL ,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL ,
 	CASETYPE		nchar(1)	collate database_default NOT NULL ,
 	ACTION			nvarchar(2)	collate database_default NOT NULL ,
 	ACTIONNAME		nvarchar(50)	collate database_default NULL ,
 	ACTEVENTNO		int		NULL ,
 	RETROEVENTNO		int		NULL ,
 	DISPLAYSEQUENCE		smallint	NULL
 )

CREATE TABLE #TEMPVALIDACTIONALLOWED
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL ,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL ,
 	CASETYPE		nchar(1)	collate database_default NOT NULL
 )

-- Prerequisite that the IMPORTED_VALIDACTION table has been loaded

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
		"UPDATE "+@sUserName+".Imported_VALIDACTION
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDACTION C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTION
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTION C
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
			"UPDATE "+@sUserName+".Imported_VALIDACTION
			SET ACTION = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ACTIONS'
					and M.MAPCOLUMN  ='ACTION'
					and M.SOURCEVALUE=C.ACTION)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTION
			SET ACTEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.ACTEVENTNO)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTION
			SET RETROEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.RETROEVENTNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end
End

If @ErrorCode=0
Begin
	-----------------------------------------
	-- Check each candidate import row of
	-- VALIDACTION to see that it is not
	-- blocked from being imported.
	-----------------------------------------
	set @sSQLString="
	insert into #TEMPVALIDACTIONALLOWED (COUNTRYCODE, PROPERTYTYPE, CASETYPE)
	select distinct V.COUNTRYCODE, V.PROPERTYTYPE, V.CASETYPE
	from "+@sUserName+".Imported_VALIDACTION V
	left join CRITERIA C on (C.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( V.CASETYPE,	
											  V.ACTION,
											  V.PROPERTYTYPE,
											  V.COUNTRYCODE,
											  default,
											  default,
											  default,
											  default) )
	where isnull(C.RULEINUSE,0)=0
	and V.ACTION in ('~1','~2')"
	
	exec @ErrorCode=sp_executesql @sSQLString
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
			CT.CASETYPEDESC		as 'Imported Case Type',
			I.ACTION		as 'Imported Action',
			I.ACTIONNAME		as 'Imported Action Name',
			EL.EVENTDESCRIPTION	as 'Imported Event for Law',
			ER.EVENTDESCRIPTION	as 'Imported Retrospective',
			C.COUNTRYCODE		as 'Country',
			P.PROPERTYNAME		as 'Property',
			CT.CASETYPEDESC		as 'Case Type',
			C.ACTION		as 'Action',
			C.ACTIONNAME		as 'Action Name',
			EL.EVENTDESCRIPTION	as 'Event for Law',
			ER.EVENTDESCRIPTION	as 'Retrospective'
		from "+@sUserName+".Imported_VALIDACTION I
		join CASETYPE CT	on (CT.CASETYPE=I.CASETYPE)
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"
		Set @sSQLString2="	join VALIDACTION C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.CASETYPE=I.CASETYPE
					and C.ACTION=I.ACTION)
		where	(I.ACTEVENTNO=C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is null))
		and	(I.RETROEVENTNO=C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			CT.CASETYPEDESC,
			I.ACTION,
			I.ACTIONNAME,
			EL.EVENTDESCRIPTION,
			ER.EVENTDESCRIPTION,
			C.COUNTRYCODE,
			P.PROPERTYNAME,
			CT.CASETYPEDESC,
			C.ACTION,
			C.ACTIONNAME,
			EL1.EVENTDESCRIPTION,
			ER1.EVENTDESCRIPTION
		from "+@sUserName+".Imported_VALIDACTION I
		join CASETYPE CT	on (CT.CASETYPE=I.CASETYPE)
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"
		Set @sSQLString4="	join VALIDACTION C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.CASETYPE=I.CASETYPE
					and C.ACTION=I.ACTION)
		left join EVENTS EL1	on (EL1.EVENTNO=C.ACTEVENTNO)
		left join EVENTS ER1	on (ER1.EVENTNO=C.RETROEVENTNO)
		where 	I.ACTEVENTNO<>C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			CT.CASETYPEDESC,
			I.ACTION,
			I.ACTIONNAME,
			EL.EVENTDESCRIPTION,
			ER.EVENTDESCRIPTION,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_VALIDACTION I
		join CASETYPE CT	on (CT.CASETYPE=I.CASETYPE)
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"
		Set @sSQLString6="	left join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
					 and C.PROPERTYTYPE=I.PROPERTYTYPE
					 and C.CASETYPE=I.CASETYPE
					 and C.ACTION=I.ACTION)
		left join VALIDACTION C1 on (C1.COUNTRYCODE='ZZZ'
					 and C1.PROPERTYTYPE=I.PROPERTYTYPE
					 and C1.CASETYPE=I.CASETYPE
					 and C1.ACTION=I.ACTION)
		left join (select distinct COUNTRYCODE,PROPERTYTYPE,CASETYPE
			   from VALIDACTION) C2
					on (C2.COUNTRYCODE=I.COUNTRYCODE
					and C2.PROPERTYTYPE=I.PROPERTYTYPE
					and C2.CASETYPE=I.CASETYPE)
		left join (select distinct I.COUNTRYCODE,I.PROPERTYTYPE,I.CASETYPE
			   from "+@sUserName+".Imported_VALIDACTION I
			   left join VALIDACTION C on (C.COUNTRYCODE='ZZZ'
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.CASETYPE=I.CASETYPE
						and C.ACTION=I.ACTION)
			   where checksum(I.PROPERTYTYPE,I.ACTEVENTNO,I.RETROEVENTNO)
			      <> checksum(C.PROPERTYTYPE,C.ACTEVENTNO,C.RETROEVENTNO)) C3
					on (C3.COUNTRYCODE=I.COUNTRYCODE
					and C3.PROPERTYTYPE=I.PROPERTYTYPE
					and C3.CASETYPE=I.CASETYPE)
		where C.COUNTRYCODE is null
		and(checksum(I.PROPERTYTYPE,I.ACTEVENTNO,I.RETROEVENTNO)<>checksum(C1.PROPERTYTYPE,C1.ACTEVENTNO,C1.RETROEVENTNO)
		 OR C2.COUNTRYCODE is not null
		 OR C3.COUNTRYCODE is not null)
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
		Update VALIDACTION
		set	ACTEVENTNO=I.ACTEVENTNO,
			RETROEVENTNO=I.RETROEVENTNO
		from	VALIDACTION C
		join	"+@sUserName+".Imported_VALIDACTION I	
						on (I.COUNTRYCODE =C.COUNTRYCODE
						and I.PROPERTYTYPE=C.PROPERTYTYPE
						and I.CASETYPE    =C.CASETYPE
						and I.ACTION      =C.ACTION)
		join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
		where 	I.ACTIONNAME<>C.ACTIONNAME OR (I.ACTIONNAME is null and C.ACTIONNAME is not null) OR (I.ACTIONNAME is not null and C.ACTIONNAME is null)
		OR	I.ACTEVENTNO<>C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 
	
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
		-------------------------------------------------------------------------
		-- Load into a temporary table the VALIDACTION keys that are eligible to
		-- be loaded from the imported rules.  This is required to help determine
		-- where the default country VALIDACTION might be able to be used.
		-------------------------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPVALIDACTION(COUNTRYCODE,PROPERTYTYPE,CASETYPE,ACTION,ACTEVENTNO,RETROEVENTNO,DISPLAYSEQUENCE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.ACTION,
				I.ACTEVENTNO,
				I.RETROEVENTNO,
				I.DISPLAYSEQUENCE
			from "+@sUserName+".Imported_VALIDACTION I
			join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
			-- No VALIDACTION row with same key
			left join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
						 and C.PROPERTYTYPE=I.PROPERTYTYPE
						 and C.CASETYPE=I.CASETYPE
						 and C.ACTION=I.ACTION)
			-- No identical VALIDACTION row for the default country
			left join VALIDACTION C1 on (C1.COUNTRYCODE='ZZZ'
						 and C1.PROPERTYTYPE=I.PROPERTYTYPE
						 and C1.CASETYPE=I.CASETYPE
						 and C1.ACTION=I.ACTION)
			-- VALIDACTION for matching country
			left join (select distinct COUNTRYCODE,PROPERTYTYPE,CASETYPE
				   from VALIDACTION) C2
						on (C2.COUNTRYCODE=I.COUNTRYCODE
						and C2.PROPERTYTYPE=I.PROPERTYTYPE
						and C2.CASETYPE=I.CASETYPE)
			-- VALIDACTION for matching country is being imported (may be a different Action)
			left join (select distinct I.COUNTRYCODE,I.PROPERTYTYPE,I.CASETYPE
				   from "+@sUserName+".Imported_VALIDACTION I
				   left join VALIDACTION C on (C.COUNTRYCODE='ZZZ'
							and C.PROPERTYTYPE=I.PROPERTYTYPE
							and C.CASETYPE=I.CASETYPE
							and C.ACTION=I.ACTION)
				   where checksum(I.ACTEVENTNO,I.RETROEVENTNO)
				      <> checksum(C.ACTEVENTNO,C.RETROEVENTNO)) C3
						on (C3.COUNTRYCODE=I.COUNTRYCODE
						and C3.PROPERTYTYPE=I.PROPERTYTYPE
						and C3.CASETYPE=I.CASETYPE)
			where C.COUNTRYCODE is null
			and(checksum(I.ACTEVENTNO,I.RETROEVENTNO)<>checksum(C1.ACTEVENTNO,C1.RETROEVENTNO)
			 OR C2.COUNTRYCODE is not null
			 OR C3.COUNTRYCODE is not null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End
		--------------------------------------------------------------------------------
		-- If a VALIDACTION is to be loaded for a COUNTRY that previously did not
		-- have any VALIDACTION rows then we need to copy across any VALIDACTION
		-- rows that existed against the Default Country ('ZZZ') rule for this database.
		-- This is required so that we do not lose any entries that the Inprotech
		-- installation had set up to apply for all generic countries.
		--------------------------------------------------------------------------------
		If @ErrorCode=0
		Begin

			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDACTION(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				ACTION,
				ACTIONNAME,
				ACTEVENTNO,
				RETROEVENTNO,
				DISPLAYSEQUENCE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				C1.ACTION,
				C1.ACTIONNAME,
				C1.ACTEVENTNO,
				C1.RETROEVENTNO,
				C1.DISPLAYSEQUENCE
			-- Get a distinct list of Countries/PropertyType/CaseType that are being imported
			from (	select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				from #TEMPVALIDACTION) I
			join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
			-- Now get a distinct list of Countries/PropertyType/CaseType already in the database
			-- so we can identify those being imported that have
			-- no existing entry in the database
			left join
			     (	select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				from VALIDACTION) C	on ( C.COUNTRYCODE=I.COUNTRYCODE
							and  C.PROPERTYTYPE=I.PROPERTYTYPE
							and  C.CASETYPE    =I.CASETYPE)
			join VALIDACTION C1		on (C1.COUNTRYCODE ='ZZZ'
							and C1.PROPERTYTYPE=I.PROPERTYTYPE
							and C1.CASETYPE    =I.CASETYPE)
			left join #TEMPVALIDACTION I2	on (I2.COUNTRYCODE =I.COUNTRYCODE
							and I2.PROPERTYTYPE=C1.PROPERTYTYPE
							and I2.CASETYPE    =C1.CASETYPE
							and I2.ACTION      =C1.ACTION)
			where C.COUNTRYCODE  is null
			and  I2.COUNTRYCODE  is null"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End

		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDACTION(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				ACTION,
				ACTIONNAME,
				ACTEVENTNO,
				RETROEVENTNO,
				DISPLAYSEQUENCE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.ACTION,
				A.ACTIONNAME,	-- use clients default ActionName
				I.ACTEVENTNO,
				I.RETROEVENTNO,
				I.DISPLAYSEQUENCE
			from #TEMPVALIDACTION I
			join ACTIONS A		on ( A.ACTION=I.ACTION)
			left join VALIDACTION C	on ( C.COUNTRYCODE=I.COUNTRYCODE
						and  C.PROPERTYTYPE=I.PROPERTYTYPE
						and  C.CASETYPE=I.CASETYPE
						and  C.ACTION=I.ACTION)
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
			Insert into VALIDACTION(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				ACTION,
				ACTIONNAME,
				ACTEVENTNO,
				RETROEVENTNO,
				DISPLAYSEQUENCE)
			select	I.COUNTRYCODE,
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.ACTION,
				A.ACTIONNAME,	-- use clients default ActionName
				I.ACTEVENTNO,
				I.RETROEVENTNO,
				I.DISPLAYSEQUENCE
			from "+@sUserName+".Imported_VALIDACTION I
			join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
			join ACTIONS A		on ( A.ACTION=I.ACTION)
			left join VALIDACTION C	on ( C.COUNTRYCODE =I.COUNTRYCODE
						and  C.PROPERTYTYPE=I.PROPERTYTYPE
						and  C.CASETYPE=I.CASETYPE
						and  C.ACTION=I.ACTION)
			where C.COUNTRYCODE is null
			and   I.COUNTRYCODE = 'ZZZ'"

			exec @ErrorCode=sp_executesql @sSQLString
		
			Set @pnRowCount=@pnRowCount+@@rowcount
		End
		
		If @ErrorCode=0
		Begin
			-- Insert the rows where the key is different.
			Set @sSQLString= "
			Insert into VALIDACTION(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				ACTION,
				ACTIONNAME,
				ACTEVENTNO,
				RETROEVENTNO,
				DISPLAYSEQUENCE)
			select	distinct
				isnull(VA.COUNTRYCODE,'ZZZ'), -- Use default Country if explicit country does not exist
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.ACTION,
				A.ACTIONNAME,	-- use clients default ActionName
				I.ACTEVENTNO,
				I.RETROEVENTNO,
				I.DISPLAYSEQUENCE
			from "+@sUserName+".Imported_VALIDACTION I
			join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
			join ACTIONS A		on ( A.ACTION=I.ACTION)
			left join (select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				   from VALIDACTION) VA
						on (VA.COUNTRYCODE =I.COUNTRYCODE
						and VA.PROPERTYTYPE=I.PROPERTYTYPE
						and VA.CASETYPE    =I.CASETYPE)
			left join VALIDACTION C	on ( C.COUNTRYCODE =isnull(VA.COUNTRYCODE,'ZZZ')
						and  C.PROPERTYTYPE=I.PROPERTYTYPE
						and  C.CASETYPE=I.CASETYPE
						and  C.ACTION=I.ACTION)
			where C.COUNTRYCODE is null
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
			Insert into VALIDACTION(
				COUNTRYCODE,
				PROPERTYTYPE,
				CASETYPE,
				ACTION,
				ACTIONNAME,
				ACTEVENTNO,
				RETROEVENTNO,
				DISPLAYSEQUENCE)
			select	I.COUNTRYCODE, 
				I.PROPERTYTYPE,
				I.CASETYPE,
				I.ACTION,
				A.ACTIONNAME,	-- use clients default ActionName
				I.ACTEVENTNO,
				I.RETROEVENTNO,
				I.DISPLAYSEQUENCE
			from "+@sUserName+".Imported_VALIDACTION I
			join #TEMPVALIDACTIONALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE
						and I1.CASETYPE    =I.CASETYPE)
			join ACTIONS A		on ( A.ACTION=I.ACTION)
			-- Explicit Country being imported Must already exist
			join (	select distinct COUNTRYCODE, PROPERTYTYPE, CASETYPE
				from VALIDACTION) VA
						on (VA.COUNTRYCODE =I.COUNTRYCODE
						and VA.PROPERTYTYPE=I.PROPERTYTYPE
						and VA.CASETYPE    =I.CASETYPE)
			left join VALIDACTION C	on ( C.COUNTRYCODE =I.COUNTRYCODE
						and  C.PROPERTYTYPE=I.PROPERTYTYPE
						and  C.CASETYPE=I.CASETYPE
						and  C.ACTION=I.ACTION)
			where C.COUNTRYCODE is null"

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
grant execute on dbo.ip_RulesVALIDACTION  to public
go
