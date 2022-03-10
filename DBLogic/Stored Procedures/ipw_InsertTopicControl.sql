-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTopicControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTopicControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTopicControl.'
	Drop procedure [dbo].[ipw_InsertTopicControl]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTopicControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_InsertTopicControl]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnTopicControlKey			int		= null	output,
	@pnWindowControlNo			int,
	@psTopicName				nvarchar(50),
	@psTopicSuffix				nvarchar(50)	= null,
	@pnRowPosition				smallint,
	@pnColPosition				smallint,
	@pnTabControlNo				int		= null,
	@psTopicTitle				nvarchar(254)	= null,
	@psTopicShortTitle			nvarchar(254)	= null,
	@psTopicDescription			nvarchar(254)	= null,
	@pbDisplayDescription		        bit		= 0,
	@psFilterName				nvarchar(50)	= null,
	@psFilterValue				nvarchar(254)	= null,
	@psScreenTip				nvarchar(254)	= null,
	@pbIsHidden				bit		= 0,
	@pbIsMandatory				bit		= 0,
	@pbIsInherited				bit		= 0,
	@pbApplyToDecendants		        bit		= 0
)
as
-- PROCEDURE:	ipw_InsertTopicControl
-- VERSION:	5
-- DESCRIPTION:	Add a new TopicControl.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2008	KR	RFC6732	1	Procedure created
-- 04 Feb 2009	JC	RFC6732	2	Fix Issues
-- 29 Jan 2010	KR	RFC8791 3	Do not insert topic to children who already have the topic
-- 05 Jul 2011  MS      RFC10722 4      Fix issue where some tabs not getting added to child criteria
-- 16 Sep 2011  MS      RFC11016 5      Fix issue where topic of child criteria was not being created if 
--                                      same topic name for other windowcontrol exists for that criteria      

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Insert new topic
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into TOPICCONTROL
		(WINDOWCONTROLNO,
		 TOPICNAME,
		 TOPICSUFFIX,
		 ROWPOSITION,
		 COLPOSITION,
		 TABCONTROLNO,
		 TOPICTITLE,
		 TOPICSHORTTITLE,
		 TOPICDESCRIPTION,
		 DISPLAYDESCRIPTION,
		 FILTERNAME,
		 FILTERVALUE,
		 SCREENTIP,
		 ISHIDDEN,
		 ISMANDATORY,
		 ISINHERITED 
		)
	values
	  ( @pnWindowControlNo,
		@psTopicName,
		@psTopicSuffix,
		@pnRowPosition,
		@pnColPosition,
		@pnTabControlNo,
		@psTopicTitle,
		@psTopicShortTitle,
		@psTopicDescription,
		@pbDisplayDescription,
		@psFilterName,
		@psFilterValue,
		@psScreenTip,
		@pbIsHidden,
		@pbIsMandatory,
		@pbIsInherited
	  )
	Set @pnTopicControlKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTopicControlKey		int		output,
					  @pnWindowControlNo		int,
					  @psTopicName				nvarchar(50),
					  @psTopicSuffix			nvarchar(50),
					  @pnRowPosition			smallint,
					  @pnColPosition			smallint,
					  @pnTabControlNo			int,
					  @psTopicTitle				nvarchar(254),
					  @psTopicShortTitle		nvarchar(254),
					  @psTopicDescription		nvarchar(254),
					  @pbDisplayDescription		smallint,
					  @psFilterName				nvarchar(50),
					  @psFilterValue			nvarchar(254),
					  @psScreenTip				nvarchar(254),
					  @pbIsHidden				bit,
					  @pbIsMandatory			bit,
					  @pbIsInherited			bit',					 
					  @pnTopicControlKey		= @pnTopicControlKey output,					 
					  @pnWindowControlNo		= @pnWindowControlNo,
					  @psTopicName				= @psTopicName,
					  @psTopicSuffix			= @psTopicSuffix,
					  @pnRowPosition			= @pnRowPosition,
					  @pnColPosition			= @pnColPosition,
					  @pnTabControlNo			= @pnTabControlNo,
					  @psTopicTitle				= @psTopicTitle,
					  @psTopicShortTitle		= @psTopicShortTitle,
					  @psTopicDescription		= @psTopicDescription,
					  @pbDisplayDescription		= @pbDisplayDescription,
					  @psFilterName				= @psFilterName,
					  @psFilterValue			= @psFilterValue,
					  @psScreenTip				= @psScreenTip,
					  @pbIsHidden				= @pbIsHidden,
					  @pbIsMandatory			= @pbIsMandatory,
					  @pbIsInherited			= @pbIsInherited	

	Select @pnTopicControlKey as TopicControlKey
End

-- Apply to all children
If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	--Get information about WINDOWCONTROL and TABCONTROL for that new TOPIC
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName nvarchar(50)
	Declare @bIsExternal bit
	Declare @sTabName nvarchar(50)

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@sWindowName = WC.WINDOWNAME,
			@bIsExternal = WC.ISEXTERNAL,
			@sTabName = TC.TABNAME
	from WINDOWCONTROL WC
	left join TABCONTROL TC on (TC.TABCONTROLNO = @pnTabControlNo)
	where WC.WINDOWCONTROLNO = @pnWindowControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @sTabName				nvarchar(50) OUTPUT,
			  @pnTabControlNo		int,
			  @pnWindowControlNo	int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @sTabName = @sTabName OUTPUT,
			  @pnTabControlNo = @pnTabControlNo,
			  @pnWindowControlNo = @pnWindowControlNo

	--Insert new topic to all children. Condition: If the topic is attached to a TABCONTROL, then the TABCONTROL.ISINHERITED=1
	-- Otherwise, WINDOWCONTROL.ISINHERITED=1 
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		insert 	into TOPICCONTROL
			(WINDOWCONTROLNO,
			 TOPICNAME,
			 TOPICSUFFIX,
			 ROWPOSITION,
			 COLPOSITION,
			 TABCONTROLNO,
			 TOPICTITLE,
			 TOPICSHORTTITLE,
			 TOPICDESCRIPTION,
			 DISPLAYDESCRIPTION,
			 FILTERNAME,
			 FILTERVALUE,
			 SCREENTIP,
			 ISHIDDEN,
			 ISMANDATORY,
			 ISINHERITED)
		Select WC.WINDOWCONTROLNO, 
			@psTopicName,
			@psTopicSuffix,
			@pnRowPosition,
			@pnColPosition,
			TC.TABCONTROLNO,
			@psTopicTitle,
			@psTopicShortTitle,
			@psTopicDescription,
			@pbDisplayDescription,
			@psFilterName,
			@psFilterValue,
			@psScreenTip,
			@pbIsHidden,
			@pbIsMandatory,
			1
		from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
								  )
		Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and TC.TABNAME = @sTabName
									and TC.ISINHERITED = 1)
		Left Join TOPICCONTROL TP ON (TP.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and (TC.TABCONTROLNO is null or TP.TABCONTROLNO = TC.TABCONTROLNO)
									and TP.TOPICNAME = @psTopicName
									and (
											(@psTopicSuffix is null and TP.TOPICSUFFIX is null)
										 or (@psTopicSuffix is not null and TP.TOPICSUFFIX = @psTopicSuffix)
										)
									) 
		where ( (TC.TABCONTROLNO is NULL and WC.ISINHERITED = 1) or TC.TABCONTROLNO is not NULL)
			and TP.WINDOWCONTROLNO is null
			and C.CRITERIANO not in ( select case when @bIsNameCriteria = 0 then CRITERIANO else NAMECRITERIANO end as CriteriaNo from WINDOWCONTROL WC1
									join TOPICCONTROL TP1 on(TP1.TOPICNAME = @psTopicName and WC1.WINDOWCONTROLNO = TP1.WINDOWCONTROLNO )
									where CriteriaNo is not null and WC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO) "
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int,
			  @bIsNameCriteria		bit,
			  @bIsExternal			bit,
			  @sWindowName			nvarchar(50),
			  @pnWindowControlNo	int,
			  @sTabName				nvarchar(50),
			  @psTopicName			nvarchar(50),
			  @psTopicSuffix		nvarchar(50),
			  @pnRowPosition		smallint,
			  @pnColPosition		smallint,
			  @psTopicTitle			nvarchar(254),
			  @psTopicShortTitle	nvarchar(254),
			  @psTopicDescription	nvarchar(254),
			  @pbDisplayDescription	smallint,
			  @psFilterName			nvarchar(50),
			  @psFilterValue		nvarchar(254),
			  @psScreenTip			nvarchar(254),
			  @pbIsHidden			bit,
			  @pbIsMandatory		bit',					 
			  @nCriteriaNo			= @nCriteriaNo,
			  @bIsNameCriteria      = @bIsNameCriteria,
			  @bIsExternal			= @bIsExternal,
			  @sWindowName			= @sWindowName,
			  @pnWindowControlNo	= @pnWindowControlNo,
			  @sTabName				= @sTabName,
			  @psTopicName			= @psTopicName,
			  @psTopicSuffix		= @psTopicSuffix,
			  @pnRowPosition		= @pnRowPosition,
			  @pnColPosition		= @pnColPosition,
			  @psTopicTitle			= @psTopicTitle,
			  @psTopicShortTitle	= @psTopicShortTitle,
			  @psTopicDescription	= @psTopicDescription,
			  @pbDisplayDescription	= @pbDisplayDescription,
			  @psFilterName			= @psFilterName,
			  @psFilterValue		= @psFilterValue,
			  @psScreenTip			= @psScreenTip,
			  @pbIsHidden			= @pbIsHidden,
			  @pbIsMandatory		= @pbIsMandatory
	End

	--Increment RowPosition for all children. Condition: If the topic is attached to a TABCONTROL, then TABCONTROL.ISINHERITED=1
	-- Otherwise, WINDOWCONTROL.ISINHERITED=1 
	If @nErrorCode = 0
	Begin

		UPDATE TP2 SET TP2.ROWPOSITION = TP2.ROWPOSITION + 1
			from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
			join WINDOWCONTROL WC on (WC.WINDOWNAME = @sWindowName
										and (
												(@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
												or
												(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo)
											)
										and WC.ISEXTERNAL = @bIsExternal
									  )
			left join TABCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and TC.TABNAME = @sTabName
										and TC.ISINHERITED = 1)
			join TOPICCONTROL TP1 ON (TP1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									 and (TC.TABCONTROLNO is null or TP1.TABCONTROLNO = TC.TABCONTROLNO)
									 and TP1.TOPICNAME = @psTopicName
									 and (
											(@psTopicSuffix is null and TP1.TOPICSUFFIX is null)
										 or (@psTopicSuffix is not null and TP1.TOPICSUFFIX = @psTopicSuffix)
										))
			join TOPICCONTROL TP2 ON (TP2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and (TC.TABCONTROLNO is null or TP2.TABCONTROLNO = TC.TABCONTROLNO)
									and TP2.TOPICNAME != @psTopicName
									and (
										(@psTopicSuffix is null and TP2.TOPICSUFFIX is null)
										or (@psTopicSuffix is not null and TP2.TOPICSUFFIX != @psTopicSuffix)
										)
									and TP2.ROWPOSITION >= TP1.ROWPOSITION)
			where ( (TC.TABCONTROLNO is NULL and WC.ISINHERITED = 1) or TC.TABCONTROLNO is not NULL)
			and C.CRITERIANO not in ( select case when @bIsNameCriteria = 0 then CRITERIANO else NAMECRITERIANO end  from WINDOWCONTROL WC1
									join TOPICCONTROL TP1 on(TP1.TOPICNAME = @psTopicName and WC1.WINDOWCONTROLNO = TP1.WINDOWCONTROLNO )) 

			
		set @nErrorCode = @@error

	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTopicControl to public
GO