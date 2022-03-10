using System.Collections.Generic;

namespace Inprotech.Setup.Contracts.Immutable
{
    public static class IisAppFeatures
    {
        public static readonly IEnumerable<string> All = new [] { AppsBridgeHttpModule };
        public const string AppsBridgeHttpModule = "AppsBridgeHttpModule";
    }
}