using System;
using DbUp.Builder;

namespace InprotechKaizen.Database
{
    public static class Extensions
    {
        public static UpgradeEngineBuilder ConfigureEx(
            this UpgradeEngineBuilder builder,
            Action<UpgradeConfiguration> callback)
        {
            builder.Configure(callback);
            return builder;
        }
    }
}