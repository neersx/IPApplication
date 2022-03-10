using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Microsoft.AspNet.SignalR;

namespace Demogod.Policing
{
    public enum ServerState
    {
        Off,
        On
    }

    public class ServerManager
    {
        const string IsPolicingRunning = @"
Select 0
from PROCESSREQUEST PR
join master.dbo.sysprocesses SP ON (SP.spid = PR.SPID and SP.login_time = PR.LOGINTIME)
join SITECONTROL SC ON (SC.CONTROLID = 'Police Continuously' and SC.COLBOOLEAN = 1)
where REQUESTTYPE = 'POLICING BACKGROUND'
";

        const string TurnOnPolicingCommand = @"
exec ipu_Policing_Start_Continuously
";

        const string TurnOffPolicingCommand = @"
UPDATE SITECONTROL SET COLBOOLEAN=0 WHERE CONTROLID = 'Police Continuously'
";

        const string MakeFailItemsCommand = @"
exec demo_generateCasesForPolicing @pnRequired=3, @psGenOptions='f'
";

        const string MakeErrorItemsCommand = @"
exec demo_generateCasesForPolicing @pnRequired =3, @psGenOptions='e'
";

        const string MakeMoreItemsCommand = @"
exec demo_generateCasesForPolicing 
";

        const string ClearAllItemsCommand = @"
delete from POLICING where SYSGENERATEDFLAG = 1
";

        const string ItemsFailedOrHasError = @"
select C.IRN as [CaseRef],
        CASE WHEN E.CASEID is not null THEN 'Error' ELSE 'Failed' END as [Status],
		case when UIN.NAMENO is null then P.SQLUSER else dbo.fn_FormatName(UIN.NAME, UIN.FIRSTNAME, UIN.TITLE, UIN.NAMESTYLE) end as [User]
        from POLICING P
        left join(select distinct CASEID
                   from POLICINGERRORS PE
                   where PE.LOGDATETIMESTAMP>=( Select MIN(P1.DATEENTERED)
                    from POLICING P1
                    where P1.ONHOLDFLAG<>1
					and P1.SYSGENERATEDFLAG=1
					and P1.ONHOLDFLAG between 2 and 4)
					) E on(E.CASEID= P.CASEID and P.ONHOLDFLAG between 2 and 4)
left join CASES C on(C.CASEID = P.CASEID)
left join USERIDENTITY UI on(P.IDENTITYID = UI.IDENTITYID)
left join NAME UIN on(UI.NAMENO = UIN.NAMENO)
where P.SYSGENERATEDFLAG=1
and ((E.CASEID is not null) or (E.CASEID is NULL and P.ONHOLDFLAG in (4) and datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) > 120))
";

        ServerState CheckState()
        {
            return ExecuteScalar(IsPolicingRunning) == null
                ? ServerState.Off
                : ServerState.On;
        }

        public void PublishServerState()
        {
            var hub = GlobalHost.ConnectionManager.GetHubContext("PolicingHub");

            var status = CheckState();

            hub.Clients.All.statusUpdate("status", status.ToString());
        }
        
        public void PublishProblemItems()
        {
            try
            {
                var hub = GlobalHost.ConnectionManager.GetHubContext("PolicingHub");
                
                var problems = FindProblems().ToArray();

                hub.Clients.All.problems(problems);
            }
            catch (Exception ex)
            {
                EventStream.Publish(ex);
            }
        }

        public void TurnOn()
        {
            ExecuteScalar(TurnOnPolicingCommand);
        }

        public void TurnOff()
        {
            ExecuteScalar(TurnOffPolicingCommand);
        }

        public void MakeFailedItems()
        {
            ExecuteScalar(MakeFailItemsCommand);
        }

        public void MakeErrorItems()
        {
            ExecuteScalar(MakeErrorItemsCommand);
        }

        public void MakeMoreItems()
        {
            ExecuteScalar(MakeMoreItemsCommand);
        }

        public void ClearAllItems()
        {
            ExecuteScalar(ClearAllItemsCommand);
        }

        object ExecuteScalar(string command)
        {
            try
            {
                using (var sqlConnection = new SqlConnection(Connection.String))
                {
                    sqlConnection.Open();
                    using (var sqlCommand = new SqlCommand(command, sqlConnection))
                    {
                        return sqlCommand.ExecuteScalar();
                    }
                }
            }
            catch (Exception ex)
            {
                EventStream.Publish(ex);
                return null;
            }
        }

        IEnumerable<PolicingProblems> FindProblems()
        {
            using (var sqlConnection = new SqlConnection(Connection.String))
            {
                sqlConnection.Open();
                using (var sqlCommand = new SqlCommand(ItemsFailedOrHasError, sqlConnection))
                using (var reader = sqlCommand.ExecuteReader(CommandBehavior.CloseConnection))
                {
                    while (reader.Read())
                    {
                        yield return new PolicingProblems
                                     {
                                         CaseRef = reader["CaseRef"] as string,
                                         Status = reader["Status"] as string,
                                         User = reader["User"] as string
                                     };
                    }
                }
            }
        }
    }

    public class PolicingProblems
    {
        public string CaseRef { get; set; }

        public string Status { get; set; }

        public string User { get; set; }
    }
}