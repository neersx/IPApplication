-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ReportSendReceiveDifferences
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ReportSendReceiveDifferences]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ReportSendReceiveDifferences.'
	drop procedure dbo.cpa_ReportSendReceiveDifferences
end
print '**** Creating procedure dbo.cpa_ReportSendReceiveDifferences...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_ReportSendReceiveDifferences 
		@pnBatchNo 		int		=null,
		@psPropertyType		nvarchar(2)	=null,
		@pbNotProperty		bit		=0,
		@psOfficeCPACode	nvarchar(3)	=null,
		@pnCaseKey              int             =null,
		@pbDiffOnly             bit             =1,
		@pbCalledFromCentura    bit             =1
as
-- PROCEDURE :	cpa_ReportSendReceiveDifferences
-- VERSION :	5
-- DESCRIPTION:	Performs a data comparison of the CPARECEIVE table against the CPASEND table for
--		a specific Batch and return details where a mismatch is found with details of the
--		mistmatch.
-- CALLED BY :	cpa_ReportSendReceiveDifferences
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	   Version      Description
-- -----------	-------	------	   -------	----------------------------------------------- 
-- 25/08/2005	MF		   1	        Procedure Created
-- 01/09/2009   LP      RFC938     2            Allow for results to be limited to a single case.
--                                              Return all columns and flag differences.
-- 12/10/2009   LP      RFC100075  3            Fix date values in Sent and Received result sets.     
-- 09 Mar 2012	vql	R10705	   4		Editable Renewals Tab in Silverlight (return logtimestamps).
-- 13 May 2016	LP	R61266	   5		Always return Sent data regardless of CPARECEIVE.

set nocount on

-- Temporary tables used in comparing data.  This has been coded 
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

CREATE TABLE #TEMPDIFFERENCES(
	CASEID			int	not null,
	PROPERTYTYPE		bit	default(0),
	ALTOFFICECODE		bit	default(0),
	FILENUMBER		bit	default(0),
	CLIENTSREFERENCE	bit	default(0),
	CPACOUNTRYCODE		bit	default(0),
	RENEWALTYPECODE		bit	default(0),
	MARK			bit	default(0),
	ENTITYSIZE		bit	default(0),
	PRIORITYDATE		bit	default(0),
	PARENTDATE		bit	default(0),
	NEXTTAXDATE		bit	default(0),
	NEXTDECOFUSEDATE	bit	default(0),
	PCTFILINGDATE		bit	default(0),
	ASSOCDESIGNDATE		bit	default(0),
	NEXTAFFIDAVITDATE	bit	default(0),
	APPLICATIONDATE		bit	default(0),
	ACCEPTANCEDATE		bit	default(0),
	PUBLICATIONDATE		bit	default(0),
	REGISTRATIONDATE	bit	default(0),
	RENEWALDATE		bit	default(0),
	NOMINALWORKINGDATE	bit	default(0),
	EXPIRYDATE		bit	default(0),
	CPASTARTPAYDATE		bit	default(0),
	CPASTOPPAYDATE		bit	default(0),
	STOPPAYINGREASON	bit	default(0),
	PRIORITYNO		bit	default(0),
	PARENTNO		bit	default(0),
	PCTFILINGNO		bit	default(0),
	ASSOCDESIGNNO		bit	default(0),
	APPLICATIONNO		bit	default(0),
	ACCEPTANCENO		bit	default(0),
	PUBLICATIONNO		bit	default(0),
	REGISTRATIONNO		bit	default(0),
	INTLCLASSES		bit	default(0),
	LOCALCLASSES		bit	default(0),
	NUMBEROFYEARS		bit	default(0),
	NUMBEROFCLAIMS		bit	default(0),
	NUMBEROFDESIGNS		bit	default(0),
	NUMBEROFCLASSES		bit	default(0),
	NUMBEROFSTATES		bit	default(0),
	DESIGNATEDSTATES	bit	default(0),
	OWNERNAME		bit	default(0),
	OWNERNAMECODE		bit	default(0),
	OWNADDRESSLINE1		bit	default(0),
	OWNADDRESSLINE2		bit	default(0),
	OWNADDRESSLINE3		bit	default(0),
	OWNADDRESSLINE4		bit	default(0),
	OWNADDRESSCOUNTRY	bit	default(0),
	OWNADDRESSPOSTCODE	bit	default(0),
	CLIENTCODE		bit	default(0),
	CPACLIENTNO		bit	default(0),
	CLIENTNAME		bit	default(0),
	CLIENTATTENTION		bit	default(0),
	CLTADDRESSLINE1		bit	default(0),
	CLTADDRESSLINE2		bit	default(0),
	CLTADDRESSLINE3		bit	default(0),
	CLTADDRESSLINE4		bit	default(0),
	CLTADDRESSCOUNTRY	bit	default(0),
	CLTADDRESSPOSTCODE	bit	default(0),
	CLIENTTELEPHONE		bit	default(0),
	CLIENTFAX		bit	default(0),
	CLIENTEMAIL		bit	default(0),
	DIVISIONCODE		bit	default(0),
	DIVISIONNAME		bit	default(0),
	DIVISIONATTENTION	bit	default(0),
	DIVADDRESSLINE1		bit	default(0),
	DIVADDRESSLINE2		bit	default(0),
	DIVADDRESSLINE3		bit	default(0),
	DIVADDRESSLINE4		bit	default(0),
	DIVADDRESSCOUNTRY	bit	default(0),
	DIVADDRESSPOSTCODE	bit	default(0),
	FOREIGNAGENTCODE	bit	default(0),
	FOREIGNAGENTNAME	bit	default(0),
	ATTORNEYCODE		bit	default(0),
	ATTORNEYNAME		bit	default(0),
	INVOICEECODE		bit	default(0),
	CPAINVOICEENO		bit	default(0),
	INVOICEENAME		bit	default(0),
	INVOICEEATTENTION	bit	default(0),
	INVADDRESSLINE1		bit	default(0),
	INVADDRESSLINE2		bit	default(0),
	INVADDRESSLINE3		bit	default(0),
	INVADDRESSLINE4		bit	default(0),
	INVADDRESSCOUNTRY	bit	default(0),
	INVADDRESSPOSTCODE	bit	default(0),
	INVOICEETELEPHONE	bit	default(0),
	INVOICEEFAX		bit	default(0),
	INVOICEEEMAIL		bit	default(0)
	)

-- Table for building up the results to display. This allows columns to 
-- be changed into rows

CREATE TABLE #TEMPRESULT(
	CASEID			int					 NOT NULL,
	IPRURN			nvarchar(7)	collate database_default NULL,
	DATAITEM		nvarchar(30)	collate database_default NOT NULL,
	DATASENT		nvarchar(200)	collate database_default NULL,			
	DATARECEIVED		nvarchar(200)	collate database_default NULL,
	CPANARRATIVE		nvarchar(50)	collate database_default NULL,
	REJECTREASON		nvarchar(50)	collate database_default NULL,
	POSITION		tinyint					 NOT NULL,
	ISDIFFERENT             bit                                      NULL,
	FORMAT                  int                                      NULL
	)

declare	@ErrorCode		int
declare @RowCount		int
declare	@TranCountStart		int
declare	@sSQLString		nvarchar(max)
declare @sPropertyType		nvarchar(100)
declare @IsReceived		bit = 0


Select	@ErrorCode	=0
Select	@TranCountStart	=0

-- Load the CPASEND and CPARECEIVE rows for the Case and 
-- batch into a temporary table.

If  @ErrorCode=0
Begin
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
		R.CASEID,R.SYSTEMID,R.BATCHNO,R.BATCHDATE,R.PROPERTYTYPE,R.CASECODE,R.TRANSACTIONCODE,R.ALTOFFICECODE,R.FILENUMBER,
		R.CLIENTSREFERENCE,R.CPACOUNTRYCODE,R.RENEWALTYPECODE,R.MARK,R.ENTITYSIZE,R.PRIORITYDATE,R.PARENTDATE,R.NEXTTAXDATE,
		R.NEXTDECOFUSEDATE,R.PCTFILINGDATE,R.ASSOCDESIGNDATE,R.NEXTAFFIDAVITDATE,R.APPLICATIONDATE,R.ACCEPTANCEDATE,
		R.PUBLICATIONDATE,R.REGISTRATIONDATE,R.RENEWALDATE,R.NOMINALWORKINGDATE,R.EXPIRYDATE,R.CPASTARTPAYDATE,
		R.CPASTOPPAYDATE,R.STOPPAYINGREASON,R.PRIORITYNO,R.PARENTNO,R.PCTFILINGNO,R.ASSOCDESIGNNO,R.APPLICATIONNO,R.ACCEPTANCENO,
		R.PUBLICATIONNO,R.REGISTRATIONNO,R.INTLCLASSES,R.LOCALCLASSES,R.NUMBEROFYEARS,R.NUMBEROFCLAIMS,R.NUMBEROFDESIGNS,
		R.NUMBEROFCLASSES,R.NUMBEROFSTATES,R.DESIGNATEDSTATES,R.OWNERNAME,R.OWNERNAMECODE,R.OWNADDRESSLINE1,R.OWNADDRESSLINE2,
		R.OWNADDRESSLINE3,R.OWNADDRESSLINE4,R.OWNADDRESSCOUNTRY,R.OWNADDRESSPOSTCODE,R.CLIENTCODE,R.CPACLIENTNO,R.CLIENTNAME,
		R.CLIENTATTENTION,R.CLTADDRESSLINE1,R.CLTADDRESSLINE2,R.CLTADDRESSLINE3,R.CLTADDRESSLINE4,R.CLTADDRESSCOUNTRY,
		R.CLTADDRESSPOSTCODE,R.CLIENTTELEPHONE,R.CLIENTFAX,R.CLIENTEMAIL,R.DIVISIONCODE,R.DIVISIONNAME,R.DIVISIONATTENTION,
		R.DIVADDRESSLINE1,R.DIVADDRESSLINE2,R.DIVADDRESSLINE3,R.DIVADDRESSLINE4,R.DIVADDRESSCOUNTRY,R.DIVADDRESSPOSTCODE,
		R.FOREIGNAGENTCODE,R.FOREIGNAGENTNAME,R.ATTORNEYCODE,R.ATTORNEYNAME,R.INVOICEECODE,R.CPAINVOICEENO,R.INVOICEENAME,
		R.INVOICEEATTENTION,R.INVADDRESSLINE1,R.INVADDRESSLINE2,R.INVADDRESSLINE3,R.INVADDRESSLINE4,R.INVADDRESSCOUNTRY,
		R.INVADDRESSPOSTCODE,R.INVOICEETELEPHONE,R.INVOICEEFAX,R.INVOICEEEMAIL,R.NARRATIVE,R.IPRURN,R.ACKNOWLEDGED
	from CPARECEIVE R
	join CASES C       on (C.CASEID=R.CASEID)
	left join OFFICE O on (O.OFFICEID=C.OFFICEID)
	where R.BATCHNO=@pnBatchNo
	and  (O.CPACODE=@psOfficeCPACode or @psOfficeCPACode is null)
	and ((R.PROPERTYTYPE= @psPropertyType and isnull(@pbNotProperty,0)=0)
	  or (R.PROPERTYTYPE<>@psPropertyType and @pbNotProperty=1)
	  or  @psPropertyType is null)"+
	CASE WHEN @pnCaseKey is not null THEN "
	        and C.CASEID = @pnCaseKey"
	     ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psPropertyType	nvarchar(2),
				  @pbNotProperty	bit,
				  @psOfficeCPACode	nvarchar(3),
				  @pnCaseKey            int',
				  @pnBatchNo=@pnBatchNo,
				  @psPropertyType=@psPropertyType,
				  @pbNotProperty=@pbNotProperty,
				  @psOfficeCPACode=@psOfficeCPACode,
				  @pnCaseKey=@pnCaseKey

	SELECT @IsReceived = 1 from #TEMPCPARECEIVE where BATCHNO = @pnBatchNo
End

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
		S.CASEID,S.SYSTEMID,S.BATCHNO,S.BATCHDATE,S.PROPERTYTYPE,S.CASECODE,S.TRANSACTIONCODE,S.ALTOFFICECODE,S.FILENUMBER,
		S.CLIENTSREFERENCE,S.CPACOUNTRYCODE,S.RENEWALTYPECODE,S.MARK,S.ENTITYSIZE,S.PRIORITYDATE,S.PARENTDATE,S.NEXTTAXDATE,
		S.NEXTDECOFUSEDATE,S.PCTFILINGDATE,S.ASSOCDESIGNDATE,S.NEXTAFFIDAVITDATE,S.APPLICATIONDATE,S.ACCEPTANCEDATE,
		S.PUBLICATIONDATE,S.REGISTRATIONDATE,S.RENEWALDATE,S.NOMINALWORKINGDATE,S.EXPIRYDATE,S.CPASTARTPAYDATE,
		S.CPASTOPPAYDATE,S.STOPPAYINGREASON,S.PRIORITYNO,S.PARENTNO,S.PCTFILINGNO,S.ASSOCDESIGNNO,S.APPLICATIONNO,S.ACCEPTANCENO,
		S.PUBLICATIONNO,S.REGISTRATIONNO,S.INTLCLASSES,S.LOCALCLASSES,S.NUMBEROFYEARS,S.NUMBEROFCLAIMS,S.NUMBEROFDESIGNS,
		S.NUMBEROFCLASSES,S.NUMBEROFSTATES,S.DESIGNATEDSTATES,S.OWNERNAME,S.OWNERNAMECODE,S.OWNADDRESSLINE1,S.OWNADDRESSLINE2,
		S.OWNADDRESSLINE3,S.OWNADDRESSLINE4,S.OWNADDRESSCOUNTRY,S.OWNADDRESSPOSTCODE,S.CLIENTCODE,S.CPACLIENTNO,S.CLIENTNAME,
		S.CLIENTATTENTION,S.CLTADDRESSLINE1,S.CLTADDRESSLINE2,S.CLTADDRESSLINE3,S.CLTADDRESSLINE4,S.CLTADDRESSCOUNTRY,
		S.CLTADDRESSPOSTCODE,S.CLIENTTELEPHONE,S.CLIENTFAX,S.CLIENTEMAIL,S.DIVISIONCODE,S.DIVISIONNAME,S.DIVISIONATTENTION,
		S.DIVADDRESSLINE1,S.DIVADDRESSLINE2,S.DIVADDRESSLINE3,S.DIVADDRESSLINE4,S.DIVADDRESSCOUNTRY,S.DIVADDRESSPOSTCODE,
		S.FOREIGNAGENTCODE,S.FOREIGNAGENTNAME,S.ATTORNEYCODE,S.ATTORNEYNAME,S.INVOICEECODE,S.CPAINVOICEENO,S.INVOICEENAME,
		S.INVOICEEATTENTION,S.INVADDRESSLINE1,S.INVADDRESSLINE2,S.INVADDRESSLINE3,S.INVADDRESSLINE4,S.INVADDRESSCOUNTRY,
		S.INVADDRESSPOSTCODE,S.INVOICEETELEPHONE,S.INVOICEEFAX,S.INVOICEEEMAIL,S.NARRATIVE,S.IPRURN,S.ACKNOWLEDGED
	from CPASEND S
	join CASES C       on (C.CASEID=S.CASEID)
	left join OFFICE O on (O.OFFICEID=C.OFFICEID)
	where BATCHNO=@pnBatchNo
	and  (O.CPACODE=@psOfficeCPACode or @psOfficeCPACode is null)
	and ((S.PROPERTYTYPE= @psPropertyType and isnull(@pbNotProperty,0)=0)
	  or (S.PROPERTYTYPE<>@psPropertyType and @pbNotProperty=1)
	  or  @psPropertyType is null)"+
	CASE WHEN @pnCaseKey is not null THEN "
	        and C.CASEID = @pnCaseKey"
	     ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psPropertyType	nvarchar(2),
				  @pbNotProperty	bit,
				  @psOfficeCPACode	nvarchar(3),
				  @pnCaseKey            int',
				  @pnBatchNo=@pnBatchNo,
				  @psPropertyType=@psPropertyType,
				  @pbNotProperty=@pbNotProperty,
				  @psOfficeCPACode=@psOfficeCPACode,
				  @pnCaseKey=@pnCaseKey
End

if @ErrorCode=0
Begin
	-- Return a result set of flags indicating the columns that have mismatched

	if NOT EXISTS(SELECT 1 from #TEMPCPARECEIVE where BATCHNO = @pnBatchNo)
	Begin
		-- If batch has not been received just display sent data
		insert into #TEMPDIFFERENCES(CASEID)
		SELECT S.CASEID
		from #TEMPCPASEND S
		join CASES C on (C.CASEID=S.CASEID)
	End
	Else Begin
		Exec("
		insert into #TEMPDIFFERENCES
		select
		S.CASEID,
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
		from #TEMPCPASEND S
		left join #TEMPCPARECEIVE R	on (R.CASEID=S.CASEID)
		join CASES C		on (C.CASEID=S.CASEID)
		join CPACOMPARE P	on (P.PROPERTYTYPEKEY=CASE C.PROPERTYTYPE WHEN 'T' THEN 'T'
										  WHEN 'D' THEN 'D'
											   ELSE 'P'
							      END)
		left join COUNTRY C1	on (C1.COUNTRY=R.CLTADDRESSCOUNTRY)
		left join COUNTRY C2	on (C2.COUNTRY=R.DIVADDRESSCOUNTRY)
		left join COUNTRY C3	on (C3.COUNTRY=R.INVADDRESSCOUNTRY)")
	End	
	Set @ErrorCode = @@ERROR
End

-- Each Column where the data sent and the data received is a mismatch is to be reported as
-- a separate row.  
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Alternate Office Code',S.ALTOFFICECODE,R.ALTOFFICECODE,R.NARRATIVE,S.NARRATIVE,1,ISNULL(D.ALTOFFICECODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN 
                " where D.ALTOFFICECODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbDiffOnly		bit',
				  @pbDiffOnly=@pbDiffOnly
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'File Number',S.FILENUMBER,R.FILENUMBER,R.NARRATIVE,S.NARRATIVE, 2, ISNULL(D.FILENUMBER,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.FILENUMBER=1" ELSE "" END
	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Reference',S.CLIENTSREFERENCE,R.CLIENTSREFERENCE,R.NARRATIVE,S.NARRATIVE, 3, ISNULL(D.CLIENTSREFERENCE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTSREFERENCE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'CPA Country Code',S.CPACOUNTRYCODE,R.CPACOUNTRYCODE,R.NARRATIVE,S.NARRATIVE, 4, ISNULL(D.CPACOUNTRYCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CPACOUNTRYCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Renewal Type',S.RENEWALTYPECODE,R.RENEWALTYPECODE,R.NARRATIVE,S.NARRATIVE, 5, ISNULL(D.RENEWALTYPECODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.RENEWALTYPECODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Mark',S.MARK,R.MARK,R.NARRATIVE,S.NARRATIVE, 6, ISNULL(D.MARK,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.MARK=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Entity Size',S.ENTITYSIZE,R.ENTITYSIZE,R.NARRATIVE,S.NARRATIVE, 7, ISNULL(D.ENTITYSIZE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ENTITYSIZE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Priority Date',CONVERT(nvarchar,convert(datetime,S.PRIORITYDATE),126),CONVERT(nvarchar,convert(datetime,R.PRIORITYDATE),126),R.NARRATIVE,S.NARRATIVE, 8, ISNULL(D.PRIORITYDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PRIORITYDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Parent Date',CONVERT(nvarchar,convert(datetime,S.PARENTDATE),126),CONVERT(nvarchar,convert(datetime,R.PARENTDATE),126),R.NARRATIVE,S.NARRATIVE, 9, ISNULL(D.PARENTDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PARENTDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Next Tax Date',CONVERT(nvarchar,convert(datetime,S.NEXTTAXDATE),126),CONVERT(nvarchar,convert(datetime,R.NEXTTAXDATE),126),R.NARRATIVE,S.NARRATIVE, 10, ISNULL(D.NEXTTAXDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NEXTTAXDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Next Declaration of Use Date',CONVERT(nvarchar,convert(datetime,S.NEXTDECOFUSEDATE),126),CONVERT(nvarchar,convert(datetime,R.NEXTDECOFUSEDATE),126),R.NARRATIVE,S.NARRATIVE, 11, ISNULL(D.NEXTDECOFUSEDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NEXTDECOFUSEDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'PCT Filing Date',CONVERT(nvarchar,convert(datetime,S.PCTFILINGDATE),126),CONVERT(nvarchar,convert(datetime,R.PCTFILINGDATE),126),R.NARRATIVE,S.NARRATIVE, 12, ISNULL(D.PCTFILINGDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PCTFILINGDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Associated Design Date',CONVERT(nvarchar,convert(datetime,S.ASSOCDESIGNDATE),126),CONVERT(nvarchar,convert(datetime,R.ASSOCDESIGNDATE),126),R.NARRATIVE,S.NARRATIVE, 13, ISNULL(D.ASSOCDESIGNDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ASSOCDESIGNDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Next Affidavit Date',CONVERT(nvarchar,convert(datetime,S.NEXTAFFIDAVITDATE),126),CONVERT(nvarchar,convert(datetime,R.NEXTAFFIDAVITDATE),126),R.NARRATIVE,S.NARRATIVE, 14, ISNULL(D.NEXTAFFIDAVITDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NEXTAFFIDAVITDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Application Date',CONVERT(nvarchar,convert(datetime,S.APPLICATIONDATE),126),CONVERT(nvarchar,convert(datetime,R.APPLICATIONDATE),126),R.NARRATIVE,S.NARRATIVE, 15, ISNULL(D.APPLICATIONDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.APPLICATIONDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Acceptance Date',CONVERT(nvarchar,convert(datetime,S.ACCEPTANCEDATE),126),CONVERT(nvarchar,convert(datetime,R.ACCEPTANCEDATE),126),R.NARRATIVE,S.NARRATIVE, 16, ISNULL(D.ACCEPTANCEDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ACCEPTANCEDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Publication Date',CONVERT(nvarchar,convert(datetime,S.PUBLICATIONDATE),126),CONVERT(nvarchar,convert(datetime,R.PUBLICATIONDATE),126),R.NARRATIVE,S.NARRATIVE, 17, ISNULL(D.PUBLICATIONDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PUBLICATIONDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Registration Date',CONVERT(nvarchar,convert(datetime,S.REGISTRATIONDATE),126),CONVERT(nvarchar,convert(datetime,R.REGISTRATIONDATE),126),R.NARRATIVE,S.NARRATIVE, 18, ISNULL(D.REGISTRATIONDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.REGISTRATIONDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Renewal Date',CONVERT(nvarchar,convert(datetime,S.RENEWALDATE),126),CONVERT(nvarchar,convert(datetime,R.RENEWALDATE),126),R.NARRATIVE,S.NARRATIVE, 19, ISNULL(D.RENEWALDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.RENEWALDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Nominal Working Date',CONVERT(nvarchar,convert(datetime,S.NOMINALWORKINGDATE),126),CONVERT(nvarchar,convert(datetime,R.NOMINALWORKINGDATE),126),R.NARRATIVE,S.NARRATIVE, 20, ISNULL(D.NOMINALWORKINGDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NOMINALWORKINGDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Expiry Date',CONVERT(nvarchar,convert(datetime,S.EXPIRYDATE),126),CONVERT(nvarchar,convert(datetime,R.EXPIRYDATE),126),R.NARRATIVE,S.NARRATIVE, 21, ISNULL(D.EXPIRYDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.EXPIRYDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'CPA Start Pay Date',CONVERT(nvarchar,convert(datetime,S.CPASTARTPAYDATE),126),CONVERT(nvarchar,convert(datetime,R.CPASTARTPAYDATE),126),R.NARRATIVE,S.NARRATIVE, 22, ISNULL(D.CPASTARTPAYDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CPASTARTPAYDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'CPA Stop Pay Date',CONVERT(nvarchar,convert(datetime,S.CPASTOPPAYDATE),126),CONVERT(nvarchar,convert(datetime,R.CPASTOPPAYDATE),126),R.NARRATIVE,S.NARRATIVE, 23, ISNULL(D.CPASTOPPAYDATE,0),9103
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CPASTOPPAYDATE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Stop Paying Reason',S.STOPPAYINGREASON,R.STOPPAYINGREASON,R.NARRATIVE,S.NARRATIVE, 24, ISNULL(D.STOPPAYINGREASON,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.STOPPAYINGREASON=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Priority No.',S.PRIORITYNO,R.PRIORITYNO,R.NARRATIVE,S.NARRATIVE, 25, ISNULL(D.PRIORITYNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PRIORITYNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Parent No.',S.PARENTNO,R.PARENTNO,R.NARRATIVE,S.NARRATIVE, 26, ISNULL(D.PARENTNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PARENTNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'PCT Filing No.',S.PCTFILINGNO,R.PCTFILINGNO,R.NARRATIVE,S.NARRATIVE, 27, ISNULL(D.PCTFILINGNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PCTFILINGNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Associated Design No.',S.ASSOCDESIGNNO,R.ASSOCDESIGNNO,R.NARRATIVE,S.NARRATIVE, 28, ISNULL(D.ASSOCDESIGNNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ASSOCDESIGNNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Application No.',S.APPLICATIONNO,R.APPLICATIONNO,R.NARRATIVE,S.NARRATIVE, 29, ISNULL(D.APPLICATIONNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.APPLICATIONNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Acceptance No.',S.ACCEPTANCENO,R.ACCEPTANCENO,R.NARRATIVE,S.NARRATIVE, 30, ISNULL(D.ACCEPTANCENO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ACCEPTANCENO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Publication No.',S.PUBLICATIONNO,R.PUBLICATIONNO,R.NARRATIVE,S.NARRATIVE, 31, ISNULL(D.PUBLICATIONNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.PUBLICATIONNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Registration No.',S.REGISTRATIONNO,R.REGISTRATIONNO,R.NARRATIVE,S.NARRATIVE, 32, ISNULL(D.REGISTRATIONNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.REGISTRATIONNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'International Classes',S.INTLCLASSES,R.INTLCLASSES,R.NARRATIVE,S.NARRATIVE, 33, ISNULL(D.INTLCLASSES,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INTLCLASSES=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Local Classes',S.LOCALCLASSES,R.LOCALCLASSES,R.NARRATIVE,S.NARRATIVE, 34,ISNULL(D.LOCALCLASSES,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.LOCALCLASSES=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Number of Years',S.NUMBEROFYEARS,R.NUMBEROFYEARS,R.NARRATIVE,S.NARRATIVE, 35, ISNULL(D.NUMBEROFYEARS,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NUMBEROFYEARS=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Number of Claims',S.NUMBEROFCLAIMS,R.NUMBEROFCLAIMS,R.NARRATIVE,S.NARRATIVE, 36, ISNULL(D.NUMBEROFCLAIMS,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NUMBEROFCLAIMS=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Number of Designs',S.NUMBEROFDESIGNS,R.NUMBEROFDESIGNS,R.NARRATIVE,S.NARRATIVE, 37, ISNULL(D.NUMBEROFDESIGNS,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NUMBEROFDESIGNS=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Number of ClasseS',S.NUMBEROFCLASSES,R.NUMBEROFCLASSES,R.NARRATIVE,S.NARRATIVE, 38, ISNULL(D.NUMBEROFCLASSES,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NUMBEROFCLASSES=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Number of States',S.NUMBEROFSTATES,R.NUMBEROFSTATES,R.NARRATIVE,S.NARRATIVE, 39, ISNULL(D.NUMBEROFSTATES,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.NUMBEROFSTATES=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Designated States',S.DESIGNATEDSTATES,R.DESIGNATEDSTATES,R.NARRATIVE,S.NARRATIVE, 40, ISNULL(D.DESIGNATEDSTATES,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DESIGNATEDSTATES=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Name',S.OWNERNAME,R.OWNERNAME,R.NARRATIVE,S.NARRATIVE, 41, ISNULL(D.OWNERNAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNERNAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Name Code',S.OWNERNAMECODE,R.OWNERNAMECODE,R.NARRATIVE,S.NARRATIVE, 42, ISNULL(D.OWNERNAMECODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNERNAMECODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Line 1',S.OWNADDRESSLINE1,R.OWNADDRESSLINE1,R.NARRATIVE,S.NARRATIVE, 43, ISNULL(D.OWNADDRESSLINE1,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSLINE1=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Line 2',S.OWNADDRESSLINE2,R.OWNADDRESSLINE2,R.NARRATIVE,S.NARRATIVE, 44, ISNULL(D.OWNADDRESSLINE2,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSLINE2=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Line 3',S.OWNADDRESSLINE3,R.OWNADDRESSLINE3,R.NARRATIVE,S.NARRATIVE, 45, ISNULL(D.OWNADDRESSLINE3,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSLINE3=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Line 4',S.OWNADDRESSLINE4,R.OWNADDRESSLINE4,R.NARRATIVE,S.NARRATIVE, 46, ISNULL(D.OWNADDRESSLINE4,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSLINE4=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Country',S.OWNADDRESSCOUNTRY,R.OWNADDRESSCOUNTRY,R.NARRATIVE,S.NARRATIVE, 47, ISNULL(D.OWNADDRESSCOUNTRY,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSCOUNTRY=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Owner Address Postcode',S.OWNADDRESSPOSTCODE,R.OWNADDRESSPOSTCODE,R.NARRATIVE,S.NARRATIVE, 48, ISNULL(D.OWNADDRESSPOSTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.OWNADDRESSPOSTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Code',S.CLIENTCODE,R.CLIENTCODE,R.NARRATIVE,S.NARRATIVE, 49, ISNULL(D.CLIENTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'CPA Client No.',S.CPACLIENTNO,R.CPACLIENTNO,R.NARRATIVE,S.NARRATIVE, 50, ISNULL(D.CPACLIENTNO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CPACLIENTNO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Name',S.CLIENTNAME,R.CLIENTNAME,R.NARRATIVE,S.NARRATIVE, 51, ISNULL(D.CLIENTNAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTNAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Attention',S.CLIENTATTENTION,R.CLIENTATTENTION,R.NARRATIVE,S.NARRATIVE, 52, ISNULL(D.CLIENTATTENTION,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTATTENTION=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Line 1',S.CLTADDRESSLINE1,R.CLTADDRESSLINE1,R.NARRATIVE,S.NARRATIVE, 53, ISNULL(D.CLTADDRESSLINE1,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSLINE1=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Line 2',S.CLTADDRESSLINE2,R.CLTADDRESSLINE2,R.NARRATIVE,S.NARRATIVE, 54, ISNULL(D.CLTADDRESSLINE2,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSLINE2=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Line 3',S.CLTADDRESSLINE3,R.CLTADDRESSLINE3,R.NARRATIVE,S.NARRATIVE, 55, ISNULL(D.CLTADDRESSLINE3,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSLINE3=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Line 4',S.CLTADDRESSLINE4,R.CLTADDRESSLINE4,R.NARRATIVE,S.NARRATIVE, 56, ISNULL(D.CLTADDRESSLINE4,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSLINE4=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Country',S.CLTADDRESSCOUNTRY,R.CLTADDRESSCOUNTRY,R.NARRATIVE,S.NARRATIVE, 57, ISNULL(D.CLTADDRESSCOUNTRY,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSCOUNTRY=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Address Postcode',S.CLTADDRESSPOSTCODE,R.CLTADDRESSPOSTCODE,R.NARRATIVE,S.NARRATIVE, 58, ISNULL(D.CLTADDRESSPOSTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLTADDRESSPOSTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Telephone',S.CLIENTTELEPHONE,R.CLIENTTELEPHONE,R.NARRATIVE,S.NARRATIVE, 59, ISNULL(D.CLIENTTELEPHONE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTTELEPHONE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Fax',S.CLIENTFAX,R.CLIENTFAX,R.NARRATIVE,S.NARRATIVE, 60, ISNULL(D.CLIENTFAX,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTFAX=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Client Email',S.CLIENTEMAIL,R.CLIENTEMAIL,R.NARRATIVE,S.NARRATIVE, 61, ISNULL(D.CLIENTEMAIL,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CLIENTEMAIL=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Code',S.DIVISIONCODE,R.DIVISIONCODE,R.NARRATIVE,S.NARRATIVE, 62, ISNULL(D.DIVISIONCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVISIONCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Name',S.DIVISIONNAME,R.DIVISIONNAME,R.NARRATIVE,S.NARRATIVE, 63,ISNULL(D.DIVISIONNAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVISIONNAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Attention',S.DIVISIONATTENTION,R.DIVISIONATTENTION,R.NARRATIVE,S.NARRATIVE, 64, ISNULL(D.DIVISIONATTENTION,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVISIONATTENTION=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Line 1',S.DIVADDRESSLINE1,R.DIVADDRESSLINE1,R.NARRATIVE,S.NARRATIVE, 65, ISNULL(D.DIVADDRESSLINE1,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSLINE1=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Line 2',S.DIVADDRESSLINE2,R.DIVADDRESSLINE2,R.NARRATIVE,S.NARRATIVE, 66, ISNULL(D.DIVADDRESSLINE2,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSLINE2=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Line 3',S.DIVADDRESSLINE3,R.DIVADDRESSLINE3,R.NARRATIVE,S.NARRATIVE, 67, ISNULL(D.DIVADDRESSLINE3,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSLINE3=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Line 4',S.DIVADDRESSLINE4,R.DIVADDRESSLINE4,R.NARRATIVE,S.NARRATIVE, 68, ISNULL(D.DIVADDRESSLINE4,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSLINE4=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Country',S.DIVADDRESSCOUNTRY,R.DIVADDRESSCOUNTRY,R.NARRATIVE,S.NARRATIVE, 69, ISNULL(D.DIVADDRESSCOUNTRY,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSCOUNTRY=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Division Address Postcode',S.DIVADDRESSPOSTCODE,R.DIVADDRESSPOSTCODE,R.NARRATIVE,S.NARRATIVE, 70, ISNULL(D.DIVADDRESSPOSTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.DIVADDRESSPOSTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Foreign Agent Code',S.FOREIGNAGENTCODE,R.FOREIGNAGENTCODE,R.NARRATIVE,S.NARRATIVE, 71, ISNULL(D.FOREIGNAGENTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.FOREIGNAGENTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Foreign Agent Name',S.FOREIGNAGENTNAME,R.FOREIGNAGENTNAME,R.NARRATIVE,S.NARRATIVE, 72, ISNULL(D.FOREIGNAGENTNAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.FOREIGNAGENTNAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Attorney Code',S.ATTORNEYCODE,R.ATTORNEYCODE,R.NARRATIVE,S.NARRATIVE, 73, ISNULL(D.ATTORNEYCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ATTORNEYCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Attorney Name',S.ATTORNEYNAME,R.ATTORNEYNAME,R.NARRATIVE,S.NARRATIVE, 74, ISNULL(D.ATTORNEYNAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.ATTORNEYNAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'invoicee Code',S.INVOICEECODE,R.INVOICEECODE,R.NARRATIVE,S.NARRATIVE, 75, ISNULL(D.INVOICEECODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEECODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'CPA Invoicee No.',S.CPAINVOICEENO,R.CPAINVOICEENO,R.NARRATIVE,S.NARRATIVE, 76, ISNULL(D.CPAINVOICEENO,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.CPAINVOICEENO=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Name',S.INVOICEENAME,R.INVOICEENAME,R.NARRATIVE,S.NARRATIVE, 77, ISNULL(D.INVOICEENAME,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEENAME=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Attention',S.INVOICEEATTENTION,R.INVOICEEATTENTION,R.NARRATIVE,S.NARRATIVE, 78, ISNULL(D.INVOICEEATTENTION,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEEATTENTION=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Line 1',S.INVADDRESSLINE1,R.INVADDRESSLINE1,R.NARRATIVE,S.NARRATIVE, 79, ISNULL(D.INVADDRESSLINE1,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSLINE1=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Line 2',S.INVADDRESSLINE2,R.INVADDRESSLINE2,R.NARRATIVE,S.NARRATIVE, 80, ISNULL(D.INVADDRESSLINE2,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSLINE2=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Line 3',S.INVADDRESSLINE3,R.INVADDRESSLINE3,R.NARRATIVE,S.NARRATIVE, 81, ISNULL(D.INVADDRESSLINE3,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSLINE3=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Line 4',S.INVADDRESSLINE4,R.INVADDRESSLINE4,R.NARRATIVE,S.NARRATIVE, 82, ISNULL(D.INVADDRESSLINE4,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSLINE4=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Country',S.INVADDRESSCOUNTRY,R.INVADDRESSCOUNTRY,R.NARRATIVE,S.NARRATIVE, 83, ISNULL(D.INVADDRESSCOUNTRY,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSCOUNTRY=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Address Postcode',S.INVADDRESSPOSTCODE,R.INVADDRESSPOSTCODE,R.NARRATIVE,S.NARRATIVE, 84, ISNULL(D.INVADDRESSPOSTCODE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVADDRESSPOSTCODE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Telephone',S.INVOICEETELEPHONE,R.INVOICEETELEPHONE,R.NARRATIVE,S.NARRATIVE, 85, ISNULL(D.INVOICEETELEPHONE,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEETELEPHONE=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Fax',S.INVOICEEFAX,R.INVOICEEFAX,R.NARRATIVE,S.NARRATIVE, 86, ISNULL(D.INVOICEEFAX,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEEFAX=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
	select D.CASEID, R.IPRURN,'Invoicee Email',S.INVOICEEEMAIL,R.INVOICEEEMAIL,R.NARRATIVE,S.NARRATIVE, 87, ISNULL(D.INVOICEEEMAIL,0),9100
	from #TEMPDIFFERENCES D
	left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
	join #TEMPCPASEND S    on (S.CASEID=D.CASEID)" +
        CASE WHEN @pbDiffOnly = 1 THEN
               " where D.INVOICEEEMAIL=1" ELSE "" END

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
        If @pbCalledFromCentura = 1
        Begin
	        Set @sSQLString="
	        select C.IRN, R.IPRURN, R.DATAITEM,R.DATASENT,R.DATARECEIVED,R.CPANARRATIVE,R.REJECTREASON
	        from #TEMPRESULT R
	        join CASES C	on (C.CASEID=R.CASEID)"+
	        CASE WHEN @pnCaseKey is not null THEN " and C.CASEID = @pnCaseKey"
	             ELSE "" END
	        +" order by C.PROPERTYTYPE, C.IRN, R.POSITION"
	End
	Else
	Begin
	        Set @sSQLString = "Update #TEMPRESULT
	        set POSITION = POSITION + 6"
                
                exec @ErrorCode=sp_executesql @sSQLString
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'System ID',S.SYSTEMID,R.SYSTEMID,R.NARRATIVE,S.NARRATIVE, 1, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Batch Number',S.BATCHNO,R.BATCHNO,R.NARRATIVE,S.NARRATIVE, 2, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Batch Date',CONVERT(nvarchar,convert(datetime,S.BATCHDATE),126),CONVERT(nvarchar,convert(datetime,R.BATCHDATE),126),R.NARRATIVE,S.NARRATIVE, 3, 0,9103
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Property Type',S.PROPERTYTYPE,R.PROPERTYTYPE,R.NARRATIVE,S.NARRATIVE, 4, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Case Code',S.CASECODE,R.CASECODE,R.NARRATIVE,S.NARRATIVE, 5, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Transaction Code',S.TRANSACTIONCODE,R.TRANSACTIONCODE,R.NARRATIVE,S.NARRATIVE, 6, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'IPRURN',S.IPRURN,R.IPRURN,R.NARRATIVE,S.NARRATIVE, 100, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	        If @ErrorCode = 0
	        Begin
	        Set @sSQLString="
                        insert into #TEMPRESULT(CASEID, IPRURN, DATAITEM,DATASENT,DATARECEIVED,CPANARRATIVE,REJECTREASON,POSITION,ISDIFFERENT,FORMAT)
                        select D.CASEID, R.IPRURN,'Acknowledged',S.ACKNOWLEDGED,R.ACKNOWLEDGED,R.NARRATIVE,S.NARRATIVE, 101, 0,9100
                        from #TEMPDIFFERENCES D
                        left join #TEMPCPARECEIVE R on (R.CASEID=D.CASEID)
                        join #TEMPCPASEND S    on (S.CASEID=D.CASEID)"

                        exec @ErrorCode=sp_executesql @sSQLString
	        End
	        
	
	        Set @sSQLString="
	        select POSITION as RowKey, C.CASEID as CaseKey, 
	        C.IRN as CaseReference, R.DATAITEM as [FieldName],
	        R.DATASENT as SentValue,
	        R.DATARECEIVED as ReceivedValue, 
	        cast(R.ISDIFFERENT as bit) as IsDifferent, 
	        R.CPANARRATIVE as Narrative, R.FORMAT as Format
	        from #TEMPRESULT R
	        join CASES C	on (C.CASEID=R.CASEID)"+
	        CASE WHEN @pnCaseKey is not null THEN " and C.CASEID = @pnCaseKey"
	             ELSE "" END
	        +" order by C.PROPERTYTYPE, C.IRN, R.POSITION"
	End

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey            int',
				  @pnCaseKey=@pnCaseKey
End



Return @ErrorCode
go

grant execute on dbo.cpa_ReportSendReceiveDifferences to public
go
