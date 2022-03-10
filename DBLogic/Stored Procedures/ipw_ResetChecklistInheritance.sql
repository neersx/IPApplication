-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ResetCheckListInheritance
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ResetCheckListInheritance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ResetCheckListInheritance.'
	Drop procedure [dbo].[ipw_ResetCheckListInheritance]
End
Print '**** Creating Stored Procedure dbo.ipw_ResetCheckListInheritance...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ResetCheckListInheritance
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCriteriaKey			int		-- Mandatory    
)
as
-- PROCEDURE:	ipw_ResetCheckListInheritance
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete current criteria details, copy everything from parent

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF		RFC9193	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nParentCriteriaKey int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- check whether the existing criteria is inherited from another criterion
	Set @sSQLString = "Select @nParentCriteriaKey = FROMCRITERIA
						from INHERITS
						where CRITERIANO = @pnCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@nParentCriteriaKey		int output,
			 			@pnCriteriaKey			int',		
						@nParentCriteriaKey		= @nParentCriteriaKey output,
						@pnCriteriaKey			= @pnCriteriaKey			

End

/*If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	Set @sSQLString = "
		Delete 
		from	CHECKLISTITEMCONDITION
		where	CRITERIANO = @pnCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnCriteriaKey			int',		
						@pnCriteriaKey			= @pnCriteriaKey
End*/

If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	Set @sSQLString = "
		Delete 
		from	CHECKLISTLETTER
		where	CRITERIANO = @pnCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnCriteriaKey			int',		
						@pnCriteriaKey			= @pnCriteriaKey
End

If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	Set @sSQLString = "
		Delete 
		from	CHECKLISTITEM
		where	CRITERIANO = @pnCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnCriteriaKey			int',		
						@pnCriteriaKey			= @pnCriteriaKey
End

If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	Set @sSQLString = "
		INSERT	CHECKLISTITEM
				(CRITERIANO,QUESTIONNO,SEQUENCENO,QUESTION,
				YESNOREQUIRED,COUNTREQUIRED,PERIODTYPEREQUIRED,
				AMOUNTREQUIRED,DATEREQUIRED,EMPLOYEEREQUIRED,TEXTREQUIRED,
				PAYFEECODE,UPDATEEVENTNO,DUEDATEFLAG,YESRATENO,NORATENO,
				INHERITED,NODUEDATEFLAG,NOEVENTNO,ESTIMATEFLAG,DIRECTPAYFLAG,
				SOURCEQUESTION,ANSWERSOURCEYES, ANSWERSOURCENO )
		SELECT	@pnCriteriaKey,QUESTIONNO,SEQUENCENO,QUESTION,
				YESNOREQUIRED,COUNTREQUIRED,PERIODTYPEREQUIRED,
				AMOUNTREQUIRED,DATEREQUIRED,EMPLOYEEREQUIRED,TEXTREQUIRED,
				PAYFEECODE,UPDATEEVENTNO,DUEDATEFLAG,YESRATENO,NORATENO,
				1,NODUEDATEFLAG,NOEVENTNO,ESTIMATEFLAG,DIRECTPAYFLAG,
				SOURCEQUESTION,ANSWERSOURCEYES, ANSWERSOURCENO
		from	CHECKLISTITEM
		where	CRITERIANO = @nParentCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@nParentCriteriaKey			int,
			 			@pnCriteriaKey				int',		
						@nParentCriteriaKey			= @nParentCriteriaKey,
						@pnCriteriaKey				= @pnCriteriaKey
End

/*If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	Set @sSQLString = "
		INSERT	CHECKLISTITEMCONDITION
				(CRITERIANO,QUESTIONNO,CONDITIONSEQNO,
				ANSWERBASEDONSOURCE,DISABLEFLAG,ISINHERITED)
		SELECT	@pnCriteriaKey,QUESTIONNO,CONDITIONSEQNO,
				ANSWERBASEDONSOURCE,DISABLEFLAG,1
		from	CHECKLISTITEMCONDITION
		where	CRITERIANO = @nParentCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@nParentCriteriaKey			int,
			 			@pnCriteriaKey				int',		
						@nParentCriteriaKey			= @nParentCriteriaKey,
						@pnCriteriaKey				= @pnCriteriaKey
End */

If @nErrorCode=0
and @nParentCriteriaKey is not null
Begin
	print 'CHECKLISTLETTER'
	Set @sSQLString = "
		INSERT	CHECKLISTLETTER
				(CRITERIANO,LETTERNO,QUESTIONNO,REQUIREDANSWER,INHERITED)
		SELECT	@pnCriteriaKey,LETTERNO,QUESTIONNO,REQUIREDANSWER,1
		from	CHECKLISTLETTER
		where	CRITERIANO = @nParentCriteriaKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@nParentCriteriaKey			int,
			 			@pnCriteriaKey				int',		
						@nParentCriteriaKey			= @nParentCriteriaKey,
						@pnCriteriaKey				= @pnCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ResetCheckListInheritance to public
GO
