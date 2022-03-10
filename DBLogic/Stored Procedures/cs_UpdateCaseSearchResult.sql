-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCaseSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCaseSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateCaseSearchResult.'
	Drop procedure [dbo].[cs_UpdateCaseSearchResult]
end
Print '**** Creating Stored Procedure dbo.cs_UpdateCaseSearchResult...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_UpdateCaseSearchResult
(
	@pnUserIdentityId	int,			
	@pnOperator			int,						-- 1=add; 2=delete
	@psFamily			nvarchar(40),
	@pnPriorArtId		int				= null,		-- optional parameters
	@pnCaseId			int				= null,	
	@psCulture			nvarchar(10) 	= null,
	@pbPolicingImmediate bit			= 0
)
as
-- PROCEDURE:	cs_UpdateCaseSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Maintain the indirect relationship between case and prior art via family.
--				This occurs when family and prior art relationship is created or deleted.  And  
--				when case is added or removed from family.
--
-- MODIFICATIONS :
-- Date			Who		Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 18 Mar 2008	DL    	11964 		1		Procedure created.

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @nRowCount		int
Declare	@sSQLString		nvarchar(4000)

Set @nErrorCode=0

-- adding/removing relationships between prior art and family
If ((@nErrorCode=0) and (@pnPriorArtId is not null) and (@psFamily is not null) )
Begin
	-- Add indirect relationships
	If @pnOperator = 1
	Begin 
		Set @sSQLString="
			Insert into CASESEARCHRESULT (FAMILYPRIORARTID, CASEID, PRIORARTID, UPDATEDDATE)
			Select FSR.FAMILYPRIORARTID, C.CASEID, @pnPriorArtId, getdate()
			from FAMILYSEARCHRESULT FSR 
			join CASES C on (C.FAMILY = FSR.FAMILY)
			left join CASESEARCHRESULT CSR on (CSR.FAMILYPRIORARTID = FSR.FAMILYPRIORARTID AND CSR.CASEID = C.CASEID)
			where FSR.FAMILY = @psFamily
			and FSR.PRIORARTID = @pnPriorArtId
			-- Ensure duplicate indirect relationship will not be inserted
			and CSR.FAMILYPRIORARTID IS NULL
			and CSR.CASEID IS NULL "
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40),
				  @pnPriorArtId	int',
				  @psFamily		= @psFamily,
				  @pnPriorArtId	= @pnPriorArtId

		-- create CASEEVENT  for the affected cases-priorart
		If @@ROWCOUNT > 0 and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_CreatePriorArtCaseEvent
						@pnUserIdentityId = @pnUserIdentityId,
						@psFamily		= @psFamily,
						@pnPriorArtId	= @pnPriorArtId,
						@pbPolicingImmediate = @pbPolicingImmediate
		End
	End
	-- remove indirect relationships
	Else If @pnOperator = 2 
	Begin
		Set @sSQLString="
			Delete CASESEARCHRESULT
			from CASESEARCHRESULT CSR
			join FAMILYSEARCHRESULT FSR on (FSR.FAMILYPRIORARTID = CSR.FAMILYPRIORARTID)
			where FSR.FAMILY = @psFamily
			and FSR.PRIORARTID = @pnPriorArtId "
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40),
				  @pnPriorArtId	int',
				  @psFamily		= @psFamily,
				  @pnPriorArtId	= @pnPriorArtId
	End
End

-- adding/removing case from family
Else If ((@nErrorCode=0) and (@pnCaseId is not null) and (@psFamily is not null) )
Begin
	-- Add indirect relationships
	If @pnOperator = 1
	Begin 
		Set @sSQLString="
			Insert into CASESEARCHRESULT (FAMILYPRIORARTID, CASEID, PRIORARTID, UPDATEDDATE)
			Select FSR.FAMILYPRIORARTID, C.CASEID, FSR.PRIORARTID, getdate()
			from FAMILYSEARCHRESULT FSR 
			join CASES C on (C.FAMILY = FSR.FAMILY)
			left join CASESEARCHRESULT CSR on (CSR.FAMILYPRIORARTID = FSR.FAMILYPRIORARTID AND CSR.CASEID = C.CASEID)
			where FSR.FAMILY = @psFamily
			-- Ensure duplicate indirect relationship will not be inserted
			and CSR.FAMILYPRIORARTID IS NULL
			and CSR.CASEID IS NULL "
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40)',
				  @psFamily		= @psFamily

		-- create CASEEVENT  for the affected cases-priorart
		If @@ROWCOUNT > 0 and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_CreatePriorArtCaseEvent
						@pnUserIdentityId = @pnUserIdentityId,
						@psFamily		= @psFamily,
						@pnCaseId		= @pnCaseId,
						@pbPolicingImmediate = @pbPolicingImmediate
		End
	End
	-- remove indirect relationships
	Else If @pnOperator = 2 
	Begin
		Set @sSQLString="
			Delete CASESEARCHRESULT
			from CASESEARCHRESULT CSR
			join FAMILYSEARCHRESULT FSR on (FSR.FAMILYPRIORARTID = CSR.FAMILYPRIORARTID)
			where FSR.FAMILY = @psFamily
			and CSR.CASEID = @pnCaseId" 
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40),
				  @pnCaseId		int',
				  @psFamily		= @psFamily,
				  @pnCaseId		= @pnCaseId
	End
End



If  @nErrorCode <>0
Begin
	RAISERROR('Cannot update CASESEARCHRESULT.', 14, 1)
	Set @nErrorCode = @@ERROR
End



Return @nErrorCode
GO

Grant execute on dbo.cs_UpdateCaseSearchResult to public
GO
