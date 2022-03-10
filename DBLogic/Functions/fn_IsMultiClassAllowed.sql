-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsMultiClassAllowed
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsMultiClassAllowed') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsMultiClassAllowed'
	Drop function [dbo].[fn_IsMultiClassAllowed]
End
Print '**** Creating Function dbo.fn_IsMultiClassAllowed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsMultiClassAllowed
(
	@psCountryCode	nvarchar(3),
	@psPropertyType	nvarchar(1),
	@psCaseType		nvarchar(1),
	@psCaseCategory  nvarchar(2)
) 
RETURNS bit
AS
-- Function :	fn_IsMultiClassAllowed
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns whether a case can have multiple classes based on country and valid category settings

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 06-Nov-2013	AT		RFC28091	1		Function created.

Begin
	Declare @bIsMultiClassAllowed bit
	Set @bIsMultiClassAllowed = 0
	
	If (exists (select * from TABLEATTRIBUTES
				where GENERICKEY = @psCountryCode
				and PARENTTABLE = 'COUNTRY'		
				and TABLECODE = 5001)
		or exists (select * from VALIDCATEGORY
				where COUNTRYCODE = @psCountryCode
				and CASETYPE = @psCaseType
				and PROPERTYTYPE = @psPropertyType
				and CASECATEGORY = @psCaseCategory
				and isnull(MULTICLASSPROPERTYAPP, 0) = 1)
		)
	Begin
		Set @bIsMultiClassAllowed = 1
	End
	
	return @bIsMultiClassAllowed
End
GO

grant execute on dbo.fn_IsMultiClassAllowed to public
go
