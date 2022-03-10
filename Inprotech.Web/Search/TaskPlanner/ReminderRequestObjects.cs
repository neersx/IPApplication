using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;

namespace Inprotech.Web.Search.TaskPlanner
{
    public class ReminderActionRequest
    {
        public string[] TaskPlannerRowKeys { get; set; }
        public SavedSearchRequestParams<TaskPlannerRequestFilter> SearchRequestParams { get; set; }
    }

    public class DeferReminderRequest : ReminderActionRequest
    {
        public DateTime? HoldUntilDate { get; set; }
        public ReminderRequestType RequestType { get; set; }
    }

    public class DismissReminderRequest : ReminderActionRequest
    {
        public ReminderRequestType RequestType { get; set; }
    }

    public class ReminderReadUnReadRequest : ReminderActionRequest
    {
        public bool IsRead { get; set; }
    }

    public class DueDateResponsibilityRequest : ReminderActionRequest
    {
        public int? ToNameId { get; set; }
    }

    public class ForwardReminderRequest : ReminderActionRequest
    {
        public int[] ToNameIds { get; set; }
    }

    public class RowKeyParam
    {
        public string Key { get; set; }
        public long? EmployeeReminderId { get; set; }
        public long? AlertId { get; set; }
        public int? EmployeeNo { get; set; }
        public string Type { get; set; }
        public long? CaseEventId { get; set; }
    }

    public class ReminderResult
    {
        public ReminderActionStatus Status { get; set; }
        public string MessageTitle { get; set; }
        public string Message { get; set; }
        public List<string> UnprocessedRowKeys { get; set; }
    }

    public class TaskPlannerEmailContent
    {
        public string Subject { get; set; }
        public string Body { get; set; }
    }

    public enum ReminderActionStatus
    {
        PartialCompletion,
        UnableToComplete,
        Success
    }

    public enum ReminderRequestType
    {
        InlineTask,
        BulkAction
    }
}