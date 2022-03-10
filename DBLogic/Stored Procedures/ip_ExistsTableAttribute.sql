-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ExistsTableAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ExistsTableAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ExistsTableAttribute.'
	Drop procedure [dbo].[ip_ExistsTableAttribute]
	Print '**** Creating Stored Procedure dbo.ip_ExistsTableAttribute...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.ip_ExistsTableAttribute
(
	@pbExists		bit		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@psParentTable		nvarchar(50),	-- Mandatory
	@psGenericKey		nvarchar(20),	-- Mandatory
	@pnTableCode		int		-- Mandatory
)

-- PROCEDURE :	ip_ExistsTableAttribute
-- VERSION :	4
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Does the attribute exist against the parent table?

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 23 Oct 2002	JEK	1	Procedure created
--  1 Nov 2002	JEK	2	Change parameter name to @psGenericKey	


AS

Declare	@nErrorCode	 int
Set	@nErrorCode=0

Set @pbExists = 0

If @nErrorCode=0
Begin
	Select @pbExists = 1
	from TABLEATTRIBUTES
	where PARENTTABLE = @psParentTable
	and GENERICKEY = @psGenericKey
	and TABLECODE = @pnTableCode

	Set @nErrorCode=@@ERROR
End

RETURN @nErrorCode
GO

Grant execute on dbo.ip_ExistsTableAttribute to public
GO
