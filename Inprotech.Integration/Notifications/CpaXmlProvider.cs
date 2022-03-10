using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Notifications
{
    public interface ICpaXmlProvider
    {
        Task<string> For(int notificationId);
    }

    public class CpaXmlProvider : ICpaXmlProvider
    {
        readonly IIntegrationServerClient _integrationServerClient;

        public CpaXmlProvider(IIntegrationServerClient integrationServerClient)
        {
            _integrationServerClient = integrationServerClient;
        }

        public async Task<string> For(int notificationId)
        {
            return await _integrationServerClient
                .DownloadString("api/dataextract/storage/cpaxml?notificationId=" + notificationId);
        }
    }
}