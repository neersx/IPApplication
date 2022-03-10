-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseCopyProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseCopyProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseCopyProfile.'
	Drop procedure [dbo].[csw_ListCaseCopyProfile]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseCopyProfile...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.csw_ListCaseCopyProfile
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnCaseKey			nvarchar(11)		-- Mandatory 

-- PROCEDURE :	csw_ListCaseCopyProfile
-- VERSION :	4
-- DESCRIPTION:	Returns a list of Case Copy Profiles.
-- SCOPE:	Clerical WorkBench

-- MODIFICTIONS :
-- Date         Change	Who  Version	Description
-- -----------	-------	---- ------- 	------------------------------------------- 
-- 14 Nov 2007	RFC5704	LP         1	Procedure created
-- 08 Jan 2008	RFC3210	LP	   2	Do not exclude Profiles linked to Country Flag
-- 11 Mar 2009  RFC6373 LP         3    Return DefaultRelationship and MustCopyRelation columns.
-- 04 Nov 2011	R11460 ASH	   4	Change @pnCaseKey to nvarchar(11)   
-- 06 Aug 2014	R37850	JD	   5	DR-6054 A default copy profile for Maketing events to be provided

as 

set nocount on
set concat_null_yields_null off

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(2000)
Declare @sFrom		nvarchar(2000)
Declare @sWhere		nvarchar(2000)
Declare	@sCaseType	nvarchar(100)
Declare @sCrmCaseTypes	nvarchar(100)
Declare @psSeparator	nvarchar(100)
Set	@nErrorCode	= 0
set	@sWhere		= char(10)+"	WHERE 1=1"
Set	@psSeparator	= ','
		
Select @sCrmCaseTypes = nullif(@sCrmCaseTypes+@psSeparator, @psSeparator) + CASETYPE
	from CASETYPE where CRMONLY = 1
	
-- Profile
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select 	DISTINCT
		CP.[PROFILENAME] as ProfileKey,
		CP.[PROFILENAME] as ProfileName,
		REL.[CHARACTERKEY] as DefaultRelationship,
		REL.[PROTECTCOPY] as MustCopyRelation
	From	[COPYPROFILE] CP
	join 	CASES C on		(C.CASEID = @pnCaseKey)
	left join [COPYPROFILE] REL ON	(REL.[PROFILENAME] = CP.[PROFILENAME]
						AND REL.[COPYAREA] = 'ADD_RELATIONSHIP')"

	Select @sCaseType = CASETYPE
	From CASES
	Where CASEID = @pnCaseKey

	If CHARINDEX(@sCaseType, @sCrmCaseTypes) > 0
	Begin
		Set @sWhere = @sWhere+char(10)+"and cp.CRMONLY = 1 "
	End
	Else
	Begin
		Set @sWhere = @sWhere+char(10)+"and cp.CRMONLY <> 1 "
	End

	Set @sWhere = @sWhere+char (10)+"and (
			REL.CHARACTERKEY IS NULL 
			OR
			REL.CHARACTERKEY IN 
				(Select VR.RELATIONSHIP
				from VALIDRELATIONSHIPS VR 
				where 
				C.PROPERTYTYPE = VR.PROPERTYTYPE AND
				VR.COUNTRYCODE = 
				( 	select min( VR1.COUNTRYCODE )
					from VALIDRELATIONSHIPS VR1
					where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE )
						and VR1.PROPERTYTYPE = C.PROPERTYTYPE
					AND VR1.RELATIONSHIP = VR.RELATIONSHIP 
				))
			)
		ORDER BY CP.PROFILENAME"
		
	set @sSQLString = @sSQLString+@sWhere

	Exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnCaseKey    int',
		@pnCaseKey	    = @pnCaseKey
End

RETURN @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.csw_ListCaseCopyProfile to public
go