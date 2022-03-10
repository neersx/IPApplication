-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCPAEnquiry
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCPAEnquiry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCPAEnquiry.'
	Drop procedure [dbo].[csw_ListCPAEnquiry]
End
Print '**** Creating Stored Procedure dbo.csw_ListCPAEnquiry...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCPAEnquiry
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey              int,            -- Mandatory
	@pnBatchNo              int             = null,
	@pbCalledFromCentura	bit		= 0,
        @psResultsRequired      nvarchar(254)   = null	
)
as
-- PROCEDURE:	csw_ListCPAEnquiry
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return CPA Enquiry information

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Sep 2009	LP	RFC938	1	Procedure created
-- 04 May 2016	LP	R54852	2	Return additional result set from CPASENDDEBTORS table.
-- 06 May 2016	LP	R54852	3	Debtors are returned in ROWID sequence.
--					Retrieve Debtor details from batches before the current CPASEND case batch.
-- 17 May 2016	LP	R61529	4	Return the latest batch first by default.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

CREATE TABLE #TEMPBATCHNUMBERS (
	BATCHNO              int 		NOT NULL
)

declare	@nErrorCode	int
declare @sPropertyType  nvarchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
        Select @sPropertyType = PROPERTYTYPE
        from CASES
        where CASEID = @pnCaseKey
        
        Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
        Insert into #TEMPBATCHNUMBERS
        SELECT BATCHNO		
        FROM CPARECEIVE WHERE CASEID = @pnCaseKey  		
        UNION  		
        SELECT BATCHNO
        FROM CPASEND WHERE CASEID = @pnCaseKey  	                             		
        ORDER BY BATCHNO   
End

-- Return list of Batch Numbers for this Case
If @nErrorCode = 0
and @pnBatchNo is null
Begin
        SELECT BATCHNO as BatchNumber
        from #TEMPBATCHNUMBERS
        order by BATCHNO
        
        Set @nErrorCode = @@ERROR     
End

-- Header Result Set
If @nErrorCode = 0
Begin
        SELECT @pnCaseKey as CaseKey,
                C.IRN as CaseReference,
                isnull(@pnBatchNo, max(T.BATCHNO)) as BatchNumber                
        FROM CASES C, #TEMPBATCHNUMBERS T
        where C.CASEID = @pnCaseKey
        GROUP BY C.IRN
        
        Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
and (@psResultsRequired is null or @psResultsRequired = 'DIFFDATA')
Begin
        If @pnBatchNo is null
        Begin
                SELECT @pnBatchNo = MIN(BATCHNO)
                from #TEMPBATCHNUMBERS
                
                Set @nErrorCode = @@ERROR                
        End
        
        If @nErrorCode = 0
        Begin
                exec @nErrorCode = cpa_ReportSendReceiveDifferences 
                             @pnBatchNo         = @pnBatchNo,	
                             @psPropertyType    = @sPropertyType,
                             @pbNotProperty     = 0,
                             @psOfficeCPACode   = null,
                             @pnCaseKey         = @pnCaseKey,
                             @pbDiffOnly        = 0,
                             @pbCalledFromCentura = @pbCalledFromCentura        
        End

	If @nErrorCode = 0
	Begin
		select DISTINCT
		C.INVOICEECODE as 'NameCode', 
		dbo.fn_ApplyNameCodeStyle(CSN.INVOICEENAME, 2, C.INVOICEECODE)as 'Name',
		C.BILLPERCENTAGE as 'BillPercentage',
		CSN.INVOICEEATTENTION as 'Attention',
		CSN.INVADDRESSLINE1
			+CASE WHEN CSN.INVADDRESSLINE2 IS NOT NULL THEN +CHAR(10)+CSN.INVADDRESSLINE2 ELSE NULL END
			+CASE WHEN CSN.INVADDRESSLINE3 IS NOT NULL THEN +CHAR(10)+CSN.INVADDRESSLINE3 ELSE NULL END
			+CASE WHEN CSN.INVADDRESSLINE4 IS NOT NULL THEN +CHAR(10)+CSN.INVADDRESSLINE4 ELSE NULL END
			+CASE WHEN CSN.INVADDRESSPOSTCODE IS NOT NULL THEN +CHAR(10)+CSN.INVADDRESSPOSTCODE ELSE NULL END
			+CASE WHEN CSN.INVADDRESSCOUNTRY IS NOT NULL THEN +CHAR(10)+CSN.INVADDRESSCOUNTRY ELSE NULL END
			as 'Address',
		CSN.INVOICEETELEPHONE as 'Telephone',
		CSN.INVOICEEFAX as 'Fax',
		CSN.INVOICEEEMAIL 'Email',
		C.ROWID as 'RowId'
		from CPASEND CS
		join CPASENDDEBTORS C on (CS.ROWID = C.CPASENDROWID)
		join CPASEND CSN on (CSN.INVOICEECODE = C.INVOICEECODE 
					and CSN.CASEID IS NULL)
		where CS.CASEID = @pnCaseKey
		and CS.BATCHNO = @pnBatchNo
		and CSN.BATCHNO = (select max(BATCHNO) from CPASEND 
					where CASEID IS NULL 
					and INVOICEECODE = C.INVOICEECODE
					and BATCHNO <= @pnBatchNo)
		ORDER by 'RowId'

		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
and (@psResultsRequired is null or @psResultsRequired = 'EVENTS')
Begin
        SELECT  ROW_NUMBER() OVER (ORDER BY EVENTDATE DESC) as RowKey,
                E.CEFNO as CEFNumber, 
                E.AGENTCASECODE as AgentCaseCode, 
                E.ANNUITY as Annuity,  
                E.CASEID as CaseKey, 
                E.CASELAPSEDATE as CaseLapseDate, 
                E.CLIENTCASECODE as ClientCaseCode,  
                E.CLIENTKEY as ClientKey, 
                E.CLIENTREF as ClientRef, 
                E.COUNTRYCODE as CountryCode,  
                E.CPAACCOUNTNO as CPAAccountNo, 
                E.CURRENCY as Currency, 
                E.DIVISIONCODE as DivisionCode,  
                E.EVENTAMOUNT as EventAmount, 
                E.EVENTCODE as EventCode, 
                E.EVENTDATE as ReportedEventDateTime,  
                E.EVENTNARRATIVE as EventNarrative, 
                E.EXPIRYDATE as ExpiryDate, 
                E.INVOICEITEMNO as InvoiceItemNo,  
                E.INVOICENO as InvoiceNo, 
                E.IPRURN as IPRURN, 
                E.LINKEDCASEFLAG as LinkedCaseFlag,  
                E.NEXTRENEWALDATE as NextRenewalDate, 
                E.FILENUMBER as FileNo, 
                E.PROPRIETOR as Proprietor,  
                E.REGISTRATIONNO as RegistrationNo, 
                E.RENEWALEVENTDATE as RenewalEventDate, 
                E.TYPECODE as PropertyTypeKey,  
                E.TYPENAME as PropertyTypeDescription, 
                E.CASEEVENTNO as CaseEventKey, 
                EC.DESCRIPTION as Description, 
                E.FINEAMOUNT as FineAmount                                                                                                                        
		FROM CPAEVENT E   
                left outer join CPAEVENTCODE EC on (E.EVENTCODE = EC.CPAEVENTCODE) 
                WHERE CASEID = @pnCaseKey 
                ORDER BY EVENTDATE DESC
                
                Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
and (@psResultsRequired is null or @psResultsRequired = 'PORTFOLIO')
Begin
        SELECT  PORTFOLIONO as RowKey, 
                AGENTCASECODE as AgentCaseCode, 
                ANNUITY as Annuity,  
                APPLICATIONDATE as ApplicationDate, 
                APPLICATIONNO as ApplicationNo, 
                BASEDATE as BaseDate,  
                CASEID as CaseKey, 
                CLIENTCASECODE as ClientCaseCode, 
                CLIENTCURRENCY as ClientCurrency,  
                CLIENTNO as ClientNo, 
                CLIENTREF as ClientRef, 
                DATEOFPORTFOLIOLST as PortfolioDate,  
                DIVISIONCODE as DivisionCode, 
                DIVISIONNAME as DivisionName, 
                EXPIRYDATE as ExpiryDate,  
                FIRSTPRIORITYDATE as FirstPriorityDate, 
                FIRSTPRIORITYNO as FirstPriorityNo, 
                GRANTDATE as GrantDate,  
                IPCOUNTRYCODE as IPCountryCode, 
                IPRENEWALNO as IPRenewalNo, 
                IPRURN as IPRURN,  
                LASTAMENDDATE as LastAmendDate, 
                NEXTRENEWALDATE as NextRenewalDate, 
                PARENTDATE as ParentDate,  
                PARENTNO as ParentNo, 
                PATENTPCTNO as PatentPCTNo, 
                PCTFILINGDATE as PCTFilingDate,  
                PROPOSEDIRN as ProposedIRN, 
                PROPRIETOR as Proprietor, 
                PUBLICATIONDATE as PublicationDate,  
                PUBLICATIONNO as PublicationNo, 
                REGISTRATIONNO as RegistrationNo, 
                RESPONSIBLEPARTY as ResponsibleParty,  
                STATUSINDICATOR as StatusIndicator, 
                TRADEMARKREF as TrademarkRef, 
                TYPECODE as PropertyTypeKey,  
                TYPENAME as PropertyTypeDescription                                           
                FROM CPAPORTFOLIO 
                WHERE CASEID = @pnCaseKey
                
        Set @nErrorCode = @@ERROR
End


Return @nErrorCode
GO

Grant execute on dbo.csw_ListCPAEnquiry to public
GO
