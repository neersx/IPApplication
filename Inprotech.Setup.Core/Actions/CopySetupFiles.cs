using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class CopySetupFiles : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public CopySetupFiles(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public string Description => "Copy setup files";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;

            eventStream.PublishInformation("Copy files to " + instancePath);

            _fileSystem.CopyDirectory(Constants.ContentRoot, instancePath);
        }
    }
}