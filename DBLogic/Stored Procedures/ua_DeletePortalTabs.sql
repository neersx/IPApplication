-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeletePortalTabs
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeletePortalTabs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeletePortalTabs.'
	Drop procedure [dbo].[ua_DeletePortalTabs]
End
Print '**** Creating Stored Procedure dbo.ua_DeletePortalTabs...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeletePortalTabs
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
as
-- PROCEDURE:	ua_DeletePortalTabs
-- VERSION:	4
-- DESCRIPTION:	Delete portal tabs of an user

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Feb 2008	SW	RFC6099	1	Procedure created
-- 03 Sep 2012  MS      R12650  2       Delete all MODULECONFIGURATION rows for the user
-- 03 Sep 2015  DV      R50260  3       Delete all PORTALSETTING rows for the user
-- 24 May 2016	MF	60860	4	The PORTALSETTING table references MODULECONFIGURATION which references PORTALTAB.
--					The delete needs to consider these relationships effectively like a cascade delete.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nTabSequence	tinyint
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode 	= 0

-- Remove settings data
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete P
		from PORTALSETTING P
		join MODULECONFIGURATION M on (M.CONFIGURATIONID=P.MODULECONFIGID)
		join PORTALTAB T           on (T.TABID=M.TABID)
		where (T.IDENTITYID=@pnUserIdentityId
		   or  P.IDENTITYID=@pnUserIdentityId
		   or  M.IDENTITYID=@pnUserIdentityId)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int',
					  @pnUserIdentityId		= @pnUserIdentityId
End


-- Remove modules that are associated to tabs
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete M 
		from MODULECONFIGURATION M
		join PORTALTAB T on (T.TABID=M.TABID)
		where (T.IDENTITYID=@pnUserIdentityId
		   or  M.IDENTITYID=@pnUserIdentityId)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int',
					  @pnUserIdentityId		= @pnUserIdentityId
End

-- Remove tabs
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete PORTALTAB
		where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int',
					  @pnUserIdentityId		= @pnUserIdentityId
End


Return @nErrorCode
GO

Grant execute on dbo.ua_DeletePortalTabs to public
GO