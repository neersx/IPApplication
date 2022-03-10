---------------------------------------------------------------------------------------------
-- Creation of dbo.ip_GetUserIdentityName
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetUserIdentityName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetUserIdentityName.'
	drop procedure [dbo].[ip_GetUserIdentityName]
	Print '**** Creating Stored Procedure dbo.ip_GetUserIdentityName...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_GetUserIdentityName
(
    @pnUserIdentityId		int 		= null,
    @psCulture			nvarchar(10) 	= null,   
    @pbCalledFromCentura	bit		= 0
)    
AS
-- PROCEDURE :	ip_GetUserIdentityName
-- VERSION :	2
-- DESCRIPTION:	A procedure to return the name of the supplied user identity, formatted for display.
-- MODIFICATIONS :
-- Date  	Who 	RFC 	Version Change
-- ------------ ------- ---- 	------- ----------------------------------------------- 
-- 29 Apr 2005  TM  	RFC2554	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@nErrorCode		int
Declare 	@sSQLString		nvarchar(4000)

-- Initialise the variables
Set @nErrorCode   = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
	from USERIDENTITY UI
	join NAME N	on (N.NAMENO = UI.NAMENO)
	where UI.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId     =@pnUserIdentityId		
End	

Return @nErrorCode
GO

Grant execute on dbo.ip_GetUserIdentityName to public
GO

