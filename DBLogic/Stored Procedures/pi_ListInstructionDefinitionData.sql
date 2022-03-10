-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_ListInstructionDefinitionData									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_ListInstructionDefinitionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_ListInstructionDefinitionData.'
	Drop procedure [dbo].[pi_ListInstructionDefinitionData]
End
Print '**** Creating Stored Procedure dbo.pi_ListInstructionDefinitionData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.pi_ListInstructionDefinitionData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDefinitionKey	int 		-- Mandatory
)
as
-- PROCEDURE:	pi_ListInstructionDefinitionData
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the InstructionDefinition business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 29 Nov 2006	AU	RFC4634	1	Procedure created
-- 20 Dec 2006	AU	RFC4634	2	Removed unnecessary Select statement.
-- 05 Feb 2007	LP	RFC5076	3	Renamed ChargeTypeKeyDescription column to ChargeTypeDescription.
-- 15 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	I.DEFINITIONID		as DefinitionKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONDEFINITION','INSTRUCTIONNAME',null,'I',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as InstructionName,
	CASE 	WHEN I.AVAILABILITYFLAGS&1 > 0
		THEN CAST(1 as bit)
		ELSE CAST(0 as bit)
	END as IsForMultipleCases,
	CASE 	WHEN I.AVAILABILITYFLAGS&2 > 0
		THEN CAST(1 as bit)
		ELSE CAST(0 as bit)
	END as IsForSingleCase,
	CASE 	WHEN I.AVAILABILITYFLAGS&4 > 0
		THEN CAST(1 as bit)
		ELSE CAST(0 as bit)
	END as IsAgainstDueEvent,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONDEFINITION','EXPLANATION',null,'I',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	" 			as 'InstructionExplanation',
	I.[ACTION]		as ActionKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as [Action],
	I.USEMAXCYCLE		as UseMaxCycle,
	I.DUEEVENTNO		as DueEventKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EVT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as DueEventDescription,
	I.PREREQUISITEEVENTNO	as PrerequisiteEventKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EVT2',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as PrerequisiteEventDescription,
	I.INSTRUCTNAMETYPE	as InstructionNameTypeKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as InstructionNameTypeDescription,
	I.CHARGETYPENO		as ChargeTypeKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as ChargeTypeDescription
	from INSTRUCTIONDEFINITION I
	left join ACTIONS A 	on (A.[ACTION] = I.[ACTION])
	left join EVENTS EVT 	on (EVT.EVENTNO = I.DUEEVENTNO)
	left join EVENTS EVT2 	on (EVT2.EVENTNO = I.PREREQUISITEEVENTNO)
	left join NAMETYPE NT 	on (NT.NAMETYPE = I.INSTRUCTNAMETYPE)
	left join CHARGETYPE CT on (CT.CHARGETYPENO = I.CHARGETYPENO)
	where I.DEFINITIONID = @pnDefinitionKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnDefinitionKey	int',
			@pnDefinitionKey	= @pnDefinitionKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	CAST(IR.DEFINITIONID as nvarchar(11))+'^'+
	CAST(IR.SEQUENCENO as nvarchar(10))
				as RowKey,
	IR.DEFINITIONID		as DefinitionKey,
	IR.SEQUENCENO		as SequenceNo,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','LABEL',null,'IR',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as ResponseLabel,
	IR.FIREEVENTNO		as FireEventKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EVT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as FireEventDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','EXPLANATION',null,'IR',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as ResponseExplanation,
	IR.DISPLAYEVENTNO	as DisplayEventKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EVT2',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as DisplayEventDescription,
	IR.HIDEEVENTNO		as HideEventKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EVT3',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as HideEventDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONRESPONSE','NOTESPROMPT',null,'IR',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as NotesPrompt
	from INSTRUCTIONRESPONSE IR
	left join EVENTS EVT 	on (EVT.EVENTNO = IR.FIREEVENTNO)
	left join EVENTS EVT2 	on (EVT2.EVENTNO = IR.DISPLAYEVENTNO)
	left join EVENTS EVT3 	on (EVT3.EVENTNO = IR.HIDEEVENTNO)
	where IR.DEFINITIONID = @pnDefinitionKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnDefinitionKey	int',
			@pnDefinitionKey	 = @pnDefinitionKey
End

Return @nErrorCode
GO

Grant execute on dbo.pi_ListInstructionDefinitionData to public
GO