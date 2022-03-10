using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Setup.Contracts.Immutable;
using Microsoft.Web.Administration;

namespace Inprotech.Setup.Core
{
    public interface IAvailableFeatures
    {
        IEnumerable<string> Resolve(XElement config, ManagedPipelineMode pipelineMode);
    }

    class AvailableFeatures : IAvailableFeatures
    {
        public IEnumerable<string> Resolve(XElement config, ManagedPipelineMode pipelineMode)
        {
            var isClassicMode = pipelineMode == ManagedPipelineMode.Classic;

            var systemNode = isClassicMode ? "system.web" : "system.webServer";
            var moduleNode = isClassicMode ? "httpModules" : "modules";
            var httpModules = HttpModules(config, systemNode, moduleNode);

            if (httpModules == null)
                yield break;

            var names = httpModules.Elements("add").Attributes("name").ToArray();
            foreach (var feature in IisAppFeatures.All)
            {
                if (names.Any(_ => string.Equals(_.Value, feature)))
                {
                    yield return feature;
                }
            }
        }

        static XElement HttpModules(XElement config, string systemNodeName, string moduleNodeName)
        {
            return WrappedInLocation(config, systemNodeName, moduleNodeName)
                   ?? NotWrappedInLocation(config, systemNodeName, moduleNodeName);
        }

        static XElement WrappedInLocation(XElement config, string systemNodeName, string moduleNodeName)
        {
            return (from loc in config.Elements("location")
                    where loc.Elements(systemNodeName).Any()
                    from web in loc.Elements(systemNodeName)
                    where web.Elements(moduleNodeName).Any()
                    select web.Element(moduleNodeName))
                .FirstOrDefault();
        }

        static XElement NotWrappedInLocation(XElement config, string systemNodeName, string moduleNodeName)
        {
            return (from web in config.Elements(systemNodeName)
                    where web.Elements(moduleNodeName).Any()
                    select web.Element(moduleNodeName))
                .FirstOrDefault();
        }
    }
}