-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchDetailLetters
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchDetailLetters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchDetailLetters.'
	Drop procedure [dbo].[csw_FetchDetailLetters]
End
Print '**** Creating Stored Procedure dbo.csw_FetchDetailLetters...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchDetailLetters
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey				int,		-- Mandatory	
	@psActionKey				nvarchar(2),
	@pnActionCycle				smallint,
	@pnCriteriaKey				int,		-- Mandatory
	@pnEntryNumber				smallint	-- Mandatory
)
as
-- PROCEDURE:	csw_FetchDetailLetters
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List the letters applicable for the current criteria entry session.
--		Logic moved from csw_ListWorkflowData

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 MAR 2012	SF	R11318	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	/* Case Letters */
	Set @sSQLString = "
		Select	cast(DL.ENTRYNUMBER as nvarchar(15)) + '^' + 
			cast(DL.LETTERNO as nvarchar(15))		as RowKey,
			@pnCaseKey					as CaseKey,
			@psActionKey					as ActionKey,
			@pnActionCycle					as ActionCycle,
			DL.ENTRYNUMBER					as EntryNumber,
			DL.LETTERNO					as LetterKey, 				
			"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'L',@sLookupCulture,@pbCalledFromCentura)			
							+"		as LetterName,    							
			L.DOCUMENTCODE					as LetterCode,
			L.COVERINGLETTER				as CoveringLetterKey,
			"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'COV',@sLookupCulture,@pbCalledFromCentura)			
							+"		as CoveringLetterName,    							
			L.ENVELOPE					as EnvelopeKey,
			"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'ENV',@sLookupCulture,@pbCalledFromCentura)			
							+"		as EnvelopeName,    							
			cast(DL.MANDATORYFLAG as bit)			as IsMandatory
		from	DETAILLETTERS DL
		join	LETTER L				on (	DL.LETTERNO = L.LETTERNO)
		left	join LETTER COV 			on (	L.COVERINGLETTER = COV.LETTERNO)
		left	join LETTER ENV 			on (	L.COVERINGLETTER = ENV.LETTERNO)
		where	DL.CRITERIANO = @pnCriteriaKey   		
		and		DL.ENTRYNUMBER = @pnEntryNumber"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey			int,		
					@pnCriteriaKey			int,
					@psActionKey			nvarchar(2),
					@pnActionCycle			smallint,
					@pnEntryNumber			smallint',
					@pnCaseKey			= @pnCaseKey,
					@pnCriteriaKey			= @pnCriteriaKey,
					@psActionKey			= @psActionKey,
					@pnActionCycle			= @pnActionCycle,
					@pnEntryNumber			= @pnEntryNumber
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchDetailLetters to public
GO
