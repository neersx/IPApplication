-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetSecurityForName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetSecurityForName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetSecurityForName.'
	Drop procedure [dbo].[naw_GetSecurityForName]
End
Print '**** Creating Stored Procedure dbo.naw_GetSecurityForName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetSecurityForName
(
	@pnUserIdentityId 	int,		-- mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,			-- mandatory
	-- Output parameters
	@pbCanSelect		bit	= 0 output,
	@pbCanDelete		bit	= 0	output,
	@pbCanInsert		bit	= 0	output,
	@pbCanUpdate		bit	= 0	output
)
as
-- PROCEDURE:	naw_GetSecurityForName
-- VERSION :	2
-- SCOPE:	CPA.net
-- DESCRIPTION:	Get the row access security available for the specified Name
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 AUG 2010	DV	RFC9695	1	Procedure created
-- 12 Sep 2011	LP	R11251  2	Row access security by Name Office should be independent of site controls.
--					Also check PARENTTABLE = 'NAME' instead of 'EMPLOYEE'

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare 	@nErrorCode		int

Declare 	@nSecurityFlag  		int
Declare		@bHasRowAccessSecurity  bit

Declare		@sSQLString		nvarchar(4000) 

set @nSecurityFlag = 15			-- default to full row access
Set @nErrorCode = 0

Set @sSQLString ="
	Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'N'
	and U.IDENTITYID = @pnUserIdentityId"

exec @nErrorCode = sp_executesql @sSQLString,
				N'@bHasRowAccessSecurity 	bit		output,
				  @pnUserIdentityId	int', 
				  @bHasRowAccessSecurity	= 	@bHasRowAccessSecurity 	output,
			 	  @pnUserIdentityId	= @pnUserIdentityId

If @nErrorCode = 0
and @bHasRowAccessSecurity = 1
Begin
	Set @nSecurityFlag = 0			-- Set to 0 as we know Row Access has been applied
	Set @sSQLString ="
	SELECT @nSecurityFlag = S.SECURITYFLAG
	from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
		+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
		+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
		+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
		FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U, NAME N 		
		WHERE R.RECORDTYPE = 'N' 
		AND R.CASETYPE IS NULL
		AND R.PROPERTYTYPE IS NULL
		AND (R.OFFICE in (select TA.TABLECODE 
					from TABLEATTRIBUTES TA 
					where TA.PARENTTABLE='NAME' 
					and TA.TABLETYPE=44 
					and TA.GENERICKEY=convert(nvarchar, N.NAMENO) )
			OR R.OFFICE IS NULL) 
		AND (R.NAMETYPE in (SELECT NAMETYPE from NAMETYPECLASSIFICATION where NAMENO = @pnNameKey and ALLOW = 1)
			or R.NAMETYPE IS NULL)
		AND U.IDENTITYID = @pnUserIdentityId 
		AND U.ACCESSNAME = R.ACCESSNAME 
		AND N.NAMENO = @pnNameKey
		ORDER BY BESTFIT DESC, SECURITYFLAG ASC) S"

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nSecurityFlag 	int		output,
			  @pnNameKey		int,
			  @pnUserIdentityId	int', 
			  @nSecurityFlag	= 	@nSecurityFlag 	output,
			  @pnNameKey		= 	@pnNameKey,
		 	  @pnUserIdentityId	= @pnUserIdentityId			
End

if @nErrorCode = 0
Begin
	-- Check which rights they have.
	Set @pbCanSelect = case when (@nSecurityFlag & 1) > 0 then 1 else 0 end
	Set @pbCanDelete = case when (@nSecurityFlag & 2) > 0 then 1 else 0 end
	Set @pbCanInsert = case when (@nSecurityFlag & 4) > 0 then 1 else 0 end
	Set @pbCanUpdate = case when (@nSecurityFlag & 8) > 0 then 1 else 0 end
End

RETURN 	@nErrorCode
GO

Grant execute on dbo.naw_GetSecurityForName to public
GO
