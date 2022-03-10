-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListImageUsedBy									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListImageUsedBy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListImageUsedBy.'
	Drop procedure [dbo].[ipw_ListImageUsedBy]
End
Print '**** Creating Stored Procedure dbo.ipw_ListImageUsedBy...'
Print ''
GO

-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

Create procedure [dbo].[ipw_ListImageUsedBy]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pnImageKey		int -- mandatory
				
as
-- PROCEDURE :	ipw_ListImageUsedBy
-- VERSION :	2
-- DESCRIPTION:	Return the Cases and Names where Image is being used.
--
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------- 
-- 12-Mar-2010	PS	RFC6139	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

set nocount on
set concat_null_yields_null off
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

-- Declare variables
Declare	@nErrorCode		int

-- initialise variables	
Set @nErrorCode	= 0


If @nErrorCode = 0
Begin
	SELECT N.NAMENO as NameKey, N.NAMECODE as 'NameCode',  dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'DisplayName'
	FROM NAME N left join NAMEIMAGE NI  on (N.NAMENO = NI.NAMENO) 	
	WHERE IMAGEID = @pnImageKey
End

If @nErrorCode = 0
Begin
	SELECT  CASES.CASEID as CaseKey, IRN   as 'CaseReference'           
	FROM CASES left join CASEIMAGE  on (CASES.CASEID = CASEIMAGE.CASEID)
	WHERE IMAGEID = @pnImageKey  
End

RETURN @nErrorCode

GO

Grant execute on dbo.ipw_ListImageUsedBy to public
GO