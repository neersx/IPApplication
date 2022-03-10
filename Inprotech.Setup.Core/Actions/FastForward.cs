using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class FastForward : ISetupAction
    {
        public string Description => "Fastfoward to last successful action";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var workflow = ctx.Workflow;

            var lastStatus = ctx.SetupSettings.Status;
            while (workflow.Peek() != null)
            {
                if (workflow.Peek() is UpdateStatus)
                {
                    if (((UpdateStatus) workflow.Peek()).Status == lastStatus)
                    {
                        workflow.Next();
                        break;
                    }
                }

                workflow.Next();
            }
        }
    }
}