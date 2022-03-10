using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using Case = Inprotech.Web.Picklists.Case;
using Name = Inprotech.Web.Picklists.Name;

namespace Inprotech.Web.Dates
{
    public interface IAdHocDates
    {
        AdHocDatePayload Get(int id);
        dynamic Delete(long alertId);
        IEnumerable<ResolveReason> ResolveReasons();
        Task<dynamic> Finalise(FinaliseRequestModel finaliseRequestModel);
        Task<dynamic> BulkFinalise(BulkFinaliseRequestModel bulkFinaliseRequestModel);
        Task<dynamic> CreateAdhocDate(AdhocSaveDetails[] saveAdhocDetails);
        Task<dynamic> ViewData(int? alertId);
        Task<dynamic> CaseEventDetails(long caseEventId);
        IEnumerable<Names> NameDetails(int caseId);
        IEnumerable<Names> RelationshipDetails(int caseId, string nameTypeCode, string relationshipCode);
        Task<dynamic> MaintainAdhocDate(int alertId, AdhocSaveDetails maintainAdhocDetails);
    }

    public class AdHocDates : IAdHocDates
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IFunctionSecurityProvider _functionSecurityProvider;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly IPolicingEngine _policingEngine;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;
        readonly ITaskPlannerRowSelectionService _taskPlannerRowSelectionService;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IReminderManager _reminderManager;

        public AdHocDates(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                          IPolicingEngine policingEngine, ITaskPlannerRowSelectionService taskPlannerRowSelectionService,
                          ISiteControlReader siteControlReader, IImportanceLevelResolver importanceLevelResolver,
                          ISecurityContext securityContext,
                          Func<DateTime> clock,
                          ITaskSecurityProvider taskSecurityProvider,
                          IFunctionSecurityProvider functionSecurityProvider, IReminderManager reminderManager)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _policingEngine = policingEngine;
            _taskPlannerRowSelectionService = taskPlannerRowSelectionService;
            _siteControls = siteControlReader;
            _importanceLevelResolver = importanceLevelResolver;
            _securityContext = securityContext;
            _clock = clock;
            _taskSecurityProvider = taskSecurityProvider;
            _functionSecurityProvider = functionSecurityProvider;
            _reminderManager = reminderManager;
        }

        public AdHocDatePayload Get(int id)
        {
            var alert = _dbContext.Set<AlertRule>().SingleOrDefault(_ => _.Id.Equals(id));
            if (alert == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var adHocDatePayload = new AdHocDatePayload
            {
                AlertId = alert.Id,
                Type = AdhocType(alert),
                AdHocDateFor = alert.StaffName.Formatted(),
                Message = alert.AlertMessage,
                DueDate = alert.DueDate,
                FinaliseReference = Reference(alert),
                Reference = AdhocReference(alert),
                DateOccurred = alert.DateOccurred,
                ResolveReason = alert.OccurredFlag?.ToString(),
                EmployeeFlag = alert.EmployeeFlag,
                SignatoryFlag = alert.SignatoryFlag,
                CriticalFlag = alert.CriticalFlag,
                DaysLead = alert.DaysLead,
                SendElectronically = alert.SendElectronically,
                EmployeeNo = alert.StaffId,
                ImportanceLevel = _dbContext.Set<Importance>().SingleOrDefault(x => x.Level == alert.Importance)?.LevelNumeric,
                DailyFrequency = alert.DailyFrequency,
                DeleteOn = alert.DeleteDate,
                EmailSubject = alert.EmailSubject,
                Event = alert.TriggerEventNo != null
                    ? new Event
                    {
                        Key = alert.TriggerEvent.Id,
                        Code = alert.TriggerEvent.Code,
                        Value = alert.TriggerEvent.Description
                    }
                    : null,
                MonthlyFrequency = alert.MonthlyFrequency,
                MonthsLead = alert.MonthsLead,
                NameNo = alert.NameId,
                EndOn = alert.StopReminderDate,
                AdhocResponsibleName = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Any(x => x.Id == alert.StaffId)
                    ? _dbContext.Set<InprotechKaizen.Model.Names.Name>().Where(x => x.Id == alert.StaffId).ToArray()
                                .Select(x => new
                                {
                                    Type = "AdhocResponsibleName",
                                    Key = x.Id,
                                    Code = x.NameCode,
                                    DisplayName = x.Formatted()
                                }).FirstOrDefault()
                    : null,
                NameTypeValue = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == alert.NameTypeId) != null
                    ? new
                    {
                        Key = alert.NameTypeId,
                        Code = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == alert.NameTypeId)?.NameTypeCode,
                        Value = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == alert.NameTypeId)?.Name
                    }
                    : null,
                RelationshipValue = _dbContext.Set<NameRelation>().SingleOrDefault(x => x.RelationshipCode == alert.Relationship) != null
                    ? new
                    {
                        Key = alert.Relationship,
                        Code = alert.Relationship,
                        Value = _dbContext.Set<NameRelation>().SingleOrDefault(x => x.RelationshipCode == alert.Relationship)?.RelationDescription
                    }
                    : null
            };

            return adHocDatePayload;
        }

        public dynamic Delete(long alertId)
        {
            var alert = _dbContext.Set<AlertRule>()
                                  .SingleOrDefault(_ => _.Id == alertId);
            if (alert == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var reminders = _dbContext.Set<StaffReminder>()
                                          .Where(_ => _.StaffId == alert.StaffId);

                reminders = alert.CaseId.HasValue
                    ? reminders.Where(_ => _.CaseId == alert.CaseId)
                    : reminders.Where(_ => !_.CaseId.HasValue);
                reminders = !string.IsNullOrEmpty(alert.Reference)
                    ? reminders.Where(_ => _.Reference == alert.Reference)
                    : reminders.Where(_ => _.Reference == null);
                reminders = alert.NameId.HasValue
                    ? reminders.Where(_ => _.NameId == alert.NameId)
                    : reminders.Where(_ => !_.NameId.HasValue);

                reminders = reminders.Where(_ => _.Source == 1);
                reminders = reminders.Where(_ => _.SequenceNo == alert.SequenceNo);

                _dbContext.RemoveRange(reminders);

                _dbContext.Set<AlertRule>().Remove(alert);

                _dbContext.SaveChanges();

                t.Complete();
            }

            return new
            {
                Status = ReminderActionStatus.Success
            };
        }

        public async Task<dynamic> Finalise(FinaliseRequestModel finaliseRequestModel)
        {
            var alert = _dbContext.Set<AlertRule>()
                                  .SingleOrDefault(_ => _.Id == finaliseRequestModel.AlertId);
            if (alert == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var requiresPolicing = RequiresPolicing(finaliseRequestModel, alert);

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                alert.OccurredFlag = finaliseRequestModel.DateOccured != null && !finaliseRequestModel.UserCode.HasValue ? 3 : finaliseRequestModel.UserCode;
                alert.DateOccurred = finaliseRequestModel.DateOccured;

                await _dbContext.SaveChangesAsync();

                if (requiresPolicing)
                {
                    var batchNo = _policingEngine.CreateBatch();
                    _policingEngine.PoliceAdHocDates(alert, batchNo);
                    await _policingEngine.PoliceWithoutTransaction(batchNo);
                }

                t.Complete();
            }

            await _reminderManager.MarkAsReadOrUnread(new ReminderReadUnReadRequest { TaskPlannerRowKeys = new[] { finaliseRequestModel.TaskPlannerRowKey }, IsRead = true });

            return new
            {
                Status = ReminderActionStatus.Success
            };
        }

        public async Task<dynamic> BulkFinalise(BulkFinaliseRequestModel bulkFinaliseRequestModel)
        {
            if (bulkFinaliseRequestModel == null) throw new ArgumentNullException();

            var rowSelections = await RowSelections(bulkFinaliseRequestModel);

            var allSelections = (string[])rowSelections.allSelection;
            var rowKeysToProcess = (string[])rowSelections.rowKeysToProcess;
            var unprocessedRowKeys = (string[])rowSelections.unprocessedRowKeys;

            var allSelectedInvalid = allSelections.Length == unprocessedRowKeys.Length;
            if (allSelectedInvalid)
            {
                return new
                {
                    Status = ReminderActionStatus.UnableToComplete,
                    UnprocessedRowKeys = unprocessedRowKeys
                };
            }

            var alertIds = rowKeysToProcess.Select(_ => Convert.ToInt64(_.Split('^')[1])).ToArray();

            var adHocDates = _dbContext.Set<AlertRule>()
                                       .Where(_ => alertIds.Contains(_.Id));
            if (!adHocDates.Any())
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                await adHocDates.ForEachAsync(_ =>
                {
                    _.DateOccurred = bulkFinaliseRequestModel.DateOccured;
                    _.OccurredFlag = bulkFinaliseRequestModel.DateOccured != null && !bulkFinaliseRequestModel.UserCode.HasValue ? 3 : bulkFinaliseRequestModel.UserCode;
                });

                await _dbContext.SaveChangesAsync();

                var batchNo = _policingEngine.CreateBatch();

                foreach (var alert in adHocDates.ToArray()) _policingEngine.PoliceAdHocDates(alert, batchNo);

                await _policingEngine.PoliceWithoutTransaction(batchNo);

                t.Complete();
            }

            await _reminderManager.MarkAsReadOrUnread(new ReminderReadUnReadRequest { TaskPlannerRowKeys = rowKeysToProcess, IsRead = true });

            return new
            {
                Status = allSelections.Length == rowKeysToProcess.Length ? ReminderActionStatus.Success : ReminderActionStatus.PartialCompletion,
                UnprocessedRowKeys = unprocessedRowKeys
            };
        }

        public async Task<dynamic> CreateAdhocDate(AdhocSaveDetails[] saveDetails)
        {
            if (saveDetails == null || !saveDetails.Any())
            {
                throw new ArgumentNullException();
            }

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var adhocSaveDetails = saveDetails;
                var employeeNos = adhocSaveDetails.Select(_ => _.EmployeeNo);
                var adhocDate = adhocSaveDetails.First();
                var sequenceNo = GetSequenceNo(employeeNos, adhocDate);
                var adhocEntities = SaveAdhocDates(adhocSaveDetails, sequenceNo);

                _dbContext.AddRange(adhocEntities);

                await _dbContext.SaveChangesAsync();

                if (!adhocSaveDetails.First().IsNoReminder)
                {
                    var batchNo = _policingEngine.CreateBatch();

                    foreach (var alert in adhocEntities) _policingEngine.PoliceAdHocDates(alert, batchNo);

                    await _policingEngine.PoliceWithoutTransaction(batchNo);
                }

                t.Complete();
            }

            var taskPlannerRowKeys = saveDetails.Where(x => !string.IsNullOrWhiteSpace(x.TaskPlannerRowKey)).Select(x => x.TaskPlannerRowKey).Distinct().ToArray();
            if (taskPlannerRowKeys.Any())
            {
                await _reminderManager.MarkAsReadOrUnread(new ReminderReadUnReadRequest { TaskPlannerRowKeys = taskPlannerRowKeys, IsRead = true });
            }

            return new
            {
                Status = ReminderActionStatus.Success
            };
        }

        public async Task<dynamic> ViewData(int? alertId)
        {
            var defaultAdHocImportance = _siteControls.Read<int?>(SiteControls.DefaultAdhocDateImportance);
            var importanceLevelOptions = (await _importanceLevelResolver.GetImportanceLevels()).Select(_ => new
            {
                Code = _.LevelNumeric,
                _.Description
            });

            var loggedInUser = new
            {
                Key = _securityContext.User.Name.Id,
                Code = _securityContext.User.Name.NameCode,
                DisplayName = _securityContext.User.Name.Formatted(),
                Type = "loggedInUser"
            };

            var criticalReminderName = _siteControls.Read<int>(SiteControls.CriticalReminder);
            var name = await _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                                       .SingleOrDefaultAsync(_ => _.Id == criticalReminderName);
            var criticalUser = new
            {
                Key = name?.Id,
                Code = name?.NameCode,
                DisplayName = name?.Formatted(),
                Type = "CriticalUser"
            };

            var canDeleteAdHoc = await EvaluateDeleteAccess(alertId);

            var canFinaliseAdhoc = _taskSecurityProvider.HasAccessTo(ApplicationTask.FinaliseAdHocDate);

            return new
            {
                defaultAdHocImportance,
                importanceLevelOptions,
                loggedInUser,
                criticalUser,
                canDeleteAdHoc,
                canFinaliseAdhoc
            };
        }

        public async Task<dynamic> CaseEventDetails(long caseEventId)
        {
            var caseEvent = await _dbContext.Set<CaseEvent>()
                                            .SingleOrDefaultAsync(ce => ce.Id == caseEventId);

            if (caseEvent == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return new
            {
                Case = new
                {
                    Key = caseEvent.Case.Id,
                    Code = caseEvent.Case.Irn,
                    Value = caseEvent.Case.Title
                }
            };
        }

        public IEnumerable<Names> NameDetails(int caseId)
        {
            var names = _dbContext.Set<CaseName>()
                                  .Where(_ => _.CaseId == caseId
                                              && (_.NameTypeId == KnownNameTypes.Signatory
                                                  || _.NameTypeId == KnownNameTypes.StaffMember)).ToArray()
                                  .Select(_ => new Names
                                  {
                                      Type = _.NameTypeId,
                                      Key = _.Name.Id,
                                      Code = _.Name.NameCode,
                                      DisplayName = _.Name.Formatted()
                                  });

            return names;
        }

        public IEnumerable<Names> RelationshipDetails(int caseId, string nameTypeCode, string relationshipCode)
        {
            if (string.IsNullOrEmpty(nameTypeCode)) throw new ArgumentNullException(nameof(nameTypeCode));
            if (string.IsNullOrEmpty(relationshipCode)) throw new ArgumentNullException(nameof(relationshipCode));

            var nameIds = _dbContext.Set<CaseName>().Where(_ => _.CaseId == caseId && _.NameTypeId == nameTypeCode)
                                    .Select(_ => _.NameId);
            var associatedNames = _dbContext.Set<AssociatedName>().Where(_ => nameIds.Contains(_.Name.Id) && _.Relationship == relationshipCode).ToArray()
                                            .Select(_ => new Names
                                            {
                                                Type = "Relationship",
                                                Key = _.RelatedNameId,
                                                Code = _.RelatedName.NameCode,
                                                DisplayName = _.RelatedName.Formatted()
                                            });
            return associatedNames;
        }

        public IEnumerable<ResolveReason> ResolveReasons()
        {
            var culture = _preferredCultureResolver.Resolve();
            var reasons = _dbContext.Set<TableCode>()
                                    .Where(_ => _.TableTypeId == (short)TableTypes.AdHocResolveReason)
                                    .Select(r => new ResolveReason
                                    {
                                        UserCode = r.UserCode,
                                        Description = DbFuncs.GetTranslation(r.Name, null, r.NameTId, culture)
                                    }).AsEnumerable();
            return reasons;
        }

        public async Task<dynamic> MaintainAdhocDate(int alertId, AdhocSaveDetails maintainAdhocDetails)
        {
            if (maintainAdhocDetails == null)
            {
                throw new ArgumentNullException(nameof(maintainAdhocDetails));
            }

            var alert = _dbContext.Set<AlertRule>()
                                  .SingleOrDefault(_ => _.Id == alertId);
            if (alert == null)
            {
                throw new InvalidDataException(nameof(alert));
            }

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                alert.StaffId = maintainAdhocDetails.EmployeeNo;
                alert.CaseId = maintainAdhocDetails.CaseId;
                alert.NameId = maintainAdhocDetails.NameNo;
                alert.AlertMessage = maintainAdhocDetails.AlertMessage;
                alert.Reference = maintainAdhocDetails.Reference;
                alert.DueDate = maintainAdhocDetails.DueDate;
                alert.DeleteDate = maintainAdhocDetails.DeleteOn;
                alert.Importance = maintainAdhocDetails.ImportanceLevel;
                alert.TriggerEventNo = maintainAdhocDetails.EventNo;
                alert.StopReminderDate = maintainAdhocDetails.StopReminderDate;
                alert.MonthlyFrequency = maintainAdhocDetails.MonthlyFrequency;
                alert.DailyFrequency = maintainAdhocDetails.DailyFrequency;
                alert.MonthsLead = maintainAdhocDetails.MonthsLead;
                alert.DaysLead = maintainAdhocDetails.DaysLead;
                alert.EmployeeFlag = maintainAdhocDetails.EmployeeFlag;
                alert.SignatoryFlag = maintainAdhocDetails.SignatoryFlag;
                alert.CriticalFlag = maintainAdhocDetails.CriticalFlag;
                alert.NameTypeId = maintainAdhocDetails.NameTypeId;
                alert.Relationship = maintainAdhocDetails.Relationship;
                alert.SendElectronically = maintainAdhocDetails.SendElectronically;
                alert.EmailSubject = maintainAdhocDetails.SendElectronically == 1 ? maintainAdhocDetails.EmailSubject : null;
                alert.DateOccurred = maintainAdhocDetails.DateOccurred;
                alert.OccurredFlag = maintainAdhocDetails.DateOccurred != null && !maintainAdhocDetails.UserCode.HasValue ? 3 : maintainAdhocDetails.UserCode;

                await _dbContext.SaveChangesAsync();

                if (!maintainAdhocDetails.IsNoReminder)
                {
                    var batchNo = _policingEngine.CreateBatch();

                    _policingEngine.PoliceAdHocDates(alert, batchNo);

                    await _policingEngine.PoliceWithoutTransaction(batchNo);
                }

                t.Complete();
            }

            await _reminderManager.MarkAsReadOrUnread(new ReminderReadUnReadRequest { TaskPlannerRowKeys = new[] { maintainAdhocDetails.TaskPlannerRowKey }, IsRead = true });

            return new
            {
                Status = ReminderActionStatus.Success
            };
        }

        async Task<bool> EvaluateDeleteAccess(int? alertId)
        {
            if (!alertId.HasValue)
            {
                return false;
            }

            var canDeleteAdHocPermission = _taskSecurityProvider
                .HasAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Delete);

            var adHocResponsibleName = _dbContext.Set<AlertRule>().Single(_ => _.Id == alertId).StaffId;
            var userAuthorizedForDelete = _securityContext.User.Name.Id.Equals(adHocResponsibleName) ||
                                          await _functionSecurityProvider.FunctionSecurityFor(BusinessFunction.Reminder,
                                                                                              FunctionSecurityPrivilege.CanDelete,
                                                                                              _securityContext.User,
                                                                                              adHocResponsibleName);

            return canDeleteAdHocPermission && userAuthorizedForDelete;
        }

        int GetSequenceNo(IEnumerable<int> employeeNos, AdhocSaveDetails adhocSaveDetails)
        {
            int sequenceNo;
            var caseId = adhocSaveDetails.CaseId;
            sequenceNo = 0;
            if (caseId != null)
            {
                var caseNames = from c in _dbContext.Set<AlertRule>()
                                join cn in _dbContext.Set<CaseName>() on c.CaseId equals cn.CaseId into cna
                                from cn in cna.DefaultIfEmpty()
                                where cn.CaseId == caseId
                                      && (cn.NameTypeId == KnownNameTypes.Signatory && adhocSaveDetails.SignatoryFlag
                                          || cn.NameTypeId == KnownNameTypes.StaffMember && adhocSaveDetails.EmployeeFlag
                                          || cn.NameTypeId == c.NameTypeId)
                                select cn.NameId;

                caseNames.ToList().AddRange(employeeNos);
                var entries = _dbContext.Set<AlertRule>().Where(_ => caseNames.Contains(_.StaffId));
                sequenceNo = !entries.Any() ? 0 : entries.Max(_ => _.SequenceNo) + 1;
            }
            else
            {
                var record = _dbContext.Set<AlertRule>().Where(_ => _.StaffId == employeeNos.FirstOrDefault());
                if (record.Any())
                {
                    sequenceNo = record.Max(_ => _.SequenceNo) + 1;
                }
            }

            return sequenceNo;
        }

        List<AlertRule> SaveAdhocDates(AdhocSaveDetails[] adhocSaveDetails, int sequenceNo)
        {
            var adhocEntities = new List<AlertRule>();
            var now = _clock();
            foreach (var adhoc in adhocSaveDetails)
            {
                var adHocEntity = new AlertRule
                {
                    StaffId = adhoc.EmployeeNo,
                    CaseId = adhoc.CaseId,
                    NameId = adhoc.NameNo,
                    AlertMessage = adhoc.AlertMessage,
                    Reference = adhoc.Reference,
                    DueDate = adhoc.DueDate,
                    DeleteDate = adhoc.DeleteOn,
                    Importance = adhoc.ImportanceLevel,
                    TriggerEventNo = adhoc.EventNo,
                    DateCreated = Date(now, adhoc.EmployeeNo),
                    SequenceNo = sequenceNo,
                    StopReminderDate = adhoc.StopReminderDate,
                    MonthlyFrequency = adhoc.MonthlyFrequency,
                    DailyFrequency = adhoc.DailyFrequency,
                    MonthsLead = adhoc.MonthsLead,
                    DaysLead = adhoc.DaysLead,
                    EmployeeFlag = adhoc.EmployeeFlag,
                    SignatoryFlag = adhoc.SignatoryFlag,
                    CriticalFlag = adhoc.CriticalFlag,
                    NameTypeId = adhoc.NameTypeId,
                    Relationship = adhoc.Relationship,
                    SendElectronically = adhoc.SendElectronically,
                    EmailSubject = adhoc.SendElectronically == 1 ? adhoc.EmailSubject : null
                };

                adhocEntities.Add(adHocEntity);
            }

            return adhocEntities;
        }

        string Reference(AlertRule alert)
        {
            if (alert.CaseId.HasValue)
            {
                return alert.Case.Irn;
            }

            if (alert.NameId.HasValue)
            {
                return alert.Name.Formatted();
            }

            return alert.Reference;
        }

        AdhocReference AdhocReference(AlertRule alert)
        {
            var reference = new AdhocReference();

            if (alert.CaseId.HasValue)
            {
                reference.Case = new Case
                {
                    Key = alert.Case.Id,
                    Code = alert.Case.Irn,
                    Value = alert.Case.Title
                };

                return reference;
            }

            if (alert.NameId.HasValue)
            {
                reference.Name = new Name
                {
                    Key = alert.Name.Id,
                    Code = alert.Name.NameCode,
                    DisplayName = alert.Name.Formatted()
                };

                return reference;
            }

            reference.General = alert.Reference;
            return reference;
        }

        string AdhocType(AlertRule alert)
        {
            if (alert.CaseId.HasValue)
            {
                return "case";
            }

            if (alert.NameId.HasValue)
            {
                return "name";
            }

            return "general";
        }

        DateTime Date(DateTime now, int staffId)
        {
            var exists = _dbContext.Set<AlertRule>().Where(_ => _.StaffId == staffId && _.DateCreated == now);
            if (exists.Any())
            {
                return now.AddMilliseconds(3);
            }

            return now;
        }

        async Task<dynamic> RowSelections(BulkFinaliseRequestModel bulkFinaliseRequestModel)
        {
            var reminderActionRequest = new ReminderActionRequest
            {
                SearchRequestParams = bulkFinaliseRequestModel.SearchRequestParams,
                TaskPlannerRowKeys = bulkFinaliseRequestModel.SelectedTaskPlannerRowKeys
            };

            var allSelection = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(reminderActionRequest);

            var rowKeysToProcess = allSelection.Where(_ => _.StartsWith("A")).ToArray();
            var unprocessedRowKeys = allSelection.Except(rowKeysToProcess).ToArray();

            return new
            {
                allSelection,
                rowKeysToProcess,
                unprocessedRowKeys
            };
        }

        bool RequiresPolicing(FinaliseRequestModel adHocDate, AlertRule oldAdHocDate, decimal? resolveReason = null)
        {
            if (adHocDate.DateOccured != oldAdHocDate.DateOccurred)
            {
                return true;
            }

            if (resolveReason.GetValueOrDefault(0) != oldAdHocDate.OccurredFlag.GetValueOrDefault(0))
            {
                return true;
            }

            return false;
        }
    }

    public class Names
    {
        public string Type { get; set; }
        public int Key { get; set; }
        public string Code { get; set; }
        public string DisplayName { get; set; }
    }

    public class AdHocDatePayload
    {
        public long AlertId { get; set; }
        public string Type { get; set; }
        public string AdHocDateFor { get; set; }
        public IEnumerable<ResolveReason> ResolveReasons { get; set; }
        public int EmployeeNo { get; set; }
        public int? CaseId { get; set; }
        public string Message { get; set; }
        public string FinaliseReference { get; set; }
        public AdhocReference Reference { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? DateOccurred { get; set; }
        public string ResolveReason { get; set; }
        public DateTime? DeleteOn { get; set; }
        public DateTime? EndOn { get; set; }
        public short? MonthlyFrequency { get; set; }
        public short? MonthsLead { get; set; }
        public short? DailyFrequency { get; set; }
        public short? DaysLead { get; set; }
        public decimal? SendElectronically { get; set; }
        public string EmailSubject { get; set; }
        public Event Event { get; set; }
        public dynamic ImportanceLevel { get; set; }
        public int? NameNo { get; set; }
        public bool EmployeeFlag { get; set; }
        public bool SignatoryFlag { get; set; }
        public bool CriticalFlag { get; set; }
        public dynamic RelationshipValue { get; set; }
        public dynamic AdhocResponsibleName { get; set; }
        public dynamic NameTypeValue { get; set; }
    }

    public class BaseRequestModel
    {
        public decimal? UserCode { get; set; }
        public DateTime? DateOccured { get; set; }
    }

    public class FinaliseRequestModel : BaseRequestModel
    {
        public string TaskPlannerRowKey { get; set; }
        public long AlertId { get; set; }
    }

    public class BulkFinaliseRequestModel : BaseRequestModel
    {
        public string[] SelectedTaskPlannerRowKeys { get; set; }
        public SavedSearchRequestParams<TaskPlannerRequestFilter> SearchRequestParams { get; set; }
    }

    public class ResolveReason
    {
        public string UserCode { get; set; }
        public string Description { get; set; }
    }

    public class AdhocSaveDetails
    {
        public string TaskPlannerRowKey { get; set; }
        public int EmployeeNo { get; set; }
        public int? CaseId { get; set; }
        public int? NameNo { get; set; }
        public int? EventNo { get; set; }
        public string ImportanceLevel { get; set; }
        public string Reference { get; set; }
        public string AlertMessage { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? DeleteOn { get; set; }
        public DateTime? StopReminderDate { get; set; }
        public bool IsNoReminder { get; set; }
        public short? DaysLead { get; set; }
        public short? DailyFrequency { get; set; }
        public short? MonthsLead { get; set; }
        public short? MonthlyFrequency { get; set; }
        public string Relationship { get; set; }
        public decimal SendElectronically { get; set; }
        public bool EmployeeFlag { get; set; }
        public bool SignatoryFlag { get; set; }
        public bool CriticalFlag { get; set; }
        public string NameTypeId { get; set; }
        public string EmailSubject { get; set; }
        public DateTime? DateOccurred { get; set; }
        public decimal? UserCode { get; set; }
    }

    public class AdhocReference
    {
        public Case Case { get; set; }
        public Name Name { get; set; }
        public string General { get; set; }
    }
}