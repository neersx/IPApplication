-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCorrespondenceNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCorrespondenceNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCorrespondenceNames.'
	Drop procedure [dbo].[csw_GetCorrespondenceNames]
End
Print '**** Creating Stored Procedure dbo.csw_GetCorrespondenceNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCorrespondenceNames
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnLetterNo		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_GetCorrespondenceNames
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the list of names used as correspondence for the letter.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 10 Dec 2018	LP	DR-46020	1	Procedure created
-- 08-Feb-2019	LP	DR-46264	2	Ability to call a data-item to filter the name list

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @tblNameIds	TABLE (NAMENO int not null)
declare	@nErrorCode	int
declare @nDocItemId	int
declare @sDocItem	nvarchar(40)
declare @sCaseRef	nvarchar(50)
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0
Set @sDocItem = 'CPA_FORMSVC_CORRESPONDENCE'

If @nErrorCode = 0
Begin
	select @nDocItemid = I.ITEM_ID 
	from ITEM I
	where I.ITEM_NAME = @sDocItem
	and DATALENGTH(I.SQL_QUERY) > 0
End

If @nErrorCode = 0 
and @nDocItemId is not null
Begin
	select @sCaseRef = C.IRN
	from CASES C
	where C.CASEID = @pnCaseKey
	
	insert into @tblNameIds
	exec @nErrorCode=dbo.[ipw_FetchDocItem]
				@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= 0,
				@psDocItem		= @sDocItem,
				@psEntryPoint		= @sCaseRef,
				@psEntryPointP1		= @pnLetterNo,
				@psEntryPointP2		= null,						
				@bIsCSVEntryPoint	= 0,
				@pbOutputToVariable	= 0,
				@psOutputString		= null

	select NAMENO as NameKey
	from @tblNameIds
End
Else Begin
	SELECT CN.NAMENO as NameKey
	from LETTER L
	join CORRESPONDTO CT on (L.CORRESPONDTYPE = CT.CORRESPONDTYPE) 
	join CASENAME CN on (CN.CASEID = @pnCaseKey
		and CN.NAMETYPE=CT.NAMETYPE
		and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())) 
	where L.LETTERNO = @pnLetterNo	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetCorrespondenceNames to public
GO
