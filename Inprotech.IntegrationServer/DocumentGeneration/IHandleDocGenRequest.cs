using System;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public interface IHandleDocGenRequest : IContextualLogger
    {
        Task<DocGenProcessResult> Handle(DocGenRequest docGenRequest);
    }
}