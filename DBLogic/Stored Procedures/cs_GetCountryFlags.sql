-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetCountryFlags
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetCountryFlags]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetCountryFlags.'
	Drop procedure [dbo].[cs_GetCountryFlags]
End
Print '**** Creating Stored Procedure dbo.cs_GetCountryFlags...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_GetCountryFlags
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKey		nvarchar(10)	= null,
	@pnInitialStatus	int		= null output,
	@pnNationalPhaseStatus 	int		= null output
)
as
-- PROCEDURE:	cs_GetCountryFlags
-- VERSION:	2
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Retrieve Country Flags (InitialStatus, NationalPhaseStatus for this case)
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13-DEC-2002  AP		1	Procedure created
-- 16 Jan 2012	LP	R11746	2	Correct logic for selecting default status flag.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nCaseKey int

Set @nErrorCode = 0

If @psCaseKey is not null
Begin
	Set @nCaseKey = Cast(@psCaseKey as int)
End

If @nErrorCode = 0
Begin
	-- ------------------
	-- Get Initial Status

	Select 	@pnInitialStatus = min(FLAGNUMBER)
	from	CASES C
	join 	COUNTRYFLAGS CF on (C.COUNTRYCODE = CF.COUNTRYCODE)
	where 	CASEID = @nCaseKey
	
	Set @nErrorCode = @@error

	If @nErrorCode = 0
	Begin
	-- -------------------------
	-- Get National Phase Status
		If exists (Select 1 from RELATEDCASE where RELATIONSHIP = 'DC1' and RELATEDCASEID IS NULL and CASEID = @nCaseKey)
		Begin
			-- Defaulted to smallest code against any designated countries
			Select 	@pnNationalPhaseStatus = MIN(RC.CURRENTSTATUS)
			from	CASES C
			join	RELATEDCASE RC on (RC.CASEID = C.CASEID)
			where	C.CASEID = @nCaseKey
			and RC.RELATIONSHIP = 'DC1'
			and RC.RELATEDCASEID IS NULL
			and exists (select 1 from COUNTRYFLAGS CF
					where CF.COUNTRYCODE = C.COUNTRYCODE
					and CF.FLAGNUMBER = RC.CURRENTSTATUS
					and CF.NATIONALALLOWED = 1)
			Set @nErrorCode = @@error
		End
		Else
		Begin		
			-- Defaulted to smallest code against treaty code
			Select 	@pnNationalPhaseStatus = min(FLAGNUMBER)
			from	CASES C
			join	COUNTRYFLAGS CF on (C.COUNTRYCODE = CF.COUNTRYCODE
						and NATIONALALLOWED = 1)
			where	CASEID = @nCaseKey

			Set @nErrorCode = @@error
		End
	End
End 


Return @nErrorCode
GO

Grant execute on dbo.cs_GetCountryFlags to public
GO
