-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_CanViewAttachments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_CanViewAttachments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_CanViewAttachments.'
	Drop procedure [dbo].[ipn_CanViewAttachments]
End
Print '**** Creating Stored Procedure dbo.ipn_CanViewAttachments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipn_CanViewAttachments
(
	@pbCanViewAttachments		bit		= null output,	
	@pnUserIdentityId	int		-- Mandatory		
)
as
-- PROCEDURE:	ipn_CanViewAttachments
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns bit indicating whether the user is allowed to view attachments (Information Security)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Oct 2007	SF	RFC4278	1	Procedure created - code taken from both csw_ListCaseDetails and cwb_ListCaseDetails
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 19 May 2015	DV	R47600	3	Remove check for WorkBench Attachments site control 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode				int
declare @sSQLString				nvarchar(4000)
declare @dtToday				datetime
Declare @bCanViewAttachments	bit

-- Initialise variables
Set @nErrorCode = 0
Set	@dtToday = getdate()

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select @pbCanViewAttachments = ISNULL(ATCHSEC.IsAvailable,0) "+char(10)+
	"From (select 1 as txt) tmp"+char(10)+
	"left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, default, @dtToday) ATCHSEC on (ATCHSEC.IsAvailable = 1)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	 	int,
					  @dtToday				datetime,
					  @pbCanViewAttachments	bit				OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @dtToday				= @dtToday,
					  @pbCanViewAttachments	= @pbCanViewAttachments	OUTPUT
					  	
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_CanViewAttachments to public
GO
