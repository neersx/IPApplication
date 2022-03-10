-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteOfficialNumber.'
	Drop procedure [dbo].[csw_DeleteOfficialNumber]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteOfficialNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteOfficialNumber
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@psOfficialNumber		nvarchar(36),	-- Mandatory	
	@psNumberTypeCode		nvarchar(3),	-- Mandatory	
	@pbOldIsCurrent			bit		= null,
	@pdtOldDateEntered		datetime	= null,
	@pbIsCurrentInUse		bit		= 0,
	@pbIsDateEnteredInUse		bit		= 0,
	@pdtLastModifiedDate		datetime	= null
)
as
-- PROCEDURE:	csw_DeleteOfficialNumber
-- VERSION:	3
-- DESCRIPTION:	Delete an official number if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Sep 2005	TM		1	Procedure created
-- 27 Oct 2011	SF	R10553	2	Added Last Modified Date
-- 19 May 2020	DL	DR-58943	3	Ability to enter up to 3 characters for Number type code via client server	


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If  @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete 
	from OFFICIALNUMBERS	
	where	CASEID 		= @pnCaseKey
	and 	OFFICIALNUMBER	= @psOfficialNumber
	and	NUMBERTYPE 	= @psNumberTypeCode"
	
	If (@pdtLastModifiedDate is not null)
	Begin
		Set @sSQLString = @sSQLString + "
		and	LOGDATETIMESTAMP = @pdtLastModifiedDate
		" 
	End

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @psOfficialNumber	nvarchar(36),
				  @psNumberTypeCode	nvarchar(3),
				  @pbOldIsCurrent	bit,
				  @pdtOldDateEntered	datetime,
				  @pdtLastModifiedDate	datetime',
				  @pnCaseKey		= @pnCaseKey,
				  @psOfficialNumber	= @psOfficialNumber,
				  @psNumberTypeCode	= @psNumberTypeCode,
				  @pbOldIsCurrent	= @pbOldIsCurrent,
				  @pdtOldDateEntered	= @pdtOldDateEntered,
				  @pdtLastModifiedDate	= @pdtLastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteOfficialNumber to public
GO
