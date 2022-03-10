using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    internal class InitRecovery : ISetupAction
    {
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly IValidator _validator;

        public InitRecovery(Func<string, ISetupSettingsManager> settingsManager,
                            IValidator validator,
                            Func<string, IIisAppInfoManager> iisAppInfoManager)
        {
            _settingsManagerFunc = settingsManager;
            _validator = validator;
            _iisAppInfoManager = iisAppInfoManager;
        }

        public bool ContinueOnException => false;

        public string Description => "Preparing";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;

            _validator.ValidateSettingsFileExists(instancePath);
            _validator.ValidateRecoveryFeature(instancePath);

            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);
            var settings = settingsManager.Read(instancePath);
            settings.RunMode = SetupRunMode.Recovery;
            settings.Status = SetupStatus.Begin;

            if (ctx.DatabaseUsername != null)
                settings.DatabaseUsername = ctx.DatabaseUsername;
            if (ctx.DatabasePassword != null)
                settings.DatabasePassword = ctx.DatabasePassword;
            
            var iisAppInfo = _iisAppInfoManager(ctx.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);
            ctx.PairedIisApp = iisAppInfo;
            ctx.SetupSettings = settings;
        }
    }
}