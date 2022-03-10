-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ConcatenateSplitString
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ConcatenateSplitString]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
 Print '**** Drop Stored Procedure dbo.ip_ConcatenateSplitString.'
 Drop procedure [dbo].[ip_ConcatenateSplitString]
 Print '**** Creating Stored Procedure dbo.ip_ConcatenateSplitString...'
 Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ConcatenateSplitString
(
	 @psString1		nvarchar(4000) = null	OUTPUT,
	 @psString2		nvarchar(4000) = null   OUTPUT,
	 @psAppendString 	nvarchar(4000)		-- Mandatory
)
AS
-- PROCEDURE: 	ip_ConcatenateSplitString
-- VERSION:   	1
-- SCOPE:     	CPA.net, InPro.net
-- DESCRIPTION: This procedure will concatenate @psAppendString to any existing string 
--		supplied in @psString1/@psString2 with the results split across @psString1
--		and @psString2 as necessary.  The first 4000 characters are placed in 
--		@psString1 and any overflow in @psString2.
--		ip_ConcatenateSplitString does not access database so it always returns 0 
-- MODIFICATIONS :
-- Date  	Who 	Version  Change
-- ------------ ------- -------  ----------------------------------------------- 
-- 03-Jun-2003  TM 	1 	 Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- If @psString1 is not full and has enough space to accommodate @psAppendString 
-- and @psString2 is null then append @psAppendString to @psString1   
	
If ISNULL(LEN(@psString1), 0)<4000 
and (4000-ISNULL(LEN(@psString1), 0))>=ISNULL(LEN(@psAppendString), 0)
and @psString2 is null
Begin
	Set @psString1 = @psString1 + char(10) + @psAppendString
		 
End

-- If @psString1 does not have enough space to accomodate @psAppendString
-- then split @psAppendString across @psString1 and @psString2 as necessary   
	
Else If ISNULL(LEN(@psString1), 0)<4000 
and (4000-ISNULL(LEN(@psString1), 0))<ISNULL(LEN(@psAppendString), 0) 
and @psString2 is null 
Begin
	-- Cut off the beginning of the @psAppendString which will be concatenated 
	-- at the end of @psString1 and save that substring in the @psString2  
	
	Set @psString2 = SUBSTRING(@psAppendString,4000 - LEN(@psString1), 4000) 
	
	-- Concatenate first part of the @psAppendString at the end of the @psString1  
	
	Set @psString1 = @psString1 + char(10) + @psAppendString
End

-- If @psString2 has something in it all future concatenations should be made at the end of @psString2 

Else If @psString2 is not null
Begin
	Set @psString2 = @psString2 + char(10) + @psAppendString
End

-- Always returns 0
	
Return 0
GO

Grant execute on dbo.ip_ConcatenateSplitString to public
GO