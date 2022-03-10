-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_ListInstructionResponses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_ListInstructionResponses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_ListInstructionResponses.'
	Drop procedure [dbo].[pi_ListInstructionResponses]
End
Print '**** Creating Stored Procedure dbo.pi_ListInstructionResponses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.pi_ListInstructionResponses
(
	@pnRowCount			int		= null output,
	@pnUserIdentityId		int,
	@psCulture			nvarchar (10) 	= null,
	@pnCaseKey			int		= null,
	@pnInstructionDefinitionKey	int		= null,
	@pnInstructionCycle		smallint 	= null,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	pi_ListInstructionResponses
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Provide a list of the possible responses for a given instruction definition/case combination.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Dec 2006	SF	RFC2982	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin


Set @sSQLString = "

	select 	R.DEFINITIONID as InstructionDefinitionKey,
	 	R.SEQUENCENO as ResponseSequence,
	"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','LABEL',null, 'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as ResponseLabel,
	"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','EXPLANATION',null, 'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as ResponseExplaination,
	"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','NOTESPROMPT',null, 'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as NotesPrompt
	FROM INSTRUCTIONRESPONSE R
	LEFT JOIN CASES C		on (C.CASEID=@pnCaseKey)
	LEFT JOIN EVENTS EA		on (EA.EVENTNO=R.DISPLAYEVENTNO)
	LEFT JOIN CASEEVENT CEA		on (CEA.CASEID=C.CASEID
				and CEA.EVENTNO=EA.EVENTNO
				and CEA.CYCLE=case when EA.NUMCYCLESALLOWED=1 then 1 else @pnInstructionCycle end 
				and CEA.OCCURREDFLAG>0) 
	LEFT JOIN EVENTS EH		on (EH.EVENTNO=R.HIDEEVENTNO)
	LEFT JOIN CASEEVENT CEH		on (CEH.CASEID=C.CASEID
				and CEH.EVENTNO=EH.EVENTNO
				and CEH.CYCLE=case when EH.NUMCYCLESALLOWED=1 then 1 else @pnInstructionCycle end 
				and CEH.OCCURREDFLAG>0)
	WHERE 	R.DEFINITIONID=@pnInstructionDefinitionKey
	and	(R.DISPLAYEVENTNO is null or CEA.EVENTNO is not null)
	and	(R.HIDEEVENTNO is null or CEH.EVENTNO is null)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @sLookupCulture		nvarchar(10),
					  @pnInstructionDefinitionKey	int,
					  @pnCaseKey			int,
					  @pnInstructionCycle		int',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @sLookupCulture		= @sLookupCulture,
					  @pnInstructionDefinitionKey	= @pnInstructionDefinitionKey,
					  @pnCaseKey			= @pnCaseKey,
					  @pnInstructionCycle		= @pnInstructionCycle

	Set @pnRowCount = @@Rowcount

End

Return @nErrorCode
GO

Grant execute on dbo.pi_ListInstructionResponses to public
GO
