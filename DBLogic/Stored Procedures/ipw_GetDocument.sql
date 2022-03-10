-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetDocument
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetDocument]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetDocument.'
	Drop procedure [dbo].[ipw_GetDocument]
End
Print '**** Creating Stored Procedure dbo.ipw_GetDocument...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetDocument
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnDocumentKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_GetDocument
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the detail of a document

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 May 2010	JC	RFC6229	1	Procedure created
-- 10 Aug 2011	JC	R11082	2	Add File Destination
-- 27 Feb 2012	SF	R11899	3	Add IsInproDocOnly, IsDGLibOnly

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	-- Some code here
	Set @sSQLString = "
	Select 	L.LETTERNO as DocumentKey,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'L',@sLookupCulture,@pbCalledFromCentura)
			+ " as DocumentDescription,
		L.DOCUMENTCODE as DocumentCode,
		L.MACRO as Template,
		CONVERT(Bit, ISNULL(L.HOLDFLAG,0)) as PlaceOnHold,
		L.DELIVERYID as DeliveryMethodKey,
		"+dbo.fn_SqlTranslatedColumn('DELIVERYMETHOD','DESCRIPTION',null,'DL',@sLookupCulture,@pbCalledFromCentura)
			+ " as DeliveryMethodDescription,
		DL.FILEDESTINATION as DefaultFilePath,
		DL.DESTINATIONSP as FileDestinationSP,
		L.DOCUMENTTYPE as DocumentType,
		L.SOURCEFILE as SourceFile,
		L.CORRESPONDTYPE as CorrespondenceTypeKey,
		"+dbo.fn_SqlTranslatedColumn('CORRESPONDTO','DESCRIPTION',null,'CT',@sLookupCulture,@pbCalledFromCentura)
			+ " as CorrespondenceTypeDescription,
		L.COVERINGLETTER as CoveringLetterKey,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)
			+ " as CoveringLetterDescription,
		L.ENVELOPE as EnvelopeKey,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'EN',@sLookupCulture,@pbCalledFromCentura)
			+ " as EnvelopeDescription,
		CONVERT(Bit, ISNULL(L.FORPRIMECASESONLY,0)) as ForPrimeCasesOnly,
		CONVERT(Bit, ISNULL(L.GENERATEASANSI,0)) as GenerateAsANSI,
		CONVERT(Bit, ISNULL(L.MULTICASEFLAG,0)) as MultiCase,
		CONVERT(Bit, ISNULL(L.COPIESALLOWEDFLAG,0)) as CopiesAllowed,
		L.EXTRACOPIES as NbExtraCopies,
		L.SINGLECASELETTERNO as SingleCaseLetterKey,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'SCL',@sLookupCulture,@pbCalledFromCentura)
			+ " as SingleCaseLetterDescription,
		CONVERT(Bit, ISNULL(L.ADDATTACHMENTFLAG,0)) as AddAttachment,
		L.ACTIVITYTYPE as ActivityTypeKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AT',@sLookupCulture,@pbCalledFromCentura)
			+ " as ActivityTypeDescription,
		L.ACTIVITYCATEGORY as ActivityCategoryKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AC',@sLookupCulture,@pbCalledFromCentura)
			+ " as ActivityCategoryDescription,
		L.INSTRUCTIONTYPE as InstructionTypeKey,
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,@pbCalledFromCentura)
			+ " as InstructionTypeDescription,
		L.COUNTRYCODE as CountryCode,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
			+ " as CountryDescription,
		L.PROPERTYTYPE as PropertyType,
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
			+ " as PropertyTypeDescription,
		CONVERT(Bit, case when L.USEDBY & 32 = 32 then 1 else 0 end) as UsedByCases,
		CONVERT(Bit, case when L.USEDBY & 256 = 256 then 1 else 0 end) as UsedByNames,
		CONVERT(Bit, case when L.USEDBY & 1 = 1 then 1 else 0 end) as UsedByTimeAndBilling,
		CONVERT(Bit, case when L.USEDBY & 1024 = 1024 then 1 else 0 end) as IsInproDocOnlyTemplate,
		CONVERT(Bit, case when L.USEDBY & 2048 = 2048 then 1 else 0 end) as IsDGLibOnlyTemplate,
		L.ENTRYPOINTTYPE as EntryPointTypeKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'ET',@sLookupCulture,@pbCalledFromCentura)
			+ " as EntryPointTypeDescription,
		L.LOGDATETIMESTAMP as LastUpdatedDate
	from LETTER L
	left join LETTER CL on (CL.LETTERNO = L.COVERINGLETTER)
	left join LETTER EN on (EN.LETTERNO = L.ENVELOPE)
	left join LETTER SCL on (SCL.LETTERNO = L.SINGLECASELETTERNO)
	left join DELIVERYMETHOD DL on (DL.DELIVERYID = L.DELIVERYID)
	left join CORRESPONDTO CT on (CT.CORRESPONDTYPE = L.CORRESPONDTYPE)
	left join INSTRUCTIONTYPE IT on (IT.INSTRUCTIONTYPE = L.INSTRUCTIONTYPE)
	left join COUNTRY C on (C.COUNTRYCODE = L.COUNTRYCODE)
	left join PROPERTYTYPE P on (P.PROPERTYTYPE = L.PROPERTYTYPE)
	left join TABLECODES AT on (AT.TABLECODE = L.ACTIVITYTYPE)
	left join TABLECODES AC on (AC.TABLECODE = L.ACTIVITYCATEGORY)
	left join TABLECODES ET on (ET.TABLECODE = L.ENTRYPOINTTYPE)
	where L.LETTERNO = @pnDocumentKey"	

	exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnDocumentKey int',
		  @pnDocumentKey = @pnDocumentKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetDocument to public
GO
