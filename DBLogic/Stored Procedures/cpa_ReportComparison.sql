-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ReportComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ReportComparison]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ReportComparison.'
	drop procedure dbo.cpa_ReportComparison
end
print '**** Creating procedure dbo.cpa_ReportComparison...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_ReportComparison 
		@pnBatchNo 		int,			-- mandatory
		@pnCaseId		int		=null,	-- Restrict to a single case
		@pbUpdateRejectList	tinyint		=0, 
		@pnCPAReceivedEvent	int		=null,	-- The event that is updated when the EPL is accepted
		@psPropertyType		nvarchar(2)	=null,
		@pbNotProperty		bit		=0,
		@psOfficeCPACode	nvarchar(3)	=null,	-- Filter by Office
		@psCPANarrative		nvarchar(50)	=null	-- Filter by the CPA Narrative
as
-- PROCEDURE :	cpa_ReportComparison
-- VERSION :	19
-- DESCRIPTION:	Performs a data comparison of the CPARECEIVE table against the CPASEND table.
--		When called with a specific CASEID then it will return a boolean flag indicating
--		those columns that have failed the comparison.
-- CALLED BY :	cpa_BatchComparison
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02/08/2002	MF			Procedure Created
-- 03/09/2002	MF			Client Reference is not to be compared if nothing was orginally sent.
-- 25/09/2002	MF	8020		Do not perform the comparison if the Narrive on the EPL has been flagged
--					to exlude the comparison.
-- 08/11/2002	MF	8134		The data comparison stage of the CPA Interface import is rejecting records 
--					because an exact match is not found.  A softer comparison in some instances 
--					is required to reduce the number of rejections without compromising the data.
-- 17/12/2002	MF	8232		Allow PropertyType and Not Property to be passed as parameters to filter the 
--					comparison
-- 04/02/03	MF	8399		Modifications to improve performance of displaying differences for a single Case.
-- 07/02/2003	MF	8296		Comparison of Names for Cases sent to CPA against those received from CPA 
--					will remove any words marked as Stop Words for Names.
--					NOTE : This change makes the process SQLServer 2000 specific !!!
-- 24/02/2003	MF	8444		If there is a match on International Classes then ignore the fact that the Local
--					classes is missing from the received data because CPA do not save the local
--					classes if the international classes exist
-- 27/03/2003	MF	8582		If the CPARECEIVE table does not have an IPRURN then the Case is to be rejected because
--					this indicates that the Case has not been loaded onto the CPA Portfolio.
-- 07/04/2003	MF	8582		Revisit of SQL for 8582 to ignore entries that do not have a CASEID.
-- 09 Apr 2003	MF	8650		Move the UPPER function into the fn_RemoveNoiceCharacters
-- 09 Apr 2003	MF	8582		Revist to include PropertyType filtering
-- 04 Jun 2003  MF	8887		Remove case sensitivity issues in the data comparison on specific fields.
-- 24 Jun 2003	MF	8721		Use the ACKNOWLEDGED column to indicate if a row has already been processed.
-- 08 Jul 2003	MF	8955		CPA Narratives marked for exclusion during the data comparison should only effect 
--					Cases on the live CPA Portfolio
-- 30 Jul 2003	MF	9029	10	Problem for clients using replication that have added a column to CPARECEIVE
--					and CPASEND.  Do not use "SELECT *"
-- 30 Jul 2003	MF	9029	11	Revisit
-- 06 Nov 2003	MF	9432	12	Data comparisons with CPA data should ignore comparing the Renewal Date if 
--					no Renewal Date was sent to CPA.
-- 26 Aug 2004	MF	10413	13	Do not compare the Priority Date if it was not sent to CPA
-- 05 Aug 2004	AB	8035	13	Add collate database_default to temp table definitions
-- 30 Mar 2005	MF	10481	14	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 09 May 2005	MF	10731	15	Allow cases to be filtered by Office User Code.
-- 15 Jun 2005	MF	10731	16	Revisit.  Change Office User Code to Office CPA Code.
-- 16 Jun 2005	MF	11516	17	Display all CPARECEIVE rows in a batch when Narrative is passed as a 
--					parameter.
-- 14 Jun 2006	MF	12810	18	This is part of a partial correction for this SQA to help address the situation
--					where the IRN of Case has been changed after the batch has been sent to CPA.
-- 19 Jun 2006	MF	12855	19	Problem occurring where Narratives are mapped to Events and the Narrative
--					string appears within another Narrative. 


set nocount on

-- Temporary tables used in comparing data for a specific Case.  This has been coded 
-- this way for performance reasons only to allow the comaparison statement to be written
-- without any variables.

CREATE TABLE #TEMPCPARECEIVE (
        CASEID               int		NULL,
        SYSTEMID             nvarchar(3)	collate database_default NULL,
        BATCHNO              int 		NOT NULL,
        BATCHDATE	     datetime		NULL,
        PROPERTYTYPE         nchar(1)		collate database_default NULL,
        CASECODE             nvarchar(15) 	collate database_default NULL,
        TRANSACTIONCODE      smallint		NULL,
        ALTOFFICECODE        nvarchar(3)	collate database_default NULL,
        FILENUMBER           nvarchar(15) 	collate database_default NULL,
        CLIENTSREFERENCE     nvarchar(35) 	collate database_default NULL,
        CPACOUNTRYCODE       nvarchar(2)	collate database_default NULL,
        RENEWALTYPECODE      nvarchar(2)	collate database_default NULL,
        MARK                 nvarchar(100) 	collate database_default NULL,
        ENTITYSIZE           nchar(1)		collate database_default NULL,
        PRIORITYDATE         datetime		NULL,
        PARENTDATE           datetime		NULL,
        NEXTTAXDATE          datetime		NULL,
        NEXTDECOFUSEDATE     datetime		NULL,
        PCTFILINGDATE        datetime		NULL,
        ASSOCDESIGNDATE      datetime		NULL,
        NEXTAFFIDAVITDATE    datetime		NULL,
        APPLICATIONDATE      datetime		NULL,
        ACCEPTANCEDATE       datetime		NULL,
        PUBLICATIONDATE      datetime		NULL,
        REGISTRATIONDATE     datetime		NULL,
        RENEWALDATE          datetime		NULL,
        NOMINALWORKINGDATE   datetime		NULL,
        EXPIRYDATE           datetime		NULL,
        CPASTARTPAYDATE      datetime		NULL,
        CPASTOPPAYDATE       datetime		NULL,
        STOPPAYINGREASON     nchar(1)		collate database_default NULL,
        PRIORITYNO           nvarchar(30) 	collate database_default NULL,
        PARENTNO             nvarchar(30) 	collate database_default NULL,
        PCTFILINGNO          nvarchar(30) 	collate database_default NULL,
        ASSOCDESIGNNO        nvarchar(30) 	collate database_default NULL,
        APPLICATIONNO        nvarchar(30) 	collate database_default NULL,
        ACCEPTANCENO         nvarchar(30) 	collate database_default NULL,
        PUBLICATIONNO        nvarchar(30) 	collate database_default NULL,
        REGISTRATIONNO       nvarchar(30) 	collate database_default NULL,
        INTLCLASSES          nvarchar(150) 	collate database_default NULL,
        LOCALCLASSES         nvarchar(150) 	collate database_default NULL,
        NUMBEROFYEARS        smallint		NULL,
        NUMBEROFCLAIMS       smallint		NULL,
        NUMBEROFDESIGNS      smallint		NULL,
        NUMBEROFCLASSES      smallint		NULL,
        NUMBEROFSTATES       smallint		NULL,
        DESIGNATEDSTATES     nvarchar(200) 	collate database_default NULL,
        OWNERNAME            nvarchar(100) 	collate database_default NULL,
        OWNERNAMECODE        nvarchar(35) 	collate database_default NULL,
        OWNADDRESSLINE1      nvarchar(50) 	collate database_default NULL,
        OWNADDRESSLINE2      nvarchar(50) 	collate database_default NULL,
        OWNADDRESSLINE3      nvarchar(50) 	collate database_default NULL,
        OWNADDRESSLINE4      nvarchar(50) 	collate database_default NULL,
        OWNADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        OWNADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        CLIENTCODE           nvarchar(15)	collate database_default NULL,
        CPACLIENTNO          int		NULL,
        CLIENTNAME           nvarchar(100)	collate database_default NULL,
        CLIENTATTENTION      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        CLTADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        CLTADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        CLIENTTELEPHONE      nvarchar(20)	collate database_default NULL,
        CLIENTFAX            nvarchar(20)	collate database_default NULL,
        CLIENTEMAIL          nvarchar(100)	collate database_default NULL,
        DIVISIONCODE         nvarchar(6)	collate database_default NULL,
        DIVISIONNAME         nvarchar(100)	collate database_default NULL,
        DIVISIONATTENTION    nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        DIVADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        DIVADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        FOREIGNAGENTCODE     nvarchar(8)	collate database_default NULL,
        FOREIGNAGENTNAME     nvarchar(100)	collate database_default NULL,
        ATTORNEYCODE         nvarchar(8)	collate database_default NULL,
        ATTORNEYNAME         nvarchar(100)	collate database_default NULL,
        INVOICEECODE         nvarchar(15)	collate database_default NULL,
        CPAINVOICEENO        int		NULL,
        INVOICEENAME         nvarchar(100)	collate database_default NULL,
        INVOICEEATTENTION    nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        INVADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        INVADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        INVOICEETELEPHONE    nvarchar(20)	collate database_default NULL,
        INVOICEEFAX          nvarchar(20)	collate database_default NULL,
        INVOICEEEMAIL        nvarchar(100)	collate database_default NULL,
        NARRATIVE            nvarchar(50)	collate database_default NULL,
	IPRURN               nvarchar(7)        collate database_default NULL,
	ACKNOWLEDGED         decimal(1,0)	NULL
 )
 
 
 CREATE TABLE #TEMPCPASEND (
        CASEID               int		NULL,
        SYSTEMID             nvarchar(3)	collate database_default NULL,
        BATCHNO              int 		NOT NULL,
        BATCHDATE	     datetime		NULL,
        PROPERTYTYPE         nchar(1)		collate database_default NULL,
        CASECODE             nvarchar(15)	collate database_default NULL,
        TRANSACTIONCODE      smallint		NULL,
        ALTOFFICECODE        nvarchar(3)	collate database_default NULL,
        FILENUMBER           nvarchar(15)	collate database_default NULL,
        CLIENTSREFERENCE     nvarchar(35)	collate database_default NULL,
        CPACOUNTRYCODE       nvarchar(2)	collate database_default NULL,
        RENEWALTYPECODE      nvarchar(2)	collate database_default NULL,
        MARK                 nvarchar(100)	collate database_default NULL,
        ENTITYSIZE           nchar(1)		collate database_default NULL,
        PRIORITYDATE         datetime		NULL,
        PARENTDATE           datetime		NULL,
        NEXTTAXDATE          datetime		NULL,
        NEXTDECOFUSEDATE     datetime		NULL,
        PCTFILINGDATE        datetime		NULL,
        ASSOCDESIGNDATE      datetime		NULL,
        NEXTAFFIDAVITDATE    datetime		NULL,
        APPLICATIONDATE      datetime		NULL,
        ACCEPTANCEDATE       datetime		NULL,
        PUBLICATIONDATE      datetime		NULL,
        REGISTRATIONDATE     datetime		NULL,
        RENEWALDATE          datetime		NULL,
        NOMINALWORKINGDATE   datetime		NULL,
        EXPIRYDATE           datetime		NULL,
        CPASTARTPAYDATE      datetime		NULL,
        CPASTOPPAYDATE       datetime		NULL,
        STOPPAYINGREASON     nchar(1)		collate database_default NULL,
        PRIORITYNO           nvarchar(30)	collate database_default NULL,
        PARENTNO             nvarchar(30)	collate database_default NULL,
        PCTFILINGNO          nvarchar(30)	collate database_default NULL,
        ASSOCDESIGNNO        nvarchar(30)	collate database_default NULL,
        APPLICATIONNO        nvarchar(30)	collate database_default NULL,
        ACCEPTANCENO         nvarchar(30)	collate database_default NULL,
        PUBLICATIONNO        nvarchar(30)	collate database_default NULL,
        REGISTRATIONNO       nvarchar(30)	collate database_default NULL,
        INTLCLASSES          nvarchar(150)	collate database_default NULL,
        LOCALCLASSES         nvarchar(150)	collate database_default NULL,
        NUMBEROFYEARS        smallint		NULL,
        NUMBEROFCLAIMS       smallint		NULL,
        NUMBEROFDESIGNS      smallint		NULL,
        NUMBEROFCLASSES      smallint		NULL,
        NUMBEROFSTATES       smallint		NULL,
        DESIGNATEDSTATES     nvarchar(200)	collate database_default NULL,
        OWNERNAME            nvarchar(100)	collate database_default NULL,
        OWNERNAMECODE        nvarchar(35)	collate database_default NULL,
        OWNADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        OWNADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        OWNADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        OWNADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        OWNADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        OWNADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        CLIENTCODE           nvarchar(15)	collate database_default NULL,
        CPACLIENTNO          int		NULL,
        CLIENTNAME           nvarchar(100)	collate database_default NULL,
        CLIENTATTENTION      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        CLTADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        CLTADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        CLTADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        CLIENTTELEPHONE      nvarchar(20)	collate database_default NULL,
        CLIENTFAX            nvarchar(20)	collate database_default NULL,
        CLIENTEMAIL          nvarchar(100)	collate database_default NULL,
        DIVISIONCODE         nvarchar(6)	collate database_default NULL,
        DIVISIONNAME         nvarchar(100)	collate database_default NULL,
        DIVISIONATTENTION    nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        DIVADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        DIVADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        DIVADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        FOREIGNAGENTCODE     nvarchar(8)	collate database_default NULL,
        FOREIGNAGENTNAME     nvarchar(100)	collate database_default NULL,
        ATTORNEYCODE         nvarchar(8)	collate database_default NULL,
        ATTORNEYNAME         nvarchar(100)	collate database_default NULL,
        INVOICEECODE         nvarchar(15)	collate database_default NULL,
        CPAINVOICEENO        int		NULL,
        INVOICEENAME         nvarchar(100)	collate database_default NULL,
        INVOICEEATTENTION    nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE1      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE2      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE3      nvarchar(50)	collate database_default NULL,
        INVADDRESSLINE4      nvarchar(50)	collate database_default NULL,
        INVADDRESSCOUNTRY    nvarchar(50)	collate database_default NULL,
        INVADDRESSPOSTCODE   nvarchar(16)	collate database_default NULL,
        INVOICEETELEPHONE    nvarchar(20)	collate database_default NULL,
        INVOICEEFAX          nvarchar(20)	collate database_default NULL,
        INVOICEEEMAIL        nvarchar(100)	collate database_default NULL,
        NARRATIVE            nvarchar(50) 	collate database_default NULL,
	IPRURN               nvarchar(7)        collate database_default NULL,
	ACKNOWLEDGED         decimal(1,0)	NULL
 )

declare	@ErrorCode		int
declare @RowCount		int
declare	@TranCountStart		int
declare	@sSQLString		nvarchar(4000)
declare @sPropertyType		nvarchar(100)

Select	@ErrorCode	=0
Select	@TranCountStart	=0

-- If a specific Case is to have its differences identified then for 
-- performance reasons load the CPASEND and CPARECEIVE rows for the Case and 
-- batch into a temporary table.

If  @ErrorCode=0
and @pnCaseId is not null
and @pbUpdateRejectList=0
Begin
	-- Create a temporary table mirroring the CPARECEIVE table.
	-- The temporary table cannot be created in sp_executesql as we need to reference
	-- it in this stored procedure in a later query.

	Set @sSQLString="
	Insert into #TEMPCPARECEIVE 
	       (CASEID,SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,FILENUMBER,
		CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,PARENTDATE,NEXTTAXDATE,
		NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,APPLICATIONDATE,ACCEPTANCEDATE,
		PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,EXPIRYDATE,CPASTARTPAYDATE,
		CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,
		PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,
		NUMBEROFCLASSES,NUMBEROFSTATES,DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,
		OWNADDRESSLINE3,OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
		CLIENTATTENTION,CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
		CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,DIVISIONATTENTION,
		DIVADDRESSLINE1,DIVADDRESSLINE2,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
		FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
		INVOICEEATTENTION,INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
		INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE,IPRURN,ACKNOWLEDGED)
	Select 
	        CASEID,SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,FILENUMBER,
		CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,PARENTDATE,NEXTTAXDATE,
		NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,APPLICATIONDATE,ACCEPTANCEDATE,
		PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,EXPIRYDATE,CPASTARTPAYDATE,
		CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,
		PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,
		NUMBEROFCLASSES,NUMBEROFSTATES,DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,
		OWNADDRESSLINE3,OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
		CLIENTATTENTION,CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
		CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,DIVISIONATTENTION,
		DIVADDRESSLINE1,DIVADDRESSLINE2,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
		FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
		INVOICEEATTENTION,INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
		INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE,IPRURN,ACKNOWLEDGED
	from CPARECEIVE R
	where CASEID=@pnCaseId
	and BATCHNO=@pnBatchNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo	int,
				  @pnCaseId	int',
				  @pnBatchNo=@pnBatchNo,
				  @pnCaseId =@pnCaseId

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Insert into #TEMPCPASEND
		       (CASEID,SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,FILENUMBER,
			CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,PARENTDATE,NEXTTAXDATE,
			NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,APPLICATIONDATE,ACCEPTANCEDATE,
			PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,EXPIRYDATE,CPASTARTPAYDATE,
			CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,
			PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,
			NUMBEROFCLASSES,NUMBEROFSTATES,DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,
			OWNADDRESSLINE3,OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
			CLIENTATTENTION,CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
			CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,DIVISIONATTENTION,
			DIVADDRESSLINE1,DIVADDRESSLINE2,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
			FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
			INVOICEEATTENTION,INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
			INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE,IPRURN,ACKNOWLEDGED)
		Select
		        CASEID,SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,FILENUMBER,
			CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,PARENTDATE,NEXTTAXDATE,
			NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,APPLICATIONDATE,ACCEPTANCEDATE,
			PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,EXPIRYDATE,CPASTARTPAYDATE,
			CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,
			PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,
			NUMBEROFCLASSES,NUMBEROFSTATES,DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,
			OWNADDRESSLINE3,OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
			CLIENTATTENTION,CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
			CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,DIVISIONATTENTION,
			DIVADDRESSLINE1,DIVADDRESSLINE2,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
			FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
			INVOICEEATTENTION,INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
			INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE,IPRURN,ACKNOWLEDGED
		from CPASEND
		where CASEID=@pnCaseId
		and BATCHNO=@pnBatchNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int,
					  @pnCaseId	int',
					  @pnBatchNo=@pnBatchNo,
					  @pnCaseId =@pnCaseId
	End

	if @ErrorCode=0
	Begin
		-- Return a result set of flags indicating the columns that have mismatched

		Exec("
		select
		0, S.CASEID,
		CASE WHEN(P.PROPERTYTYPE      =1 AND (S.PROPERTYTYPE      <>R.PROPERTYTYPE       or (S.PROPERTYTYPE       is not null and R.PROPERTYTYPE       is null) or (S.PROPERTYTYPE       is null and R.PROPERTYTYPE       is not null))) THEN 1 END as PROPERTYTYPEFLAG,
		CASE WHEN(P.ALTOFFICECODE     =1 AND (S.ALTOFFICECODE     <>R.ALTOFFICECODE      or (S.ALTOFFICECODE      is not null and R.ALTOFFICECODE      is null) or (S.ALTOFFICECODE      is null and R.ALTOFFICECODE      is not null))) THEN 1 END as ALTOFFICECODEFLAG,
		CASE WHEN(P.FILENUMBER        =1 AND (S.FILENUMBER        <>R.FILENUMBER         or (S.FILENUMBER         is not null and R.FILENUMBER         is null) or (S.FILENUMBER         is null and R.FILENUMBER         is not null))) THEN 1 END as FILENUMBERFLAG,
		CASE WHEN(P.CLIENTSREFERENCE  =1 AND (dbo.fn_RemoveNoiseCharacters(S.CLIENTSREFERENCE)<>dbo.fn_RemoveNoiseCharacters(R.CLIENTSREFERENCE)    )AND S.CLIENTSREFERENCE not like '%'+R.CLIENTSREFERENCE+'%') THEN 1 END as CLIENTSREFERENCEFLAG,
		CASE WHEN(P.CPACOUNTRYCODE    =1 AND (S.CPACOUNTRYCODE    <>R.CPACOUNTRYCODE     or (S.CPACOUNTRYCODE     is not null and R.CPACOUNTRYCODE     is null) or (S.CPACOUNTRYCODE     is null and R.CPACOUNTRYCODE     is not null))) THEN 1 END as CPACOUNTRYCODEFLAG,
		CASE WHEN(P.RENEWALTYPECODE   =1 AND (S.RENEWALTYPECODE   <>R.RENEWALTYPECODE    or (S.RENEWALTYPECODE    is not null and R.RENEWALTYPECODE    is null) or (S.RENEWALTYPECODE    is null and R.RENEWALTYPECODE    is not null))) THEN 1 END as RENEWALTYPECODEFLAG,
		CASE WHEN(P.MARK              =1 AND (upper(S.MARK)       <>upper(R.MARK)        or (S.MARK               is not null and R.MARK               is null) or (S.MARK               is null and R.MARK               is not null))) THEN 1 END as MARKFLAG,
		CASE WHEN(P.ENTITYSIZE        =1 AND (S.ENTITYSIZE        <>R.ENTITYSIZE         or (S.ENTITYSIZE         is not null and R.ENTITYSIZE         is null) or (S.ENTITYSIZE         is null and R.ENTITYSIZE         is not null))) THEN 1 END as ENTITYSIZEFLAG,
		-- Do not compare if no PriorityDate was sent
		CASE WHEN(P.PRIORITYDATE      =1 AND (S.PRIORITYDATE      <>R.PRIORITYDATE       or (S.PRIORITYDATE       is not null and R.PRIORITYDATE       is null)                                                                       )) THEN 1 END as PRIORITYDATEFLAG,
		CASE WHEN(P.PARENTDATE        =1 AND (S.PARENTDATE        <>R.PARENTDATE         or (S.PARENTDATE         is not null and R.PARENTDATE         is null) or (S.PARENTDATE         is null and R.PARENTDATE         is not null))) THEN 1 END as PARENTDATEFLAG,
		CASE WHEN(P.NEXTTAXDATE       =1 AND (S.NEXTTAXDATE       <>R.NEXTTAXDATE        or (S.NEXTTAXDATE        is not null and R.NEXTTAXDATE        is null) or (S.NEXTTAXDATE        is null and R.NEXTTAXDATE        is not null))) THEN 1 END as NEXTTAXDATEFLAG,
		CASE WHEN(P.NEXTDECOFUSEDATE  =1 AND (S.NEXTDECOFUSEDATE  <>R.NEXTDECOFUSEDATE   or (S.NEXTDECOFUSEDATE   is not null and R.NEXTDECOFUSEDATE   is null) or (S.NEXTDECOFUSEDATE   is null and R.NEXTDECOFUSEDATE   is not null))) THEN 1 END as NEXTDECOFUSEDATE,
		CASE WHEN(P.PCTFILINGDATE     =1 AND (S.PCTFILINGDATE     <>R.PCTFILINGDATE      or (S.PCTFILINGDATE      is not null and R.PCTFILINGDATE      is null) or (S.PCTFILINGDATE      is null and R.PCTFILINGDATE      is not null))) THEN 1 END as PCTFILINGDATEFLAG,
		CASE WHEN(P.ASSOCDESIGNDATE   =1 AND (S.ASSOCDESIGNDATE   <>R.ASSOCDESIGNDATE    or (S.ASSOCDESIGNDATE    is not null and R.ASSOCDESIGNDATE    is null) or (S.ASSOCDESIGNDATE    is null and R.ASSOCDESIGNDATE    is not null))) THEN 1 END as ASSOCDESIGNDATEFLAG,
		CASE WHEN(P.NEXTAFFIDAVITDATE =1 AND (S.NEXTAFFIDAVITDATE <>R.NEXTAFFIDAVITDATE  or (S.NEXTAFFIDAVITDATE  is not null and R.NEXTAFFIDAVITDATE  is null) or (S.NEXTAFFIDAVITDATE  is null and R.NEXTAFFIDAVITDATE  is not null))) THEN 1 END as NEXTAFFIDAVITDATEFLAG,
		CASE WHEN(P.APPLICATIONDATE   =1 AND (S.APPLICATIONDATE   <>R.APPLICATIONDATE    or (S.APPLICATIONDATE    is not null and R.APPLICATIONDATE    is null) or (S.APPLICATIONDATE    is null and R.APPLICATIONDATE    is not null))) THEN 1 END as APPLICATIONDATEFLAG,
		CASE WHEN(P.ACCEPTANCEDATE    =1 AND (S.ACCEPTANCEDATE    <>R.ACCEPTANCEDATE     or (S.ACCEPTANCEDATE     is not null and R.ACCEPTANCEDATE     is null) or (S.ACCEPTANCEDATE     is null and R.ACCEPTANCEDATE     is not null))) THEN 1 END as ACCEPTANCEDATE,
		CASE WHEN(P.PUBLICATIONDATE   =1 AND (S.PUBLICATIONDATE   <>R.PUBLICATIONDATE    or (S.PUBLICATIONDATE    is not null and R.PUBLICATIONDATE    is null) or (S.PUBLICATIONDATE    is null and R.PUBLICATIONDATE    is not null))) THEN 1 END as PUBLICATIONDATEFLAG,
		CASE WHEN(P.REGISTRATIONDATE  =1 AND (S.REGISTRATIONDATE  <>R.REGISTRATIONDATE   or (S.REGISTRATIONDATE   is not null and R.REGISTRATIONDATE   is null) or (S.REGISTRATIONDATE   is null and R.REGISTRATIONDATE   is not null))) THEN 1 END as REGISTRATIONDATEFLAG,
		-- Do not compare if no RenewalDate was sent
		CASE WHEN(P.RENEWALDATE       =1 AND (S.RENEWALDATE       <>R.RENEWALDATE        or (S.RENEWALDATE        is not null and R.RENEWALDATE        is null)                                                                       )) THEN 1 END as RENEWALDATEFLAG,
		CASE WHEN(P.NOMINALWORKINGDATE=1 AND (S.NOMINALWORKINGDATE<>R.NOMINALWORKINGDATE or (S.NOMINALWORKINGDATE is not null and R.NOMINALWORKINGDATE is null) or (S.NOMINALWORKINGDATE is null and R.NOMINALWORKINGDATE is not null))) THEN 1 END as NOMINALWORKINGDATE,
		CASE WHEN(P.EXPIRYDATE        =1 AND (S.EXPIRYDATE        <>R.EXPIRYDATE         or (S.EXPIRYDATE         is not null and R.EXPIRYDATE         is null) or (S.EXPIRYDATE         is null and R.EXPIRYDATE         is not null))) THEN 1 END as EXPIRYDATEFLAG,
		CASE WHEN(P.CPASTARTPAYDATE   =1 AND (S.CPASTARTPAYDATE   <>R.CPASTARTPAYDATE    or (S.CPASTARTPAYDATE    is not null and R.CPASTARTPAYDATE    is null) ))                                                                       THEN 1 END as CPASTARTPAYDATEFLAG,
		CASE WHEN(P.CPASTOPPAYDATE    =1 AND (S.CPASTOPPAYDATE    <>R.CPASTOPPAYDATE     or (S.CPASTOPPAYDATE     is not null and R.CPASTOPPAYDATE     is null) or (S.CPASTOPPAYDATE     is null and R.CPASTOPPAYDATE     is not null))) THEN 1 END as CPASTOPPAYDATEFLAG,
		CASE WHEN(P.STOPPAYINGREASON  =1 AND (S.STOPPAYINGREASON  <>R.STOPPAYINGREASON   or (S.STOPPAYINGREASON   is not null and R.STOPPAYINGREASON   is null) or (S.STOPPAYINGREASON   is null and R.STOPPAYINGREASON   is not null))) THEN 1 END as STOPPAYINGREASONFLAG,
	
		CASE WHEN(P.PRIORITYNO        =1 AND (dbo.fn_RemoveNoiseCharacters(S.PRIORITYNO    )<>dbo.fn_RemoveNoiseCharacters(R.PRIORITYNO    ) or (S.PRIORITYNO         is not null and R.PRIORITYNO         is null) or (S.PRIORITYNO         is null and R.PRIORITYNO         is not null))) THEN 1 END as PRIORITYNOFLAG,
		CASE WHEN(P.PARENTNO          =1 AND (dbo.fn_RemoveNoiseCharacters(S.PARENTNO      )<>dbo.fn_RemoveNoiseCharacters(R.PARENTNO      ) or (S.PARENTNO           is not null and R.PARENTNO           is null) or (S.PARENTNO           is null and R.PARENTNO           is not null))) THEN 1 END as PARENTNOFLAG,
		CASE WHEN(P.PCTFILINGNO       =1 AND (dbo.fn_RemoveNoiseCharacters(S.PCTFILINGNO   )<>dbo.fn_RemoveNoiseCharacters(R.PCTFILINGNO   ) or (S.PCTFILINGNO        is not null and R.PCTFILINGNO        is null) or (S.PCTFILINGNO        is null and R.PCTFILINGNO        is not null))) THEN 1 END as PCTFILINGNOFLAG,
		CASE WHEN(P.ASSOCDESIGNNO     =1 AND (dbo.fn_RemoveNoiseCharacters(S.ASSOCDESIGNNO )<>dbo.fn_RemoveNoiseCharacters(R.ASSOCDESIGNNO ) or (S.ASSOCDESIGNNO      is not null and R.ASSOCDESIGNNO      is null) or (S.ASSOCDESIGNNO      is null and R.ASSOCDESIGNNO      is not null))) THEN 1 END as ASSOCDESIGNNOFLAG,
		CASE WHEN(P.APPLICATIONNO     =1 AND (dbo.fn_RemoveNoiseCharacters(S.APPLICATIONNO )<>dbo.fn_RemoveNoiseCharacters(R.APPLICATIONNO ) or (S.APPLICATIONNO      is not null and R.APPLICATIONNO      is null) or (S.APPLICATIONNO      is null and R.APPLICATIONNO      is not null))) THEN 1 END as APPLICATIONNOFLAG,
		CASE WHEN(P.ACCEPTANCENO      =1 AND (dbo.fn_RemoveNoiseCharacters(S.ACCEPTANCENO  )<>dbo.fn_RemoveNoiseCharacters(R.ACCEPTANCENO  ) or (S.ACCEPTANCENO       is not null and R.ACCEPTANCENO       is null) or (S.ACCEPTANCENO       is null and R.ACCEPTANCENO       is not null))) THEN 1 END as ACCEPTANCENOFLAG,
		CASE WHEN(P.PUBLICATIONNO     =1 AND (dbo.fn_RemoveNoiseCharacters(S.PUBLICATIONNO )<>dbo.fn_RemoveNoiseCharacters(R.PUBLICATIONNO ) or (S.PUBLICATIONNO      is not null and R.PUBLICATIONNO      is null) or (S.PUBLICATIONNO      is null and R.PUBLICATIONNO      is not null))) THEN 1 END as PUBLICATIONNOFLAG,
		CASE WHEN(P.REGISTRATIONNO    =1 AND (dbo.fn_RemoveNoiseCharacters(S.REGISTRATIONNO)<>dbo.fn_RemoveNoiseCharacters(R.REGISTRATIONNO) or (S.REGISTRATIONNO     is not null and R.REGISTRATIONNO     is null) or (S.REGISTRATIONNO     is null and R.REGISTRATIONNO     is not null))) THEN 1 END as REGISTRATIONNO,
	
		CASE WHEN(P.INTLCLASSES       =1 AND (S.INTLCLASSES       <>R.INTLCLASSES        or (S.INTLCLASSES        is not null and R.INTLCLASSES        is null) or (S.INTLCLASSES        is null and R.INTLCLASSES        is not null))) THEN 1 END as INTLCLASSESFLAG,
		CASE WHEN(P.LOCALCLASSES      =1 AND (S.LOCALCLASSES      <>R.LOCALCLASSES       or (S.LOCALCLASSES       is not null and R.LOCALCLASSES       is null and (S.LOCALCLASSES<>S.INTLCLASSES OR S.INTLCLASSES is null)) or (S.LOCALCLASSES       is null and R.LOCALCLASSES       is not null))) THEN 1 END as LOCALCLASSESFLAG,
	
		CASE WHEN(P.NUMBEROFYEARS     =1 AND (isnull(S.NUMBEROFYEARS,0)  <>R.NUMBEROFYEARS      or (S.NUMBEROFYEARS      is not null and R.NUMBEROFYEARS      is null))) THEN 1 END as NUMBEROFYEARSFLAG,
		CASE WHEN(P.NUMBEROFCLAIMS    =1 AND (isnull(S.NUMBEROFCLAIMS,0) <>R.NUMBEROFCLAIMS     or (S.NUMBEROFCLAIMS     is not null and R.NUMBEROFCLAIMS     is null))) THEN 1 END as NUMBEROFCLAIMSFLAG,
		CASE WHEN(P.NUMBEROFDESIGNS   =1 AND (isnull(S.NUMBEROFDESIGNS,0)<>R.NUMBEROFDESIGNS    or (S.NUMBEROFDESIGNS    is not null and R.NUMBEROFDESIGNS    is null))) THEN 1 END as NUMBEROFDESIGNSFLAG,
		CASE WHEN(P.NUMBEROFCLASSES   =1 AND (isnull(S.NUMBEROFCLASSES,0)<>R.NUMBEROFCLASSES    or (S.NUMBEROFCLASSES    is not null and R.NUMBEROFCLASSES    is null))) THEN 1 END as NUMBEROFCLASSESFLAG,
		CASE WHEN(P.NUMBEROFSTATES    =1 AND (isnull(S.NUMBEROFSTATES,0) <>R.NUMBEROFSTATES     or (S.NUMBEROFSTATES     is not null and R.NUMBEROFSTATES     is null))) THEN 1 END as NUMBEROFSTATESFLAG,
	
		CASE WHEN(P.DESIGNATEDSTATES  =1 AND (S.DESIGNATEDSTATES  <>R.DESIGNATEDSTATES   or (S.DESIGNATEDSTATES   is not null and R.DESIGNATEDSTATES   is null) or (S.DESIGNATEDSTATES   is null and R.DESIGNATEDSTATES   is not null))) THEN 1 END as DESIGNATEDSTATESFLAG,
		CASE WHEN(P.OWNERNAME         =1 AND (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.OWNERNAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.OWNERNAME)),8) or (S.OWNERNAME          is not null and R.OWNERNAME          is null) or (S.OWNERNAME          is null and R.OWNERNAME          is not null))) THEN 1 END as OWNERNAMEFLAG,
		CASE WHEN(P.OWNERNAMECODE     =1 AND (S.OWNERNAMECODE     <>R.OWNERNAMECODE      or (S.OWNERNAMECODE      is not null and R.OWNERNAMECODE      is null) or (S.OWNERNAMECODE      is null and R.OWNERNAMECODE      is not null))) THEN 1 END as OWNERNAMECODEFLAG,
	
		CASE WHEN(P.OWNADDRESSLINE1   =1 AND (replace(S.OWNADDRESSLINE1,' ','')<>replace(R.OWNADDRESSLINE1,' ','') or (S.OWNADDRESSLINE1    is not null and R.OWNADDRESSLINE1    is null) or (S.OWNADDRESSLINE1    is null and R.OWNADDRESSLINE1    is not null))) THEN 1 END as OWNADDRESSLINE1FLAG,
		CASE WHEN(P.OWNADDRESSLINE2   =1 AND (replace(S.OWNADDRESSLINE2,' ','')<>replace(R.OWNADDRESSLINE2,' ','') or (S.OWNADDRESSLINE2    is not null and R.OWNADDRESSLINE2    is null) or (S.OWNADDRESSLINE2    is null and R.OWNADDRESSLINE2    is not null))) THEN 1 END as OWNADDRESSLINE2FLAG,
		CASE WHEN(P.OWNADDRESSLINE3   =1 AND (replace(S.OWNADDRESSLINE3,' ','')<>replace(R.OWNADDRESSLINE3,' ','') or (S.OWNADDRESSLINE3    is not null and R.OWNADDRESSLINE3    is null) or (S.OWNADDRESSLINE3    is null and R.OWNADDRESSLINE3    is not null))) THEN 1 END as OWNADDRESSLINE3FLAG,
		CASE WHEN(P.OWNADDRESSLINE4   =1 AND (replace(S.OWNADDRESSLINE4,' ','')<>replace(R.OWNADDRESSLINE4,' ','') or (S.OWNADDRESSLINE4    is not null and R.OWNADDRESSLINE4    is null) or (S.OWNADDRESSLINE4    is null and R.OWNADDRESSLINE4    is not null))) THEN 1 END as OWNADDRESSLINE4FLAG,
	
		CASE WHEN(P.OWNADDRESSCOUNTRY =1 AND (S.OWNADDRESSCOUNTRY <>R.OWNADDRESSCOUNTRY  or (S.OWNADDRESSCOUNTRY  is not null and R.OWNADDRESSCOUNTRY  is null) or (S.OWNADDRESSCOUNTRY  is null and R.OWNADDRESSCOUNTRY  is not null))) THEN 1 END as OWNADDRESSCOUNTRYFLAG,
		CASE WHEN(P.OWNADDRESSPOSTCODE=1 AND (S.OWNADDRESSPOSTCODE<>R.OWNADDRESSPOSTCODE or (S.OWNADDRESSPOSTCODE is not null and R.OWNADDRESSPOSTCODE is null) or (S.OWNADDRESSPOSTCODE is null and R.OWNADDRESSPOSTCODE is not null))) THEN 1 END as OWNADDRESSPOSTCODEFLAG,
		CASE WHEN(P.CLIENTCODE        =1 AND (S.CLIENTCODE        <>R.CLIENTCODE         or (S.CLIENTCODE         is not null and R.CLIENTCODE         is null) or (S.CLIENTCODE         is null and R.CLIENTCODE         is not null))) THEN 1 END as CLIENTCODEFLAG,
		CASE WHEN(P.CPACLIENTNO       =1 AND (isnull(S.CPACLIENTNO,0)<>R.CPACLIENTNO        or (S.CPACLIENTNO        is not null and R.CPACLIENTNO        is null))) THEN 1 END as CPACLIENTNOFLAG,
		CASE WHEN(P.CLIENTNAME        =1 AND (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.CLIENTNAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.CLIENTNAME)),8) or (S.CLIENTNAME         is not null and R.CLIENTNAME         is null) or (S.CLIENTNAME         is null and R.CLIENTNAME         is not null))) THEN 1 END as CLIENTNAMEFLAG,
		CASE WHEN(P.CLIENTATTENTION   =1 and S.CLIENTATTENTION    is not null and R.CLIENTATTENTION not like '%Dear Sir%' and Charindex(replace(S.CLIENTATTENTION,  ' ',''), replace(R.CLIENTATTENTION+R.CLTADDRESSLINE1+R.CLTADDRESSLINE2,' ',''))=0) THEN 1 END as CLIENTATTENTIONFLAG,
	
		CASE WHEN(P.CLTADDRESSLINE1   =1 and S.CLTADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0) THEN 1 END as CLTADDRESSLINE1FLAG,
		CASE WHEN(P.CLTADDRESSLINE2   =1 and S.CLTADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0) THEN 1 END as CLTADDRESSLINE2FLAG,
		CASE WHEN(P.CLTADDRESSLINE3   =1 and S.CLTADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0) THEN 1 END as CLTADDRESSLINE3FLAG,
		CASE WHEN(P.CLTADDRESSLINE4   =1 and S.CLTADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0) THEN 1 END as CLTADDRESSLINE4FLAG,
		CASE WHEN(P.CLTADDRESSCOUNTRY =1 and S.CLTADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C1.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C1.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0) THEN 1 END as CLTADDRESSCOUNTRYFLAG,
		CASE WHEN(P.CLTADDRESSPOSTCODE=1 and S.CLTADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY+R.CLTADDRESSPOSTCODE))=0) THEN 1 END as CLTADDRESSPOSTCODEFLAG,

			-- Telephone/Fax matches if the last 6 digits sent appears anywhere in the received data after stripping out spaces, +, - and brackets
		CASE WHEN(P.CLIENTTELEPHONE   =1 AND S.CLIENTTELEPHONE    is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.CLIENTTELEPHONE)),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.CLIENTTELEPHONE)))=0) THEN 1 END as CLIENTTELEPHONEFLAG,
		CASE WHEN(P.CLIENTFAX         =1 AND S.CLIENTFAX          is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.CLIENTFAX      )),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.CLIENTFAX      )))=0) THEN 1 END as CLIENTFAXFLAG,
		CASE WHEN(P.CLIENTEMAIL       =1 AND (S.CLIENTEMAIL       <>R.CLIENTEMAIL        or (S.CLIENTEMAIL        is not null and R.CLIENTEMAIL        is null) or (S.CLIENTEMAIL        is null and R.CLIENTEMAIL        is not null))) THEN 1 END as CLIENTEMAILFLAG,
		CASE WHEN(P.DIVISIONCODE      =1 AND (S.DIVISIONCODE      <>R.DIVISIONCODE       or (S.DIVISIONCODE       is not null and R.DIVISIONCODE       is null) or (S.DIVISIONCODE       is null and R.DIVISIONCODE       is not null))) THEN 1 END as DIVISIONCODEFLAG,
		CASE WHEN(P.DIVISIONNAME      =1 AND (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.DIVISIONNAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.DIVISIONNAME)),8) or (S.DIVISIONNAME       is not null and R.DIVISIONNAME       is null) or (S.DIVISIONNAME       is null and R.DIVISIONNAME       is not null))) THEN 1 END as DIVISIONNAMEFLAG,
		CASE WHEN(P.DIVISIONATTENTION =1 AND S.DIVISIONATTENTION  is not null and R.DIVISIONATTENTION not like '%Dear Sir%' and Charindex(replace(S.DIVISIONATTENTION,  ' ',''), replace(R.DIVISIONATTENTION+R.DIVADDRESSLINE1+R.DIVADDRESSLINE2,' ',''))=0) THEN 1 END as DIVISIONATTENTIONFLAG,
	
		CASE WHEN(P.DIVADDRESSLINE1   =1 and S.DIVADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0) THEN 1 END as DIVADDRESSLINE1FLAG,
		CASE WHEN(P.DIVADDRESSLINE2   =1 and S.DIVADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0) THEN 1 END as DIVADDRESSLINE2FLAG,
		CASE WHEN(P.DIVADDRESSLINE3   =1 and S.DIVADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0) THEN 1 END as DIVADDRESSLINE3FLAG,
		CASE WHEN(P.DIVADDRESSLINE4   =1 and S.DIVADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0) THEN 1 END as DIVADDRESSLINE4FLAG,
		CASE WHEN(P.DIVADDRESSCOUNTRY =1 and S.DIVADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0  AND Charindex(dbo.fn_RemoveNoiseCharacters(C2.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C2.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0) THEN 1 END as DIVADDRESSCOUNTRYFLAG,
		CASE WHEN(P.DIVADDRESSPOSTCODE=1 and S.DIVADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY+R.DIVADDRESSPOSTCODE))=0) THEN 1 END as DIVADDRESSPOSTCODEFLAG,
	
		CASE WHEN(P.FOREIGNAGENTCODE  =1 AND (S.FOREIGNAGENTCODE  <>R.FOREIGNAGENTCODE   or (S.FOREIGNAGENTCODE   is not null and R.FOREIGNAGENTCODE   is null) or (S.FOREIGNAGENTCODE   is null and R.FOREIGNAGENTCODE   is not null))) THEN 1 END as FOREIGNAGENTCODEFLAG,
		CASE WHEN(P.FOREIGNAGENTNAME  =1 AND (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.FOREIGNAGENTNAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.FOREIGNAGENTNAME)),8) or (S.FOREIGNAGENTNAME   is not null and R.FOREIGNAGENTNAME   is null) or (S.FOREIGNAGENTNAME   is null and R.FOREIGNAGENTNAME   is not null))) THEN 1 END as FOREIGNAGENTNAMEFLAG,
		CASE WHEN(P.ATTORNEYCODE      =1 AND (S.ATTORNEYCODE      <>R.ATTORNEYCODE       or (S.ATTORNEYCODE       is not null and R.ATTORNEYCODE       is null) or (S.ATTORNEYCODE       is null and R.ATTORNEYCODE       is not null))) THEN 1 END as ATTORNEYCODEFLAG,
		CASE WHEN(P.ATTORNEYNAME      =1 AND (Left(dbo.fn_RemoveNoiseCharacters(S.ATTORNEYNAME),8)<>Left(dbo.fn_RemoveNoiseCharacters(R.ATTORNEYNAME),8) or (S.ATTORNEYNAME       is not null and R.ATTORNEYNAME       is null) or (S.ATTORNEYNAME       is null and R.ATTORNEYNAME       is not null))) THEN 1 END as ATTORNEYNAMEFLAG,
		CASE WHEN(P.INVOICEECODE      =1 AND (S.INVOICEECODE      <>R.INVOICEECODE       or (S.INVOICEECODE       is not null and R.INVOICEECODE       is null) or (S.INVOICEECODE       is null and R.INVOICEECODE       is not null))) THEN 1 END as INVOICEECODEFLAG,
		CASE WHEN(P.CPAINVOICEENO     =1 AND (isnull(S.CPAINVOICEENO,0)<>R.CPAINVOICEENO or (S.CPAINVOICEENO      is not null and R.CPAINVOICEENO is null))) THEN 1 END as CPAINVOICEENOFLAG,
		CASE WHEN(P.INVOICEENAME      =1 AND (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.INVOICEENAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.INVOICEENAME)),8) or (S.INVOICEENAME       is not null and R.INVOICEENAME       is null) or (S.INVOICEENAME       is null and R.INVOICEENAME       is not null))) THEN 1 END as INVOICEENAMEFLAG,
		CASE WHEN(P.INVOICEEATTENTION =1 AND S.INVOICEEATTENTION  is not null and R.INVOICEEATTENTION not like '%Dear Sir%' and Charindex(replace(S.INVOICEEATTENTION,  ' ',''), replace(R.INVOICEEATTENTION+R.INVADDRESSLINE1+R.INVADDRESSLINE2,' ',''))=0) THEN 1 END as INVOICEEATTENTIONFLAG,
	
		CASE WHEN(P.INVADDRESSLINE1   =1 and S.INVADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0) THEN 1 END as INVADDRESSLINE1FLAG,
		CASE WHEN(P.INVADDRESSLINE2   =1 and S.INVADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0) THEN 1 END as INVADDRESSLINE2FLAG,
		CASE WHEN(P.INVADDRESSLINE3   =1 and S.INVADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0) THEN 1 END as INVADDRESSLINE3FLAG,
		CASE WHEN(P.INVADDRESSLINE4   =1 and S.INVADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0) THEN 1 END as INVADDRESSLINE4FLAG,
		CASE WHEN(P.INVADDRESSCOUNTRY =1 and S.INVADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0  AND Charindex(dbo.fn_RemoveNoiseCharacters(C3.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C3.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0) THEN 1 END as INVADDRESSCOUNTRYFLAG,
		CASE WHEN(P.INVADDRESSPOSTCODE=1 and S.INVADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY+R.INVADDRESSPOSTCODE))=0) THEN 1 END as INVADDRESSPOSTCODEFLAG,

		CASE WHEN(P.INVOICEETELEPHONE =1 AND S.INVOICEETELEPHONE  is not null and Charindex(substring(reverse(replace(replace(replace(replace(replace(S.INVOICEETELEPHONE,'-',''),' ',''),'+',''),'(',''),')','')),1,6),reverse(replace(replace(replace(replace(replace(R.INVOICEETELEPHONE,'-',''),' ',''),'+',''),'(',''),')','')))=0) THEN 1 END as INVOICEETELEPHONEFLAG,
		CASE WHEN(P.INVOICEEFAX       =1 AND S.INVOICEEFAX        is not null and Charindex(substring(reverse(replace(replace(replace(replace(replace(S.INVOICEEFAX      ,'-',''),' ',''),'+',''),'(',''),')','')),1,6),reverse(replace(replace(replace(replace(replace(R.INVOICEEFAX      ,'-',''),' ',''),'+',''),'(',''),')','')))=0) THEN 1 END as INVOICEEFAXFLAG,
		CASE WHEN(P.INVOICEEEMAIL     =1 AND (S.INVOICEEEMAIL    <>R.INVOICEEEMAIL      or (S.INVOICEEEMAIL      is not null and R.INVOICEEEMAIL      is null) or (S.INVOICEEEMAIL      is null and R.INVOICEEEMAIL      is not null))) THEN 1 END as INVOICEEEMAILFLAG
		from #TEMPCPARECEIVE R
		join #TEMPCPASEND S	on (S.CASEID=R.CASEID)
		join CASES C		on (C.CASEID=R.CASEID)
		join CPACOMPARE P	on (P.PROPERTYTYPEKEY=CASE C.PROPERTYTYPE WHEN 'T' THEN 'T'
										  WHEN 'D' THEN 'D'
										           ELSE 'P'
							      END)
		left join COUNTRY C1	on (C1.COUNTRY=R.CLTADDRESSCOUNTRY)
		left join COUNTRY C2	on (C2.COUNTRY=R.DIVADDRESSCOUNTRY)
		left join COUNTRY C3	on (C3.COUNTRY=R.INVADDRESSCOUNTRY)")

		Select 	@ErrorCode=@@Error
	End
End

-- If only a list of rejected cases is required then do not bother returning
-- details of the specific column mismatches as this has performance implications.
-- Compare data for an entire batch where a reject list is required

If  @ErrorCode=0
and @pbUpdateRejectList=1
begin
	insert into #TEMPREJECTEDCASES (CASEID,REJECTFLAG)
	select S.CASEID,1
	from CPARECEIVE R
	join CPASEND S		on (S.CASEID =R.CASEID 
				and S.BATCHNO=R.BATCHNO)
	join CASES C		on (C.CASEID=S.CASEID)
	join CPACOMPARE P	on (P.PROPERTYTYPEKEY=CASE C.PROPERTYTYPE WHEN 'T' THEN 'T'
									  WHEN 'D' THEN 'D'
									           ELSE 'P'
						      END)
	left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
	left join COUNTRY C1	on (C1.COUNTRY=R.CLTADDRESSCOUNTRY)
	left join COUNTRY C2	on (C2.COUNTRY=R.DIVADDRESSCOUNTRY)
	left join COUNTRY C3	on (C3.COUNTRY=R.INVADDRESSCOUNTRY)
	where	 R.BATCHNO = @pnBatchNo
	and	 isnull(S.ACKNOWLEDGED,0)=0
	and	 isnull(@pnCaseId,S.CASEID)=S.CASEID
	and	(O.CPACODE=@psOfficeCPACode OR @psOfficeCPACode is null)
	and 	(R.NARRATIVE=@psCPANarrative  OR @psCPANarrative   is null)
	and    ((C.PROPERTYTYPE<>@psPropertyType and @pbNotProperty=1) OR (C.PROPERTYTYPE=@psPropertyType and @pbNotProperty=0) OR (C.PROPERTYTYPE=@psPropertyType and @pbNotProperty is null) OR @psPropertyType is NULL) 
	and    ((P.PROPERTYTYPE      =1 and (S.PROPERTYTYPE      <>R.PROPERTYTYPE       or (S.PROPERTYTYPE       is not null and R.PROPERTYTYPE       is null) or (S.PROPERTYTYPE       is null and R.PROPERTYTYPE       is not null)))
	or	(P.ALTOFFICECODE     =1 and (S.ALTOFFICECODE     <>R.ALTOFFICECODE      or (S.ALTOFFICECODE      is not null and R.ALTOFFICECODE      is null) or (S.ALTOFFICECODE      is null and R.ALTOFFICECODE      is not null)))
	or	(P.FILENUMBER        =1 and (S.FILENUMBER        <>R.FILENUMBER         or (S.FILENUMBER         is not null and R.FILENUMBER         is null) or (S.FILENUMBER         is null and R.FILENUMBER         is not null)))
	or	(P.CLIENTSREFERENCE  =1 and (dbo.fn_RemoveNoiseCharacters(S.CLIENTSREFERENCE)<>dbo.fn_RemoveNoiseCharacters(R.CLIENTSREFERENCE)) AND S.CLIENTSREFERENCE not like '%'+R.CLIENTSREFERENCE+'%')
	or	(P.CPACOUNTRYCODE    =1 and (S.CPACOUNTRYCODE    <>R.CPACOUNTRYCODE     or (S.CPACOUNTRYCODE     is not null and R.CPACOUNTRYCODE     is null) or (S.CPACOUNTRYCODE     is null and R.CPACOUNTRYCODE     is not null)))
	or	(P.RENEWALTYPECODE   =1 and (S.RENEWALTYPECODE   <>R.RENEWALTYPECODE    or (S.RENEWALTYPECODE    is not null and R.RENEWALTYPECODE    is null) or (S.RENEWALTYPECODE    is null and R.RENEWALTYPECODE    is not null)))
	or	(P.MARK              =1 and (upper(S.MARK)       <>upper(R.MARK)        or (S.MARK               is not null and R.MARK               is null) or (S.MARK               is null and R.MARK               is not null)))
	or	(P.ENTITYSIZE        =1 and (S.ENTITYSIZE        <>R.ENTITYSIZE         or (S.ENTITYSIZE         is not null and R.ENTITYSIZE         is null) or (S.ENTITYSIZE         is null and R.ENTITYSIZE         is not null)))
		-- Do not compare Priority Date if no date was sent
	or	(P.PRIORITYDATE      =1 and (S.PRIORITYDATE      <>R.PRIORITYDATE       or (S.PRIORITYDATE       is not null and R.PRIORITYDATE       is null) ))
	or	(P.PARENTDATE        =1 and (S.PARENTDATE        <>R.PARENTDATE         or (S.PARENTDATE         is not null and R.PARENTDATE         is null) or (S.PARENTDATE         is null and R.PARENTDATE         is not null)))
	or	(P.NEXTTAXDATE       =1 and (S.NEXTTAXDATE       <>R.NEXTTAXDATE        or (S.NEXTTAXDATE        is not null and R.NEXTTAXDATE        is null) or (S.NEXTTAXDATE        is null and R.NEXTTAXDATE        is not null)))
	or	(P.NEXTDECOFUSEDATE  =1 and (S.NEXTDECOFUSEDATE  <>R.NEXTDECOFUSEDATE   or (S.NEXTDECOFUSEDATE   is not null and R.NEXTDECOFUSEDATE   is null) or (S.NEXTDECOFUSEDATE   is null and R.NEXTDECOFUSEDATE   is not null)))
	or	(P.PCTFILINGDATE     =1 and (S.PCTFILINGDATE     <>R.PCTFILINGDATE      or (S.PCTFILINGDATE      is not null and R.PCTFILINGDATE      is null) or (S.PCTFILINGDATE      is null and R.PCTFILINGDATE      is not null)))
	or	(P.ASSOCDESIGNDATE   =1 and (S.ASSOCDESIGNDATE   <>R.ASSOCDESIGNDATE    or (S.ASSOCDESIGNDATE    is not null and R.ASSOCDESIGNDATE    is null) or (S.ASSOCDESIGNDATE    is null and R.ASSOCDESIGNDATE    is not null)))
	or	(P.NEXTAFFIDAVITDATE =1 and (S.NEXTAFFIDAVITDATE <>R.NEXTAFFIDAVITDATE  or (S.NEXTAFFIDAVITDATE  is not null and R.NEXTAFFIDAVITDATE  is null) or (S.NEXTAFFIDAVITDATE  is null and R.NEXTAFFIDAVITDATE  is not null)))
	or	(P.APPLICATIONDATE   =1 and (S.APPLICATIONDATE   <>R.APPLICATIONDATE    or (S.APPLICATIONDATE    is not null and R.APPLICATIONDATE    is null) or (S.APPLICATIONDATE    is null and R.APPLICATIONDATE    is not null)))
	or	(P.ACCEPTANCEDATE    =1 and (S.ACCEPTANCEDATE    <>R.ACCEPTANCEDATE     or (S.ACCEPTANCEDATE     is not null and R.ACCEPTANCEDATE     is null) or (S.ACCEPTANCEDATE     is null and R.ACCEPTANCEDATE     is not null)))
	or	(P.PUBLICATIONDATE   =1 and (S.PUBLICATIONDATE   <>R.PUBLICATIONDATE    or (S.PUBLICATIONDATE    is not null and R.PUBLICATIONDATE    is null) or (S.PUBLICATIONDATE    is null and R.PUBLICATIONDATE    is not null)))
	or	(P.REGISTRATIONDATE  =1 and (S.REGISTRATIONDATE  <>R.REGISTRATIONDATE   or (S.REGISTRATIONDATE   is not null and R.REGISTRATIONDATE   is null) or (S.REGISTRATIONDATE   is null and R.REGISTRATIONDATE   is not null)))
		-- Do not compare Renewal Date if no date was sent
	or	(P.RENEWALDATE       =1 and (S.RENEWALDATE       <>R.RENEWALDATE        or (S.RENEWALDATE        is not null and R.RENEWALDATE        is null) ))
	or	(P.NOMINALWORKINGDATE=1 and (S.NOMINALWORKINGDATE<>R.NOMINALWORKINGDATE or (S.NOMINALWORKINGDATE is not null and R.NOMINALWORKINGDATE is null) or (S.NOMINALWORKINGDATE is null and R.NOMINALWORKINGDATE is not null)))
	or	(P.EXPIRYDATE        =1 and (S.EXPIRYDATE        <>R.EXPIRYDATE         or (S.EXPIRYDATE         is not null and R.EXPIRYDATE         is null) or (S.EXPIRYDATE         is null and R.EXPIRYDATE         is not null)))
	or	(P.CPASTARTPAYDATE   =1 and (S.CPASTARTPAYDATE   <>R.CPASTARTPAYDATE    or (S.CPASTARTPAYDATE    is not null and R.CPASTARTPAYDATE    is null)))
	or	(P.CPASTOPPAYDATE    =1 and (S.CPASTOPPAYDATE    <>R.CPASTOPPAYDATE     or (S.CPASTOPPAYDATE     is not null and R.CPASTOPPAYDATE     is null) or (S.CPASTOPPAYDATE     is null and R.CPASTOPPAYDATE     is not null)))
	or	(P.STOPPAYINGREASON  =1 and (S.STOPPAYINGREASON  <>R.STOPPAYINGREASON   or (S.STOPPAYINGREASON   is not null and R.STOPPAYINGREASON   is null) or (S.STOPPAYINGREASON   is null and R.STOPPAYINGREASON   is not null)))

	or	(P.PRIORITYNO        =1 and (dbo.fn_RemoveNoiseCharacters(S.PRIORITYNO   )<>dbo.fn_RemoveNoiseCharacters(R.PRIORITYNO   ) or (S.PRIORITYNO         is not null and R.PRIORITYNO         is null) or (S.PRIORITYNO         is null and R.PRIORITYNO         is not null)))
	or	(P.PARENTNO          =1 and (dbo.fn_RemoveNoiseCharacters(S.PARENTNO     )<>dbo.fn_RemoveNoiseCharacters(R.PARENTNO     ) or (S.PARENTNO           is not null and R.PARENTNO           is null) or (S.PARENTNO           is null and R.PARENTNO           is not null)))
	or	(P.PCTFILINGNO       =1 and (dbo.fn_RemoveNoiseCharacters(S.PCTFILINGNO  )<>dbo.fn_RemoveNoiseCharacters(R.PCTFILINGNO  ) or (S.PCTFILINGNO        is not null and R.PCTFILINGNO        is null) or (S.PCTFILINGNO        is null and R.PCTFILINGNO        is not null)))
	or	(P.ASSOCDESIGNNO     =1 and (dbo.fn_RemoveNoiseCharacters(S.ASSOCDESIGNNO)<>dbo.fn_RemoveNoiseCharacters(R.ASSOCDESIGNNO) or (S.ASSOCDESIGNNO      is not null and R.ASSOCDESIGNNO      is null) or (S.ASSOCDESIGNNO      is null and R.ASSOCDESIGNNO      is not null)))
	or	(P.ACCEPTANCENO      =1 and (dbo.fn_RemoveNoiseCharacters(S.ACCEPTANCENO )<>dbo.fn_RemoveNoiseCharacters(R.ACCEPTANCENO ) or (S.ACCEPTANCENO       is not null and R.ACCEPTANCENO       is null) or (S.ACCEPTANCENO       is null and R.ACCEPTANCENO       is not null)))
	or	(P.PUBLICATIONNO     =1 and (dbo.fn_RemoveNoiseCharacters(S.PUBLICATIONNO)<>dbo.fn_RemoveNoiseCharacters(R.PUBLICATIONNO) or (S.PUBLICATIONNO      is not null and R.PUBLICATIONNO      is null) or (S.PUBLICATIONNO      is null and R.PUBLICATIONNO      is not null)))

		-- If both the ApplicationNo and RegistrationNo are to be included in the matching process
		-- then both must fail the test for the row to be rejected
	or	((P.APPLICATIONNO    =1 and (dbo.fn_RemoveNoiseCharacters(S.APPLICATIONNO )<>dbo.fn_RemoveNoiseCharacters(R.APPLICATIONNO ) or (S.APPLICATIONNO      is not null and R.APPLICATIONNO      is null) or (S.APPLICATIONNO      is null and R.APPLICATIONNO      is not null)))
	and	 (P.REGISTRATIONNO   =1 and (dbo.fn_RemoveNoiseCharacters(S.REGISTRATIONNO)<>dbo.fn_RemoveNoiseCharacters(R.REGISTRATIONNO) or (S.REGISTRATIONNO     is not null and R.REGISTRATIONNO     is null) or (S.REGISTRATIONNO     is null and R.REGISTRATIONNO     is not null))))

		-- If the ApplicationNo  is being compared but not the RegistrationNo (or there is no RegistrationNo) then the match can fail just on the ApplicationNo
	or	(P.APPLICATIONNO     =1 and (P.REGISTRATIONNO=0 OR P.REGISTRATIONNO is null or R.REGISTRATIONNO is null) and (dbo.fn_RemoveNoiseCharacters(S.APPLICATIONNO)<>dbo.fn_RemoveNoiseCharacters(R.APPLICATIONNO) or (S.APPLICATIONNO  is not null and R.APPLICATIONNO  is null) or (S.APPLICATIONNO    is null and R.APPLICATIONNO  is not null)))

		-- If the RegistrationNo is being compared but not the ApplicationNo  (or there is no ApplicationNo)  then the match can fail just on the RegistrationNo
	or	(P.REGISTRATIONNO    =1 and (P.APPLICATIONNO=0 OR P.APPLICATIONNO   is null or R.APPLICATIONNO  is null) and (dbo.fn_RemoveNoiseCharacters(S.REGISTRATIONNO)<>dbo.fn_RemoveNoiseCharacters(R.REGISTRATIONNO) or (S.REGISTRATIONNO is not null and R.REGISTRATIONNO is null) or (S.REGISTRATIONNO   is null and R.REGISTRATIONNO is not null)))


	or	(P.INTLCLASSES       =1 and (S.INTLCLASSES       <>R.INTLCLASSES        or (S.INTLCLASSES        is not null and R.INTLCLASSES        is null) or (S.INTLCLASSES        is null and R.INTLCLASSES        is not null)))
	or	(P.LOCALCLASSES      =1 and (S.LOCALCLASSES      <>R.LOCALCLASSES       or (S.LOCALCLASSES       is not null and R.LOCALCLASSES       is null and (S.LOCALCLASSES<>S.INTLCLASSES OR S.INTLCLASSES is null)) or (S.LOCALCLASSES       is null and R.LOCALCLASSES       is not null)))

	or	(P.NUMBEROFYEARS     =1 and (isnull(S.NUMBEROFYEARS,0)  <>R.NUMBEROFYEARS      or (S.NUMBEROFYEARS      is not null and R.NUMBEROFYEARS      is null)))
	or	(P.NUMBEROFCLAIMS    =1 and (isnull(S.NUMBEROFCLAIMS,0) <>R.NUMBEROFCLAIMS     or (S.NUMBEROFCLAIMS     is not null and R.NUMBEROFCLAIMS     is null)))
	or	(P.NUMBEROFDESIGNS   =1 and (isnull(S.NUMBEROFDESIGNS,0)<>R.NUMBEROFDESIGNS    or (S.NUMBEROFDESIGNS    is not null and R.NUMBEROFDESIGNS    is null)))
	or	(P.NUMBEROFCLASSES   =1 and (isnull(S.NUMBEROFCLASSES,0)<>R.NUMBEROFCLASSES    or (S.NUMBEROFCLASSES    is not null and R.NUMBEROFCLASSES    is null)))
	or	(P.NUMBEROFSTATES    =1 and (isnull(S.NUMBEROFSTATES,0) <>R.NUMBEROFSTATES     or (S.NUMBEROFSTATES     is not null and R.NUMBEROFSTATES     is null)))

	or	(P.DESIGNATEDSTATES  =1 and (S.DESIGNATEDSTATES  <>R.DESIGNATEDSTATES   or (S.DESIGNATEDSTATES   is not null and R.DESIGNATEDSTATES   is null) or (S.DESIGNATEDSTATES   is null and R.DESIGNATEDSTATES   is not null)))
		
		-- Note : Names do an inexact match. Strip out Spaces; Full Stops; Commas and Hyphens and compare the first 8 characters

	or	(P.OWNERNAME         =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.OWNERNAME)       ),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.OWNERNAME)       ),8) or (S.OWNERNAME          is not null and R.OWNERNAME          is null) or (S.OWNERNAME          is null and R.OWNERNAME          is not null)))
	or	(P.CLIENTNAME        =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.CLIENTNAME)      ),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.CLIENTNAME)      ),8) or (S.CLIENTNAME         is not null and R.CLIENTNAME         is null) or (S.CLIENTNAME         is null and R.CLIENTNAME         is not null)))
	or	(P.DIVISIONNAME      =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.DIVISIONNAME)    ),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.DIVISIONNAME)    ),8) or (S.DIVISIONNAME       is not null and R.DIVISIONNAME       is null) or (S.DIVISIONNAME       is null and R.DIVISIONNAME       is not null)))
	or	(P.FOREIGNAGENTNAME  =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.FOREIGNAGENTNAME)),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.FOREIGNAGENTNAME)),8) or (S.FOREIGNAGENTNAME   is not null and R.FOREIGNAGENTNAME   is null) or (S.FOREIGNAGENTNAME   is null and R.FOREIGNAGENTNAME   is not null)))
	or	(P.ATTORNEYNAME      =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.ATTORNEYNAME)    ),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.ATTORNEYNAME)    ),8) or (S.ATTORNEYNAME       is not null and R.ATTORNEYNAME       is null) or (S.ATTORNEYNAME       is null and R.ATTORNEYNAME       is not null)))
	or	(P.INVOICEENAME      =1 and (Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(S.INVOICEENAME)    ),8)<>Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(R.INVOICEENAME)    ),8) or (S.INVOICEENAME       is not null and R.INVOICEENAME       is null) or (S.INVOICEENAME       is null and R.INVOICEENAME       is not null)))

	or	(P.OWNERNAMECODE     =1 and (S.OWNERNAMECODE     <>R.OWNERNAMECODE      or (S.OWNERNAMECODE      is not null and R.OWNERNAMECODE      is null) or (S.OWNERNAMECODE      is null and R.OWNERNAMECODE      is not null)))

	or	(P.OWNADDRESSLINE1   =1 and (replace(S.OWNADDRESSLINE1,' ','')<>replace(R.OWNADDRESSLINE1,' ','') or (S.OWNADDRESSLINE1    is not null and R.OWNADDRESSLINE1    is null) or (S.OWNADDRESSLINE1    is null and R.OWNADDRESSLINE1    is not null)))
	or	(P.OWNADDRESSLINE2   =1 and (replace(S.OWNADDRESSLINE2,' ','')<>replace(R.OWNADDRESSLINE2,' ','') or (S.OWNADDRESSLINE2    is not null and R.OWNADDRESSLINE2    is null) or (S.OWNADDRESSLINE2    is null and R.OWNADDRESSLINE2    is not null)))
	or	(P.OWNADDRESSLINE3   =1 and (replace(S.OWNADDRESSLINE3,' ','')<>replace(R.OWNADDRESSLINE3,' ','') or (S.OWNADDRESSLINE3    is not null and R.OWNADDRESSLINE3    is null) or (S.OWNADDRESSLINE3    is null and R.OWNADDRESSLINE3    is not null)))
	or	(P.OWNADDRESSLINE4   =1 and (replace(S.OWNADDRESSLINE4,' ','')<>replace(R.OWNADDRESSLINE4,' ','') or (S.OWNADDRESSLINE4    is not null and R.OWNADDRESSLINE4    is null) or (S.OWNADDRESSLINE4    is null and R.OWNADDRESSLINE4    is not null)))

	or	(P.OWNADDRESSCOUNTRY =1 and (S.OWNADDRESSCOUNTRY <>R.OWNADDRESSCOUNTRY  or (S.OWNADDRESSCOUNTRY  is not null and R.OWNADDRESSCOUNTRY  is null) or (S.OWNADDRESSCOUNTRY  is null and R.OWNADDRESSCOUNTRY  is not null)))
	or	(P.OWNADDRESSPOSTCODE=1 and (S.OWNADDRESSPOSTCODE<>R.OWNADDRESSPOSTCODE or (S.OWNADDRESSPOSTCODE is not null and R.OWNADDRESSPOSTCODE is null) or (S.OWNADDRESSPOSTCODE is null and R.OWNADDRESSPOSTCODE is not null)))
	or	(P.CLIENTCODE        =1 and (S.CLIENTCODE        <>R.CLIENTCODE         or (S.CLIENTCODE         is not null and R.CLIENTCODE         is null) or (S.CLIENTCODE         is null and R.CLIENTCODE         is not null)))
	or	(P.CPACLIENTNO       =1 and (isnull(S.CPACLIENTNO,0)<>R.CPACLIENTNO     or (S.CPACLIENTNO        is not null and R.CPACLIENTNO        is null)))
	OR	(P.CLIENTATTENTION   =1 and S.CLIENTATTENTION    is not null and R.CLIENTATTENTION not like '%Dear Sir%' and Charindex(replace(S.CLIENTATTENTION,  ' ',''), replace(R.CLIENTATTENTION+R.CLTADDRESSLINE1+R.CLTADDRESSLINE2,' ',''))=0)

	or	(P.CLTADDRESSLINE1   =1 and S.CLTADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0)
	or	(P.CLTADDRESSLINE2   =1 and S.CLTADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0)
	or	(P.CLTADDRESSLINE3   =1 and S.CLTADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0)
	or	(P.CLTADDRESSLINE4   =1 and S.CLTADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0)
	or	(P.CLTADDRESSCOUNTRY =1 and S.CLTADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C1.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C1.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY))=0)
	or	(P.CLTADDRESSPOSTCODE=1 and S.CLTADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.CLTADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.CLTADDRESSLINE1+R.CLTADDRESSLINE2+R.CLTADDRESSLINE3+R.CLTADDRESSLINE4+R.CLTADDRESSCOUNTRY+R.CLTADDRESSPOSTCODE))=0)

	or	(P.CLIENTTELEPHONE   =1 AND S.CLIENTTELEPHONE    is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.CLIENTTELEPHONE)),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.CLIENTTELEPHONE)))=0)
	or	(P.CLIENTFAX         =1 AND S.CLIENTFAX          is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.CLIENTFAX      )),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.CLIENTFAX      )))=0)
	or	(P.CLIENTEMAIL       =1 and (S.CLIENTEMAIL       <>R.CLIENTEMAIL        or (S.CLIENTEMAIL        is not null and R.CLIENTEMAIL        is null) or (S.CLIENTEMAIL        is null and R.CLIENTEMAIL        is not null)))
	or	(P.DIVISIONCODE      =1 and (S.DIVISIONCODE      <>R.DIVISIONCODE       or (S.DIVISIONCODE       is not null and R.DIVISIONCODE       is null) or (S.DIVISIONCODE       is null and R.DIVISIONCODE       is not null)))
	OR	(P.DIVISIONATTENTION =1 and S.DIVISIONATTENTION  is not null and R.DIVISIONATTENTION not like '%Dear Sir%' and Charindex(replace(S.DIVISIONATTENTION,  ' ',''), replace(R.DIVISIONATTENTION+R.DIVADDRESSLINE1+R.DIVADDRESSLINE2,' ',''))=0)

	or	(P.DIVADDRESSLINE1   =1 and S.DIVADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0)
	or	(P.DIVADDRESSLINE2   =1 and S.DIVADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0)
	or	(P.DIVADDRESSLINE3   =1 and S.DIVADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0)
	or	(P.DIVADDRESSLINE4   =1 and S.DIVADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0)
	or	(P.DIVADDRESSCOUNTRY =1 and S.DIVADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C2.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C2.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY))=0)
	or	(P.DIVADDRESSPOSTCODE=1 and S.DIVADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.DIVADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.DIVADDRESSLINE1+R.DIVADDRESSLINE2+R.DIVADDRESSLINE3+R.DIVADDRESSLINE4+R.DIVADDRESSCOUNTRY+R.DIVADDRESSPOSTCODE))=0)

	or	(P.FOREIGNAGENTCODE  =1 and (S.FOREIGNAGENTCODE  <>R.FOREIGNAGENTCODE   or (S.FOREIGNAGENTCODE   is not null and R.FOREIGNAGENTCODE   is null) or (S.FOREIGNAGENTCODE   is null and R.FOREIGNAGENTCODE   is not null)))
	or	(P.ATTORNEYCODE      =1 and (S.ATTORNEYCODE      <>R.ATTORNEYCODE       or (S.ATTORNEYCODE       is not null and R.ATTORNEYCODE       is null) or (S.ATTORNEYCODE       is null and R.ATTORNEYCODE       is not null)))
	or	(P.INVOICEECODE      =1 and (S.INVOICEECODE      <>R.INVOICEECODE       or (S.INVOICEECODE       is not null and R.INVOICEECODE       is null) or (S.INVOICEECODE       is null and R.INVOICEECODE       is not null)))
	or	(P.CPAINVOICEENO     =1 and (isnull(S.CPAINVOICEENO,0)<>R.CPAINVOICEENO      or (S.CPAINVOICEENO      is not null and R.CPAINVOICEENO      is null)))
	OR	(P.INVOICEEATTENTION =1 and S.INVOICEEATTENTION  is not null and R.INVOICEEATTENTION not like '%Dear Sir%' and Charindex(replace(S.INVOICEEATTENTION,  ' ',''), replace(R.INVOICEEATTENTION+R.INVADDRESSLINE1+R.INVADDRESSLINE2,' ',''))=0)

	or	(P.INVADDRESSLINE1   =1 and S.INVADDRESSLINE1    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE1   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0)
	or	(P.INVADDRESSLINE2   =1 and S.INVADDRESSLINE2    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE2   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0)
	or	(P.INVADDRESSLINE3   =1 and S.INVADDRESSLINE3    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE3   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0)
	or	(P.INVADDRESSLINE4   =1 and S.INVADDRESSLINE4    is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSLINE4   ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0)
	or	(P.INVADDRESSCOUNTRY =1 and S.INVADDRESSCOUNTRY  is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSCOUNTRY ), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C3.INFORMALNAME), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0 AND Charindex(dbo.fn_RemoveNoiseCharacters(C3.COUNTRYABBREV), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY))=0)
	or	(P.INVADDRESSPOSTCODE=1 and S.INVADDRESSPOSTCODE is not null and Charindex(dbo.fn_RemoveNoiseCharacters(S.INVADDRESSPOSTCODE), dbo.fn_RemoveNoiseCharacters(R.INVADDRESSLINE1+R.INVADDRESSLINE2+R.INVADDRESSLINE3+R.INVADDRESSLINE4+R.INVADDRESSCOUNTRY+R.INVADDRESSPOSTCODE))=0)

	or	(P.INVOICEETELEPHONE =1 AND S.INVOICEETELEPHONE  is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.INVOICEETELEPHONE)),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.INVOICEETELEPHONE)))=0)
	or	(P.INVOICEEFAX       =1 AND S.INVOICEEFAX        is not null and Charindex(substring(reverse(dbo.fn_RemoveNoiseCharacters(S.INVOICEEFAX      )),1,6),reverse(dbo.fn_RemoveNoiseCharacters(R.INVOICEEFAX      )))=0)
	or	(P.INVOICEEEMAIL     =1 and (S.INVOICEEEMAIL     <>R.INVOICEEEMAIL      or (S.INVOICEEEMAIL      is not null and R.INVOICEEEMAIL      is null) or (S.INVOICEEEMAIL      is null and R.INVOICEEEMAIL      is not null))))
	-- COMMENTED out as the new ACKNOWLEDGED flag will indicate if the record has been processed
	--and     not exists
	--	(select * from CASEEVENT CE
	--	 where CE.CASEID=C.CASEID
	--	 and   CE.EVENTDATE is not null
	--	 and   CE.EVENTNO=@pnCPAReceivedEvent)

	-- COMMENTED out for performance reasons.  See next DELETE statement.
	--and	not exists
	--	(select * from CPANARRATIVE N
	--	 where N.EXCLUDEFLAG=1
	--	 and R.NARRATIVE like N.CPANARRATIVE)

	Select 	@ErrorCode=@@Error

	-- The following code looks pretty dumb when you consider a NOT EXISTS
	-- in the previous statement would have stopped the CASEIDs from being
	-- loaded into the temporary table in the first place.  The only problem
	-- is that the NOT EXIST caused the statement to run unacceptably slowly
	-- so I have elected to stop beating my head against a wall and use the
	-- following to DELETE those rejected Cases that have a Narrative that has
	-- been flagged to be ignored.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete #TEMPREJECTEDCASES
		from #TEMPREJECTEDCASES T
		join CPARECEIVE R   on (R.CASEID=T.CASEID)
		join CPAPORTFOLIO P on (P.CASEID=R.CASEID	-- SQA 8955
				    and P.STATUSINDICATOR='L')
		where R.BATCHNO=@pnBatchNo
		and exists
		(select * from CPANARRATIVE N
		 where N.EXCLUDEFLAG=1
		 and ( R.NARRATIVE = N.CPANARRATIVE
		 or   (R.NARRATIVE like N.CPANARRATIVE AND N.CPANARRATIVE like '%\%%' ESCAPE'\')))"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

	End

	-- Finally load the TEMPREJECTEDCASES with any CPARECEIVE cases that were not added to the
	-- CPA Portfolio which is indicated by the absence of the IPRURN.

	If @ErrorCode=0
	Begin
		Set @sSQLString="	
		insert into #TEMPREJECTEDCASES (CASEID,REJECTFLAG)
		select R.CASEID,1
		from CPARECEIVE R
		join CASES C	on (C.CASEID=R.CASEID)
		left join OFFICE O on (O.OFFICEID=C.OFFICEID)
		where R.BATCHNO = @pnBatchNo
		and   isnull(@pnCaseId,R.CASEID)=R.CASEID
		and   isnull(R.ACKNOWLEDGED,0)=0
		and   R.IPRURN is null
		and  (R.NARRATIVE=@psCPANarrative  OR @psCPANarrative   is null)
		and  (O.CPACODE=@psOfficeCPACode OR @psOfficeCPACode is null)
		and ((C.PROPERTYTYPE<>@psPropertyType and @pbNotProperty=1) OR (C.PROPERTYTYPE=@psPropertyType and isnull(@pbNotProperty,0)=0) OR @psPropertyType is NULL) 
		and not exists
		(select * from #TEMPREJECTEDCASES T
		 where T.CASEID=R.CASEID)"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @pnCaseId		int,
					  @psPropertyType	nvarchar(2),
					  @pbNotProperty	bit,
					  @psCPANarrative	nvarchar(50),
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo=@pnBatchNo,
					  @pnCaseId=@pnCaseId,
					  @psPropertyType=@psPropertyType,
					  @pbNotProperty=@pbNotProperty,
					  @psCPANarrative=@psCPANarrative,
					  @psOfficeCPACode=@psOfficeCPACode
	End
End

-- If the ErrorCode is no longer zero then report the ErrorCode

If  @ErrorCode<>0
Begin
	-- This Select is required for Centura programs calling the stored procedure
	Select @ErrorCode
End

Return @ErrorCode
go

grant execute on dbo.cpa_ReportComparison to public
go
