using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Actions
{
    public class ApplyInprotechDatabaseChanges : ISetupAction
    {
        readonly IProcessRunner _processRunner;

        public ApplyInprotechDatabaseChanges(IProcessRunner processRunner)
        {
            if (processRunner == null) throw new ArgumentNullException(nameof(processRunner));
            _processRunner = processRunner;
        }

        public bool ContinueOnException => false;

        public string Description => "Apply Inprotech database changes";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechAdministrationConnectionString = (string)context["InprotechAdministrationConnectionString"];

            var r = _processRunner.Run("Content\\Database\\InprotechKaizen.Database.exe",
                                       $"-m Inprotech -c \"{CommandLineUtility.EncodeArgument(inprotechAdministrationConnectionString)}\"");

            if (!string.IsNullOrWhiteSpace(r.Output))
                eventStream.PublishInformation(r.Output);

            if (r.ExitCode != 0 || !string.IsNullOrWhiteSpace(r.Error))
                throw new SetupFailedException(r.Error);            
        }
    }
}
