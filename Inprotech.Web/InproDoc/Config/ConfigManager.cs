using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;

namespace Inprotech.Web.InproDoc.Config
{
    public interface IPassThruManager
    {
        IEnumerable<EntryPoint> GetEntryPoints();
    }

    public class ConfigManager : IPassThruManager
    {
        const string ConfigFile = "Inprotech.Web.InproDoc.config";
        System.Configuration.Configuration _config;

        public IEnumerable<EntryPoint> GetEntryPoints()
        {
            OpenConfiguration();

            var docGenSection = _config.GetSection("docGen") as DocGenSection;

            if (docGenSection == null || docGenSection.EntryPoints == null) yield break;

            foreach (EntryPointElement entryPointElement in docGenSection.EntryPoints)
            {
                yield return new EntryPoint
                {
                    Name = entryPointElement.Name,
                    Description = entryPointElement.Description,
                    AskLabel = entryPointElement.AskLabel,
                    EntryPointValueType = entryPointElement.EntryPointValueType,
                    Length = entryPointElement.Length,
                    RequireValidation = entryPointElement.RequireValidation,
                    ItemValidation = entryPointElement.ItemValidation,
                    EvalItemOnRegister = entryPointElement.EvalItemOnRegister
                };
            }
        }

        void OpenConfiguration()
        {
            if (!File.Exists(ConfigFile))
            {
                throw new ApplicationException($"'{ConfigFile}' file not found.");
            }

            var configFileMap = new ExeConfigurationFileMap {ExeConfigFilename = ConfigFile};

            _config = ConfigurationManager.OpenMappedExeConfiguration(configFileMap, ConfigurationUserLevel.None);
        }
    }
}