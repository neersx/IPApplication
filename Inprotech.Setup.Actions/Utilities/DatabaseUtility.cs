using System;
using System.Data;
using System.Data.SqlClient;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class DatabaseUtility
    {
        public static void EnsureWindowsUserLogin(string administrationConnectionString, string user)
        {
            var builder = new SqlConnectionStringBuilder(administrationConnectionString);

            const string createLogin =
                "IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '{0}' or sid = suser_sid(N'{0}')) BEGIN CREATE LOGIN [{0}] FROM WINDOWS WITH DEFAULT_DATABASE=[{1}] END";

            const string createUser =
                "IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '{0}' or sid = suser_sid(N'{0}')) RETURN; CREATE USER [{0}] FOR LOGIN [{0}];";

            using (var connection = new SqlConnection(administrationConnectionString))
            {
                connection.Open();
                connection.ChangeDatabase("master");

                var command = connection.CreateCommand();
                command.CommandText = string.Format(createLogin, user, builder.InitialCatalog);
                command.ExecuteNonQuery();

                connection.ChangeDatabase(builder.InitialCatalog);
                command = connection.CreateCommand();
                command.CommandText = string.Format(createUser, user);
                command.ExecuteNonQuery();
            }
        }

        public static void EnsureSqlUserLogin(string connectionString, string user)
        {
            const string createUser =
                "IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '{0}' or sid = suser_sid(N'{0}')) RETURN; CREATE USER [{0}] FOR LOGIN [{0}];";

            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandText = string.Format(createUser, user);
                command.ExecuteNonQuery();
            }
        }

        public static void GrantReaderWriterAccess(string connectionString, string user)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandText =
                    string.Format($"declare @un varchar(max); select @un = name from sysusers where name = '{user}' or sid = suser_sid(N'{user}'); IF(@un <> 'dbo') BEGIN EXEC sp_addrolemember 'db_datawriter', @un; EXEC sp_addrolemember 'db_datareader', @un; END");
                command.ExecuteNonQuery();
            }
        }

        public static void UpdateInprotechVersion(string connectionString, string version, string siteControl)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = $"update SITECONTROL set COLCHARACTER='{version}' where CONTROLID='{siteControl}'";
                command.ExecuteNonQuery();
            }
        }

        public static void UpdateInprotechIntegrationVersion(string connectionString, string version, string siteControl)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = $"update ConfigurationSettings set value = '{version}' where [key] = '{siteControl}'";
                command.ExecuteNonQuery();
            }
        }

        public static int UpdateJobAllocations(string connectionString, string currentInstanceName, string newInstanceName)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = "IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DependableJobs') BEGIN update DependableJobs set InstanceName = @pNew where InstanceName = @pOld ";

                var p1 = command.Parameters.Add("@pOld", SqlDbType.NVarChar, 200);
                var p2 = command.Parameters.Add("@pNew", SqlDbType.NVarChar, 200);
                p1.Value = string.IsNullOrWhiteSpace(currentInstanceName)
                    ? DBNull.Value
                    : (object) currentInstanceName;

                p2.Value = string.IsNullOrWhiteSpace(newInstanceName)
                    ? DBNull.Value
                    : (object) newInstanceName;

                if (string.IsNullOrWhiteSpace(currentInstanceName))
                    command.CommandText += " or InstanceName is null";
                command.CommandText += " END";

                return command.ExecuteNonQuery();
            }
        }

        public static string GetSqlVersion(string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                return connection.ServerVersion;
            }
        }

        public static bool IsMixedMode(string connectionString)
        {
            const string mixedMode = "MixedMode";
            const string windowsMode = "WindowsMode";

            try
            {
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    var command = connection.CreateCommand();
                    command.CommandText = $"SELECT CASE SERVERPROPERTY('IsIntegratedSecurityOnly') WHEN 0 THEN '{mixedMode}' WHEN 1 THEN '{windowsMode}' END AS [AuthMode]";
                    var authMode = command.ExecuteScalar().ToString();

                    if (authMode == mixedMode)
                        return true;
                }
            }
            catch (Exception)
            {
                return false;
            }

            return false;
        }
    }
}