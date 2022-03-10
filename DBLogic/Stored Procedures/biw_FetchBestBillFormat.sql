-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_FetchBestBillFormat] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_FetchBestBillFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_FetchBestBillFormat].'
	drop procedure dbo.[biw_FetchBestBillFormat]
end
print '**** Creating procedure dbo.[biw_FetchBestBillFormat]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS OFF
go

create procedure dbo.[biw_FetchBestBillFormat]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnBillFormatId int = null OUTPUT, -- set this if you want to return BillFormatDirectly
				@pnLanguage		int = null, -- Set the remainder if best fit is to be used.
				@pnEntityNo		int = null,
				@pnNameNo		int = null,
				@psCaseType		nvarchar(1) = null,
				@psAction		nvarchar(2) = null,
				@psPropertyType	nvarchar(1) = null,
				@pnRenewalWIP	int = null,
				@pnSingleCase	int = null,
				@pnEmployeeNo	int = null,
				@pnOfficeId		int	= null,
				@pbReturnBillFormatDetails int = 1

as
-- PROCEDURE :	biw_FetchBestBillFormat
-- VERSION :	8
-- DESCRIPTION:	A procedure that returns the best fit Bill Format
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 30-Nov-2009	AT	RFC3605	1	Procedure created
-- 07-May-2010	AT	RFC9135	2	Incorporate bill profile into best fit.
-- 27-May-2010	AT	RFC9092	3	Put NameNo back into best fit for backwards compatability.
-- 24-Jun-2010	MS	RFC7269	4	Add ConsolidateMar and MarginWIPCode
-- 03-Jun-2011	AT	RFC10763	5	Fixed (added) Office best fit null check.
-- 06-Dec-2011	AT	RFC10458	6	Return SORTTAXCODE column.
-- 19-Nov-2012	MS	R12954		7	Fixed (added) Renewal WIP best fit null check.
-- 11-Feb-2013	DV	R13175	8	Get the OfficeId from the NameNo

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@nBestFitScore	int
Declare		@nBillProfileId	int

Set @ErrorCode = 0

If (@ErrorCode = 0 and @pnBillFormatId is null)
Begin

	Set @sSQLString = "Select @nBillProfileId = BILLFORMATID
				FROM IPNAME WHERE NAMENO = @pnNameNo"
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nBillProfileId int OUTPUT,
					@pnNameNo int',
					@nBillProfileId = @nBillProfileId OUTPUT,
					@pnNameNo = @pnNameNo

	If (@ErrorCode = 0 and @pnOfficeId is null and @pnEmployeeNo is not null)
	Begin
		Set @sSQLString = "SELECT @pnOfficeId = TABLECODE 
							FROM TABLEATTRIBUTES
							WHERE TABLETYPE = 44
							and PARENTTABLE = 'NAME'
							and GENERICKEY = @pnEmployeeNo"
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnOfficeId int OUTPUT,
						@pnEmployeeNo int',
						@pnOfficeId = @pnOfficeId OUTPUT,
						@pnEmployeeNo = @pnEmployeeNo
	End
	
	If (@ErrorCode = 0)
	Begin
		Set @sSQLString = "
			select @pnBillFormatId = BESTFIT.BillFormatId
			From 
			(SELECT  top 1 (1 - ISNULL( (LANGUAGE * 0), 1 ) )		* 10000000000 + 
				(1 - ISNULL( (ENTITYNO * 0), 1 ) )					* 1000000000 +
				CASE WHEN FORMATPROFILEID IS NULL THEN 0 ELSE 1 END	* 100000000 +
				CASE WHEN NAMENO IS NULL THEN 0 ELSE 1 END			* 10000000 +
				CASE WHEN CASETYPE IS NULL THEN 0 ELSE 1 END		* 1000000 +
				CASE WHEN ACTION IS NULL THEN 0 ELSE 1 END			* 100000 +
				CASE WHEN PROPERTYTYPE IS NULL THEN 0 ELSE 1 END	* 10000 + 
				(1- ISNULL( (RENEWALWIP * 0), 1 ) )					* 1000 +
				(1- ISNULL( (SINGLECASE * 0), 1 ) )					* 100 + 
				(1- ISNULL( (EMPLOYEENO * 0), 1 ) )					* 10 + 
				(1- ISNULL( (OFFICEID * 0), 1 ) )					* 1 as BESTFITSCORE,
			BILLFORMATID as 'BillFormatId'
			FROM BILLFORMAT
			WHERE (LANGUAGE = @pnLanguage OR LANGUAGE IS NULL) 
			AND (ENTITYNO = @pnEntityNo OR ENTITYNO IS NULL)
			AND (FORMATPROFILEID = @nBillProfileId OR FORMATPROFILEID IS NULL)
			AND (NAMENO = @pnNameNo OR NAMENO IS NULL)
			AND (CASETYPE = @psCaseType OR CASETYPE IS NULL) 
			AND (ACTION = @psAction OR ACTION IS NULL) 
			AND (PROPERTYTYPE = @psPropertyType OR PROPERTYTYPE IS NULL) 
			AND (RENEWALWIP = @pnRenewalWIP OR RENEWALWIP IS NULL)
			AND (SINGLECASE = @pnSingleCase OR SINGLECASE IS NULL) 
			AND (EMPLOYEENO = @pnEmployeeNo OR EMPLOYEENO IS NULL) 
			AND (OFFICEID = @pnOfficeId OR OFFICEID IS NULL)
			AND UPPER(RIGHT(BILLFORMATREPORT, 3)) = 'RDL'
			ORDER BY 1 DESC) as BESTFIT"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'
					@pnBillFormatId int OUTPUT,
					@pnLanguage		int,
					@pnEntityNo		int,
					@nBillProfileId	int,
					@pnNameNo		int,
					@psCaseType		nvarchar(1),
					@psAction		nvarchar(2),
					@psPropertyType	nvarchar(1),
					@pnRenewalWIP	int,
					@pnSingleCase	int,
					@pnEmployeeNo	int,
					@pnOfficeId		int',
					@pnBillFormatId = @pnBillFormatId OUTPUT,
					@pnLanguage=@pnLanguage,
					@pnEntityNo=@pnEntityNo,
					@nBillProfileId=@nBillProfileId,
					@pnNameNo=@pnNameNo,
					@psCaseType=@psCaseType,
					@psAction=@psAction,
					@psPropertyType=@psPropertyType,
					@pnRenewalWIP=@pnRenewalWIP,
					@pnSingleCase=@pnSingleCase,
					@pnEmployeeNo=@pnEmployeeNo,
					@pnOfficeId=@pnOfficeId
	End
End


If (@pnBillFormatId is not null and @pbReturnBillFormatDetails = 1)
Begin
	Set @sSQLString = "
		select 
		BILLFORMATID as 'BillFormatId',
		ACTION as 'Action',
		BILLFORMATDESC as 'BillFormatDesc',  
		BILLFORMATREPORT as 'BillFormatReport',
		CASETYPE as 'CaseType', 
		CONSOLIDATECHTYP as 'ConsolidateChTyp',
		CONSOLIDATEDISC as 'ConsolidateDisc', 
		CONSOLIDATEMAR as 'ConsolidateMar',
		CONSOLIDATEOR as 'ConsolidateOR',
		CONSOLIDATEPD as 'ConsolidatePD',
		CONSOLIDATESC as 'ConsolidateSC',
		DISC.COLCHARACTER as 'DiscountWIPCode',
		MAR.COLCHARACTER as 'MarginWIPCode',
		BF.COVERINGLETTER as 'CoveringLetter',
		DEBITNOTE as 'DebitNote',
		DETAILSREQUIRED as 'DetailsRequired',
		EMPLOYEENO as 'EmployeeNo',
		ENTITYNO as 'EntityNo',
		EXPENSEGROUPTITLE as 'ExpenseGroupTitle',
		FORMATNAME as 'FormatName',
		LANGUAGE as 'Language',
		NAMENO as 'NameNo',
		OFFICEID as 'OfficeId',
		BF.PROPERTYTYPE as 'PropertyType',
		RENEWALWIP as 'RenewalWIP',
		SINGLECASE as 'SingleCase',
		SORTCASE as 'SortCase',
		SORTCASEMODE as 'SortCaseMode',
		SORTDATE as 'SortDate',
		SORTWIPCATEGORY as 'SortWIPCategory',
		SORTCASETITLE as 'SortCaseTitle',
		SORTCASEDEBTORREF as 'SortCaseDebtorRef',
		cast(L.DOCUMENTTYPE as int) as 'DocumentType',
		SORTTAXCODE as 'SortTaxCode'
		from BILLFORMAT BF
		Left Join LETTER L on (L.LETTERNO = BF.DEBITNOTE),
		SITECONTROL DISC, SITECONTROL MAR
		where BILLFORMATID = @pnBillFormatId
		and DISC.CONTROLID = 'Discount WIP Code'
		and MAR.CONTROLID = 'Margin WIP Code'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBillFormatId	int',
					@pnBillFormatId=@pnBillFormatId
End

return @ErrorCode
go

grant execute on dbo.[biw_FetchBestBillFormat]  to public
go


