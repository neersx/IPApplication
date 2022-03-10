-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NumberType
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_NumberType]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_NumberType.'
	drop function [dbo].[fn_NumberType]
	print '**** Creating Function dbo.fn_NumberType...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_NumberType
	(
		@nNumberTypeNumber int,
		@sNumberTypeString nvarchar(1)
	)
Returns nvarchar(1)

-- FUNCTION :	fn_NumberType
-- VERSION :	3
-- DESCRIPTION:	Translated NumberType from DataSet <> Inproma formats
--		Pass null for the format you do not know.

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 14/07/2002	JB	Function created
 
AS
Begin
	Declare @sReturn nvarchar(1)

	If @nNumberTypeNumber is null
		Set @sReturn =  
			CASE @sNumberTypeString
				WHEN 'A' THEN 1
				WHEN 'P' THEN 2
				WHEN 'R' THEN 3
			END

	If @sNumberTypeString is null
		Set @sReturn =  
			CASE @nNumberTypeNumber
				WHEN 1 THEN 'A'
				WHEN 2 THEN 'P'
				WHEN 3 THEN 'R'
			END

Return @sReturn	
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_NumberType to public
GO
