-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_MatchPattern stored procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_MatchPattern]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_MatchPattern.'
	drop procedure dbo.ip_MatchPattern
	print '**** Creating procedure dbo.ip_MatchPattern...'
	print ''
End
go

create procedure dbo.ip_MatchPattern
	@psSourceString 	nvarchar(254), 		-- string to be matched by psPattern
	@psPattern 		nvarchar(254), 		-- a pattern (regular expression)
	@pbInvokedByCentura	tinyint 	= 0	-- indicates that Centura code is calling the Stored Procedure

as
-- PROCEDURE  :	ip_MatchPattern
-- VERSION    :	3
-- DESCRIPTION:	Matches the psSourceString string to the psPattern pattern 
--		using RegEx functionality (in vbscript dll).
--
--		Error codes returned:
--		 0 - psSourceString matches psPattern
--		-1 - psSourceString does not match psPattern
--		 1 - could not create VBScript.RegExp object
--		 2 - error occurred when setting the psPattern pattern
--		 3 - psPattern is not a valid pattern
--		 4 - error occurred when matching the psPattern pattern

-- CALLED BY :	

-- MODIFICTION HISTORY
-- Date			Who	Number  Version	Change
-- ------------	---	-------	-------	----------------------------------------------- 
-- 15/07/2002	IB				1	Procedure created
-- 29/08/2003	AB				2	Add 'dbo.' to creation of sp.
-- 28 May 2013	DL	10030		3	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx


declare @nErrorCode	int,
	@nRegExp	int,
	@nMatch		int

-- Create VBScript.RegExp com object
exec @nErrorCode = dbo.ipu_OACreate 	'VBScript.RegExp',
					@nRegExp output
					
If @nErrorCode = 0
-- Set VBScript.RegExp object's Pattern property to @psPattern
	Begin
		exec @nErrorCode = 
			dbo.ipu_OASetProperty	@nRegExp,
						'Pattern',
						@psPattern
	End
Else
-- Indicate that creation of VBScript.RegExp com object failed by setting @nErrorCode to 1
	Begin
		Set @nErrorCode = 1
	End


If @nErrorCode = 0
-- check whether @psPattern is valid by calling Test method and passing it an empty string
	Begin
		exec @nErrorCode = 
			dbo.ipu_OAMethod @nRegExp,
					'Test',
					@nMatch output,
					@psParameterName = ''
	End
Else If @nErrorCode < -2140000000
-- error occurred when setting the psPattern pattern
	Begin
		Set @nErrorCode = 2
	End

If @nErrorCode = 0
	Begin
		exec @nErrorCode = 
			dbo.ipu_OAMethod @nRegExp,
					'Test',
					@nMatch output,
					@psParameterName = @psSourceString
	End
Else If @nErrorCode < -2140000000
-- error occurred while validating the psPattern value against an empty string,
-- indicates that psPattern is not valid.
	Begin
		Set @nErrorCode = 3
	End

If @nErrorCode = 0
-- destroy the VBScript.RegExp object
	Begin
		exec @nErrorCode = dbo.ipu_OADestroy @nRegExp
	End
Else If @nErrorCode < -2140000000
-- the previous call to the Test function failed
	Begin
		Set @nErrorCode = 4
	End

If @nErrorCode = 0
	Begin
		If @nMatch = 1
			Begin
				Set @nErrorCode = 0
			End
		Else
			Begin
				Set @nErrorCode = -1
			End
	End

If @pbInvokedByCentura = 1
	Begin
		Select @nErrorCode
	End

return 	@nErrorCode 	
go

grant exec on dbo.ip_MatchPattern to public
go
