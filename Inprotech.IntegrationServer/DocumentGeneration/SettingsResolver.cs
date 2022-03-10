using System;
using Inprotech.Infrastructure;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public interface ISettingsResolver
    {
        DocumentGenerationSettings Resolve();
    }

    public class SettingsResolver : ISettingsResolver
    {
        readonly Func<string, IGroupedConfig> _settingsFunc;
        
        DocumentGenerationSettings _settings;

        public SettingsResolver(Func<string, IGroupedConfig> settingsFunc)
        {
            _settingsFunc = settingsFunc;
        }

        public DocumentGenerationSettings Resolve()
        {
            if (_settings == null)
            {
                var settingValues = _settingsFunc("DocGen");

                var e1 = settingValues.GetValueOrDefault<string>("Email.EmbedImagesUsing") ?? EmbedImagesUsing.ContentId.ToString();

                _settings = new DocumentGenerationSettings();

                if (Enum.TryParse<EmbedImagesUsing>(e1, true, out var e2))
                {
                    _settings.EmbedImagesUsing = e2;
                }
            }

            return _settings;
        }
    }

    public class DocumentGenerationSettings
    {
        public EmbedImagesUsing EmbedImagesUsing { get; set; } = EmbedImagesUsing.ContentId;
    }

    public enum EmbedImagesUsing
    {
        ContentId,
        DataStream
    }
}
