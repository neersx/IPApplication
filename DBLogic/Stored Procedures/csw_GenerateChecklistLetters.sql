-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GenerateChecklistLetters
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GenerateChecklistLetters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GenerateChecklistLetters.'
	Drop procedure [dbo].[csw_GenerateChecklistLetters]
End
Print '**** Creating Stored Procedure dbo.csw_GenerateChecklistLetters...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GenerateChecklistLetters
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey						int,		-- Mandatory
	@pnChecklistTypeKey				smallint,
	@pnScreenCriteriaKey			int		 	= null,
	@pnChecklistCriteriaKey			int		 	= null,
	@pnQuestionKey					smallint	= null,
	@pbYesNoValue					bit			= null,
	@pdtDateValue					datetime	= null,
	@pnStaffNameKey					int		 	= null,
	@pbProduceLetterEvenIfExists 	bit			= 1
	
)
as
-- PROCEDURE:	csw_GenerateChecklistLetters
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate letter according to checklist answer

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 FEB 2008	SF	RFC5776	  1	Procedure created
-- 19 AUG 2011  DV      RFC11069  2     Insert IDENTITYID value in ACTIVITYREQUEST table

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE	@nErrorCode	int
DECLARE @sSQLString nvarchar(4000)
DECLARE @bCanPrintIfPrimeOnly bit

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		-- Check if the case can generate prime case only letters 
		-- (i.e. the case is either marked as prime on a case list or is not against any case list).
		Set @sSQLString = "
			Select @bCanPrintIfPrimeOnly = 
			case when exists (SELECT 1 FROM CASELISTMEMBER 
						WHERE CASEID = @pnCaseKey
						and PRIMECASE = 1)
				or not exists (Select 1
						from CASELISTMEMBER
						where CASEID = @pnCaseKey) 
			then 1 else 0 end"

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@bCanPrintIfPrimeOnly bit OUTPUT,
			@pnCaseKey	int',
			@pnCaseKey = @pnCaseKey,
			@bCanPrintIfPrimeOnly = @bCanPrintIfPrimeOnly output

		Set @sSQLString = 
			"
			INSERT INTO ACTIVITYREQUEST(
			CASEID, SQLUSER, WHENREQUESTED, PROGRAMID, LETTERNO, QUESTIONNO, ACTIVITYTYPE, ACTIVITYCODE,
			EMPLOYEENO, [ACTION], PROCESSED, TRANSACTIONFLAG, LETTERDATE, PRODUCTCODE, CHECKLISTTYPE,
			DELIVERYID, HOLDFLAG,IDENTITYID)
			
			SELECT @pnCaseKey, SYSTEM_USER, GETDATE(), 'WorkBnch', L.LETTERNO, @pnQuestionKey, 32, 3204, 
			@pnStaffNameKey, null, 0, 0, isnull(@pdtDateValue, getdate()), null, @pnChecklistTypeKey, 
			L.DELIVERYID, L.HOLDFLAG,@pnUserIdentityId
			
			FROM CHECKLISTLETTER CL
			JOIN LETTER L ON (CL.LETTERNO = L.LETTERNO)
			WHERE CL.CRITERIANO = @pnChecklistCriteriaKey " +
			Case when @pnQuestionKey is not null then 
			"AND CL.QUESTIONNO = @pnQuestionKey
			AND CL.REQUIREDANSWER IN (" + CASE when @pbYesNoValue = 1 then "1" else "2" end + " , 3)"
			else "AND CL.QUESTIONNO is null"
			end + "
			AND (	(L.FORPRIMECASESONLY = 1 AND @bCanPrintIfPrimeOnly = 1) 
				or L.FORPRIMECASESONLY <> 1 or L.FORPRIMECASESONLY IS NULL)"
		
		If (@pbProduceLetterEvenIfExists = 0 or @pbProduceLetterEvenIfExists is null)
		Begin
			-- Don't include letters that are already requested for the case.
			Set @sSQLString = @sSQLString + "
			AND L.LETTERNO NOT IN (SELECT LETTERNO FROM ACTIVITYREQUEST WHERE CASEID = @pnCaseKey and LETTERNO IS NOT NULL)"
		End

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey		int, 
			@pnQuestionKey		int, 
			@pnStaffNameKey		int, 
			@pdtDateValue		datetime, 
			@pnChecklistTypeKey	int, 
			@pnChecklistCriteriaKey	int,
			@bCanPrintIfPrimeOnly	bit,
			@pnUserIdentityId       int',
			@pnCaseKey = @pnCaseKey,
			@pnQuestionKey = @pnQuestionKey,
			@pnStaffNameKey = @pnStaffNameKey,
			@pdtDateValue = @pdtDateValue,
			@pnChecklistTypeKey = @pnChecklistTypeKey,
			@pnChecklistCriteriaKey = @pnChecklistCriteriaKey,
			@bCanPrintIfPrimeOnly = @bCanPrintIfPrimeOnly,
			@pnUserIdentityId = @pnUserIdentityId
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GenerateChecklistLetters to public
GO
