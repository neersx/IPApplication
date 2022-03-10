-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCaseText									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCaseText.'
	Drop procedure [dbo].[csw_FetchCaseText]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCaseText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchCaseText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int, 		-- Mandatory
	@pbNewRow		bit		= 0,  -- Indicates whether a template row containing default data is required.  
	@pbSuppressClassText	bit		= 0,  -- If this parameter is set (=1) CaseText rows with type equal to 'G' or Class column populated will not be retrieved. Otherwise all CaseText rows will be retrieved.
	@psClass		nvarchar(15)	= null,
	@psTextType		nvarchar(2)	= null,
	@pnTextNo		int		= null,
        @psLanguageKey		nvarchar(10) 	= null
)
as
-- PROCEDURE:	csw_FetchCaseText
-- VERSION:	24
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseTextEntity business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 07 Nov 2005		RFC3201	1	Procedure created
-- 01 Dec 2005	TM	RFC3201	2	Include defaulting of Language.
-- 19 Dec 2005	TM	RFC3326	3	Suppress Goods and Services and Classes CaseText
-- 19 Dec 2005	TM	RFC3326	4	Change parameter @pbSuppressClassText to be @pbSuppressClassText.
-- 20 Dec 2005	TM	RFC3326	5	Correct class filtering logic.
-- 30 Nov 2007	AT	RFC3208	6	Add class specific filtering.
-- 24 Jan 2008	SW	RFC4206	7	Add the SITECONTROL check, and to deal with the condition when LASTMODIFIED is NULL.
-- 14 Feb 2008	AT	RFC3208	8	Fix bug with displaying class text.
-- 11 Dec 2008	MF	17136		9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Jan 2009  	LP  	RFC7488 	10 	 If param @pbSuppressClassText = 1, display Goods and Services CaseText with no Class. 
-- 08 May 2009	SF	RFC7631 	11	HasHistory is returned incorrectly.
-- 25 OCT 2010	ASH	RFC9564 	12	Filter Case Text according to language.
-- 29 Oct 2010	ASH	RFC9788 	13       Maintain Title in foreign languages.
-- 29 Nov 2010	ASH	RFC10009 	14      rectify Issue for long Case Text.
-- 23 Aug 2011	LP	RFC10993 	15	Allow to return Goods & Services row even if it does not have text stored against it.
--						Previously these were not returned and duplicate CASETEXT row is inserted for new G&S text.
-- 24 Oct 2011	ASH	R11460 	16	Convert CaseId to nvarchar(11) data type.
-- 01 Nov 2011	LP	R11394	17	Default language should be defaulted from LANGUAGE site control.
--					Otherwise set to English from TABLECODE.
-- 17 Feb 2012  MS  R11154  18      Return LogDateTimeStamp in result set
-- 15 Apr 2013	DV	R13270	19	Increase the length of nvarchar to 11 when casting or declaring integer
-- 13 Jun 2013	LP	R13507	20	Return TextType and TextTypeDescription in template if provided as a parameter.
-- 17 Mar 2014	SF	R32517	21	Should not return historical rows in all cases.
-- 20 May 2014	AK	R34568	22	Made the formatted case text dependent on the sitecontrol.
-- 08 Oct 2018	AV	R74875  23  Highlight items that are not defined
-- 01 Nov 2018	DV	R75391	24  Return default class heading in resultset
	
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sSQLSelect	nvarchar(2000)
Declare @sSQLFrom	nvarchar(2000)
Declare @sSQLWhere	nvarchar(2000)
Declare @sSQLOrderBy	nvarchar(2000)
Declare @sLookupCulture	nvarchar(10)
Declare @sLanguage nvarchar(10)
Declare @bHasDefaultTextOnly	bit
Declare @nAllowSubClassItem int
Declare @sCountryCode nvarchar(3)
Declare @sPropertyTypeCode nchar(1)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bHasDefaultTextOnly = 0

If @nErrorCode = 0
and @pnCaseKey is not null and @psClass is not null and @psTextType is not null
Begin
	SELECT @bHasDefaultTextOnly = cast(1 as bit)
	from CASETEXT C
	where C.CASEID = @pnCaseKey
	and C.CLASS = @psClass
	and C.TEXTTYPE = @psTextType
	and C.LANGUAGE IS NULL
	and ((C.LONGFLAG=0 and C.SHORTTEXT IS NULL)
	or datalength(C.TEXT) = 0)	
End

if @nErrorCode = 0
Begin
	Select @sCountryCode = ISNULL(TM1.COUNTRYCODE,'ZZZ') , 
	@sPropertyTypeCode = C.PROPERTYTYPE 
	from CASES C 
	left JOIN TMCLASS TM1 on (C.PROPERTYTYPE = TM1.PROPERTYTYPE and C.COUNTRYCODE = TM1.COUNTRYCODE)
	where C.CASEID = @pnCaseKey
End

If @nErrorCode = 0
Begin
Set @sSQLSelect = 
	"Select @sLanguage = convert(nvarchar(10),isnull(SC.COLINTEGER, TC.TABLECODE))
	from TABLECODES TC 
	left join SITECONTROL SC on (SC.CONTROLID = 'LANGUAGE')
	where TC.TABLETYPE = 47
	and (TC.TABLECODE = SC.COLINTEGER 
		or UPPER(TC.USERCODE) like 'EN%' 
		or UPPER(TC.DESCRIPTION) = 'ENGLISH');
	SELECT @nAllowSubClassItem = CASE WHEN P.ALLOWSUBCLASS = 1 THEN 1
									  WHEN P.ALLOWSUBCLASS = 2 THEN 2 ELSE 0 END 
			FROM	PROPERTYTYPE P 
			join CASES C ON (C.PROPERTYTYPE = P.PROPERTYTYPE)
			WHERE C.CASEID = @pnCaseKey;"

        exec @nErrorCode=sp_executesql @sSQLSelect,
					N'@sLanguage	nvarchar(10)	OUTPUT,
					@nAllowSubClassItem int OUTPUT,
					@pnCaseKey	int',
					  @sLanguage	= @sLanguage	OUTPUT,
					  @nAllowSubClassItem = @nAllowSubClassItem OUTPUT,
					  @pnCaseKey	= @pnCaseKey
End

If @nErrorCode = 0
and (@pbNewRow = 0 or @bHasDefaultTextOnly = 1)
Begin
	Set @sSQLSelect = 
	"Select
	CAST(C.CASEID as nvarchar(11))+'^'+
	C.TEXTTYPE+'^'+
	CAST(C.TEXTNO as nvarchar(11))		
				as RowKey,
	C.CASEID		as CaseKey,
	C.TEXTTYPE		as TextTypeCode,
	"+dbo.fn_SqlTranslatedColumn('TEXTTYPE','TEXTDESCRIPTION',null,'TP',@sLookupCulture,@pbCalledFromCentura)
				+ " as TextTypeDescription,
	C.TEXTNO		as TextSubSequence,
	C.CLASS			as Class,
	C.LANGUAGE		as LanguageKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as LanguageDescription,
	C.MODIFIEDDATE		as LastModified,
	CL.FIRSTUSE		as FirstUse,
	CL.FIRSTUSEINCOMMERCE	as FirstUseInCommerce,
	CASE WHEN SC.COLBOOLEAN=1 Then ISNULL("+dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','C',@sLookupCulture,@pbCalledFromCentura)
				+ ",
        "+dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ ")
	  ELSE dbo.fn_StripHTML(ISNULL("+dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','C',@sLookupCulture,@pbCalledFromCentura)
				+ ",
        "+dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ "))  END 
				as Text,
	CASE WHEN CTR.CaseTextRows > 1 THEN 1 ELSE 0 END
				as HasHistory," + 
		dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'TM',@sLookupCulture,@pbCalledFromCentura) +" AS ClassHeading,
		CASE 
	WHEN @nAllowSubClassItem = 2 THEN dbo.fn_ClassItemConcatedText(C.CASEID, C.LANGUAGE, C.CLASS) ELSE NULL END as ConcatedItemText,
        C.LOGDATETIMESTAMP      as LogDateTimeStamp"

	Set @sSQLFrom = "
	from CASETEXT C
	left join SITECONTROL SC on (SC.CONTROLID = 'Enable Rich Text Formatting')
	join TEXTTYPE TP	on (TP.TEXTTYPE = C.TEXTTYPE)
	left join TABLECODES TC	on (TC.TABLECODE = C.LANGUAGE)
	left join TMCLASS TM on (TM.CLASS = C.CLASS and TM.COUNTRYCODE = @sCountryCode and TM.PROPERTYTYPE = @sPropertyTypeCode
							and TM.SEQUENCENO = (SELECT min(TM1.SEQUENCENO) from TMCLASS TM1 
												where TM.CLASS = TM1.CLASS and TM.COUNTRYCODE = TM1.COUNTRYCODE 
												and TM.PROPERTYTYPE = TM1.PROPERTYTYPE))
	left join (Select CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE, COUNT(*) as CaseTextRows
		   from CASETEXT CT1
		   group by CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE) CTR on (CTR.CASEID = C.CASEID
								   and CTR.TEXTTYPE = C.TEXTTYPE
								   and (CTR.CLASS = C.CLASS or (CTR.CLASS is null and C.CLASS is null))
								   and (CTR.LANGUAGE = C.LANGUAGE
								    or (CTR.LANGUAGE is null and
									C.LANGUAGE is null)))
	left join CLASSFIRSTUSE CL on (C.CASEID=CL.CASEID
					and C.CLASS =CL.CLASS)
	left join (	select CASEID, TEXTTYPE, LANGUAGE, CLASS, MAX( convert(nvarchar(24),MODIFIEDDATE, 21)+cast(TEXTNO as nvarchar(6)) ) as LATESTDATE
			from CASETEXT
			group by CASEID, TEXTTYPE, LANGUAGE, CLASS	
			) CT2 on (CT2.CASEID = C.CASEID
					and   CT2.TEXTTYPE = C.TEXTTYPE
					and   (CT2.CLASS = C.CLASS or (CT2.CLASS is null and C.CLASS is null))
					and   (	(CT2.LANGUAGE = C.LANGUAGE)
						    or	(CT2.LANGUAGE	IS NULL
							 and C.LANGUAGE IS NULL))  )"


	Set @sSQLWhere = "
		where C.CASEID = @pnCaseKey"+
		CASE	WHEN @pbSuppressClassText = 1
			THEN CHAR(10)+"and C.CLASS is null"
			END+CHAR(10)+
		CASE	WHEN @psClass is not null
			THEN CHAR(10)+"and C.CLASS = @psClass"
			END+CHAR(10)+
		CASE	WHEN @psTextType is not null
			THEN CHAR(10)+"and C.TEXTTYPE = @psTextType"
			END+CHAR(10)+
		CASE	WHEN @pnTextNo is not null
			THEN CHAR(10)+"and C.TEXTNO = @pnTextNo"
			END+CHAR(10)

	set @sSQLWhere = @sSQLWhere + 
			"and ( (convert(nvarchar(24),C.MODIFIEDDATE, 21)+cast(C.TEXTNO as nvarchar(6))) = CT2.LATESTDATE
				or CT2.LATESTDATE is null )"
	
	if (@psLanguageKey is not null and @psLanguageKey != "" and @psLanguageKey != @sLanguage )
	Begin
		set @sSQLWhere = @sSQLWhere + 
			"and C.LANGUAGE =@psLanguageKey "
	End
        if (@psLanguageKey is not null and @psLanguageKey = @sLanguage )
	Begin
		set @sSQLWhere = @sSQLWhere + 
			" and ( C.LANGUAGE =@psLanguageKey or C.LANGUAGE is NULL) "
	End
	Set @sSQLOrderBy = 
		"order by CaseKey, TextTypeDescription, TextTypeCode, Class, LanguageDescription, LanguageKey"

	Set @sSQLString = @sSQLSelect + @sSQLFrom + @sSQLWhere + @sSQLOrderBy

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey		int,
			  @psClass		nvarchar(15),
			  @psTextType		nvarchar(2),
			  @pnTextNo		int,
                          @sLanguage            nvarchar(10),
                          @psLanguageKey        nvarchar(10),
						  @nAllowSubClassItem	int,
						  @sPropertyTypeCode	nchar(1),
						  @sCountryCode			nvarchar(3)',
			  @pnCaseKey	 	= @pnCaseKey,
			  @psClass 		= @psClass,
			  @psTextType 		= @psTextType,
			  @pnTextNo		= @pnTextNo,
                          @psLanguageKey        = @psLanguageKey,
                          @sLanguage            = @sLanguage,
						  @nAllowSubClassItem	= @nAllowSubClassItem,
						  @sPropertyTypeCode	= @sPropertyTypeCode,
						  @sCountryCode			= @sCountryCode
End
Else If @nErrorCode = 0
and @pbNewRow = 1
Begin
	Set @sSQLString = 
	"Select
	'NewKey'        as RowKey,
	@pnCaseKey	as CaseKey," +
	CASE WHEN @psTextType is not null THEN 
	"TP.TEXTTYPE as TextTypeCode," +dbo.fn_SqlTranslatedColumn('TEXTTYPE','TEXTDESCRIPTION',null,'TP',@sLookupCulture,@pbCalledFromCentura)
				+ " as TextTypeDescription,"
	ELSE
	"null as TextTypeCode,
	null as TextTypeDescription,"
	END
	+
	"null		as TextSubSequence,
	null		as Class,
	TC.TABLECODE	as LanguageKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as LanguageDescription,
	null		as LastModified,
	null		as Text,
	0		as HasHistory,
	null	as ClassHeading,
	CASE WHEN @nAllowSubClassItem = 2 THEN dbo.fn_ClassItemConcatedText(C.CASEID, NULL, NULL) ELSE NULL END as ConcatedItemText,
	null            as LogDateTimeStamp
	from CASES C
	left join OFFICE O		on (O.OFFICEID = C.OFFICEID)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'LANGUAGE')
	left join TABLECODES TC		on (TC.TABLECODE = ISNULL(O.LANGUAGECODE,SC.COLINTEGER))" +
	
	CASE WHEN @psTextType is not null THEN 
	"left join TEXTTYPE TP	on (TP.TEXTTYPE = @psTextType)"
	ELSE NULL END
	
	+
	"where C.CASEID = @pnCaseKey
	order by CaseKey, TextTypeDescription, TextTypeCode, Class, LanguageDescription, LanguageKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey		int,
			  @psTextType		nvarchar(2),
			  @nAllowSubClassItem	int',
			  @pnCaseKey	 	= @pnCaseKey,
			  @psTextType		= @psTextType,
			  @nAllowSubClassItem = @nAllowSubClassItem
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCaseText to public
GO
