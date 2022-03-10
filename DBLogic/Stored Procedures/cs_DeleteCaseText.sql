-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteCaseText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_DeleteCaseText.'
	Drop procedure [dbo].[cs_DeleteCaseText]
End
Print '**** Creating Stored Procedure dbo.cs_DeleteCaseText...'
Print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_DeleteCaseText
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey		varchar(11) = null, 
	@pnTextTypeId		int = null,
	@pnTextSequence		int = null,
	@psText			ntext = null
)
as
-- VERSION:	5
-- DESCRIPTION:	Returns Case details for a given CaseKey passed as a parameter.
-- SCOPE:	CPA.net
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12/07/2002	SF						procedure created
-- 15/11/2002	SF					4	Updated Version Number
-- 15/04/2013	DV		R13270		5	Increase the length of nvarchar to 11 when casting or declaring integer

begin

	declare @nErrorCode int
	declare @sTextType nvarchar(2)

	set @nErrorCode = 0

	if @nErrorCode = 0
	begin
		set @sTextType = case @pnTextTypeId
				  when	0	then 'T'	/* Title 	*/
				  when	1	then 'R'	/* Remarks 	*/
				  when 	2	then 'CL'	/* Claims 	*/
				  when 	3	then 'A'	/* Abstract 	*/
				  when	4	then 'T1'	/* Text1 	*/
				  when 	5	then 'T2'	/* Text2 	*/
				  when	6	then 'T3'	/* Text3 	*/
				end

		if @sTextType is null
			set @nErrorCode = -1
	end

	if @nErrorCode = 0
	begin
		delete 
		from 	CASETEXT
		where	CASEID = cast(@psCaseKey as int)
		and	TEXTTYPE = @sTextType
		and	TEXTNO = @pnTextSequence
		
		set @nErrorCode = @@error
	end

	return @nErrorCode
end

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_DeleteCaseText to public
go
