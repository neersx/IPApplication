using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model.Components.Names;
using YamlDotNet.RepresentationModel;
using YamlDotNet.Serialization;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public interface ISettingYamlMapper
    {
        Task<StringBuilder> GetYamlStringForSiteConfig(IManageSettings.SiteDatabaseSettings config);
    }

    public class SettingYamlMapper : ISettingYamlMapper
    {
        readonly ISiteControlReader _siteControlReader;
        readonly IDisplayFormattedName _displayFormattedName;

        public SettingYamlMapper(ISiteControlReader siteControlReader, IDisplayFormattedName displayFormattedName)
        {
            _siteControlReader = siteControlReader;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<StringBuilder> GetYamlStringForSiteConfig(IManageSettings.SiteDatabaseSettings config)
        {
            var sr = new StringReader(string.Empty);
            var stream = new YamlStream();
            stream.Load(sr);
            var homeNameNo = _siteControlReader.Read<int>(SiteControls.HomeNameNo);
            var name = await _displayFormattedName.For(homeNameNo);
            var shortName = string.Join(string.Empty, name.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Select(_ => _.First()).Where(char.IsUpper).Select(_ => _.ToString().ToLower()));
            var node = new YamlMappingNode
            {
                {"id", $"inprotech-{shortName}"},
                {"name", $"Inprotech ({name})"},
                {"publisher", "CPA Global"},
                {"api_key", config.ClientId},
                {"api_secret", config.ClientSecret},
                {"redirect_url", GetCallbackUrlNode(config.CallbackUrls().ToList())},
                {"scope", "user"}
            };
            stream.Add(new YamlDocument(node));
            var serializer = new Serializer();
            var sb = new StringBuilder();
            using (var writer = new StringWriter(sb))
            {
                serializer.Serialize(writer, node);
            }

            return sb;
        }

        YamlNode GetCallbackUrlNode(List<string> callbackUrls)
        {
            if (callbackUrls.Count() > 1)
            {
                return new YamlSequenceNode(callbackUrls.Select(_ => new YamlScalarNode(_)));
            }

            return new YamlScalarNode(callbackUrls.First());
        }
    }

}