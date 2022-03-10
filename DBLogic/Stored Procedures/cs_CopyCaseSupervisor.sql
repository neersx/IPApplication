-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CopyCaseSupervisor
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_CopyCaseSupervisor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_CopyCaseSupervisor.'
	drop procedure [dbo].[cs_CopyCaseSupervisor]
end
print '**** Creating Stored Procedure dbo.cs_CopyCaseSupervisor...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_CopyCaseSupervisor
(
	@psNewCaseKeys			nvarchar(4000)	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11)	= null,
	@psProfileName			nvarchar(50)	= null,
	@psCaseFamilyReference		nvarchar(20)	= null,
	@psCountryKey			nvarchar(3)	= null,
	@psCountryName			nvarchar(60)	= null,
	@psCaseCategoryKey		nvarchar(2)	= null,
	@psCaseCategoryDescription	nvarchar(50)	= null,
	@psSubTypeKey			nvarchar(2)	= null,
	@psSubTypeDescription		nvarchar(50)	= null,
	@psCaseStatusKey		nvarchar(10)	= null,
	@psCaseStatusDescription	nvarchar(50)	= null,
	@psApplicationNumber		nvarchar(36)	= null,
	@pdtApplicationDate		datetime 	= null,
	@pnPolicingBatchNo		int		= null,
	@pbDebug			bit		= null
)
as
-- PROCEDURE:	cs_CopyCaseSupervisor
-- VERSION:	11
-- SCOPE:	CPA.net
-- DESCRIPTION:	Copy an existing case, optionally providing specific attribute values to use on the new case(s).
--              The process will normally result in a single new case.  
--              However, if a multi-class case is being copied to a country that permits only single class applications, 
--              a new case is created for each class.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02-DEC-2002  SF		1	Procedure created
-- 24-FEB-2003	SF	RFC57 	2	Change @psCaseFamilyReference to size 20
-- 24-FEB-2003	SF	RFC62 	3	Add constraint on CaseType 'A'
-- 25-FEB-2003	SF	RFC37 	4	Add @pnPolicingBatchNo
-- 09-APR-2003	SF	RFC55	5	CountryKey replacement data is incorrectly being cleared.
-- 28-APR-2003	SF	RFC55	8	rework
-- 29 Oct 2004	AB	8035	9	Use collate database_default on temp tables
-- 07 Jul 2005  TM	RFC2329	10	Increase the size of all case category parameters and local variables 
--					to 2 characters. 
-- 25 Nov 2011	ASH	R100640	11	Change the size of Case Key to 11.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @bCreateSingleCase bit

Set @nErrorCode = 0
Set @bCreateSingleCase = 1

If exists(Select * 
		from 	COPYPROFILE 
		where 	PROFILENAME = @psProfileName 
		and 	COPYAREA = 'CASES'
		and	CHARACTERKEY = 'NOOFCLASSES')
Begin
	-- Classes are to be copied.
	Declare @sCountryKey nvarchar(3)
	Declare @sCaseTypeKey nvarchar(3)

	Set @sCountryKey = null

	-- Get casetype of the new case	
	Select	@sCaseTypeKey = isnull(P.REPLACEMENTDATA, C.CASETYPE)
	from 	CASES C, COPYPROFILE P 
	where 	C.CASEID = @psCaseKey
	and 	P.PROFILENAME = @psProfileName
	and 	P.COPYAREA = 'CASES'
	and 	P.CHARACTERKEY = 'CASETYPE'

	-- Get country of the new case	
	Set @sCountryKey = @psCountryKey

	If @sCountryKey is null	
	Begin
		Select	@sCountryKey = isnull( P.REPLACEMENTDATA, C.COUNTRYCODE)
		from 	CASES C, COPYPROFILE P 
		where 	C.CASEID = @psCaseKey
		and 	P.PROFILENAME = @psProfileName
		and 	P.COPYAREA = 'CASES'
		and 	P.CHARACTERKEY = 'COUNTRYCODE'	

		if @sCountryKey is null 
			Set @sCountryKey = @psCountryKey
	End

	-- does it allow multi class application?	
	if (@sCaseTypeKey='A') 
	and not exists (Select	* 
			from	TABLEATTRIBUTES TA 
			where 	TA.PARENTTABLE = 'COUNTRY' 
			and	TA.TABLECODE = 5001
			and 	TA.GENERICKEY = @sCountryKey)
	Begin

		Declare @nRowCount int
		Declare @sNewCaseKey nvarchar(4000)
		Declare @sLocalClasses nvarchar(254)
		Declare @tLocalClasses table (	IDENT		int identity(1,1),
						LOCALCLASS 	nvarchar(5) collate database_default)

		Set @psNewCaseKeys = ''
		Set @sNewCaseKey = null
	
		Select 	@sLocalClasses = isnull( P.REPLACEMENTDATA, C.LOCALCLASSES)
		from 	CASES C, COPYPROFILE P 
		where 	C.CASEID = @psCaseKey
		and 	P.PROFILENAME = @psProfileName
		and 	P.COPYAREA = 'CASES'
		and 	P.CHARACTERKEY = 'LOCALCLASSES'

		If @sLocalClasses is not null
		Begin
			-- Yes, so, for each local class to be copied, create a new case.
			Set @bCreateSingleCase = 0

			Insert into @tLocalClasses (LOCALCLASS)
				Select 	Parameter 
				from	dbo.fn_Tokenise(@sLocalClasses,',')
	
			Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
	
			If @nRowCount > 0 and @nErrorCode = 0
			Begin
				Declare @nCounter int
				Declare @sLocalClass nvarchar(5)
				
				Set @nCounter = 1
				While @nCounter <= @nRowCount and @nErrorCode = 0
				Begin
					
					Select 	@sLocalClass = LOCALCLASS
						from @tLocalClasses
						where IDENT = @nCounter
		
					Exec @nErrorCode = cs_CopyCase
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@psCaseKey = @psCaseKey,
						@psProfileName = @psProfileName,
						@psNewCaseKey = @sNewCaseKey OUTPUT,
						@psCaseFamilyReference = @psCaseFamilyReference,
						@psCountryKey = @psCountryKey,
						@psCountryName = @psCountryName,
						@psCaseCategoryKey = @psCaseCategoryKey,
						@psCaseCategoryDescription = @psCaseCategoryDescription,
						@psSubTypeKey = @psSubTypeKey,
						@psSubTypeDescription = @psSubTypeDescription,
						@psCaseStatusKey = @psCaseStatusKey,
						@psCaseStatusDescription = @psCaseStatusDescription,
						@psApplicationNumber = @psApplicationNumber,
						@pdtApplicationDate = @pdtApplicationDate,
						@psLocalClasses = @sLocalClass,
						@psIntClasses = @sLocalClass,						
						@pnNoOfClasses = 1,
						@pnPolicingBatchNo = @pnPolicingBatchNo,
						@pbDebug = @pbDebug
		
					Set @nCounter = @nCounter + 1
	
					If len(@psNewCaseKeys)>0				
						Set @psNewCaseKeys = @psNewCaseKeys + ',' + @sNewCaseKey
					Else
						Set @psNewCaseKeys = @sNewCaseKey
				End
			End
		End
	End
End



If @nErrorCode = 0
and @bCreateSingleCase = 1
Begin
	-- Some of the conditions are not met so only a single case will be created.
	Exec @nErrorCode = cs_CopyCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@psCaseKey = @psCaseKey,
		@psProfileName = @psProfileName,
		@psNewCaseKey = @psNewCaseKeys OUTPUT,
		@psCaseFamilyReference = @psCaseFamilyReference,
		@psCountryKey = @psCountryKey,
		@psCountryName = @psCountryName,
		@psCaseCategoryKey = @psCaseCategoryKey,
		@psCaseCategoryDescription = @psCaseCategoryDescription,
		@psSubTypeKey = @psSubTypeKey,
		@psSubTypeDescription = @psSubTypeDescription,
		@psCaseStatusKey = @psCaseStatusKey,
		@psCaseStatusDescription = @psCaseStatusDescription,
		@psApplicationNumber = @psApplicationNumber,
		@pdtApplicationDate = @pdtApplicationDate,
		@psLocalClasses = null,
		@psIntClasses = null,
		@pnNoOfClasses = null,
		@pnPolicingBatchNo = @pnPolicingBatchNo,
		@pbDebug = @pbDebug

End

Return @nErrorCode
GO

Grant execute on dbo.cs_CopyCaseSupervisor to public
GO
