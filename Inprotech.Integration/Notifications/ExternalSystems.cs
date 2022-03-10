using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model;

namespace Inprotech.Integration.Notifications
{
    public interface IExternalSystems
    {
        string[] DataSources();
    }

    public class ExternalSystems : IExternalSystems
    {
        static readonly Dictionary<DataSourceType, KnownExternalSystemIds> DataSourceToExternalSystemMap = new Dictionary
            <DataSourceType, KnownExternalSystemIds>
            {
                {DataSourceType.UsptoPrivatePair, KnownExternalSystemIds.UsptoPrivatePair},
                {DataSourceType.UsptoTsdr, KnownExternalSystemIds.UsptoTsdr},
                {DataSourceType.Epo, KnownExternalSystemIds.Epo},
                {DataSourceType.IpOneData, KnownExternalSystemIds.IPONE},
                {DataSourceType.File, KnownExternalSystemIds.File}
            };

        static readonly Dictionary<DataSourceType, string> DataSourceToDescriptionMap = new Dictionary
            <DataSourceType, string>
            {
                {DataSourceType.UsptoPrivatePair, "USPTO Private PAIR"},
                {DataSourceType.UsptoTsdr, "USPTO TSDR"},
                {DataSourceType.Epo, "European Patent Office"},
                {DataSourceType.IpOneData, "IP One Data"},
                {DataSourceType.File, "FILE"}
            };

        static readonly Dictionary<DataSourceType, string> DataSourceToSystemCodeMap = new Dictionary
            <DataSourceType, string>
            {
                {DataSourceType.UsptoPrivatePair, "USPTO.PrivatePAIR"},
                {DataSourceType.UsptoTsdr, "USPTO.TSDR"},
                {DataSourceType.Epo, "EPO"},
                {DataSourceType.IpOneData, "IPOneData"},
                {DataSourceType.File, "FILE"}
            };

        readonly IRepository _repository;

        public ExternalSystems(IRepository repository)
        {
            _repository = repository;
        }

        public string[] DataSources()
        {
            return _repository.Set<Case>()
                              .Select(c => c.Source)
                              .Distinct()
                              .ToArray()
                              .Select(SystemCode).ToArray();
        }

        public static int? Id(DataSourceType source)
        {
            if (DataSourceToExternalSystemMap.TryGetValue(source, out KnownExternalSystemIds knownExternalSystem))
            {
                return (int) knownExternalSystem;
            }

            return null;
        }

        public static string DisplayText(DataSourceType source)
        {
            if(DataSourceToDescriptionMap.TryGetValue(source, out string displayText))
            {
                return displayText;
            }

            return string.Empty;
        }

        public static int? Id(string source)
        {
            return Enum.TryParse(source, true, out DataSourceType dataSource) ? Id(dataSource) : null;
        }

        public static string SystemCode(DataSourceType source)
        {
            return DataSourceToSystemCodeMap.TryGetValue(source, out string systemCode) ? systemCode : null;
        }

        public static DataSourceType DataSource(string systemCode)
        {
            return DataSourceToSystemCodeMap.Single(_ => _.Value == systemCode).Key;
        }

        public static DataSourceType? DataSourceOrNull(string systemCode)
        {
            if (DataSourceToSystemCodeMap.ContainsValue(systemCode))
            {
                return DataSourceToSystemCodeMap.Single(_ => _.Value == systemCode).Key;
            }

            return null;
        }
    }

    public class DataSource
    {
        public string DisplayText { get; set; }
        public string Name { get; set; }
    }
}