using System;
using System.Globalization;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Meta
    {
        [JsonProperty("service_id")]
        public string ServiceId { get; set; }

        [JsonProperty("service_type")]
        public string ServiceType { get; set; }

        [JsonProperty("event_date")]
        public string EventDate { get; set; }

        [JsonProperty("event_timestamp")]
        public string EventTimeStamp { get; set; }

        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }

        [JsonProperty("transaction_id")]
        public string TransactionId { get; set; }

        [JsonIgnore]
        public DateTime EventDateParsed => this.ParseEventTimestamp();
    }

    public static class MessageEventTimeExtensions
    {
        static readonly string[] SupportedFormats = { "yyyy-MM-dd HH:mm:ss:ffffff", "yyyy-MM-dd HH:mm:ss.ffffff", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd" };

        public static DateTime ParseEventTimestamp(this Meta meta)
        {
            var input = new[] { meta.EventTimeStamp, meta.EventDate }
                .Where(dt => !string.IsNullOrWhiteSpace(dt))
                .ToArray();

            if (TryParseMessageEventTimeStamp(input, out DateTime result))
                return result;

            throw new NotSupportedException("DateTime is not provided in a supported format.");
        }

        public static bool TryParseMessageEventTimeStamp(this string dateTimeString, out DateTime firstSuccessfulParse)
        {
            return new[] { dateTimeString }.TryParseMessageEventTimeStamp(out firstSuccessfulParse);
        }

        static bool TryParseMessageEventTimeStamp(this string[] dateTimeStrings, out DateTime firstSuccessfulParse)
        {
            var parsed = (from dateTime in dateTimeStrings.Where(dt => !string.IsNullOrWhiteSpace(dt))
                          from format in SupportedFormats
                          let parsedOrNull = ParseDateTimeOrNull(dateTime, format)
                          where parsedOrNull != null
                          select parsedOrNull).FirstOrDefault();

            if (parsed == null)
            {
                firstSuccessfulParse = DateTime.MinValue;
                return false;
            }

            firstSuccessfulParse = (DateTime)parsed;
            return true;
        }

        public static string SetFileStoreMessageEventTimeStamp(this DateTime fileStoreDateTime)
        {
            return fileStoreDateTime.ToString(SupportedFormats.First());
        }

        static DateTime? ParseDateTimeOrNull(string dateTime, string format)
        {
            return DateTime.TryParseExact(dateTime, format, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dt)
                ? (DateTime?)dt
                : null;
        }
    }
}