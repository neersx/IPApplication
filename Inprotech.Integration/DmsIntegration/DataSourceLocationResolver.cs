using System;
using Inprotech.Infrastructure;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.DmsIntegration
{
    public interface IResolveDmsLocationForDataSourceType
    {
        string ResolveDestinationPath(Document document);
    }

    public class DataSourceLocationResolver : IResolveDmsLocationForDataSourceType
    {
        readonly IDmsIntegrationSettings _settings;
        readonly IFileHelpers _fileHelpers;
        readonly IFormatDmsFilenames _formatter;

        public DataSourceLocationResolver(IDmsIntegrationSettings settings, IFileHelpers fileHelpers, IFormatDmsFilenames formatter)
        {
            if (settings == null) throw new ArgumentNullException("settings");
            if (fileHelpers == null) throw new ArgumentNullException("fileHelpers");
            if (formatter == null) throw new ArgumentNullException("formatter");

            _settings = settings;
            _fileHelpers = fileHelpers;
            _formatter = formatter;
        }

        string ResolveLocation(DataSourceType dataSourceType)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    return _settings.PrivatePairLocation;
                case DataSourceType.UsptoTsdr:
                    return _settings.TsdrLocation;
                default:
                    throw new InvalidOperationException("Unknown dataSourceType");
            }
        }

        public string ResolveDestinationPath(Document document)
        {
            return _fileHelpers.PathCombine(ResolveLocation(document.Source), _formatter.Format(document));
        }
    }
}
