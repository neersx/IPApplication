-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCRITERIA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCRITERIA.'
	drop procedure dbo.ip_RulesCRITERIA
	print '**** Creating procedure dbo.ip_RulesCRITERIA...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCRITERIA
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCRITERIA
-- VERSION :	10
-- DESCRIPTION:	The comparison/display and merging of imported data for the CRITERIA table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 07 Jul 2005	MF	11011	2	Increase CaseCategory column size to NVARCHAR(2)
-- 05 Feb 2007	MF	13335	3	Do not turn the Rule In Use ON if it is OFF on the database
--					being imported into.
-- 22 May 2007	MF	14110	4	Differences in Parent CriteriaNo should not be shown as difference
-- 21 Jan 2011	MF	19321	5	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 11 Mar 2011	MF	19321	6	Revisit to include additional columns that do not need to be shown as a difference.
-- 12 Jul 2013	MF	R13596	7	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	8	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 30 Apr 2014	MF	R33822	9	A @psUserName of 9 characters resulted in the generated dynamic SQL exceeding the internal variable
--					lengths.  Needed to change the internal formatting.  Not able to just switch to variables defined
--					as nvarchar(max) at this stage because that would require a change to the calling Centura code.
-- 01 Jun 2014	MF	R35000	10	Restructure dynamic SQL as variable being truncated resulting in SQL Error.
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


-- Prerequisite that the IMPORTED_CRITERIA table has been loaded

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

--------------------------------------
-- Create and load CRITERIAALLOWED if
-- it does not exist already
--------------------------------------
If @ErrorCode=0
and not exists(	SELECT 1 
		from sysobjects 
		where id = object_id(@sUserName+'.CRITERIAALLOWED'))
Begin
	---------------------------------------------------
	-- Create an interim table to hold the criteria
	-- that are allowed to be imported for the purpose
	-- of creating or update laws on the receiving
	-- database
	---------------------------------------------------
	Set @sSQLString="CREATE TABLE "+@sUserName+".CRITERIAALLOWED (CRITERIANO int not null PRIMARY KEY)"
	exec @ErrorCode=sp_executesql @sSQLString
	
	If @ErrorCode=0
	Begin
		-----------------------------------------
		-- Load the CRITERIA that are candidates
		-- to be imported into a temporary table.
		-- This allows rules defined by a firm to
		-- block or allow criteria.
		-----------------------------------------
		set @sSQLString="
		insert into "+@sUserName+".CRITERIAALLOWED (CRITERIANO)
		select distinct C.CRITERIANO
		from "+@sUserName+".Imported_CRITERIA C
		left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
												    C.ACTION,
												    C.PROPERTYTYPE,
												    C.COUNTRYCODE,
												    C.CASECATEGORY,
												    C.SUBTYPE,
												    C.BASIS,
												    C.DATEOFACT) )
		where isnull(C1.RULEINUSE,0)=0"
		
		exec @ErrorCode=sp_executesql @sSQLString
	End
end

-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison
If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_CRITERIA
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_CRITERIA C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"
	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET ACTION = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
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
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
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
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET CASECATEGORY = substring(M.MAPVALUE, 2,2)
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='CASECATEGORY'
					and M.MAPCOLUMN  ='CASECATEGORY'
					and M.SOURCEVALUE=C.CASETYPE+C.CASECATEGORY)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET SUBTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='SUBTYPE'
					and M.MAPCOLUMN  ='SUBTYPE'
					and M.SOURCEVALUE=C.SUBTYPE)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET BASIS = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='APPLICATIONBASIS'
					and M.MAPCOLUMN  ='BASIS'
					and M.SOURCEVALUE=C.BASIS)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET TABLECODE = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.TABLECODE)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET TYPEOFMARK = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.TYPEOFMARK)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CRITERIA
			SET RENEWALTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_CRITERIA C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='TABLECODES'
					and M.MAPCOLUMN  ='TABLECODE'
					and M.SOURCEVALUE=C.RENEWALTYPE)
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
			I.CRITERIANO		as 'Imported Criteria No',
			CASE (I.PURPOSECODE)
				WHEN('A') THEN 'CPA Renewal Types'
				WHEN('C') THEN 'Checklists'
				WHEN('E') THEN 'Events & Entries'
				WHEN('F') THEN 'Fees & Charges'
				WHEN('R') THEN 'Case Reference Format'
				WHEN('S') THEN 'Case Windows'
				WHEN('W') THEN 'Web Windows'
			END			as 'Imported Purpose',
			CT.CASETYPEDESC		as 'Imported Case Type',
			A.ACTIONNAME		as 'Imported Action',
			CL.CHECKLISTDESC	as 'Imported Checklist',
			I.PROGRAMID		as 'Imported Program',
			P.PROPERTYNAME		as 'Imported Property',
			dbo.fn_DisplayBoolean(I.PROPERTYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Property Unknown',
			I.COUNTRYCODE		as 'Imported Country',
			dbo.fn_DisplayBoolean(I.COUNTRYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Country Unknown',
			CC.CASECATEGORYDESC	as 'Imported Category',
			dbo.fn_DisplayBoolean(I.CATEGORYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Category Unknown',
			SB.SUBTYPEDESC		as 'Imported Sub Type',
			dbo.fn_DisplayBoolean(I.SUBTYPEUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Sub Type Unknown',
			AB.BASISDESCRIPTION	as 'Imported Basis',
			I.REGISTEREDUSERS	as 'Imported Registered Users',
			dbo.fn_DisplayBoolean(I.LOCALCLIENTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Local Client',
			TC.DESCRIPTION		as 'Imported Table Code',
			R.RATEDESC		as 'Imported Rate',
			I.DATEOFACT		as 'Imported Date of Law',
			dbo.fn_DisplayBoolean(I.USERDEFINEDRULE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported User Defined',
			dbo.fn_DisplayBoolean(I.RULEINUSE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Rule In Use',
			C.DESCRIPTION		as 'Imported Description',
			CPA.DESCRIPTION		as 'Imported Renewal Type',
			C.CRITERIANO		as 'Criteria No',
			CASE (C.PURPOSECODE)
				WHEN('A') THEN 'CPA Renewal Types'
				WHEN('C') THEN 'Checklists'
				WHEN('E') THEN 'Events & Entries'
				WHEN('F') THEN 'Fees & Charges'
				WHEN('R') THEN 'Case Reference Format'
				WHEN('S') THEN 'Case Windows'
				WHEN('W') THEN 'Web Windows'
			END			as 'Purpose',
			CT.CASETYPEDESC		as 'Case Type',
			A.ACTIONNAME		as 'Action',
			CL.CHECKLISTDESC	as 'Checklist',
			C.PROGRAMID		as 'Program',
			P.PROPERTYNAME		as 'Property',
			dbo.fn_DisplayBoolean(C.PROPERTYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Property Unknown',
			C.COUNTRYCODE		as 'Country',
			dbo.fn_DisplayBoolean(C.COUNTRYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Country Unknown',
			CC.CASECATEGORYDESC	as 'Category',
			dbo.fn_DisplayBoolean(C.CATEGORYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Category Unknown',
			SB.SUBTYPEDESC		as 'Sub Type',
			dbo.fn_DisplayBoolean(C.SUBTYPEUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Sub Type Unknown',
			AB.BASISDESCRIPTION	as 'Basis',
			C.REGISTEREDUSERS	as 'Registered Users',
			dbo.fn_DisplayBoolean(C.LOCALCLIENTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Local Client',
			TC.DESCRIPTION		as 'Table Code',
			R.RATEDESC		as 'Rate',
			C.DATEOFACT		as 'Date of Law',
			dbo.fn_DisplayBoolean(C.USERDEFINEDRULE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'User Defined',
			dbo.fn_DisplayBoolean(C.RULEINUSE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Rule In Use',
			C.DESCRIPTION		as 'Description',
			CPA.DESCRIPTION		as 'Renewal Type'
		from "+@sUserName+".Imported_CRITERIA I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join CASETYPE CT on (CT.CASETYPE=I.CASETYPE)
		left join "+@sUserName+".Imported_PROPERTYTYPE P on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_ACTIONS A on (A.ACTION=I.ACTION)
		left join "+@sUserName+".Imported_CHECKLISTS CL on (CL.CHECKLISTTYPE=I.CHECKLISTTYPE)
		left join "+@sUserName+".Imported_CASECATEGORY CC on (CC.CASETYPE=I.CASETYPE
								  and CC.CASECATEGORY=I.CASECATEGORY)"
		Set @sSQLString2="	
		left join "+@sUserName+".Imported_SUBTYPE SB on (SB.SUBTYPE=I.SUBTYPE)
		left join "+@sUserName+".Imported_APPLICATIONBASIS AB on (AB.BASIS=I.BASIS)
		left join "+@sUserName+".Imported_TABLECODES TC on (TC.TABLECODE=I.TABLECODE)
		left join "+@sUserName+".Imported_TABLECODES CPA on (CPA.TABLECODE=I.RENEWALTYPE)
		left join RATES R on (R.RATENO=I.RATENO)
		join CRITERIA C	on( C.CRITERIANO=I.CRITERIANO)
		where	(I.PURPOSECODE=C.PURPOSECODE OR (I.PURPOSECODE is null and C.PURPOSECODE is null))
		and	(I.CASETYPE=C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
		and	(I.ACTION=C.ACTION OR (I.ACTION is null and C.ACTION is null))
		and	(I.CHECKLISTTYPE=C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is null))
		and	(I.PROGRAMID=C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is null))
		and	(I.PROPERTYTYPE=C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
		and	(I.PROPERTYUNKNOWN=C.PROPERTYUNKNOWN OR (I.PROPERTYUNKNOWN is null and C.PROPERTYUNKNOWN is null))
		and	(I.COUNTRYCODE=C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
		and	(I.COUNTRYUNKNOWN=C.COUNTRYUNKNOWN OR (I.COUNTRYUNKNOWN is null and C.COUNTRYUNKNOWN is null))
		and	(I.CASECATEGORY=C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
		and	(I.CATEGORYUNKNOWN=C.CATEGORYUNKNOWN OR (I.CATEGORYUNKNOWN is null and C.CATEGORYUNKNOWN is null))
		and	(I.SUBTYPE=C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))
		and	(I.SUBTYPEUNKNOWN=C.SUBTYPEUNKNOWN OR (I.SUBTYPEUNKNOWN is null and C.SUBTYPEUNKNOWN is null))
		and	(I.BASIS=C.BASIS OR (I.BASIS is null and C.BASIS is null))
		and	(I.REGISTEREDUSERS=C.REGISTEREDUSERS OR (I.REGISTEREDUSERS is null and C.REGISTEREDUSERS is null))
		and	(I.LOCALCLIENTFLAG=C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is null))
		and	(I.TABLECODE=C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is null))
		and	(I.RATENO=C.RATENO OR (I.RATENO is null and C.RATENO is null))
		and	(I.DATEOFACT=C.DATEOFACT OR (I.DATEOFACT is null and C.DATEOFACT is null))
		and	(I.USERDEFINEDRULE=C.USERDEFINEDRULE OR (I.USERDEFINEDRULE is null and C.USERDEFINEDRULE is null))
		and	(I.RULEINUSE=C.RULEINUSE OR (I.RULEINUSE is null and C.RULEINUSE is null))
		and	(I.RENEWALTYPE=C.RENEWALTYPE OR (I.RENEWALTYPE is null and C.RENEWALTYPE is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.CRITERIANO,
			CASE (I.PURPOSECODE)
				WHEN('A') THEN 'CPA Renewal Types'
				WHEN('C') THEN 'Checklists'
				WHEN('E') THEN 'Events & Entries'
				WHEN('F') THEN 'Fees & Charges'
				WHEN('R') THEN 'Case Reference Format'
				WHEN('S') THEN 'Case Windows'
				WHEN('W') THEN 'Web Windows'
			END,
			CT.CASETYPEDESC,
			A.ACTIONNAME,
			CL.CHECKLISTDESC,
			I.PROGRAMID,
			CASE WHEN(C.PROPERTYTYPE=I.PROPERTYTYPE) THEN P1.PROPERTYNAME ELSE P.PROPERTYNAME END,
			dbo.fn_DisplayBoolean(I.PROPERTYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			I.COUNTRYCODE,
			dbo.fn_DisplayBoolean(I.COUNTRYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE WHEN(C.CASECATEGORY=I.CASECATEGORY) THEN CC1.CASECATEGORYDESC ELSE CC.CASECATEGORYDESC END,
			dbo.fn_DisplayBoolean(I.CATEGORYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE WHEN(C.SUBTYPE=I.SUBTYPE) THEN SB1.SUBTYPEDESC ELSE SB.SUBTYPEDESC END,
			dbo.fn_DisplayBoolean(I.SUBTYPEUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE WHEN(C.BASIS=I.BASIS) THEN AB1.BASISDESCRIPTION ELSE AB.BASISDESCRIPTION END,
			I.REGISTEREDUSERS,
			dbo.fn_DisplayBoolean(I.LOCALCLIENTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CASE WHEN(C.TABLECODE=I.TABLECODE) THEN TC1.DESCRIPTION ELSE TC.DESCRIPTION END,
			R.RATEDESC,
			I.DATEOFACT,
			dbo.fn_DisplayBoolean(I.USERDEFINEDRULE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.RULEINUSE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			C.DESCRIPTION,
			CPA.DESCRIPTION,
			C.CRITERIANO,
			CASE (C.PURPOSECODE)
				WHEN('A') THEN 'CPA Renewal Types'
				WHEN('C') THEN 'Checklists'
				WHEN('E') THEN 'Events & Entries'
				WHEN('F') THEN 'Fees & Charges'
				WHEN('R') THEN 'Case Reference Format'
				WHEN('S') THEN 'Case Windows'
				WHEN('W') THEN 'Web Windows'
			END,
			CT1.CASETYPEDESC,
			A1.ACTIONNAME,
			CL1.CHECKLISTDESC,
			C.PROGRAMID,
			P1.PROPERTYNAME,
			dbo.fn_DisplayBoolean(C.PROPERTYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			C.COUNTRYCODE,
			dbo.fn_DisplayBoolean(C.COUNTRYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CC1.CASECATEGORYDESC,
			dbo.fn_DisplayBoolean(C.CATEGORYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			SB1.SUBTYPEDESC,
			dbo.fn_DisplayBoolean(C.SUBTYPEUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AB1.BASISDESCRIPTION,
			C.REGISTEREDUSERS,
			dbo.fn_DisplayBoolean(C.LOCALCLIENTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			TC1.DESCRIPTION,
			R1.RATEDESC,
			C.DATEOFACT,
			dbo.fn_DisplayBoolean(C.USERDEFINEDRULE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(C.RULEINUSE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			C.DESCRIPTION,
			CPA1.DESCRIPTION
		from "+@sUserName+".Imported_CRITERIA I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join CASETYPE CT on (CT.CASETYPE=I.CASETYPE)
		left join "+@sUserName+".Imported_PROPERTYTYPE P on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_ACTIONS A on (A.ACTION=I.ACTION)
		left join "+@sUserName+".Imported_CHECKLISTS CL on (CL.CHECKLISTTYPE=I.CHECKLISTTYPE)
		left join "+@sUserName+".Imported_CASECATEGORY CC on (CC.CASETYPE=I.CASETYPE
								  and CC.CASECATEGORY=I.CASECATEGORY)"
		Set @sSQLString4="	left join "+@sUserName+".Imported_SUBTYPE SB on (SB.SUBTYPE=I.SUBTYPE)
		left join "+@sUserName+".Imported_APPLICATIONBASIS AB on (AB.BASIS=I.BASIS)
		left join "+@sUserName+".Imported_TABLECODES TC on (TC.TABLECODE=I.TABLECODE)
		left join "+@sUserName+".Imported_TABLECODES CPA on (CPA.TABLECODE=I.RENEWALTYPE)
		left join RATES R on (R.RATENO=I.RATENO)
		join CRITERIA C	on( C.CRITERIANO=I.CRITERIANO)
		left join PROPERTYTYPE P1 on (P1.PROPERTYTYPE=C.PROPERTYTYPE)
		left join CASETYPE CT1 on (CT1.CASETYPE=C.CASETYPE)
		left join ACTIONS A1 on (A1.ACTION=C.ACTION)
		left join CHECKLISTS CL1 on (CL1.CHECKLISTTYPE=C.CHECKLISTTYPE)
		left join CASECATEGORY CC1 on (CC1.CASETYPE=C.CASETYPE
					   and CC1.CASECATEGORY=C.CASECATEGORY)
		left join SUBTYPE SB1 on (SB1.SUBTYPE=C.SUBTYPE)
		left join APPLICATIONBASIS AB1 on (AB1.BASIS=C.BASIS)
		left join TABLECODES TC1  on (TC1.TABLECODE=C.TABLECODE)
		left join TABLECODES CPA1 on (CPA1.TABLECODE=C.RENEWALTYPE)
		left join RATES R1 on (R1.RATENO=C.RATENO)
		where 	I.PURPOSECODE<>C.PURPOSECODE OR (I.PURPOSECODE is null and C.PURPOSECODE is not null) OR (I.PURPOSECODE is not null and C.PURPOSECODE is null)
		OR	I.CASETYPE<>C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) OR (I.CASETYPE is not null and C.CASETYPE is null)
		OR	I.ACTION<>C.ACTION OR (I.ACTION is null and C.ACTION is not null) OR (I.ACTION is not null and C.ACTION is null)
		OR	I.CHECKLISTTYPE<>C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is not null) OR (I.CHECKLISTTYPE is not null and C.CHECKLISTTYPE is null)
		OR	I.PROGRAMID<>C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is not null) OR (I.PROGRAMID is not null and C.PROGRAMID is null)
		OR	I.PROPERTYTYPE<>C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null)
		OR	I.PROPERTYUNKNOWN<>C.PROPERTYUNKNOWN OR (I.PROPERTYUNKNOWN is null and C.PROPERTYUNKNOWN is not null) OR (I.PROPERTYUNKNOWN is not null and C.PROPERTYUNKNOWN is null)
		OR	I.COUNTRYCODE<>C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null)
		OR	I.COUNTRYUNKNOWN<>C.COUNTRYUNKNOWN OR (I.COUNTRYUNKNOWN is null and C.COUNTRYUNKNOWN is not null) OR (I.COUNTRYUNKNOWN is not null and C.COUNTRYUNKNOWN is null)
		OR	I.CASECATEGORY<>C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) OR (I.CASECATEGORY is not null and C.CASECATEGORY is null)
		OR	I.CATEGORYUNKNOWN<>C.CATEGORYUNKNOWN OR (I.CATEGORYUNKNOWN is null and C.CATEGORYUNKNOWN is not null) OR (I.CATEGORYUNKNOWN is not null and C.CATEGORYUNKNOWN is null)
		OR	I.SUBTYPE<>C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) OR (I.SUBTYPE is not null and C.SUBTYPE is null)
		OR	I.SUBTYPEUNKNOWN<>C.SUBTYPEUNKNOWN OR (I.SUBTYPEUNKNOWN is null and C.SUBTYPEUNKNOWN is not null) OR (I.SUBTYPEUNKNOWN is not null and C.SUBTYPEUNKNOWN is null)
		OR	I.BASIS<>C.BASIS OR (I.BASIS is null and C.BASIS is not null) OR (I.BASIS is not null and C.BASIS is null)
		OR	I.REGISTEREDUSERS<>C.REGISTEREDUSERS OR (I.REGISTEREDUSERS is null and C.REGISTEREDUSERS is not null) OR (I.REGISTEREDUSERS is not null and C.REGISTEREDUSERS is null)
		OR	I.LOCALCLIENTFLAG<>C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null) OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null)
		OR	I.TABLECODE<>C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) OR (I.TABLECODE is not null and C.TABLECODE is null)
		OR	I.RATENO<>C.RATENO OR (I.RATENO is null and C.RATENO is not null) OR (I.RATENO is not null and C.RATENO is null)
		OR	I.DATEOFACT<>C.DATEOFACT OR (I.DATEOFACT is null and C.DATEOFACT is not null) OR (I.DATEOFACT is not null and C.DATEOFACT is null)
		OR	I.USERDEFINEDRULE<>C.USERDEFINEDRULE OR (I.USERDEFINEDRULE is null and C.USERDEFINEDRULE is not null) OR (I.USERDEFINEDRULE is not null and C.USERDEFINEDRULE is null)"
		Set @sSQLString5="
		OR	I.RULEINUSE<>C.RULEINUSE OR (I.RULEINUSE is null and C.RULEINUSE is not null) OR (I.RULEINUSE is not null and C.RULEINUSE is null)
		OR	I.STARTDETAILENTRY<>C.STARTDETAILENTRY OR (I.STARTDETAILENTRY is null and C.STARTDETAILENTRY is not null) OR (I.STARTDETAILENTRY is not null and C.STARTDETAILENTRY is null)
		OR	I.RENEWALTYPE<>C.RENEWALTYPE OR (I.RENEWALTYPE is null and C.RENEWALTYPE is not null) OR (I.RENEWALTYPE is not null and C.RENEWALTYPE is null)
		UNION ALL
		select	1,
			'X',
			I.CRITERIANO,
			CASE (I.PURPOSECODE)
				WHEN('A') THEN 'CPA Renewal Types'
				WHEN('C') THEN 'Checklists'
				WHEN('E') THEN 'Events & Entries'
				WHEN('F') THEN 'Fees & Charges'
				WHEN('R') THEN 'Case Reference Format'
				WHEN('S') THEN 'Case Windows'
				WHEN('W') THEN 'Web Windows'
			END,
			CT.CASETYPEDESC,
			A.ACTIONNAME,
			CL.CHECKLISTDESC,
			I.PROGRAMID,
			P.PROPERTYNAME,
			dbo.fn_DisplayBoolean(I.PROPERTYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			I.COUNTRYCODE,
			dbo.fn_DisplayBoolean(I.COUNTRYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			CC.CASECATEGORYDESC,
			dbo.fn_DisplayBoolean(I.CATEGORYUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			SB.SUBTYPEDESC,
			dbo.fn_DisplayBoolean(I.SUBTYPEUNKNOWN,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			AB.BASISDESCRIPTION,
			I.REGISTEREDUSERS,
			dbo.fn_DisplayBoolean(I.LOCALCLIENTFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			TC.DESCRIPTION,
			R.RATEDESC,
			I.DATEOFACT,
			dbo.fn_DisplayBoolean(I.USERDEFINEDRULE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			dbo.fn_DisplayBoolean(I.RULEINUSE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			I.DESCRIPTION,
			CPA.DESCRIPTION,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_CRITERIA I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join CASETYPE CT on (CT.CASETYPE=I.CASETYPE)
		left join "+@sUserName+".Imported_PROPERTYTYPE P on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_ACTIONS A on (A.ACTION=I.ACTION)
		left join "+@sUserName+".Imported_CHECKLISTS CL on (CL.CHECKLISTTYPE=I.CHECKLISTTYPE)
		left join "+@sUserName+".Imported_CASECATEGORY CC on (CC.CASETYPE=I.CASETYPE
								  and CC.CASECATEGORY=I.CASECATEGORY)
		left join "+@sUserName+".Imported_SUBTYPE SB on (SB.SUBTYPE=I.SUBTYPE)
		left join "+@sUserName+".Imported_APPLICATIONBASIS AB on (AB.BASIS=I.BASIS)
		left join "+@sUserName+".Imported_TABLECODES TC on (TC.TABLECODE=I.TABLECODE)
		left join "+@sUserName+".Imported_TABLECODES CPA on (CPA.TABLECODE=I.RENEWALTYPE)
		left join RATES R on (R.RATENO=I.RATENO)"
		Set @sSQLString6="	left join CRITERIA C on( C.CRITERIANO=I.CRITERIANO)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,4,8 desc, 10 desc, 12 desc, 14 desc, 16 desc, 5,6,7,9,11,13,15,17,18,19,20,21,22" ELSE "4,8 desc, 10 desc, 12 desc, 14 desc, 16 desc, 5,6,7,9,11,13,15,17,18,19,20,21,22" END
	
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
	
		Set @sSQLString1="
		Update CRITERIA
		set	CASETYPE=I.CASETYPE,
			ACTION=I.ACTION,
			CHECKLISTTYPE=I.CHECKLISTTYPE,
			PROGRAMID=I.PROGRAMID,
			PROPERTYTYPE=I.PROPERTYTYPE,
			PROPERTYUNKNOWN=I.PROPERTYUNKNOWN,
			COUNTRYCODE=I.COUNTRYCODE,
			COUNTRYUNKNOWN=I.COUNTRYUNKNOWN,
			CASECATEGORY=I.CASECATEGORY,
			CATEGORYUNKNOWN=I.CATEGORYUNKNOWN,
			SUBTYPE=I.SUBTYPE,
			SUBTYPEUNKNOWN=I.SUBTYPEUNKNOWN,
			BASIS=I.BASIS,
			REGISTEREDUSERS=I.REGISTEREDUSERS,
			LOCALCLIENTFLAG=I.LOCALCLIENTFLAG,
			TABLECODE=I.TABLECODE,
			RATENO=I.RATENO,
			DATEOFACT=I.DATEOFACT,
			USERDEFINEDRULE=I.USERDEFINEDRULE,
			RULEINUSE=CASE WHEN(isnull(C.RULEINUSE,0)=0) THEN C.RULEINUSE ELSE I.RULEINUSE END, --SQA13335 do not Set ON if Rule In Use is already OFF.
			STARTDETAILENTRY=I.STARTDETAILENTRY,
			PARENTCRITERIA=I.PARENTCRITERIA,
			BELONGSTOGROUP=I.BELONGSTOGROUP,
			DESCRIPTION=I.DESCRIPTION,
			TYPEOFMARK=I.TYPEOFMARK,
			RENEWALTYPE=I.RENEWALTYPE,
			CASEOFFICEID=I.CASEOFFICEID
		from	CRITERIA C
		join	"+@sUserName+".Imported_CRITERIA I	on ( I.CRITERIANO=C.CRITERIANO)
		join	"+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"

		Set @sSQLString2="
		where   C.CASETYPE        <>I.CASETYPE         or (C.CASETYPE         is not null and I.CASETYPE         is null) or (C.CASETYPE         is null and I.CASETYPE         is not null)
		or      C.ACTION          <>I.ACTION           or (C.ACTION           is not null and I.ACTION           is null) or (C.ACTION           is null and I.ACTION           is not null)
		or      C.CHECKLISTTYPE   <>I.CHECKLISTTYPE    or (C.CHECKLISTTYPE    is not null and I.CHECKLISTTYPE    is null) or (C.CHECKLISTTYPE    is null and I.CHECKLISTTYPE    is not null)
		or      C.PROGRAMID       <>I.PROGRAMID        or (C.PROGRAMID        is not null and I.PROGRAMID        is null) or (C.PROGRAMID        is null and I.PROGRAMID        is not null)
		or      C.PROPERTYTYPE    <>I.PROPERTYTYPE     or (C.PROPERTYTYPE     is not null and I.PROPERTYTYPE     is null) or (C.PROPERTYTYPE     is null and I.PROPERTYTYPE     is not null)
		or      C.PROPERTYUNKNOWN <>I.PROPERTYUNKNOWN  or (C.PROPERTYUNKNOWN  is not null and I.PROPERTYUNKNOWN  is null) or (C.PROPERTYUNKNOWN  is null and I.PROPERTYUNKNOWN  is not null)
		or      C.COUNTRYCODE     <>I.COUNTRYCODE      or (C.COUNTRYCODE      is not null and I.COUNTRYCODE      is null) or (C.COUNTRYCODE      is null and I.COUNTRYCODE      is not null)
		or      C.COUNTRYUNKNOWN  <>I.COUNTRYUNKNOWN   or (C.COUNTRYUNKNOWN   is not null and I.COUNTRYUNKNOWN   is null) or (C.COUNTRYUNKNOWN   is null and I.COUNTRYUNKNOWN   is not null)
		or      C.CASECATEGORY    <>I.CASECATEGORY     or (C.CASECATEGORY     is not null and I.CASECATEGORY     is null) or (C.CASECATEGORY     is null and I.CASECATEGORY     is not null)
		or      C.CATEGORYUNKNOWN <>I.CATEGORYUNKNOWN  or (C.CATEGORYUNKNOWN  is not null and I.CATEGORYUNKNOWN  is null) or (C.CATEGORYUNKNOWN  is null and I.CATEGORYUNKNOWN  is not null)
		or      C.SUBTYPE         <>I.SUBTYPE          or (C.SUBTYPE          is not null and I.SUBTYPE          is null) or (C.SUBTYPE          is null and I.SUBTYPE          is not null)
		or      C.SUBTYPEUNKNOWN  <>I.SUBTYPEUNKNOWN   or (C.SUBTYPEUNKNOWN   is not null and I.SUBTYPEUNKNOWN   is null) or (C.SUBTYPEUNKNOWN   is null and I.SUBTYPEUNKNOWN   is not null)
		or      C.BASIS           <>I.BASIS            or (C.BASIS            is not null and I.BASIS            is null) or (C.BASIS            is null and I.BASIS            is not null)
		or      C.REGISTEREDUSERS <>I.REGISTEREDUSERS  or (C.REGISTEREDUSERS  is not null and I.REGISTEREDUSERS  is null) or (C.REGISTEREDUSERS  is null and I.REGISTEREDUSERS  is not null)
		or      C.LOCALCLIENTFLAG <>I.LOCALCLIENTFLAG  or (C.LOCALCLIENTFLAG  is not null and I.LOCALCLIENTFLAG  is null) or (C.LOCALCLIENTFLAG  is null and I.LOCALCLIENTFLAG  is not null)
		or      C.TABLECODE       <>I.TABLECODE        or (C.TABLECODE        is not null and I.TABLECODE        is null) or (C.TABLECODE        is null and I.TABLECODE        is not null)
		or      C.RATENO          <>I.RATENO           or (C.RATENO           is not null and I.RATENO           is null) or (C.RATENO           is null and I.RATENO           is not null)
		or      C.DATEOFACT       <>I.DATEOFACT        or (C.DATEOFACT        is not null and I.DATEOFACT        is null) or (C.DATEOFACT        is null and I.DATEOFACT        is not null)
		or      C.USERDEFINEDRULE <>I.USERDEFINEDRULE  or (C.USERDEFINEDRULE  is not null and I.USERDEFINEDRULE  is null) or (C.USERDEFINEDRULE  is null and I.USERDEFINEDRULE  is not null)
		or     (C.RULEINUSE       = 1                 and isnull(I.RULEINUSE,0)=0) -- SQA13335 Rule in Use will only be changed if it is currently ON
		or      C.STARTDETAILENTRY<>I.STARTDETAILENTRY or (C.STARTDETAILENTRY is not null and I.STARTDETAILENTRY is null) or (C.STARTDETAILENTRY is null and I.STARTDETAILENTRY is not null)
		or      C.PARENTCRITERIA  <>I.PARENTCRITERIA   or (C.PARENTCRITERIA   is not null and I.PARENTCRITERIA   is null) or (C.PARENTCRITERIA   is null and I.PARENTCRITERIA   is not null)
		or      C.BELONGSTOGROUP  <>I.BELONGSTOGROUP   or (C.BELONGSTOGROUP   is not null and I.BELONGSTOGROUP   is null) or (C.BELONGSTOGROUP   is null and I.BELONGSTOGROUP   is not null)
		or      C.DESCRIPTION     <>I.DESCRIPTION      or (C.DESCRIPTION      is not null and I.DESCRIPTION      is null) or (C.DESCRIPTION      is null and I.DESCRIPTION      is not null)
		or      C.TYPEOFMARK      <>I.TYPEOFMARK       or (C.TYPEOFMARK       is not null and I.TYPEOFMARK       is null) or (C.TYPEOFMARK       is null and I.TYPEOFMARK       is not null)
		or      C.RENEWALTYPE     <>I.RENEWALTYPE      or (C.RENEWALTYPE      is not null and I.RENEWALTYPE      is null) or (C.RENEWALTYPE      is null and I.RENEWALTYPE      is not null)
		or      C.CASEOFFICEID    <>I.CASEOFFICEID     or (C.CASEOFFICEID     is not null and I.CASEOFFICEID     is null) or (C.CASEOFFICEID     is null and I.CASEOFFICEID     is not null)"

		exec(@sSQLString1+@sSQLString2)
		
		Select 	@ErrorCode=@@error,
			@pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into CRITERIA(
			CRITERIANO,
			PURPOSECODE,
			CASETYPE,
			ACTION,
			CHECKLISTTYPE,
			PROGRAMID,
			PROPERTYTYPE,
			PROPERTYUNKNOWN,
			COUNTRYCODE,
			COUNTRYUNKNOWN,
			CASECATEGORY,
			CATEGORYUNKNOWN,
			SUBTYPE,
			SUBTYPEUNKNOWN,
			BASIS,
			REGISTEREDUSERS,
			LOCALCLIENTFLAG,
			TABLECODE,
			RATENO,
			DATEOFACT,
			USERDEFINEDRULE,
			RULEINUSE,
			STARTDETAILENTRY,
			PARENTCRITERIA,
			BELONGSTOGROUP,
			DESCRIPTION,
			TYPEOFMARK,
			RENEWALTYPE,
			CASEOFFICEID)
		select	I.CRITERIANO,
			I.PURPOSECODE,
			I.CASETYPE,
			I.ACTION,
			I.CHECKLISTTYPE,
			I.PROGRAMID,
			I.PROPERTYTYPE,
			I.PROPERTYUNKNOWN,
			I.COUNTRYCODE,
			I.COUNTRYUNKNOWN,
			I.CASECATEGORY,
			I.CATEGORYUNKNOWN,
			I.SUBTYPE,
			I.SUBTYPEUNKNOWN,
			I.BASIS,
			I.REGISTEREDUSERS,
			I.LOCALCLIENTFLAG,
			I.TABLECODE,
			I.RATENO,
			I.DATEOFACT,
			I.USERDEFINEDRULE,
			I.RULEINUSE,
			I.STARTDETAILENTRY,
			I.PARENTCRITERIA,
			I.BELONGSTOGROUP,
			I.DESCRIPTION,
			I.TYPEOFMARK,
			I.RENEWALTYPE,
			I.CASEOFFICEID
		from "+@sUserName+".Imported_CRITERIA I
		join "+@sUserName+".CRITERIAALLOWED T	on ( T.CRITERIANO=I.CRITERIANO)
		left join CRITERIA C	on ( C.CRITERIANO=I.CRITERIANO)
		where C.CRITERIANO is null"

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
grant execute on dbo.ip_RulesCRITERIA  to public
go

