using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Graph
{
    public class GraphAppointment
    {
        public string Subject { get; set; }
        public GraphMessageBody Body { get; set; }
        public EventDate Start { get; set; }
        public EventDate End { get; set; }
        public string Importance { get; set; }
        public bool IsReminderOn { get; set; }
        public string Id { get; set; }
        public int ReminderMinutesBeforeStart { get; set; }
        public SingleValueExtendedProperty[] SingleValueExtendedProperties { get; set; }
    }

    public class GraphMessageBody
    {
        public string ContentType { get; set; }
        public string Content { get; set; }
    }

    public class EventDate
    {
        public EventDate()
        {
            TimeZone = TimeZoneInfo.Local.StandardName;
        }

        public DateTime DateTime { get; set; }
        public string TimeZone { get; }
    }

    public class SingleValueExtendedProperty
    {
        public string Id { get; set; }
        public string Value { get; set; }
    }

    public enum GraphMessageBodyType
    {
        Html,
        Text
    }

    public class GraphAppointments
    {
        public List<GraphAppointment> Value { get; set; }
    }

    public enum GraphImportance
    {
        Low,
        Normal,
        High
    }

    public class GraphTask
    {
        public string Title { get; set; }
        public GraphMessageBody Body { get; set; }
        public string Importance { get; set; }
        public EventDate DueDateTime { get; set; }
        public string Id { get; set; }
        public bool IsReminderOn { get; set; }
        public int ReminderMinutesBeforeStart { get; set; }
    }

    public class TaskExtension
    {
        [JsonProperty("@odata.type")]
        public string DataType => "microsoft.graph.openTypeExtension";

        [JsonProperty("extensionName")]
        public string ExtensionName => "taskExtension";

        public int StaffKey { get; set; }

        public string CreatedOn { get; set; }
    }

    public class GraphEmailMessage
    {
        public string Id { get; set; }

        public string Subject { get; set; }

        public GraphMessageBody Body { get; set; }

        [JsonProperty("toRecipients")]
        public List<GraphEmailAddress> To { get; set; }

        [JsonProperty("ccRecipients")]
        public List<GraphEmailAddress> Cc { get; set; }

        [JsonProperty("bccRecipients")]
        public List<GraphEmailAddress> Bcc { get; set; }

        [JsonProperty("attachments")]
        public List<GraphAttachment> Attachments { get; set; }
    }

    public class GraphEmailAddress
    {
        public EmailAddress EmailAddress { get; set; }
    }

    public class EmailAddress
    {
        public string Name { get; set; }
        public string Address { get; set; }
    }

    public class GraphAttachment
    {
        [JsonProperty("@odata.type")]
        public string DataType => "#microsoft.graph.fileAttachment";

        public byte[] ContentBytes { get; set; }
        public string ContentId { get; set; }
        public bool IsInline { get; set; }
        public string Name { get; set; }
    }
}