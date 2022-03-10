
using System.Threading.Tasks;

namespace Inprotech.Integration.PostSourceUpdate
{
    public interface ISourceUpdatedHandler
    {
        Task Handle(int caseId, string rawCpaXml);
    }
}
