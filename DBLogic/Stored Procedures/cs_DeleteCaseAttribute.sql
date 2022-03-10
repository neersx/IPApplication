-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteCaseAttribute
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteCaseAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_DeleteCaseAttribute.'
	Drop procedure [dbo].[cs_DeleteCaseAttribute]
End
Print '**** Creating Stored Procedure dbo.cs_DeleteCaseAttribute...'
Print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_DeleteCaseAttribute
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey		varchar(11) = null, 
	@pnAttributeTypeId	int = null,
	@psAttributeKey		varchar(11) = null,
	@psAttributeDescription	nvarchar(80) = null
)
as
-- PROCEDURE :	cs_InsertExpense
-- VERSION :	9
-- DESCRIPTION:	See CaseData.doc 
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16-Jul-2002  JB				1	Procedure created
-- 05-Aug-2002	JB				2	Proper error handling
-- 15-Nov-2002	SF				7	Grant statement had a syntax error.
-- 25 Nov 2011	ASH	R100640		8	Change the size of Case Key and Related Case key to 11.
-- 15 Apr 2013	DV	R13270		9	Increase the length of nvarchar to 11 when casting or declaring integer


Declare @nErrorNo int
-- Pre-Condition
If 	@psCaseKey is null or @psCaseKey = ''
	or @psAttributeKey is null or @psAttributeKey = ''
	Set @nErrorNo = -1

-- Remove Relationship
Delete 
	From 	TABLEATTRIBUTES
	Where 	PARENTTABLE = 'CASES'
	and	GENERICKEY = @psCaseKey
	and	TABLECODE = Cast(@psAttributeKey as int)

Set @nErrorNo = @@ERROR

RETURN @nErrorNo
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_DeleteCaseAttribute to public
go
