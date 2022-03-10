-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ReportCPASendDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ReportCPASendDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ReportCPASendDetails.'
	drop procedure dbo.cpa_ReportCPASendDetails
end
print '**** Creating procedure dbo.cpa_ReportCPASendDetails...'
print ''
go 


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE 	dbo.cpa_ReportCPASendDetails 
			@pnBatchNo 		int,
			@psPropertyType		nvarchar(2)	=null,
			@pbNotProperty		bit		=0,
			@psOfficeCPACode	nvarchar(3)	=null
as
-- PROCEDURE :	dbo.cpa_ReportCPASendDetails
-- VERSION :	1
-- DESCRIPTION:	Lists all columns from CPASEND table.
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07/10/2005	KR		1	Procedure Created

set nocount on


DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(2000)

set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT 	BATCHNO, BATCHDATE,

		CASECODE, TRANSACTIONCODE, NARRATIVE,

		PROPERTYTYPE, CPACOUNTRYCODE, RENEWALTYPECODE,

		ALTOFFICECODE, FILENUMBER, CLIENTSREFERENCE, MARK, ENTITYSIZE,

		PRIORITYDATE, PARENTDATE, APPLICATIONDATE, ACCEPTANCEDATE, 
		PUBLICATIONDATE, REGISTRATIONDATE, PCTFILINGDATE, ASSOCDESIGNDATE,

		RENEWALDATE, NOMINALWORKINGDATE, EXPIRYDATE, NEXTTAXDATE, 
		NEXTDECOFUSEDATE, NEXTAFFIDAVITDATE,

		CPASTARTPAYDATE, CPASTOPPAYDATE, STOPPAYINGREASON,

		APPLICATIONNO, ACCEPTANCENO, PUBLICATIONNO, REGISTRATIONNO, PRIORITYNO,
		PARENTNO, PCTFILINGNO, ASSOCDESIGNNO,

		INTLCLASSES, LOCALCLASSES,

		NUMBEROFYEARS, NUMBEROFCLAIMS, NUMBEROFDESIGNS, NUMBEROFCLASSES,
		NUMBEROFSTATES, DESIGNATEDSTATES,

		OWNERNAME, OWNERNAMECODE, OWNADDRESSLINE1, OWNADDRESSLINE2, 
		OWNADDRESSLINE3, OWNADDRESSLINE4, OWNADDRESSCOUNTRY, OWNADDRESSPOSTCODE,

		CLIENTCODE, CLIENTNAME, CLIENTATTENTION, CLTADDRESSLINE1, CLTADDRESSLINE2,
		CLTADDRESSLINE3, CLTADDRESSLINE4, CLTADDRESSCOUNTRY, CLTADDRESSPOSTCODE, 
		CLIENTTELEPHONE, CLIENTFAX, CLIENTEMAIL,

		DIVISIONCODE, DIVISIONNAME, DIVISIONATTENTION, 
		DIVADDRESSLINE1, DIVADDRESSLINE2, DIVADDRESSLINE3, DIVADDRESSLINE4, 
		DIVADDRESSCOUNTRY, DIVADDRESSPOSTCODE,

		FOREIGNAGENTCODE, FOREIGNAGENTNAME,
		
		INVOICEECODE, INVOICEENAME, INVOICEEATTENTION, INVADDRESSLINE1, INVADDRESSLINE2,
		INVADDRESSLINE3, INVADDRESSLINE4, INVADDRESSCOUNTRY, INVADDRESSPOSTCODE, 
		INVOICEETELEPHONE, INVOICEEFAX, INVOICEEEMAIL

	FROM	CPASEND
	
	WHERE	BATCHNO = @pnBatchNo
	AND	((PROPERTYTYPE = @psPropertyType and isnull(@pbNotProperty,0)= 0)
	  	or (PROPERTYTYPE <> @psPropertyType and @pbNotProperty=1)
	  	or  @psPropertyType is null)
	AND	(ALTOFFICECODE = @psOfficeCPACode or @psOfficeCPACode is null)
	ORDER BY ALTOFFICECODE, PROPERTYTYPE, CPACOUNTRYCODE, CASECODE"
		
		

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psPropertyType	nvarchar(2),
				  @pbNotProperty	bit,
				  @psOfficeCPACode	nvarchar(3)',
				  @pnBatchNo=@pnBatchNo,
				  @psPropertyType=@psPropertyType,
				  @pbNotProperty=@pbNotProperty,
				  @psOfficeCPACode=@psOfficeCPACode


End

RETURN @ErrorCode 

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.cpa_ReportCPASendDetails to public
GO
