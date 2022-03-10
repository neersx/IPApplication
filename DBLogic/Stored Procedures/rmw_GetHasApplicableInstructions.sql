-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_GetHasApplicableInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_GetHasApplicableInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_GetHasApplicableInstructions.'
	Drop procedure [dbo].[rmw_GetHasApplicableInstructions]
End
Print '**** Creating Stored Procedure dbo.rmw_GetHasApplicableInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_GetHasApplicableInstructions
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit	= 0,
	@pnEmployeeKey			int,
	@pdtReminderDateCreated	datetime
)
as
-- PROCEDURE:	rmw_GetHasApplicableInstructions
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return whether the reminder has applicable instructions that can be provided
--				NOTE, this may be expanded to include the full check.  Currently this is approximation.
--				Full check - RFC2982\Provide Instructions.sql

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 FEB 2011	SF	9824	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		Select	case 
					when D.CASEID IS NOT NULL 
						then cast(1 as bit) 
						else cast(0 as bit) 
				end
		FROM	EMPLOYEEREMINDER ER
		left join CASEEVENT CE		on (CE.CASEID = ER.CASEID
								and CE.EVENTNO = ER.EVENTNO
								and CE.CYCLE = ER.CYCLENO)
		left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO
				   From CASES C
				   cross join INSTRUCTIONDEFINITION D
				   left join CASEEVENT P	on (P.CASEID=C.CASEID
								and P.EVENTNO=D.PREREQUISITEEVENTNO)
				   where D.AVAILABILITYFLAGS&4=4
				   and	 D.DUEEVENTNO IS NOT NULL
				   and 	(D.PREREQUISITEEVENTNO IS NULL OR
						 P.EVENTNO IS NOT NULL
					)
				   ) D			on (D.CASEID=CE.CASEID
							and D.EVENTNO=CE.EVENTNO)
		WHERE	ER.EMPLOYEENO = @pnEmployeeKey
		and		ER.MESSAGESEQ = @pdtReminderDateCreated
		and		ER.HOLDUNTILDATE is null
		"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEmployeeKey			int,
				  @pdtReminderDateCreated	datetime',
				  @pnEmployeeKey			= @pnEmployeeKey,
				  @pdtReminderDateCreated	= @pdtReminderDateCreated

End

Return @nErrorCode
GO

Grant execute on dbo.rmw_GetHasApplicableInstructions to public
GO
