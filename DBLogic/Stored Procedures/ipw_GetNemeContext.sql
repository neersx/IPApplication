-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetNameContext
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetNameContext]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetNameContext.'
	Drop procedure [dbo].[ipw_GetNameContext]
	Print '**** Creating Stored Procedure dbo.ipw_GetNameContext...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE [dbo].[ipw_GetNameContext]
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture				nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameKey				int              
)
AS

-- PROCEDURE :	ipw_GetNameContext
-- VERSION :	2
-- DESCRIPTION:	Return a context identifier to caller i.e. WorkBenches so that it can be used  
--				to display custom content and colour based on that identifier 
-- MODIFICATIONS :
-- Date  		Who 				RFC 	Version Change
-- ------------ -------				---- 	------- ----------------------------------------------- 
-- 1 Apr 2008	Praveen Suhalka  	RFC5774	1		Procedure created
-- 7 May 2008	Siew Fai Hoy		RFC6570	2		Add prefix to stored procedure name, update comment and logic

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@nErrorCode		int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
    
	-- place holder
	Select 'Lead'

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetNameContext to public
GO
