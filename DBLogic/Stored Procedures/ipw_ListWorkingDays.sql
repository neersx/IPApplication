-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListWorkingDays									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListWorkingDays]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListWorkingDays.'
	Drop procedure [dbo].[ipw_ListWorkingDays]
End
Print '**** Creating Stored Procedure dbo.ipw_ListWorkingDays...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_ListWorkingDays
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListWorkingDays
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the working days of the week that are available for the Country 
--		in which Inprotech is implemented (setup in the HOMECOUNTRY site control).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 23 May 2006	IB	RFC3678	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode = 0

If @nErrorCode=0
Begin
	Set @sSQLString = "Select 
		T.USERCODE 		as WorkingDayKey, 
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)+"
					as WorkingDay
		from TABLECODES T
		join SITECONTROL H 	on (H.CONTROLID='HOMECOUNTRY')
		join COUNTRY C		on (C.COUNTRYCODE=H.COLCHARACTER)
		where T.TABLETYPE=88
		and (	(C.WORKDAYFLAG&1=1   and T.TABLECODE=8801) or	-- Saturday
			(C.WORKDAYFLAG&2=2   and T.TABLECODE=8802) or	-- Sunday
			(C.WORKDAYFLAG&4=4   and T.TABLECODE=8803) or	-- Monday
			(C.WORKDAYFLAG&8=8   and T.TABLECODE=8804) or 	-- Tuesday
			(C.WORKDAYFLAG&16=16 and T.TABLECODE=8805) or	-- Wednesday
			(C.WORKDAYFLAG&32=32 and T.TABLECODE=8806) or	-- Thursday
			(C.WORKDAYFLAG&64=64 and T.TABLECODE=8807) 	-- Friday
		    )
		order by WorkingDayKey"

	Exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListWorkingDays to public
GO

