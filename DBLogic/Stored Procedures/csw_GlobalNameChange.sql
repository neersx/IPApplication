
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GlobalNameChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GlobalNameChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GlobalNameChange.'
	Drop procedure [dbo].[csw_GlobalNameChange]
End
Print '**** Creating Stored Procedure dbo.csw_GlobalNameChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[csw_GlobalNameChange]  
(
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	-- Filter Parameters
	@psNameType			nvarchar(3)	= null,	-- the NameType
	@pnExistingNameNo		int		= null,	-- the NameNo if a specific one is effected by the change
	@pnExistingCorrespondName	int		= null,	-- a particular CorrespondName to be modified
	-- Change Details
	@pnNewNameNo			int		= null,	-- the replacement Name.  If null then deletion is required.
	@pnNewCorrespondName		int		= null,	-- the replacement Correspondence Name.	
	-- Options
	@pbUpdateName			bit		= 1,	-- indicates that existing Names are to be changed
	@pbInsertName			bit		= 0,	-- indicates that the Name is to be inserted if it does not already exist
	@pbDeleteName			bit		= 0,	-- indicates the name is to be removed from Cases
	@pbKeepCorrespondName		bit		= 0, 	-- when set on the existing Correspondence Name will not be changed.
	@pnKeepReferenceNo		smallint	= 2, 	-- when 1 the existing ReferenceNo will be retained.  when 2 the existing
								-- reference no will be cleared, when 3 new reference number will be received via
								-- @psReferenceNo
	@pbApplyInheritance		bit		= 0,	-- indicates that changed NameType is to have a cascading
								-- global name change effect based on inheritance rules.
								-- NOTE: The checkbox for this flag must only be enabled
								--       if the user has specified a NameType and has 
								--       NOT specified an ExistingNameNo.  This is to 
								--       allow inheritance to apply to all of the Cases
								--       in the temporary table.
	@psReferenceNo			nvarchar(80)	= null,	-- the new reference number for the new name.	
	@pdtCommenceDate		datetime	= null,	-- used to indicate when the Name will take effect against the Case
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@psTextTypeCode			nvarchar(2)	= null,	-- TextTypeCode
	@psText				ntext		= null,	-- TextTypeDesc  
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@psProgramId			nvarchar(30)    = null,  -- Indicates the Program through which it is called	
	@pbMoveAlerts			bit		= 1,  --Indicates that the alerts should be moved to the new name 
	@pnExistingAddressKey		int		= null, -- a particular Address to be modified
	@pnNewAddressKey		int		= null,  -- the replacement Address.
	@pbResetAddress			bit		= 0,	-- Reset address flag
	@pbResetAttention		bit		= 0,	-- Reset the attention
	@pbFromDefaultAttention		bit		= 0,	-- Change attention where the current attention is the default or null
	@pbFromDefaultAddress		bit		= 0	-- Change address where the current address is the default or null
)
AS
-- PROCEDURE:	csw_GlobalNameChange
-- VERSION:	12
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedure calls the cs_GlobalNameChange asynchronously. 
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number  Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 03 Nov 2008  MS	RFC5698	1	Procedure created 
-- 27 Nov 2008  MS	RFC5698	2	Update cs_GlobalNameChange call to asynchronous using OLE Automation 
-- 06 Jan 2009	MS	RFC7371 3       Add parameter @psProgramId for setting the Program through which it is called
-- 25 Mar 2009  MS	RFC5703 4	Update cs_GlobalNameChange call to asynchronous using OLE Automation 	
-- 07 Apr 2009	MF	RFC7852	5	The entire filter for the Case query will be passed as XML in @ptXMLFilterCriteria.
--					This will be used to constuct the WHERE clause for the purpose of loading a temporary
--					table of CASEIDs against which the Global Name Change will be applied.
-- 03 Jul 2012	LP	R12446	6	Avoid use of global temp table to store CASEIDs as this was being dropped before processing starts.
--					Create BACKGROUNDPROCESS, CASENAMEREQUEST and CASENAMEREQUESTCASES when this is called.
-- 28 May 2013	DL	10030	7	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 04 Aug 2014	AT	R36958	8	Add options to change addresses.
-- 05 Aug 2014	SS	36960	9	Move reminders to the new name based on the users choice
-- 07 Aug 2014	AT	R36959	10	Add reset address flag.
-- 19 Jul 2017	MF	71968	11	When determining the default Case program, first consider the Profile of the User.
-- 01 Oct 2018	MF	74987	12	Output parameter to csw_ConstructCaseWhere to be nvarchar(max).


SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON

Declare @sSQLString     nvarchar(max)
Declare @sWhereFilter	nvarchar(max)
Declare @sInterimTable  nvarchar(50)
Declare @nErrorCode	int
Declare @idoc 		int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
declare	@sCommand	varchar(max)
declare	@nObject	int
declare	@nObjectExist	tinyint
Declare @sProgramId	nvarchar(30)
declare @TranCountStart	int
declare @nBackgroundProcessId int
declare @nRequestNo	int


-- Initialise variables
Set  @nErrorCode    = 0
Set  @sInterimTable = '##INTERIMLIST_' + Cast(@@SPID as varchar(10))

-- Set the ProgramId 
If @psProgramId is null or @psProgramId = ''
Begin
	Select @psProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
	from SITECONTROL S
	     join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
	left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
					and PA.ATTRIBUTEID=2)	-- Default Cases Program
	where S.CONTROLID='Case Screen Default Program'
End

-------------------------------------------------
-- Remove any preexisting global temporary tables
-------------------------------------------------

If exists(select * from tempdb.dbo.sysobjects where name = @sInterimTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "Drop table "+@sInterimTable
	
	Exec @nErrorCode = sp_executesql @sSQLString
End

If @nErrorCode = 0
and @psProgramId is not null
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- The Global Name Change Process is added to the BackgroundProcess list
	If @pbCalledFromCentura=0
	Begin
		Set @sSQLString="Insert into BACKGROUNDPROCESS (IDENTITYID,PROCESSTYPE, STATUS, STATUSDATE)
		Values (@pnUserIdentityId,'GlobalNameChange',1, getDate())"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId int',
				  @pnUserIdentityId = @pnUserIdentityId

		If @nErrorCode = 0
		Begin
			Set @nBackgroundProcessId = IDENT_CURRENT('BACKGROUNDPROCESS') 
		End
		
		If @pbCalledFromCentura=0
		Begin
			Set @sSQLString="
			SET IDENTITY_INSERT CASENAMEREQUEST ON	
			
			insert into CASENAMEREQUEST(REQUESTNO, PROGRAMID,NAMETYPE,CURRENTNAMENO,CURRENTATTENTION,NEWNAMENO,NEWATTENTION,
					    UPDATEFLAG,INSERTFLAG,DELETEFLAG,KEEPATTENTIONFLAG,KEEPREFERENCEFLAG,
					    INHERITANCEFLAG,MOVEALERTSFLAG,NEWREFERENCE,COMMENCEDATE,CURRENTADDRESSCODE,ADDRESSCODE,RESETADDRESSFLAG,ONHOLDFLAG,IDENTITYID,
					    RESETATTENTIONFLAG,FROMDEFAULTATTENTIONFLAG,FROMDEFAULTADDRESSFLAG)
			values(@nBackgroundProcessId,@psProgramId,@psNameType,@pnExistingNameNo,@pnExistingCorrespondName,@pnNewNameNo,@pnNewCorrespondName,
			@pbUpdateName,@pbInsertName,@pbDeleteName,@pbKeepCorrespondName,@pnKeepReferenceNo,
			@pbApplyInheritance,@pbMoveAlerts,@psReferenceNo,@pdtCommenceDate,@pnExistingAddressKey,@pnNewAddressKey,@pbResetAddress,1,@pnUserIdentityId,
			@pbResetAttention,@pbFromDefaultAttention,@pbFromDefaultAddress)

			set @nRequestNo=SCOPE_IDENTITY()

			SET IDENTITY_INSERT CASENAMEREQUEST OFF
			"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nBackgroundProcessId		int,
					  @psProgramId			nvarchar(20),
					  @psNameType			nvarchar(3),
					  @pnExistingNameNo		int,
					  @pnExistingCorrespondName	int,
					  @pnExistingAddressKey		int,
					  @pnNewNameNo			int,
					  @pnNewCorrespondName		int,
					  @pnNewAddressKey		int,
					  @pbResetAddress		bit,
					  @pbUpdateName			bit,
					  @pbInsertName			bit,
					  @pbDeleteName			bit,
					  @pbKeepCorrespondName		bit,
					  @pnKeepReferenceNo		smallint,
					  @pbApplyInheritance		bit,
					  @pbMoveAlerts			bit,
					  @psReferenceNo		nvarchar(80),
					  @pdtCommenceDate		datetime,
					  @nRequestNo			int	OUTPUT,
					  @pnUserIdentityId		int,
					  @pbResetAttention		bit,
					  @pbFromDefaultAttention	bit,
					  @pbFromDefaultAddress		bit',
					  @nBackgroundProcessId		=@nBackgroundProcessId,	
					  @psProgramId			=@psProgramId,
					  @psNameType			=@psNameType,
					  @pnExistingNameNo		=@pnExistingNameNo,
					  @pnExistingCorrespondName	=@pnExistingCorrespondName,
					  @pnExistingAddressKey		=@pnExistingAddressKey,
					  @pnNewNameNo			=@pnNewNameNo,
					  @pnNewCorrespondName		=@pnNewCorrespondName,
					  @pnNewAddressKey		=@pnNewAddressKey,
					  @pbResetAddress		=@pbResetAddress,
					  @pbUpdateName			=@pbUpdateName,
					  @pbInsertName			=@pbInsertName,
					  @pbDeleteName			=@pbDeleteName,
					  @pbKeepCorrespondName		=@pbKeepCorrespondName,
					  @pnKeepReferenceNo		=@pnKeepReferenceNo,
					  @pbApplyInheritance		=@pbApplyInheritance,
					  @pbMoveAlerts			=@pbMoveAlerts,
					  @psReferenceNo		=@psReferenceNo,
					  @pdtCommenceDate		=@pdtCommenceDate,
					  @nRequestNo			=@nRequestNo	OUTPUT,
					  @pnUserIdentityId		=@pnUserIdentityId,
					  @pbResetAttention		=@pbResetAttention,
					  @pbFromDefaultAttention	=@pbFromDefaultAttention,
					  @pbFromDefaultAddress		=@pbFromDefaultAddress
		End	
		
		-- The Cases derived table needs only be constructed when the @bHasCase = 1.
		If  @nErrorCode = 0
		and @ptXMLFilterCriteria is not null
		Begin
			-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
			-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
			-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
			-- table that may hold the filtered list of cases.

			
			exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sWhereFilter	  	OUTPUT, 			
								@psTempTableName 	= @sInterimTable	OUTPUT,	
								@pnUserIdentityId	= @pnUserIdentityId,	
								@psCulture		= @psCulture,	
								@pbIsExternalUser	= 0,
								@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    			@pbCalledFromCentura	= 0	
		End	
		
		----------------------------------------
		-- Insert CaseIds from filtercriteria into the temp table
		----------------------------------------
		Set @sSQLString = "INSERT INTO CASENAMEREQUESTCASES (REQUESTNO, CASEID)
				  Select @nRequestNo, C.CASEID
				  From CASES C
				  Where 1=1"

		If @sWhereFilter is not null
		Begin
			Set @sSQLString=@sSQLString+char(10)+@sWhereFilter
		End

		Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nRequestNo	int',
				@nRequestNo = @nRequestNo
		
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

If @nErrorCode = 0 
and @psTextTypeCode is not null 
and @psText is not null
and @nRequestNo is not null
Begin
	----------------------------------------
	--Call csw_CaseTextChange. This SP will update the Case Text values for the selected cases
	----------------------------------------
 	Exec @nErrorCode = [dbo].[csw_CaseTextChange]		
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,	
			@psTextTypeCode		= @psTextTypeCode,
			@psText                 = @psText,
			@pnRequestNo		= @nRequestNo
End


If  @nErrorCode = 0
Begin
	------------------------------------------
	-- Build command line to run cs_GlobalNameChange 	
	-----------------------------------------
	Set @sCommand = 'dbo.cs_GlobalNameChange '
	
	If @pnUserIdentityId is not null
			Set @sCommand = @sCommand + "@pnUserIdentityId='" + convert(varchar,@pnUserIdentityId) + "',"

	If @psCulture is not null
		Set @sCommand = @sCommand + "@psCulture='" + convert(varchar,@psCulture) + "',"

	If @psProgramId is not null
		Set @sCommand = @sCommand + "@psProgramId='" + convert(varchar,@psProgramId) + "',"	

	If @psNameType is not null
		Set @sCommand = @sCommand + "@psNameType='" + convert(varchar,@psNameType) + "',"

	If @pnExistingNameNo is not null
		Set @sCommand = @sCommand + "@pnExistingNameNo='" + convert(varchar,@pnExistingNameNo) + "',"

	If @pnExistingCorrespondName is not null
		Set @sCommand = @sCommand + "@pnExistingCorrespondName='" + convert(nvarchar,@pnExistingCorrespondName) + "',"
		
	If @pnExistingAddressKey is not null
		Set @sCommand = @sCommand + "@pnExistingAddressKey='" + convert(nvarchar,@pnExistingAddressKey) + "',"

	If @pnNewNameNo is not null
		Set @sCommand = @sCommand + "@pnNewNameNo='" + convert(varchar,@pnNewNameNo) + "',"

	If @pnNewCorrespondName is not null
		Set @sCommand = @sCommand + "@pnNewCorrespondName='" + convert(nvarchar,@pnNewCorrespondName) + "',"	
		
	If @pnNewAddressKey is not null
		Set @sCommand = @sCommand + "@pnAddressCode='" + convert(nvarchar,@pnNewAddressKey) + "',"
		
	Set @sCommand = @sCommand + "@pbResetAddress='" + convert(nvarchar,@pbResetAddress) + "',"

	Set @sCommand = @sCommand + "@pbUpdateName='" + convert(varchar,@pbUpdateName) + "',"
	Set @sCommand = @sCommand + "@pbInsertName='" + convert(varchar,@pbInsertName) + "',"
	Set @sCommand = @sCommand + "@pbDeleteName='" + convert(varchar,@pbDeleteName) + "',"
	Set @sCommand = @sCommand + "@pbKeepCorrespondName='" + convert(varchar,@pbKeepCorrespondName) + "',"
	Set @sCommand = @sCommand + "@pnKeepReferenceNo='" + convert(varchar,@pnKeepReferenceNo) + "',"
	Set @sCommand = @sCommand + "@pbApplyInheritance='" + convert(varchar,@pbApplyInheritance) + "',"
	Set @sCommand = @sCommand + "@pbAlerts='" + convert(varchar,@pbMoveAlerts) + "',"
	Set @sCommand = @sCommand + "@pbResetAttention='" + convert(varchar,@pbResetAttention) + "',"
	Set @sCommand = @sCommand + "@pbFromDefaultAttention='" + convert(varchar,@pbFromDefaultAttention) + "',"
	Set @sCommand = @sCommand + "@pbFromDefaultAddress='" + convert(varchar,@pbFromDefaultAddress) + "',"

	If @psReferenceNo is not null
		Set @sCommand = @sCommand + "@psReferenceNo='" + convert(varchar,@psReferenceNo) + "',"

	Set @sCommand = @sCommand + "@pbSuppressOutput=0,"

	If @pdtCommenceDate is not null
		Set @sCommand = @sCommand + "@pdtCommenceDate='" + convert(varchar,@pdtCommenceDate,121) + "',"

	Set @sCommand = @sCommand + "@pnRequestNo='"+ convert(varchar,@nRequestNo)+"',"	
	Set @sCommand = @sCommand + "@pbCalledFromCentura=0" 

	---------------------------------------------------------------
	-- Run the command asynchronously using Service Broker (rfc39102)
	--------------------------------------------------------------- 
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
End
		
Return @nErrorCode
GO

Grant execute on dbo.csw_GlobalNameChange to public
GO
