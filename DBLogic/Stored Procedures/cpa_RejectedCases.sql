-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_RejectedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpa_RejectedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cpa_RejectedCases.'
	Drop procedure [dbo].[cpa_RejectedCases]
End
Print '**** Creating Stored Procedure dbo.cpa_RejectedCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cpa_RejectedCases
	@pnBatchNo			int,
	@psOfficeCPACode		nvarchar (3)	=null
	
AS
-- PROCEDURE :	cpa_RejectedCases
-- VERSION :	5
-- DESCRIPTION:	Get the rejected cases within the specified batch
-- COPYRIGHT :	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 01 Jun 2005	PS	10077	1	Procedure created
-- 31 Aug 2005	MF	11795	2	Reject Reason was not being extracted correctly.
-- 18 Sep 2007	MF	15372	3	Only report a Case as rejected if the Narrative in the
--					CPASEND table does not match the Narrative for the previous
--					batch in which the Case was reported.
-- 21 Sep 2007	MF	15372	4	Reverse changes applied above for 15372.  On reflection the original
--					version was deemed to be a better solution.
-- 11 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(1000), 
		@sOfficeFilter	nvarchar(1000)

set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT 	R.BATCHDATE, R.CASECODE, R.CLIENTSREFERENCE, R.IPRURN, 
		R.CPACOUNTRYCODE, R.PROPERTYTYPE, R.RENEWALDATE, S.NARRATIVE, 
		R.BATCHNO 
	FROM CPARECEIVE R
	JOIN CPASEND S		on (S.BATCHNO=R.BATCHNO
				and S.CASEID =R.CASEID)
	JOIN SITECONTROL SC 	on (SC.CONTROLID = 'CPA Rejected Event')
	LEFT JOIN CASEEVENT CE	on (CE.CASEID =R.CASEID 
				and CE.EVENTNO=SC.COLINTEGER 
				and CE.CYCLE=1 
				and CE.OCCURREDFLAG=1)
	JOIN CASES C		on (C.CASEID=R.CASEID) 
	LEFT JOIN OFFICE O	on (C.OFFICEID=O.OFFICEID) 
	WHERE R.BATCHNO=@pnBatchNo 
	and R.ACKNOWLEDGED=1 
	and (O.CPACODE=@psOfficeCPACode or @psOfficeCPACode is null)
	and (CE.CASEID IS NOT NULL OR S.NARRATIVE IS NOT NULL)" 

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psOfficeCPACode	nvarchar(3)',
				  @pnBatchNo = @pnBatchNo,
				  @psOfficeCPACode = @psOfficeCPACode


End

RETURN @ErrorCode
GO

Grant execute on dbo.cpa_RejectedCases to public
GO
