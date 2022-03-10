SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListEventDocument]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListEventDocument.'
	Drop procedure [dbo].[ip_ListEventDocument]
End
Print '**** Creating Stored Procedure dbo.ip_ListEventDocument...'
Print ''
GO

CREATE PROCEDURE dbo.ip_ListEventDocument
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int,		-- Mandatory
	@pnEventKey		int		-- Mandatory
)
-- PROCEDURE:	ip_ListEventDocument
-- VERSION:	2
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Lists the documents that will be produced when an event is updated.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 26-Mar-2003  JEK	1	Procedure created.  RFC03 Case Workflow.
-- 03-Apr-2003	JEK	2	Change column names to match resources.

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
	From REMINDERS R
	Join LETTER L		on (L.LETTERNO = R.LETTERNO)
	Where R.CRITERIANO = @pnCriteriaKey
	and R.EVENTNO = @pnEventKey
	and R.UPDATEEVENT = 2 -- Produce document when event updated
	Order by L.LETTERNAME, L.DOCUMENTCODE

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListEventDocument to public
GO

