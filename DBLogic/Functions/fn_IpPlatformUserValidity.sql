-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IpPlatformUserValidity
-----------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('dbo.fn_CheckValidityForIpPlatform') AND xtype IN ('FN'))
BEGIN
	PRINT '**** Drop function dbo.fn_CheckValidityForIpPlatform.'
	DROP FUNCTION dbo.fn_CheckValidityForIpPlatform
END
PRINT '**** Creating function dbo.fn_CheckValidityForIpPlatform...'
PRINT ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_CheckValidityForIpPlatform
(
	@pnUserIdentityId	int = NULL
)
RETURNS bit


-- FUNCTION :	fn_IpPlatformUserValidity
-- VERSION :	1
-- DESCRIPTION:	Determines apps is configured to use the IP Platform integration and the user is linked to SSO GUK.
-- WORD OF CAUTION: The data referenced here from ConfigurationSettings and UserIdentity table is added from Apps- only after specific steps are followed during Apps installation. 
--					Modifying the data MANUALLY will not get intended results in the Application. 					

-- MODIFICATION
-- Date			Who	Version Change
-- ====         ===	=== 	=======
-- 25 Jul 2017	SS	1		Function created

AS 
BEGIN
	 DECLARE @bvalidForIpPlatform bit 
	 
	 IF(@pnUserIdentityId IS NULL)
	 BEGIN
		 SELECT @bvalidForIpPlatform = CAST(COUNT(*) AS bit) FROM USERIDENTITY U
		 JOIN CONFIGURATIONSETTINGS CS ON CS.SETTINGKEY = 'InprotechServer.AppSettings.AuthenticationMode' AND CS.SETTINGVALUE LIKE '%Sso%'
	 END 
	 ELSE
	 BEGIN
		 SELECT @bvalidForIpPlatform = CAST(COUNT(*) AS bit) FROM USERIDENTITY U
		 JOIN CONFIGURATIONSETTINGS CS ON CS.SETTINGKEY = 'InprotechServer.AppSettings.AuthenticationMode' AND CS.SETTINGVALUE LIKE '%Sso%'
		 WHERE U.CPAGLOBALUSERID IS NOT NULL AND U.IDENTITYID = @pnUserIdentityId
	 END 
	 RETURN @bvalidForIpPlatform
END
     
GO

GRANT  REFERENCES, EXECUTE on dbo.fn_CheckValidityForIpPlatform to public
GO