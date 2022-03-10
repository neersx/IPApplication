SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListEntryDocument]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListEntryDocument.'
	Drop procedure [dbo].[ip_ListEntryDocument]
End
Print '**** Creating Stored Procedure dbo.ip_ListEntryDocument...'
Print ''
GO

CREATE PROCEDURE dbo.ip_ListEntryDocument
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int,		-- Mandatory
	@pnEntryNumber		smallint	-- Mandatory
)
-- PROCEDURE:	ip_ListEntryDocument
-- VERSION:	2
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Returns the mandatory letters that will be produced for the entry.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 26-MAR-2003  JEK	1	Procedure created.  RFC03 Case Workflow.
-- 02-APR-2003	JEK	2	Change column names to match resources.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select	L.LETTERNO		as 'DocumentKey',
		L.LETTERNAME		as 'Document_DocumentDescription',
		L.DOCUMENTCODE		as 'Document_DocumentCode'
	From DETAILLETTERS D
	Join LETTER L		on (L.LETTERNO = D.LETTERNO)
	Where D.CRITERIANO = @pnCriteriaKey
	and D.ENTRYNUMBER = @pnEntryNumber
	and D.MANDATORYFLAG = 1
	Order by L.LETTERNAME, L.LETTERNO

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListEntryDocument to public
GO

