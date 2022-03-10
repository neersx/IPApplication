using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Actions
{
    public class FailedDatabaseScript : ISetupAction
    {
        readonly IFileSystem _fileSystem;
        readonly IProcessRunner _processRunner;

        readonly IDictionary<string, string[]> _supportedActions = new Dictionary<string, string[]>
        {
            {typeof(ApplyInprotechDatabaseChanges).Name, new[] {"Inprotech", "InprotechAdministrationConnectionString"}},
            {typeof(ApplyIntegrationDatabaseChanges).Name, new[] {"InprotechIntegration", "IntegrationAdministrationConnectionString"}}
        };

        public FailedDatabaseScript(IProcessRunner processRunner, IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException(nameof(fileSystem));
            if (processRunner == null) throw new ArgumentNullException(nameof(processRunner));

            _fileSystem = fileSystem;
            _processRunner = processRunner;
        }

        public FailedDatabaseScript(IProcessRunner processRunner) : this(processRunner, new FileSystem())
        {
        }

        static string MessageHeader => @"/*
------------------------------------------------------------------------------------------------------------
--- The following script failed to be executed.
--- You may attempt to correct the script and run it manually, after which please run the setup again and resume.
--- If you are unable to proceed, please contact Inprotech Support.
------------------------------------------------------------------------------------------------------------
*/ ";

        static string MessageFooter => @"/*
        
------------------------------------------------------------------------------------------------------------
--- If the attempt to correct this script has failed, you may consider indicating to the Inprotech.Setup ---
--- so that it will not run this script when you resume setup.  If you are using this step to proceed,   ---
--- you will need to ensure the cause of initial failure is attended to after the set up completes.      ---
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------- UNCOMMENT THE BELOW SECTION TO PREVENT INPROTECH SETUP FROM RUNNING THIS SCRIPT ON RESUME  ---------
------------------------------------------------------------------------------------------------------------

if not exists (select * from SchemaVersions where ScriptName = '{0}') 
begin 
    insert SchemaVersions (ScriptName, Applied) 
    values ('{0}', getdate()) 
end 
go 
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
*/";

        public string Description => "Recover failed database script";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var failedActionForRecovery = (string) context["failedActionName"];
            if (!_supportedActions.ContainsKey(failedActionForRecovery))
            {
                throw new MissingFieldException("supportedAction");
            }

            var action = _supportedActions[failedActionForRecovery];
            var connectionString = (string) context[action[1]];

            var r = _processRunner.Run("Content\\Database\\InprotechKaizen.Database.exe",
                                       $"-m {action[0]} -c \"{CommandLineUtility.EncodeArgument(connectionString)}\" -s");

            if (r.ExitCode != 0 || !string.IsNullOrWhiteSpace(r.Error))
            {
                throw new SetupFailedException(r.Error);
            }

            var rawScript = r.Output;
            var scriptName = ExtractScriptName(rawScript);

            var message = MessageHeader + DbUsingStatement(connectionString) + rawScript;

            if (!string.IsNullOrWhiteSpace(scriptName))
            {
                message += Environment.NewLine + Environment.NewLine + string.Format(MessageFooter, scriptName);
            }

            _processRunner.Open(_fileSystem.WriteTemperoryFile(message, ".sql"));
        }

        static string ExtractScriptName(string rawScript)
        {
            if (string.IsNullOrWhiteSpace(rawScript)) return null;

            var regex = new Regex("-- SCRIPT NAME: (?<scriptname>[^\r\n]*)", RegexOptions.Compiled);
            var match = regex.Match(rawScript);

            return match.Success
                ? match.Groups["scriptname"].Value.Replace("-- SCRIPT NAME: ", string.Empty)
                : null;
        }

        static string DbUsingStatement(string connectionString)
        {
            var crlf = Environment.NewLine;
            var connectionBuilder = new SqlConnectionStringBuilder(connectionString);

            return $"{crlf}{crlf}USE [{connectionBuilder.InitialCatalog}] {crlf}GO{crlf}{crlf}";
        }
    }
}