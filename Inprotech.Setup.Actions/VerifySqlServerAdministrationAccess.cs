using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Threading;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class VerifySqlServerAdministrationAccess : ISetupAction
    {
        public string Description => "Verify SQL Server administration access";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var inprotechConnectionString = (string) context["InprotechConnectionString"];
            var inprotechAdministrationConnectionString = (string) context["InprotechAdministrationConnectionString"];
            var integrationAdministrationConnectionString = (string) context["IntegrationAdministrationConnectionString"];

            var p = new SqlAccessProber(inprotechAdministrationConnectionString, integrationAdministrationConnectionString);
            if (p.CanAccess())
            {
                return;
            }

            var applyCredentials = false;
            bool isMixedMode;

            if (context.ContainsKey("Database.Username") && !string.IsNullOrEmpty((string) context["Database.Username"]))
            {
                var username = (string) context["Database.Username"];
                var pwd = (string) context["Database.Password"];

                applyCredentials = p.CanAccess(username, pwd);
                isMixedMode = true;
            }
            else
            {
                isMixedMode = DatabaseUtility.IsMixedMode(inprotechConnectionString);
            }

            if (!applyCredentials && context.ContainsKey("Dispatcher"))
            {
                var dispatcher = (Dispatcher) context["Dispatcher"];
                var shouldCredentialsBeApplied = isMixedMode;

                dispatcher.Invoke(() =>
                {
                    var window = isMixedMode ? (Window) new SqlCredentials(p) : new SqlCredentialsWindowsOnlyAuthMode();
                    if (window.ShowDialog() == true)
                    {
                        applyCredentials = shouldCredentialsBeApplied;
                    }
                });
            }

            if (!applyCredentials)
            {
                throw new SetupFailedException("A valid Microsoft SQL Server account has not been provided to continue with the database setup.");
            }

            var c = new SqlConnectionStringBuilder(p.InprotechConnectionString);

            context["InprotechAdministrationConnectionString"] = ApplyUpdateCredentials(inprotechAdministrationConnectionString, c.UserID, c.Password);

            context["IntegrationAdministrationConnectionString"] = ApplyUpdateCredentials(integrationAdministrationConnectionString, c.UserID, c.Password);
        }

        static string ApplyUpdateCredentials(string existingConnectionString, string userName, string password)
        {
            return new SqlConnectionStringBuilder(existingConnectionString)
            {
                UserID = userName,
                Password = password,
                IntegratedSecurity = false,
                PersistSecurityInfo = true
            }.ToString();
        }
    }

    public class SqlAccessProber
    {
        public SqlAccessProber(string inprotechConnectionStr, string integrationConnectionStr)
        {
            InprotechConnectionString = inprotechConnectionStr;
            IntegrationConnectionString = integrationConnectionStr;
        }

        public string InprotechConnectionString { get; private set; }

        public string IntegrationConnectionString { get; private set; }

        public bool CanAccess(string userName, string password)
        {
            if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
            {
                return false;
            }

            InprotechConnectionString = new SqlConnectionStringBuilder(InprotechConnectionString)
            {
                UserID = userName,
                Password = password,
                IntegratedSecurity = false,
                PersistSecurityInfo = true
            }.ToString();

            return CanAccess() || IsOwner(userName, password);
        }

        public bool CanAccess()
        {
            return IsAdmin() || IsOwner();
        }

        bool IsAdmin()
        {
            try
            {
                using (var c = new SqlConnection(InprotechConnectionString))
                {
                    c.Open();
                    c.ChangeDatabase("master");

                    using (var cmd = c.CreateCommand())
                    {
                        cmd.CommandText =
                            "select CASE WHEN IS_SRVROLEMEMBER ('sysadmin') = 1 OR IS_SRVROLEMEMBER ('dbcreator') = 1 THEN 1 ELSE 0 END";
                        return (int) cmd.ExecuteScalar() == 1;
                    }
                }
            }
            catch (Exception)
            {
                return false;
            }
        }

        bool IsOwner(string userName, string password)
        {
            if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
            {
                return false;
            }

            InprotechConnectionString = new SqlConnectionStringBuilder(InprotechConnectionString)
            {
                UserID = userName,
                Password = password,
                IntegratedSecurity = false,
                PersistSecurityInfo = true
            }.ToString();

            IntegrationConnectionString = new SqlConnectionStringBuilder(IntegrationConnectionString)
            {
                UserID = userName,
                Password = password,
                IntegratedSecurity = false,
                PersistSecurityInfo = true
            }.ToString();

            return IsOwner();
        }

        bool IsOwner()
        {
            if (IsOwner(InprotechConnectionString))
            {
                return IsOwner(IntegrationConnectionString);
            }
            return false;
        }

        bool IsOwner(string connString)
        {
            try
            {
                using (var c = new SqlConnection(connString))
                {
                    c.Open();
                    using (var cmd = c.CreateCommand())
                    {
                        cmd.CommandText =
                            "select CASE WHEN IS_MEMBER ('db_owner') = 1 AND IS_MEMBER ('db_denydatawriter') = 0 AND IS_MEMBER ('db_denydatareader') = 0 THEN 1 ELSE 0 END";
                        return (int) cmd.ExecuteScalar() == 1;
                    }
                }
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}