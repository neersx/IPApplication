using System;
using Inprotech.Integration;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public static class DataSourceHelper
    {
        public const string PrivatePairJobType = "SendPrivatePairDocumentsToDms";
        public const string TsdrJobType = "SendTsdrDocumentsToDms";

        public static string GetJobType(DataSourceType dataSource)
        {
            switch (dataSource)
            {
                case DataSourceType.UsptoPrivatePair:
                    return PrivatePairJobType;
                case DataSourceType.UsptoTsdr:
                    return TsdrJobType;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }
    }
}
