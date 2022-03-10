
---------------------------------------------------------------------------------------------
--	Update TOPICCONTROL records to set 	TOPICSUFFIX to null for cloned Case_TextTopic												--
---------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM TOPICCONTROL T where 
					T.WINDOWCONTROLNO not in (
													select WINDOWCONTROLNO
													from WINDOWCONTROL WC
													where WC.WINDOWNAME = 'WorkflowWizard'
												 )
					and ( 
						  T.TOPICNAME like 'Case_TextTopic_cloned%' or
						  T.TOPICNAME like 'CaseNameText_Component%' or
						  T.TOPICNAME like 'Names_Component%' or
						  T.TOPICNAME like 'NameCustomContent_Component%' or
						  T.TOPICNAME like 'CaseCustomContent_Component%' 
						)
					and T.TOPICSUFFIX is not null)
BEGIN
		update T
			set T.TOPICSUFFIX = null
			from TOPICCONTROL T
			where T.WINDOWCONTROLNO not in (
				select WINDOWCONTROLNO
				from WINDOWCONTROL WC
				where WC.WINDOWNAME = 'WorkflowWizard'
			)
			and ( 
				  T.TOPICNAME like 'Case_TextTopic_cloned%' or
				  T.TOPICNAME like 'CaseNameText_Component%' or
				  T.TOPICNAME like 'Names_Component%' or
				  T.TOPICNAME like 'NameCustomContent_Component%' or
				  T.TOPICNAME like 'CaseCustomContent_Component%' 
				)
			and T.TOPICSUFFIX is not null

END
GO