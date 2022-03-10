using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Actions.Utilities
{
    public class ConfigurationUtility
    {
        public static void UpdateConnectionString(
            string configPath,
            string key,
            string connectionString)
        {
            var config = ReadConfigFile(configPath);
            config.ConnectionStrings.ConnectionStrings[key].ConnectionString = connectionString;
            ConfigurationManager.RefreshSection("connectionStrings");
            config.Save();
        }

        public static void EncryptConnectionString(string configPath)
        {
            var config = ReadConfigFile(configPath);
            var connectionStringSection = config.GetSection("connectionStrings");
            if (!connectionStringSection.SectionInformation.IsProtected)
            {
                connectionStringSection.SectionInformation.ProtectSection("DataProtectionConfigurationProvider");
                ConfigurationManager.RefreshSection("connectionStrings");
                config.Save(ConfigurationSaveMode.Full);
            }
        }

        public static string ReadConnectionString(string configPath, string name)
        {
            var config = ReadConfigFile(configPath);
            return config.ConnectionStrings.ConnectionStrings[name].ConnectionString;
        }

        public static void UpdateSmtpSettings(
            XmlDocument document,
            string host)
        {
            var smtpNode = document.SelectSingleNode($"//configuration/system.net/mailSettings/smtp");
            if (smtpNode == null)
                throw new SetupFailedException($"smtp node could not be found.");

            if (smtpNode.Attributes?["deliveryMethod"] == null || smtpNode.Attributes["deliveryMethod"].Value?.Equals("network", StringComparison.InvariantCultureIgnoreCase) == true)
            {
                var networkNode = smtpNode.SelectSingleNode("network");
                if (networkNode == null)
                    throw new SetupFailedException($"smtp/network node could not be found.");

                networkNode.SetAttribute(document, "host", host);
            }
        }

        public static void UpdateAppSettings(
            string configPath,
            IDictionary<string, string> values)
        {
            var config = ReadConfigFile(configPath);
            var settings = config.AppSettings.Settings;
            foreach (var pair in values)
            {
                var key = pair.Key;
                var value = pair.Value;

                if (settings.AllKeys.Contains(key))
                    settings[key].Value = value;
            }
            config.Save();
        }

        public static void AddUpdateAppSettings(
            string configPath,
            IDictionary<string, string> values)
        {
            var config = ReadConfigFile(configPath);
            var settings = config.AppSettings.Settings;
            foreach (var pair in values)
            {
                var key = pair.Key;
                var value = pair.Value;

                if (settings.AllKeys.Contains(key))
                    settings[key].Value = value;
                else
                    settings.Add(key, value);
            }
            config.Save();
        }

        public static void RemoveAppSettings(XmlDocument document, string[] keys)
        {
            foreach (var key in keys)
            {
                var node = document.SelectSingleNode($"//appSettings/add[@key='{key}']");

                node?.ParentNode?.RemoveChild(node);
            }
        }

        public static IDictionary<string, string> ReadAppSettings(string configPath)
        {
            var config = ReadConfigFile(configPath);
            return ReadAppSettings(XElement.Parse(config.GetSection("appSettings").SectionInformation.GetRawXml()));
        }

        static IDictionary<string, string> ReadAppSettings(XElement root)
        {
            return (from add in root.Elements("add")
                    let key = add.Attribute("key")
                    where key != null
                    select new
                    {
                        Key = (string)key,
                        Value = (string)add.Attribute("value")
                    }).ToDictionary(a => a.Key, a => a.Value);
        }

        public static Configuration ReadConfigFile(string configPath)
        {
            var map = new ExeConfigurationFileMap
            {
                ExeConfigFilename = configPath
            };
            return ConfigurationManager.OpenMappedExeConfiguration(map, ConfigurationUserLevel.None);
        }

        public static CommandLineUtilityResult RegisterService(
            string path,
            string user,
            string password,
            string instance,
            bool isBuiltInServiceUser)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("A valid path is required.");
            if (string.IsNullOrWhiteSpace(user)) throw new ArgumentException("A valid user is required.");

            var r = CommandLineUtility.Run(path, "uninstall");
            if (r.ExitCode != 0)
                return r;

            var userArg = CommandLineUtility.EncodeArgument(user.ToCanonicalUserName());

            var args = isBuiltInServiceUser
                ? "install --networkservice"
                : $"install -username \"{userArg}\" -password:{password}";

            return CommandLineUtility.Run(path, $"{args} -instance:{instance}");
        }

        public static CommandLineUtilityResult UnRegisterService(string path, string instance)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("A valid path is required.");

            return CommandLineUtility.Run(path, $"uninstall -instance:{instance}");
        }
    }

    public static class XmlNodeExt
    {
        public static XmlNode SetAttribute(this XmlNode node, XmlDocument document, string name, string value)
        {
            var attr = node.SelectSingleNode($"@{name}");
            if (attr == null)
            {
                attr = document.CreateAttribute(name);
                node.Attributes.SetNamedItem(attr);
            }

            attr.Value = value;
            return node;
        }
    }
}