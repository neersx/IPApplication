-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListGeneralSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListGeneralSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListGeneralSupport.'
	Drop procedure [dbo].[ipw_ListGeneralSupport]
	Print '**** Creating Stored Procedure dbo.ipw_ListGeneralSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListGeneralSupport
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,	-- Is the comma separated list of requested tables 
							-- (e.g.'ImageStatus,ImageType')
	@pnSubjectKey		int		= null  -- An optional key for addiational filtering
)
AS
-- PROCEDURE:	ipw_ListGeneralSupport
-- VERSION:	25
-- DESCRIPTION:	Returns list of valid values for the requested tables. 
--		Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 29-Mar-2006	IB	RFC3388	1	Procedure created
-- 13-Apr-2006	SF	RFC3388 2	Add SearchOperator support table entry point
-- 27-Mar-2007	PG	RFC3646	3	Add DocumentRequestNameType entry point
-- 12-Oct-2007	vql	RFC3500	4	Add entry point DeviceType and Carrier.
-- 21-Nov-2007	vql	RFC5762	5	Add entry point Source, Name Status.
-- 29-Apr-2008	AT	RFC6512	6	Add Sender RequestType.
-- 13-Oct-2008	SF	RFC6510	7	Add TableType, ModifiableTableCodeTypes
-- 20-Nov-2008	NG	RFC6921	8	Add Program
-- 06-Jul-2009	MS	RFC7085	9	Add SubjectKey to Program type
-- 30-Aug-2009	MS	RFC8288	10	Add entry point ExchangeSchedule
-- 11-Sep-2009	LP	RFC8047	11	Add UserProfile picklist.
-- 15 Sep 2009	LP	RFC8047	12	Add ValidProfileAttributes and ProfileAttributeTypes picklist.
-- 21 Dec 2009	NG	RFC8631	13	Add Function picklist.
-- 30 Dec 2009  MS	RFC8649 14	Add ValidActions
-- 21 May 2010  JC	RFC6229 15	Add ActivityType, ActivityCategory, DeliveryMethod, CorrespondenceType, InstructionType and EntryPointType
-- 21 Oct 2010	DV	RFC9437	16	Add SearchColumn, SearchColumnGroup
-- 07 Dec 2010	JC	RFC9624	17	Add Language and Remove ActivityType and ActivityCategory (they belong to mk_ListContactSupport)
-- 01 Feb 2011	DV	RFC9387	18  Add CaseTableColumn
-- 14 Feb 2011  MS  RFC8363 19  Add Device 
-- 25 Mar 2011  MS  RFC100502 20Add FilePartType, FileRecordStatus, FileRequestStatus and Priority
-- 02 Dec 2011  MS  R11208  21  Add FilePartSearchStatus and FilesDepartmentStaff
-- 31 Aug 2012	ASH	R100753	22  Add NameTableColumn
-- 15 Apr 2013	DV	R13270	23	Increase the length of nvarchar to 11 when casting or declaring integer
-- 21 Jun 2013  MS      DR108   24      Added Country Attribute type
-- 07 Sep 2018	AV	74738	25	Set isolation level to read uncommited.


-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare variables
Declare	@nErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(4000)
Declare @sWorkParam		varchar(1000)

-- initialise variables
Set @nRow			= 1	

Set @nRowCount			= 0
Set @nErrorCode			= 0

While @nRow is not null
and @nErrorCode = 0
Begin
	-- Extract the stored procedure's name from the @psTables comma separated string 
	-- using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'ImageStatus'				THEN 'ipw_ListTableCodes11'
			WHEN 'ImageType'				THEN 'ipw_ListTableCodes12'
			WHEN 'SearchOperator'				THEN 'ipw_ListTableCodes112'
			WHEN 'DeviceType'				THEN 'ipw_ListTableCodes19'
			WHEN 'Carrier'					THEN 'ipw_ListTableCodes5'
			WHEN 'Source'					THEN 'ipw_ListTableCodes143'
			WHEN 'NameStatus'				THEN 'ipw_ListTableCodes144'			
			WHEN 'DocumentRequestNameType'		        THEN 'ipw_ListDocumentRequestNameTypes'
			WHEN 'RequestType'				THEN 'ede_ListRequestType'
			WHEN 'TableType'				THEN 'ipw_ListTableTypes'
			WHEN 'ModifiableTableCodeTypes'		        THEN 'ipw_ListTableTypesTABLECODES'
			WHEN 'Program'					THEN 'ipw_ListPrograms'
			WHEN 'ExchangeRateSchedule'			THEN 'ipw_ListExchangeSchedule'
			WHEN 'UserProfile'				THEN 'ipw_ListUserProfile'
			WHEN 'ValidProfileAttributes'		        THEN 'ipw_ListValidProfileAttributes'
			WHEN 'ProfileAttributeTypes'		        THEN 'ipw_ListProfileAttributeTypes'
			WHEN 'ValidActions'				THEN 'ipw_ListValidActions'
			WHEN 'Function'					THEN 'ipw_ListFunctions'
			WHEN 'ActivityType'				THEN 'ipw_ListTableCodes58'
			WHEN 'DeliveryMethod'				THEN 'ipw_ListDeliveryMethods'
			WHEN 'CorrespondenceType'			THEN 'ipw_ListCorrespondenceTypes'
			WHEN 'InstructionType'				THEN 'ipw_InstructionTypes'
			WHEN 'EntryPointType'				THEN 'ipw_ListTableCodes141'
			WHEN 'SearchColumn'				THEN 'ipw_ListSearchColumns'
			WHEN 'SearchColumnGroup'			THEN 'ipw_ListSearchColumnGroups'
                        WHEN 'Device'                                   THEN 'ipw_ListResources1' 
			WHEN 'Language'					THEN 'ipw_ListTableCodes47'
			WHEN 'CaseTableColumn'				THEN 'ipw_ListTableCodes-502'
			WHEN 'NameTableColumn'				THEN 'ipw_ListTableCodes-502'
                        WHEN 'FileRequestStatus'                        THEN 'ipw_ListFileRequestSupport0'
                        WHEN 'FileRecordStatus'                         THEN 'ipw_ListFileRequestSupport1'
                        WHEN 'FilePartType'                             THEN 'ipw_ListFileRequestSupport2'
                        WHEN 'FileRequestPriority'                      THEN 'ipw_ListPriority'
                        WHEN 'FilePartSearchStatus'                     THEN 'ipw_ListFileRequestSupport3'
                        WHEN 'CountryAttributeType'			THEN 'csw_ListCountryAttributeTypes'
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

			If @sProc like 'ipw_ListTableCodes%'  
			Begin
				-- For the ipw_ListTableCodes the @pnTableTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnTableTypeKey = ' + substring(@sProc, 19, 5)

				-- Extended in version 2
				If @sProc = 'ipw_ListTableCodes112'  
				Begin
					-- When table code user key is key of the table type.
					Set @sParams = @sParams + ', @pbIsKeyUserCode = 1'
				End
				If @sProc = 'ipw_ListTableCodes-502'  and @psTables = 'CaseTableColumn'
				Begin
					-- When table code user key is key of the table type.
					Set @sParams = @sParams + ', @psUserCode = "C"'
				End
				
				If @sProc = 'ipw_ListTableCodes-502'  and @psTables = 'NameTableColumn'
				Begin
					-- When table code user key is key of the table type.
					Set @sParams = @sParams + ', @psUserCode = "N"'
				End
				
				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End
			If @sProc like 'ipw_ListDocumentRequestNameTypes' and @pnSubjectKey is not null
			Begin
				Set @sParams = @sParams + ', @pnDocumentRequestTypeKey = ' + CAST(@pnSubjectKey as nvarchar(11))
			End
			If @sProc like 'ipw_ListTableTypes%'
			Begin
				-- For the ipw_ListTableTypes the @psDatabaseTables is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				
				Set @sWorkParam =  substring(@sProc, 19, LEN(@sProc)-18)
				
				If LEN(@sWorkParam)>0
				Begin				
					Set @sParams = @sParams + ', @psDatabaseTables = ' + @sWorkParam				
				End
				
				-- Cut off the @psDatabaseTables from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableTypes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End
			If @sProc like 'ipw_ListPrograms' and @pnSubjectKey is not null
			Begin
				Set @sParams = @sParams + ', @pnProgramFilterKey = ' + CAST(@pnSubjectKey as nvarchar(11))
			End
			If @sProc like 'ipw_ListValidProfileAttributes' and @pnSubjectKey is not null
			Begin
				Set @sParams = @sParams + ', @pnAttributeKey = ' + CAST(@pnSubjectKey as nvarchar(11))
			End
			If @sProc like 'ipw_ListValidActions' and @pnSubjectKey is not null
			Begin
				Set @sParams = @sParams + ', @pnCriteriaKey = ' + CAST(@pnSubjectKey as nvarchar(11))
			End
                        If @sProc like 'ipw_ListResources%' 
			Begin
				-- For the ipw_ListResources the @pnResourceTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnResourceTypeKey = ' + substring(@sProc, 18, 5)

				-- Cut off the @pnResourceTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListResources' 
				Set @sProc = substring(@sProc, 1, 17)  
			End
			If @sProc like 'ipw_ListFileRequestSupport%'
			Begin		        
			        
			        -- For the ipw_ListFileRequestSupport the @pnType is concatenated at the end of 
				-- the @sProc string so cut it off and pass it to the stored procedure: 
			        Set @sParams = @sParams + ', @pnType = ' + substring(@sProc, 27, 2)
			        
			        -- Cut off the @pnType from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListFileRequestSupport' 
				Set @sProc = substring(@sProc, 1, 26) 
			End
			
			Exec (@sProc + ' ' + @sParams)	

			Set @nErrorCode=@@Error		
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

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ListGeneralSupport to public
GO
