using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.ServiceProcess;
using Inprotech.Tests.Integration.Extensions;
using static System.String;

namespace Inprotech.Tests.Integration
{
    public static class Runner
    {
        public static void ExecuteSqlViaMaster(string command, string connectionString, string teamCityMessage = null)
        {
            var connStr = BuildConnectionStringForExecutionContext(connectionString, "master");
            InnerExecuteSql(command, connStr, teamCityMessage);
        }

        public static void ExecuteSql(string command, string connectionString, string teamCityMessage = null)
        {
            var connStr = BuildConnectionStringForExecutionContext(connectionString);
            InnerExecuteSql(command, connStr, teamCityMessage);
        }

        public static object ExecuteScalar(string command, string connectionString, string teamCityMessage = null)
        {
            var connStr = BuildConnectionStringForExecutionContext(connectionString);
            return InnerExecuteScalar(command, connStr, teamCityMessage);
        }

        public static string RunProcess(string app, string args, string teamCityMessage = null)
        {
            RunnerInterface.Log(teamCityMessage);

            try
            {
                RunnerInterface.Log("app : " + app);
                RunnerInterface.Log("args: " + args);

                string output = null;

                using (var process = new Process())
                {
                    process.StartInfo.FileName = app;
                    process.StartInfo.Arguments = args;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.OutputDataReceived += (sender, a) =>
                    {
                        if (!IsNullOrEmpty(output)) output += "\r\n";
                        output += a.Data;
                        RunnerInterface.Log(a.Data);
                    };
                    process.Start();
                    process.BeginOutputReadLine();
                    process.WaitForExit();

                    if (process.ExitCode != 0) throw new Exception("process exited with code " + process.ExitCode);
                }
                return output;
            }
            catch (Exception ex)
            {
                throw new Exception("failed to run process " + app + " with args " + args, ex);
            }
        }

        public static void KillProcess(params string[] exeNames)
        {
            foreach (var exeName in exeNames)
            {
                var exeWithoutExtension = exeName.Contains(".exe") ? exeName.Replace(".exe", string.Empty) : exeName;
                foreach (var process in Process.GetProcessesByName(exeWithoutExtension))
                {
                    process.KillProcessAndChildren();
                }
            }
        }

        public static bool StopService(string serviceName)
        {
            if (ServiceController.GetServices().All(s => s.ServiceName != serviceName)) return false;

            try
            {
                RunnerInterface.Log("Stopping " + serviceName);

                using (var serviceController = new ServiceController(serviceName, "."))
                {
                    if (serviceController.Status == ServiceControllerStatus.StopPending ||
                        serviceController.Status == ServiceControllerStatus.Stopped)
                    {
                        return false;
                    }

                    serviceController.Stop();
                }
            }
            finally
            {
                RunnerInterface.Log("Stopped " + serviceName);
            }

            return true;
        }

        public static void StartService(string serviceName)
        {
            if (ServiceController.GetServices().All(s => s.ServiceName != serviceName)) return;

            try
            {
                RunnerInterface.Log("Starting " + serviceName);

                using (var serviceController = new ServiceController(serviceName, "."))
                {
                    if (serviceController.Status == ServiceControllerStatus.StartPending ||
                        serviceController.Status == ServiceControllerStatus.Running)
                    {
                        return;
                    }

                    serviceController.Start();
                }
            }
            finally
            {
                RunnerInterface.Log("Started " + serviceName);
            }
        }

        static string BuildConnectionStringForExecutionContext(string connectionString, string replaceDb = null)
        {
            var connBuilder = new SqlConnectionStringBuilder(connectionString);
            var database = replaceDb ?? connBuilder.InitialCatalog;
            var serverName = connBuilder.DataSource;
            if (serverName == ".") serverName = "localhost";

            connBuilder.DataSource = serverName;
            connBuilder.InitialCatalog = database;
            connBuilder.ApplicationName = "E2E Test";
            return connBuilder.ToString();
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        static void InnerExecuteSql(string command, string connectionString, string teamCityMessage = null)
        {
            if (IsNullOrWhiteSpace(command)) return;

            RunnerInterface.Log(teamCityMessage);
            RunnerInterface.Log(command);

            try
            {
                using (var sqlConnection = new SqlConnection(connectionString))
                {
                    sqlConnection.Open();
                    using (var sqlCommand = new SqlCommand(command, sqlConnection))
                    {
                        sqlCommand.CommandTimeout = 0;
                        sqlCommand.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                RunnerInterface.Log(ex.Message);
            }
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        static object InnerExecuteScalar(string command, string connectionString, string teamCityMessage = null)
        {
            if (IsNullOrWhiteSpace(command)) return null;

            RunnerInterface.Log(teamCityMessage);
            RunnerInterface.Log(command);

            try
            {
                using (var sqlConnection = new SqlConnection(connectionString))
                {
                    sqlConnection.Open();
                    using (var sqlCommand = new SqlCommand(command, sqlConnection))
                    {
                        sqlCommand.CommandTimeout = 0;
                        var scalarValue = sqlCommand.ExecuteScalar();
                        return scalarValue;
                    }
                }
            }
            catch (Exception ex)
            {
                RunnerInterface.Log(ex.Message);
            }

            return null;
        }
    }
}