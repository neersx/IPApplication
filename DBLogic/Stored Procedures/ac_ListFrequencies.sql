-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListFrequencies   
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListFrequencies]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListFrequencies.'
	Drop procedure [dbo].[ac_ListFrequencies   ]
End
Print '**** Creating Stored Procedure dbo.ac_ListFrequencies...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_ListFrequencies   
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListFrequencies   
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists payment terms (Frequencies).
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07-Sep-2004	TM	RFC1158	1	Procedure created
-- 13-Sep-2004	TM	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 19 May 2011  MS      RFC7998 4       Add FrequencyType in Result

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  FREQUENCYNO 	as FrequencyKey,
	"+dbo.fn_SqlTranslatedColumn('FREQUENCY','DESCRIPTION',null,'F',@sLookupCulture,@pbCalledFromCentura)
				+ " as FrequencyDescription,
        FREQUENCYTYPE           as FrequencyType
	from FREQUENCY F
	order by FrequencyDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListFrequencies to public
GO
