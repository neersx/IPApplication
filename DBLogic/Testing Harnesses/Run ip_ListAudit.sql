
exec ip_ListAuditTrail
	@pnUserIdentityId	= null,
	@psCulture		= null,
	@pnSubjectArea		= 1,
	@pnNameNo		= null, 
	@pdtFromDate		= null,
	@pbIncludeUpdates	= 1,
	@pbIncludeDeletes	= 1,
	@pbIncludeInserts	= 1,
	@psFilterTable		= null,
	@psFilterColumn		= null,
	@psFilterColumnValue	= null,
	@psFilterKeyValue	= -487,
	@psColumnsToAudit	=
				'<ip_ListAuditTrail>
					<ColumnsToAudit>
						<Table Name="CASES">
							<Column>IRN</Column>
							<Column>TITLE</Column>
						</Table>
						<Table Name="CASENAME">
							<Column>NAMENO</Column>
							<Column>REFERENCENO</Column>
						</Table>
					</ColumnsToAudit>
				</ip_ListAuditTrail>',
	@psSortOrderColumn	='AUDITDATA',
	@psSortOrderDirection	='D',
	@pbPrintSQL=0
