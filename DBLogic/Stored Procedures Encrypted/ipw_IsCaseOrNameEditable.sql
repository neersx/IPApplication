-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_IsCaseOrNameEditable
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_IsCaseOrNameEditable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_IsCaseOrNameEditable.'
	drop procedure dbo.ipw_IsCaseOrNameEditable
end
print '**** Creating procedure dbo.ipw_IsCaseOrNameEditable...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_IsCaseOrNameEditable
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture				nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCaseKey				int,
	@pnNameKey				int
)
with ENCRYPTION
AS
-- PROCEDURE :	ipw_IsCaseOrNameEditable
-- VERSION :	6
-- DESCRIPTION:	Obsolete.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 29 Mar 2010	JC  	RFC8994		1	Procedure Created
-- 15 Jul 2011	JCLG  	RFC10989	2	Encrypt
-- 26 Dec 2011	DV		RFC11140	3	Check for Case Access Security.
-- 11 Jan 2011	SF		RFC11781	4	Incorrectly filtering out licenses which has not expired.
-- 12 Jan 2011  DV		RFC11781	5	Implement Row Access security for both Case and Name
-- 20 Mar 2013	SF		RFC13286	6	Superceded by ipw_GetCaseOrNameEditability.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


SELECT cast(0 as bit) as 'IsEditable'

RETURN @@Error
go

grant execute on dbo.ipw_IsCaseOrNameEditable to public
go
