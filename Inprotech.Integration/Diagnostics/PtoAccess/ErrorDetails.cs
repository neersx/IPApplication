using System;
using System.Linq;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class ErrorDetail
    {
        string _rawError;

        [ExcelHeader("Activity")]
        public string Activity { get; set; }

        [ExcelHeader("Message")]
        public string Message { get; set; }

        [ExcelHeader("Last Modified", "d-mmm-yyyy h:mm")]
        public DateTime Date { get; set; }

        [ExcelHeader("Full Log")]
        public dynamic Error { get; set; }

        [ExcelHeader("Source", Converter = typeof(EnumToStringConverter))]
        public DataSourceType DataSource { get; set; }

        [JsonIgnore]
        public string RawError
        {
            get { return _rawError; }
            set
            {
                _rawError = value;
                Populate();
            }
        }

        protected virtual void Populate()
        {
            if (string.IsNullOrWhiteSpace(RawError) || RawError.AsJArray().Count == 0)
            {
                Activity = null;
                Error = null;
                return;
            }

            Error = RawError.AsJArray();

            var firstError = Error[0];

            Message = (string) firstError["message"];

            var type = (string) firstError["activityType"];
            if (type != null)
            {
                Activity = type.Split(',').FirstOrDefault() ?? string.Empty;
            }
        }
    }

    public class ScheduleInitialisationErrorDetails : ErrorDetail
    {
        [ExcelHeader("ScheduleName")]
        public string ScheduleName { get; set; }

        [ExcelHeader("For")]
        public string CorrelationId { get; set; }

        [JsonIgnore]
        public string AdditionalInfoPath { get; set; }

        [ExcelHeader("Type", Converter = typeof(EnumToStringConverter))]
        [JsonConverter(typeof (StringEnumConverter))]
        public ScheduleType ScheduleType { get; set; }

        [ExcelHeader("Schedule Identifier")]
        public int ScheduleId { get; set; }

        [ExcelHeader("Execution Identifier")]
        public Guid ScheduleExecutionId { get; set; }

        protected override void Populate()
        {
            if (string.IsNullOrWhiteSpace(RawError))
            {
                Activity = null;
                AdditionalInfoPath = null;
                Error = null;
                return;
            }

            Error = RawError.AsJArray();

            var firstError = Error[0];

            Message = (string) firstError["message"];

            var type = (string) firstError["activityType"];
            if (type != null)
            {
                Activity = type.Split(',').FirstOrDefault() ?? string.Empty;
            }

            var data = firstError["data"];
            if (data != null)
            {
                AdditionalInfoPath = (string) data["additionalInfo"];
            }
        }
    }

    public class CaseLevelErrorDetail : ErrorDetail
    {
        [ExcelHeader("Id")]
        public int Id { get; set; }

        [ExcelHeader("Application")]
        public string ApplicationNumber { get; set; }

        [ExcelHeader("Publication")]
        public string PublicationNumber { get; set; }

        [ExcelHeader("Registration")]
        public string RegistrationNumber { get; set; }

        [ExcelHeader("Case In Inprotech")]
        public int? IdentifiedInprotechCaseId { get; set; }
    }

    public class DocumentLevelErrorDetail : ErrorDetail
    {
        [ExcelHeader("Id")]
        public int Id { get; set; }

        [ExcelHeader("Application")]
        public string ApplicationNumber { get; set; }

        [ExcelHeader("Publication")]
        public string PublicationNumber { get; set; }

        [ExcelHeader("Registration")]
        public string RegistrationNumber { get; set; }
    }

    public static class ErrorDetailsExtension
    {
        public static JArray AsJArray(this string jsonString)
        {
            var js = jsonString.StartsWith("[") ? jsonString : "[" + jsonString + "]";
            return JArray.Parse(js);
        }
    }
}