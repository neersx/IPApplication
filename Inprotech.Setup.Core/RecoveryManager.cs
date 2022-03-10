using Autofac;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Actions;

namespace Inprotech.Setup.Core
{
    public interface IRecoveryManager
    {
        bool CanRecover(string instancePath, string failedActionName);
    }
    class RecoveryManager : IRecoveryManager
    {
        readonly IComponentContext _container;

        public RecoveryManager(IComponentContext container)
        {
            _container = container;
        }

        public bool CanRecover(string instancePath, string failedActionName)
        {
            var recoveryActionsLoader = _container.Resolve<LoadSetupActions>();
            recoveryActionsLoader.IgnoreNotFound = true;
            recoveryActionsLoader.Build = _ => new[] { ((ISetupActionBuilder3)_).BuildRecoveryActions(failedActionName) };

            return HasWorkflow(recoveryActionsLoader, new SetupContext
            {
                Workflow = _container.Resolve<SetupWorkflow>(),
                InstancePath = instancePath
            });
        }

        bool HasWorkflow(LoadSetupActions action, SetupContext context)
        {
            action.Run(context, new NullEventStream());

            return context.Workflow.Peek() != null;
        }
    }
}