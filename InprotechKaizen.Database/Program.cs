using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Reflection;
using CommandLine;
using Dapper;
using DbUp;
using DbUp.Helpers;
using Dependable.Extensions.Persistence.Sql;

namespace InprotechKaizen.Database
{
    class Program
    {
        static readonly IDictionary<string, string> ScriptSet = new Dictionary<string, string>
        {
            {"inprotech", "Scripts"},
            {"inprotechintegration", "IntegrationScripts"}
        };

        static readonly IDictionary<string, Func<Options, DbUpgradeStatus>> Addons = new Dictionary
            <string, Func<Options, DbUpgradeStatus>>
        {
            {"inprotech", _ => DbUpgradeStatus.Success},
            {"inprotechintegration", ApplyIntegrationServerAddons}
        };

        static readonly IDictionary<string, Func<Options, DbUpgradeStatus>> Setup = new Dictionary
            <string, Func<Options, DbUpgradeStatus>>
        {
            {"inprotech", _ => DbUpgradeStatus.Success},
            {"inprotechintegration", CreateIntegrationServerDatabase}
        };

        static int Main(string[] args)
        {
            var options = new Options();
            if (!Parser.Default.ParseArguments(args, options))
            {
                throw new InvalidOperationException(
                    "Invalid arguments. Please use named arguments e.g. -m [inprotech|inprotechintegration] -c <ConnetionString>.\nThe actual arguments:\n" +
                    string.Join(" ", args));
            }

            var mode = options.Mode.ToLower();

            if (options.Script)
                return (int)ExecuteSafe(options, FirstPendingScript);

            if (ExecuteSafe(options, Setup[mode]) == DbUpgradeStatus.Failure)
                return 1;

            if (ExecuteSafe(options, Addons[mode]) == DbUpgradeStatus.Failure)
                return 1;

            return (int)ExecuteSafe(options, ApplyChanges);
            
        }

        public static DbUpgradeStatus ApplyChanges(Options options)
        {
            var scriptsSet = ScriptSet[options.Mode.ToLower()];
            var upgrader =
                DeployChanges.To
                    .SqlDatabase(options.ConnectionString, null)
                    .ConfigureEx(c =>
                    {
                        c.ScriptExecutor.ExecutionTimeoutSeconds = 300;
                        if (options.Force)
                            c.Journal = new NullJournal();
                    })
                    .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(), s => s.Filter(scriptsSet))
                    .LogToConsole()
                    .Build();

            var result = upgrader.PerformUpgrade();

            if (!result.Successful)
                throw result.Error;

            return DbUpgradeStatus.Success;
        }

        public static DbUpgradeStatus ApplyIntegrationServerAddons(Options options)
        {
            DependableJobsTable.Create(options.ConnectionString);

            DependableJobsTable.Clean(options.ConnectionString);
            return DbUpgradeStatus.Success;
        }

        static DbUpgradeStatus CreateIntegrationServerDatabase(Options options)
        {
            var connectionStringBuilder = new SqlConnectionStringBuilder(options.ConnectionString);
            var targetDatabaseName = connectionStringBuilder.InitialCatalog;
            connectionStringBuilder.InitialCatalog = "master";

            using (var connection = new SqlConnection(connectionStringBuilder.ConnectionString))
            {
                
                connection.Execute(
                    string.Format(
                        "if not exists (select * from sys.databases WHERE [name]=N'{0}') begin  create database [{0}] COLLATE Latin1_General_CI_AS end",
                        targetDatabaseName));
            }

            return DbUpgradeStatus.Success;
        }

        static DbUpgradeStatus ExecuteSafe(Options options, Func<Options, DbUpgradeStatus> func)
        {
            try
            {
                return func(options);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine(e);
                return DbUpgradeStatus.Failure;
            }
        }

        static DbUpgradeStatus FirstPendingScript(Options options)
        {
            var scriptsSet = ScriptSet[options.Mode.ToLower()];
            var upgrader =
                DeployChanges.To
                    .SqlDatabase(options.ConnectionString, null)
                    .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(), s => s.Filter(scriptsSet))
                    .Build();
            var failedScripts = upgrader.GetScriptsToExecute();
            if (failedScripts.Count > 0)
            {
                Console.Out.WriteLine("-- SCRIPT NAME: " + failedScripts[0].Name);
                Console.Out.WriteLine();
                Console.Out.Write(failedScripts[0].Contents);                
                return DbUpgradeStatus.Success;
            }
            throw new Exception("No Pending Script");
        }
    }
}