using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Integration.Notifications
{
    public class CaseNotificationResponse
    {
        readonly CaseNotificateType _type;

        public CaseNotificationResponse()
        {
        }

        public CaseNotificationResponse(CaseNotification notification, string title, object body = null)
        {
            if (notification == null) throw new ArgumentNullException(nameof(notification));

            Title = title;
            Body = body;
            NotificationId = notification.Id;
            DataSourceType = notification.Case.Source;
            AppNum = notification.Case.ApplicationNumber;
            RegNum = notification.Case.RegistrationNumber;
            PubNum = notification.Case.PublicationNumber;
            IsReviewed = notification.IsReviewed;
            Date = notification.UpdatedOn;
            CaseId = notification.Case.CorrelationId;

            _type = notification.Type;
        }

        public string Type
        {
            get
            {
                switch (_type)
                {
                    case CaseNotificateType.CaseUpdated:
                        return CaseId != null
                            ? "case-comparison"
                            : "new-case";

                    case CaseNotificateType.Rejected:
                        return "rejected";

                    case CaseNotificateType.Error:
                        return "error";
                }

                throw new NotSupportedException($"Notification type {_type} is not supported");
            }
        }

        public int NotificationId { get; set; }
        public int? CaseId { get; set; }
        public string DataSource => DataSourceType.ToString();
        public string AppNum { get; set; }
        public string RegNum { get; set; }
        public string PubNum { get; set; }
        public string CaseRef { get; set; }
        public string Title { get; set; }
        public object Body { get; set; }
        public bool IsReviewed { get; set; }
        public DateTime Date { get; set; }

        [JsonIgnore]
        public DataSourceType DataSourceType { get; set; }
    }

    public static class CaseNotificationResponseExt
    {
        public static IEnumerable<CaseNotificationResponse> WithMatchingDataSources(
            this IEnumerable<CaseNotificationResponse> responses, IEnumerable<DataSourceType> dataSourceTypes)
        {
            if (responses == null) throw new ArgumentNullException(nameof(responses));
            if (dataSourceTypes == null) throw new ArgumentNullException(nameof(dataSourceTypes));

            var filter = dataSourceTypes.ToArray();

            return !filter.Any() ? responses : responses.Where(_ => filter.Contains(_.DataSourceType));
        }

        public static IEnumerable<CaseNotificationResponse> IncludesErrors(
            this IEnumerable<CaseNotificationResponse> responses, bool include)
        {
            if (responses == null) throw new ArgumentNullException(nameof(responses));

            return include ? responses : responses.Where(_ => _.Type != "error");
        }

        public static IEnumerable<CaseNotificationResponse> IncludesRejected(
            this IEnumerable<CaseNotificationResponse> responses, bool include)
        {
            if (responses == null) throw new ArgumentNullException(nameof(responses));

            return include ? responses : responses.Where(_ => _.Type != "rejected");
        }

        public static IEnumerable<CaseNotificationResponse> IncludesReviewed(
            this IEnumerable<CaseNotificationResponse> responses, bool include)
        {
            if (responses == null) throw new ArgumentNullException(nameof(responses));

            return include ? responses : responses.Where(_ => _.IsReviewed != true);
        }
    }
}