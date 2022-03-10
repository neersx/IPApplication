
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_CaseTextChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_CaseTextChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_CaseTextChange.'
	Drop procedure [dbo].[csw_CaseTextChange]
End
Print '**** Creating Stored Procedure dbo.csw_CaseTextChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_CaseTextChange]  
(
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psTextTypeCode			nvarchar(2)	= null, -- TextTypeCode
	@psText				nvarchar(max)	= null,	-- TextTypeDesc  
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure	
	@pnRequestNo			int		= null  -- Global Name Change Request No.
)
AS
-- PROCEDURE:	csw_CaseTextChange
-- VERSION:	4
-- DESCRIPTION:	This stored procedure will be called by csw_GlobalNameChange. This procedure is used
-- to update the CaseText for all the cases selected. 
-- COPYRIGHT:	Copyright 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number  Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 03 Nov 2008  MS	RFC5698	1	Procedure created 
-- 14 May 2012  MS      R12294  2       Fix logic to append notes rather than replacing it
-- 03 Jul 2012	LP	R12446	3	Remove use of global temp table for CaseIds. Pass RequestNo instead.
-- 09 Jul 2013	DV	R13722	4	Fixed issue where quotes in casetext was throwing an error

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON

Declare @sSQLString     nvarchar(max)
Declare @tCurrentTable  nvarchar(100)
Declare @nErrorCode	int
Declare @bLongFlag      bit
Declare @bKeepHistory   bit
Declare @sStaffCode	nvarchar(10)
Declare @dtLastModified datetime

-- Initialise variables
Set @nErrorCode  = 0
Set @bKeepHistory = 0
Set @dtLastModified = getdate()
Set @bLongFlag = CASE WHEN DATALENGTH(@psText) <= 508 THEN 0 ELSE 1 END

-- Get the NAMECODE for the current user
If @nErrorCode = 0
Begin
	Select @sStaffCode = N.NAMECODE
	from NAME N
	join USERIDENTITY U on (U.NAMENO = N.NAMENO)
	where U.IDENTITYID = @pnUserIdentityId
	
	Set @nErrorCode = @@ERROR
End

-- Check the KEEPSPECIHISTORY site control to see if we should insert or update
If @nErrorCode = 0 
Begin
	set @sSQLString = "Select @bKeepHistory = COLBOOLEAN
			from SITECONTROL WHERE CONTROLID = 'KEEPSPECIHISTORY'"
			
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@bKeepHistory	bit OUTPUT',
			@bKeepHistory = @bKeepHistory OUTPUT
End

If @nErrorCode = 0
Begin
        -- No history required for case text updates
        If @bKeepHistory = 0
	Begin		                      
	        Set @sSQLString = "Update CASETEXT
		Set MODIFIEDDATE  = @dtLastModified,
		LONGFLAG          = CASE WHEN C.LONGFLAG = 1 THEN 1 
		                         WHEN @bLongFlag = 1 THEN 1
		                         WHEN DATALENGTH(@psText + CHAR(13) + C.SHORTTEXT) > 508 THEN 1
		                         ELSE 0 END,
		SHORTTEXT 	  = CASE WHEN C.LONGFLAG = 0 THEN  
		                        CASE WHEN DATALENGTH(@psText + CHAR(13) + C.SHORTTEXT) > 508 THEN NULL 
		                             ELSE  @psText + CHAR(13) + C.SHORTTEXT END 
		                        ELSE NULL END,
		TEXT  	          = CASE WHEN C.LONGFLAG = 1 THEN  @psText + CHAR(13) + cast(C.TEXT as nvarchar(max)) 
		                         WHEN @bLongFlag = 1 THEN  @psText + CHAR(13) + C.SHORTTEXT 
		                         WHEN DATALENGTH(@psText + CHAR(13) + C.SHORTTEXT) > 508 THEN  @psText + CHAR(13) + C.SHORTTEXT
		                         ELSE NULL END
		from CASETEXT C
		join CASENAMEREQUESTCASES CS on (CS.CASEID = C.CASEID and CS.REQUESTNO = @pnRequestNo)
		where C.TEXTTYPE = @psTextTypeCode
		and C.LANGUAGE is null
		and C.CLASS is null
		and C.TEXTNO = (SELECT MAX(CT2.TEXTNO) from CASETEXT CT2
				where CT2.CASEID = CS.CASEID
				and CT2.TEXTTYPE = @psTextTypeCode
				and CT2.CLASS is null
				and CT2.LANGUAGE is null)"  
							             	
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@dtLastModified       datetime,
		        @psTextTypeCode         nvarchar(2),
		        @bLongFlag              bit,
		        @pnRequestNo		int,
		        @psText				nvarchar(max)',
		        @dtLastModified         = @dtLastModified,
		        @psTextTypeCode         = @psTextTypeCode,
		        @bLongFlag              = @bLongFlag,
		        @pnRequestNo		= @pnRequestNo,	
		        @psText				= @psText	
        End
	Else 
	-- case text updates are kept historically
	Begin	      
	        Set @sSQLString = "
		INSERT INTO CASETEXT(
		        CASEID, 
		        TEXTTYPE, 
		        TEXTNO, 
		        CLASS, 
		        LANGUAGE, 
		        MODIFIEDDATE, 
		        LONGFLAG, 
		        SHORTTEXT, 
		        TEXT)
		SELECT C.CASEID, 
		        @psTextTypeCode, 
		        ISNULL((SELECT MAX(TEXTNO) + 1 FROM CASETEXT WHERE CASEID = C.CASEID AND TEXTTYPE = C.TEXTTYPE), 0), 
		        null, 
		        null, 
		        @dtLastModified, 
		        CASE WHEN C.LONGFLAG = 1 THEN 1 
		             WHEN @bLongFlag = 1 THEN 1
		             WHEN DATALENGTH( @psText + CHAR(13) + C.SHORTTEXT) > 508 THEN 1
		             ELSE 0 END, 
		        CASE WHEN C.LONGFLAG = 0 THEN  
		             CASE WHEN DATALENGTH( @psText + CHAR(13) + C.SHORTTEXT) > 508 THEN NULL 
		                  ELSE   @psText + CHAR(13) + C.SHORTTEXT END 
		             ELSE NULL END, 
			CASE WHEN C.LONGFLAG = 1 THEN  @psText + CHAR(13) + cast(C.TEXT as nvarchar(max)) 
		             WHEN @bLongFlag = 1 THEN  @psText + CHAR(13) + C.SHORTTEXT 
		             WHEN DATALENGTH( @psText + CHAR(13) + C.SHORTTEXT) > 508 THEN  @psText + CHAR(13) + C.SHORTTEXT
		             ELSE NULL END
		FROM CASETEXT C
		join CASENAMEREQUESTCASES CS on (CS.CASEID = C.CASEID and CS.REQUESTNO = @pnRequestNo)
		where C.TEXTTYPE = @psTextTypeCode
		and C.TEXTNO = ISNULL((SELECT MAX(TEXTNO)FROM CASETEXT WHERE CASEID = C.CASEID AND TEXTTYPE = C.TEXTTYPE), 0)"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		        N'@dtLastModified       datetime,
		        @psTextTypeCode         nvarchar(2),
		        @bLongFlag              bit,
		        @pnRequestNo		int,
				@psText				nvarchar(max)',
		        @dtLastModified         = @dtLastModified,
		        @psTextTypeCode         = @psTextTypeCode,
		        @bLongFlag              = @bLongFlag,
		        @pnRequestNo		= @pnRequestNo,
		        @psText				= @psText
        End
End
	        
-- Now insert new text for cases without specified case text type
If @nErrorCode = 0
Begin		
                        
        Set @sSQLString = '
	        INSERT INTO CASETEXT(
	                CASEID, 
	                TEXTTYPE, 
	                TEXTNO, 
	                CLASS, 
	                LANGUAGE, 
	                MODIFIEDDATE, 
	                LONGFLAG, 
	                SHORTTEXT, 
	                TEXT)
	        SELECT C.CASEID, 
	                @psTextTypeCode, 
	                ISNULL((SELECT MAX(CT.TEXTNO) + 1 
	                        FROM CASETEXT CT
	                        join CASES CA on (CT.CASEID = CA.CASEID)
	                        WHERE CT.CASEID = CS.CASEID  
	                        AND CT.TEXTTYPE = @psTextTypeCode), 0), 
			null, 
			null, 
			@dtLastModified, 
			@bLongFlag, 
	                CASE @bLongFlag WHEN 0 THEN @psText ELSE NULL END, 
	                CASE @bLongFlag WHEN 1 THEN @psText ELSE NULL END
	        FROM CASES C
	        join CASENAMEREQUESTCASES CS on (CS.CASEID = C.CASEID and CS.REQUESTNO = @pnRequestNo)
		where C.CASEID not in (SELECT DISTINCT CT.CASEID from CASETEXT CT
		                        join CASENAMEREQUESTCASES CS on (CS.CASEID = CT.CASEID and CS.REQUESTNO = @pnRequestNo)
	                                where CT.TEXTTYPE = @psTextTypeCode
	                                and (CT.CLASS is null)
	                                and (CT.LANGUAGE is null))'
	                                
        exec @nErrorCode = sp_executesql @sSQLString,
	           N'@dtLastModified    datetime,
	           @psTextTypeCode      nvarchar(2),
	           @bLongFlag           bit,
	           @psText		nvarchar(max),
	           @pnRequestNo		int',
	           @dtLastModified      = @dtLastModified,
	           @psTextTypeCode      = @psTextTypeCode,
	           @bLongFlag           = @bLongFlag,
	           @psText		= @psText,
	           @pnRequestNo		= @pnRequestNo
End
		
Return @nErrorCode
GO

Grant execute on dbo.csw_CaseTextChange to public
GO


