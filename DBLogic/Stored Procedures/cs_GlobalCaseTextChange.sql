-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalCaseTextChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalCaseTextChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalCaseTextChange.'
	Drop procedure [dbo].[cs_GlobalCaseTextChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalCaseTextChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalCaseTextChange
(
	@pnResults		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessId		int,		-- Identifier for the background process request
	@psGlobalTempTable	nvarchar(50),	
	@pbDebugFlag            bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@psErrorMsg nvarchar(max) = null output
)
as
-- PROCEDURE:	cs_GlobalCaseTextChange
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts/updates Case Text against the specified case. 
--              No concurrency checking. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 31 Mar 2010  LP      RFC5730   1     Procedure created.
-- 06 May 2010	LP	RFC5730	  2	New options to append to or replace existing text.
-- 14 Oct 2010	LP	RFC9321	  3	Extended to process cases in bulk.
--					Use nvarchar(max) instead of ntext.
-- 05 Nov 2010	LP	RFC9321	  4	Update tables containing results for Global Case Change.
-- 09 Dec 2010	LP	RFC10085  5	Fix logic to append/replace text independent of KEEPSPECIHISTORY site control.
-- 15 Mar 2011  LP      RFC10087  6      Fix logic when KEEPSPECIHISTORY site control is Off.
-- 17 Mar 2011  LP      RFC100488 7     Fix incorrect join to CASES when KEEPSPECIHISTORY site control is Off.
-- 21 Sep 2012  MS      R12780    8     Display old text in newline and correct logic of calculating LONGFLAG
-- 21 Sep 2012  MS      R12761    9     Display old text in newline and correct logic of calculating LONGFLAG
-- 13 Sep 2013  SW      DR783     10    Fixed Case Text truncate in Global Field Update
-- 28 Oct 2013  MZ  RFC10491 11  Fixed global field update of family not working and error message not showing correctly
-- 14 Nov 2018  AV  75198/DR-45358	12   Date conversion errors when creating cases and opening names in Chinese DB
-- 21 Jun 2018	DV	DR-48520	  13	Add check for valid status before updating the text.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Begin Try

Declare	@nErrorCode	int
Declare @nRowCount	int
Declare @bLongFlag 	bit
Declare @sSQLString     nvarchar(max)
Declare @dtLastModified datetime
Declare @bKeepHistory   bit
Declare @sStaffCode	nvarchar(10)
Declare @sText		nvarchar(max)
Declare @bIsAppend	bit

CREATE TABLE #UPDATEDCASES(
	CASEID int NOT NULL
)

CREATE TABLE #VALIDCASES(
	CASEID int NOT NULL
)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0

-- Get the NAMECODE for the current user
If @nErrorCode = 0
Begin
	Select @sStaffCode = N.NAMECODE
	from NAME N
	join USERIDENTITY U on (U.NAMENO = N.NAMENO)
	where U.IDENTITYID = @pnUserIdentityId
	
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Select @sText = cast(TEXT as nvarchar(max)) + ' ('+@sStaffCode+': ' + REPLACE(CONVERT(nvarchar, GETDATE(), 112),' ','-') + ')',
	@bIsAppend = ISTEXTAPPEND
	FROM GLOBALCASECHANGEREQUEST
	WHERE PROCESSID = @pnProcessId
	
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "INSERT INTO #VALIDCASES (CASEID) SELECT CS.CASEID FROM " +@psGlobalTempTable+ " CS 
					join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
					join CASES CA on (CA.CASEID = CS.CASEID)
				    left join STATUS S			on (S.STATUSCODE = GC.STATUSCODE)
					left join VALIDSTATUS V		on (V.STATUSCODE = GC.STATUSCODE
							and V.PROPERTYTYPE=CA.PROPERTYTYPE
							and V.CASETYPE    =CA.CASETYPE
							and V.COUNTRYCODE =(	select min(V1.COUNTRYCODE)
										from VALIDSTATUS V1
										where V1.COUNTRYCODE in (CA.COUNTRYCODE, 'ZZZ')
										and   V1.CASETYPE    =V.CASETYPE
										and   V1.PROPERTYTYPE=V.PROPERTYTYPE))
					left join SITECONTROL SC on (SC.CONTROLID = 'Confirmation Passwd')
					Where (GC.STATUSCODE is null or (V.STATUSCODE is not null and ((S.CONFIRMATIONREQ = 1 and SC.COLCHARACTER = GC.STATUSCONFIRM) OR (S.CONFIRMATIONREQ = 0))))"

					  exec @nErrorCode = sp_executesql @sSQLString,
	                                N'@pnProcessId		int',
	                                @pnProcessId		= @pnProcessId	 

End

If @nErrorCode = 0
Begin
        If @sText is null
        Begin
                If @pbDebugFlag = 1
                Begin
                        Print 'Clear Text...'
                        Print ''
                End
                -- Delete the Case text if updating to null
	        Set @sSQLString = "Delete 
					OUTPUT DELETED.CASEID
					INTO #UPDATEDCASES
				   from CASETEXT C
	                           join  #VALIDCASES CS on (CS.CASEID = C.CASEID)
				   join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)	
	                           and C.TEXTTYPE = GC.TEXTTYPE
	                           and (C.CLASS = GC.CLASS or (C.CLASS is null and GC.CLASS is null))
                                   and (C.LANGUAGE = GC.LANGUAGE or(C.LANGUAGE is null and GC.LANGUAGE is null))"
        	                   
	        exec @nErrorCode = sp_executesql @sSQLString,
	                                N'@pnProcessId		int',
	                                @pnProcessId		= @pnProcessId	                                
                        	                                
        End
        Else
        Begin
                -- Is the new CaseText long text?                
		Set @bLongFlag = CASE WHEN datalength(@sText) <= 508 or @sText is null THEN 0 ELSE 1 END		
                Set @dtLastModified = getdate()
                
	        -- Check the KEEPSPECIHISTORY site control to see if we should insert or update
	        If (@nErrorCode = 0)
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
				If @pbDebugFlag = 1
				Begin
					Print 'Update text...'
					Print ''
	                        End
	                        
	                        Set @sSQLString = "Update CASETEXT
				        set CLASS = GC.CLASS,
				        LANGUAGE = GC.LANGUAGE,
				        MODIFIEDDATE = @dtLastModified,"
		                If @bIsAppend = 1
				Begin
                                        Set @sSQLString = @sSQLString + CHAR(10) +
					        "LONGFLAG = CASE WHEN C.LONGFLAG = 1 or @bLongFlag = 1 or DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) > 508 
					                        THEN 1
		                                             ELSE 0 END,
					        TEXT = CASE WHEN C.LONGFLAG = 1 THEN @sText + CHAR(13) + cast(C.TEXT as nvarchar(max)) 
		                                             WHEN @bLongFlag = 1 THEN @sText + CHAR(13) + C.SHORTTEXT 
		                                             WHEN DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) > 508 
		                                                THEN @sText + CHAR(13) + C.SHORTTEXT
		                                             ELSE NULL END,
					        SHORTTEXT =  CASE WHEN C.LONGFLAG = 0 and @bLongFlag = 0 and DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) <= 508  
		                                                THEN @sText + CHAR(13) + C.SHORTTEXT  
		                                             ELSE NULL END"
		                End
		                Else
		                Begin
		                        Set @sSQLString = @sSQLString + CHAR(10) +
		                               "LONGFLAG = CASE WHEN @bLongFlag = 1 or DATALENGTH(@sText) > 508 
		                                                THEN 1
		                                             ELSE 0 END,
					       TEXT =  CASE WHEN @bLongFlag = 1 or DATALENGTH(@sText) > 508
					                        THEN @sText
		                                             ELSE NULL END,
					       SHORTTEXT = CASE WHEN @bLongFlag = 0 and DATALENGTH(@sText) <= 508 
		                                                THEN @sText  
		                                             ELSE NULL END"
		                End
		                
		                Set @sSQLString = @sSQLString + CHAR(10)+"
		                        OUTPUT INSERTED.CASEID
					INTO #UPDATEDCASES
					from CASETEXT C
			                join #VALIDCASES CS on (CS.CASEID = C.CASEID)
					join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)					
	 		                where C.TEXTTYPE = GC.TEXTTYPE
			                and C.TEXTNO = (SELECT MAX(CT2.TEXTNO) from CASETEXT CT2
							where CT2.CASEID = CS.CASEID
							and CT2.TEXTTYPE = GC.TEXTTYPE
							and (CT2.CLASS = GC.CLASS or (CT2.CLASS is null and GC.CLASS is null))
	                                                and (CT2.LANGUAGE = GC.LANGUAGE or (CT2.LANGUAGE is null and GC.LANGUAGE is null)))
					and (C.CLASS = GC.CLASS or (C.CLASS is null and GC.CLASS is null))
	                                and (C.LANGUAGE = GC.LANGUAGE or (C.LANGUAGE is null and GC.LANGUAGE is null))"                	
		                
		                If @pbDebugFlag = 1
				Begin
					Print @sSQLString
					Print ''
	                        End
                	        exec @nErrorCode=sp_executesql @sSQLString,
			                      N'@dtLastModified		datetime,
			                        @sText                  nvarchar(max),
			                        @bLongFlag              bit,
				                @pnProcessId		int',
				                @dtLastModified	        = @dtLastModified,
				                @sText                  = @sText,
				                @bLongFlag              = @bLongFlag,
				                @pnProcessId		= @pnProcessId
				                
				
	                End
	                Else 
	                -- case text updates are kept historically
	                Begin
				If @pbDebugFlag = 1
				Begin
					Print 'Insert Text...' + @sText
					Print ''
				End		                               		
	                        
	                        Set @sSQLString = "
		                INSERT INTO CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, TEXT)
		                OUTPUT INSERTED.CASEID
				INTO #UPDATEDCASES
		                SELECT C.CASEID, GC.TEXTTYPE, 
		                        ISNULL((SELECT MAX(TEXTNO) + 1 FROM CASETEXT CT2 WHERE CT2.CASEID = C.CASEID AND CT2.TEXTTYPE = C.TEXTTYPE), 0), 
		                        GC.CLASS, GC.LANGUAGE, @dtLastModified," 
		                If @bIsAppend = 1
				Begin
				        Set @sSQLString = @sSQLString + CHAR(10) +
					        "CASE WHEN C.LONGFLAG = 1 or @bLongFlag = 1 or DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) > 508 
					                THEN 1
		                                      ELSE 0 END,
		                                CASE WHEN C.LONGFLAG = 0 and @bLongFlag = 0 and DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) <= 508  
		                                        THEN @sText + CHAR(13) + C.SHORTTEXT  
		                                     ELSE NULL END,
					        CASE WHEN C.LONGFLAG = 1 THEN @sText + CHAR(13) + cast(C.TEXT as nvarchar(max)) 
		                                     WHEN @bLongFlag = 1 THEN @sText + CHAR(13) + C.SHORTTEXT 
		                                     WHEN DATALENGTH(@sText + CHAR(13) + C.SHORTTEXT) > 508 
		                                        THEN @sText + CHAR(13) + C.SHORTTEXT
		                                     ELSE NULL END"
		                End
		                Else
		                Begin
		                        Set @sSQLString = @sSQLString + CHAR(10) +
		                                "CASE WHEN @bLongFlag = 1 or DATALENGTH(@sText) > 508 
		                                        THEN 1
		                                      ELSE 0 END,
		                                CASE WHEN @bLongFlag = 0 and DATALENGTH(@sText) <= 508 
		                                        THEN @sText  
		                                     ELSE NULL END,
					        CASE WHEN @bLongFlag = 1 or DATALENGTH(@sText) > 508
					                THEN @sText
		                                     ELSE NULL END"
		                End
		                
		                Set @sSQLString = @sSQLString + CHAR(10) +
		                "FROM CASETEXT C
		                join #VALIDCASES CS on (CS.CASEID = C.CASEID)
				join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)				
				where C.TEXTTYPE = GC.TEXTTYPE
		                and  C.TEXTNO = ISNULL((SELECT MAX(TEXTNO)FROM CASETEXT CT2
		                                        WHERE CT2.CASEID = C.CASEID 
		                                        AND CT2.TEXTTYPE = C.TEXTTYPE
		                                        AND (CT2.CLASS = GC.CLASS or (CT2.CLASS is null and GC.CLASS is null))
	                                                AND (CT2.LANGUAGE = GC.LANGUAGE or (CT2.LANGUAGE is null and GC.LANGUAGE is null))), 0)
		                and (C.CLASS = GC.CLASS or (C.CLASS is null and GC.CLASS is null))
	                        and (C.LANGUAGE = GC.LANGUAGE or (C.LANGUAGE is null and GC.LANGUAGE is null))"
		                
		                If @pbDebugFlag = 1
				Begin
					Print @sSQLString
				End
				
		                exec @nErrorCode = sp_executesql @sSQLString,
		                                N'@dtLastModified       datetime,
		                                  @sText                nvarchar(max),
		                                  @bLongFlag            bit,
		                                  @pnProcessId		int',
		                                  @dtLastModified       = @dtLastModified,
		                                  @sText                = @sText,
		                                  @bLongFlag            = @bLongFlag,
		                                  @pnProcessId		= @pnProcessId
	                End
	        End
	        
	        -- Now insert new text for cases without specified case text type
	        If @nErrorCode = 0
	        Begin
			If @pbDebugFlag = 1
			Begin
				Print 'Insert Text for Cases without Case Text for the specific Text Type, Class and Language ...'
				Print ''
			End
                        
                        Set @sSQLString = '
	                INSERT INTO CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, TEXT)
	                OUTPUT INSERTED.CASEID
			INTO #UPDATEDCASES
	                SELECT C.CASEID, GC.TEXTTYPE, 
	                        ISNULL((SELECT MAX(TEXTNO) + 1 FROM CASETEXT CT2 WHERE CT2.CASEID = C.CASEID AND CT2.TEXTTYPE = GC.TEXTTYPE), 0), 
	                        GC.CLASS, GC.LANGUAGE, @dtLastModified, @bLongFlag, 
	                        CASE @bLongFlag WHEN 0 THEN @sText ELSE NULL END, 
	                        CASE @bLongFlag WHEN 1 THEN @sText ELSE NULL END
	                FROM CASES C
	                join #VALIDCASES CS on (CS.CASEID = C.CASEID)
			join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	                where C.CASEID not in (SELECT DISTINCT CT.CASEID from CASETEXT CT
					join ' +@psGlobalTempTable+ ' CS on (CS.CASEID = CT.CASEID)
	                                 where CT.TEXTTYPE = GC.TEXTTYPE
	                                and (CT.CLASS = GC.CLASS or (CT.CLASS is null and GC.CLASS is null))
	                                and (CT.LANGUAGE = GC.LANGUAGE or (CT.LANGUAGE is null and GC.LANGUAGE is null)))'

	                If @pbDebugFlag = 1
			Begin
				Print @sSQLString
				Print ''
                        End
	                exec @nErrorCode = sp_executesql @sSQLString,
	                                N'@dtLastModified       datetime,
	                                  @sText                nvarchar(max),
	                                  @bLongFlag            bit,
	                                  @pnProcessId		int',
	                                  @dtLastModified       = @dtLastModified,
	                                  @sText                = @sText,
	                                  @bLongFlag            = @bLongFlag,
	                                  @pnProcessId		= @pnProcessId
                End
                
                If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			UPDATE " +@psGlobalTempTable+ "
			SET CASETEXTUPDATED = 1
			from " +@psGlobalTempTable+ " C
			join #UPDATEDCASES UC on (UC.CASEID = C.CASEID)"
			
			exec @nErrorCode = sp_executesql @sSQLString
		End
        End
End

End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalCaseTextChange to public
GO
