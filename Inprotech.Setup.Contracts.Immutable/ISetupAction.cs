using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Setup.Contracts.Immutable
{
    public interface ISetupAction
    {
        string Description { get; }

        bool ContinueOnException { get; }
        
        void Run(IDictionary<string, object> context, IEventStream eventStream);
    }

    public interface ISetupActionAsync : ISetupAction
    {
        Task RunAsync(IDictionary<string, object> context, IEventStream eventStream);
    }
}