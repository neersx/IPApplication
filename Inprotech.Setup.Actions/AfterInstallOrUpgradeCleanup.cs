using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class AfterInstallOrUpgradeCleanup : ISetupAction
    {
        public string Description => "After Install Cleanup";
        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            DeleteInprotechBackupConfig(GetBackupWebConfigPath(context), eventStream);
        }

        void DeleteInprotechBackupConfig(string path, IEventStream eventStream)
        {
            var fileSystem = new FileSystem();

            if (!fileSystem.FileExists(path))
                return;

            fileSystem.DeleteFile(path);
            eventStream.PublishInformation("Inprotech web.config backup file is deleted");
        }

        string GetBackupWebConfigPath(IDictionary<string, object> context)
        {
            return Path.Combine((string)context["PhysicalPath"], Constants.InprotechBackup.Folder, Constants.InprotechBackup.WebConfig);
        }
    }
}
