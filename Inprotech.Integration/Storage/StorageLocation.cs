using System;
using Inprotech.Contracts;

namespace Inprotech.Integration.Storage
{
    public class StorageLocation : IStorageLocation
    {
        readonly IAppSettingsProvider _appSettingsProvider;

        public StorageLocation(IAppSettingsProvider appSettingsProvider)
        {
            if (appSettingsProvider == null) throw new ArgumentNullException("appSettingsProvider");
            _appSettingsProvider = appSettingsProvider;
        }

        public string Resolve()
        {
            return _appSettingsProvider["StorageLocation"];
        }
    }
}
