using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public interface IApiKeyValidator
    {
        Task<bool> ValidateApiToken(string apiKey, string applicationName, bool isOneTimeToken);
    }
}
