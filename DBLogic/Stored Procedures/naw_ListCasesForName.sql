-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListCasesForName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListCasesForName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListCasesForName.'
	Drop procedure [dbo].[naw_ListCasesForName]
	Print '**** Creating Stored Procedure dbo.naw_ListCasesForName...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListCasesForName
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,	
	@pnNameKey		int,		-- Mandatory, the name the results are required for.
	@psNameTypeKey		nvarchar(3)	-- Mandatory, the Name Type the NameKey has to the cases to be reported.
)
AS 
-- PROCEDURE:	naw_ListCasesForName
-- VERSION:	2
-- SCOPE:	Inprotech Web
-- DESCRIPTION:	Returns cases where the client name is of a selected Name Type.
-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 13 Dec 2011  vql	RFC10456	1	Procedure created.
-- 24 Aug 2017	MF	71721		2	Ethical Walls rules applied for logged on user.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
			
If (@nErrorCode = 0) and (@psNameTypeKey is not null) and (@pnNameKey is not null)
Begin
	Set @sSQLString = "Select C.CASEID as CaseKey, @pnNameKey as NameKey, IRN as IRN, C.CURRENTOFFICIALNO as OfficialNumber, C.TITLE as Title, S.INTERNALDESC as CaseStatus
			   from dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C
			   join CASENAME CN on (CN.CASEID = C.CASEID)
			   left join STATUS S on (C.STATUSCODE = S.STATUSCODE)
			   where CN.NAMENO = @pnNameKey and CN.NAMETYPE = @psNameTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psNameTypeKey	nvarchar(3)',
					  @pnNameKey		= @pnNameKey,
					  @psNameTypeKey	= @psNameTypeKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListCasesForName to public
GO