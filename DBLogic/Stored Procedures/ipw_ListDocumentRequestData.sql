-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocumentRequestData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocumentRequestData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocumentRequestData.'
	Drop procedure [dbo].[ipw_ListDocumentRequestData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocumentRequestData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocumentRequestData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDocumentRequestKey	int,
	@pbNewRow		bit 		= 0
)
as
-- PROCEDURE:	ipw_ListDocumentRequestData
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Mar 2007	PG	3646	1	Procedure created
-- 18 Apr 2007	LP	3646	2	Return 0 for CanFilterCases and CanFilterEvents for new requests.
--					Set EventStartingFrom to current date		
-- 22 Feb 2008	SF	6228	3	Return translated data where applicable
--					Return formatted name
-- 14 Aug 2008  LP      8348    4       Return DayOfMonth field        
-- 15 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	6	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @sLookupCulture	nvarchar(10)
declare @dtStartingFrom datetime
declare @nDocumentRequestKey int 

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nDocumentRequestKey =-1

--Populate DocumentRequest results set
If @nErrorCode = 0
Begin
	If @pbNewRow = 0
	Begin
		Set @sSQLString = "
		Select CAST(@pnDocumentRequestKey as nvarchar(11))	as RowKey,
			DR.REQUESTID 					as DocumentRequestKey,
			DR.DESCRIPTION 					as RequestDescription,
			DR.RECIPIENT					as RecipientKey,
			N.NAMECODE					as RecipientCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
					as Recipient,
			CASE WHEN DE.EMAIL IS NULL 
				THEN 'M'
				ELSE 'O'
			 	END					as EMailToCode,
			DE.EMAIL 					as OtherEmailAddress,
			DE.DOCUMENTEMAILID				as OtherEmailKey,
			DR.DOCUMENTDEFID				as DocumentDefinitionKey,
			"+dbo.fn_SqlTranslatedColumn('DOCUMENTDEFINITION','NAME',null,'DD',@sLookupCulture,@pbCalledFromCentura)
						+ " 			as DocumentDefinition,
			DD.CANFILTERCASES				as CanFilterCases,
			DD.CANFILTEREVENTS				as CanFilterEvents,
			CASE WHEN DR.FREQUENCY IS NULL
				THEN 'O'
				ELSE 'E'	
				END					as FrequencyTypeCode,
			DR.FREQUENCY					as Frequency,
			DR.PERIODTYPE					as PeriodTypeKey,
			dbo.fn_GetTranslation(TC1.DESCRIPTION,null,TC1.DESCRIPTION_TID,@sLookupCulture)
									as PeriodType,
			DR.OUTPUTFORMATID				as ExportFormatKey,
			dbo.fn_GetTranslation(TC2.DESCRIPTION,null,TC2.DESCRIPTION_TID,@sLookupCulture)
									as ExportFormatDescription,
			DR.NEXTGENERATE					as NextGenerateDate,
			DR.STOPON					as StopOn,
			DR.LASTGENERATED				as LastGeneratedDate,
			DR.BELONGINGTOCODE				as BelongingToCode,
			DR.CASEFILTERID					as CaseFilterKey,
			QF.XMLFILTERCRITERIA				as CaseFilterXML,
			DR.EVENTSTART					as EventsStartingFrom,
			DR.SUPPRESSWHENEMPTY				as IsSuppressedWhenEmpty,
			DR.DAYOFMONTH                                   as DayOfMonth
			from DOCUMENTREQUEST DR
			join NAME N on (N.NAMENO = DR.RECIPIENT)
			left join DOCUMENTREQUESTEMAIL DE	on (DE.REQUESTID = DR.REQUESTID AND DE.ISMAIN=1)
			join DOCUMENTDEFINITION DD	on (DD.DOCUMENTDEFID= DR.DOCUMENTDEFID)
			left join TABLECODES TC1	on (TC1.USERCODE=DR.PERIODTYPE and TC1.TABLETYPE=127)
			left join TABLECODES TC2	on (TC2.TABLECODE=DR.OUTPUTFORMATID and TC2.TABLETYPE=137)
			left join QUERYFILTER QF	on (QF.FILTERID=DR.CASEFILTERID)
			where DR.REQUESTID=@pnDocumentRequestKey"
	
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnDocumentRequestKey	int,
						@sLookupCulture	nvarchar(10)',
						@pnDocumentRequestKey	= @pnDocumentRequestKey,
						@sLookupCulture	= @sLookupCulture
	

		--DocumentRequestEmail results set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select 	DE.DOCUMENTEMAILID	as RowKey,
				DE.DOCUMENTEMAILID	as DocumentEmailKey,
				DE.REQUESTID		as DocumentRequestKey,
				DE.EMAIL		as Email
				from DOCUMENTREQUESTEMAIL DE
				where DE.REQUESTID=@pnDocumentRequestKey
				and DE.ISMAIN <> 1
				order by DE.EMAIL"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnDocumentRequestKey	int',
							@pnDocumentRequestKey	= @pnDocumentRequestKey	
		End
		-- EventsToInclude results set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select 	CAST(@pnDocumentRequestKey as nvarchar(11))+'^'+
				CAST(TC.TABLECODE as nvarchar(11))	as RowKey,
				@pnDocumentRequestKey	as DocumentRequestKey,
				TC.TABLECODE 		as EventGroupKey,		       		
					dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
									as EventGroup,
		       		CASE WHEN EXISTS (Select * from DOCUMENTEVENTGROUP DG Where
				  	DG.REQUESTID=@pnDocumentRequestKey AND
				  	DG.EVENTGROUP=TC.TABLECODE) Then 1
				Else 0
				END			as IsSelected
			From TABLECODES TC Where TABLETYPE=142"
		
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnDocumentRequestKey	int,
						@sLookupCulture	nvarchar(10)',
						@pnDocumentRequestKey	= @pnDocumentRequestKey,
						@sLookupCulture	= @sLookupCulture	
		
		End
		
		--ActingAs results set
		If @nErrorCode =0
		Begin
			Set @sSQLString = "
			Select 	CAST(DA.REQUESTID as nvarchar(11))+'^'+
				CAST(DA.NAMETYPE as nvarchar(10))	as RowKey,
				DA.REQUESTID				as DocumentRequestKey,
				DA.NAMETYPE				as NameTypeKey,				
				dbo.fn_GetTranslation(NT.DESCRIPTION,null,NT.DESCRIPTION_TID,@sLookupCulture)
									as NameType
				from DOCUMENTREQUESTACTINGAS DA
				join NAMETYPE NT on (NT.NAMETYPE=DA.NAMETYPE)
				where DA.REQUESTID=@pnDocumentRequestKey
				order by DA.NAMETYPE"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnDocumentRequestKey	int,
						@sLookupCulture	nvarchar(10)',
							@pnDocumentRequestKey	= @pnDocumentRequestKey,
						@sLookupCulture	= @sLookupCulture	
		
		End
	End
	Else -- @pbNewRow=1
	Begin
		exec @nErrorCode = dbo.ip_GetCurrentDate
				@pdtCurrentDate		= @dtStartingFrom  output,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psDateType		= 'A', 	-- 'A'- Application Date; 'U'  User Date
				@pbIncludeTime		= 0 
		
		If @pnDocumentRequestKey is not null
		Begin
			Set @nDocumentRequestKey = @pnDocumentRequestKey
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select CAST(-1 as nvarchar(11))		as RowKey,
				CAST(@nDocumentRequestKey as nvarchar(11))	as DocumentRequestKey,
				null 				as RequestDescription,
				null				as RecipientKey,
				null				as RecipientCode,
				null				as Recipient,
				null				as EMailToCode,
				null 				as OtherEmailAddress,
				null				as OtherEmailKey,
				null				as DocumentDefinitionKey,
				null 				as DocumentDefinition,
				0				as CanFilterCases,
				0				as CanFilterEvents,
				null				as FrequencyTypeCode,
				null				as Frequency,
				null				as PeriodTypeKey,
				null				as PeriodType,
				null				as ExportFormatKey,
				null				as ExportFormatDescription,
				null				as NextGenerateDates,
				null				as StopOn,
				null				as LastGeneratedDate,
				null				as BelongingToCode,
				null				as CaseFilterKey,
				null				as CaseFilterXML,
				@dtStartingFrom			as EventsStartingFrom,
				null				as IsSuppressedWhenEmpty,
				null                            as DayOfMonth
			"
		
				Print @sSQLString
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@dtStartingFrom	datetime,
							@nDocumentRequestKey	int',
							@dtStartingFrom	= @dtStartingFrom,
							@nDocumentRequestKey = @nDocumentRequestKey
			
		End
		--DocumentRequestEmail results set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select 	CAST(-1 as nvarchar(11))	as RowKey,
				CAST(-1 as nvarchar(11))	as DocumentEmailKey,
				CAST(@nDocumentRequestKey as nvarchar(11))	as DocumentRequestKey,
				null				as Email
				"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nDocumentRequestKey	int',
					@nDocumentRequestKey	= @nDocumentRequestKey	

				
		End			
		-- EventsToInclude results set
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select 	CAST(@nDocumentRequestKey as nvarchar(11))+'^'+
				CAST(TC.TABLECODE as nvarchar(11))	as RowKey,
				CAST(@nDocumentRequestKey as nvarchar(11))	as DocumentRequestKey,
				TC.TABLECODE 			as EventGroupKey,
		       		dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
									as EventGroup,
		       		0				as IsSelected
			From TABLECODES TC Where TABLETYPE=142"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nDocumentRequestKey	int,
						@sLookupCulture	nvarchar(10)',
					@nDocumentRequestKey	= @nDocumentRequestKey,
						@sLookupCulture	= @sLookupCulture	
			
		End
	End	
End



Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocumentRequestData to public
GO
