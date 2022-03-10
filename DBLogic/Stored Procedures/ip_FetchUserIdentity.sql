-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_FetchUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_FetchUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_FetchUserIdentity.'
	Drop procedure [dbo].[ip_FetchUserIdentity]
End
Print '**** Creating Stored Procedure dbo.ip_FetchUserIdentity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_FetchUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int
)
as
-- PROCEDURE:	ip_FetchUserIdentity
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate basic User Identity data

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Oct 2006  PG      RFC4338 1       Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Declare variables
declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

Begin
		Select
		U.IDENTITYID	as RowKey,
		U.IDENTITYID	as IdentityKey,
		U.LOGINID	as UserLoginID,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)
				as UserName
		from USERIDENTITY U
		join [NAME] N 	on (N.NAMENO=U.NAMENO)
		where U.IDENTITYID=@pnIdentityKey
		
		Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_FetchUserIdentity to public
GO