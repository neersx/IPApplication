using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.SqlServer;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.TaskPlanner.Reminders
{
    public interface IReminderManager
    {
        Task<ReminderResult> Defer(DeferReminderRequest request);
        Task<ReminderResult> Dismiss(DismissReminderRequest request);
        Task<int> MarkAsReadOrUnread(ReminderReadUnReadRequest request);
        Task<ReminderResult> ChangeDueDateResponsibility(DueDateResponsibilityRequest request);
        Task<ReminderResult> ForwardReminders(ForwardReminderRequest request);
        Task<IEnumerable<TaskPlannerEmailContent>> GetEmailContent(string[] rowKeys);
        Task<Picklists.Name> GetDueDateResponsibility(string taskPlannerRowKey);
        IEnumerable<RowKeyParam> GetRowKeyParams(string[] taskPlannerRowKeys);
    }

    public class ReminderManager : IReminderManager
    {
        readonly IDbContext _dbContext;
        readonly IForwardReminderHandler _forwardReminderHandler;
        readonly IFunctionSecurityProvider _functionSecurityProvider;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly ITaskPlannerEmailResolver _taskPlannerEmailResolver;

        public ReminderManager(
            IDbContext dbContext,
            Func<DateTime> now,
            ISiteControlReader siteControlReader,
            ISecurityContext securityContext,
            IFunctionSecurityProvider functionSecurityProvider,
            ITaskPlannerEmailResolver taskPlannerEmailResolver,
            IForwardReminderHandler forwardReminderHandler)
        {
            _dbContext = dbContext;
            _now = now;
            _siteControlReader = siteControlReader;
            _securityContext = securityContext;
            _functionSecurityProvider = functionSecurityProvider;
            _taskPlannerEmailResolver = taskPlannerEmailResolver;
            _forwardReminderHandler = forwardReminderHandler;
        }

        public async Task<ReminderResult> Defer(DeferReminderRequest request)
        {
            if (request?.TaskPlannerRowKeys == null || !request.TaskPlannerRowKeys.Any())
            {
                throw new ArgumentNullException();
            }

            var holdExcludeDays = _siteControlReader.Read<int>(SiteControls.HOLDEXCLUDEDAYS);
            var dateToCompare = request.HoldUntilDate ?? _now();
            IQueryable<StaffReminder> staffReminders = null;
            var requestKeyParams = GetRowKeyParams(request.TaskPlannerRowKeys);

            var keyParamsToBeProcessed = await GetPrivilegedRequestParams(requestKeyParams, FunctionSecurityPrivilege.CanUpdate);
            var reminderIds = keyParamsToBeProcessed.Where(x => x.EmployeeReminderId.HasValue)
                                                    .Select(x => x.EmployeeReminderId.Value)
                                                    .ToArray();
            if (reminderIds.Any())
            {
                staffReminders = from r in _dbContext.Set<StaffReminder>()
                                 where reminderIds.Contains(r.EmployeeReminderId)
                                       && r.DueDate.HasValue
                                       && SqlFunctions.DateDiff("day", dateToCompare, r.DueDate) > holdExcludeDays
                                 select r;
            }

            if (staffReminders == null || !staffReminders.Any())
            {
                return new ReminderResult
                {
                    Status = ReminderActionStatus.UnableToComplete,
                    UnprocessedRowKeys = request.TaskPlannerRowKeys.ToList(),
                    Message = $"{(request.RequestType == ReminderRequestType.InlineTask ? "taskPlannerTaskMenu" : "taskPlannerBulkActionMenu")}.deferredUnableToComplete{(request.HoldUntilDate.HasValue ? "WithDate" : string.Empty)}"
                };
            }

            var processedReminderIds = await staffReminders.Select(x => x.EmployeeReminderId).ToArrayAsync();
            if (request.HoldUntilDate.HasValue)
            {
                await _dbContext.UpdateAsync(staffReminders, _ => new StaffReminder
                {
                    ReminderDate = request.HoldUntilDate,
                    HoldUntilDate = request.HoldUntilDate
                });
            }
            else
            {
                keyParamsToBeProcessed = keyParamsToBeProcessed.Where(x => x.EmployeeReminderId.HasValue && processedReminderIds.Contains(x.EmployeeReminderId.Value)).ToArray();
                var nextCalculatedDates = await GetNextCalculatedDates(keyParamsToBeProcessed);
                if (nextCalculatedDates.Any())
                {
                    processedReminderIds = nextCalculatedDates.Keys.ToArray();
                    foreach (var reminder in staffReminders)
                    {
                        reminder.ReminderDate = nextCalculatedDates[reminder.EmployeeReminderId];
                        reminder.HoldUntilDate = nextCalculatedDates[reminder.EmployeeReminderId];
                    }

                    await _dbContext.SaveChangesAsync();
                }
            }

            await MarkAsReadOrUnread(keyParamsToBeProcessed.Where(x => x.EmployeeReminderId.HasValue && processedReminderIds.Contains(x.EmployeeReminderId.Value)).ToArray(), true);

            var result = new ReminderResult
            {
                Status = !processedReminderIds.Any() ? ReminderActionStatus.UnableToComplete
                    : processedReminderIds.Length == request.TaskPlannerRowKeys.Length ? ReminderActionStatus.Success : ReminderActionStatus.PartialCompletion,
                UnprocessedRowKeys = !processedReminderIds.Any()
                    ? request.TaskPlannerRowKeys.ToList()
                    : requestKeyParams.Where(x => !x.EmployeeReminderId.HasValue || !processedReminderIds.Contains(x.EmployeeReminderId.Value)).Select(x => x.Key).ToList(),
                Message = $"{(request.RequestType == ReminderRequestType.InlineTask ? "taskPlannerTaskMenu" : "taskPlannerBulkActionMenu")}"
            };

            result.Message = $"{result.Message}.deferred{result.Status}{(result.Status != ReminderActionStatus.Success && request.HoldUntilDate.HasValue ? "WithDate" : string.Empty)}";

            return result;
        }

        public async Task<ReminderResult> Dismiss(DismissReminderRequest request)
        {
            var reminderDeleteButton = _siteControlReader.Read<int>(SiteControls.ReminderDeleteButton);
            if (request?.TaskPlannerRowKeys == null || !request.TaskPlannerRowKeys.Any() || reminderDeleteButton == KnownDismissReminderActions.CanNotDismiss) throw new ArgumentNullException();

            var requestKeyParams = GetRowKeyParams(request.TaskPlannerRowKeys);

            var privilegedKeyParams = await GetPrivilegedRequestParams(requestKeyParams, FunctionSecurityPrivilege.CanDelete, FunctionSecurityPrivilege.CanUpdate);
            if (!privilegedKeyParams.Any())
            {
                return new ReminderResult
                {
                    Status = ReminderActionStatus.UnableToComplete,
                    UnprocessedRowKeys = request.TaskPlannerRowKeys.ToList(),
                    MessageTitle = "modal.unableToComplete",
                    Message = request.RequestType == ReminderRequestType.BulkAction ? "taskPlannerBulkActionMenu.dismissUnableToComplete" : "taskPlannerTaskMenu.doNotHavePermissionToDismiss"
                };
            }

            var privilegedReminderIds = privilegedKeyParams.Select(x => x.EmployeeReminderId).ToArray();

            IQueryable<StaffReminder> staffRemindersToBeProcessed = null;
            if (privilegedReminderIds.Any())
            {
                var tomorrow = _now().AddDays(1).Date;
                staffRemindersToBeProcessed = from r in _dbContext.Set<StaffReminder>()
                                              where privilegedReminderIds.Contains(r.EmployeeReminderId)
                                                    && (reminderDeleteButton == KnownDismissReminderActions.DismissAny || reminderDeleteButton == KnownDismissReminderActions.DismissPastOnly && r.DueDate < tomorrow)
                                              select r;
            }

            var processedReminderIds = staffRemindersToBeProcessed?.Select(x => x.EmployeeReminderId).ToArray();
            if (staffRemindersToBeProcessed != null && staffRemindersToBeProcessed.Any())
            {
                await _dbContext.DeleteAsync(staffRemindersToBeProcessed);
                await MarkAsReadOrUnread(privilegedKeyParams.Where(x => x.EmployeeReminderId.HasValue && processedReminderIds.Contains(x.EmployeeReminderId.Value)).ToArray(), true);
            }

            return GenerateDismissResult(requestKeyParams, processedReminderIds, request.RequestType);
        }

        public async Task<int> MarkAsReadOrUnread(ReminderReadUnReadRequest request)
        {
            if (request?.TaskPlannerRowKeys == null || !request.TaskPlannerRowKeys.Any()) throw new ArgumentNullException();

            var requestKeyParams = GetRowKeyParams(request.TaskPlannerRowKeys);
            var privilegedRequestParams = await GetPrivilegedRequestParams(requestKeyParams, FunctionSecurityPrivilege.CanUpdate);

            return await MarkAsReadOrUnread(privilegedRequestParams, request.IsRead);
        }

        public async Task<Picklists.Name> GetDueDateResponsibility(string taskPlannerRowKey)
        {
            if (string.IsNullOrWhiteSpace(taskPlannerRowKey)) throw new ArgumentNullException();

            var caseEventId = GetRowKeyParams(new[] { taskPlannerRowKey }).Single().CaseEventId;

            var name = await (from ce in _dbContext.Set<CaseEvent>()
                              join n in _dbContext.Set<InprotechKaizen.Model.Names.Name>() on ce.EmployeeNo equals n.Id
                              where caseEventId == ce.Id
                              select n).SingleOrDefaultAsync();

            return name != null
                ? new Picklists.Name
                {
                    Key = name.Id,
                    Code = name.NameCode,
                    DisplayName = name.Formatted(),
                    Remarks = name.Remarks
                }
                : null;
        }

        public async Task<ReminderResult> ChangeDueDateResponsibility(DueDateResponsibilityRequest request)
        {
            if (request?.TaskPlannerRowKeys == null || !request.TaskPlannerRowKeys.Any())
            {
                throw new ArgumentNullException();
            }

            var dueDateKeysToBeChanged = GetRowKeyParams(request.TaskPlannerRowKeys)
                                         .Where(x => x.Type == KnownReminderTypes.ReminderOrDueDate && x.CaseEventId.HasValue)
                                         .ToArray();

            if (dueDateKeysToBeChanged.Any())
            {
                var caseEventIds = dueDateKeysToBeChanged.Select(x => x.CaseEventId.Value).ToArray();
                var caseEvents = from ce in _dbContext.Set<CaseEvent>()
                                 where caseEventIds.Contains(ce.Id)
                                 select ce;
                await _dbContext.UpdateAsync(caseEvents, _ => new CaseEvent
                {
                    EmployeeNo = request.ToNameId
                });
            }

            await MarkAsReadOrUnread(dueDateKeysToBeChanged, true);

            var processedRowKeys = dueDateKeysToBeChanged.Select(x => x.Key).ToArray();
            return new ReminderResult
            {
                Status = processedRowKeys.Length == request.TaskPlannerRowKeys.Length
                    ? ReminderActionStatus.Success
                    : processedRowKeys.Any()
                        ? ReminderActionStatus.PartialCompletion
                        : ReminderActionStatus.UnableToComplete,
                UnprocessedRowKeys = request.TaskPlannerRowKeys.Except(processedRowKeys).ToList()
            };
        }

        public async Task<ReminderResult> ForwardReminders(ForwardReminderRequest request)
        {
            if (request?.TaskPlannerRowKeys == null || !request.TaskPlannerRowKeys.Any()
                                                    || request.ToNameIds == null || !request.ToNameIds.Any())
            {
                throw new ArgumentNullException("request.TaskPlannerRowKeys");
            }

            var keyParams = GetRowKeyParams(request.TaskPlannerRowKeys).ToList();
            var reminderIdsToBeProcessed = keyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate || x.EmployeeReminderId.HasValue)
                                                    .Select(x => x.EmployeeReminderId.Value).ToArray();

            if (!reminderIdsToBeProcessed.Any())
            {
                return new ReminderResult
                {
                    Status = ReminderActionStatus.UnableToComplete,
                    UnprocessedRowKeys = request.TaskPlannerRowKeys.ToList()
                };
            }

            await _forwardReminderHandler.Process(reminderIdsToBeProcessed, request.ToNameIds.ToList(), keyParams);

            await MarkAsReadOrUnread(keyParams.Where(x => x.EmployeeReminderId.HasValue && reminderIdsToBeProcessed.Contains(x.EmployeeReminderId.Value)).ToArray(), true);

            var unprocessedRowKeys = keyParams.Where(x => !x.EmployeeReminderId.HasValue
                                                          || !reminderIdsToBeProcessed.Contains(x.EmployeeReminderId.Value))
                                              .Select(x => x.Key).ToList();
            return new ReminderResult
            {
                UnprocessedRowKeys = unprocessedRowKeys,
                Status = unprocessedRowKeys.Count() == request.TaskPlannerRowKeys.Length
                    ? ReminderActionStatus.UnableToComplete
                    : unprocessedRowKeys.Any()
                        ? ReminderActionStatus.PartialCompletion
                        : ReminderActionStatus.Success
            };
        }

        public async Task<IEnumerable<TaskPlannerEmailContent>> GetEmailContent(string[] rowKeys)
        {
            if (rowKeys == null || !rowKeys.Any()) throw new ArgumentNullException();

            var emailContentList = new List<TaskPlannerEmailContent>();
            var subjectDocItem = _siteControlReader.Read<string>(SiteControls.EmailTaskPlannerSubject);
            var bodyDocItem = _siteControlReader.Read<string>(SiteControls.EmailTaskPlannerBody);
            foreach (var rowKey in rowKeys)
            {
                emailContentList.Add(new TaskPlannerEmailContent
                {
                    Subject = _taskPlannerEmailResolver.Resolve(rowKey, subjectDocItem),
                    Body = _taskPlannerEmailResolver.Resolve(rowKey, bodyDocItem)
                });
            }

            await MarkAsReadOrUnread(GetRowKeyParams(rowKeys).ToArray(), true);

            return emailContentList.AsEnumerable();
        }

        async Task<int> MarkAsReadOrUnread(RowKeyParam[] keyParams, bool isRead)
        {
            var reminderIdsToBeProcessed = keyParams.Select(x => x.EmployeeReminderId).ToArray();

            if (!reminderIdsToBeProcessed.Any()) return 0;

            var staffReminders = from r in _dbContext.Set<StaffReminder>()
                                 where reminderIdsToBeProcessed.Contains(r.EmployeeReminderId)
                                 select r;

            return await _dbContext.UpdateAsync(staffReminders, _ => new StaffReminder
            {
                IsRead = isRead ? 1 : 0
            });
        }

        ReminderResult GenerateDismissResult(IEnumerable<RowKeyParam> requestKeyParams, long[] processedReminderIds, ReminderRequestType requestType)
        {
            var rowKeyParams = requestKeyParams as RowKeyParam[] ?? requestKeyParams.ToArray();
            var noOfRequestedRows = rowKeyParams.ToList().Count;
            var noOfProcessedRows = processedReminderIds.Length;
            string message;
            var messageTitle = string.Empty;
            if (noOfRequestedRows == noOfProcessedRows)
            {
                message = requestType == ReminderRequestType.BulkAction ? "taskPlannerBulkActionMenu.dismissedMessage" : "taskPlannerTaskMenu.dismissedMessage";
            }
            else if (noOfProcessedRows == 0)
            {
                messageTitle = "modal.unableToComplete";
                message = requestType == ReminderRequestType.BulkAction ? "taskPlannerBulkActionMenu.dismissUnableToComplete" : "taskPlannerTaskMenu.couldNotBeDismissedMessage";
            }
            else
            {
                messageTitle = "modal.partialComplete";
                message = "taskPlannerBulkActionMenu.dismissPartialCompletion";
            }

            return new ReminderResult
            {
                Status = noOfProcessedRows == noOfRequestedRows ? ReminderActionStatus.Success :
                    noOfProcessedRows == 0 ? ReminderActionStatus.UnableToComplete : ReminderActionStatus.PartialCompletion,
                MessageTitle = messageTitle,
                Message = message,
                UnprocessedRowKeys = rowKeyParams.Where(x => !x.EmployeeReminderId.HasValue || !processedReminderIds.Contains(x.EmployeeReminderId.Value)).Select(x => x.Key).ToList()
            };
        }

        async Task<RowKeyParam[]> GetPrivilegedRequestParams(IEnumerable<RowKeyParam> requestKeyParams, FunctionSecurityPrivilege functionSecurityPrivilege, FunctionSecurityPrivilege? alternativeFunctionSecurityPrivilege = null)
        {
            var keyParams = requestKeyParams.Where(x => x.EmployeeReminderId.HasValue).ToArray();

            if (!keyParams.Any()) return keyParams;
            var employeeReminderIds = keyParams.Select(x => x.EmployeeReminderId.Value).ToArray();

            var selectedReminders = await _dbContext.Set<StaffReminder>()
                                                    .Where(x => employeeReminderIds.Contains(x.EmployeeReminderId))
                                                    .Select(x => new
                                                    {
                                                        EmployeeNo = x.StaffId,
                                                        x.EmployeeReminderId
                                                    }).ToArrayAsync();
            foreach (var requestParam in keyParams) requestParam.EmployeeNo = selectedReminders.FirstOrDefault(x => x.EmployeeReminderId == requestParam.EmployeeReminderId)?.EmployeeNo;

            var privilegedEmployeeNos = (await _functionSecurityProvider.FunctionSecurityFor(BusinessFunction.Reminder,
                                                                                             functionSecurityPrivilege,
                                                                                             _securityContext.User,
                                                                                             keyParams.Where(x => x.EmployeeNo.HasValue).Select(x => x.EmployeeNo.Value).Distinct())).ToList();
            if (alternativeFunctionSecurityPrivilege.HasValue)
            {
                privilegedEmployeeNos.AddRange(await _functionSecurityProvider.FunctionSecurityFor(BusinessFunction.Reminder,
                                                                                                   alternativeFunctionSecurityPrivilege.Value,
                                                                                                   _securityContext.User,
                                                                                                   keyParams.Where(x => x.EmployeeNo.HasValue).Select(x => x.EmployeeNo.Value).Distinct()));
                privilegedEmployeeNos = privilegedEmployeeNos.Distinct().ToList();
            }

            return keyParams.Where(x => x.EmployeeReminderId.HasValue && x.EmployeeNo.HasValue && privilegedEmployeeNos.Contains(x.EmployeeNo.Value)).ToArray();
        }

        async Task<Dictionary<long, DateTime>> GetNextCalculatedDates(RowKeyParam[] validKeyParams)
        {
            var reminderDates = new Dictionary<long, DateTime>();
            var adHocKeyParams = validKeyParams.Where(x => x.Type == KnownReminderTypes.AdHocDate && x.AlertId.HasValue).ToArray();

            if (adHocKeyParams.Any())
            {
                var alertIds = adHocKeyParams.Select(x => x.AlertId.Value).ToArray();
                var alertDates = await (from a in _dbContext.Set<AlertRule>()
                                        where alertIds.Contains(a.Id) && a.AlertDate.HasValue
                                        select new { AlertId = a.Id, AlertDate = a.AlertDate.Value }).ToListAsync();
                if (alertDates.Any())
                {
                    reminderDates = (from a in alertDates
                                     join p in adHocKeyParams on a.AlertId equals p.AlertId
                                     select new { a, p }).ToDictionary(x => x.p.EmployeeReminderId.Value, x => x.a.AlertDate);
                }
            }

            var caseEventIds = validKeyParams.Where(x => x.Type == KnownReminderTypes.ReminderOrDueDate && x.CaseEventId.HasValue).Select(x => x.CaseEventId.Value).ToArray();

            if (caseEventIds.Any())
            {
                var caseEvents = await (from ce in _dbContext.Set<CaseEvent>()
                                        where caseEventIds.Contains(ce.Id) && ce.ReminderDate.HasValue
                                        select ce).ToListAsync();
                if (caseEvents.Any())
                {
                    var dueDateReminderDates = (from ce in caseEvents
                                                join p in validKeyParams.Where(x => x.Type == KnownReminderTypes.ReminderOrDueDate) on ce.Id equals p.CaseEventId
                                                select new { ce, p }).ToDictionary(x => x.p.EmployeeReminderId.Value, x => x.ce.ReminderDate.Value);
                    if (dueDateReminderDates.Any())
                    {
                        reminderDates.AddRange(dueDateReminderDates);
                    }
                }
            }

            return reminderDates;
        }

        public IEnumerable<RowKeyParam> GetRowKeyParams(string[] taskPlannerRowKeys)
        {
            return (from rowKey in taskPlannerRowKeys
                    let keys = rowKey.Split('^')
                    select new RowKeyParam
                    {
                        Key = rowKey,
                        Type = keys[0],
                        AlertId = keys[0] == KnownReminderTypes.AdHocDate ? Convert.ToInt64(keys[1]) : null,
                        CaseEventId = keys[0] == KnownReminderTypes.ReminderOrDueDate && !string.IsNullOrWhiteSpace(keys[1]) ? Convert.ToInt64(keys[1]) : null,
                        EmployeeReminderId = string.IsNullOrWhiteSpace(keys[2]) ? null : Convert.ToInt64(keys[2])
                    }).ToList();
        }
    }
}