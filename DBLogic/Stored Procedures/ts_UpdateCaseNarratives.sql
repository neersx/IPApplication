---------------------------------------------------------------------------------------------
-- Creation of dbo.ts_UpdateCaseNarratives
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_UpdateCaseNarratives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_UpdateCaseNarratives.'
	drop procedure [dbo].[ts_UpdateCaseNarratives]
	Print '**** Creating Stored Procedure dbo.ts_UpdateCaseNarratives...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_UpdateCaseNarratives
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.	
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,	        -- Mandatory
	@pnStaffKey		int,            -- Mandatory
	@pnEntryNo              int             = null,
	@pnEntityNo             int             = null,
	@pnTransNo              int             = null,
	@pnNarrativeKey         int             = null,
	@psNarrative            nvarchar(max)   = null,
	@pbIsPosted             bit             = 0,
	@pdtLogDateTimeStamp    datetime        = null
)
AS
-- PROCEDURE:	ts_UpdateCaseNarratives
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Update the Case narratives entered in timesheet.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Jan 2013  MS	R12396	1	Procedure created
-- 23 May 2013  MS      R12396  2       Fix issue with WORKINPROGRESS table update with Long text

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @nNarrativeKey          int
Declare @bLongFlag              bit
Declare @nShortNarrativeTID     int
Declare @nLongNarrativeTID      int
Declare @nTID                   int

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode     = 0

-- Is the Narrative long text?
Set @bLongFlag = CASE WHEN (datalength(@psNarrative) <= 508)
                                or datalength(@psNarrative) is null THEN 0 ELSE 1 END

If  @nErrorCode = 0
Begin
        if @sLookupCulture is not null and @psNarrative is not null
	Begin
                Set @sSQLString = "
			        Select @nShortNarrativeTID = SHORTNARRATIVE_TID,
			        @nLongNarrativeTID = LONGNARRATIVE_TID
			        FROM DIARY
			        WHERE CASEID = @pnCaseKey
	                        AND EMPLOYEENO = @pnStaffKey
	                        AND ENTRYNO = @pnEntryNo"
        		
		exec @nErrorCode=sp_executesql @sSQLString,
                         N'@nShortNarrativeTID	int     output,
			 @nLongNarrativeTID     int     output,
			 @pnStaffKey	        int,
			 @pnCaseKey	        int,
			 @pnEntryNo             int',
			 @nShortNarrativeTID    = @nShortNarrativeTID   output,
			 @nLongNarrativeTID     = @nLongNarrativeTID    output,
			 @pnStaffKey	        = @pnStaffKey,
			 @pnCaseKey	        = @pnCaseKey,
			 @pnEntryNo             = @pnEntryNo       		
                
			        
		If @nErrorCode = 0
		Begin
		        exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			        @pnUserIdentityId	= @pnUserIdentityId,
			        @psCulture		= @sLookupCulture,
			        @psTableName		= "DIARY",	        -- Mandatory
			        @psTIDColumnName	= "SHORTNARRATIVE_TID",	-- Mandatory
			        @psText			= @psNarrative,
			        @pnTID			= @nShortNarrativeTID
			        
		        exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			        @pnUserIdentityId	= @pnUserIdentityId,
			        @psCulture		= @sLookupCulture,
			        @psTableName		= "DIARY",	        -- Mandatory
			        @psTIDColumnName	= "LONGNARRATIVE_TID",	-- Mandatory
			        @psText			= @psNarrative,
			        @pnTID			= @nLongNarrativeTID
		End
	End
	ELSE 
	BEGIN
	        Set @sSQLString = "UPDATE DIARY
	                SET NARRATIVENO = @pnNarrativeKey,
                        SHORTNARRATIVE = CASE WHEN @bLongFlag = 0 THEN @psNarrative ELSE NULL END,
	                LONGNARRATIVE = CASE WHEN @bLongFlag = 1 THEN @psNarrative ELSE NULL END
	        WHERE CASEID = @pnCaseKey
	        AND EMPLOYEENO = @pnStaffKey
	        AND ENTRYNO = @pnEntryNo
	        AND (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (@pdtLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"
        	
	        exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pnCaseKey		int,
			  @pnEntryNo            int,
			  @bLongFlag            bit,
			  @pnNarrativeKey       int,
			  @psNarrative          nvarchar(max),
			  @pdtLogDateTimeStamp  datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pnCaseKey		= @pnCaseKey,
			  @pnEntryNo            = @pnEntryNo,
			  @bLongFlag            = @bLongFlag,
			  @pnNarrativeKey       = @pnNarrativeKey,
			  @psNarrative          = @psNarrative,
			  @pdtLogDateTimeStamp  = @pdtLogDateTimeStamp
        End
End 

If @nErrorCode = 0 and @pbIsPosted = 1
Begin
        If @nErrorCode = 0 and
	exists (select * from WORKINPROGRESS
		WHERE ENTITYNO = @pnEntityNo
		and	TRANSNO = @pnTransNo
		and	WIPSEQNO = 1
		and ((NARRATIVENO != @pnNarrativeKey OR (NARRATIVENO is null and @pnNarrativeKey is null))
		       OR (ISNULL(SHORTNARRATIVE,LONGNARRATIVE) != @psNarrative 
		                OR (ISNULL(SHORTNARRATIVE,LONGNARRATIVE) is null and @psNarrative is null))
		     ))
        Begin	        
	        -- Just update the debit note text and narrative. No transaction required.
	        if @nErrorCode = 0 and @sLookupCulture is not null and @psNarrative is not null
	        Begin
	                Set @sSQLString = '
			        Select  @nShortNarrativeTID = SHORTNARRATIVE_TID,
			                @nLongNarrativeTID = LONGNARRATIVE_TID
			        FROM WORKINPROGRESS
			        WHERE ENTITYNO = @pnEntityNo
			        and TRANSNO = @pnTransNo
			        and WIPSEQNO = 1'
        		
		        exec @nErrorCode=sp_executesql @sSQLString,
                                 N'@nShortNarrativeTID	int     output,
			         @nLongNarrativeTID     int     output,
			         @pnEntityNo	        int,
				 @pnTransNo	        int',
			         @nShortNarrativeTID    = @nShortNarrativeTID   output,
			         @nLongNarrativeTID     = @nLongNarrativeTID    output,
			         @pnEntityNo            = @pnEntityNo,
				 @pnTransNo             = @pnTransNo
                	
                	If @nErrorCode = 0
		        Begin	
                                exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			                @pnUserIdentityId	= @pnUserIdentityId,
			                @psCulture		= @sLookupCulture,
			                @psTableName		= "WORKINPROGRESS",	-- Mandatory
			                @psTIDColumnName	= "SHORTNARRATIVE_TID",	-- Mandatory
			                @psText			= @psNarrative,
			                @pnTID			= @nShortNarrativeTID
        			        
		        
		                exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			                @pnUserIdentityId	= @pnUserIdentityId,
			                @psCulture		= @sLookupCulture,
			                @psTableName		= "WORKINPROGRESS",	-- Mandatory
			                @psTIDColumnName	= "LONGNARRATIVE_TID",	-- Mandatory
			                @psText			= @psNarrative,
			                @pnTID			= @nLongNarrativeTID
		        End
        		
		        
	        End
	        Else if @nErrorCode = 0
	        Begin        		
		        Set @sSQLString = "
			        update WORKINPROGRESS SET NARRATIVENO = @pnNarrativeKey,
			                SHORTNARRATIVE = CASE WHEN @bLongFlag = 0 THEN @psNarrative ELSE NULL END,
	                                LONGNARRATIVE = CASE WHEN @bLongFlag = 1 THEN @psNarrative ELSE NULL END
			        WHERE ENTITYNO = @pnEntityNo
			        and	TRANSNO = @pnTransNo
			        and	WIPSEQNO = 1"
        		
		        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@pnNarrativeKey	int,
				        @bLongFlag              bit,
				        @psNarrative	        nvarchar(max),
				        @pnEntityNo		int,
				        @pnTransNo		int',
				        @pnNarrativeKey         = @pnNarrativeKey,
				        @bLongFlag              = @bLongFlag,
				        @psNarrative            = @psNarrative,
				        @pnEntityNo             = @pnEntityNo,
				        @pnTransNo              = @pnTransNo
	        End
        	
	        if @nErrorCode = 0 and 
		        @sLookupCulture is not null and @psNarrative is not null
	        Begin

		        Set @sSQLString = "
			        Select @nTID = NARRATIVE_TID
			        FROM WORKHISTORY
			        WHERE ENTITYNO = @pnEntityNo
			        and	TRANSNO = @pnTransNo
			        and	WIPSEQNO = 1"
        		
		        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@nTID		int output,
				        @pnEntityNo	int,
				        @pnTransNo	int',
				        @nTID           = @nTID output,
				        @pnEntityNo     = @pnEntityNo,
				        @pnTransNo      = @pnTransNo
				        
        		if @nErrorCode = 0
        		Begin
		        exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			        @pnUserIdentityId	= @pnUserIdentityId,
			        @psCulture		= @sLookupCulture,
			        @psTableName		= "WORKHISTORY",	-- Mandatory
			        @psTIDColumnName	= "NARRATIVE_TID",	-- Mandatory
			        @psText			= @psNarrative,
			        @pnTID			= @nTID
		        End
	        End
	        Else if @nErrorCode = 0
	        Begin
	                Set @sSQLString = "
			        update WORKHISTORY SET NARRATIVENO = @pnNarrativeKey,
		                        SHORTNARRATIVE = CASE WHEN @bLongFlag = 0 THEN @psNarrative ELSE NULL END,
	                                LONGNARRATIVE = CASE WHEN @bLongFlag = 1 THEN @psNarrative ELSE NULL END
		                WHERE ENTITYNO = @pnEntityNo
		                and	TRANSNO = @pnTransNo
		                and	WIPSEQNO = 1"
        		
		        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@pnNarrativeKey	int,
				        @bLongFlag              bit,
				        @psNarrative	        nvarchar(max),
				        @pnEntityNo		int,
				        @pnTransNo		int',
				        @pnNarrativeKey         = @pnNarrativeKey,
				        @bLongFlag              = @bLongFlag,
				        @psNarrative            = @psNarrative,
				        @pnEntityNo             = @pnEntityNo,
				        @pnTransNo              = @pnTransNo
				        
		        
	        End
        End
End

Return @nErrorCode
GO

Grant exec on dbo.ts_UpdateCaseNarratives to public
GO
