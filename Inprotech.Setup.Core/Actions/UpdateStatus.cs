using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class UpdateStatus : ISetupAction
    {
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;

        public UpdateStatus(Func<string, ISetupSettingsManager> settingsManagerFunc)
        {
            _settingsManagerFunc = settingsManagerFunc;
        }

        public SetupStatus Status { get; internal set; }

        public string Description => "Update Status";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;

            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);
            var settings = settingsManager.Read(instancePath);

            eventStream.PublishInformation("Set status to " + Status);

            settings.Status = Status;
            settingsManager.Write(instancePath, settings);
        }
    }
}