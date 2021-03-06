-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainCriteriaInheritance
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].ipw_MaintainCriteriaInheritance') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainCriteriaInheritance.'
	Drop procedure [dbo].ipw_MaintainCriteriaInheritance
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainCriteriaInheritance...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_MaintainCriteriaInheritance]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnCriteriaKey				int,		-- Mandatory
	@pnParentCriteriaKey			int		= null,
	@pnOldParentCriteriaKey			int		= null,
	@pbIsNameCriteria			bit		= 0
)
as
-- PROCEDURE:	ipw_MaintainCriteriaInheritance
-- VERSION:	7
-- DESCRIPTION:	Maintains inheritance properties of a criteria 
--		and propagates changes to other related tables.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 18 Mar 2009	LP	RFC7208	1	Procedure created
-- 29 May 2009  LP      RFC7824 2       Check on TOPICTITLE unnecessary for inserting ELEMENTCONTROL
-- 13 Oct 2009  LP      RFC8526 3       Fix logic for Name Window Control Criteria inheritance
-- 10 Dec 2010	KR	RFC9193	4	Extended for checklist
-- 29 Aug 2011  MS      R11024  5       Extended for Default Settings
-- 23 May 2014  SW      R27241  6       Handled more than one element controls with same topic header using DISTINCT prior to INSERT
--                                      in ELEMENTCONTROL
-- 09 Sep 2015  MS      R51201  7       Added TOPICCONTROLFILTER insert when adding inheritance

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @bIsInherited	bit
declare @PurposeCode	nvarchar(1)

-- Initialise variables
Set @nErrorCode 	= 0
Set @bIsInherited	= 0

-- Delete the old link
If @nErrorCode = 0
Begin
	Select @PurposeCode = PURPOSECODE from CRITERIA where CRITERIANO = @pnCriteriaKey
	
	Set @sSQLString = " 
	Delete from " + 
		CASE When @pbIsNameCriteria = 0 Then "INHERITS" 
		Else "NAMECRITERIAINHERITS" END + 
	" where " +
		CASE When @pbIsNameCriteria = 0 Then "CRITERIANO" 
		Else "NAMECRITERIANO" END +
	" = @pnCriteriaKey" +
	" and " +
		CASE When @pbIsNameCriteria = 0 Then "FROMCRITERIA" 
		Else "FROMNAMECRITERIANO" END + 	
	" = @pnOldParentCriteriaKey"
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey			int,
					  @pnOldParentCriteriaKey		int,
					  @pbIsNameCriteria			bit',		
					  @pnCriteriaKey			= @pnCriteriaKey,
					  @pnOldParentCriteriaKey		= @pnOldParentCriteriaKey,
					  @pbIsNameCriteria			= @pbIsNameCriteria
					  
	select @pnCriteriaKey, @pnOldParentCriteriaKey, @pbIsNameCriteria
	select @sSQLString
				
End



-- Insert the new link
If @nErrorCode = 0
and @pnParentCriteriaKey is not null
Begin
	Set @sSQLString = " 
	Insert into " + 
		CASE When @pbIsNameCriteria = 0 Then "INHERITS" 
		Else "NAMECRITERIAINHERITS" END + 
	"(" +	
		CASE When @pbIsNameCriteria = 0 Then "CRITERIANO" 
		Else "NAMECRITERIANO" END + 
	","+	
		CASE When @pbIsNameCriteria = 0 Then "FROMCRITERIA" 
		Else "FROMNAMECRITERIANO" END +
	") "+ 	
	"values(@pnCriteriaKey, @pnParentCriteriaKey)"
	print @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey			int,
					  @pnParentCriteriaKey			int,
					  @pbIsNameCriteria			bit',		
					  @pnCriteriaKey			= @pnCriteriaKey,
					  @pnParentCriteriaKey			= @pnParentCriteriaKey,
					  @pbIsNameCriteria			= @pbIsNameCriteria
	select  @pnCriteriaKey,  @pnParentCriteriaKey, @pbIsNameCriteria
	select @sSQLString
				
End

If @nErrorCode = 0
and @pbIsNameCriteria = 0
Begin
	Update CRITERIA
	Set PARENTCRITERIA = @pnParentCriteriaKey
	Where CRITERIANO = @pnCriteriaKey
	
	select 1
	
	Set @nErrorCode = @@ERROR
End

-- Propagate new inheritance
If @nErrorCode = 0
and @PurposeCode = 'C'
Begin
	-- checklist inheritance
	If @pnParentCriteriaKey is not null
	Begin
		select 2
		
		--delete existing CHECKLISTITEM that are to be inherited from new parent
		Delete CI
		from CHECKLISTITEM CI
                left join CHECKLISTITEM CI2 on (CI2.CRITERIANO = @pnParentCriteriaKey 
                                and CI2.QUESTIONNO = CI.QUESTIONNO)
                Where CI.CRITERIANO = @pnCriteriaKey
                and CI2.CRITERIANO IS NOT NULL
		
		Set @nErrorCode = @@Error
		
		If @nErrorCode = 0
		Begin
		        --delete existing CHECKLISTITEM from descendants if to be inherited from new parent
		        Delete CI
		        from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
                        join CHECKLISTITEM CI on (CI.CRITERIANO=C.CRITERIANO)
                        left join CHECKLISTITEM CI2 on (CI2.CRITERIANO = @pnParentCriteriaKey
                                        and CI2.QUESTIONNO = CI.QUESTIONNO)
                        Where CI2.CRITERIANO IS NOT NULL
        		
		        Set @nErrorCode = @@Error
		End
		
		If @nErrorCode = 0
		Begin
		        -- delete existing CHECKLISTLETTER that are to be inherited from the parent
		        Delete CL
		        from CHECKLISTLETTER  CL
		        left join CHECKLISTLETTER CL2 on (CL2.CRITERIANO = @pnParentCriteriaKey 
		                                        and CL2.QUESTIONNO = CL.QUESTIONNO 
		                                        and CL2.LETTERNO = CL.LETTERNO)
		        Where CL.CRITERIANO = @pnCriteriaKey
		        and CL2.CRITERIANO IS NOT NULL
		        
		        Set @nErrorCode = @@Error
		End	
		
		If @nErrorCode = 0
		Begin
		        --delete existing CHECKLISTLETTER from descendants that are to be inherited
		        Delete CL
		        from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
		        join CHECKLISTLETTER CL on (CL.CRITERIANO=C.CRITERIANO)
		        where CL.INHERITED=1
        		
		        Set @nErrorCode = @@Error
		End
		
		
		-- insert into CHECKLISTITEM
		If @nErrorCode = 0
		Begin
		        INSERT INTO CHECKLISTITEM(
		        CRITERIANO,
		        QUESTIONNO,
		        SEQUENCENO,
		        QUESTION,
		        YESNOREQUIRED,
		        COUNTREQUIRED,
		        PERIODTYPEREQUIRED,
		        AMOUNTREQUIRED,
		        DATEREQUIRED,
		        EMPLOYEEREQUIRED,
		        TEXTREQUIRED,
		        PAYFEECODE,
		        UPDATEEVENTNO,
		        DUEDATEFLAG,
		        YESRATENO,
		        NORATENO,
		        YESCHECKLISTTYPE,
		        NOCHECKLISTTYPE,
		        INHERITED,
		        NODUEDATEFLAG,
		        NOEVENTNO,
		        ESTIMATEFLAG,
		        QUESTION_TID,
		        DIRECTPAYFLAG,
		        SOURCEQUESTION,
		        ANSWERSOURCEYES,
		        ANSWERSOURCENO)
        		
		        SELECT
		        C.CRITERIANO,
		        CI.QUESTIONNO,
		        CI.SEQUENCENO,
		        CI.QUESTION,
		        CI.YESNOREQUIRED,
		        CI.COUNTREQUIRED,
		        CI.PERIODTYPEREQUIRED,
		        CI.AMOUNTREQUIRED,
		        CI.DATEREQUIRED,
		        CI.EMPLOYEEREQUIRED,
		        CI.TEXTREQUIRED,
		        CI.PAYFEECODE,
		        CI.UPDATEEVENTNO,
		        CI.DUEDATEFLAG,
		        CI.YESRATENO,
		        CI.NORATENO,
		        CI.YESCHECKLISTTYPE,
		        CI.NOCHECKLISTTYPE,
		        1,
		        CI.NODUEDATEFLAG,
		        CI.NOEVENTNO,
		        CI.ESTIMATEFLAG,
		        CI.QUESTION_TID,
		        CI.DIRECTPAYFLAG,
		        CI.SOURCEQUESTION,
		        CI.ANSWERSOURCEYES,
		        CI.ANSWERSOURCENO
		        FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C 
		        join CHECKLISTITEM CI on (CI.CRITERIANO = @pnParentCriteriaKey)
		        
		        Set @nErrorCode = @@Error
		End
		
		If @nErrorCode = 0
		Begin
		        -- insert into CHECKLISTLETTER
		        INSERT INTO CHECKLISTLETTER
		        (CRITERIANO,
		        LETTERNO,
		        QUESTIONNO,
		        REQUIREDANSWER,
		        INHERITED)
		        SELECT
		        C.CRITERIANO,
		        CL.LETTERNO,
		        CL.QUESTIONNO,
		        CL.REQUIREDANSWER,
		        1
		        FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C 
		        join CHECKLISTLETTER CL on (CL.CRITERIANO = @pnParentCriteriaKey)
		       
		        Set @nErrorCode = @@Error
		End
	End
	Else
	Begin
		select 3
		
		If @nErrorCode = 0
		Begin
		        UPDATE CHECKLISTITEM
		        SET INHERITED = 0
		        WHERE CRITERIANO = @pnCriteriaKey
		        
		        Set @nErrorCode = @@Error
		End
		
		If @nErrorCode = 0
		Begin
		        UPDATE CHECKLISTLETTER
		        SET INHERITED = 0
		        WHERE CRITERIANO = @pnCriteriaKey
		        
		        Set @nErrorCode = @@Error
		End
	End
	
End
Else
Begin
	If @nErrorCode = 0
	Begin
		If @pnParentCriteriaKey is not null
		Begin
			-------------------------------------
			-- Delete all WINDOWCONTROL rows for 
			-- @pnCriteriaKey and its descendants
			-------------------------------------
			If @pbIsNameCriteria=1
			Begin
				Delete from WINDOWCONTROL
				where NAMECRITERIANO = @pnCriteriaKey
				
				Set @nErrorCode=@@Error
			End
			Else Begin
				Delete from WINDOWCONTROL
				where CRITERIANO = @pnCriteriaKey
				
				Set @nErrorCode=@@Error
			End
			
			If @nErrorCode = 0 
			Begin
				If @pbIsNameCriteria=1
				Begin
					Delete WC
					from dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C
					join WINDOWCONTROL WC on (WC.NAMECRITERIANO=C.CRITERIANO)
					where WC.ISINHERITED=1
	        			
					Set @nErrorCode=@@Error
				End
				Else Begin
					Delete WC
					from dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C
					join WINDOWCONTROL WC on (WC.CRITERIANO=C.CRITERIANO)
					where WC.ISINHERITED=1
	        			
					Set @nErrorCode=@@Error
				End
			End
			
			-- Insert new WINDOWCONTROL rows for the child criteria
			If @nErrorCode = 0
			Begin
				If @pbIsNameCriteria = 0
				Begin
					INSERT INTO WINDOWCONTROL(CRITERIANO, NAMECRITERIANO, WINDOWNAME, ISEXTERNAL, DISPLAYSEQUENCE, WINDOWTITLE, WINDOWSHORTTITLE, ENTRYNUMBER, THEME, ISINHERITED)
					SELECT C.CRITERIANO,NULL,WP.WINDOWNAME, WP.ISEXTERNAL, WP.DISPLAYSEQUENCE, WP.WINDOWTITLE, WP.WINDOWSHORTTITLE, WP.ENTRYNUMBER, WP.THEME, 1
					FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C 
					join WINDOWCONTROL WP on (WP.CRITERIANO = @pnParentCriteriaKey)
				End
				Else If @pbIsNameCriteria = 1
				Begin
					INSERT INTO WINDOWCONTROL(CRITERIANO, NAMECRITERIANO, WINDOWNAME, ISEXTERNAL, DISPLAYSEQUENCE, WINDOWTITLE, WINDOWSHORTTITLE, ENTRYNUMBER, THEME, ISINHERITED)
					SELECT NULL,C.CRITERIANO,WP.WINDOWNAME, WP.ISEXTERNAL, WP.DISPLAYSEQUENCE, WP.WINDOWTITLE, WP.WINDOWSHORTTITLE, WP.ENTRYNUMBER, WP.THEME, 1
					FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C 
					join WINDOWCONTROL WP on (WP.NAMECRITERIANO = @pnParentCriteriaKey)
				End
	                        
				Set @nErrorCode = @@ERROR
			End          
	                
			-- Insert TABCONTROL, TOPICCONTROL, ELEMENTCONTROL and TOPICCONTROLFILTER for the child criteria
			If @nErrorCode = 0
			Begin
				Set @sSQLString = 
				"INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, DISPLAYSEQUENCE, TABTITLE, ISINHERITED)
				SELECT WC.WINDOWCONTROLNO, T.TABNAME, T.DISPLAYSEQUENCE, TABTITLE, 1
				FROM WINDOWCONTROL W
				JOIN TABCONTROL T on (T.WINDOWCONTROLNO=W.WINDOWCONTROLNO)                        
				JOIN dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C on (1=1)
				JOIN WINDOWCONTROL WC on ("+
				CASE WHEN @pbIsNameCriteria=0 THEN "WC.CRITERIANO" ELSE "WC.NAMECRITERIANO" END
				+" = C.CRITERIANO)"+   
				"WHERE "+                    
				CASE WHEN @pbIsNameCriteria=0 THEN "W.CRITERIANO" ELSE "W.NAMECRITERIANO" END
				+ "=@pnParentCriteriaKey"+char(10)+
				"AND W.WINDOWNAME = WC.WINDOWNAME
				AND W.ISEXTERNAL = WC.ISEXTERNAL"                          
	                        
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCriteriaKey      int,
						@pbIsNameCriteria     bit,
						@pnParentCriteriaKey  int',
						@pnCriteriaKey = @pnCriteriaKey,
						@pbIsNameCriteria = @pbIsNameCriteria,
						@pnParentCriteriaKey = @pnParentCriteriaKey
			End
	                
			If @nErrorCode = 0
			Begin
				Set @sSQLString = 
				"INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TOPICNAME, TOPICSUFFIX, ROWPOSITION, COLPOSITION, TABCONTROLNO, TOPICTITLE, TOPICSHORTTITLE, TOPICDESCRIPTION, DISPLAYDESCRIPTION, SCREENTIP, ISHIDDEN, ISMANDATORY, ISINHERITED, FILTERNAME, FILTERVALUE)
				SELECT WC.WINDOWCONTROLNO, T.TOPICNAME, T.TOPICSUFFIX, ROWPOSITION, COLPOSITION, TC.TABCONTROLNO, TOPICTITLE, TOPICSHORTTITLE, TOPICDESCRIPTION, DISPLAYDESCRIPTION, SCREENTIP, ISHIDDEN, ISMANDATORY, 1, FILTERNAME, FILTERVALUE
				FROM WINDOWCONTROL W
				JOIN TOPICCONTROL T on (T.WINDOWCONTROLNO = W.WINDOWCONTROLNO)
				join dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C on (1=1)
				join WINDOWCONTROL WC on ("+
				CASE WHEN @pbIsNameCriteria=0 THEN "WC.CRITERIANO" ELSE "WC.NAMECRITERIANO" END
				+" = C.CRITERIANO AND WC.WINDOWNAME = W.WINDOWNAME)
				left join TABCONTROL TCP on (TCP.TABCONTROLNO = T.TABCONTROLNO)
				left join TABCONTROL TC on (TC.TABNAME = TCP.TABNAME AND TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO)
				WHERE "+
				CASE WHEN @pbIsNameCriteria=0 THEN "W.CRITERIANO" ELSE "W.NAMECRITERIANO" END
				+" = @pnParentCriteriaKey"                         
	                        
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCriteriaKey      int,
						@pbIsNameCriteria     bit,
						@pnParentCriteriaKey  int',
						@pnCriteriaKey = @pnCriteriaKey,
						@pbIsNameCriteria = @pbIsNameCriteria,
						@pnParentCriteriaKey = @pnParentCriteriaKey
			End
	                
			If @nErrorCode = 0
			Begin
				Set @sSQLString = 
				"INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, SHORTLABEL, FULLLABEL, BUTTON, TOOLTIP, LINK, LITERAL, DEFAULTVALUE, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED, FILTERNAME, FILTERVALUE)
				SELECT DISTINCT TC.TOPICCONTROLNO, ELEMENTNAME, SHORTLABEL, FULLLABEL, BUTTON, TOOLTIP, LINK, LITERAL, DEFAULTVALUE, E.ISHIDDEN, E.ISMANDATORY, ISREADONLY, 1, E.FILTERNAME, E.FILTERVALUE
				FROM WINDOWCONTROL W
				JOIN TOPICCONTROL T on (T.WINDOWCONTROLNO = W.WINDOWCONTROLNO)
				JOIN ELEMENTCONTROL E on (E.TOPICCONTROLNO = T.TOPICCONTROLNO)
				join dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C on (1=1)
				join WINDOWCONTROL WC on ("+
				CASE WHEN @pbIsNameCriteria=0 THEN "WC.CRITERIANO" ELSE "WC.NAMECRITERIANO" END
				+" = C.CRITERIANO)
				join TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO 
							AND TC.TOPICNAME = T.TOPICNAME)  
				WHERE "+
				CASE WHEN @pbIsNameCriteria=0 THEN "W.CRITERIANO" ELSE "W.NAMECRITERIANO" END
				+" = @pnParentCriteriaKey"                 
	                        
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCriteriaKey      int,
						@pbIsNameCriteria     bit,
						@pnParentCriteriaKey  int',
						@pnCriteriaKey = @pnCriteriaKey,
						@pbIsNameCriteria = @pbIsNameCriteria,
						@pnParentCriteriaKey = @pnParentCriteriaKey
			End     
                        
                        If @nErrorCode = 0
			Begin
				Set @sSQLString = 
				"INSERT INTO TOPICCONTROLFILTER(TOPICCONTROLNO, FILTERNAME, FILTERVALUE)
				SELECT DISTINCT TC.TOPICCONTROLNO, TF.FILTERNAME, TF.FILTERVALUE
				FROM WINDOWCONTROL W
				JOIN TOPICCONTROL T on (T.WINDOWCONTROLNO = W.WINDOWCONTROLNO)
				JOIN TOPICCONTROLFILTER TF on (TF.TOPICCONTROLNO = T.TOPICCONTROLNO)
				JOIN dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C on (1=1)
				JOIN WINDOWCONTROL WC on ("+
				CASE WHEN @pbIsNameCriteria=0 THEN "WC.CRITERIANO" ELSE "WC.NAMECRITERIANO" END
				+" = C.CRITERIANO)
				JOIN TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO 
							AND TC.TOPICNAME = T.TOPICNAME)  
				WHERE "+
				CASE WHEN @pbIsNameCriteria=0 THEN "W.CRITERIANO" ELSE "W.NAMECRITERIANO" END
				+" = @pnParentCriteriaKey"                 
	                        
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCriteriaKey      int,
						@pbIsNameCriteria     bit,
						@pnParentCriteriaKey  int',
						@pnCriteriaKey = @pnCriteriaKey,
						@pbIsNameCriteria = @pbIsNameCriteria,
						@pnParentCriteriaKey = @pnParentCriteriaKey
			End    
	                
	                -------------------------------------
			-- Delete all WINDOWCONTROL rows for 
			-- @pnCriteriaKey and its descendants
			-------------------------------------
			If @pbIsNameCriteria=1
			Begin
				Delete from TOPICDEFAULTSETTINGS
				where NAMECRITERIANO = @pnCriteriaKey
				
				Set @nErrorCode=@@Error
			End
			Else Begin
				Delete from TOPICDEFAULTSETTINGS
				where CRITERIANO = @pnCriteriaKey
				
				Set @nErrorCode=@@Error
			End
			
			If @nErrorCode = 0 
			Begin
				If @pbIsNameCriteria=1
				Begin
					Delete TD
					from dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C
					join TOPICDEFAULTSETTINGS TD on (TD.NAMECRITERIANO=C.CRITERIANO)
					where TD.ISINHERITED=1
	        			
					Set @nErrorCode=@@Error
				End
				Else Begin
					Delete TD
					from dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C
					join TOPICDEFAULTSETTINGS TD on (TD.CRITERIANO=C.CRITERIANO)
					where TD.ISINHERITED=1
	        			
					Set @nErrorCode=@@Error
				End
			End
			
			-- Insert new TOPICDEFAULTSETTINGS rows for the child criteria
			If @nErrorCode = 0
			Begin
				If @pbIsNameCriteria = 0
				Begin
					INSERT INTO TOPICDEFAULTSETTINGS(CRITERIANO, NAMECRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE, ISINHERITED)
					SELECT C.CRITERIANO,NULL,TD.TOPICNAME, TD.FILTERNAME, TD.FILTERVALUE, 1
					FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C 
					join TOPICDEFAULTSETTINGS TD on (TD.CRITERIANO = @pnParentCriteriaKey)
				End
				Else If @pbIsNameCriteria = 1
				Begin
					INSERT INTO TOPICDEFAULTSETTINGS(CRITERIANO, NAMECRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE, ISINHERITED)
					SELECT NULL,C.CRITERIANO,TD.TOPICNAME, TD.FILTERNAME, TD.FILTERVALUE, 1
					FROM dbo.fn_GetChildCriteria (@pnCriteriaKey,@pbIsNameCriteria) C 
					join TOPICDEFAULTSETTINGS TD on (TD.NAMECRITERIANO = @pnParentCriteriaKey)
				End
	                        
				Set @nErrorCode = @@ERROR
			End      
		End
		Else 
		-- removing inheritance link: child criteria keeps properties
		Begin
			If @pbIsNameCriteria = 0
			Begin
				UPDATE WINDOWCONTROL
				SET ISINHERITED = 0
				WHERE CRITERIANO = @pnCriteriaKey
	                        
				Set @nErrorCode = @@ERROR
	                        
				If @nErrorCode = 0
				Begin
					UPDATE TABCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from WINDOWCONTROL 
						WHERE CRITERIANO = @pnCriteriaKey 
						and WINDOWCONTROLNO = TABCONTROL.WINDOWCONTROLNO)         
	                                
					Set @nErrorCode = @@ERROR               
				End
	                        
				If @nErrorCode = 0
				Begin
					UPDATE TOPICCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from WINDOWCONTROL
						      WHERE CRITERIANO = @pnCriteriaKey
						      and WINDOWCONTROLNO = TOPICCONTROL.WINDOWCONTROLNO)
	                                
					Set @nErrorCode = @@ERROR 
				End
	                        
				If @nErrorCode = 0
				Begin
					UPDATE ELEMENTCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from TOPICCONTROL T
							JOIN WINDOWCONTROL W on (W.CRITERIANO = @pnCriteriaKey
							AND W.WINDOWCONTROLNO = T.WINDOWCONTROLNO)
							WHERE TOPICCONTROLNO = ELEMENTCONTROL.TOPICCONTROLNO)
	                                
					Set @nErrorCode = @@ERROR  
				End
				
				If @nErrorCode = 0
				Begin
					UPDATE TOPICDEFAULTSETTINGS
					SET ISINHERITED = 0
					WHERE CRITERIANO = @pnCriteriaKey         
	                                
					Set @nErrorCode = @@ERROR               
				End
			End
			Else
			Begin
				UPDATE WINDOWCONTROL
				SET ISINHERITED = 0
				WHERE NAMECRITERIANO = @pnCriteriaKey
	                        
				Set @nErrorCode = @@ERROR
	                        
				If @nErrorCode = 0
				Begin
					UPDATE TABCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from WINDOWCONTROL 
						WHERE NAMECRITERIANO = @pnCriteriaKey 
						and WINDOWCONTROLNO = TABCONTROL.WINDOWCONTROLNO)         
	                                
					Set @nErrorCode = @@ERROR               
				End
	                        
				If @nErrorCode = 0
				Begin
					UPDATE TOPICCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from WINDOWCONTROL
						      WHERE NAMECRITERIANO = @pnCriteriaKey
						      and WINDOWCONTROLNO = TOPICCONTROL.WINDOWCONTROLNO)
	                                
					Set @nErrorCode = @@ERROR 
				End
	                        
				If @nErrorCode = 0
				Begin
					UPDATE ELEMENTCONTROL
					SET ISINHERITED = 0
					WHERE EXISTS (SELECT 1 from TOPICCONTROL T
							JOIN WINDOWCONTROL W on (W.NAMECRITERIANO = @pnCriteriaKey
							AND W.WINDOWCONTROLNO = T.WINDOWCONTROLNO)
							WHERE TOPICCONTROLNO = ELEMENTCONTROL.TOPICCONTROLNO)
	                                
					Set @nErrorCode = @@ERROR  
				End
				
				If @nErrorCode = 0
				Begin
					UPDATE TOPICDEFAULTSETTINGS
				        SET ISINHERITED = 0
				        WHERE NAMECRITERIANO = @pnCriteriaKey         
	                                
					Set @nErrorCode = @@ERROR               
				End
			End
		End        
	End
End




Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainCriteriaInheritance to public
GO