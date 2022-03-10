-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_IsPolicingOutstanding
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_IsPolicingOutstanding]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_IsPolicingOutstanding.'
	Drop procedure [dbo].[ipn_IsPolicingOutstanding]
End
Print '**** Creating Stored Procedure dbo.ipn_IsPolicingOutstanding...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipn_IsPolicingOutstanding
(	
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@psCaseKeys				nvarchar(max),	-- Mandatory, comma separated
	@pbIsExternalUser			bit		= 0,
	@pbCalledFromCentura			bit				= 0
)
as
-- PROCEDURE:	ipn_IsPolicingOutstanding
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a result set indicating the cases pending policing.  Called by WorkBenches.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 JAN 2008	SF		1	Procedure created
-- 28 Sep 2018	MF	74987	2	CaseKeys parameter changed to nvarchar(max) from nvarchar(1000) to avoid trunction of list of CaseKeys.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
-- Initialise variables
Set @nErrorCode 	= 0

If  @pbIsExternalUser is null
and @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	Output,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	Output,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- Find out if Policing is Pending
If @nErrorCode=0
and @psCaseKeys is not null
Begin	
	Set @sSQLString = "
	Select  distinct C.CASEID as CaseKey,
			CASE 	WHEN P.CASEID is not null THEN cast(1 as bit) ELSE cast(0 as bit) END		as IsPolicingOutstanding		
	from CASES C" +
	-- Validate that the user has access to the Case passed as a parameter if the
	-- user is not an internal user	
	Case WHEN @pbIsExternalUser = 1
		THEN CHAR(10)+"	join dbo.fn_FilterUserCases(@pnUserIdentityId,1,null) VIEWABLE on (C.CASEID = VIEWABLE.CASEID)" END + char(10) + 
	-- IsPolicingOutstanding is true if there is a row in 
	-- the POLICING table for the CaseKey where SYSGENERATEDFLAG = 1:		
	"left join POLICING P on (P.SYSGENERATEDFLAG = 1 and P.CASEID = C.CASEID)		
	where C.CASEID in (" +  @psCaseKeys + ")"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKeys	nvarchar(max),	
				  @pnUserIdentityId int',
				  @psCaseKeys	= @psCaseKeys,
				  @pnUserIdentityId = @pnUserIdentityId

End
Else If @psCaseKeys is null
Begin
	Select null as CaseKey,
			null as IsPolicingOutstanding
	From CASES 
	WHERE 1=0
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_IsPolicingOutstanding to public
GO
