-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListTaskGrantedBy
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListTaskGrantedBy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListTaskGrantedBy.'
	Drop procedure [dbo].[sc_ListTaskGrantedBy]
End
Print '**** Creating Stored Procedure dbo.sc_ListTaskGrantedBy...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListTaskGrantedBy
(
	@pnTaskKey			int
)
as
-- PROCEDURE:	sc_ListTaskGrantedBy
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return all licenses that makes this task available

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 JUN 2008	SF	RFC6643	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select MODULEID as LicenseModuleKey
	from dbo.fn_ObjectLicense(@pnTaskKey, 20)
End

Return @nErrorCode
GO

Grant execute on dbo.sc_ListTaskGrantedBy to public
GO
