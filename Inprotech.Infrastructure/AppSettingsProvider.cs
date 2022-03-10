using System.Configuration;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure
{
    public class AppSettingsProvider : IAppSettingsProvider
    {
        public string this[string index] => ConfigurationManager.AppSettings[index];
    }
}
