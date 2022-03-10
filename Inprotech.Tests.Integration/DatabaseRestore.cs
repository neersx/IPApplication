using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Threading;
using Inprotech.Tests.Integration.Utils;

namespace Inprotech.Tests.Integration
{
    public static class DatabaseRestore
    {
        const string SqlLoginScript =
            @"IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '{0}' or sid = suser_sid(N'{0}')) RETURN; CREATE USER [{0}] FOR LOGIN [{0}];";

        const string AddMemberToRoleScript =
            @"if (IS_ROLEMEMBER('{1}', '[{0}]')=0) ALTER ROLE [{1}] ADD MEMBER [{0}]";

        const string TakeDatabaseOfflineCmd = @"
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '{0}' OR name = '{0}')))
BEGIN
    ALTER DATABASE [{0}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
END";

        const string DropDatabase = @"
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '{0}' OR name = '{0}')))
BEGIN
    DROP DATABASE [{0}]
END";

        static bool _restored;

        internal static void Restore()
        {
            if (_restored) return;

            Do(() =>
            {
                PrepareDatabaseForE2E();
                RebuildIntegrationDatabase();
            });

            _restored = true;
        }

        internal static void SafeRebuildIntegrationDatabase()
        {
            Do(RebuildIntegrationDatabase, forDevHost: false);
        }

        static void Do(Action runDatabaseRestore, bool forTeamCity = true, bool forDevHost = true)
        {
            var serverRunning = false;
            var intergrationRunning = false;
            var devHostRunning = DevelopmentHost.IsRunning();
            var devIntegrationServerRunning = DevelopmentIntegrationServer.IsRunning();

            var instanceName = Runtime.InstanceName;

            try
            {
                if (forTeamCity)
                {
                    if (Runtime.IsRunningInDockerMode)
                    {
                        RunnerInterface.StopDockerAppsInstances();
                    }
                    else
                    {
                        serverRunning = Runner.StopService($"Inprotech.Server${instanceName}");
                        intergrationRunning = Runner.StopService($"Inprotech.IntegrationServer${instanceName}");
                    }
                }

                if (forDevHost)
                {
                    if (devHostRunning) DevelopmentHost.Stop();
                    if (devIntegrationServerRunning) DevelopmentIntegrationServer.Stop();
                }

                runDatabaseRestore();
            }
            finally
            {
                if (forTeamCity)
                {
                    if (Runtime.IsRunningInDockerMode)
                    {
                        RunnerInterface.StartDockerAppsInstances();
                    }
                    else
                    {
                        if (serverRunning) Try.Do(() => Runner.StartService($"Inprotech.Server${instanceName}"));
                        if (intergrationRunning) Try.Do(() => Runner.StartService($"Inprotech.IntegrationServer${instanceName}"));
                        if (serverRunning && intergrationRunning) WaitUntilServerOnline(TimeSpan.FromMinutes(2));
                    }
                }

                if (forDevHost)
                {
                    if (devHostRunning) DevelopmentHost.Start();
                    if (devIntegrationServerRunning) DevelopmentIntegrationServer.Start();
                    if (devHostRunning && devIntegrationServerRunning) WaitUntilServerOnline(TimeSpan.FromMinutes(2));
                }
            }
        }

        internal static void GrantAllPermissions()
        {
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
            Runner.ExecuteSql(From.EmbeddedScripts("post-dev-upgrade.sql"), connStr, "Grant all permissions");
        }

        internal static void EnableServiceBroker()
        {
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
            foreach (var statement in SqlUtility.SplitSqlStatements(From.EmbeddedScripts("EnableServiceBroker.sql"))) Runner.ExecuteSql(statement, connStr, "Enable Service Broker");
        }

        internal static void UpdateDatabaseForE2E()
        {
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;

            var sql = From.EmbeddedScripts("AddE2ECreatedColumn.sql");
            Runner.ExecuteSql(sql, connStr, "Add column to track rows added by E2E");

            foreach (var statement in SqlUtility.SplitSqlStatements(From.EmbeddedScripts("lastrefno.sql"))) Runner.ExecuteSql(statement, connStr, "Set InternalSequence");
        }

        internal static void RebuildIntegrationDatabase()
        {
            var connStr = ConfigurationManager.ConnectionStrings["InprotechIntegration"].ConnectionString;
            var integration = new SqlConnectionStringBuilder(connStr);
            var database = integration.InitialCatalog;
            var serverName = integration.DataSource;
            if (serverName == ".") serverName = "localhost";
            var user = integration.UserID;
            var osUser = Env.GetUserDomainAndName();

            Try.Do(() => Runner.ExecuteSqlViaMaster(string.Format(TakeDatabaseOfflineCmd, database), connStr, "Take integration database offline"));

            Try.Do(() => Runner.ExecuteSqlViaMaster(string.Format(DropDatabase, database), connStr, "Drop integration database"));

            var integargs = $"-m \"inprotechintegration\" -c \"{connStr}\"";

            Runner.RunProcess(Runtime.Tools.Upgrade, integargs, "Upgrade integration database");

            // EnsureWindowsLogin(osUser, connStr);

            EnsureSqlLogin(user, connStr);
        }

        static void PrepareDatabaseForE2E()
        {
            GrantAllPermissions();
            EnableServiceBroker();
            UpdateDatabaseForE2E();
        }
        
        static void EnsureSqlLogin(string user, string connStr)
        {
            if (string.IsNullOrWhiteSpace(user))
            {
                return;
            }

            Runner.ExecuteSqlViaMaster(string.Format(SqlLoginScript, user), connStr, "assigning sql login");

            var roles = new[] { "db_owner", "db_accessadmin", "db_securityadmin" };

            foreach (var role in roles) Runner.ExecuteSql(string.Format(AddMemberToRoleScript, user, role), connStr, $"assinging {role} to {user}");
        }

        internal static void CreateNegativeWorkflowSecurityTask()
        {
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
            foreach (var statement in SqlUtility.SplitSqlStatements(From.EmbeddedScripts("SecurityTask-CreateNegativeWorkflowRules.sql"))) Runner.ExecuteSql(statement, connStr, "Create security task for negative workflow");
        }

        internal static void CreateElectronicFilingArtifacts()
        {
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
            foreach (var statement in SqlUtility.SplitSqlStatements(From.EmbeddedScripts("E-Filing-DeliverIntegrationArtifacts.sql"))) Runner.ExecuteSql(statement, connStr, "Create E-filing Integration database artifacts");
        }

        static void WaitUntilServerOnline(TimeSpan? maxWait = null)
        {
            var w = new Stopwatch();
            var connStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;

            w.Start();

            do
            {
                var instances = @"select case when SETTINGVALUE like '%Online%' then 1 else 0 end from CONFIGURATIONSETTINGS where SETTINGKEY = '{0}';";

                var serverStarted = Runner.ExecuteScalar(string.Format(instances, "Inprotech.Server.Instances"), connStr, $"Inprotech.Server not yet online {w.ElapsedMilliseconds}");

                var integrationServerStarted = Runner.ExecuteScalar(string.Format(instances, "Inprotech.IntegrationServer.Instances"), connStr, $"Inprotech.IntegrationServer not yet online {w.ElapsedMilliseconds}");

                if (IsTrue(serverStarted) && IsTrue(integrationServerStarted))
                {
                    RunnerInterface.Log($"Servers online now after {TimeSpan.FromMilliseconds(w.ElapsedMilliseconds).ToString()}");
                    w.Stop();
                    return;
                }

                Thread.Sleep(TimeSpan.FromMilliseconds(500));
            }
            while (w.Elapsed <= (maxWait ?? TimeSpan.FromMinutes(2)));

            w.Stop();
            RunnerInterface.Log("Max timeout reached waiting for the servers to be online");

            bool IsTrue(object v)
            {
                return v is int && (int)v == 1;
            }
        }
    }
}