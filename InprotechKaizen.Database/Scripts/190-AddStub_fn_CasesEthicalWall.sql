if exists (select * from sysobjects where id = object_id('dbo.fn_CasesEthicalWall') and xtype in ('IF','TF'))
begin
	set noexec on;
end
go

Create Function dbo.fn_CasesEthicalWall(@pnUserIdentityId int)
/* This is a stub for before Release 11.1 pairing */
RETURNS TABLE as RETURN Select C.* From CASES C with (NOLOCK)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_CasesEthicalWall to public
go

set noexec off;
