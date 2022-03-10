-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListPriorArtSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListPriorArtSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListPriorArtSupport.'
	Drop procedure [dbo].[prw_ListPriorArtSupport]
	Print '**** Creating Stored Procedure dbo.prw_ListPriorArtSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_ListPriorArtSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null		-- Is the comma separated list of requested tables
)
AS
-- PROCEDURE:	prw_ListCaseSearchResults
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC		RFC6563	1		Procedure created
-- 15 Apr 2013	DV		R13270	2		Increase the length of nvarchar to 11 when casting or declaring integer


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
			WHEN 'Source'		THEN 'ipw_ListTableCodes147'
			WHEN 'Status'		THEN 'ipw_ListTableCodes148'
			WHEN 'Translation'	THEN 'ipw_ListTableCodes150'
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

Grant execute on dbo.prw_ListPriorArtSupport to public
GO
