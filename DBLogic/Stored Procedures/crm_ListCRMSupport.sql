-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListCRMSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListCRMSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListCRMSupport.'
	Drop procedure [dbo].[crm_ListCRMSupport]
	Print '**** Creating Stored Procedure dbo.crm_ListCRMSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.crm_ListCRMSupport
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,	-- Is the comma separated list of requested tables 
							-- (e.g.'LeadSource,LeadStatus')
	@pnSubjectKey		int		= null  -- An optional key for addiational filtering
)
AS
-- PROCEDURE:	crm_ListCRMSupport
-- VERSION:	4
-- DESCRIPTION:	Returns list of valid values for the requested tables. 
--		Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 23-Jun-2008	SF	RFC6508	1	Procedure created.
-- 11-Jul-2008	SF	RFC5763	2	Add Opportunity Status, Opportunity Source
-- 12-Aug-2008	SF	RFC5760	3	Add Marketing Activity Status, Correspondence 
-- 15 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(4000)

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
			WHEN 'LeadSource'					THEN 'ipw_ListTableCodes143'
			WHEN 'LeadStatus'					THEN 'ipw_ListTableCodes144'
			WHEN 'OpportunitySource'			THEN 'ipw_ListTableCodes143'
			WHEN 'OpportunityStatus'			THEN 'ipw_ListTableCodes145'
			WHEN 'ProductInterest'				THEN 'ipw_ListTableCodes151'
			WHEN 'MarketingActivityStatus'		THEN 'ipw_ListTableCodes152'
			WHEN 'CorrespondenceReceived'		THEN 'ipw_ListTableCodes153'
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

				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End
			If @sProc like 'ipw_ListDocumentRequestNameTypes' and @pnSubjectKey is not null
			Begin
				Set @sParams = @sParams + ', @pnDocumentRequestTypeKey = ' + CAST(@pnSubjectKey as nvarchar(11))
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

Grant execute on dbo.crm_ListCRMSupport to public
GO
