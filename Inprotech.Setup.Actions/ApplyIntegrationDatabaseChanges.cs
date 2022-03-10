using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Actions
{
    public class ApplyIntegrationDatabaseChanges : ISetupAction
    {
        readonly IProcessRunner _processRunner;

        public ApplyIntegrationDatabaseChanges(IProcessRunner processRunner)
        {
            if(processRunner == null) throw new ArgumentNullException(nameof(processRunner));
            _processRunner = processRunner;
        }

        public string Description => "Apply Inprotech Integration database changes";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var integrationAdministrationConnectionString = (string)context["IntegrationAdministrationConnectionString"];
            eventStream.PublishInformation("This may take several minutes.");

            var r = _processRunner.Run("Content\\Database\\InprotechKaizen.Database.exe",
                                       $"-m InprotechIntegration -c \"{CommandLineUtility.EncodeArgument(integrationAdministrationConnectionString)}\"");

            if (!string.IsNullOrWhiteSpace(r.Output))
                eventStream.PublishInformation(r.Output);

            if (r.ExitCode != 0 || !string.IsNullOrWhiteSpace(r.Error))
                throw new SetupFailedException(r.Error);                
        }
    }
}
