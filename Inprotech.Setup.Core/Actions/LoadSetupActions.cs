using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class LoadSetupActions : ISetupAction
    {
        readonly IFileSystem _fileSystem;
        readonly ISetupActionsAssemblyLoader _setupActionsAssemblyLoader;

        public LoadSetupActions(
            ISetupActionsAssemblyLoader setupActionsAssemblyLoader,
            IFileSystem fileSystem)
        {
            _setupActionsAssemblyLoader = setupActionsAssemblyLoader;
            _fileSystem = fileSystem;
        }

        public Func<ISetupActionBuilder, IEnumerable<IEnumerable<ISetupAction>>> Build { get; internal set; }

        public string Description => "Load Setup Actions";

        public bool ContinueOnException => false;

        internal bool IgnoreNotFound { get; set; }

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;
            var dll = Path.Combine(instancePath, Constants.SetupActionsFileName);
            if (!_fileSystem.FileExists(dll))
            {
                if (IgnoreNotFound)
                    return;

                throw new Exception(dll + " not found");
            }

            var builder = Load(instancePath);
            var actions = Build(builder).SelectMany(_ => _);

            ctx.Workflow.Prepend(actions);
        }

        ISetupActionBuilder Load(string instanceRoot)
        {
            var assembly = _setupActionsAssemblyLoader.Load(instanceRoot);

            return assembly.GetExportedTypes()
                .Where(t => typeof (ISetupActionBuilder).IsAssignableFrom(t))
                .Select(type => (ISetupActionBuilder) Activator.CreateInstance(type))
                .Single();
        }
    }
}