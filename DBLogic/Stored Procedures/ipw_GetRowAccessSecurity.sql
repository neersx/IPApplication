-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetRowAccessSecurity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetRowAccessSecurity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetRowAccessSecurity.'
	Drop procedure [dbo].[ipw_GetRowAccessSecurity]
End
Print '**** Creating Stored Procedure dbo.ipw_GetRowAccessSecurity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_GetRowAccessSecurity
(
	@pnSecurityFlag		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pnNameKey		int		= null,
	@psCaseTypeKey		nvarchar(2)	= null,
	@psPropertyTypeKey	nvarchar(2)	= null,
	@pnOfficeKey		int		= null,
	@psNameTypeKey		nvarchar(6)	= null,	
	@psRecordType		nvarchar(1)	= 'C',
	@pbCalledFromCentura	bit		= 0
)
as
-- THIS STORED PROCEDURE INTENTIONALLY RETURNS THE LEAST RESTRICTIVE ROW ACCESS PRIVILEGES
-- SO THAT THE LINKS TO CREATE NEW CASE OR TAKEOVER CASE APPEAR IN THE LEFT PANEL
-- EVEN IF THE USER IS RESTRICTED TO BE ABLE TO CREATE ONLY ONE CASE TYPE
-- PROCEDURE:	ipw_GetRowAccessSecurity
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Row Access Security flag for the user 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Oct 2009	LP	RFC6712	1	Procedure created
-- 06 Jan 2010	LP	RFC6712	2	Fix Name Row Security logic.
-- 12 Sep 2011	LP	R11251  3	Name restriction by Office should be independent of any site controls.
-- 28 Oct 2011	LP	R11476	4	Sort results by SECRURITYFLAG descending to return highest privilege available
--					Previously sorted ascending so lowest privilege is always returned.
-- 26 Dec 2011	DV	R11140	5	Check for Case Access Security.

-- 27 Aug 2012  MS      R12045  6       Fix OFFICEID issue of ROWACCESSDETAIL table
-- 03 Jul 2014	LP	R33261	7	Only apply best-fit logic when case/name data is available.
-- 07 Sep 2018	AV	74738	8	Set isolation level to read uncommited.
-- 28 Nov 2018  MS      DR-44781 9      Check office from CASE.OFFICEID also when Row Security Uses Case Office site control is false       


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode		int
declare @bHasRowAccessSecurity	bit
declare @bHasCaseAccessSecurity	bit
declare @bUseOfficeSecurity	bit
declare @sSQLString		nvarchar(max)
declare @nCaseAccessSecurityFlag	int	-- The security flag return from USERSTATUS
declare @bCaseDataAvailable	bit
declare @bNameDataAvailable	bit

-- Initialise variables
Set @nErrorCode = 0
Set @bHasRowAccessSecurity = 0
Set @bHasCaseAccessSecurity = 0
Set @bUseOfficeSecurity = 0
Set @pnSecurityFlag = 15		-- Set security flag to maximum level by default

If @pnCaseKey is not null
or @psCaseTypeKey is not null
or @psPropertyTypeKey is not null
or @pnOfficeKey is not null
	Set @bCaseDataAvailable = 1

If @pnNameKey is not null
or @psNameTypeKey is not null
	Set @bNameDataAvailable = 1
	
-- Set the Case Security level to the default value.
If @nErrorCode=0
and @pbCalledFromCentura = 0
Begin
	SELECT @nCaseAccessSecurityFlag = ISNULL(SC.COLINTEGER,15)
			FROM SITECONTROL SC WHERE SC.CONTROLID = 'Default Security'
End
	
-- Check if user has been assigned row access security profile
If @nErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	Set @sSQLString = 
	"Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = @psRecordType
	and U.IDENTITYID = @pnUserIdentityId"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bHasRowAccessSecurity	bit output,
					  @psRecordType			nvarchar(1)',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bHasRowAccessSecurity	= @bHasRowAccessSecurity OUTPUT,
					  @psRecordType			= @psRecordType
	
End

If  @nErrorCode = 0 
and @bHasRowAccessSecurity = 1
and @psRecordType = 'C'
Begin
	select @bUseOfficeSecurity = ISNULL(SC.COLBOOLEAN, 0)
	from SITECONTROL SC WITH (NOLOCK) 
	where SC.CONTROLID = 'Row Security Uses Case Office'
	
	Set @pnSecurityFlag = 0		-- Set to 0 since we know that Row Access has been applied
	If @bUseOfficeSecurity = 1
	Begin
		Set @sSQLString = 
			"SELECT @pnSecurityFlag = S.SECURITYFLAG
			from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
			+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
			+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
			+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
			FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U"+char(10)+
			CASE WHEN @pnCaseKey is not null THEN "join CASES C on (C.CASEID = @pnCaseKey)" ELSE "" END	
			+char(10)+"WHERE R.RECORDTYPE = 'C' "+
			CASE WHEN @pnCaseKey is not null THEN 
			+char(10)+"AND (R.CASETYPE = C.CASETYPE OR R.CASETYPE IS NULL)
			AND (R.PROPERTYTYPE = C.PROPERTYTYPE OR R.PROPERTYTYPE IS NULL) 
			AND (R.OFFICE = C.OFFICEID OR R.OFFICE IS NULL)" END
			+char(10)+"AND R.NAMETYPE IS NULL
			AND U.IDENTITYID = @pnUserIdentityId
			AND U.ACCESSNAME = R.ACCESSNAME "+
			CASE WHEN @psCaseTypeKey is not null THEN " AND (R.CASETYPE = @psCaseTypeKey or R.CASETYPE IS NULL)" ELSE "" END +
			CASE WHEN @psPropertyTypeKey is not null THEN " AND (R.PROPERTYTYPE = @psPropertyTypeKey or R.PROPERTYTYPE IS NULL)" ELSE "" END +
			CASE WHEN @pnOfficeKey is not null THEN " AND (R.OFFICE = @pnOfficeKey or R.OFFICE IS NULL)" ELSE "" END + char(10)+
			case when @bCaseDataAvailable = 1 THEN 
			"ORDER BY BESTFIT DESC, SECURITYFLAG DESC) S" ELSE "ORDER BY SECURITYFLAG DESC) S" END
			
	End
	Else
	Begin
		Set @sSQLString = 
			"SELECT @pnSecurityFlag = S.SECURITYFLAG
			from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
			+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
			+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
			+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
			FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U"+char(10)+
			CASE WHEN @pnCaseKey is not null THEN "join CASES C on (C.CASEID = @pnCaseKey)" ELSE "" END
			+char(10)+"WHERE R.RECORDTYPE = 'C'"+ 
			CASE WHEN @pnCaseKey is not null THEN 
			+char(10)+"AND (R.CASETYPE = C.CASETYPE OR R.CASETYPE IS NULL)
			AND (R.PROPERTYTYPE = C.PROPERTYTYPE OR R.PROPERTYTYPE IS NULL) 
			AND (R.OFFICE = C.OFFICEID OR R.OFFICE in (select TA.TABLECODE 
						from TABLEATTRIBUTES TA 
						where TA.PARENTTABLE='CASES' 
						and TA.TABLETYPE=44 
						and TA.GENERICKEY=convert(nvarchar, C.CASEID) )
				OR R.OFFICE IS NULL) " END
			+char(10)+"AND R.NAMETYPE IS NULL
			AND U.IDENTITYID = @pnUserIdentityId
			AND U.ACCESSNAME = R.ACCESSNAME "+
			CASE WHEN @psCaseTypeKey is not null THEN " AND (R.CASETYPE = @psCaseTypeKey or R.CASETYPE IS NULL)" ELSE "" END +
			CASE WHEN @psPropertyTypeKey is not null THEN " AND (R.PROPERTYTYPE = @psPropertyTypeKey or R.PROPERTYTYPE IS NULL)" ELSE "" END +
			CASE WHEN @pnOfficeKey is not null THEN " AND (R.OFFICE = @pnOfficeKey or R.OFFICE IS NULL)" ELSE "" END +char(10)+
			case when @bCaseDataAvailable = 1 THEN 
			"ORDER BY BESTFIT DESC, SECURITYFLAG DESC) S" ELSE "ORDER BY SECURITYFLAG DESC) S" END
	End		

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSecurityFlag		int output,
					  @pnUserIdentityId		int,
					  @pnCaseKey			int,
					  @psCaseTypeKey		nvarchar(2),
					  @psPropertyTypeKey		nvarchar(2),
					  @pnOfficeKey			int',
					  @pnSecurityFlag		= @pnSecurityFlag output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey,
					  @psCaseTypeKey		= @psCaseTypeKey,
					  @psPropertyTypeKey		= @psPropertyTypeKey,
					  @pnOfficeKey			= @pnOfficeKey  		
End

If  @nErrorCode = 0 
Begin
	Set @sSQLString = 
		"SELECT @bHasCaseAccessSecurity = 1,
			@nCaseAccessSecurityFlag = ISNULL(U.SECURITYFLAG,@nCaseAccessSecurityFlag) 
		FROM USERSTATUS U
		JOIN USERIDENTITY UI ON UI.LOGINID = U.USERID
		JOIN CASES C ON C.STATUSCODE = U.STATUSCODE
		WHERE UI.IDENTITYID = @pnUserIdentityId 
		AND C.CASEID = @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseAccessSecurityFlag	int output,
					  @bHasCaseAccessSecurity       int output,
					  @pnUserIdentityId		int,
					  @pnCaseKey			int',
					  @nCaseAccessSecurityFlag	= @nCaseAccessSecurityFlag output,
					  @bHasCaseAccessSecurity	= @bHasCaseAccessSecurity output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey 
	
	Set @sSQLString = 
		"SELECT @pnSecurityFlag = CASE 
					 WHEN @bHasCaseAccessSecurity = 0 and @bHasRowAccessSecurity = 0 THEN 
							CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@pnSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END 
					 WHEN @bHasCaseAccessSecurity = 0 and @bHasRowAccessSecurity = 1 THEN ISNULL(@pnSecurityFlag,15)
					 WHEN @bHasCaseAccessSecurity = 1 and @bHasRowAccessSecurity = 0 THEN 
							CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@pnSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END
					 ELSE 
							CASE WHEN ISNULL(@pnSecurityFlag,15) <= 
								CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@pnSecurityFlag,15)
								ELSE @nCaseAccessSecurityFlag END 
							     THEN ISNULL(@pnSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END
					 END"
				
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSecurityFlag		int output,
					  @nCaseAccessSecurityFlag	int,
					  @bHasCaseAccessSecurity	bit,
					  @bHasRowAccessSecurity	bit',
					  @pnSecurityFlag		= @pnSecurityFlag output,
					  @nCaseAccessSecurityFlag	= @nCaseAccessSecurityFlag,
					  @bHasCaseAccessSecurity	= @bHasCaseAccessSecurity,
					  @bHasRowAccessSecurity	= @bHasRowAccessSecurity			

	
End

If  @nErrorCode = 0 
and @bHasRowAccessSecurity = 1
and @psRecordType = 'N'
Begin
	Set @pnSecurityFlag = 0		-- Set to 0 since we know that Row Access has been applied
	Set @sSQLString=
		"SELECT @pnSecurityFlag = S.SECURITYFLAG
		from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
		+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
		+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
		+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
		FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U"+char(10)+
		CASE WHEN @pnNameKey is not null THEN "join NAME N on (N.NAMENO = @pnNameKey)" ELSE "" END		
		+char(10)+"WHERE R.RECORDTYPE = 'N'"+ 
		CASE WHEN @pnNameKey is not null THEN 
		+char(10)+"AND (R.NAMETYPE in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = N.NAMENO) OR R.NAMETYPE IS NULL)" END 
		+char(10)+"AND (R.CASETYPE IS NULL)
		AND (R.PROPERTYTYPE IS NULL)"+ 
		CASE WHEN @pnNameKey is not null THEN 
		+char(10)+"AND (R.OFFICE in (select TA.TABLECODE 
					from TABLEATTRIBUTES TA 
					where TA.PARENTTABLE='NAME' 
					and TA.TABLETYPE=44 
					and TA.GENERICKEY=convert(nvarchar, N.NAMENO))"
		+char(10)+" OR R.OFFICE IS NULL) AND (R.NAMETYPE in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = N.NAMENO) OR R.NAMETYPE IS NULL)" 
		ELSE "" END + 
		+char(10)+
		"AND U.IDENTITYID = @pnUserIdentityId 
		AND U.ACCESSNAME = R.ACCESSNAME"+
		CASE WHEN @psNameTypeKey is not null THEN " AND (R.NAMETYPE = @psNameTypeKey)" 
		ELSE "" END +
		char(10)+
		case when @bNameDataAvailable = 1 THEN 
		"ORDER BY BESTFIT DESC, SECURITYFLAG DESC) S" ELSE "ORDER BY SECURITYFLAG DESC) S" END
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSecurityFlag		int output,
					  @pnUserIdentityId		int,
					  @pnNameKey			int,
					  @psNameTypeKey		nvarchar(6)',
					  @pnSecurityFlag		= @pnSecurityFlag output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnNameKey			= @pnNameKey,
					  @psNameTypeKey		= @psNameTypeKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetRowAccessSecurity to public
GO
