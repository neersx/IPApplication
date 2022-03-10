-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalCaseChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalCaseChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalCaseChange.'
	Drop procedure [dbo].[cs_GlobalCaseChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalCaseChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalCaseChange
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTextTypeCode         nvarchar(4)	= null,    -- TextType is mandatory
	@psClass                nvarchar(11)    = null,
	@pnLanguageKey          int             = null,
	@ptText                 nvarchar(max)   = null,
	@pbIsAppend		bit		= 1, -- Append text by default	
	@pnOfficeKey            int             = null,
	@psFamily		nvarchar(20)	= null,
	@psTitle		nvarchar(254)	= null,
	@pnStatusCode		int		= null,
	@psStatusConfirmPwd	nvarchar(254)	= null,
	@pnFileLocationKey	int		= null,
	@pnFilePartKey		smallint	= null,
	@pdtWhenMoved		datetime	= null,	
	@pnMovedByKey		int		= null,
	@psBayNo		nvarchar(20)	= null,
	@pbHasTextUpdate	bit		= 0,
	@pbHasOfficeUpdate	bit		= 0,
	@pbHasFamilyUpdate	bit		= 0,
	@pbHasTitleUpdate	bit		= 0,
	@pbHasStatusUpdate	bit		= 0,
	@pbHasFileLocationUpdate bit		= 0,
	@pnBackgroundProcessId	nvarchar(32)	= null,
	@pbCalledFromCentura	bit		= 0, 
	@pnCaseId		int		= null,	-- Use if just a single Case is to be updated as an alternative to @sGlobalTempTable
	@psCaseType		nchar(1)	= null,
	@psCountryCode		nvarchar(3)	= null,
	@psPropertyType		nchar(1)	= null,
	@psCaseCategory		nvarchar(2)	= null,
	@psSubType		nvarchar(2)	= null,
	@psBasis		nvarchar(2)	= null,
	@pbHasCaseTypeUpdate	bit		= 0,
	@pbHasCountryUpdate	bit		= 0,
	@pbHasPropertyUpdate	bit		= 0,
	@pbHasCategoryUpdate	bit		= 0,
	@pbHasSubTypeUpdate	bit		= 0,
	@pbHasBasisUpdate	bit		= 0,
        @pbHasPolicingRequest   bit             = 0,
        @psActionKey            nvarchar(2)     = 0
)
as
-- PROCEDURE:	cs_GlobalCaseChange
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Manages global field updates on multiple selected cases
--		Uses OLE automation for background processing of the updates
--		Stores results of the updates in BACKGROUNDPROCESS and GLOBALCASECHANGEREQUEST

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Oct 2010	LP	RFC9321 1	Procedure created
-- 05 Nov 2010	LP	RFC9321	2	Extend TextTypeCode field to nvarchar(2)
-- 12 Apr 2011	MF	RFC10491 3	Allow CaseType, CountryCode, PropertyType, CaseCategory, SubType and Basis
--					to be set to a specific value for a set of Cases.
-- 16 Aug 2013	MS	R17322	4	Replace Globaltemptable parameter with BackGroundProcessId and remove the logic 
--					of entering records in BackgroundProcess table
-- 28 Oct 2013  MZ      RFC10491 5      Fixed global field update of family not working and error message not showing correctly
-- 28 Jun 2018  MS      R11355  6       Added batch policing request logic
-- 26 Dec 2018	MF	DR-46199 7	Rename the temporary table #TEMPPOLICING to #TEMPPOLICE to avoid scoping error.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF
 
Create table dbo.#TEMPSELECTEDCASES
			       (CASEID			int	NOT NULL,
				CASETEXTUPDATED		bit	NOT NULL DEFAULT 0,
				STATUSUPDATED		bit	NOT NULL DEFAULT 0,
				FILELOCATIONUPDATED	bit	NOT NULL DEFAULT 0,
				TITLEUPDATED		bit	NOT NULL DEFAULT 0,
				OFFICEUPDATED		bit	NOT NULL DEFAULT 0,
				FAMILYUPDATED		bit	NOT NULL DEFAULT 0,
				CASETYPEUPDATED		bit	NOT NULL DEFAULT 0,
				COUNTRYCODEUPDATED	bit	NOT NULL DEFAULT 0,
				PROPERTYTYPEUPDATED	bit	NOT NULL DEFAULT 0,
				CASECATEGORYUPDATED	bit	NOT NULL DEFAULT 0,
				SUBTYPEUPDATED		bit	NOT NULL DEFAULT 0,
				BASISUPDATED		bit	NOT NULL DEFAULT 0,
                                ISPOLICED               bit     NOT NULL DEFAULT 0
				) 

Create table dbo.#TEMPPOLICE   (CASEID		int		NOT NULL,
				ACTION		nvarchar(3)	collate database_default NOT NULL,
				CYCLE		int		NOT NULL,
				SEQUENCENO	int		identity(1,1)
				)
 
-- VARIABLES
declare @nErrorCode		int
declare @TranCountStart		int
declare @nRowCount		int
declare @bWaitLoop		bit
declare @sDelayLength		nvarchar(10)
declare @sSQLString		nvarchar(max)
declare @nSavedErrorCode	int
declare @sErrorMessage		nvarchar(max)
declare @sGlobalTempTable	nvarchar(50)

set @nErrorCode           = 0
set @nRowCount		  = 0 
Set @sGlobalTempTable	  ='#TEMPSELECTEDCASES'

----------------------------------------------
-- Change @sGlobalTempTable argument to local temp 
-- table for avoiding the error in web version 
----------------------------------------------
If @nErrorCode = 0 
and @pbCalledFromCentura = 0
Begin
	----------------------------------------
	-- Insert CaseIds from global temp table 
	-- into the temp table
	----------------------------------------
	If @pnBackgroundProcessId is not null
	Begin
		Set @sSQLString = "INSERT INTO dbo.#TEMPSELECTEDCASES (CASEID)
				  Select CASEID
				  From GLOBALCASECHANGECASES
				  Where PROCESSID =  @pnBackgroundProcessId"
	End
	Else Begin
		Set @sSQLString = "INSERT INTO dbo.#TEMPSELECTEDCASES (CASEID)
				  Select @pnCaseId"
	End

	Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseId			int,
					  @pnBackgroundProcessId	int',
					  @pnCaseId			= @pnCaseId,
					  @pnBackgroundProcessId	= @pnBackgroundProcessId
END

If @nErrorCode = 0 and @pbCalledFromCentura = 0
Begin
	Set @sDelayLength='0:0:10'
	Set @bWaitLoop=1
		
	While(@bWaitLoop=1 and @nErrorCode=0)
	Begin
		Set @bWaitLoop=0
		----------------------------------
		-- Compare the Cases passed in the 
		-- temporary table to see if any 
		-- of these are currently being
		-- processed.
		----------------------------------
		Set @sSQLString="
		Select @bWaitLoop=1
		from dbo.#TEMPSELECTEDCASES C1
		join GLOBALCASECHANGECASES C2 on (C2.CASEID=C1.CASEID)
		where C2.LOGDATETIMESTAMP>dateadd(mi,-5,getdate())
		and C2.PROCESSID <> @pnBackgroundProcessId"	-- Check for requests in the last 5 minutes

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@bWaitLoop			bit		OUTPUT,
					  @pnBackgroundProcessId	int',
					  @bWaitLoop			= @bWaitLoop	OUTPUT,
					  @pnBackgroundProcessId	= @pnBackgroundProcessId

		If  @bWaitLoop=1 and @nErrorCode=0
		Begin
			WAITFOR DELAY @sDelayLength
		End
	End		
End

If @nErrorCode = 0 and @pnBackgroundProcessId is null
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
		Set @pnBackgroundProcessId = IDENT_CURRENT('BACKGROUNDPROCESS') 
	End
	
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		insert into GLOBALCASECHANGEREQUEST
		       (PROCESSID,
			OFFICEID,FAMILY,TITLE,
			TEXTTYPE,CLASS,LANGUAGE,
			TEXT,ISTEXTAPPEND,STATUSCODE,STATUSCONFIRM,
			FILELOCATION,FILEPARTID,WHENMOVED,ISSUEDBY,BAYNO,
			CASETYPE,COUNTRYCODE,PROPERTYTYPE,CASECATEGORY,SUBTYPE,BASIS,ACTION)
		values(	@pnBackgroundProcessId,
			@pnOfficeKey,@psFamily,@psTitle,
			@psTextTypeCode,@psClass,@pnLanguageKey,
			@ptText,@pbIsAppend,@pnStatusCode,@psStatusConfirmPwd,
			@pnFileLocationKey,@pnFilePartKey,@pdtWhenMoved,@pnMovedByKey,@psBayNo,
			@psCaseType,@psCountryCode,@psPropertyType,@psCaseCategory,@psSubType,@psBasis,@psAction)"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBackgroundProcessId	int,
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
				  @psCaseType			nchar(1),
			 	  @psCountryCode		nvarchar(3),
				  @psPropertyType		nchar(1),
				  @psCaseCategory		nvarchar(2),
				  @psSubType			nvarchar(2),
				  @psBasis			nvarchar(2),
                                  @psActionKey                  nvarchar(2)',
				  @pnBackgroundProcessId	=@pnBackgroundProcessId,	
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
				  @psCaseType			=@psCaseType,
			 	  @psCountryCode		=@psCountryCode,
				  @psPropertyType		=@psPropertyType,
				  @psCaseCategory		=@psCaseCategory,
				  @psSubType			=@psSubType,
				  @psBasis			=@psBasis,
                                  @psActionKey                  =@psActionKey
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
		select @nBackgroundProcessId,CASEID
		from dbo.#TEMPSELECTEDCASES"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBackgroundProcessId	int',
					  @pnBackgroundProcessId	= @pnBackgroundProcessId
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
Else If @nErrorCode = 0
Begin
	Set @sSQLString="
		Select  @pnOfficeKey = OFFICEID,
			@psFamily = FAMILY,
			@psTitle = TITLE,
			@psTextTypeCode = TEXTTYPE,
			@pnFileLocationKey = FILELOCATION,
			@pnStatusCode = STATUSCODE,
			@psCaseType = CASETYPE,
			@psCountryCode = COUNTRYCODE,
			@psPropertyType = PROPERTYTYPE,
			@psCaseCategory = CASECATEGORY,
			@psSubType = SUBTYPE,
			@psBasis = BASIS,
                        @psActionKey = ACTION
		From GLOBALCASECHANGEREQUEST
		Where PROCESSID = @pnBackgroundProcessId"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBackgroundProcessId	int,
				  @pnOfficeKey			int			output,
				  @psFamily			nvarchar(20)		output,
				  @psTitle			nvarchar(254)		output,
				  @psTextTypeCode		nvarchar(2)		output,
				  @pnStatusCode			smallint		output,
				  @pnFileLocationKey		int			output,
				  @psCaseType			nchar(1)		output,
			 	  @psCountryCode		nvarchar(3)		output,
				  @psPropertyType		nchar(1)		output,
				  @psCaseCategory		nvarchar(2)		output,
				  @psSubType			nvarchar(2)		output,
				  @psBasis			nvarchar(2)		output,
                                  @psActionKey                  nvarchar(2)             output',
				  @pnBackgroundProcessId	=@pnBackgroundProcessId,	
				  @pnOfficeKey			=@pnOfficeKey		output,
				  @psFamily			=@psFamily		output,
				  @psTitle			=@psTitle		output,
				  @psTextTypeCode		=@psTextTypeCode	output,
				  @pnStatusCode			=@pnStatusCode		output,
				  @pnFileLocationKey		=@pnFileLocationKey	output,
				  @psCaseType			=@psCaseType		output,
			 	  @psCountryCode		=@psCountryCode		output,
				  @psPropertyType		=@psPropertyType	output,
				  @psCaseCategory		=@psCaseCategory	output,
				  @psSubType			=@psSubType		output,
				  @psBasis			=@psBasis		output,
                                  @psActionKey                  =@psActionKey           output
End

If @nErrorCode=0
Begin
	
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	----------------------------------------------------------------------------
	-- PROCESS CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, BASIS
	----------------------------------------------------------------------------
	If @nErrorCode = 0 
	and((@pbHasCaseTypeUpdate = 1 AND @psCaseType     is not null)
	 or (@pbHasCountryUpdate  = 1 AND @psCountryCode  is not null)
	 or (@pbHasPropertyUpdate = 1 AND @psPropertyType is not null)
	 or (@pbHasCategoryUpdate = 1 AND @psCaseCategory is not null)
	 or (@pbHasSubTypeUpdate  = 1 AND @psSubType      is not null)
	 or (@pbHasBasisUpdate    = 1 AND @psBasis        is not null) )
	Begin
		exec @nErrorCode = dbo.cs_GlobalCaseCriteriaChange
								@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable
	End
	-----------------
	-- PROCESS OFFICE
	-----------------
	If @nErrorCode = 0 
	and @pbHasOfficeUpdate = 1
	and @pnOfficeKey is not null
	Begin
		exec @nErrorCode = dbo.cs_GlobalOfficeChange	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg = @sErrorMessage OUTPUT
	End

	-----------------
	-- PROCESS TITLE
	-----------------
	If @nErrorCode = 0 
	and @pbHasTitleUpdate = 1
	and @psTitle is not null
	Begin
		exec @nErrorCode = dbo.cs_GlobalTitleChange	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg = @sErrorMessage OUTPUT
	End

	-----------------
	-- PROCESS FAMILY
	-----------------
	If @nErrorCode = 0 
	and @pbHasFamilyUpdate = 1
	and @psFamily is not null
	Begin
		exec @nErrorCode = dbo.cs_GlobalFamilyChange	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg = @sErrorMessage OUTPUT
	End

	--------------------
	-- PROCESS CASE TEXT
	--------------------
	If @nErrorCode = 0 
	and @pbHasTextUpdate = 1
	and @psTextTypeCode is not null
	Begin
		exec @nErrorCode = dbo.cs_GlobalCaseTextChange	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg = @sErrorMessage OUTPUT
	End

	-----------------
	-- PROCESS STATUS
	-----------------
	If @nErrorCode = 0 
	and @pbHasStatusUpdate = 1
	and @pnStatusCode is not null
	Begin
		exec @nErrorCode = dbo.cs_GlobalStatusChange	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg = @sErrorMessage OUTPUT
	End

	------------------------
	-- PROCESS FILE LOCATION
	------------------------
	If @nErrorCode = 0 
	and @pbHasFileLocationUpdate = 1
	and @pnFileLocationKey is not null
	and @pnFileLocationKey != ''
	Begin
		exec @nErrorCode = dbo.cs_GlobalFileLocationChange	@pnResults		= @nRowCount OUTPUT,
									@pnUserIdentityId	= @pnUserIdentityId,
									@psCulture		= @psCulture,	
									@pnProcessId		= @pnBackgroundProcessId,
									@psGlobalTempTable	= @sGlobalTempTable,
									@psErrorMsg = @sErrorMessage OUTPUT
	End

        ---------------------------------
        -- Process Batch Policing Request
        ---------------------------------
        If @nErrorCode = 0
        and @pbHasPolicingRequest = 1
        and @psActionKey is not null
        Begin
                exec @nErrorCode = dbo.cs_GlobalPolicingRequest	@pnResults		= @nRowCount OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,	
								@pnProcessId		= @pnBackgroundProcessId,
								@psGlobalTempTable	= @sGlobalTempTable,
								@psErrorMsg             = @sErrorMessage OUTPUT
        End


	---------------------------------------
	-- Any OPENACTION rows that are open
	-- to be Policed need to be considered
	-- to be repoliced if a characteristic
	-- that can impact Policing has changed
	---------------------------------------

	If @nErrorCode=0
	and((@pbHasCaseTypeUpdate = 1 AND @psCaseType     is not null)
	 or (@pbHasCountryUpdate  = 1 AND @psCountryCode  is not null)
	 or (@pbHasPropertyUpdate = 1 AND @psPropertyType is not null)
	 or (@pbHasCategoryUpdate = 1 AND @psCaseCategory is not null)
	 or (@pbHasSubTypeUpdate  = 1 AND @psSubType      is not null)
	 or (@pbHasBasisUpdate    = 1 AND @psBasis        is not null)
	 or (@pbHasOfficeUpdate   = 1 AND @pnOfficeKey    is not null) )
	Begin
		Set @sSQLString="
		insert into #TEMPPOLICE(CASEID, ACTION, CYCLE)
		Select T.CASEID, OA.ACTION, OA.CYCLE
		from #TEMPSELECTEDCASES T
		join OPENACTION OA	on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
		where OA.CRITERIANO<>dbo.fn_GetCriteriaNo(OA.CASEID,'E',OA.ACTION,getdate(), default)
		or OA.CRITERIANO is null"

		exec @nErrorCode=sp_executesql @sSQLString
		Set @nRowCount=@@Rowcount

		If  @nErrorCode=0
		and @nRowCount >0
		Begin
			----------------------------------------------------------
			-- Now load live Policing table with generated sequence no
			----------------------------------------------------------
			Set @sSQLString="
			insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
			 		      ONHOLDFLAG, ACTION, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
			select	getdate(), 
				T.SEQUENCENO, 
				'GLOBAL-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
				1,
				0, 
				T.ACTION, 
				T.CASEID, 
				T.CYCLE, 
				1, 
				substring(SYSTEM_USER,1,60), 
				@pnUserIdentityId
			from #TEMPPOLICE T"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId=@pnUserIdentityId
		End
	End
	
	-------------------------------------
	-- Commit or Rollback the transaction
	-------------------------------------
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

Set @nSavedErrorCode = @nErrorCode

If @nErrorCode=0 and @pbCalledFromCentura=0
Begin
        Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

        --------------------------------
	-- Delete the global case change
	-- request details on successful
	-- completion of the process 
	--------------------------------
	Set @sSQLString="Delete GLOBALCASECHANGECASES
	                where PROCESSID=@pnBackgroundProcessId"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int',
			  @pnBackgroundProcessId        = @pnBackgroundProcessId

	If @nErrorCode=0
	Begin
		Set @sSQLString="Delete	GLOBALCASECHANGEREQUEST
		                where PROCESSID=@pnBackgroundProcessId"

		exec @nErrorCode=sp_executesql @sSQLString,
				 N'@pnBackgroundProcessId	int',
				   @pnBackgroundProcessId       = @pnBackgroundProcessId
	End

	-------------------------------------
	-- Commit or Rollback the transaction
	-------------------------------------
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

---------------------------------------
-- Update BACKGROUNDPROCESS table 
---------------------------------------	
If @pbCalledFromCentura=0
Begin
	If @nSavedErrorCode = 0
	Begin
		Set @sSQLString = "Update BACKGROUNDPROCESS
				Set STATUS = 2,
				    STATUSDATE = getdate()
				Where PROCESSID = @pnBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int',
			@pnBackgroundProcessId  = @pnBackgroundProcessId	
		
		
		-- Add Changed Cases in GLOBALCASECHANGERESULTS table
		If @nErrorCode = 0
		Begin
			INSERT INTO GLOBALCASECHANGERESULTS(PROCESSID, CASEID, CASETEXTUPDATED, STATUSUPDATED, FILELOCATIONUPDATED, TITLEUPDATED, OFFICEUPDATED, FAMILYUPDATED,
							    CASETYPEUPDATED, COUNTRYCODEUPDATED, PROPERTYTYPEUPDATED, CASECATEGORYUPDATED, SUBTYPEUPDATED, BASISUPDATED, ISPOLICED)
			SELECT DISTINCT @pnBackgroundProcessId, C.CASEID,  C.CASETEXTUPDATED, C.STATUSUPDATED, C.FILELOCATIONUPDATED, C.TITLEUPDATED, C.OFFICEUPDATED, C.FAMILYUPDATED,
					C.CASETYPEUPDATED, C.COUNTRYCODEUPDATED, C.PROPERTYTYPEUPDATED, C.CASECATEGORYUPDATED, C.SUBTYPEUPDATED, C.BASISUPDATED, C.ISPOLICED
			FROM dbo.#TEMPSELECTEDCASES C				

		End
	End
	Else
	Begin
		IF @sErrorMessage IS NULL
		BEGIN
			Set @sSQLString="Select @sErrorMessage = description
				from master..sysmessages
				where error=@nSavedErrorCode
				and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

			Exec sp_executesql @sSQLString,
				N'@sErrorMessage	nvarchar(254) output,
				  @nSavedErrorCode	int',
				  @sErrorMessage	= @sErrorMessage output,
				  @nSavedErrorCode	= @nSavedErrorCode
		END
		---------------------------------------
		-- Update BACKGROUNDPROCESS table 
		---------------------------------------	
		Set @sSQLString = "Update BACKGROUNDPROCESS
					Set STATUS = 3,
					    STATUSDATE = getdate(),
					    STATUSINFO = @sErrorMessage
					Where PROCESSID = @pnBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int,
			  @sErrorMessage	nvarchar(254)',
			  @pnBackgroundProcessId = @pnBackgroundProcessId,
			  @sErrorMessage	 = @sErrorMessage
		End
End

---------------------------------------
-- drop the temporary table @sGlobalTempTable after use
---------------------------------------
IF @nErrorCode=0
Begin
	---------------------------------------
	-- Drop temporary table 
	---------------------------------------	
	Set @sSQLString = "Drop table "+CHAR(10)+ @sGlobalTempTable
	exec @nErrorCode = sp_executesql @sSQLString		
End

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalCaseChange to public
GO
