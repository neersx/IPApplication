using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    internal class InitRemove : ISetupAction
    {
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;
        readonly Func<string, ISetupSettingsManager> _settingsManager;
        readonly IValidator _validator;

        public InitRemove(Func<string, ISetupSettingsManager> settingsManager, IValidator validator, Func<string, IIisAppInfoManager> iisAppInfoManager)
        {
            _settingsManager = settingsManager;
            _validator = validator;
            _iisAppInfoManager = iisAppInfoManager;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;

            _validator.ValidateSettingsFileExists(instancePath);
            var s = _settingsManager(ctx.PrivateKey);
            var settings = s.Read(instancePath);

            settings.RunMode = SetupRunMode.Remove;
            settings.Status = SetupStatus.Begin;

            s.Write(instancePath, settings);

            ((SetupContext) context).PairedIisApp = _iisAppInfoManager(settings.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);
        }
    }
}