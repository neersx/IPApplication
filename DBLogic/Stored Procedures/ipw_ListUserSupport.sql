-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListUserSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListUserSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListUserSupport.'
	Drop procedure [dbo].[ipw_ListUserSupport]
	Print '**** Creating Stored Procedure dbo.ipw_ListUserSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListUserSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,		-- Is the comma separated list of requested tables (e.g.'Role, AvailableEmployees')
	@pnAccessAccountKey	int	 	= null
)
AS
-- PROCEDURE:	ipw_ListUserSupport
-- VERSION:	18
-- DESCRIPTION:	Returns list of valid values for the requested tables. 
--		Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01-Dec-2003	JEK	RFC408	1	Procedure created
-- 05-Dec-2003	JEK	RFC408	2	Implement NameTitle, NamePresentation, AccountOrganisation
-- 19-Apr-2004	TM	RRC917	3	Implement PortalConfiguration, DataTopic 
-- 18-Jun-2004	TM	RFC1499	4	Remove reference to ua_ListPortalConfigurations.
-- 22-Jun-2004	TM	RFC1085	5	Add two tables: UserTask (sc_ListUserTasks) and Task (ua_ListTasks).
-- 06-Jul-2004	TM	RFC915	6	Add new tables: Module (ua_ListModule) and ModuleSetting (ua_ListModuleSettings).
-- 14-jUL-2004	TM	RFC916	7	Add new UserModule table that calls sc_ListUserModules.
-- 21-Jul-2004	TM	RFC915	8	Return the Description column for the Module table.
-- 16-Nov-2004	TM	RFC869	9	Remove references to ua_ListDataTopics and ua_ListTasks - they are no longer 
--					in use.
-- 17-Nov-2004	JEK	RFC869	10	Tasks result set still required.  Implement via search procedure.
--				11	DataTopic result set still required.  Implement via search procedure.
-- 23-Dec-2004	TM	RFC2162	12	Modify the sorting to use TopicName followed by TopicKey only.
-- 23-Mar-2006	IB	RFC3212	13	Call ua_ListRole instead of calling ipw_ListRoles.
-- 04-May-2006	SW	RFC3212	14	Remove AvailableEmployees and AccountOrganisation
-- 10-Nov-2006	LP	RFC4340	15	Fix OutputRequest XML for list Role request
-- 10-Nov-2009	LP	RFC6712	16	Add new RowAccessProfile table.
-- 15 Apr 2013	DV	R13270	17	Increase the length of nvarchar to 11 when casting or declaring integer
-- 31 Oct 2018	DL	DR-45102	18	Replace control character (word hyphen) with normal sql editor hyphen
-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(1000)
Declare @nNamePresentationKey	nchar(2)	-- Hard coded TableType=71 parameter value for the ipw_ListTableCodes call   
Declare @tXMLModuleRequests	nvarchar(4000)	-- Hard coded XMLOutputRequests value for ua_ListModule call
Declare @tXMLTaskRequests	nvarchar(4000)	-- Hard coded XMLOutputRequests value for ua_ListTask call
Declare @tXMLDataTopicRequests  nvarchar(4000)	-- Hard coded XMLOutputRequests value for ua_ListDataTopic call
Declare @tXMLRoleRequests  	nvarchar(4000)	-- Hard coded XMLOutputRequests value for ua_ListRole call

-- initialise variables
Set @nRow			= 1		

Set @nRowCount			= 0
Set @ErrorCode			= 0
Set @nNamePresentationKey	= '71'
Set @tXMLModuleRequests		= N'<OutputRequests>
			    		<Column ID="ModuleKey" PublishName="ModuleKey" SortOrder="" SortDirection="" />
			    		<Column ID="Title" PublishName="Title" SortOrder="3" SortDirection="A" />
					<Column ID="Description" PublishName="Description" />
			    		<Column ID="IsExternal" PublishName="IsExternal" SortOrder="1" SortDirection="A" />
			    		<Column ID="IsInternal" PublishName="IsInternal" SortOrder="2" SortDirection="A" />				
			 	  </OutputRequests>'
Set @tXMLTaskRequests		= N'<OutputRequests>
					    <Column ID="TaskKey" PublishName="TaskKey" SortOrder="1" SortDirection="A" />
					    <Column ID="TaskName" PublishName="TaskName" />
				  </OutputRequests>'
Set @tXMLDataTopicRequests	= N'<OutputRequests>
					    <Column ID="DataTopicKey" PublishName="TopicKey" SortOrder="2" SortDirection="A" />
					    <Column ID="Name" PublishName="TopicName" SortOrder="1" SortDirection="A"/>
					    <Column ID="Description " PublishName="TopicDescription " />
					    <Column ID="IsExternal" PublishName="IsExternal" />
					    <Column ID="IsInternal" PublishName="IsInternal" />				
				  </OutputRequests>'
Set @tXMLRoleRequests		= N'<OutputRequests>
					    <Column ID="RoleKey" PublishName="RoleKey"/>
					    <Column ID="RoleName" PublishName="RoleName" SortOrder="1" SortDirection="A"/>
					    <Column ID="Description" PublishName="RoleDescription" />
					    <Column ID="IsExternal" PublishName="IsExternal" />
					    <Column ID="IsProtected" PublishName="IsProtected" />				
				  </OutputRequests>'

While @nRow is not null
and @ErrorCode = 0
Begin
	-- Extract the stored procedure's name from the @psTables comma separated string using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'Role'			THEN 'ua_ListRole'
			WHEN 'NameTitle'		THEN 'naw_ListTitles'
			WHEN 'NamePresentation'		THEN 'ipw_ListTableCodes'
			WHEN 'UserTask'			THEN 'sc_ListUserTasks' 
			WHEN 'Module'			THEN 'ua_ListModule'
			WHEN 'ModuleSetting'		THEN 'ua_ListModuleSettings'
			WHEN 'UserModule'		THEN 'sc_ListUserModules'
			WHEN 'Task'			THEN 'ua_ListTask'
			WHEN 'DataTopic'		THEN 'ua_ListDataTopic'
			WHEN 'RowAccessProfile'		THEN 'ipw_ListRowAccessProfile'
			ELSE NULL
		END	
	from fn_Tokenise (@psTables, NULL)
	where InsertOrder = @nRow
	
	Set @nRowCount = @@Rowcount
	

	-- If the dataset name is valid build the string to execute required stored procedure
	If (@nRowCount > 0)
	Begin
		If @sProc is not null
		Begin
			-- Build the parameters

			Set @sParams = '@pnUserIdentityId=' + CAST(@pnUserIdentityId as varchar(11)) 

			If @psCulture is not null
			Begin
				Set @sParams = @sParams + ", @psCulture='" + @psCulture + "'"
			End

			If @sProc = 'ua_ListRole'  
			Begin
				Set @sParams = @sParams + ', @ptXMLOutputRequests = ' + "'" + @tXMLRoleRequests + "'"
			End

			If @sProc = 'ipw_ListTableCodes'  
			Begin

				Set @sParams = @sParams + ', @pnTableTypeKey = ' + @nNamePresentationKey
			End

			If @sProc = 'ua_ListModule'  
			Begin
				Set @sParams = @sParams + ', @ptXMLOutputRequests = ' + "'" + @tXMLModuleRequests + "'"
			End

			If @sProc = 'ua_ListTask'  
			Begin
				Set @sParams = @sParams + ', @ptXMLOutputRequests = ' + "'" + @tXMLTaskRequests + "'"
			End

			If @sProc = 'ua_ListDataTopic'  
			Begin
				Set @sParams = @sParams + ', @ptXMLOutputRequests = ' + "'" + @tXMLDataTopicRequests + "'"
			End

			Exec (@sProc + ' ' + @sParams)	

			Set @ErrorCode=@@Error		
		End

		-- Increment @nRow by one so it points to the next dataset name
		
		Set @nRow = @nRow + 1
	End
	Else 
	Begin
		-- If the dataset name is not valid then exit the 'While' loop
	
		Set @nRow = null
	End

End

RETURN @ErrorCode
GO

Grant execute on dbo.ipw_ListUserSupport to public
GO
