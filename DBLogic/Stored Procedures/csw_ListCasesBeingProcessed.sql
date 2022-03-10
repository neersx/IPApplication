-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCasesBeingProcessed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCasesBeingProcessed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCasesBeingProcessed.'
	Drop procedure [dbo].[csw_ListCasesBeingProcessed]
End
Print '**** Creating Stored Procedure dbo.csw_ListCasesBeingProcessed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_ListCasesBeingProcessed]
(	
	@pnUserIdentityId		int,		-- Mandatory		
	@psCulture			nvarchar(10)	= null,
	@psCaseKeys			nvarchar(max)	= null,
	@pbIsExternalUser		bit		= 0,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	csw_ListCasesBeingProcessed
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a result set indicating the cases pending policing or have been placed in Global Name Change queue.
--				Called by WorkBenches.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Change
-- -----------	----	-------	------- ------------------------------------------------------ 
-- 30 JAN 2009	SF	6693	1	Procedure created
-- 11 MAY 2011	MF	10604	2	Reduce the locking level to the lowest level.
-- 28 FEB 2013  AK	13157   3	Used fn_Tokenise to match casekeys.
-- 07 Sep 2018	AV	74738	4	Set isolation level to read uncommited.
-- 28 Sep 2018	MF	74987	5	CaseKeys parameter changed to nvarchar(max) from nvarchar(1000) to avoid trunction of list of CaseKeys.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

---------------------------------------
-- Reducing to the lowest locking level
---------------------------------------
set transaction isolation level read uncommitted

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

-- Find out if anything against the case is Pending
If @nErrorCode=0
and @psCaseKeys is not null
Begin	
	Set @sSQLString = "
	Select  distinct C.CASEID as CaseKey,
			CASE WHEN P.CASEID    is not null THEN cast(1 as bit) ELSE cast(0 as bit) END as IsPolicingOutstanding,
			CASE WHEN CNRC.CASEID is not null THEN cast(1 as bit) ELSE cast(0 as bit) END as IsGNCOutstanding
	from CASES C" +
	-- Validate that the user has access to the Case passed as a parameter if the
	-- user is not an internal user	
	Case WHEN @pbIsExternalUser = 1
		THEN CHAR(10)+"	join dbo.fn_FilterUserCases(@pnUserIdentityId,1,null) VIEWABLE on (C.CASEID = VIEWABLE.CASEID)" END + char(10) + 
	-- IsPolicingOutstanding is true if there is a row in 
	-- the POLICING table for the CaseKey where SYSGENERATEDFLAG = 1:		
	"left join POLICING P on (P.SYSGENERATEDFLAG = 1 and P.CASEID = C.CASEID)		
	 left join CASENAMEREQUESTCASES CNRC on (CNRC.CASEID = C.CASEID)
	 where C.CASEID in (select parameter from fn_Tokenise(@psCaseKeys,','))"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKeys		nvarchar(max),	
				  @pnUserIdentityId	int',
			          @psCaseKeys	    = @psCaseKeys,
				  @pnUserIdentityId = @pnUserIdentityId

End
Else If @psCaseKeys is null
Begin
	Select  null as CaseKey,
		null as IsPolicingOutstanding
	From CASES 
	WHERE 1=0
End


Return @nErrorCode
GO

Grant execute on dbo.csw_ListCasesBeingProcessed to public
GO


