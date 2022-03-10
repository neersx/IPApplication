using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Integration.ReportingServices;

namespace Inprotech.Integration.Reports
{
    public interface IReportClientProvider
    {
        Task<HttpClient> GetClient();
    }

    public class ReportClientProvider : IReportClientProvider
    {
        readonly IReportingServicesSettingsResolver _reportingServicesSettingsResolver;

        public ReportClientProvider(IReportingServicesSettingsResolver reportingServicesSettingsResolver)
        {
            _reportingServicesSettingsResolver = reportingServicesSettingsResolver;
        }

        public async Task<HttpClient> GetClient()
        {
            var setting = await _reportingServicesSettingsResolver.Resolve();
            
            return new HttpClient(
                                  new HttpClientHandler
                                  {
                                      Credentials = setting.Security.IsEmpty()
                                          ? CredentialCache.DefaultNetworkCredentials
                                          : new NetworkCredential(
                                                                  setting.Security.Username,
                                                                  setting.Security.Password,
                                                                  setting.Security.Domain)
                                  })
            {
                Timeout = TimeSpan.FromMinutes(setting.Timeout),
                MaxResponseContentBufferSize = setting.MessageSize * 1048576
            };
        }
    }
}