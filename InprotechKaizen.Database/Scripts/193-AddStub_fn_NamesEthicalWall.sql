if exists (select * from sysobjects where id = object_id('dbo.fn_NamesEthicalWall') and xtype in ('IF','TF'))
begin
	set noexec on;
end
go

Create Function dbo.fn_NamesEthicalWall(@pnUserIdentityId int)
/* This is a stub for before Release 11.1 pairing */
RETURNS TABLE as RETURN Select N.* From NAME N with (NOLOCK)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_NamesEthicalWall to public
go

set noexec off;