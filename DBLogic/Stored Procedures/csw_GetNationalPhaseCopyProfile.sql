-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetNationalPhaseCopyProfile
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].csw_GetNationalPhaseCopyProfile') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_GetNationalPhaseCopyProfile.'
	drop procedure [dbo].csw_GetNationalPhaseCopyProfile
end
print '**** Creating Stored Procedure dbo.csw_GetNationalPhaseCopyProfile...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_GetNationalPhaseCopyProfile
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psProfileName		nvarchar(50)	= null output,
	@pnCaseKey		nvarchar(11)	= null,
	@pnNationalPhaseStatus		int	= null

)
as
-- PROCEDURE:	csw_GetNationalPhaseCopyProfile
-- VERSION:	2
-- DESCRIPTION:	Return the default copy profile for cases that enter National Phase status
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07-Jan-2008  LP		1	Procedure created
-- 15 Apr 2013	DV		2	R13270 Increase the length of nvarchar to 11 when casting or declaring integer



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sProfileName nvarchar(50)

Set @nErrorCode = 0
Set @sProfileName = null

If @nErrorCode=0
and @pnNationalPhaseStatus is not null
Begin
	select 	@psProfileName = PROFILENAME
	from	CASES C
	join	COUNTRYFLAGS CF on (C.COUNTRYCODE = CF.COUNTRYCODE
				and FLAGNUMBER = @pnNationalPhaseStatus)
	and	C.CASEID = @pnCaseKey

	Set @nErrorCode=@@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetNationalPhaseCopyProfile to public
GO
