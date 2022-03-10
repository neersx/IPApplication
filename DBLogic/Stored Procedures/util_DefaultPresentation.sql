-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_DefaultPresentation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].util_DefaultPresentation') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_DefaultPresentation.'
	Drop procedure [dbo].util_DefaultPresentation
End
Print '**** Creating Stored Procedure dbo.util_DefaultPresentation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.util_DefaultPresentation
(
	@pnPresentationID	int	-- Optional, if provided, presentation will be defaulted for the context.
)
as
-- PROCEDURE:	util_DefaultPresentation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	A utility to allow an existing saved external search to be converted to 
--		a default presentation for that context. 
--		Note: the original saved search will be reset as alternate presentation (not default).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	----	------	-------	----------------------------------------------- 
-- 07 May 2007	SW	RFC4795       1	Procedure created
-- 01 Jun 2008	LP	RFC6684       2	Modified to create copy of specified presentation instead of replacing state of existing default
--					Copy QUERYCONTENT rows from specified presentation

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @nPresentationID int

-- Initialise variables
Set @nErrorCode = 0

If @pnPresentationID is not null
Begin
	-- Reset existing default presentation of the context if any
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Update	QUERYPRESENTATION
			set	ISDEFAULT = 0,
				ISPROTECT = 0
			where	PRESENTATIONID in (
				select P.PRESENTATIONID
				from QUERYPRESENTATION as P
				join QUERYPRESENTATION as DFP on (DFP.CONTEXTID = P.CONTEXTID)
				where DFP.PRESENTATIONID = @pnPresentationID
				and P.ISDEFAULT = 1)"

		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnPresentationID		int',
					  @pnPresentationID		= @pnPresentationID
	End
	
	-- Insert copy of specified default presentation
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		INSERT INTO QUERYPRESENTATION(CONTEXTID,IDENTITYID,ISDEFAULT,REPORTTITLE,REPORTTEMPLATE,REPORTTOOL,EXPORTFORMAT,PRESENTATIONTYPE,ACCESSACCOUNTID,ISPROTECT)
		SELECT CONTEXTID,NULL,1,REPORTTITLE,REPORTTEMPLATE,REPORTTOOL,EXPORTFORMAT,PRESENTATIONTYPE,NULL,1 FROM QUERYPRESENTATION QP
		where QP.PRESENTATIONID = @pnPresentationID
		
		Set @nPresentationID = SCOPE_IDENTITY()"
		
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnPresentationID		int,
					  @nPresentationID		int	OUTPUT',
					  @pnPresentationID		= @pnPresentationID,
					  @nPresentationID		= @nPresentationID	OUTPUT
	End
	-- Insert new QUERYCONTENT based on original presentation
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		insert into QUERYCONTENT (PRESENTATIONID, CONTEXTID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION)
		select @nPresentationID, P.CONTEXTID, C.COLUMNID, C.DISPLAYSEQUENCE, C.SORTORDER, C.SORTDIRECTION
		from QUERYCONTENT C
		left join QUERYPRESENTATION P on (P.PRESENTATIONID = @pnPresentationID)
		where C.PRESENTATIONID = @pnPresentationID"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPresentationID    int,
					  @pnPresentationID    int',
					  @nPresentationID    = @nPresentationID,
					  @pnPresentationID    = @pnPresentationID
		
	End
End


Return @nErrorCode
GO

Grant execute on dbo.util_DefaultPresentation to public
GO
