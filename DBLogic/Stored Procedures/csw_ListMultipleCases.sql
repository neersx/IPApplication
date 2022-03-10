-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListMultipleCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListMultipleCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListMultipleCases.'
	Drop procedure [dbo].[csw_ListMultipleCases]
End
Print '**** Creating Stored Procedure dbo.csw_ListMultipleCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListMultipleCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKeys		nvarchar(max)	-- comma-separated list of CASEIDs
)
as
-- PROCEDURE:	csw_ListMultipleCases
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given a comma-separated list of CASEIDs, return the list of matching cases
--		as a table with CASEID and CASEREFERENCE columns

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 jan 2013	LP	R11313	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

Set @sSQLString='
Select	CASEID							as CaseKey,
	IRN	 						as CaseReference
from	CASES
where	CASEID in ('

Exec  (@sSQLString + @psCaseKeys + ')')
select	@nErrorCode =@@Error

Return @nErrorCode
GO

Grant execute on dbo.csw_ListMultipleCases to public
GO
