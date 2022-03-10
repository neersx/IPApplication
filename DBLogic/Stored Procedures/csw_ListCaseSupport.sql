-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseSupport.'
	Drop procedure [dbo].[csw_ListCaseSupport]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListCaseSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,		-- Is the comma separated list of requested tables (e.g.'CaseType,PropertyType')
	@pnCaseKey		int	 	= null,
	@pnCaseAccessMode	int		= 1,		/* 0-Return All, 1=Select, 4=insert, 8=update */
	@pbIsExternalUser	bit		= null
)
AS
-- PROCEDURE:	csw_ListCaseSupport
-- VERSION:	49
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14-Nov-2003	TM	RFC396	1	Procedure created
-- 17-Nov-2003	TM	RFC396	2	Change @psCaseKey varchar(10) to @pnCaseKey int.
-- 19-Nov-2003	TM	RFC396	3	Modify comments accordingly to the coding standards
-- 01-Dec-2003	JEK	RFC396	4	Fix case in Ipw_ListValidSubType.
-- 05-Feb-2004	TM	RFC642	5	Implement the following new tables: CaseStatus, RenewalStatus, 
--					CaseAttributeType, Instructions
-- 20-Apr-2004	TM	RFC919	6	Implement the two new tables:
--					QueryGroup (qr_ListQueryGroups), ValidExportFormat (qr_ListValidExportFormat).
-- 23 Apr 2004	TM	RFC1334	7	Add a new ImportanceLevel option implemented as ipw_ListImportanceLevel without 
--					any site control parameter.
-- 08 Jul 2004	TM	RFC1230	8	Add Action (ipw_ListAction) and StaffNameType (ipw_ListNameType) tables.
-- 26 Jul 2004	TM	RFC1323	9	Add an EventCategory table implemented via ipw_ListEventCategories.
-- 02 Dec 2005	TM	RFC3276	10	Add a new Language table. 
-- 09 Dec 2005	TM	RFC3275	11	Add a new csw_ListValidRelations table.
-- 15 Dec 2005	TM	RFC3255	12	Implement new Office, EntitySize, TaxTreatment and ValidCaseStatus tables.
-- 04 Jan 2006	TM	RFC2483 13	Add new InstructionCharacteristic table.
-- 27 Mar 2006	IB	RFC3378 14	Add InstructionType, StandingInstructions and PeriodType tables.
-- 29 Mar 2006	IB	RFC3388 15	Add DesignElement table.
-- 23 May 2006	IB	RFC3678 16	Add AdjustmentType table implemented via ipw_ListAdjustmentTypes 
--					(pass @pbForStandingInstructions=1).
--					Add StartMonth table implemented via ipw_ListTableCodes 
--					(@pnTableTypeKey = 89 and @pbIsKeyUserCode = 1) .
--					Add WorkingDays table implemented via ipw_ListWorkingDays.
-- 29 May 2006	IB	RFC3678 17	Implemented StartMonth table via ipw_ListMonths stored procedure.
-- 25 Jul 2006	SW	RFC2307	18	Add FilePart table implemented via csw_ListFileParts stored procedure.
--					Add FileLocation table implemented via ipw_ListTableCodes (@pnTableTypeKey = 10).
-- 28 Aug 2006	LP	RFC3827	19	Add new CaseRelation table.
-- 11 Sep 2006	LP	RFC3218	20	Add new ChargeType table.
-- 19 Dec 2006	SF	RFC2982	21	Add new InstructionDefinition table
-- 21 Dec 2006  PG      RFC3646 22      Add @pbIsExternalUser parameter
-- 14 Nov 2007	LP	RFC5704	23	Add new CopyProfile table
-- 22 Nov 2007	SF	RFC5776 24	Add ChecklistType table
-- 03 Dec 2007	AT	RFC3208	25	Add Classes support table
-- 03 Dec 2007	LP	RFC3210 26	Add new CountryFlags support table
-- 20 Dec 2007	SF	RFC5708	27	Add SendMethod table
-- 02 Apr 2008	AT	RFC6369	28	Add Instruction Definition support table
-- 20 Nov 2008	MF	RFC7316	29	Allow CaseKey to be optionally passed as parameter to ipw_ListChargeTypes
-- 05 Sep 2008	AT	RFC5750	30	Add CaseId parameter to Case Attribute support table
-- 16 Oct 2008	SF	RFC3392	31	Add Available Actions support table
-- 25 Nov 2008  PS  	RFC7316 32  	Allow CaseKey to be optionally passed as parameter to ipw_ListChargeTypes
-- 29 Jan 2009	AT	RFC7173	33	Added Case/Property Type with CRM Support tables
-- 12 Mar 2009	NG	RFC6921	34	Added CaseCategoryWithCaseType parameter to get category values along with Case Type
-- 26 Aug 2009  PS	RFC8092 35	Allow CaseKey to be optionally passed as parameter to ipw_ListNumberTypes
-- 11 Nov 2009	LP	RFC7612	36	Pass AccessMode parameter to ipw_ListCaseTypes.
-- 25 Jan 2010	LP	RFC100065 37	Allow filtering of Case Office by Access Mode.
-- 16 Feb 2010  PA      RFC100149 38	Use the existing @pnCaseKey parameter to send the parameter value as context key in the qr_ListQueryGroups stored Procedure
-- 25 Oct 2010	DV	RFC9526	39	Add AllTextTypes to return all the available text types
-- 29 Nov 2010	SF	RFC7284	40	Allow ChecklistTypes to be filtered by Casekey
-- 19 Jan 2011	DV	RFC9387 41	Add InstructionLabel to return all available Instruction Labels
-- 22 Feb 2011	ASH	RFC9978	42	Add AllCaseStatus to return all the case status.
-- 24 Oct 2011	ASH	R11460 	43	Cast integer columns as nvarchar(11) data type.
-- 03 Sep 2012  MS      R12673  44      Add  RenewalType and StopPayReason table
-- 15 Apr 2013	DV	R13270	45      Increase the length of nvarchar to 11 when casting or declaring integer
-- 22 Dec 2014  SW      R41698  46      Added result set required for ValidBasisEx
-- 04 Feb 2014	JD	R43900	47	Pass @pbIsRenewal=0 to ipw_ListValidStatus to not return renewal status
-- 18 Mar 2015  SW      R42466  48      Add support for Predefined Event Notes table codes
-- 07 Sep 2018	AV	74738	49	Set isolation level to read uncommited.

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(4000)
Declare @nTableTypeKey		nchar(5)	-- @pnTableType parameter value to call the ipw_ListTableCodes  

-- initialise variables
Set @nRow			= 1		

Set @nRowCount			= 0
Set @ErrorCode			= 0

While @nRow is not null
and @ErrorCode = 0
Begin
	-- Extruct the stored procedure's name from the @psTables comma separated string using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'CaseType'			THEN 'ipw_ListCaseTypes'
			WHEN 'CaseTypeWithCRM'		THEN 'ipw_ListCaseTypesWithCRM'
			WHEN 'PropertyType'		THEN 'ipw_ListProperties'
			WHEN 'PropertyTypeWithCRM'	THEN 'ipw_ListPropertiesWithCRM'
			WHEN 'CaseCategory'		THEN 'ipw_ListCaseCategories'
			WHEN 'SubType'			THEN 'ipw_ListSubTypes'
			WHEN 'Basis'			THEN 'ipw_ListApplicationBasis'
			WHEN 'ValidProperty'		THEN 'ipw_ListValidProperties'
			WHEN 'ValidCategory'		THEN 'ipw_ListValidCategories'
			WHEN 'ValidSubType'		THEN 'ipw_ListValidSubTypes'
			WHEN 'ValidBasis'		THEN 'ipw_ListValidBasis'
			WHEN 'ValidBasisEx'		THEN 'ipw_ListValidBasisEx'
			WHEN 'NumberType'		THEN 'ipw_ListNumberTypes'
			WHEN 'TypeOfMark'		THEN 'ipw_ListTableCodes51'
			WHEN 'TextType'			THEN 'ipw_ListTextTypes'
			WHEN 'NameType'			THEN 'ipw_ListNameTypes'
			WHEN 'ExternalRenewalStatus'	THEN 'ipw_ListExternalRenewalStatus'			
			WHEN 'CaseStatus'		THEN 'ipw_ListStatus0'
			WHEN 'RenewalStatus'		THEN 'ipw_ListStatus1'
			WHEN 'CaseAttributeType'	THEN 'csw_ListAttributeTypes'
			WHEN 'CaseInstructions'		THEN 'ipw_ListInstructions'
			WHEN 'QueryGroup'		THEN 'qr_ListQueryGroups'
			WHEN 'ValidExportFormat'	THEN 'qr_ListValidExportFormats'
			WHEN 'ImportanceLevel'		THEN 'ipw_ListImportanceLevel'
			WHEN 'Action'			THEN 'ipw_ListAction'
			WHEN 'StaffNameType'		THEN 'ipw_ListNameTypes1'
			WHEN 'EventCategory'		THEN 'ipw_ListEventCategories'
			WHEN 'Language'			THEN 'ipw_ListTableCodes47'
			WHEN 'ValidRelation'		THEN 'csw_ListValidRelations'
			WHEN 'Office'			THEN 'ip_ListTable'
			WHEN 'EntitySize'		THEN 'ipw_ListTableCodes26'
			WHEN 'TaxTreatment'		THEN 'ac_ListTaxRates'
			WHEN 'ValidCaseStatus'		THEN 'ipw_ListValidStatus'
			WHEN 'InstructionCharacteristic' THEN 'ipw_ListInstructionCharcteristics'
			WHEN 'InstructionType'		THEN 'ipw_ListInstructionTypes'
			WHEN 'StandingInstructions'	THEN 'ipw_ListInstructions'
			WHEN 'PeriodType'		THEN 'ipw_ListTableCodes127'
			WHEN 'DesignElement'		THEN 'csw_ListDesignElements'
			WHEN 'AdjustmentType'		THEN 'ipw_ListAdjustmentTypes'
			WHEN 'StartMonth'		THEN 'ipw_ListMonths'
			WHEN 'WorkingDays'		THEN 'ipw_ListWorkingDays'
			WHEN 'FilePart'			THEN 'csw_ListFileParts'
			WHEN 'FileLocation'		THEN 'ipw_ListTableCodes10'
			WHEN 'CaseRelation'		THEN 'csw_ListCaseRelations'
			WHEN 'ChargeType'		THEN 'ipw_ListChargeTypes'
			WHEN 'InstructionDefinition'	THEN 'pi_ListInstructionDefinition'
			WHEN 'CopyProfile'		THEN 'csw_ListCaseCopyProfile'
			WHEN 'ChecklistType'		THEN 'ipw_ListChecklistTypes'
			WHEN 'CaseClasses'		THEN 'csw_GetCaseClasses'
			WHEN 'CountryFlag'		THEN 'ipw_ListCountryFlags'
			WHEN 'SendMethod'		THEN 'ipw_ListTableCodes107'
			WHEN 'InstructionDefinition'	THEN 'ipw_ListInstructionDefinition'
			WHEN 'AvailableActions'		THEN 'csw_ListAvailableActions'
			WHEN 'CaseCategoryWithCaseType'	THEN 'ipw_ListCaseCategoryWithCaseType'
			WHEN 'AllCaseStatus'		THEN 'ipw_ListStatus'
			WHEN 'AllTextType'		THEN 'ipw_ListTextTypes0'
			WHEN 'InstructionLabels'	THEN 'ipw_ListInstructionLabel'
			WHEN 'RenewalType'              THEN 'ipw_ListTableCodes17'
			WHEN 'StopPayReason'            THEN 'ipw_ListTableCodes68'			
			WHEN 'DefaultEventNote'         THEN 'ipw_ListTableCodes-508'
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

				-- Set the @pbIsKeyUserCode parameter to 1 for PeriodType and StartMonth tables
	
				If @sProc = 'ipw_ListTableCodes127' or @sProc = 'ipw_ListTableCodes68'
				Begin
					Set @sParams = @sParams + ', @pbIsKeyUserCode = 1'
				End

				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End

			-- Pass the hard coded @pbIsUsedByStaff=1 parameter value to the ipw_ListNameTypes

			If @sProc = 'ipw_ListNameTypes1'  
			Begin
				Set @sParams = @sParams + ', @pbIsUsedByStaff = 1' 
				
				-- Cut off the '1' from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListNameTypes' 
				Set @sProc = substring(@sProc, 1, 17)  
			End
	
			-- Pass the hard coded @pbIsCaseOnly =0 parameter value to the ipw_ListTextTypes

			If @sProc = 'ipw_ListTextTypes0'  
			Begin
				Set @sParams = @sParams + ', @pbIsCaseOnly = 0' 
				
				-- Cut off the '0' from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTextTypes' 
				Set @sProc = substring(@sProc, 1, 17)  
			End

			If @sProc like 'ipw_ListStatus%'  
			Begin
				-- For the ipw_ListStatus the @pbIsRenewal is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				
				if (substring(@sProc,15,1) != '')
				Begin
					Set @sParams = @sParams + ', @pbIsRenewal = ' + substring(@sProc, 15, 1)
				End
				Else
				Begin
					Set @sParams = @sParams + ', @pbIsRenewal = null'
				End

				-- Cut off the @pbIsRenewal from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListStatus' 
				Set @sProc = substring(@sProc, 1, 14)  
			End

			-- Pass the @pnCaseKey parameter to the csw_ListValidRelations, csw_ListDesignElements, csw_ListFileParts, csw_ListCaseCopyProfile,
			--					csw_GetCaseClasses, ipw_ListCountryFlags and ipw_ListChargeTypes

			If @sProc = 'csw_ListValidRelations'  
			or @sProc = 'csw_ListDesignElements'
			or @sProc = 'csw_ListFileParts'
			or @sProc = 'csw_ListCaseCopyProfile'
			or @sProc = 'csw_GetCaseClasses'
			or @sProc = 'ipw_ListCountryFlags'
			or @sProc = 'ipw_ListChargeTypes'
			or @sProc = 'csw_ListAttributeTypes'
			or @sProc = 'csw_ListAvailableActions'
			or @sProc = 'ipw_ListChargeTypes'
			or @sProc = 'ipw_ListNumberTypes'
			or @sProc = 'ipw_ListChecklistTypes'

			Begin
				If @pnCaseKey is not null
				Begin
					Set @sParams = @sParams + ', @pnCaseKey = ' + cast(@pnCaseKey as nvarchar(11)) 				
				End
				Else
				Begin
					Set @sParams = @sParams + ', @pnCaseKey = null'
				End
			End

			-- Pass @pbForStandingInstructions( =1) parameter to the ipw_ListAdjustmentTypes sp

			If @sProc = 'ipw_ListAdjustmentTypes'
			Begin
				Set @sParams = @sParams + ', @pbForStandingInstructions = 1'
			End

			If @sProc = 'ipw_ListMonths'
			Begin
				Set @sParams = @sParams + ', @pbCalledFromCentura = 0'
			End

			if @sProc = 'csw_GetCaseClasses'
			Begin
				Set @sParams = @sParams + ', @pbForPicklist=1, @pbCalledFromCentura=0'
			End

			If @sProc = 'ip_ListTable'  
			Begin
				Set @sParams = @sParams + ", @ptXMLOutputRequests = 	N'<OutputRequests>"+char(10)+
								    				'<Column ID="Key" PublishName="OfficeKey " />'+char(10)+
												'<Column ID="Description" PublishName="OfficeDescription" SortOrder="1" SortDirection="A" />'+char(10)+
											"</OutputRequests>',"+char(10)+
							    "@ptXMLFilterCriteria = N'<ip_ListTable>"+char(10)+
												"<FilterCriteria>"+char(10)+
													"<TableTypeKey>44</TableTypeKey>"+char(10)+
													"<AccessMode>"+convert(nvarchar(3),@pnCaseAccessMode)+"</AccessMode>"+char(10)+					
												"</FilterCriteria>"+char(10)+
											"</ip_ListTable>',"+char(10)+
							    "@pbProduceTableName	= 0"
												
			End
			-- pass the @pnCaseKey paramter as ContextKey
			If (@sProc = 'qr_ListQueryGroups')
			Begin
				Set @sParams = @sParams + ', @pnContextKey = '+ cast(@pnCaseKey as nvarchar(3))
			End

			If @pbIsExternalUser is not null
			Begin
				If @sProc = 'ipw_ListCaseTypes'
				or @sProc = 'ipw_ListCaseTypesWithCRM'
				or @sProc = 'ipw_ListNumberTypes'
				or @sProc = 'ipw_ListTableCodes'
				or @sProc = 'ipw_ListTextTypes'
				or @sProc = 'ipw_ListNameTypes'
				or @sProc = 'ipw_ListInstructions'
				or @sProc = 'ipw_ListInstructionTypes'
				or @sProc = 'ipw_ListChargeTypes'
				or @sProc = 'ipw_ListCaseOffice'	
				Begin
					Set @sParams = @sParams + ', @pbIsExternalUser = ' + cast(@pbIsExternalUser as nvarchar(1)) 
				End
			End
			if @sProc = 'pi_ListInstructionDefinition'
			Begin
				Set @sParams = @sParams + ", @ptXMLOutputRequests = 	N'<OutputRequests>"+char(10)+
												'<Column ID="InstructionName" PublishName="InstructionDefinitionName" SortOrder="1" SortDirection="A"/>'+char(10)+
												'<Column ID="DefinitionKey" PublishName="InstructionDefinitionKey" />'+char(10)+
											"</OutputRequests>',"+char(10)+
							    "@ptXMLFilterCriteria = N'<pi_ListInstructionDefinition><FilterCriteria /></pi_ListInstructionDefinition>'"
			End

			If (@sProc = 'ipw_ListCaseTypes' or @sProc = 'ipw_ListProperties')
			Begin
				Set @sParams = @sParams + ', @pbIncludeCRM = 0, @pnCaseAccessMode = '+ cast(@pnCaseAccessMode as nvarchar(1)) 
			End

			If (@sProc = 'ipw_ListCaseTypesWithCRM')
			Begin
				Set @sProc = 'ipw_ListCaseTypes'
				Set @sParams = @sParams + ', @pbIncludeCRM = 1, @pnCaseAccessMode = '+ cast(@pnCaseAccessMode as nvarchar(1)) 
			End
			
			
			If (@sProc = 'ipw_ListPropertiesWithCRM')
			Begin
				Set @sProc = 'ipw_ListProperties'
				Set @sParams = @sParams + ', @pbIncludeCRM = 1'
			End
			
			If (@sProc = 'ipw_ListValidProperties')
			Begin
				Set @sParams = @sParams + ', @pnCaseAccessMode = '+ cast(@pnCaseAccessMode as nvarchar(1)) 
			End
						
			-- Pass @pbIsRenewal(=0) parameter to ipw_ListValidStatus

			If @sProc = 'ipw_ListValidStatus'  
			Begin
				Set @sParams = @sParams + ', @pbIsRenewal = 0' 
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

Grant execute on dbo.csw_ListCaseSupport to public
GO
