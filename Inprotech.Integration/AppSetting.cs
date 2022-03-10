using System.Configuration;

namespace Inprotech.Integration
{
    public interface IAppSettings
    {
        string GraphApiUrl { get; }

        string GraphAuthUrl { get; }
    }

    public class AppSettings : IAppSettings
    {
        public string GraphApiUrl => ConfigurationManager.AppSettings["GraphApiUrl"];

        public string GraphAuthUrl => ConfigurationManager.AppSettings["GraphAuthUrl"];
    }
}
