-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_ConvertNameData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_ConvertNameData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_ConvertNameData.'
	Drop procedure [dbo].[fi_ConvertNameData]
End
Print '**** Creating Stored Procedure dbo.fi_ConvertNameData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.fi_ConvertNameData
(
	@prsSelect		nvarchar(2000)	= null output,	
	@prsFrom		nvarchar(2000)	= null output,	
	@prsJoin		nvarchar(2000)	= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@pnNameData		int,		-- Mandatory
	@psNameColumn		nvarchar(254),	-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0,
	@pbDebugFlag		tinyint		= 0
)
as

-- PROCEDURE:	fi_ConvertNameData
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Called by the fi_AppendUserFieldContent stored procedure
--		used to create and post Financial Interface journals.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Dec 2009	CR	RFC8407	1	Procedure created
-- 04 Jun 2010	MF	18703	2	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sAccountAliasType	nvarchar(3)

-- Initialise variables
Set @nErrorCode = 0

-- Determine the Account Alias Type
If @nErrorCode = 0
Begin
	
	Select	@sAccountAliasType = COLCHARACTER 
	from SITECONTROL
	Where CONTROLID = 'Accounts Alias'
	Set @nErrorCode=@@Error

	If @pbDebugFlag = 1
	Begin
		SELECT @sAccountAliasType AS AccountAliasType
	End
End

If @nErrorCode = 0
Begin
	If @pbDebugFlag = 1
	Begin
		If ( @pnNameData = 6901 )
		Begin
			PRINT '-- NAME.NAMECODE'
		End
		If ( @pnNameData = 6902 )
		Begin
			PRINT '-- NAMEALIAS.ALIAS' 
		End
		If ( @pnNameData = 6903 )
		Begin
			PRINT '-- NAME Formatted Name'
		End
		If ( @pnNameData = 6904 )
		Begin
			PRINT '-- EMPLOYEE.PROFITCENTRECODE'
		End
		If ( @pnNameData = 6905 )
		Begin
			print '-- NAMEFAMILY.FAMILYCOMMENTS'
		End

		Select @prsSelect AS SELECTSTMT,	
			@prsFrom AS FROMSTMT,	
			@prsJoin AS JOINSTMT
	End
	-- __cfConvertToNameData
	If ( @pnNameData = 6901 )
	Begin
		Set @prsSelect = @prsSelect + ", N.NAMECODE"
		Set @prsFrom = @prsFrom + "
			INNER JOIN NAME N ON (N.NAMENO = " + @psNameColumn + ") "
		Set @prsJoin = @prsJoin + " AND 
			N.NAMECODE IS NOT NULL"
	End
	If ( @pnNameData = 6902 )
	Begin
		Set @prsSelect = @prsSelect + ", NA.ALIAS" 
		Set @prsFrom = @prsFrom + "
			INNER JOIN NAMEALIAS NA ON (NA.NAMENO  = " + @psNameColumn + ")"
		-- There can be duplicate Aliases, so select the minimum code
		Set @prsJoin = @prsJoin + " AND 
			NA.ALIASTYPE = " + @sAccountAliasType  + "
				AND NA.ALIAS =
					( SELECT MIN(ALIAS.ALIAS) FROM NAMEALIAS ALIAS
					WHERE ALIAS.NAMENO = NA.NAMENO
					AND ALIAS.ALIASTYPE = NA.ALIASTYPE
					AND ALIAS.ALIAS IS NOT NULL
					AND ALIAS.COUNTRYCODE  is null
					AND ALIAS.PROPERTYTYPE is null ) "
	End
	If ( @pnNameData = 6903 )
	Begin
		Set @prsSelect = @prsSelect + ", dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)"
		Set @prsFrom = @prsFrom +  "
				INNER JOIN NAME N ON (N.NAMENO  = " + @psNameColumn + ")"
	End
	If ( @pnNameData = 6904 )
	Begin
		Set @prsSelect = @prsSelect + ", EMP.PROFITCENTRECODE"
		Set @prsFrom = @prsFrom + "
			INNER JOIN EMPLOYEE EMP ON (EMP.EMPLOYEENO = " + @psNameColumn + ")" 
		Set @prsJoin = @prsJoin + "AND
			EMP.PROFITCENTRECODE IS NOT NULL"
	End
	If ( @pnNameData = 6905 )
	Begin
		Set @prsSelect = @prsSelect + ", NF.FAMILYCOMMENTS" 
		Set @prsFrom = @prsFrom + "
			INNER JOIN NAME N ON (N.NAMENO  = " + @psNameColumn + ")
			INNER JOIN NAMEFAMILY NF ON (NF.FAMILYNO = N.FAMILYNO)" 
		Set @prsJoin = @prsJoin + " AND 
		N.FAMILYNO IS NOT NULL"
	End
/*
	ELSE
	Begin
		-- Error
	End
*/	
	If @pbDebugFlag = 1
	Begin
		Select @prsSelect AS SELECTSTMT,	
			@prsFrom AS FROMSTMT,	
			@prsJoin AS JOINSTMT
	End

End

Return @nErrorCode
GO

Grant execute on dbo.fi_ConvertNameData to public
GO
