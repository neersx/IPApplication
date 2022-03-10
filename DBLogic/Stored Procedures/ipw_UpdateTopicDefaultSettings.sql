-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTopicDefaultSettings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTopicDefaultSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTopicDefaultSettings.'
	Drop procedure [dbo].[ipw_UpdateTopicDefaultSettings]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTopicDefaultSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateTopicDefaultSettings
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaNo		int		= null,
	@pnNameCriteriaNo	int		= null,
	@psTopicName		nvarchar(50),
	@psFilterName		nvarchar(50),
	@psFilterValue		nvarchar(250)	= null,
	@psRowKey               nvarchar(10)    = null,
	@pbIsInherited          bit             = null,
	@pbApplyToChildren      bit             = 0                    
)
as
-- PROCEDURE:	ipw_UpdateTopicDefaultSettings
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Default Settings for Case Criteria / Name Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Dec 2009	MS	RFC8469	1	Procedure created
-- 08 Jul 2011  MS      R10851  2       Use DEFAULTSETTINGNO in where condition for Update and Delete
-- 29 Aug 2011  MS      R11024  3       Apply inheritance

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_NULLS ON

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(MAX)
Declare @bIsNameCriteria bit

-- Initialise variables
Set @nErrorCode = 0
Set @bIsNameCriteria = CASE WHEN @pnNameCriteriaNo is null then 0 else 1 end

If @nErrorCode = 0
Begin
	If @psRowKey is not null and ISNUMERIC(@psRowKey) <> 0 and
	exists (Select 1 from TOPICDEFAULTSETTINGS where DEFAULTSETTINGNO = @psRowKey)
	Begin
		If @psFilterValue is not null and @psFilterValue <> ''
		Begin
			Set @sSQLString = " 
			Update 	TOPICDEFAULTSETTINGS
			Set	FILTERVALUE = @psFilterValue,
			        ISINHERITED = 0
			Where	DEFAULTSETTINGNO = @psRowKey"
			
			exec @nErrorCode=sp_executesql @sSQLString,
			N'@psFilterValue	nvarchar(254),
			@psRowKey		nvarchar(10)',
			@psFilterValue	        = @psFilterValue,
			@psRowKey               = @psRowKey
			
			If @nErrorCode = 0 and @pbApplyToChildren=1
		        Begin
		                If @pnNameCriteriaNo is not null
				Begin
				        UPDATE TOPICDEFAULTSETTINGS 
				        SET FILTERVALUE = @psFilterValue				        
					WHERE NAMECRITERIANO in (
					        Select CRITERIANO 
					        from dbo.fn_GetChildCriteria (@pnNameCriteriaNo,@bIsNameCriteria) 
					        where CRITERIANO <> @pnNameCriteriaNo)
					and ISINHERITED = 1 
					and TOPICNAME = @psTopicName
					and FILTERNAME = @psFilterName
	        			
					Set @nErrorCode=@@Error
				End
				Else Begin
					UPDATE TOPICDEFAULTSETTINGS 
				        SET FILTERVALUE = @psFilterValue				        
					WHERE CRITERIANO in (
					        Select CRITERIANO 
					        from dbo.fn_GetChildCriteria (@pnCriteriaNo,@bIsNameCriteria) 
					        where CRITERIANO <> @pnCriteriaNo)
					and ISINHERITED=1 
					and TOPICNAME = @psTopicName
					and FILTERNAME = @psFilterName
	        			
					Set @nErrorCode=@@Error
				End
		        End
		End
		ELSE
		Begin
			Set @sSQLString = "
			Delete from TOPICDEFAULTSETTINGS
			Where	DEFAULTSETTINGNO = @psRowKey"
			
			exec @nErrorCode=sp_executesql @sSQLString,
			N'@psFilterValue	nvarchar(254),
			@psRowKey		nvarchar(10)',
			@psFilterValue	        = @psFilterValue,
			@psRowKey               = @psRowKey
			
			If @nErrorCode = 0 and @pbApplyToChildren=1
		        Begin
		                If @pnNameCriteriaNo is not null
				Begin
					Delete TD
					from dbo.fn_GetChildCriteria (@pnNameCriteriaNo,@bIsNameCriteria) C
					join TOPICDEFAULTSETTINGS TD on (TD.NAMECRITERIANO=C.CRITERIANO)
					where TD.ISINHERITED=1 
					and TD.TOPICNAME = @psTopicName
					and TD.FILTERNAME = @psFilterName
					and C.CRITERIANO <> @pnNameCriteriaNo
	        			
					Set @nErrorCode=@@Error
				End
				Else Begin
					Delete TD
					from dbo.fn_GetChildCriteria (@pnCriteriaNo,@bIsNameCriteria) C
					join TOPICDEFAULTSETTINGS TD on (TD.CRITERIANO=C.CRITERIANO)
					where TD.ISINHERITED=1
					and TD.TOPICNAME = @psTopicName
					and TD.FILTERNAME = @psFilterName
					and C.CRITERIANO <> @pnCriteriaNo
	        			
					Set @nErrorCode=@@Error
				End
		        End
		End
		
	End	
	Else If @psFilterValue is not null and @psFilterValue <> ''
	begin
		Set @sSQLString = " 
		Insert into TOPICDEFAULTSETTINGS (CRITERIANO, NAMECRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE,ISINHERITED)
			values (@pnCriteriaNo, @pnNameCriteriaNo, @psTopicName, @psFilterName, @psFilterValue,0)"	

	        exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCriteriaNo		int,
			  @pnNameCriteriaNo	int,
			  @psTopicName		nvarchar(50),					 
			  @psFilterName 	nvarchar(50),
			  @psFilterValue	nvarchar(254)',
			  @pnCriteriaNo		= @pnCriteriaNo,
			  @pnNameCriteriaNo	= @pnNameCriteriaNo,
			  @psTopicName		= @psTopicName,					
			  @psFilterName		= @psFilterName,
			  @psFilterValue	= @psFilterValue	
			  
                If @nErrorCode = 0 and @pbApplyToChildren=1
		Begin
		        If @bIsNameCriteria = 0
			Begin
				INSERT INTO TOPICDEFAULTSETTINGS(CRITERIANO, NAMECRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE,ISINHERITED)
				SELECT C.CRITERIANO,NULL,TD.TOPICNAME, TD.FILTERNAME, TD.FILTERVALUE, 1
				FROM dbo.fn_GetChildCriteria (@pnCriteriaNo,@bIsNameCriteria) C 
				join TOPICDEFAULTSETTINGS TD on (TD.CRITERIANO = @pnCriteriaNo)
				where C.CRITERIANO <> @pnCriteriaNo
				and TD.TOPICNAME = @psTopicName
				and TD.FILTERNAME = @psFilterName
				and C.CRITERIANO not in (
				        SELECT CS.CRITERIANO from TOPICDEFAULTSETTINGS TS
				        join dbo.fn_GetChildCriteria (@pnCriteriaNo,@bIsNameCriteria) CS on (TS.CRITERIANO = CS.CRITERIANO)
				        where TS.TOPICNAME = TD.TOPICNAME
				        and TS.FILTERNAME = TD.FILTERNAME
				        and TS.CRITERIANO <> TD.CRITERIANO)
			End
			Else If @bIsNameCriteria = 1
			Begin
				INSERT INTO TOPICDEFAULTSETTINGS(CRITERIANO, NAMECRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE, ISINHERITED)
				SELECT NULL,C.CRITERIANO,TD.TOPICNAME, TD.FILTERNAME, TD.FILTERVALUE, 1
				FROM dbo.fn_GetChildCriteria (@pnNameCriteriaNo,@bIsNameCriteria) C 
				join TOPICDEFAULTSETTINGS TD on (TD.NAMECRITERIANO = @pnNameCriteriaNo)
				where C.CRITERIANO <> @pnNameCriteriaNo
				and TD.TOPICNAME = @psTopicName
				and TD.FILTERNAME = @psFilterName
				and C.CRITERIANO not in (
				        SELECT CS.CRITERIANO from TOPICDEFAULTSETTINGS TS
				        join dbo.fn_GetChildCriteria (@pnNameCriteriaNo,@bIsNameCriteria) CS on (TS.NAMECRITERIANO = CS.CRITERIANO)
				        where TS.TOPICNAME = TD.TOPICNAME
				        and TS.FILTERNAME = TD.FILTERNAME
				        and TS.NAMECRITERIANO <> TD.NAMECRITERIANO)
			End
	        End		  
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTopicDefaultSettings to public
GO
