-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainChecklistItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainChecklistItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainChecklistItem.'
	Drop procedure [dbo].[ipw_MaintainChecklistItem]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainChecklistItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_MaintainChecklistItem
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura	bit			= 0,
	@pnQuestionKey			smallint,	-- Mandatory
    @pnCriteriaKey			int,		-- Mandatory
    @pnSequenceNo			smallint	= null,
    @psQuestion				nvarchar(100)	= null,
    @pnYesNoRequired		decimal(1,0)		= null,
    @pnCountRequired		decimal(1,0)		= null,
    @pnAmountRequired		decimal(1,0)		= null,
    @pnEmployeeRequired		decimal(1,0)		= null,
    @pnTextRequired			decimal(1,0)	= null,
    @pnPeriodRequired		decimal(1,0)		= null,
    @pnUpdateEventNo		int			= null,
    @pnNoEventNo			int		= null,
    @pbYesDueDateFlag		int			= null,
    @pbNoDueDateFlag		int			= null,
    @pnYesRateNo			int		= null,
    @pnNoRateNo				int		= null,
    @pbIsInherited			decimal(1,0)	= null,
    @psPayFeeCode			nchar(2)	= null,
    @pbIsEstimate			decimal(1,0)	= null,
    @pbIsDirectPay			decimal(1,0)	= null,
    @pnSourceQuestionKey		smallint	= null,
    @pnAnswerSourceYes			decimal(1,0)	= null,
    @pnAnswerSourceNo			decimal(1,0)	= null,
    @pbPassToDescendants        bit                     = 0,
    @pdtLastModifiedDate	datetime		= null
    
)
as
-- PROCEDURE:	ipw_MaintainChecklistItem
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the checklist item.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF	RFC9193	1	Procedure created
-- 21 JAN 2011	SF	RFC9193	2	Allow comparison of null values
-- 03 Feb 2011  LP      RFC9193 3       Added functionality to propagate changes to all descendants.     
--                                      Use cursor to loop through all descendants and re-allocate sequence
--                                      numbers for inherited checklist items  

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

CREATE TABLE #ChildCriteria (
                                CRITERIANO		int	NOT NULL	primary key,
                                FROMCRITERIA		int	NULL,
                                DEPTH			int	NOT NULL
                            )

declare	@nErrorCode	int
declare @sSQLString nvarchar(max)
declare @nChildCriteria int
declare @nReturnCode    int

-- Initialise variables
Set @nErrorCode = 0

-- Populate table with child criteria
If @nErrorCode = 0
Begin
        Insert into #ChildCriteria(CRITERIANO, FROMCRITERIA, DEPTH)
        select C.CRITERIANO, C.FROMCRITERIA, C.DEPTH
        from dbo.fn_GetChildCriteria(@pnCriteriaKey,0) C 
        where C.DEPTH > 1
        
        Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	If exists(Select 1 
				from CHECKLISTITEM 
				where CRITERIANO = @pnCriteriaKey
				and		QUESTIONNO = @pnQuestionKey)
	Begin

		Set @sSQLString = N'
		Update CHECKLISTITEM
			Set SEQUENCENO = @pnSequenceNo,
				QUESTION = @psQuestion,
				YESNOREQUIRED = @pnYesNoRequired,
				COUNTREQUIRED = @pnCountRequired,
				PERIODTYPEREQUIRED = @pnPeriodRequired,
				AMOUNTREQUIRED = @pnAmountRequired,
				EMPLOYEEREQUIRED = @pnEmployeeRequired,
				TEXTREQUIRED = @pnTextRequired,
				PAYFEECODE = @psPayFeeCode,
				UPDATEEVENTNO = @pnUpdateEventNo,
				DUEDATEFLAG = @pbYesDueDateFlag,
				YESRATENO = @pnYesRateNo,
				NORATENO = @pnNoRateNo,
				NODUEDATEFLAG = @pbNoDueDateFlag,
				NOEVENTNO	= @pnNoEventNo,
				ESTIMATEFLAG = @pbIsEstimate,			
				DIRECTPAYFLAG = @pbIsDirectPay,
				SOURCEQUESTION = @pnSourceQuestionKey,
				ANSWERSOURCEYES = @pnAnswerSourceYes,
				ANSWERSOURCENO = @pnAnswerSourceNo
			from CHECKLISTITEM CI
			where	CI.CRITERIANO = @pnCriteriaKey
			and		CI.QUESTIONNO = @pnQuestionKey
			and		CI.LOGDATETIMESTAMP = @pdtLastModifiedDate'
		
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnQuestionKey			smallint,	
						@pnCriteriaKey			int,		
						@pnSequenceNo			smallint,
						@psQuestion				nvarchar(100),
						@pnYesNoRequired		decimal(1,0),
						@pnCountRequired		decimal(1,0),
						@pnAmountRequired		decimal(1,0),
						@pnEmployeeRequired		decimal(1,0),
						@pnTextRequired			decimal(1,0),
						@pnPeriodRequired		decimal(1,0),
						@pnUpdateEventNo		int,
						@pnNoEventNo			int,
						@pbYesDueDateFlag		int,
						@pbNoDueDateFlag		int,
						@pnYesRateNo			int,
						@pnNoRateNo			int,
						@psPayFeeCode			nchar(2),
						@pbIsEstimate			decimal(1,0),
						@pbIsDirectPay			decimal(1,0),
						@pnSourceQuestionKey		smallint,
						@pnAnswerSourceYes		decimal(1,0),
						@pnAnswerSourceNo		decimal(1,0),
						@pdtLastModifiedDate		datetime',
						@pnQuestionKey			= @pnQuestionKey,	
						@pnCriteriaKey			= @pnCriteriaKey,		
						@pnSequenceNo			= @pnSequenceNo,
						@psQuestion				= @psQuestion,
						@pnYesNoRequired		= @pnYesNoRequired,
						@pnCountRequired		= @pnCountRequired,
						@pnAmountRequired		= @pnAmountRequired,
						@pnEmployeeRequired		= @pnEmployeeRequired,
						@pnTextRequired			= @pnTextRequired,
						@pnPeriodRequired		= @pnPeriodRequired,
						@pnUpdateEventNo		= @pnUpdateEventNo,
						@pnNoEventNo			= @pnNoEventNo,
						@pbYesDueDateFlag		= @pbYesDueDateFlag,
						@pbNoDueDateFlag		= @pbNoDueDateFlag,
						@pnYesRateNo			= @pnYesRateNo,
						@pnNoRateNo				= @pnNoRateNo,
						@psPayFeeCode			= @psPayFeeCode,
						@pbIsEstimate			= @pbIsEstimate,
						@pbIsDirectPay			= @pbIsDirectPay,
						@pnSourceQuestionKey	= @pnSourceQuestionKey,
						@pnAnswerSourceYes	= @pnAnswerSourceYes,
						@pnAnswerSourceNo	= @pnAnswerSourceNo,
						@pdtLastModifiedDate	= @pdtLastModifiedDate
						
		If @nErrorCode = 0
		and @pbPassToDescendants = 1
		Begin
		
		-- First delete existing CHECKLISTITEM if it will be INHERITED
	                Delete CI
		        from #ChildCriteria C
                        join CHECKLISTITEM CI on (CI.CRITERIANO=C.CRITERIANO)
                        left join CHECKLISTITEM CI2 on (CI2.CRITERIANO = @pnCriteriaKey and CI2.QUESTIONNO = CI.QUESTIONNO)
                        where C.FROMCRITERIA IS NOT NULL
                        and CI2.CRITERIANO IS NOT NULL
                        and CI2.QUESTIONNO = @pnQuestionKey
        		
		        Set @nErrorCode = @@Error
	        
	                If @nErrorCode = 0
	                Begin
                                Set @sSQLString = 
	                        N'INSERT CHECKLISTITEM (
		                CRITERIANO,
		                QUESTIONNO,
		                SEQUENCENO,
		                QUESTION,
		                YESNOREQUIRED,
		                COUNTREQUIRED,
		                PERIODTYPEREQUIRED,
		                AMOUNTREQUIRED,
		                EMPLOYEEREQUIRED,
		                TEXTREQUIRED,
		                PAYFEECODE,
		                UPDATEEVENTNO,
		                DUEDATEFLAG,
		                YESRATENO,
		                NORATENO,
		                NODUEDATEFLAG,
		                NOEVENTNO,
		                ESTIMATEFLAG,
		                DIRECTPAYFLAG,
		                SOURCEQUESTION,
		                ANSWERSOURCEYES,
		                ANSWERSOURCENO,
		                INHERITED
	                        )
	                        SELECT	
		                        C.CRITERIANO,
		                        @pnQuestionKey,
		                        @pnSequenceNo,
		                        @psQuestion,
		                        @pnYesNoRequired,
		                        @pnCountRequired,
		                        @pnPeriodRequired,
		                        @pnAmountRequired,
		                        @pnEmployeeRequired,
		                        @pnTextRequired,
		                        @psPayFeeCode,
		                        @pnUpdateEventNo,
		                        @pbYesDueDateFlag,
		                        @pnYesRateNo,
		                        @pnNoRateNo,
		                        @pbNoDueDateFlag,
		                        @pnNoEventNo,
		                        @pbIsEstimate,			
		                        @pbIsDirectPay,
		                        @pnSourceQuestionKey,
		                        @pnAnswerSourceYes,
		                        @pnAnswerSourceNo,
		                        1
	                        from #ChildCriteria C
	                        where C.FROMCRITERIA IS NOT NULL
	                        '
                	
	                        exec @nErrorCode = sp_executesql @sSQLString,
		 		                  N'@pnQuestionKey			smallint,	
					                @pnCriteriaKey			int,		
					                @pnSequenceNo			smallint,
					                @psQuestion			nvarchar(100),
					                @pnYesNoRequired		decimal(1,0),
					                @pnCountRequired		decimal(1,0),
					                @pnAmountRequired		decimal(1,0),
					                @pnEmployeeRequired		decimal(1,0),
					                @pnTextRequired			decimal(1,0),
					                @pnPeriodRequired		decimal(1,0),
					                @pnUpdateEventNo		int,
					                @pnNoEventNo			int,
					                @pbYesDueDateFlag		int,
					                @pbNoDueDateFlag		int,
					                @pnYesRateNo			int,
					                @pnNoRateNo			int,
					                @psPayFeeCode			nchar(2),
					                @pbIsEstimate			decimal(1,0),
					                @pbIsDirectPay			decimal(1,0),
					                @pnSourceQuestionKey		smallint,
					                @pnAnswerSourceYes		decimal(1,0),
					                @pnAnswerSourceNo		decimal(1,0)',
					                @pnQuestionKey			= @pnQuestionKey,	
					                @pnCriteriaKey			= @pnCriteriaKey,		
					                @pnSequenceNo			= @pnSequenceNo,
					                @psQuestion			= @psQuestion,
					                @pnYesNoRequired		= @pnYesNoRequired,
					                @pnCountRequired		= @pnCountRequired,
					                @pnAmountRequired		= @pnAmountRequired,
					                @pnEmployeeRequired		= @pnEmployeeRequired,
					                @pnTextRequired			= @pnTextRequired,
					                @pnPeriodRequired		= @pnPeriodRequired,
					                @pnUpdateEventNo		= @pnUpdateEventNo,
					                @pnNoEventNo			= @pnNoEventNo,
					                @pbYesDueDateFlag		= @pbYesDueDateFlag,
					                @pbNoDueDateFlag		= @pbNoDueDateFlag,
					                @pnYesRateNo			= @pnYesRateNo,
					                @pnNoRateNo			= @pnNoRateNo,
					                @psPayFeeCode			= @psPayFeeCode,
					                @pbIsEstimate			= @pbIsEstimate,
					                @pbIsDirectPay			= @pbIsDirectPay,
					                @pnSourceQuestionKey		= @pnSourceQuestionKey,
					                @pnAnswerSourceYes		= @pnAnswerSourceYes,
					                @pnAnswerSourceNo		= @pnAnswerSourceNo
		                    End
		End
	End
	Else
	Begin
		Set @sSQLString = 
		N'INSERT CHECKLISTITEM (
			CRITERIANO,
			QUESTIONNO,
			SEQUENCENO,
			QUESTION,
			YESNOREQUIRED,
			COUNTREQUIRED,
			PERIODTYPEREQUIRED,
			AMOUNTREQUIRED,
			EMPLOYEEREQUIRED,
			TEXTREQUIRED,
			PAYFEECODE,
			UPDATEEVENTNO,
			DUEDATEFLAG,
			YESRATENO,
			NORATENO,
			NODUEDATEFLAG,
			NOEVENTNO,
			ESTIMATEFLAG,
			DIRECTPAYFLAG,
			SOURCEQUESTION,
			ANSWERSOURCEYES,
			ANSWERSOURCENO
		)
		values 
		(	
			@pnCriteriaKey,
			@pnQuestionKey,
			@pnSequenceNo,
			@psQuestion,
			@pnYesNoRequired,
			@pnCountRequired,
			@pnPeriodRequired,
			@pnAmountRequired,
			@pnEmployeeRequired,
			@pnTextRequired,
			@psPayFeeCode,
			@pnUpdateEventNo,
			@pbYesDueDateFlag,
			@pnYesRateNo,
			@pnNoRateNo,
			@pbNoDueDateFlag,
			@pnNoEventNo,
			@pbIsEstimate,			
			@pbIsDirectPay,
			@pnSourceQuestionKey,
			@pnAnswerSourceYes,
			@pnAnswerSourceNo
		)'
		
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pnQuestionKey			smallint,	
						@pnCriteriaKey			int,		
						@pnSequenceNo			smallint,
						@psQuestion			nvarchar(100),
						@pnYesNoRequired		decimal(1,0),
						@pnCountRequired		decimal(1,0),
						@pnAmountRequired		decimal(1,0),
						@pnEmployeeRequired		decimal(1,0),
						@pnTextRequired			decimal(1,0),
						@pnPeriodRequired		decimal(1,0),
						@pnUpdateEventNo		int,
						@pnNoEventNo			int,
						@pbYesDueDateFlag		int,
						@pbNoDueDateFlag		int,
						@pnYesRateNo			int,
						@pnNoRateNo			int,
						@psPayFeeCode			nchar(2),
						@pbIsEstimate			decimal(1,0),
						@pbIsDirectPay			decimal(1,0),
						@pnSourceQuestionKey		smallint,
						@pnAnswerSourceYes		decimal(1,0),
						@pnAnswerSourceNo		decimal(1,0)',
						@pnQuestionKey			= @pnQuestionKey,	
						@pnCriteriaKey			= @pnCriteriaKey,		
						@pnSequenceNo			= @pnSequenceNo,
						@psQuestion			= @psQuestion,
						@pnYesNoRequired		= @pnYesNoRequired,
						@pnCountRequired		= @pnCountRequired,
						@pnAmountRequired		= @pnAmountRequired,
						@pnEmployeeRequired		= @pnEmployeeRequired,
						@pnTextRequired			= @pnTextRequired,
						@pnPeriodRequired		= @pnPeriodRequired,
						@pnUpdateEventNo		= @pnUpdateEventNo,
						@pnNoEventNo			= @pnNoEventNo,
						@pbYesDueDateFlag		= @pbYesDueDateFlag,
						@pbNoDueDateFlag		= @pbNoDueDateFlag,
						@pnYesRateNo			= @pnYesRateNo,
						@pnNoRateNo			= @pnNoRateNo,
						@psPayFeeCode			= @psPayFeeCode,
						@pbIsEstimate			= @pbIsEstimate,
						@pbIsDirectPay			= @pbIsDirectPay,
						@pnSourceQuestionKey		= @pnSourceQuestionKey,
						@pnAnswerSourceYes		= @pnAnswerSourceYes,
						@pnAnswerSourceNo		= @pnAnswerSourceNo
	
	        If @nErrorCode = 0
	        and @pbPassToDescendants = 1
	        Begin
	                -- First delete existing CHECKLISTITEM if it will be INHERITED
	                Delete CI
		        from #ChildCriteria C
                        join CHECKLISTITEM CI on (CI.CRITERIANO=C.CRITERIANO)
                        left join CHECKLISTITEM CI2 on (CI2.CRITERIANO = @pnCriteriaKey and CI2.QUESTIONNO = CI.QUESTIONNO)
                        where C.FROMCRITERIA IS NOT NULL
                        and CI2.CRITERIANO IS NOT NULL
                        and CI2.QUESTIONNO = @pnQuestionKey
        		
		        Set @nErrorCode = @@Error
	        
	                If @nErrorCode = 0
	                Begin
                                Set @sSQLString = 
	                        N'INSERT CHECKLISTITEM (
		                CRITERIANO,
		                QUESTIONNO,
		                SEQUENCENO,
		                QUESTION,
		                YESNOREQUIRED,
		                COUNTREQUIRED,
		                PERIODTYPEREQUIRED,
		                AMOUNTREQUIRED,
		                EMPLOYEEREQUIRED,
		                TEXTREQUIRED,
		                PAYFEECODE,
		                UPDATEEVENTNO,
		                DUEDATEFLAG,
		                YESRATENO,
		                NORATENO,
		                NODUEDATEFLAG,
		                NOEVENTNO,
		                ESTIMATEFLAG,
		                DIRECTPAYFLAG,
		                SOURCEQUESTION,
		                ANSWERSOURCEYES,
		                ANSWERSOURCENO,
		                INHERITED
	                        )
	                        SELECT	
		                        C.CRITERIANO,
		                        @pnQuestionKey,
		                        @pnSequenceNo,
		                        @psQuestion,
		                        @pnYesNoRequired,
		                        @pnCountRequired,
		                        @pnPeriodRequired,
		                        @pnAmountRequired,
		                        @pnEmployeeRequired,
		                        @pnTextRequired,
		                        @psPayFeeCode,
		                        @pnUpdateEventNo,
		                        @pbYesDueDateFlag,
		                        @pnYesRateNo,
		                        @pnNoRateNo,
		                        @pbNoDueDateFlag,
		                        @pnNoEventNo,
		                        @pbIsEstimate,			
		                        @pbIsDirectPay,
		                        @pnSourceQuestionKey,
		                        @pnAnswerSourceYes,
		                        @pnAnswerSourceNo,
		                        1
	                        from #ChildCriteria C
	                        where C.FROMCRITERIA IS NOT NULL
	                        '
                	
	                        exec @nErrorCode = sp_executesql @sSQLString,
		 		                  N'@pnQuestionKey			smallint,	
					                @pnCriteriaKey			int,		
					                @pnSequenceNo			smallint,
					                @psQuestion			nvarchar(100),
					                @pnYesNoRequired		decimal(1,0),
					                @pnCountRequired		decimal(1,0),
					                @pnAmountRequired		decimal(1,0),
					                @pnEmployeeRequired		decimal(1,0),
					                @pnTextRequired			decimal(1,0),
					                @pnPeriodRequired		decimal(1,0),
					                @pnUpdateEventNo		int,
					                @pnNoEventNo			int,
					                @pbYesDueDateFlag		int,
					                @pbNoDueDateFlag		int,
					                @pnYesRateNo			int,
					                @pnNoRateNo			int,
					                @psPayFeeCode			nchar(2),
					                @pbIsEstimate			decimal(1,0),
					                @pbIsDirectPay			decimal(1,0),
					                @pnSourceQuestionKey		smallint,
					                @pnAnswerSourceYes		decimal(1,0),
					                @pnAnswerSourceNo		decimal(1,0)',
					                @pnQuestionKey			= @pnQuestionKey,	
					                @pnCriteriaKey			= @pnCriteriaKey,		
					                @pnSequenceNo			= @pnSequenceNo,
					                @psQuestion			= @psQuestion,
					                @pnYesNoRequired		= @pnYesNoRequired,
					                @pnCountRequired		= @pnCountRequired,
					                @pnAmountRequired		= @pnAmountRequired,
					                @pnEmployeeRequired		= @pnEmployeeRequired,
					                @pnTextRequired			= @pnTextRequired,
					                @pnPeriodRequired		= @pnPeriodRequired,
					                @pnUpdateEventNo		= @pnUpdateEventNo,
					                @pnNoEventNo			= @pnNoEventNo,
					                @pbYesDueDateFlag		= @pbYesDueDateFlag,
					                @pbNoDueDateFlag		= @pbNoDueDateFlag,
					                @pnYesRateNo			= @pnYesRateNo,
					                @pnNoRateNo			= @pnNoRateNo,
					                @psPayFeeCode			= @psPayFeeCode,
					                @pbIsEstimate			= @pbIsEstimate,
					                @pbIsDirectPay			= @pbIsDirectPay,
					                @pnSourceQuestionKey		= @pnSourceQuestionKey,
					                @pnAnswerSourceYes		= @pnAnswerSourceYes,
					                @pnAnswerSourceNo		= @pnAnswerSourceNo
		        End
	        End
						
	End
	
	If (@nErrorCode = 0
	and @@ROWCOUNT > 0)
	Begin
		Set @sSQLString = N'
		Select @pbIsInherited = isnull(I.CRITERIANO, 0)
		from CHECKLISTITEM CI
		/* find identical rule */		
		left join CHECKLISTITEM CIPARENT on (
								CIPARENT.QUESTIONNO = CI.QUESTIONNO
								and CIPARENT.QUESTION = CI.QUESTION
								and	CIPARENT.SEQUENCENO = CI.SEQUENCENO
								and CIPARENT.YESNOREQUIRED = CI.YESNOREQUIRED
								and CIPARENT.COUNTREQUIRED = CI.COUNTREQUIRED
								and CIPARENT.PERIODTYPEREQUIRED = CI.PERIODTYPEREQUIRED
								and CIPARENT.AMOUNTREQUIRED = CI.AMOUNTREQUIRED
								and CIPARENT.EMPLOYEEREQUIRED = CI.EMPLOYEEREQUIRED
								and CIPARENT.TEXTREQUIRED = CI.TEXTREQUIRED
								and CIPARENT.PAYFEECODE = CI.PAYFEECODE
								and CIPARENT.UPDATEEVENTNO = CI.UPDATEEVENTNO
								and CIPARENT.DUEDATEFLAG = CI.DUEDATEFLAG
								and CIPARENT.YESRATENO = CI.YESRATENO
								and CIPARENT.NORATENO = CI.NORATENO
								and CIPARENT.NODUEDATEFLAG = CI.NODUEDATEFLAG
								and CIPARENT.NOEVENTNO = CI.NOEVENTNO
								and CIPARENT.ESTIMATEFLAG = CI.ESTIMATEFLAG
								and CIPARENT.DIRECTPAYFLAG = CI.DIRECTPAYFLAG
								and CIPARENT.SOURCEQUESTION = CI.SOURCEQUESTION
								and CIPARENT.ANSWERSOURCEYES = CI.ANSWERSOURCEYES
								and CIPARENT.ANSWERSOURCENO = CI.ANSWERSOURCENO)
		/* that it inherits from */			
		left join INHERITS I on (I.CRITERIANO = CI.CRITERIANO
							and  I.FROMCRITERIA = CIPARENT.CRITERIANO)
		where	CI.CRITERIANO = @pnCriteriaKey
		and		CI.QUESTIONNO = @pnQuestionKey
		'
		exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pbIsInherited			decimal(1,0) output,
			 			@pnQuestionKey			smallint,	
						@pnCriteriaKey			int,		
						@pnSequenceNo			smallint,
						@psQuestion				nvarchar(100),
						@pnYesNoRequired		decimal(1,0),
						@pnCountRequired		decimal(1,0),
						@pnAmountRequired		decimal(1,0),
						@pnEmployeeRequired		decimal(1,0),
						@pnTextRequired			decimal(1,0),
						@pnPeriodRequired		decimal(1,0),
						@pnUpdateEventNo		int,
						@pnNoEventNo			int,
						@pbYesDueDateFlag		int,
						@pbNoDueDateFlag		int,
						@pnYesRateNo			int,
						@pnNoRateNo				int,
						@psPayFeeCode			nchar(2),
						@pbIsEstimate			decimal(1,0),
						@pbIsDirectPay			decimal(1,0),
						@pnSourceQuestionKey		smallint,
						@pnAnswerSourceYes		decimal(1,0),
						@pnAnswerSourceNo		decimal(1,0)',
						@pbIsInherited			= @pbIsInherited output,
						@pnQuestionKey			= @pnQuestionKey,	
						@pnCriteriaKey			= @pnCriteriaKey,		
						@pnSequenceNo			= @pnSequenceNo,
						@psQuestion				= @psQuestion,
						@pnYesNoRequired		= @pnYesNoRequired,
						@pnCountRequired		= @pnCountRequired,
						@pnAmountRequired		= @pnAmountRequired,
						@pnEmployeeRequired		= @pnEmployeeRequired,
						@pnTextRequired			= @pnTextRequired,
						@pnPeriodRequired		= @pnPeriodRequired,
						@pnUpdateEventNo		= @pnUpdateEventNo,
						@pnNoEventNo			= @pnNoEventNo,
						@pbYesDueDateFlag		= @pbYesDueDateFlag,
						@pbNoDueDateFlag		= @pbNoDueDateFlag,
						@pnYesRateNo			= @pnYesRateNo,
						@pnNoRateNo				= @pnNoRateNo,
						@psPayFeeCode			= @psPayFeeCode,
						@pbIsEstimate			= @pbIsEstimate,
						@pbIsDirectPay			= @pbIsDirectPay,
						@pnSourceQuestionKey		= @pnSourceQuestionKey,
						@pnAnswerSourceYes		= @pnAnswerSourceYes,
						@pnAnswerSourceNo		= @pnAnswerSourceNo
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString = N'
				Update CHECKLISTITEM 
					Set INHERITED = @pbIsInherited
				where	CRITERIANO = @pnCriteriaKey
				and		QUESTIONNO = @pnQuestionKey
			'
			
			exec @nErrorCode = sp_executesql @sSQLString,
			 		  N'@pbIsInherited			decimal(1,0),
			 			@pnQuestionKey			smallint,	
						@pnCriteriaKey			int',		
						@pbIsInherited			= @pbIsInherited,
						@pnQuestionKey			= @pnQuestionKey,	
						@pnCriteriaKey			= @pnCriteriaKey	
		End
	End
	
	If @nErrorCode = 0
	Begin
	        -- Re-allocate SequenceNos for checklist items that have been inherited
                DECLARE ChecklistItem_Cursor CURSOR FOR 
	        SELECT C.CRITERIANO
	        FROM #ChildCriteria C
	        
                OPEN ChecklistItem_Cursor

                FETCH NEXT FROM ChecklistItem_Cursor 
                INTO @nChildCriteria
                WHILE (@nErrorCode = 0 and @@FETCH_STATUS = 0)
                Begin
                        
                        exec dbo.ipr_ArrangeChecklistItemSeq @nChildCriteria, @pnQuestionKey, @nReturnCode output
                
                        Set @nErrorCode = @nReturnCode
                        
        	        FETCH NEXT FROM ChecklistItem_Cursor 
	                INTO @nChildCriteria
                End

                CLOSE ChecklistItem_Cursor
                DEALLOCATE ChecklistItem_Cursor
        
        End
        
End

Drop Table #ChildCriteria

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainChecklistItem to public
GO
