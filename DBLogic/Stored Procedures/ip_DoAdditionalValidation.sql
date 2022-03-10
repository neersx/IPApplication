-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DoAdditionalValidation stored procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_DoAdditionalValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_DoAdditionalValidation.'
	drop procedure dbo.ip_DoAdditionalValidation
End
print '**** Creating procedure dbo.ip_DoAdditionalValidation...'
print ''
go

create procedure dbo.ip_DoAdditionalValidation
	@pnValidationError	int		OUTPUT,
	@psErrorMessage		nvarchar(254)	OUTPUT,
	@pnWarningFlag		tinyint		OUTPUT,
	@psSourceString 	nvarchar(36), 		-- string to be validated
	@psProcedureName	nvarchar(254), 		-- a stored procedure that will perform an additional validation
	@pbInvokedByCentura	tinyint 	= 0	-- indicates that Centura code is calling the Stored Procedure

as
-- PROCEDURE  :	ip_DoAdditionalValidation
-- VERSION    :	1.0.0
-- DESCRIPTION:	Executes the @psProcedureName stored procedure that validates
--		the @psSourceString string
--		Error codes returned:
--		0 - Passed validation
--		1 - Validation failed

-- CALLED BY :	

-- Date		MODIFICATION HISTORY
--		User
--		SQA	Description
-- ==========	=========================================================================
-- 25/09/2009	IB		
--		9267	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@sSQLString		nvarchar(4000)

set @pnValidationError = 0	-- default to indicate a valid match

If datalength(@psProcedureName) = 0 
Begin
	Set @pnValidationError = 1
	Set @psErrorMessage = 'No stored procedure has been specified.'
End

If @pnValidationError = 0
Begin
	If NOT exists (select * from sysobjects where id = object_id(N'[dbo].[' + @psProcedureName + ']') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Begin
		Set @pnValidationError = 1
		Set @psErrorMessage = 'Could not find ' + @psProcedureName + ' stored procedure.'
	End
End

If @pnValidationError = 0
Begin
	Set @sSQLString =	'Exec @pnValidationError='+@psProcedureName + ' '	+ char(10) +
				'                	@psSourceString,'	+ char(10) +
				'                	@psErrorMessage 	OUTPUT,' + char(10) +
				'                	@pnWarningFlag		OUTPUT'
	
	exec sp_executesql 	@sSQLString,
				N'@psSourceString 	nvarchar(36),
			  	@psErrorMessage		nvarchar(254)	OUTPUT,
			  	@pnWarningFlag		tinyint		OUTPUT,
			  	@pnValidationError	int		OUTPUT',
			  	@psSourceString,		
			  	@psErrorMessage		OUTPUT,	
			  	@pnWarningFlag		OUTPUT,
			  	@pnValidationError	OUTPUT
End
			
-- Return the result set indicating if 
If @pbInvokedByCentura = 1
begin
	select	@pnValidationError	as PatternErrorFlag,
	 	@psErrorMessage 	as ErrorMessage,
		@pnWarningFlag  	as WarningFlag
end

return 	@pnValidationError
go

grant exec on dbo.ip_DoAdditionalValidation to public
go
