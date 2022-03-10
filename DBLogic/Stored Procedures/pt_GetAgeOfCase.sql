-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetAgeOfCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetAgeOfCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetAgeOfCase.'
	drop procedure dbo.pt_GetAgeOfCase
	print '**** Creating procedure dbo.pt_GetAgeOfCase...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc dbo.pt_GetAgeOfCase 
		@pnCaseId 		int, 
		@pnCycle 		smallint = null, 
		@pbCalledFromCentura	tinyint  = 0,
		@pnAgeOfCase 		int 	output,
		@pdtRenewalStartDate	datetime = null,
		@pdtNextRenewalDate	datetime = null,
		@pdtCPARenewalDate	datetime = null
as

-- PROCEDURE :	pt_GetAgeOfCase
-- VERSION :	10
-- DESCRIPTION:	Determines the age of the Case from the Next Renewal Date either identified by
--		the cycle or calculated using the standard NRD calculation
-- CALLED BY :	FEESCALC, FEESCALCEXTENDED

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 26/02/2002	MF			Procedure Created
-- 05/08/2002	CR	7629		Incorporated VALIDPROPERTY.OFFSET into the equation.
--					Added a select of @pnAgeOfCase so that this value may
--					be returned to Centura calls.
-- 26/02/2002	MF	8455		Revist of 7629.  Need to allow for the VALIDPROPERTY dropping
--					back to the defaul entry if there is not a specific entry for the Country.
-- 29/05/2003	MF	8315		Improve performance on non SQLServer2000 databases by modifying how @prnYear is 
--					calculated and also standardise the extraction of the NRD by calling another procedure. 
-- 03/06/2003	IB	8778		Fix parameter order (@pdtRenewalStartDate, @pdtNextRenewalDate to go at end).
-- 27 Oct 2004	MF	RFC1539	5	If CPA are managing the Case then return the age of the Case from the Annuity
--					of the last CPAEVENT row that matches the CPA Renewal Date.
-- 02 Nov 2004	TM	RFC1539	6	Add standard settings.
-- 31 Jan 2006	MF	11942	7	Allow the Age of Case (Annuity) to be determined more flexibly depending on
--					rules associated with a given Country and Property Type combination.
-- 01 Dec 2009	MF	18278	8	Calculation of annuity number should consider special situations where Renewal date 
--					is not anniversary of Start Date
-- 22 Jan 2010	MF	18393	9	Revisit of 18278.  Datediff function should be using YY parameter and not Y.
-- 01 Aug 2011	Dw	19885	10	If CPA are managing the case but CPAEVENT data is insufficient to allow Age of Case
--					to be derived then fall back to using the standard calculation method.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@ErrorCode		int
declare @sSQLString		nvarchar(4000)

Select	@ErrorCode=0

-- If we do not have the CPA Renewal Date then calculate the age of the Case from 
-- first principles.
If @pdtCPARenewalDate is null
and @ErrorCode=0
Begin
	-- If the Renewal Start Date has not been passed as a parameter then extract it.
	If  @pdtRenewalStartDate is null
	Begin
		Set @sSQLString="Select @pdtRenewalStartDate=CE.EVENTDATE
				 From CASEEVENT CE
				 Where CE.CASEID=@pnCaseId
				 and   CE.EVENTNO=-9
				 and   CE.CYCLE=1"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnCaseId		int,
						  @pdtRenewalStartDate	datetime	OUTPUT',
						  @pnCaseId            =@pnCaseId,
						  @pdtRenewalStartDate=@pdtRenewalStartDate OUTPUT
	End
	
	-- If the Next Renewal Date has not been passed as a parameter then fetch it.
	
	If  @ErrorCode=0
	and @pdtNextRenewalDate is null
	Begin
		If @pnCycle>0
		Begin
			Set @sSQLString="Select @pdtNextRenewalDate=isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
					 from CASEEVENT CE
					 where CE.CASEID=@pnCaseId
					 and   CE.EVENTNO=-11
					 and   CE.CYCLE  =@pnCycle"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnCaseId		int,
							  @pnCycle		smallint,
							  @pdtNextRenewalDate	datetime	OUTPUT',
							  @pnCaseId            =@pnCaseId,
							  @pnCycle             =@pnCycle,
							  @pdtNextRenewalDate=@pdtNextRenewalDate OUTPUT
		End
		Else Begin
			-- Use a common stored procedure to get the Next Renewal Date
	
			Exec @ErrorCode= dbo.cs_GetNextRenewalDate
						@pnCaseKey		=@pnCaseId,
						@pbCallFromCentura	=0,
						@pdtNextRenewalDate 	=@pdtNextRenewalDate	output,
						@pdtCPARenewalDate	=@pdtCPARenewalDate	output,
						@pnCycle		=@pnCycle		output
	
			If @pdtCPARenewalDate is not null
				Set @pdtNextRenewalDate=@pdtCPARenewalDate
		End
	End	
End

-- If the CPA Renewal Date is available then extract the Age of Case as the Annuity
-- that matches that CPA Renewal Date.
-- Note that the @pdtCPARenewalDate may have been found in the previous block of code.

If @pdtCPARenewalDate is not null
and @ErrorCode=0
Begin
	-- Do not get the Annuity column for Trademark cases as Trademarks do not have an Annuity and
	-- the CPA column is actually storing the length of time (term) of the next renewal period.
	Set @sSQLString="	Select @pnAgeOfCase=min(CPA.ANNUITY)
				from CPAEVENT CPA
				where CPA.CASEID=@pnCaseId
				and CPA.ANNUITY is not null
				and CPA.NEXTRENEWALDATE=@pdtCPARenewalDate
				and CPA.TYPECODE<>'TM'"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId		int,
					  @pdtCPARenewalDate	datetime,
					  @pnAgeOfCase		smallint OUTPUT',
					  @pnCaseId		=@pnCaseId,
					  @pdtCPARenewalDate	=@pdtCPARenewalDate,
					  @pnAgeOfCase=@pnAgeOfCase OUTPUT
End


-- Calculate the Annuity if Inprotech is managing the Renewal dates and not CPA
-- or if the Annuity could not be derived from the CPA data
If  @ErrorCode=0
and ((@pdtCPARenewalDate is null) 
	or (@pnAgeOfCase is null) or (@pnAgeOfCase = 0))
Begin
	set @sSQLString="SELECT	@pnAgeOfCase=CASE(VP.ANNUITYTYPE)
						WHEN(0) THEN NULL
						WHEN(1) THEN 
							CASE WHEN(datepart(m,@pdtRenewalStartDate)=datepart(m,@pdtNextRenewalDate)+1
							       or(datepart(m,@pdtRenewalStartDate)=1 and datepart(m,@pdtNextRenewalDate)=12))
							       THEN floor(datediff(mm,@pdtRenewalStartDate, @pdtNextRenewalDate)/11) + ISNULL(VP.OFFSET, 0)
							     WHEN( datepart(m,@pdtNextRenewalDate)=1 
							       and datepart(d,@pdtNextRenewalDate)=1
							       and datepart(m,@pdtRenewalStartDate)<>datepart(m,@pdtNextRenewalDate) )
							       THEN datediff(yy,@pdtRenewalStartDate, @pdtNextRenewalDate) + ISNULL(VP.OFFSET, 0)
							       ELSE floor(datediff(mm,@pdtRenewalStartDate, @pdtNextRenewalDate)/12) + ISNULL(VP.OFFSET, 0)
							END
						WHEN(2) THEN @pnCycle+isnull(VP.CYCLEOFFSET,0)
					     END
			 FROM CASES C
			 join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
						and VP.COUNTRYCODE  = (select min(VP1.COUNTRYCODE)
									from VALIDPROPERTY VP1
									where VP1.PROPERTYTYPE=C.PROPERTYTYPE
									and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
			 WHERE   C.CASEID  = @pnCaseId"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId		int,
					  @pdtRenewalStartDate	datetime,
					  @pdtNextRenewalDate	datetime,
					  @pnCycle		smallint,
					  @pnAgeOfCase		smallint OUTPUT',
					  @pnCaseId		=@pnCaseId,
					  @pdtRenewalStartDate	=@pdtRenewalStartDate,
					  @pdtNextRenewalDate	=@pdtNextRenewalDate,
					  @pnCycle		=@pnCycle,
					  @pnAgeOfCase=@pnAgeOfCase OUTPUT
End

-- If called from Centurea select this parameter to make it available to Centura calls
if @pbCalledFromCentura = 1
	Select @pnAgeOfCase

Return @ErrorCode
go

grant execute on dbo.pt_GetAgeOfCase to public
go
