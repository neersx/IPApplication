using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core
{
    public interface IWebAppConfigurationReader
    {
        IEnumerable<InstanceComponentConfiguration> Read(string path);
    }

    class WebAppConfigurationReader : IWebAppConfigurationReader
    {
        readonly ISetupActionsAssemblyLoader _setupAssemblyLoaderLoader;

        public WebAppConfigurationReader(ISetupActionsAssemblyLoader setupAssemblyLoaderLoader)
        {
            _setupAssemblyLoaderLoader = setupAssemblyLoaderLoader ?? throw new ArgumentNullException(nameof(setupAssemblyLoaderLoader));
        }

        public IEnumerable<InstanceComponentConfiguration> Read(string path)
        {
            var assebmly = _setupAssemblyLoaderLoader.Load(path);
            if (assebmly == null)
                return Enumerable.Empty<InstanceComponentConfiguration>();

            var type = assebmly.GetType("Inprotech.Setup.Actions.InstanceConfigurationReader");
            var reader = (IInstanceConfigurationReader)Activator.CreateInstance(type);

            var config = reader.Read(path);
            return new[]
            {
                new InstanceComponentConfiguration
                {
                    Name = "General",
                    Configuration = new Dictionary<string, string>
                    {
                        {"Instance Location", path}
                    },
                    AppSettings = new Dictionary<string, string>()
                }
            }.Concat(config);
        }
    }
}
