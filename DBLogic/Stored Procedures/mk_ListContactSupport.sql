-----------------------------------------------------------------------------------------------------------------------------
-- Creation of mk_ListContactSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_ListContactSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_ListContactSupport.'
	Drop procedure [dbo].[mk_ListContactSupport]
	Print '**** Creating Stored Procedure dbo.mk_ListContactSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_ListContactSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null		-- Is the comma separated list of requested tables (e.g.'ContactActivityCategory,ContactActivityType')
)
AS
-- PROCEDURE:	mk_ListContactSupport
-- VERSION:	4
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Jan 2005	TM	RFC1838	1	Procedure created
-- 10 Feb 2005	TM	RFC1743	2	Include a new option ActivityTypeDirection that runs mk_ListActivityTypeDirection.
-- 15 May 2006	SW	RFC3301	3	Add site control key if @psTables has ContactActivityCategory
-- 29 Sep 2008	SF	RFC5745	4	Add attachment type

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(1000)	-- Current parameters list
Declare @nTableTypeKey		nchar(5)	-- @pnTableType parameter value to call the ipw_ListTableCodes    

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
			-- For ContactActivityCategory and ContactActivityType
			-- (i.e. '59' and '58') required to call ipw_ListTableCodes
			WHEN 'ContactActivityCategory'		THEN 'ipw_ListTableCodes59'
			WHEN 'ContactActivityType'			THEN 'ipw_ListTableCodes58'			
			WHEN 'ActivityTypeDirection'		THEN 'mk_ListActivityTypeDirection'
			WHEN 'AttachmentType'				THEN 'ipw_ListTableCodes101'
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

			Set @sParams = '@pnUserIdentityId=' + CAST(@pnUserIdentityId as varchar(10)) 

			If @psCulture is not null
			Begin
				Set @sParams = @sParams + ", @psCulture='" + @psCulture + "'"
			End

			-- For ContactActivityCategory, set the site control key to 'Client Activity Categories'
			If @sProc = 'ipw_ListTableCodes59'
			Begin
				Set @sParams = @sParams + ', @psFilterSiteControlKey = ''Client Activity Categories'''
			End

			If @sProc like 'ipw_ListTableCodes%'  
			Begin
				-- For the ipw_ListTableCodes the @pnTableTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnTableTypeKey = ' + substring(@sProc, 19, 5)

				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
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

Grant execute on dbo.mk_ListContactSupport to public
GO
