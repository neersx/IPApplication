-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_GetLetter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_GetLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_GetLetter.'
	Drop procedure [dbo].[dg_GetLetter]
End
Print '**** Creating Stored Procedure dbo.dg_GetLetter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_GetLetter
	@pnLetterNo		int
AS
-- Procedure :	dg_GetLetter
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will return a set of  Activity Requests on the queue
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 29 July 2011	PK	RFC10708	1	Initial creation
-- 22 Dec 2011	PK	RFC11035	2	Add support for Email DocItems

-- Declare variables
Declare	@nErrorCode			int
Declare @sSQLString 		nvarchar(4000)

-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	l.LETTERNO as LetterNo,
			l.LETTERNAME as LetterName,
			l.DOCUMENTCODE as DocumentCode,
			l.CORRESPONDTYPE as CorrespondType,
			l.COPIESALLOWEDFLAG as CopiesAllowedFlag,
			l.COVERINGLETTER as CoveringLetter,
			l.EXTRACOPIES as ExtraCopies,
			l.MULTICASEFLAG as MultiCaseFlag,
			l.MACRO as Macro,
			l.SINGLECASELETTERNO as SingleCaseLetterNo,
			l.INSTRUCTIONTYPE as InstructionType,
			l.ENVELOPE as Envelope,
			l.COUNTRYCODE as CountryCode,
			l.DELIVERYID as DeliveryID,
			l.PROPERTYTYPE as PropertyType,
			l.HOLDFLAG as HoldFlag,
			l.NOTES as Notes,
			l.DOCUMENTTYPE as DocumentType,
			l.USEDBY as UsedBy,
			l.FORPRIMECASESONLY as ForPrimeCasesOnly,
			l.GENERATEASANSI as GenerateAsANSI,
			l.ADDATTACHMENTFLAG as AddAttachmentFlag,
			l.ACTIVITYTYPE as ActivityType,
			l.ACTIVITYCATEGORY as ActivityCategory,
			l.ENTRYPOINTTYPE as EntryPointType,
			l.SOURCEFILE as SourceFile,
			l.EXTERNALUSAGE as ExternalUsage,
			l.DELIVERLETTER as DeliverLetter,
			l.DOCITEMMAILBOX as DocItemMailbox,
			l.DOCITEMSUBJECT as DocItemSubject,
			l.DOCITEMBODY as DocItemBody
		From	LETTER l
		Where	l.LETTERNO = @pnLetterNo
		"
		
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnLetterNo		int',
			@pnLetterNo		= @pnLetterNo
		
	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_GetLetter to Public
go
