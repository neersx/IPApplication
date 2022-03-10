using System.Threading.Tasks;
using Inprotech.Integration.CaseSource;

namespace Inprotech.Integration
{
    public interface ISourceImageDownloadHandler
    {
        Task Download(EligibleCase eligibleCase, string cpaXmlPath, string imagePath);
    }
}
