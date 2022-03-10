-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GlobalCaseChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GlobalCaseChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GlobalCaseChange.'
	Drop procedure [dbo].[csw_GlobalCaseChange]
End
Print '**** Creating Stored Procedure dbo.csw_GlobalCaseChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[csw_GlobalCaseChange]  
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psTextTypeCode         nvarchar(4)	= null,    -- TextType is mandatory
	@psClass                nvarchar(11)    = null,
	@pnLanguageKey          int             = null,
	@ptText                 ntext           = null,
	@pbIsAppend		bit		= 1, -- Append text by default	
	@pnOfficeKey            int             = null,
	@psFamily		nvarchar(20)	= null,
	@psTitle		nvarchar(254)	= null,
	@pnStatusCode		int		= null,
	@pbRenewalFlag		bit		= 0,
	@psStatusConfirmPwd	nvarchar(254)	= null,
	@pnFileLocationKey	int		= null,
	@pnFilePartKey		smallint	= null,
	@pdtWhenMoved		datetime	= null,	
	@pnMovedByKey		int		= null,
	@psBayNo		nvarchar(20)	= null,
        @psActionKey            nvarchar(2)     = null,
	@pbHasTextUpdate	bit		= 0,
	@pbHasOfficeUpdate	bit		= 0,
	@pbHasFamilyUpdate	bit		= 0,
	@pbHasTitleUpdate	bit		= 0,
	@pbHasStatusUpdate	bit		= 0,
	@pbHasFileLocationUpdate bit		= 0,
        @pbHasPolicingRequest   bit             = 0,
	@psGlobalTempTable	nvarchar(32)	= null,
	@ptXMLFilterCriteria	ntext,		-- Mandatory
	@pbCalledFromCentura	bit		= 0	-- Indicates that Centura called the stored procedure	
)
AS
-- PROCEDURE:	csw_GlobalCaseChange
-- VERSION:	10
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedure calls the cs_GlobalCaseChange asynchronously. 
-- COPYRIGHT:	Copyright 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number  Version	Change
-- ------------	---	-------	-------	----------------------------------------------- 
-- 13 Oct 2010  LP	RFC9321	1	Procedure created 
-- 05 Nov 2010	LP	RFC9321	2	Pass null if there are no values in parameters.
-- 28 May 2013	DL	10030	3	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 31 Jul 2013	vql	DR536	4	Make sure ipu_OAGetErrorInfo is called correctly. 
-- 16 Aug 2013	MS	R17322	5	Added background process logic and removed temporary tables
-- 28 Oct 2013  MZ	R10491  6       Fixed global field update of family not working and error message not showing correctly
-- 14 Oct 2014	DL	R39102	7	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 04 Jul 2018	DV	R74342	8	Added Renewal flag to indicate renewal status
-- 28 Jun 2018  MS      R11355  9       Added batch policing request logic
-- 14 Nov 2018  AV  75198/DR-45358	10   Date conversion errors when creating cases and opening names in Chinese DB

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON

Declare @sSQLString		nvarchar(Max)
Declare @sWhereFilter		nvarchar(Max)
Declare @nErrorCode		int		
declare	@sCommand		nvarchar(max)
declare	@nObject		int
declare	@nObjectExist		tinyint
declare @nBackgroundProcessId	int
declare @TranCountStart		int
declare @nRowCount		int

-- Initialise variables
Set  @nErrorCode    = 0
set  @nBackgroundProcessId = 0

-- The Cases derived table needs only be constructed when the @bHasCase = 1.
If  @nErrorCode = 0
and @ptXMLFilterCriteria is not null
Begin
	-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
	-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
	-- separate occurrence of FilterCriteria.	
	exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sWhereFilter	  	OUTPUT, 
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= 0,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= 0	
End

If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- The Global Case Change Process is added to the BackgroundProcess list
	Set @sSQLString="Insert into BACKGROUNDPROCESS (IDENTITYID,PROCESSTYPE, STATUS, STATUSDATE)
			Values (@pnUserIdentityId,'GlobalCaseChange',1, getDate())"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId int',
			  @pnUserIdentityId = @pnUserIdentityId

	If @nErrorCode = 0
	Begin
		Set @nBackgroundProcessId = IDENT_CURRENT('BACKGROUNDPROCESS') 
	End
	
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		insert into GLOBALCASECHANGEREQUEST
		       (PROCESSID,
			OFFICEID,FAMILY,TITLE,
			TEXTTYPE,CLASS,LANGUAGE,
			TEXT,ISTEXTAPPEND,STATUSCODE,STATUSCONFIRM,
			FILELOCATION,FILEPARTID,WHENMOVED,ISSUEDBY,BAYNO,RENEWALFLAG, ACTION)
		values(	@nBackgroundProcessId,
			@pnOfficeKey,@psFamily,@psTitle,
			@psTextTypeCode,@psClass,@pnLanguageKey,
			@ptText,@pbIsAppend,@pnStatusCode,@psStatusConfirmPwd,
			@pnFileLocationKey,@pnFilePartKey,@pdtWhenMoved,@pnMovedByKey,@psBayNo,@pbRenewalFlag, @psActionKey)"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nBackgroundProcessId		int,
				  @pnOfficeKey			int,
				  @psFamily			nvarchar(20),
				  @psTitle			nvarchar(254),
				  @psTextTypeCode		nvarchar(2),
				  @psClass			nvarchar(100),
				  @pnLanguageKey		int,
				  @ptText			nvarchar(max),
				  @pbIsAppend			bit,
				  @pnStatusCode			smallint,
				  @psStatusConfirmPwd		nvarchar(254),
				  @pnFileLocationKey		int,
				  @pnFilePartKey		smallint,
				  @pdtWhenMoved			datetime,
				  @pnMovedByKey			int,
				  @psBayNo			nvarchar(20),
				  @pbRenewalFlag		bit,
                                  @psActionKey                  nvarchar(2)',
				  @nBackgroundProcessId		=@nBackgroundProcessId,	
				  @pnOfficeKey			=@pnOfficeKey,
				  @psFamily			=@psFamily,
				  @psTitle			=@psTitle,
				  @psTextTypeCode		=@psTextTypeCode,
				  @psClass			=@psClass,
				  @pnLanguageKey		=@pnLanguageKey,
				  @ptText			=@ptText,
				  @pbIsAppend			=@pbIsAppend,
				  @pnStatusCode			=@pnStatusCode,
				  @psStatusConfirmPwd		=@psStatusConfirmPwd,
				  @pnFileLocationKey		=@pnFileLocationKey,
				  @pnFilePartKey		=@pnFilePartKey,
				  @pdtWhenMoved			=@pdtWhenMoved,
				  @pnMovedByKey			=@pnMovedByKey,
				  @psBayNo			=@psBayNo,
				  @pbRenewalFlag	        = @pbRenewalFlag,
                                  @psActionKey                  = @psActionKey
	End
	
	------------------------------
	-- Load the Cases supplied in
	-- the temporary table for the
	-- request.
	------------------------------
	If  @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into GLOBALCASECHANGECASES(PROCESSID,CASEID)
		select @nBackgroundProcessId,C.CASEID
		From CASES C
		Where 1=1"

		If @sWhereFilter is not null
		Begin
			Set @sSQLString=@sSQLString+char(10)+@sWhereFilter
		End

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nBackgroundProcessId	int',
					  @nBackgroundProcessId=@nBackgroundProcessId
	End
	
	-- Commit or Rollback the transaction
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

If  @nErrorCode = 0
Begin
	------------------------------------------
	-- Build command line to run cs_GlobalNameChange 
	-- RFC39102 - Replace ole auto with service broker	
	-----------------------------------------
	Set @sCommand = 'dbo.cs_GlobalCaseChange '
	
	If @pnUserIdentityId is not null
		Set @sCommand = @sCommand + "@pnUserIdentityId=" + convert(varchar,@pnUserIdentityId) + ","

	If @psCulture is not null
		Set @sCommand = @sCommand + "@psCulture='" + convert(varchar,@psCulture) + "',"

	If @pbHasTextUpdate is not null
		Set @sCommand = @sCommand + "@pbHasTextUpdate='" + convert(varchar,@pbHasTextUpdate) + "',"

	If @pbHasOfficeUpdate is not null
		Set @sCommand = @sCommand + "@pbHasOfficeUpdate='" + convert(varchar,@pbHasOfficeUpdate) + "',"

	If @pbHasFamilyUpdate is not null
		Set @sCommand = @sCommand + "@pbHasFamilyUpdate='" + convert(varchar,@pbHasFamilyUpdate) + "',"

	If @pbHasTitleUpdate is not null
		Set @sCommand = @sCommand + "@pbHasTitleUpdate='" + convert(varchar,@pbHasTitleUpdate) + "',"

	If @pbHasStatusUpdate is not null
		Set @sCommand = @sCommand + "@pbHasStatusUpdate='" + convert(varchar,@pbHasStatusUpdate) + "',"

	If @pbHasFileLocationUpdate is not null
		Set @sCommand = @sCommand + "@pbHasFileLocationUpdate='" + convert(varchar,@pbHasFileLocationUpdate) + "',"
	
	If @nBackgroundProcessId is not null
		Set @sCommand = @sCommand + "@pnBackgroundProcessId='" + convert(varchar,@nBackgroundProcessId) + "',"	

        If @pbHasPolicingRequest is not null
		Set @sCommand = @sCommand + "@pbHasPolicingRequest='" + convert(varchar,@pbHasPolicingRequest) + "',"
		
	Set @sCommand = @sCommand + "@pbCalledFromCentura=0" 	

	---------------------------------------------------------------
	-- Run the command asynchronously using Service Broker (rfc39102)
	 --------------------------------------------------------------- 
	If @nErrorCode = 0
	Begin
		print ''
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
		print 'Command called...'
		print @sCommand
		print ''
	End
	--exec ipu_OAGetErrorInfo if there are errors
	
	--If @nErrorCode <> 0
	--Begin
	--	declare @sSource nvarchar(4000)
	--	declare @sDescription nvarchar(4000)
		
	--	execute ipu_OAGetErrorInfo 
	--		@pnObjectToken 	= @nObject,
	--		@psSource	= @sSource OUT,
	--		@psDescription	= @sDescription OUT,
	--		@psHelpFile	= null,
	--		@pnHelpId	= null
		
	--	RAISERROR('Could not run shell command asynchronously using WshShell ole automation. Error received: %s. Error source: %s', 10, 1, @sDescription, @sSource) WITH LOG 
	--End
	 	
End
		
Return @nErrorCode
GO

Grant execute on dbo.csw_GlobalCaseChange to public
GO
