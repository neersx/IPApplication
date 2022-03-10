using System.IO;
using Inprotech.Integration.Documents;

namespace Inprotech.Integration.DmsIntegration
{
    public interface IBuildXmlMetadata
    {
        Stream Build(int caseId, Document document);
    }
}
