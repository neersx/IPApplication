using System;
using System.Threading.Tasks;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core
{
    public interface ISetupRunner
    {
        event Action<ISetupAction> OnBeforeAction;
        event Action<ISetupAction> OnSuccess;
        event Action<ISetupAction> OnFailed;
        Task<bool> Run(SetupWorkflow workflow, IEventStream eventStream);
    }

    class SetupRunner : ISetupRunner
    {
        public event Action<ISetupAction> OnBeforeAction;
        public event Action<ISetupAction> OnSuccess;
        public event Action<ISetupAction> OnFailed;

        public async Task<bool> Run(SetupWorkflow workflow, IEventStream eventStream)
        {
            ISetupAction action;

            var context = new SetupContext { Workflow = workflow };

            workflow.InitContext?.Invoke(context);

            while ((action = workflow.Next()) != null)
            {
                try
                {
                    OnBeforeAction?.Invoke(action);

                    var actionAsync = action as ISetupActionAsync;
                    if (actionAsync != null)
                    {
                        await actionAsync.RunAsync(context, eventStream);
                    }
                    else
                    {
                        action.Run(context, eventStream);
                    }
                    
                    OnSuccess?.Invoke(action);
                }
                catch (Exception ex)
                {
                    var e = ex;
                    var aex = ex as AggregateException;
                    if (aex != null)
                    {
                        e = aex.Flatten();
                    }

                    if (!action.ContinueOnException)
                    {
                        OnFailed?.Invoke(action);

                        eventStream.PublishError(e.ToString());
                        return false;
                    }

                    eventStream.PublishWarning(e.ToString());

                    OnSuccess?.Invoke(action);
                }
            }

            return true;
        }
    }
}