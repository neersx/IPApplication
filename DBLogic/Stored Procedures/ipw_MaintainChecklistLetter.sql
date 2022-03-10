-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainChecklistLetter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainChecklistLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainChecklistLetter.'
	Drop procedure [dbo].[ipw_MaintainChecklistLetter]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainChecklistLetter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_MaintainChecklistLetter
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCriteriaKey			int,		-- Mandatory
    @pnLetterKey			smallint,	-- Mandatory
    @pnQuestionKey			smallint		= null,
    @pnAnswerRequired		decimal(1,0)	= null,
    @pbIsInherited		decimal(1,0)	= null,
    @pbPassToDescendants        bit             = 0,
    @pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	ipw_MaintainChecklistLetter
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the checklist letter.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF	RFC9193	1	Procedure created
-- 21 JAN 2011	SF	RFC9193	2	Allow comparison of null values
-- 04 Feb 2011  LP      RFC9193 3       Allow changes to propagate to descendants.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If exists(Select 1 
				from CHECKLISTLETTER 
				where CRITERIANO = @pnCriteriaKey
				and		LETTERNO = @pnLetterKey)
	Begin

		Set @sSQLString = N'
		Update CHECKLISTLETTER
			Set QUESTIONNO				= @pnQuestionKey,
			REQUIREDANSWER			= @pnAnswerRequired
		where	CRITERIANO		= @pnCriteriaKey
		and		LETTERNO			= @pnLetterKey
		and		LOGDATETIMESTAMP = @pdtLastModifiedDate'

		
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnCriteriaKey			int,		
						@pnLetterKey			smallint,	
						@pnQuestionKey			smallint,	
						@pnAnswerRequired		decimal(1,0),
						@pdtLastModifiedDate	datetime',
						@pnCriteriaKey			= @pnCriteriaKey,		
						@pnQuestionKey			= @pnQuestionKey,	
						@pnLetterKey			= @pnLetterKey,	
						@pnAnswerRequired		= @pnAnswerRequired,
						@pdtLastModifiedDate	= @pdtLastModifiedDate 
	        If @nErrorCode = 0
		and @pbPassToDescendants = 1
		Begin
		        -- First delete existing CHECKLISTITEM if it will be INHERITED
	                Delete CL
		        from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
                        join CHECKLISTLETTER CL on (CL.CRITERIANO=C.CRITERIANO)
                        left join CHECKLISTLETTER CL2 on (CL2.CRITERIANO = @pnCriteriaKey
                                        and CL2.LETTERNO = CL.LETTERNO)
                        Where CL2.CRITERIANO IS NOT NULL
                        and CL2.LETTERNO = @pnLetterKey
        		
		        Set @nErrorCode = @@Error
		        
		        If @nErrorCode = 0
		        Begin
		                Set @sSQLString = 
	                                N'INSERT CHECKLISTLETTER (
		                                CRITERIANO,
		                                LETTERNO,
		                                QUESTIONNO,
		                                REQUIREDANSWER,
		                                INHERITED
	                                )
	                                SELECT	
	                                        C.CRITERIANO,	
		                                @pnLetterKey,
		                                @pnQuestionKey,
		                                @pnAnswerRequired,
		                                1
	                                from dbo.fn_GetChildCriteria(@pnCriteriaKey,0) C
	                                where C.FROMCRITERIA IS NOT NULL'
                        		
	                                exec @nErrorCode = sp_executesql @sSQLString,
		 		                                        N'@pnCriteriaKey		int,		
					                                @pnLetterKey			smallint,	
					                                @pnQuestionKey			smallint,	
					                                @pnAnswerRequired		decimal(1,0)',
					                                @pnCriteriaKey			= @pnCriteriaKey,	
					                                @pnLetterKey			= @pnLetterKey,		
					                                @pnQuestionKey			= @pnQuestionKey,	
					                                @pnAnswerRequired		= @pnAnswerRequired
		        End
		End
	End
	Else
	Begin
		Set @sSQLString = 
		N'INSERT CHECKLISTLETTER (
			CRITERIANO,
			LETTERNO,
			QUESTIONNO,
			REQUIREDANSWER
		)
		values 
		(	
			@pnCriteriaKey,
			@pnLetterKey,
			@pnQuestionKey,
			@pnAnswerRequired
		)'
		
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnCriteriaKey			int,		
						@pnLetterKey			smallint,	
						@pnQuestionKey			smallint,	
						@pnAnswerRequired		decimal(1,0)',
						@pnCriteriaKey			= @pnCriteriaKey,	
						@pnLetterKey			= @pnLetterKey,		
						@pnQuestionKey			= @pnQuestionKey,	
						@pnAnswerRequired		= @pnAnswerRequired
						
	        If @nErrorCode = 0
	        and @pbPassToDescendants = 1
	        Begin
	                -- First delete existing CHECKLISTITEM if it will be INHERITED
	                Delete CL
		        from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
                        join CHECKLISTLETTER CL on (CL.CRITERIANO=C.CRITERIANO)
                        left join CHECKLISTLETTER CL2 on (CL2.CRITERIANO = @pnCriteriaKey
                                        and CL2.LETTERNO = CL.LETTERNO)
                        Where CL2.CRITERIANO IS NOT NULL
                        and CL2.LETTERNO = @pnLetterKey
        		
		        Set @nErrorCode = @@Error
		        
		        If @nErrorCode = 0
		        Begin
		                Set @sSQLString = 
		                        N'INSERT CHECKLISTLETTER (
			                        CRITERIANO,
			                        LETTERNO,
			                        QUESTIONNO,
			                        REQUIREDANSWER,
			                        INHERITED
		                        )
		                        SELECT	
		                                C.CRITERIANO,	
			                        @pnLetterKey,
			                        @pnQuestionKey,
			                        @pnAnswerRequired,
			                        1
		                        from dbo.fn_GetChildCriteria(@pnCriteriaKey,0) C
		                        where C.FROMCRITERIA IS NOT NULL'
                        		
		                        exec @nErrorCode = sp_executesql @sSQLString,
			 		                                N'@pnCriteriaKey		int,		
						                        @pnLetterKey			smallint,	
						                        @pnQuestionKey			smallint,	
						                        @pnAnswerRequired		decimal(1,0)',
						                        @pnCriteriaKey			= @pnCriteriaKey,	
						                        @pnLetterKey			= @pnLetterKey,		
						                        @pnQuestionKey			= @pnQuestionKey,	
						                        @pnAnswerRequired		= @pnAnswerRequired
		        End
		        
	        End
	
	End
	
	If (@nErrorCode = 0
	and @@ROWCOUNT > 0)
	Begin
		Set @sSQLString = N'
		Select @pbIsInherited = isnull(I.CRITERIANO, 0)
		from CHECKLISTLETTER CL
		/* find identical rule */		
		left join CHECKLISTLETTER CLPARENT on (
									CLPARENT.LETTERNO = CL.LETTERNO
								and CLPARENT.QUESTIONNO = CL.QUESTIONNO
								and CLPARENT.REQUIREDANSWER = CL.REQUIREDANSWER)
		/* that it inherits from */			
		left join INHERITS I on (I.CRITERIANO = CL.CRITERIANO
							and  I.FROMCRITERIA = CLPARENT.CRITERIANO)
		where	CL.CRITERIANO = @pnCriteriaKey
		and		CL.LETTERNO = @pnLetterKey
		'
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pbIsInherited			decimal(1,0) output,
			 			@pnLetterKey			smallint,	
						@pnCriteriaKey			int,		
						@pnQuestionKey			smallint,	
						@pnAnswerRequired		decimal(1,0)',
						@pbIsInherited			= @pbIsInherited output,
						@pnLetterKey			= @pnLetterKey,	
						@pnCriteriaKey			= @pnCriteriaKey,		
						@pnQuestionKey			= @pnQuestionKey,	
						@pnAnswerRequired		= @pnAnswerRequired
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString = N'
				Update CHECKLISTLETTER 
					Set INHERITED = @pbIsInherited
				where	CRITERIANO = @pnCriteriaKey
				and		LETTERNO = @pnLetterKey
			'
			
			exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pbIsInherited			decimal(1,0),
			 			@pnLetterKey			smallint,	
						@pnCriteriaKey			int',		
						@pbIsInherited			= @pbIsInherited,
						@pnCriteriaKey			= @pnCriteriaKey,	
						@pnLetterKey			= @pnLetterKey	
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainChecklistLetter to public
GO
