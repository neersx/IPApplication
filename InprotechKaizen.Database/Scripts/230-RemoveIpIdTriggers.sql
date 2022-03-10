if exists (select * from sysobjects where type='TR'and name='tU_OFFICIALNUMBERS_CpaGlobalidentifier')
begin
	drop trigger tU_OFFICIALNUMBERS_CpaGlobalidentifier
end
go

if exists (select * from sysobjects where type='TR'and name='tD_OFFICIALNUMBERS_CpaGlobalidentifier')
begin
	drop trigger tD_OFFICIALNUMBERS_CpaGlobalidentifier
end
go

if exists (select * from sysobjects where type='TR'and name='tU_CaseEvent_CpaGlobalidentifier')
begin
	drop trigger tU_CaseEvent_CpaGlobalidentifier
end
go

if exists (select * from sysobjects where type='TR'and name='tD_CaseEvent_CpaGlobalidentifier')
begin
	drop trigger tD_CaseEvent_CpaGlobalidentifier
end
go