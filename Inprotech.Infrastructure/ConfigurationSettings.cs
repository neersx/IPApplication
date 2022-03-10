using System.Configuration;
namespace Inprotech.Infrastructure
{
    public class ConfigurationSettings : IConfigurationSettings
    {
        public string this[string index] => ConfigurationManager.AppSettings[index];
    }
}