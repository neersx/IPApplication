-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ExistsNationalPhaseCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ExistsNationalPhaseCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_ExistsNationalPhaseCase.'
	drop procedure [dbo].[cs_ExistsNationalPhaseCase]
end
print '**** Creating Stored Procedure dbo.cs_ExistsNationalPhaseCase...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_ExistsNationalPhaseCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbExists		bit		= null output,
	@psCaseKey		nvarchar(11)	= null,
	@psCountryKey		nvarchar(3)	= null

)
as
-- PROCEDURE:	cs_ExistsNationalPhaseCase
-- VERSION:	2
-- DESCRIPTION:	To see if a related national phase case already exists
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13-DEC-2002  SF				1	Procedure created
-- 15 Apr 2013	DV		R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0
Set @pbExists = 0

If @nErrorCode=0
Begin
	Select 	@pbExists = 1
	from 	RELATEDCASE
	where	CASEID = Cast(@psCaseKey as int)
	and	RELATIONSHIP = 'DC1'
	and	COUNTRYCODE = @psCountryKey
	and	RELATEDCASEID is not null

	Set @nErrorCode=@@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.cs_ExistsNationalPhaseCase to public
GO
