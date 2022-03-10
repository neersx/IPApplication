-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_DateToString
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_DateToString]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_DateToString.'
	drop function [dbo].[fn_DateToString]
	print '**** Creating Function dbo.fn_DateToString...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_DateToString
	(	
		@pdDateToConvert	datetime,
		@psFormat		nvarchar(30)
	)
Returns nvarchar(20)

-- FUNCTION :	fn_DateToString
-- VERSION :	5
-- DESCRIPTION:	Converts a date/time stamp into a string format initially used 
--		to generate a unique string primarily for policing

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 14 JUL 2002	JB		Function created
-- 15 JUL 2002 	SF		Added '0000'
-- 19 MAR 2003	SF	5	It is incorrectly truncating the date 21 converstion.
as
Begin
	Declare @sReturn nvarchar(25)

	If @psFormat = 'CLEAN-DATETIME'
	Begin
		Set @sReturn = convert(varchar(25), @pdDateToConvert, 21)
		Set @sReturn = replace(@sReturn, '-', '')
		Set @sReturn = replace(@sReturn, ' ', '')
		Set @sReturn = replace(@sReturn, ':', '')
		Set @sReturn = replace(@sReturn, '.', '')
		Set @sReturn = @sReturn + '0'	/* should be a bit longer */
	End

	-- We can add other Date to String formats in here

	Return @sReturn
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_DateToString to public
GO
