-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetNextRenewalDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetNextRenewalDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetNextRenewalDate.'
	Drop procedure [dbo].[cs_GetNextRenewalDate]
End
Print '**** Creating Stored Procedure dbo.cs_GetNextRenewalDate...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_GetNextRenewalDate
(
	@pnCaseKey			int,
	@pbCallFromCentura		bit=0,
	@pdtNextRenewalDate 		datetime=null 		output,
	@pdtCPARenewalDate		datetime=null		output,
	@pnCycle			smallint=null		output,
	@pbUseHighestCycle		bit=0

)
as
-- PROCEDURE :	cs_GetNextRenewalDate
-- VERSION :	18
-- DESCRIPTION:	Returns the next renewal date for the Case taking into consideration CPA dates as well.
-- NOTES:	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Jun 2003	MF			Procedure created
-- 02 Jun2003	MF	8788		Return the Cycle of the current Next Renewal Date
-- 03 Jun 2003	IB	8778		Added OUTPUT qualifier to @pnCycle parameter.
-- 11 Jun 2003	MF	8898		Remove the use of TOP and ORDER BY when getting CPA date.
-- 15 Sep 2003	MF	9057	5	If the Case is not flagged as CPA then do not extract the data.
-- 07 Oct 2003	MF	9329	6	Only return a CPA Next Renewal Date from the CPA EPL if the EPL 
--					indicates the case has been added to the Portfolio.
-- 23 Oct 2003	MF	9374	7	When getting the CPA Next Renewal Date only consider entries on 
--					the CPA Portfolio that are currently live.
-- 17 Nov 2003	MF	9457	8	If no CPA data exists then ensure the date 01 JAN 1801 is correctly returned
--					so that it can be replaced by NULL.  This is required to avoid getting an 
--					ANSI Warning message that indicates nulls have been eliminated.
-- 26 Nov 2003	MF	9491	9	Replace the ASATDATE with 01 Jan 1801 if it is null rather than CHAR(8)
-- 09 Jun 2004	MF	10161	10	Use derived table to get the cycle of the Open Action.  This gives better
--					performance and is consistent with the approach used by csw_ConstructCaseSelect.
-- 16 Jun 2004	MF	10180	11	Ignore certain types of records on CPA Portfolio when determining the CPA
--					next renewal date.  This is because CPA create multiple Portfolio records to
--					handle such things as Nominal Working or Affidavit of Use.
-- 28 Oct 2004	MF	10597	12	When the CPA Event file is being used to supply the Renewal Date use the 
--					NEXTRENEWALDATE column as this is consistent with the Portfolio.
-- 01 Jun 2005	MF	11434	13	Ignore CPARECEIVE records where the Narrative is "Non Relevant Amend".
-- 28 Feb 2007	PY	S14425	14	Reserved word [cycle]
-- 11 Dec 2008	MF	S17136	15	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 May 2010	MF	R9071	16	Allow a parameter to specify that the highest open cycle should be used to determin NRD.
-- 03 Jul 2013	vql	R13608	17	Error when using case search in french environment.
-- 29 Dec 2014	MF	R42684	18	Refactored code into the function fn_GetNextRenewalDate

Set nocount on

Declare @ErrorCode 	int
Set @ErrorCode = 0

if @ErrorCode=0
Begin 
	Select @pdtNextRenewalDate=NEXTRENEWALDATE,
	       @pdtCPARenewalDate =CPARENEWALDATE,
	       @pnCycle           =CYCLE
	from dbo.fn_GetNextRenewalDate (@pbUseHighestCycle)
	where CASEID=@pnCaseKey
End

If  @pbCallFromCentura=1
and @ErrorCode=0
Begin				
	Select	@pdtNextRenewalDate as NextRenewalDate,
		@pdtCPARenewalDate  as CPARenewalDate,
		@pnCycle            as [Cycle]
End

Return @ErrorCode
go

grant execute on dbo.cs_GetNextRenewalDate to public
go
