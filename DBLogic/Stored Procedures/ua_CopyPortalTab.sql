-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_CopyPortalTab
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].ua_CopyPortalTab') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_CopyPortalTab.'
	Drop procedure [dbo].ua_CopyPortalTab
End
Print '**** Creating Stored Procedure dbo.ua_CopyPortalTab...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_CopyPortalTab
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnDeleteTabId		int		= null	-- Optionally do not copy this tab key
)
as
-- PROCEDURE:	ua_CopyPortalTab
-- VERSION:	6
-- DESCRIPTION:	Copy a set of Portal Tabs from default.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Sep 2007	SW	RFC5424	1	Procedure created
-- 11 Mar 2008	SW	RFC6099	2	Add copy translation
-- 30 Apr 2008	JCLG	RFC6487	3	Fix problem with nullable value
-- 03 Sep 2012  MS      R12650  4       Copy ModuleConfiguration from default configuration rather than 
--                                      copying it from all users data
-- 17 Jan 2013  DV	R266806	5	Check if TABNAME_TID is not null before inserting into TRANSLATEDTEXT
-- 03 Sep 2015	DV	R50260	6	Copy the Portal settings from the default setings
-- 28 May 2018	AV	70932	7	Duplicate key error when adding tab to Workbench

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode 	= 0

-- Check if any existing configurations
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Select @nRowCount = count(*) from PORTALTAB
		where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nRowCount		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @nRowCount		= @nRowCount		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

If @nRowCount = 0
Begin

	-- Copy PORTALTAB from default configuration
	If @nErrorCode = 0  
	Begin
		Set @sSQLString = " 
			Insert	into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID, CSSCLASSNAME, CANRENAME, CANDELETE, PARENTTABID)
			Select	P.TABNAME, @pnUserIdentityId, P.TABSEQUENCE, P.PORTALID, P.CSSCLASSNAME, P.CANRENAME, P.CANDELETE, P.TABID
			from	PORTALTAB P
			join	USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId)
			where	P.PORTALID = U.DEFAULTPORTALID
			and	(@pnDeleteTabId is null or P.TABID <> @pnDeleteTabId)
			and	P.PARENTTABID is null
                        and     P.IDENTITYID is null"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int,
						  @pnDeleteTabId	int',
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @pnDeleteTabId	= @pnDeleteTabId
	End

	-- Copy MODULECONFIGURATION from default configuration
	If @nErrorCode = 0  
	Begin
		Set @sSQLString = " 
			Insert	into MODULECONFIGURATION (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
			Select	@pnUserIdentityId, P.TABID, M.MODULEID, M.MODULESEQUENCE, M.PANELLOCATION, M.PORTALID
			from	MODULECONFIGURATION M
			join	PORTALTAB P on (P.PARENTTABID = M.TABID and P.IDENTITYID = @pnUserIdentityId)
			where   M.IDENTITYID is null  or M.IDENTITYID = @pnUserIdentityId"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId	= @pnUserIdentityId		
	End
	
	-- Delete modules added by user in default pages because they are copied above			  
	If @nErrorCode = 0
	Begin
	        Set @sSQLString = " 
			Delete	MODULECONFIGURATION 
			from	MODULECONFIGURATION M
			join	PORTALTAB P on (P.TABID = M.TABID and P.IDENTITYID is null)
			where   M.IDENTITYID = @pnUserIdentityId"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId	= @pnUserIdentityId
	End
	
	--Update th moduleconfig if any settings have been modified
	If @nErrorCode = 0
	Begin
	        Set @sSQLString = " 
			UPDATE PORTALSETTING SET MODULECONFIGID = MC1.CONFIGURATIONID 
			FROM PORTALSETTING PS 
			JOIN MODULECONFIGURATION MC on (MC.CONFIGURATIONID = PS.MODULECONFIGID 
							and MC.IDENTITYID is null)
			JOIN PORTALTAB PT on (PT.PARENTTABID = MC.TABID 
						and PT.IDENTITYID = @pnUserIdentityId)
			JOIN MODULECONFIGURATION MC1 on (MC1.TABID = PT.TABID 
						and MC1.MODULEID = MC.MODULEID)
			WHERE PS.IDENTITYID = @pnUserIdentityId and PS.MODULECONFIGID = MC.CONFIGURATIONID"
					
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId	= @pnUserIdentityId
	End
	
	If @nErrorCode = 0
	Begin
	        Set @sSQLString = " 
			Insert	into PORTALSETTING (MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)
			SELECT MC1.CONFIGURATIONID, @pnUserIdentityId, PS.SETTINGNAME, PS.SETTINGVALUE  
			FROM PORTALSETTING PS 
			JOIN MODULECONFIGURATION MC on (MC.CONFIGURATIONID = PS.MODULECONFIGID 
							and MC.IDENTITYID is null)
			JOIN PORTALTAB PT on (PT.PARENTTABID = MC.TABID 
						and PT.IDENTITYID = @pnUserIdentityId)
			JOIN MODULECONFIGURATION MC1 on (MC1.TABID = PT.TABID 
						and MC1.MODULEID = MC.MODULEID)
			WHERE PS.IDENTITYID IS NULL and not exists (SELECT 1 FROM PORTALSETTING 
							WHERE MODULECONFIGID = MC1.CONFIGURATIONID 
							and IDENTITYID = @pnUserIdentityId)"
					
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId	= @pnUserIdentityId
	End

	-- Copy TRANSLATEDTEXT
	-- Match the current PORTALTAB.TABNAME from the default set, and copy the TRANSLATEDTEXT
	-- correspond to the default set to the current set
	If @nErrorCode = 0  
	Begin
		Set @sSQLString = " 
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT, HASSOURCECHANGED)
			Select DISTINCT	C.TABNAME_TID, TT.CULTURE, TT.SHORTTEXT, TT.HASSOURCECHANGED
			from	TRANSLATEDTEXT TT
			join	PORTALTAB P on (TT.TID = P.TABNAME_TID)
			join	USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId)
			join	PORTALTAB C on (C.IDENTITYID = @pnUserIdentityId and C.TABNAME = P.TABNAME)
			where	P.PORTALID = U.DEFAULTPORTALID
			and	P.PARENTTABID is null
			and C.TABNAME_TID is not null"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId	= @pnUserIdentityId		
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_CopyPortalTab to public
GO