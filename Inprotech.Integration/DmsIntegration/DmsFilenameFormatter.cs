using System;
using System.IO;
using Inprotech.Infrastructure.IO;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.DmsIntegration
{
    public interface IFormatDmsFilenames
    {
        string Format(Document document);
    }

    public class DmsFilenameFormatter : IFormatDmsFilenames
    {
        readonly IDmsIntegrationSettings _settings;
        readonly Func<DateTime> _now;

        public DmsFilenameFormatter(IDmsIntegrationSettings settings, Func<DateTime> now)
        {
            if (settings == null) throw new ArgumentNullException("settings");
            if (now == null) throw new ArgumentNullException("now");

            _settings = settings;
            _now = now;
        }

        public string Format(Document document)
        {
            var filenameFormat = GetFormatForSource(document.Source);

            var replacedFilenameFormat = filenameFormat
                .Replace("{AN", "{0")
                .Replace("{RN", "{1")
                .Replace("{PN", "{2")
                .Replace("{MDT", "{3")
                .Replace("{CAT", "{4")
                .Replace("{ID", "{5")
                .Replace("{DESC", "{6")
                .Replace("{CDT", "{7");

            try
            {
                var formatted = StorageHelpers.EnsureValid(
                                                           string.Format(replacedFilenameFormat, document.ApplicationNumber,
                                                                         document.RegistrationNumber, document.PublicationNumber, document.MailRoomDate, document.DocumentCategory,
                                                                         document.DocumentObjectId, document.DocumentDescription, _now())).Trim();

                if (StringComparer.InvariantCultureIgnoreCase.Compare(document.FileExtension(), Path.GetExtension(formatted)) != 0)
                {
                    formatted = Path.ChangeExtension(formatted, document.FileExtension());
                }

                return formatted;
            }
            catch (Exception e)
            {
                throw new FilenameFormatException(filenameFormat, e);
            }
        }

        string GetFormatForSource(DataSourceType source)
        {
            switch (source)
            {
                case DataSourceType.UsptoPrivatePair:
                    return _settings.PrivatePairFilename;
                case DataSourceType.UsptoTsdr:
                    return _settings.TsdrFilename;
                default:
                    throw new InvalidOperationException("Unknown data source");
            }
        }
    }
}