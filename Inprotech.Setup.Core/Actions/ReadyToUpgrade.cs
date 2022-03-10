using System;
using System.Collections.Generic;
using System.Threading;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class ReadyToUpgrade : ISetupAction
    {
        readonly IFileSystem _fileSystem;
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly IVersionManager _versionManager;

        public ReadyToUpgrade(IFileSystem fileSystem, Func<string, ISetupSettingsManager> settingsManagerFunc, IVersionManager versionManager)
        {
            _fileSystem = fileSystem;
            _settingsManagerFunc = settingsManagerFunc;
            _versionManager = versionManager;
        }

        public string Description => "Ready to Upgrade";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;

            Thread.Sleep(5000); // wait for all services shut down

            _fileSystem.DeleteAllExcept(ctx.InstancePath, Constants.SettingsFileName, Constants.BackupDirectory);

            if (ctx.NewInstancePath != null && !Helpers.ArePathsEqual(ctx.InstancePath, ctx.NewInstancePath))
            {
                var oldInstancePath = ctx.InstancePath;
                _fileSystem.CopyDirectory(oldInstancePath, ctx.NewInstancePath);
                try
                {
                    _fileSystem.DeleteDirectory(oldInstancePath);
                }
                catch (Exception ex)
                {
                    eventStream.PublishWarning("Unable to delete old instance folder. You might need to manually delete it.");
                    eventStream.PublishWarning(ex.ToString());
                }
                ctx.InstancePath = ctx.NewInstancePath;
            }

            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);
            var settings = settingsManager.Read(ctx.InstancePath);
            settings.Version = _versionManager.GetCurrentWebAppVersion();

            ctx.Version = settings.Version;
            settingsManager.Write(ctx.InstancePath, settings);
        }
    }
}