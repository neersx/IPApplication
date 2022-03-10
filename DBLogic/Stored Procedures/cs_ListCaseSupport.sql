-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ListCaseSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_ListCaseSupport.'
	Drop procedure [dbo].[cs_ListCaseSupport]
	Print '**** Creating Stored Procedure dbo.cs_ListCaseSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_ListCaseSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,
	@psCaseKey		varchar(11) 	= null,
	@pnCaseAccessMode	int		= 1,		/* 1=Select, 4=insert, 8=update */
	@ptXMLFilterCriteria	ntext		= null		-- The filtering to be performed on the ValidStatus result set.
)

-- PROCEDURE:	cs_ListCaseSupport
-- VERSION :	21
-- DESCRIPTION:	Picklist for Case Maintenance in CPA.Net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 09-JUL-2002	Alan		Procedure created
-- 13-AUG-2002	SF		Conforming coding standards.
-- 22-OCT-2002	JB	5	New parameter to accept case access mode
-- 24-OCT-2002	JB	6	Fixed bug with quotes round @psCulture
-- 18-NOV-2002	SF	9	Removed references to the following sps
--				1 'MainEvent'		(ipn_ListMainEvents)
--				2 'Events'		(ipn_ListEvents)
--				3 'AllMainEvents'	(ipn_ListAllMainEvents)
--				4 'ValidEvent'		(ipn_ListValidEvents)
-- 18-NOV-2002	SF	10	Removed references to letter.
--				  'Letter'		(ipn_ListLetters)
-- 28-JAN-2003	SF	11	Added Support for NumberTypes
-- 19-MAR-2003	SF	12	Added Support for RenewalTypes, ExaminationTypes.
-- 30-APR-2003	SF	14	Added Support for Importance Level
-- 14-MAY-2003  TM      15      Removed the call to ipn_ListCountries
-- 11-AUG-2003	TM	16	RFC224 - Office level rules. Implement a new Office support
--				table (returned by ipn_ListOffices).
-- 21-AUG-2003	TM	17	RFC228 - Case Subclasses. The name of the supporting table 
--				was changed from TrademarkClass to Class. The data 
--				returned was changed to use the new <Class>.<SubClass>
-- 25-MAY-2005	TM	18	RFC2241	Add a new parameter @ptXMLFilterCriteria and pass it to ipn_ValidBasis.
-- 26-MAY-2005	TM	19	RFC2241	Remove debugging code.
-- 11 Apr 2013	DV	20	R13270  Increase the length of nvarchar to 11 when casting or declaring integer
-- 07 Sep 2018	AV	74738	21	Set isolation level to read uncommited.

AS

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare variables
Declare	@ErrorCode		int
Declare @nRow			smallint
Declare	@nUserIdentityId	int
Declare @sCulture		nvarchar(10)
Declare	@sProc			nvarchar(254)
Declare @sCaseKey		varchar(11)
Declare @bUsesCaseID		bit
Declare @sParams		varchar(1000)
Declare @nCaseAccessMode	int

-- initialise variables
Set @nUserIdentityId=@pnUserIdentityId
Set @sCulture=@psCulture
Set @sCaseKey=@psCaseKey
Set @nCaseAccessMode = @pnCaseAccessMode
Set @nRow=1
Set @ErrorCode=0

While @nRow is not null
Begin
	Select 	@sProc=
		CASE Parameter
			When 'CaseType'		then 'ipn_ListCaseTypes'
			When 'CaseCategory'	then 'ipn_ListCaseCategories'
			When 'PropertyType'	then 'ipn_ListProperties'
			When 'Status'		then 'ipn_ListStatus'
			When 'ValidStatus'	then 'ipn_ListValidStatus'
			When 'ValidProperty'	then 'ipn_ListValidProperties'
			When 'ValidCategory'	then 'ipn_ListValidCategories'
			When 'ValidSubType'	then 'ipn_ListValidSubTypes'
			When 'ValidBasis'	then 'ipn_ListValidBasis'
			When 'AnalysisCode1'	then 'ipn_ListAnalysisCode1'
			When 'AnalysisCode2'	then 'ipn_ListAnalysisCode2'
			When 'AnalysisCode3'	then 'ipn_ListAnalysisCode3'
			When 'AnalysisCode4'	then 'ipn_ListAnalysisCode4'
			When 'AnalysisCode5'	then 'ipn_ListAnalysisCode5'
			When 'NameType'		then 'ipn_ListNameTypes'
			When 'Action'		then 'ipn_ListActions'
			When 'ExpenseType'	then 'ipn_ListExpenseTypes'
			When 'ValidExpenseCategory' then 'ipn_ListValidExpenseCategories'
			When 'ValidRelationship' then 'ipn_ListValidRelationships'
			When 'Class'		then 'ipn_ListTrademarkClasses'
			When 'EntitySize'	then 'ipn_ListEntitySizes'
			When 'FileLocation'	then 'ipn_ListFileLocations'
			When 'StopPayReason'	then 'ipn_ListStopPayReasons'
			When 'TypeOfMark'	then 'ipn_ListTypeOfMarks'
			When 'NumberType'	then 'ipn_ListNumberTypes'
			When 'ExaminationType'	then 'ipn_ListExaminationTypes'
			When 'RenewalType'	then 'ipn_ListRenewalTypes'
			When 'ImportanceLevel'	then 'ipn_ListImportanceLevel'
			When 'Office'		then 'ipn_ListOffices'
		else NULL
		End,

		@bUsesCaseID=
		CASE Parameter
			When 'Action'		then 1
			When 'Class'		then 1
			When 'ValidRelationship' then 1
			else 0 end
	
	from fn_Tokenise (@psTables, NULL)
	where InsertOrder=@nRow

	--If @sProc is not null
	If (@@ROWCOUNT > 0)
	Begin
		If @sProc is not null
		Begin
			-- Build the parameters

			Set @sParams = '@pnUserIdentityId=' + CAST(@nUserIdentityId as varchar(11)) 

			If @sCulture is not null
				Set @sParams = @sParams + ", @psCulture='" + @sCulture + "'"

			If @bUsesCaseID = 1
				Set @sParams = @sParams + ", @psCaseKey='" + @sCaseKey + "'"

			-- Extended in version 5
			If @sProc = 'ipn_ListProperties'  
			or @sProc = 'ipn_ListValidProperties'
			or @sProc = 'ipn_ListCaseTypes'
			Begin
				Set @sParams = @sParams + ', @pnCaseAccessMode = ' + CAST(@nCaseAccessMode as varchar(11))
			End

			-- Pass @ptXMLFilterCriteria into the ipn_ListValidBasis:
			If @sProc = 'ipn_ListValidBasis' 
			Begin 
				Set @sParams = @sParams + ", @ptXMLFilterCriteria = N'" + CAST(@ptXMLFilterCriteria as nvarchar(4000)) + "'"
			End
 

			Exec (@sProc + ' ' + @sParams)
			Set @ErrorCode=@@ERROR
		End
		--exec sp_executesql @sProc, @params =N'@pnUserIdentityId int, @psCulture nvarchar(10)', @pnUserIdentityId=@pnUserIdentityId, @psCulture=@psCulture
		Set @nRow=@nRow+1
	End
	Else 
	Begin
		Set @nRow=null
	End

End

RETURN @ErrorCode
GO

Grant execute on dbo.cs_ListCaseSupport to public
GO
