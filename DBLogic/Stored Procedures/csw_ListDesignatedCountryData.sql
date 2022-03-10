-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListDesignatedCountryData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].csw_ListDesignatedCountryData') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListDesignatedCountryData.'
	Drop procedure [dbo].csw_ListDesignatedCountryData
	Print '**** Creating Stored Procedure dbo.csw_ListDesignatedCountryData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListDesignatedCountryData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int	 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListDesignatedCountryData
-- VERSION:	23
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Dec 2007	LP	R3210	1	Procedure created
-- 07 Jan 2008	LP	R3210	2	Return NationalPhaseStatus flag column
-- 07 Feb 2008	LP	R3210	3	Return DateJoined and DateInstructed columns
-- 21 Apr 2010	ASH	R9152	4	Cast CURRENTSTATUS and DEFAULTFLAG to nvarchar(10).
-- 05 Apr 2011  LP      R10396	5	Use Filing Event Date(EVENTNO -4) for DateInstructed column, if it exists.
--					If it does not exist, then revert to Date Of Instruction (EVENTNO -16).
-- 07 Apr 2011  LP      R10453	6	Return NationalAllowedStatus result set.
-- 06 Sep 2011	LP	R10891	7	Return PreventNationalPhase column.
-- 02 Nov 2011	MF	R11492	8	Designated countries not displayed if there isn't at least one Status that has NationalAllowed flag set to 1.
-- 16 Dec 2011	KR	R11628	9	Added RELATIONSHIPNO to RowKey
-- 15 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer
-- 08 May 2013	MF	R13462	11	Designated Countries were not being displayed in some situations.
-- 07 Jun 2013  SW	DR58	12	Added Subsequent Designation Flag in Case Result set, Added filter on AvailableDesignatedCountryResultSet for
--					member country on basis of SubsequentDesignationAllowed flag, Changed the composition of RowKey for AvailableDesignatedCountryResultSet.
-- 05 Jun 2013	MS	DR60	13	return Classes in Selected Countries list
-- 10 Jun 2013	AK	DR59	14	return DesignatedDate in selected countries list
-- 12 Jun 2013  SW	DR65	15  return MembershipDate and IsExtensionState flag in Available and Selected country resultset.
-- 12 Jun 2013  SW	DR58	16	Reverted rowkey composition in AvailableCountry result set. 
-- 13 Jun 2013  SW	DR58	17	Added IsDesignated flag in Available Country result set.
-- 13 Jun 2013  SW	DR58	18	Fixed duplicate row issue in Available Country result set.
-- 21 Jun 2013  MS      DR60    19      Fix IsDefaultClasses select condition
-- 02 Jan 2014  DV	R27003	20	Return LOGDATETIMESTAMP column
-- 05 May 2014  MS      R33700  21      Return IsMultiClassAllowed attribute
-- 07 Dec 2017  DV	R73083	22	Return Designation for a Case even if it has been removed from the Country Group.
-- 14 Mar 2018	DV	R73394	23  Only show countries to designate that are relevant for property type of case.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare @pnRowCount		int
Declare @bIsSubsequentDesignationAllowed   bit

Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set	@bIsSubsequentDesignationAllowed = 0

-- Subsequent Designation Allowed
If @nErrorCode = 0
BEGIN
Set @sSQLString = "SELECT @bIsSubsequentDesignationAllowed = 1
					FROM TABLEATTRIBUTES TA
					JOIN CASES C on (TA.GENERICKEY = C.COUNTRYCODE)
					WHERE TA.PARENTTABLE = 'COUNTRY'		
					AND TA.TABLECODE = 5012
					AND C.CASEID = @pnCaseKey"
	Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int,
					@bIsSubsequentDesignationAllowed bit output',
					@pnCaseKey = @pnCaseKey,
					@bIsSubsequentDesignationAllowed = @bIsSubsequentDesignationAllowed output
END

-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @pnCaseKey   as CaseKey,
			NULL	    as SelectedCountryFlag,
			@bIsSubsequentDesignationAllowed as IsSubsequentDesignationAllowed,
			C.COUNTRYCODE as ParentCaseCountryCode,
			REPLACE(C.LOCALCLASSES,',',', ')   as ParentCaseLocalClasses
		from CASES C
		where C.CASEID = @pnCaseKey				
	"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				@bIsSubsequentDesignationAllowed bit',
				@pnCaseKey = @pnCaseKey,
				@bIsSubsequentDesignationAllowed = @bIsSubsequentDesignationAllowed
End

-- SelectedDesignatedCountry result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
		SELECT	
			R.COUNTRYCODE+'^'+CAST(CURRENTSTATUS as nvarchar(11))+'^'+CAST(RELATIONSHIPNO as nvarchar(11)) as RowKey,
			@pnCaseKey	as CaseKey,
			R.RELATIONSHIP	as RelationshipCode,	
			CS.IRN		as RelatedCaseReference,   		
			R.COUNTRYCODE	as CountryCode,	
			C.COUNTRY	as CountryName,    		
			R.ACCEPTANCEDETAILS as Comments,  		
			CF.FLAGNAME	as StatusDescription,	
			R.CURRENTSTATUS as StatusCode,  		
			R.RELATEDCASEID as RelatedCaseKey, 
			R.PRIORITYDATE as DesignatedDate, 
			ST.INTERNALDESC as CaseStatus,    
			0		as IsSelected,
			R.RELATIONSHIPNO as Sequence,
			isnull(G.DEFAULTFLAG,0)	as IsDefault,
			cast (ISNULL(G.ASSOCIATEMEMBER, 0) as bit) as IsExtensionState,
			CASE WHEN G.ASSOCIATEMEMBER = 1 THEN NULL ELSE G.FULLMEMBERDATE END AS MembershipDate,
			isnull(CF2.FLAGNUMBER,'') as NationalPhaseStatus,
			cast (ISNULL(G.PREVENTNATPHASE, 0) as bit) as PreventNationalPhase,
			REPLACE(
			     CASE WHEN CS.CASEID is not null
				THEN CS.LOCALCLASSES
			     WHEN R.CLASS is not null
				THEN R.CLASS
			     WHEN R.RELATIONSHIPNO = (SELECT MIN(RC1.RELATIONSHIPNO)
								FROM RELATEDCASE RC1
								WHERE RC1.CASEID = R.CASEID
								AND RC1.RELATIONSHIP = R.RELATIONSHIP
								AND RC1.COUNTRYCODE = R.COUNTRYCODE)
				THEN CS1.LOCALCLASSES 
			     ELSE null
			End,',',', ')	as Classes,
			CASE WHEN R.CLASS is null and CS.CASEID is null 
			                and R.RELATIONSHIPNO = (SELECT MIN(RC1.RELATIONSHIPNO)
								FROM RELATEDCASE RC1
								WHERE RC1.CASEID = R.CASEID
								AND RC1.RELATIONSHIP = R.RELATIONSHIP
								AND RC1.COUNTRYCODE = R.COUNTRYCODE)
				THEN 1 ELSE 0 
			END		as IsDefaultClasses,
			R.LOGDATETIMESTAMP as LastModifiedDate,
			CASE WHEN TA.GENERICKEY is not null THEN 1 ELSE 0 END as IsMultiClassAllowed
		FROM	RELATEDCASE R  		
		LEFT JOIN CASES CS1 ON (CS1.CASEID = @pnCaseKey)  	
		LEFT JOIN COUNTRYGROUP G ON (G.MEMBERCOUNTRY = R.COUNTRYCODE and G.TREATYCODE = CS1.COUNTRYCODE)  		
		JOIN COUNTRY C ON (C.COUNTRYCODE = R.COUNTRYCODE) 
		LEFT JOIN COUNTRYFLAGS CF ON (CF.COUNTRYCODE = CS1.COUNTRYCODE   						
					  AND CF.FLAGNUMBER = R.CURRENTSTATUS )  		
		LEFT JOIN CASES CS ON (CS.CASEID = R.RELATEDCASEID)			  		
		LEFT JOIN STATUS ST ON (ST.STATUSCODE = CS.STATUSCODE )    	  
		LEFT JOIN COUNTRYFLAGS CF2 ON (CF2.COUNTRYCODE = CS1.COUNTRYCODE
					   AND CF2.FLAGNUMBER = (SELECT MIN(FLAGNUMBER) from COUNTRYFLAGS
								 WHERE COUNTRYCODE = CS1.COUNTRYCODE 
								 AND NATIONALALLOWED = 1))
	        LEFT JOIN TABLEATTRIBUTES TA on (TA.PARENTTABLE = 'COUNTRY' 
	                                        and TA.GENERICKEY = R.COUNTRYCODE
	                                        and TA.TABLECODE = 5001)	                                                        
		WHERE	R.CASEID = @pnCaseKey    	     
		AND	R.RELATIONSHIP = 'DC1'
		ORDER BY COUNTRYCODE, R.PRIORITYDATE, Classes"       	


	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey = @pnCaseKey
End		 

-- AvailableDesignatedCountry result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
		Select distinct
			C.COUNTRYCODE+'^'+CAST(CG.DEFAULTFLAG as nvarchar(10)) as RowKey,
			@pnCaseKey	    as CaseKey,
			NULL		    as RelationshipCode,
			NULL		    as RelatedCaseReference,
			C.COUNTRYCODE	    as CountryCode, 
			C.COUNTRY	    as CountryName,   		
			NULL		    as Comments,
			CF.FLAGNAME	    as StatusDescription,
			CF.FLAGNUMBER	    as StatusCode,
			NULL		    as RelatedCaseKey,
			NULL		    as CaseStatus,
			0		    as IsSelected,
			CG.DEFAULTFLAG	    as IsDefault,
			CG.DATECOMMENCED    as DateJoined,
			cast (ISNULL(CG.ASSOCIATEMEMBER, 0) as bit) as IsExtensionState,
			CASE WHEN CG.ASSOCIATEMEMBER = 1 THEN NULL ELSE CG.FULLMEMBERDATE END AS MembershipDate,
			CASE WHEN R.COUNTRYCODE IS NULL THEN 0 ELSE 1 END AS IsDesignated,
			ISNULL(E.EVENTDATE, ISNULL(E2.EVENTDATE, getdate()))	as DateInstructed,
			isnull(CF2.FLAGNUMBER,'') as NationalPhaseStatus,
			cast (ISNULL(CG.PREVENTNATPHASE, 0) as bit) as PreventNationalPhase,
			CASE WHEN TA.GENERICKEY is not null THEN 1 ELSE 0 END as IsMultiClassAllowed
		From COUNTRYGROUP CG	
		join COUNTRY C	on (C.COUNTRYCODE=CG.MEMBERCOUNTRY)  	
		left join CASEEVENT E on (E.CASEID = @pnCaseKey
   					and E.EVENTNO = -4  			
					and E.CYCLE = 1)  	
		left join CASEEVENT E2 on (E.CASEID = @pnCaseKey
   					and E.EVENTNO = -16  			
					and E.CYCLE = 1)  				
		LEFT JOIN COUNTRYFLAGS CF ON (CF.COUNTRYCODE = CG.TREATYCODE)		
		LEFT JOIN CASES CS ON (CS.CASEID = @pnCaseKey)  
		LEFT JOIN COUNTRYFLAGS CF2 ON (CF2.COUNTRYCODE = CS.COUNTRYCODE
					   AND CF2.FLAGNUMBER = (Select min(FLAGNUMBER) 
								From COUNTRYFLAGS 
								where NATIONALALLOWED = 1 
								and COUNTRYCODE = CS.COUNTRYCODE)) 
		LEFT JOIN TABLEATTRIBUTES TA on (TA.PARENTTABLE = 'COUNTRY' 
	                                        and TA.GENERICKEY = CG.MEMBERCOUNTRY
	                                        and TA.TABLECODE = 5001)
		LEFT JOIN RELATEDCASE R ON (R.CASEID = @pnCaseKey and R.COUNTRYCODE = C.COUNTRYCODE)						
		where 	CG.TREATYCODE = CS.COUNTRYCODE	
		AND CF.FLAGNUMBER in (select min(FLAGNUMBER) 
					from COUNTRYFLAGS 
					where COUNTRYCODE = CG.TREATYCODE)	-- RFC13462 correction to remove incorrect prefix from COUNTRYCODE
		AND (CG.DATECEASED > isnull(E.EVENTDATE, getdate()) OR CG.DATECEASED is null)
		AND (CG.PROPERTYTYPES is null or CG.PROPERTYTYPES = '' or exists(select * from fn_Tokenise(CG.PROPERTYTYPES, ',') K where K.Parameter = CS.PROPERTYTYPE))
		"  If (@bIsSubsequentDesignationAllowed = 0)
			Begin
			set @sSQLString = @sSQLString + " 
				AND
				MEMBERCOUNTRY NOT IN (Select COUNTRYCODE 
					    From RELATEDCASE 
					    WHERE CASEID = @pnCaseKey 
					    AND COUNTRYCODE IS NOT NULL
					    AND RELATIONSHIP = 'DC1') 
		ORDER BY COUNTRY"
			End

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey = @pnCaseKey
End

-- NationalAllowedStatus result set
If @nErrorCode = 0
Begin
        Set @sSQLString = "Select       CF.COUNTRYCODE as CountryCode,
                                        CF.FLAGNUMBER as CountryFlag,
                                        CF.PROFILENAME as ProfileKey,
                                        CF.STATUS as StatusKey
                           From COUNTRYFLAGS CF
                           where CF.NATIONALALLOWED = 1                           
        "
        
        Exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.csw_ListDesignatedCountryData to public
go
