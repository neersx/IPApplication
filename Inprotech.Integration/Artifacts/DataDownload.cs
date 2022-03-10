using System;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model;
using Newtonsoft.Json;

namespace Inprotech.Integration.Artifacts
{
    public class DataDownload
    {
        public int ScheduleId { get; set; }

        public DataSourceType DataSourceType { get; set; }

        public string Name { get; set; }

        public Guid Id { get; set; }

        public EligibleCase Case { get; set; }

        public DownloadType DownloadType { get; set; }

        public string AdditionalDetails { get; set; }

        public int? Chunk { get; set; }
    }

    public static class DataDownloadExtensions
    {
        public static T GetExtendedDetails<T>(this DataDownload dataDownload) where T : class
        {
            if (string.IsNullOrWhiteSpace(dataDownload.AdditionalDetails))
                return default(T);

            return JsonConvert.DeserializeObject<T>(dataDownload.AdditionalDetails);
        }

        public static DataDownload WithExtendedDetails<T>(this DataDownload dataDownload, T details)
        {
            dataDownload.AdditionalDetails = JsonConvert.SerializeObject(details, Formatting.None);
            return dataDownload;
        }

        public static bool IsTrademarkDataValidation(this DataDownload dataDownload)
        {
            return dataDownload.Case.PropertyType == KnownPropertyTypes.TradeMark;
        }

        public static bool IsPatentsDataValidation(this DataDownload dataDownload)
        {
            return dataDownload.Case.PropertyType != KnownPropertyTypes.TradeMark;
        }
    }
}
