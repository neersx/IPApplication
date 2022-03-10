using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Settings;
using Inprotech.Integration;
using Inprotech.Integration.Settings;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public interface ICommonSettings
    {
        int GetChunkSize(DataSourceType sourceType);
    }

    public class CommonSettings : ICommonSettings
    {
        readonly Dictionary<DataSourceType, IGroupedSettings> _settings;

        public CommonSettings(GroupedConfigSettings.Factory settings)
        {
            _settings = Enum.GetValues(typeof(DataSourceType))
                            .Cast<DataSourceType>()
                            .ToDictionary(k => k, v => (IGroupedSettings)settings(v.ToString()));

        }

        public int GetChunkSize(DataSourceType sourceType)
        {
            return _settings[sourceType].GetValueOrDefault<int?>("Request.ChunkSize") ?? 1000;
        }
    }
}
