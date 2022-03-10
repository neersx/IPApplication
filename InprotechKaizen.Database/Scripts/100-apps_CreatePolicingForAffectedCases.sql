if exists (select * from sysobjects where id = object_id(N'[dbo].[apps_CreatePolicingForAffectedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.apps_CreatePolicingForAffectedCases.'
	drop procedure dbo.apps_CreatePolicingForAffectedCases
	print '**** Creating procedure dbo.apps_CreatePolicingForAffectedCases...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS on
GO

Create PROCEDURE [dbo].[apps_CreatePolicingForAffectedCases]
(	
	@pnUserIdentityId int,
	@pnRequestId int
)
-- PROCEDURE :	apps_CreatePolicingForAffectedCases
-- VERSION :	1
-- DESCRIPTION:	wrapper to call ip_WhatWillBePoliced procedure. It calls the Sp to generate policing queue rows for the caseses affected by policing request

-- Modifications
--
-- Date			Who	Number	Version	Description
-- ------------	------	-------	-------	------------------------------------
-- 09/09/2016	HM	DR-22549	1	Procedure created.

AS
declare @nNumberOfCases	int=0,
@nPolicingSeqNo int,
@dtPolicingDateEntered datetime,
@bIsSupportedFeature bit=0;

if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_WhatWillBePoliced]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin	
		Begin
			select @dtPolicingDateEntered=DATEENTERED,@nPolicingSeqNo=POLICINGSEQNO  from POLICING where REQUESTID=@pnRequestId

			exec dbo.ip_WhatWillBePoliced
			@pnUserIdentityId	    = @pnUserIdentityId,			-- Identity of connected user
			@pdtPolicingDateEntered	= @dtPolicingDateEntered,	-- Key to Policing row
			@pnPolicingSeqNo	    = @nPolicingSeqNo,			-- Key to Policing row
			@pbReturnCaseList	    = 0,			-- Indicates that the actual Cases that will be policed should be returned
			@pbRaiseCasePolicingRequest = 1,			-- Indicates that the procedure should generate a policing request for each Case.
			@pnNumberOfCases	    = @nNumberOfCases OUTPUT	-- The output parameter that will return the case count.
		End

end

select @bIsSupportedFeature as IsSupported,@nNumberOfCases as NoOfCases
Go

Grant execute on dbo.apps_CreatePolicingForAffectedCases to public
GO