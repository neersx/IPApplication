using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Reflection;

namespace Inprotech.Setup.IWSConfig
{
    internal enum ExitCode
    {
        ArgumentsIncorrect = -1,
        UnknownError = -9
    }

    internal enum ResolvableConfiguration
    {
        None,
        Dms,
        Reports,
        Attachment
    }

    internal class Program
    {
        const string DmsServiceConfigurationNameSpace = "Inprotech.Modules.DMS.WorkSite.ServiceConfiguration";
        const string AttachmentConfigurationNameSpace = "Inprotech.Modules.ContactActivity.Attachment.ServiceConfiguration";
        const string ReportsConfigurationNameSpace = "Inprotech.Modules.Reports.ServiceConfiguration";

        static readonly Dictionary<ResolvableConfiguration, Func<string, string>> ConfigResolverMap
            = new Dictionary<ResolvableConfiguration, Func<string, string>>
            {
                {ResolvableConfiguration.Dms, LoadDmsConfig},
                {ResolvableConfiguration.Reports, LoadReportsConfig},
                {ResolvableConfiguration.Attachment, LoadAttachmentConfig}
            };

        static void Main(string[] args)
        {
            if (!TryParse(args, out var result))
            {
                Environment.Exit((int) ExitCode.ArgumentsIncorrect);
                return;
            }

            try
            {
                AppDomain.CurrentDomain.AssemblyResolve += (s, e) =>
                {
                    var assemblyRequested = e.Name;

                    return Assembly.Load(File.ReadAllBytes(Path.Combine(result.Location, assemblyRequested + ".dll")));
                };

                ConfigResolverMap[result.Config](result.Location);

                Console.WriteLine(Encrypt(result.EncryptionKey, ConfigResolverMap[result.Config](result.Location)));
            }
            catch (Exception)
            {
                Environment.Exit((int) ExitCode.UnknownError);
            }
        }

        static bool TryParse(string[] args, out ResolvedArgs result)
        {
            if (args.Length != 3 ||
                string.IsNullOrWhiteSpace(args[0]) ||
                !Enum.TryParse(args[1], out ResolvableConfiguration config) ||
                string.IsNullOrWhiteSpace(args[2]) ||
                !Directory.Exists(args[2]))
            {
                result = new ResolvedArgs();
                return false;
            }

            result = new ResolvedArgs
            {
                Config = config,
                EncryptionKey = args[0],
                Location = args[2]
            };

            return true;
        }

        static string Encrypt(string encryptionKey, string data)
        {
            return new CryptoService().Encrypt(encryptionKey, data);
        }

        static string LoadDmsConfig(string location)
        {
            var configFileName = Path.Combine(location, "Inprotech.Modules.DMS.WorkSite.config");

            Assembly.Load(DmsServiceConfigurationNameSpace);

            var configFileMap = new ExeConfigurationFileMap {ExeConfigFilename = configFileName};
            var config = ConfigurationManager.OpenMappedExeConfiguration(configFileMap, ConfigurationUserLevel.None);

            return config.GetSection("worksite").SectionInformation.GetRawXml();
        }

        static string LoadReportsConfig(string location)
        {
            var configFileName = Path.Combine(location, "Inprotech.Modules.Reports.config");

            Assembly.Load(ReportsConfigurationNameSpace);

            var configFileMap = new ExeConfigurationFileMap {ExeConfigFilename = configFileName};
            var config = ConfigurationManager.OpenMappedExeConfiguration(configFileMap, ConfigurationUserLevel.None);

            return config.GetSection("reports").SectionInformation.GetRawXml();
        }

        static string LoadAttachmentConfig(string location)
        {
            var configFileName = Path.Combine(location, "Inprotech.Modules.ContactActivity.Attachment.config");

            Assembly.Load(AttachmentConfigurationNameSpace);

            var configFileMap = new ExeConfigurationFileMap {ExeConfigFilename = configFileName};
            var config = ConfigurationManager.OpenMappedExeConfiguration(configFileMap, ConfigurationUserLevel.None);

            return config.GetSection("attachment").SectionInformation.GetRawXml();
        }

        public class ResolvedArgs
        {
            public string EncryptionKey { get; set; }
            public ResolvableConfiguration Config { get; set; }
            public string Location { get; set; }
        }
    }
}