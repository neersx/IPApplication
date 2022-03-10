-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainCaseList 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainCaseList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainCaseList.'
	Drop procedure [dbo].[csw_MaintainCaseList]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainCaseList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_MaintainCaseList
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnListKey		int				= null,
	@psListName		nvarchar(100)	= null,
	@psListDescription nvarchar(508)	= null,
	@pnCaseKey				int			= null,
	@psCaseReference		nvarchar(100),
	@pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	csw_MaintainCaseList
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the checklist item.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 1 MAR 2011	KR	RFC6563		1	Procedure created
--22 JUN 2011	KR	RFC100571	2	Fixed the problem when the LASTINTERNALCODE doesn't exist for CASELIST
--09 SEP 2011	KR	RFC11100	3	Prime case can be null
--12 OCT 2011	KR	RFC100632	4	If prime case exists as a normalcase, remove and add as prime case


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nCaseListNo int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if @pnListKey is not null
	Begin
		Set @sSQLString = N'
		Update	CASELIST
				Set 
				CASELISTNAME =  @psListName,
				DESCRIPTION = @psListDescription
				where	CASELISTNO = @pnListKey and
				LOGDATETIMESTAMP = @pdtLastModifiedDate'
			
			exec @nErrorCode = sp_executesql @sSQLString,
			 				N'@pnListKey		int,
			 				@psListName		nvarchar(100),
			 				@psListDescription nvarchar(508),
							@pdtLastModifiedDate		datetime',
							@pnListKey			= @pnListKey,
							@psListName			= @psListName,
							@psListDescription	= @psListDescription,
							@pdtLastModifiedDate		= @pdtLastModifiedDate			
							
			
			Set @sSQLString = N'Delete	CASELISTMEMBER
				where	CASELISTNO = @pnListKey and
				PRIMECASE = 1'
			
			exec @nErrorCode = sp_executesql @sSQLString,
	 						N'@pnListKey		int,
	 						@pnCaseKey		int',
							@pnListKey			= @pnListKey,
							@pnCaseKey			= @pnCaseKey
			if @pnCaseKey is not null
			Begin
			
				If exists (Select 1 From CASELISTMEMBER where CASELISTNO = @pnListKey and CASEID = @pnCaseKey)
				Begin
					Delete from CASELISTMEMBER where CASELISTNO = @pnListKey and CASEID = @pnCaseKey 
				End
						
				Set @sSQLString = "Insert into CASELISTMEMBER
				(
				CASELISTNO,
				CASEID,
				PRIMECASE
				)
				Values
				(
				@pnListKey,
				@pnCaseKey,
				1
				)"
				
				exec @nErrorCode = sp_executesql @sSQLString,
			 					N'@pnListKey		int,
			 					@pnCaseKey		int',
								@pnListKey			= @pnListKey,
								@pnCaseKey			= @pnCaseKey
			End
		
	End	
	Else
	Begin
			if exists (select 1 from LASTINTERNALCODE Where TABLENAME = 'CASELIST')
				Select @nCaseListNo = INTERNALSEQUENCE+1 From LASTINTERNALCODE Where TABLENAME = 'CASELIST'
			else
				Set @nCaseListNo = 0
			
			Set @sSQLString = "Insert into CASELIST
			(
			CASELISTNO,
			CASELISTNAME,
			DESCRIPTION
			)
			Values
			(
			@nCaseListNo,
			@psListName,
			@psListDescription
			)"
			
			exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCaseListNo		int,
			@psListName			nvarchar(100),		
			@psListDescription		nvarchar(508)',
			@nCaseListNo		= @nCaseListNo,
			@psListName			= @psListName,
			@psListDescription	= @psListDescription
			
			if exists (select 1 from LASTINTERNALCODE Where TABLENAME = 'CASELIST')			
				Update LASTINTERNALCODE Set INTERNALSEQUENCE = @nCaseListNo Where TABLENAME = 'CASELIST'
			else
				Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE) values ('CASELIST', @nCaseListNo)
			
			if @pnCaseKey is not null
			Begin
				Set @sSQLString = "Insert into CASELISTMEMBER
				(
				CASELISTNO,
				CASEID,
				PRIMECASE
				)
				Values
				(
				@nCaseListNo,
				@pnCaseKey,
				1
				)"
				
				exec @nErrorCode = sp_executesql @sSQLString,
			 					N'@nCaseListNo		int,
			 					@pnCaseKey		int',
								@nCaseListNo			= @nCaseListNo,
								@pnCaseKey			= @pnCaseKey
			End
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainCaseList to public
GO
