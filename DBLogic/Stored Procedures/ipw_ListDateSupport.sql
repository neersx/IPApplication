-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDateSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDateSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDateSupport.'
	Drop procedure [dbo].[ipw_ListDateSupport]
	Print '**** Creating Stored Procedure dbo.ipw_ListDateSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListDateSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null		-- Is the comma separated list of requested tables (e.g.'StaffNameType,DateDisplayImportanceLevel')	
	
)
AS
-- PROCEDURE:	ipw_ListDateSupport
-- VERSION:	4
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Mar 2004	TM	RFC951	1	Procedure created
-- 17 Aug 2005	TM	RFC2938	2	Implement a new ImportanceLevel option that calls ipw_ListImportanceLevel 
--					without any @psControlId parameter.
-- 29 Mar 2004	AU	RFC4266	3	Implement a new AdHocResolveReason option that calls ipw_ListTableCodes 
-- 15 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(1000)	-- Current parameters list 

-- Initialise variables
Set @nRow			= 1		

Set @nRowCount			= 0
Set @ErrorCode			= 0

While @nRow is not null
and @ErrorCode = 0
Begin
	-- Extruct the stored procedure's name from the @psTables comma separated string using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'StaffNameType'			THEN 'ipw_ListNameTypes'			
			WHEN 'DateDisplayImportanceLevel'	THEN 'ipw_ListImportanceLevel2'			
			WHEN 'ImportanceLevel'			THEN 'ipw_ListImportanceLevel'
			WHEN 'AdHocResolveReason'		THEN 'ipw_ListTableCodes'
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

			-- To get the StaffNameType table pass the parameter @pbIsUsedByStaff = 1.
			If @sProc = 'ipw_ListNameTypes'  			
			Begin
				Set @sParams = @sParams + ', @pbIsUsedByStaff = 1' 
			End
		
			-- To get the DateDisplayImportanceLevel table pass the parameter @psControlId = 'Events Displayed'. 
			If @sProc = 'ipw_ListImportanceLevel2'  			
			Begin
				Set @sParams = @sParams + ", @psControlId = 'Events Displayed'"

				-- Cut off the '2' from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListNameTypes' 
				Set @sProc = substring(@sProc, 1, 23)  
			End

			If @sProc = 'ipw_ListTableCodes'  			
			Begin
				Set @sParams = @sParams + ', @pnTableTypeKey = 131' 
				Set @sParams = @sParams + ', @pbIsKeyUserCode = 1'
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

Grant execute on dbo.ipw_ListDateSupport to public
GO
