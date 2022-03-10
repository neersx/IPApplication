-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListPotentialDuplicate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListPotentialDuplicate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListPotentialDuplicate.'
	Drop procedure [dbo].[na_ListPotentialDuplicate]
	Print '**** Creating Stored Procedure dbo.na_ListPotentialDuplicate...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_ListPotentialDuplicate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psName			nvarchar(254),
	@psGivenName		nvarchar(50),
	@pnRestrictToOffice	int		= null,
	@pnRowCount		int		= 0	output,
	@pbCalledFromCentura	bit		= 1,
	@pnAccessAccountKey	int		= 0
)
as
-- PROCEDURE:	na_ListPotentialDuplicate
-- VERSION:	20
-- SCOPE:	C/S Names program and WorkBenches
-- DESCRIPTION:	The stored procedure returns a result set of potential duplicate names and details about these names.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23-Jun-2003  Dw		1	Procedure created
-- 02-Oct-2003	MF	9276	2	Rewrite to address performance issues on a large database.
-- 27-Sep-2004	MF	9878	3	Allow the restriction of duplicate checking to Names belonging to
--					a specific Office or no Office.
-- 01/02/08	Dw	15774	4	filter out CRM names
-- 26/08/08	Dw	16442	5	extend to allow CRM Only names to be greyed out
-- 16/02/09	NG	RFC4026	6	to return duplicate names result set required for workbenches.
-- 05-Mar-2009  LP      RFC7654 7       Fix to be useable by WorkBenches import from MS Exchange.
-- 02-Apr-2009	NG	RFC4026 8	Fix to be used by WorkBenches in case duplicate check is required for more than one name.
-- 13-May-2009	NG	RFC7849	9	Implement duplicate name check for external users in workbenches.
-- 22-Jul-2009`	KR	RFC8109 10	Added SearchKey1 and SearchKey2
-- 04-Nov-2009	Dw	SQA18188 11	Increased size of variable @sNameType
-- 29-Apr-2011	Dw	SQA19573 12	Duplicate checking for individual names was not working for names with surnames < 8 chars
-- 07 Jul 2011	DL	RFC10830 13	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 27 Oct 2015	vql	R54041	14	Extend New Name window to allow middle name entry (DR-15641).
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).
-- 12 Apr 2016  MS      R52206  16      Add wrapquotes for @psName and @psGivenName to avoid sql injection
-- 19 Jul 2016	MF	64437	17	Include Row Access Security when checking for duplicate names.
-- 19 Jul 2016	MF	64438	18	Ethical Walls rules applied for logged on user.
-- 28 Jul 2016	MF	64570	19	Row Access Security for client/server added.
-- 29 Jul 2016	MF	64570	20	For client/server get the user using either SYSTEM_USER or dbo.fn_SystemUser().

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 		int
Declare	@sSQLString		nvarchar(max)
Declare @sSelect		nvarchar(max)
Declare @sWhere			nvarchar(max)
Declare @sFrom			nvarchar(max)
Declare	@sNameType		nvarchar(max)

Declare @bHasWBRowLevelSecurity	bit
Declare	@bOfficeSecurity	bit
Declare	@bNameTypeSecurity	bit

create table #tbDuplicates (	NAMENO		int,
				NAME		nvarchar(254) collate database_default,
				FIRSTNAME	nvarchar(50)  collate database_default,
				MIDDLENAME	nvarchar(50)  collate database_default,
				POSTALADDRESS	int,
				USEDASFLAG	smallint,
				ALLOW		int,
				STREETADDRESS	int,
				MAINCONTACT	int,
				MAINEMAIL	int,
				FAX		int,
				MAINPHONE	int,
				REMARKS		nvarchar(254) collate database_default,
				TITLE		nvarchar(20)  collate database_default,
				SEARCHKEY1	nvarchar(20)  collate database_default,
				SEARCHKEY2	nvarchar(20)  collate database_default)

Set @ErrorCode = 0
-- @sNameType is a comma separated list of name types not flagged as CRM only
If @ErrorCode = 0
Begin
	Select @sNameType=isnull(@sNameType,'')+
			CASE WHEN(@sNameType is NOT NULL) THEN "," ELSE '' END+
			"'"+NAMETYPE+"'"
	from NAMETYPE
	where (PICKLISTFLAGS&32)=0 -- Not CRM Only nametype
End

-- In WorkBenches, SearchKey1 is set to NAME, FIRSTNAME
-- 19573 included this logic for C/S too
If @ErrorCode = 0
Begin
        set @psName = @psName +', '+ @psGivenName 
End

If @ErrorCode = 0
Begin
        -- Strip out irrelevant words and remove unimportant characters and then take the first 8 characters
	set @psName=Upper(Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(@psName)),8))
        
        set @sSelect = "
        Insert into #tbDuplicates(NAMENO, NAME, FIRSTNAME, MIDDLENAME, POSTALADDRESS, USEDASFLAG, ALLOW, STREETADDRESS, MAINCONTACT, MAINEMAIL, FAX, MAINPHONE, REMARKS, TITLE, SEARCHKEY1, SEARCHKEY2)
        Select distinct N.NAMENO, N.NAME, N.FIRSTNAME, N.MIDDLENAME, N.POSTALADDRESS, N.USEDASFLAG, NTC.ALLOW, N.STREETADDRESS, N.MAINCONTACT, N.MAINEMAIL, N.FAX, N.MAINPHONE, N.REMARKS, N.TITLE, N.SEARCHKEY1, N.SEARCHKEY2
        "
        
        Set @sFrom = "
        from dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") N
        LEFT JOIN (	select NAMENO, max(ALLOW) as ALLOW
	        from NAMETYPECLASSIFICATION
	        where NAMETYPE not in ("+@sNameType+")
	        group by NAMENO) NTC2 ON (NTC2.NAMENO = N.NAMENO)
        LEFT JOIN (	select NAMENO, max(ALLOW) as ALLOW
	        from NAMETYPECLASSIFICATION  
	        where NAMETYPE in ("+@sNameType+")
	        group by NAMENO) NTC ON (NTC.NAMENO = N.NAMENO)
	        "
	        
	Set @sWhere = "
        where LEFT(Upper(
	        replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
	        (N.SEARCHKEY1	,	' ',''),
				        '&',''),
				        '(',''),
				        ')',''),
				        '-',''),
				        '+',''),
				        ':',''),
				        ';',''),
				        char(34),''),
				        char(39),''),
				        ',',''),
				        '.',''),
				        '/',''),
				        '\',''),
				        '^','')),8) = "+dbo.fn_WrapQuotes(@psName,0,0)+"
        and (NTC.ALLOW=1 OR NTC2.ALLOW=1)
        "
        
	-- if the given name is provided then add an extra condition to where clause
	If @psGivenName is not null
        Begin
		
		-- Get the first character of the Given Name
		set @psGivenName=Upper(Left(LTRIM(@psGivenName),1))

                set @sWhere = @sWhere+"
		and (Upper(Left(LTRIM(N.FIRSTNAME),1))="+dbo.fn_WrapQuotes(@psGivenName,0,0)+"
			or (N.FIRSTNAME is null and N.USEDASFLAG not in (0,4)))"
	End
	
	-----------------------------------------------
	-- Row Access Security is to also be considered
	-----------------------------------------------
	If @pbCalledFromCentura = 0
	Begin
		--------------------------------------------------------------------
		-- Check what level of Row Access Security has been defined.
		-- This will help tailor the generated SELECT to improve performance
		--------------------------------------------------------------------
		Set @sSQLString = "
		Select	@bHasWBRowLevelSecurity=SUM(CASE WHEN(R.RECORDTYPE IS NOT NULL) THEN 1 ELSE 0 END),
			@bOfficeSecurity       =SUM(CASE WHEN(R.OFFICE     IS NOT NULL) THEN 1 ELSE 0 END),
			@bNameTypeSecurity     =SUM(CASE WHEN(R.NAMETYPE   IS NOT NULL) THEN 1 ELSE 0 END)
		from IDENTITYROWACCESS U WITH (NOLOCK) 
		join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME
		                                     and R.RECORDTYPE = 'N') 
		where U.IDENTITYID = @pnUserIdentityId"
		
		exec @ErrorCode = sp_executesql @sSQLString,
			N'@bHasWBRowLevelSecurity	bit		output,
			  @bOfficeSecurity		bit		output,
			  @bNameTypeSecurity		bit		output,
			  @pnUserIdentityId		int',
			  @bHasWBRowLevelSecurity	= @bHasWBRowLevelSecurity	output,
			  @bOfficeSecurity		= @bOfficeSecurity		output,
			  @bNameTypeSecurity		= @bNameTypeSecurity		output,
			  @pnUserIdentityId		= @pnUserIdentityId
		
		 
	End
	Else Begin
		--------------------------------------------------------------------
		-- Check what level of Row Access Security has been defined.
		-- This will help tailor the generated SELECT to improve performance
		--------------------------------------------------------------------
		Set @sSQLString = "
		Select	@bHasWBRowLevelSecurity=SUM(CASE WHEN(R.RECORDTYPE IS NOT NULL) THEN 1 ELSE 0 END),
			@bOfficeSecurity       =SUM(CASE WHEN(R.OFFICE     IS NOT NULL) THEN 1 ELSE 0 END),
			@bNameTypeSecurity     =SUM(CASE WHEN(R.NAMETYPE   IS NOT NULL) THEN 1 ELSE 0 END)
		from USERROWACCESS U WITH (NOLOCK) 
		join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME
		                                     and R.RECORDTYPE = 'N') 
		where U.USERID in (SYSTEM_USER, dbo.fn_SystemUser())"
		
		exec @ErrorCode = sp_executesql @sSQLString,
			N'@bHasWBRowLevelSecurity	bit		output,
			  @bOfficeSecurity		bit		output,
			  @bNameTypeSecurity		bit		output',
			  @bHasWBRowLevelSecurity	= @bHasWBRowLevelSecurity	output,
			  @bOfficeSecurity		= @bOfficeSecurity		output,
			  @bNameTypeSecurity		= @bNameTypeSecurity		output
		
		 
	End
		
	If  @bHasWBRowLevelSecurity = 1
	Begin
		If @pbCalledFromCentura = 0
		Begin
			Set @sWhere = @sWhere
			+char(10)+"	and  Substring("          
			+char(10)+"		(select MAX (   CASE WHEN RAD.OFFICE    IS NULL THEN '0' ELSE '1' END +" 
			+char(10)+"				CASE WHEN RAD.NAMETYPE  IS NULL THEN '0' ELSE '1' END +"
			+char(10)+"				CASE WHEN RAD.SECURITYFLAG < 10 THEN '0' ELSE ''  END +"  
			+char(10)+"		convert(nvarchar,RAD.SECURITYFLAG))"   
			+char(10)+"		     from IDENTITYROWACCESS UA WITH (NOLOCK) "
			+char(10)+"		left join ROWACCESSDETAIL RAD WITH (NOLOCK) on (RAD.ACCESSNAME=UA.ACCESSNAME"  
		End
		Else Begin
			Set @sWhere = @sWhere
			+char(10)+"	and  Substring("          
			+char(10)+"		(select MAX (   CASE WHEN RAD.OFFICE    IS NULL THEN '0' ELSE '1' END +" 
			+char(10)+"				CASE WHEN RAD.NAMETYPE  IS NULL THEN '0' ELSE '1' END +"
			+char(10)+"				CASE WHEN RAD.SECURITYFLAG < 10 THEN '0' ELSE ''  END +"  
			+char(10)+"		convert(nvarchar,RAD.SECURITYFLAG))"   
			+char(10)+"		     from USERROWACCESS UA WITH (NOLOCK) "
			+char(10)+"		left join ROWACCESSDETAIL RAD WITH (NOLOCK) on (RAD.ACCESSNAME=UA.ACCESSNAME"  
		End

		---------------------------------------------------
		-- Performance improvement step to only restrict to 
		-- OFFICE if row access has been defined for OFFICE
		---------------------------------------------------					
		If @bOfficeSecurity=1
		begin
			-------------------------------------------------------------------------------
			-- RFC31341 The left join to TABLEATTRIBUEST has been deliberately moved out 
			--          of the WHERE clause because if a Name is associated with more than
			--          one office then we are interested in any rule that allows the user
			--          access to the Names associated with any of those offices.
			-------------------------------------------------------------------------------
			Set @sFrom = @sFrom+char(10)+" left join TABLEATTRIBUTES TA on (TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, N.NAMENO))"
			
			Set @sWhere = @sWhere
			+char(10)+"	and (RAD.OFFICE = TA.TABLECODE or RAD.OFFICE is NULL)" 
		end

		-------------------------------------------------------
		-- RFC13142
		-- Performance improvement step to only restrict to 
		-- NAMETYPE if row access has been defined for NAMETYPE
		-------------------------------------------------------	
		If @bNameTypeSecurity=1
			Set @sWhere = @sWhere
			+char(10)+"	and (RAD.NAMETYPE in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = N.NAMENO)" 
			+char(10)+"	  or RAD.NAMETYPE is NULL)" 


		If @pbCalledFromCentura = 0
		Begin
			Set @sWhere = @sWhere
			+char(10)+"					and RAD.RECORDTYPE = 'N')"  
			+char(10)+"	where UA.IDENTITYID = "+convert(nvarchar,@pnUserIdentityId)+"),   3,2)"
			+char(10)+"	in (  '01','03','05','07','09','10','11','13','15' )"   
		End 
		Else Begin
			Set @sWhere = @sWhere
			+char(10)+"					and RAD.RECORDTYPE = 'N')"  
			+char(10)+"	where UA.USERID in (SYSTEM_USER, dbo.fn_SystemUser())),   3,2)"
			+char(10)+"	in (  '01','03','05','07','09','10','11','13','15' )"   
		End  
	End
	
	Set @sSQLString=@sSelect+@sFrom+@sWhere

	exec (@sSQLString)
	Set @ErrorCode=@@Error

	
	If @pbCalledFromCentura = 1
	Begin
		If  @ErrorCode=0
		and @pnRestrictToOffice is NULL
		Begin
			Select N.NAMENO, N.NAME, N.FIRSTNAME, N.USEDASFLAG, N.ALLOW, A.CITY,O.OwnerCount, I.InstructorCount, D.DebtorCount
			from #tbDuplicates N
			left join ADDRESS A on (N.POSTALADDRESS = A.ADDRESSCODE)
			left join (select count(*) as OwnerCount, NAMENO
				from CASENAME
				where NAMETYPE='O'
				and EXPIRYDATE is null
				group by NAMENO) O	on (O.NAMENO=N.NAMENO)
			left join (select count(*) as InstructorCount, NAMENO
				from CASENAME
				where NAMETYPE='I'
				and EXPIRYDATE is null
				group by NAMENO) I	on (I.NAMENO=N.NAMENO)
			left join (select count(*) as DebtorCount, NAMENO
				from CASENAME
				where NAMETYPE='D'
				and EXPIRYDATE is null
				group by NAMENO) D	on (D.NAMENO=N.NAMENO)

			Select 	@ErrorCode =@@Error,
				@pnRowCount=@@RowCount
		End
	
		-- If the duplicate checking is to be restricted to a specific office then only individuals
		-- who are either marked as belonging to the given office or who have not been assigned an
		-- office at all are to be returned as potential duplicates.
		Else If  @ErrorCode=0
			and @pnRestrictToOffice is not NULL
		Begin
			Select N.NAMENO, N.NAME, N.FIRSTNAME, N.USEDASFLAG, N.ALLOW, A.CITY,O.OwnerCount, I.InstructorCount, D.DebtorCount, N.SEARCHKEY1, N.SEARCHKEY2
			from #tbDuplicates N
			left join ADDRESS A on (N.POSTALADDRESS = A.ADDRESSCODE)
			left join (select count(*) as OwnerCount, NAMENO
				from CASENAME
				where NAMETYPE='O'
				and EXPIRYDATE is null
				group by NAMENO) O	on (O.NAMENO=N.NAMENO)
			left join (select count(*) as InstructorCount, NAMENO
				from CASENAME
				where NAMETYPE='I'
				and EXPIRYDATE is null
				group by NAMENO) I	on (I.NAMENO=N.NAMENO)
			left join (select count(*) as DebtorCount, NAMENO
				from CASENAME
				where NAMETYPE='D'
				and EXPIRYDATE is null
				group by NAMENO) D	on (D.NAMENO=N.NAMENO)
			left join TABLEATTRIBUTES T	on (T.PARENTTABLE='NAME'
							and T.TABLETYPE=44
							and T.GENERICKEY=cast(N.NAMENO as varchar))
			where (T.TABLECODE=@pnRestrictToOffice
			or     T.TABLECODE is NULL
			or     N.USEDASFLAG not in (1,5))	-- only Individuals are to have office restriction

			Select 	@ErrorCode =@@Error,
				@pnRowCount=@@RowCount
		End
	End
	Else If @ErrorCode=0 and
		@pbCalledFromCentura = 0
	Begin
		Set @sSQLString="Insert into #tmpTableDuplicates"+char(10)+
			"Select"+char(10)+
			"Cast(N.NAMENO as nvarchar(20)) as RowKey,"+char(10)+ 
			"dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as Name,"+char(10)+
			"N.FIRSTNAME as GivenName, N.MIDDLENAME as MiddleName, N.USEDASFLAG as UsedAs, N.ALLOW as Allow,"+char(10)+
			"dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PC.POSTALNAME, PC.POSTCODEFIRST, PC.STATEABBREVIATED, SC.POSTCODELITERAL, PC.ADDRESSSTYLE) as PostalAddress,"+char(10)+
			"dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE) as StreetAddress,"+char(10)+
			"PA.CITY as City,"+char(10)+ 
			"O.OwnerCount as UsedAsOwner, I.InstructorCount as UsedAsInstructor, D.DebtorCount as UsedAsDebtor,"+char(10)+
			"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null) as MainContact,"+char(10)+
			"dbo.fn_GetMainTelecom(N.NAMENO, 1901) as Telephone,"+char(10)+
			"dbo.fn_GetMainTelecom(N.NAMENO, 1905) as WebSite,"+char(10)+
			"dbo.fn_GetMainTelecom(N.NAMENO, 1902) as Fax,"+char(10)+
			"dbo.fn_GetMainTelecom(N.NAMENO, 1903) as Email,"+char(10)+
			"N.REMARKS as Remarks,"+char(10)+
			"N.SEARCHKEY1 as SearchKey1,"+char(10)+
			"N.SEARCHKEY2 as SearchKey2"+char(10)+
			"from #tbDuplicates N"+char(10)+				
			-- For 'Postal Address'
			"left join ADDRESS PA on (N.POSTALADDRESS = PA.ADDRESSCODE)"+char(10)+
			"left join COUNTRY PC on (PA.COUNTRYCODE = PC.COUNTRYCODE)"+char(10)+
			"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE and PS.STATE = PA.STATE)"+char(10)+
			-- For 'Street Address'
			"left join ADDRESS SA on (N.STREETADDRESS = SA.ADDRESSCODE)"+char(10)+
			"left join COUNTRY SC on (SA.COUNTRYCODE = SC.COUNTRYCODE)"+char(10)+
			"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE and SS.STATE = SA.STATE)"+char(10)+
			-- For 'MainContactName' use Name.MainContact
			"left join NAME N1		on (N1.NAMENO  = N.MAINCONTACT)"+char(10)+		
			"left join (select count(*) as OwnerCount, NAMENO"+char(10)+
				"from CASENAME"+char(10)+
				"where NAMETYPE='O'"+char(10)+
				"and EXPIRYDATE is null"+char(10)+
				"group by NAMENO) O	on (O.NAMENO=N.NAMENO)"+char(10)+
			"left join (select count(*) as InstructorCount, NAMENO"+char(10)+
				"from CASENAME"+char(10)+
				"where NAMETYPE='I'"+char(10)+
				"and EXPIRYDATE is null"+char(10)+
				"group by NAMENO) I	on (I.NAMENO=N.NAMENO)"+char(10)+
			"left join (select count(*) as DebtorCount, NAMENO"+char(10)+
				"from CASENAME"+char(10)+
				"where NAMETYPE='D'"+char(10)+
				"and EXPIRYDATE is null"+char(10)+
				"group by NAMENO) D	on (D.NAMENO=N.NAMENO)" +char(10)+
		
			CASE WHEN @pnAccessAccountKey <> 0 THEN
			+	"join (select AAN.NAMENO, AN.RELATEDNAME from ACCESSACCOUNTNAMES AAN" +char(10)+
							"left join ASSOCIATEDNAME AN on (AAN.NAMENO = AN.NAMENO)" +char(10)+
							"where AAN.ACCOUNTID = @pnAccessAccountKey and AN.RELATIONSHIP = 'EMP') AA" +char(10)+
							"on (AA.RELATEDNAME = N.NAMENO)"
			ELSE " " END + char(10)+	
		
			CASE WHEN @pnRestrictToOffice is not NULL THEN
			+	"left join TABLEATTRIBUTES T"+char(10)+	
				"on (T.PARENTTABLE='NAME' and T.TABLETYPE=44 and T.GENERICKEY=cast(N.NAMENO as varchar))"
			ELSE " " END + char(10)+
			"where 1=1"+char(10)+	
				
			CASE WHEN @pnRestrictToOffice is not NULL THEN
			+	"and ((T.TABLECODE=@pnRestrictToOffice)"+char(10)+
			"or     T.TABLECODE is NULL"+char(10)+
			"or     N.USEDASFLAG not in (1,5))" 
			ELSE "" END + char(10)		
		
		Exec @ErrorCode = sp_executesql @sSQLString,
					N'@pnAccessAccountKey	int,
					  @pnRestrictToOffice 	int',
					@pnAccessAccountKey = @pnAccessAccountKey,
					@pnRestrictToOffice = @pnRestrictToOffice
				
		Select 	@ErrorCode =@@Error,
			@pnRowCount=@@RowCount
						
	End		
End

Return @ErrorCode
GO

Grant execute on dbo.na_ListPotentialDuplicate to public
GO