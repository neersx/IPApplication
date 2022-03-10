using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using AutoMapper;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using TransactionStatus = InprotechKaizen.Model.Accounting.TransactionStatus;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/posted-time")]
    public class PostedTimeController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPostedWipAdjustor _postedWipAdjustor;
        readonly IDiaryUpdate _diaryUpdate;
        readonly IMapper _mapper;
        readonly IValidatePostDates _validatePostDates;
        readonly IWipStatusEvaluator _wipStatusEvaluator;
        readonly ISecurityContext _securityContext;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly ITimesheetList _timesheetList;

        public PostedTimeController(IDbContext dbContext,
                                    IPostedWipAdjustor postedWipAdjustor,
                                    IDiaryUpdate diaryUpdate,
                                    IMapper mapper,
                                    IValidatePostDates validatePostDates,
                                    IWipStatusEvaluator wipStatusEvaluator,
                                    ISecurityContext securityContext,
                                    IFunctionSecurityProvider functionSecurity,
                                    ITimesheetList timesheetList)
        {
            _dbContext = dbContext;
            _postedWipAdjustor = postedWipAdjustor;
            _diaryUpdate = diaryUpdate;
            _mapper = mapper;
            _validatePostDates = validatePostDates;
            _wipStatusEvaluator = wipStatusEvaluator;
            _securityContext = securityContext;
            _functionSecurity = functionSecurity;
            _timesheetList = timesheetList;
        }

        async Task<(bool isValid, ApplicationAlert error)> ValidateRequest(PostedTime time)
        {
            var wipStatusCheckResult = await _wipStatusEvaluator.GetWipStatus(time.EntryNo.GetValueOrDefault(), time.StaffId.GetValueOrDefault());

            if (wipStatusCheckResult != WipStatusEnum.Editable)
                return (false, new ApplicationAlert {AlertID = (wipStatusCheckResult == WipStatusEnum.Billed) ? KnownWipStatusErrors.Billed : KnownWipStatusErrors.Locked});

            var result = await _validatePostDates.For(time.EntryDate);
            if (!result.isValid && result.code != KnownErrors.ItemPostedToDifferentPeriod)
                return (false, new ApplicationAlert {AlertID = result.code});

            return (true, null);
        }

        [HttpPut]
        [Route("updateDate")]
        [RequiresAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Modify)]
        [RequiresCaseAuthorization(PropertyPath = "time.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "time.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> ChangeEntryDate([FromBody] PostedTime time)
        {
            var (isValid, error) = await ValidateRequest(time);
            if (!isValid)
            {
                return new
                {
                    Error = error
                };
            }

            var originalTime = _dbContext.Set<Diary>().Include(_ => _.DebtorSplits).AsNoTracking().Single(v => v.EmployeeNo == time.StaffId && v.EntryNo == time.EntryNo);
            if (originalTime == null || originalTime.DebtorSplits?.Count > 0)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == originalTime.WipEntityId && w.TransactionId == originalTime.TransactionId && w.Status == TransactionStatus.Active).ToList();

            var adjustTimeResult = await PerformWipAdjustment(wipItemsToAdjust, time, originalTime, true);

            return new
            {
                Response = new {adjustTimeResult.EntryNo}
            };
        }

        [HttpPut]
        [Route("update")]
        [RequiresAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Modify)]
        [RequiresCaseAuthorization(PropertyPath = "time.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "time.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> UpdatePostedTime([FromBody] PostedTime time)
        {
            var (isValid, error) = await ValidateRequest(time);
            if (!isValid)
            {
                return new
                {
                    Error = error
                };
            }

            time.StaffId ??= _securityContext.User.NameId;

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, time.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var originalTime = _dbContext.Set<Diary>().Include(_ => _.DebtorSplits).AsNoTracking().Single(v => v.EmployeeNo == time.StaffId && v.EntryNo == time.EntryNo);
            if (originalTime == null || originalTime.DebtorSplits?.Count > 0)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (originalTime.CaseId == null && time.CaseKey != null || originalTime.CaseId != null && time.CaseKey == null || time.CaseKey == null && originalTime.NameNo != time.NameKey)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == originalTime.WipEntityId && w.TransactionId == originalTime.TransactionId && w.Status == TransactionStatus.Active).ToList();
            var hasTransferrableWip = wipItemsToAdjust.Any();            
            
            WipAdjustOrSplitResult wipTransferOrSplitResult = null;
            if (time.CaseKey != originalTime.CaseId)
            {
                if (!hasTransferrableWip)
                {
                    return new
                    {
                        Error = new ApplicationAlert {AlertID = "NoWipToTransfer"}
                    };
                }
                wipTransferOrSplitResult = await PerformWipTransfer(wipItemsToAdjust, time, TransactionType.CaseWipTransfer);
                if (wipTransferOrSplitResult.Error != null)
                    return wipTransferOrSplitResult;
            }

            if (wipTransferOrSplitResult?.NewTransKey != null)
                wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == originalTime.WipEntityId && w.TransactionId == wipTransferOrSplitResult.NewTransKey && w.Status == TransactionStatus.Active).ToList();

            if (time.Activity != originalTime.Activity)
            {
                if (!hasTransferrableWip)
                {
                    return new
                    {
                        Error = new ApplicationAlert {AlertID = "NoWipToTransfer"}
                    };
                }
                wipTransferOrSplitResult = await PerformWipTransfer(wipItemsToAdjust, time, TransactionType.ActivityWipTransfer);
                if (wipTransferOrSplitResult.Error != null)
                    return wipTransferOrSplitResult;
            }

            if (wipTransferOrSplitResult?.NewTransKey != null)
                wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == originalTime.WipEntityId && w.TransactionId == wipTransferOrSplitResult.NewTransKey && w.Status == TransactionStatus.Active).ToList();

            originalTime.TransactionId = wipTransferOrSplitResult?.NewTransKey ?? originalTime.TransactionId;
            var adjustTimeResult = await PerformWipAdjustment(wipItemsToAdjust, time, originalTime);

            return new
            {
                Response = new {adjustTimeResult.EntryNo}
            };
        }

        async Task<WipAdjustOrSplitResult> PerformWipTransfer(IEnumerable<WorkInProgress> wipItemsToAdjust, RecordableTime time, TransactionType transactionType)
        {
            WipAdjustOrSplitResult adjustOrSplitResult;
            TimeEntry result;

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                adjustOrSplitResult = await _postedWipAdjustor.TransferWip(wipItemsToAdjust, time, transactionType);
                result = await _diaryUpdate.UpdateEntry(time, adjustOrSplitResult.NewTransKey);

                if (result.DebtorSplits?.Count > 0)
                    return new WipAdjustOrSplitResult {Error = "ConversionToMultiDebor"};

                tsc.Complete();
            }

            return new WipAdjustOrSplitResult
            {
                EntryNo = result.EntryNo,
                NewTransKey = adjustOrSplitResult.NewTransKey
            };
        }

        async Task<dynamic> PerformWipAdjustment(IEnumerable<WorkInProgress> wipItemsToAdjust, RecordableTime time, Diary originalTime, bool isDateChange = false)
        {
            TimeEntry updatedTime;
            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                updatedTime = await _diaryUpdate.UpdateEntry(time, originalTime.TransactionId);
                await _postedWipAdjustor.AdjustWipBatch(wipItemsToAdjust, updatedTime, _mapper.Map<Diary, TimeEntry>(originalTime));

                if (isDateChange)
                {
                    await _postedWipAdjustor.AdjustPostedEntryDate(updatedTime);
                }

                tsc.Complete();
            }

            return new WipAdjustOrSplitResult
            {
                EntryNo = updatedTime.EntryNo
            };
        }

        [HttpGet]
        [Route("openPeriods")]
        public async Task<IEnumerable<dynamic>> GetOpenPeriod()
        {
            return await _validatePostDates.GetOpenPeriodsFor(periodsBefore: DateTime.Today);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Delete)]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> DeletePostedTime([FromBody] PostedTime timeEntry)
        {
            if (timeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var wipStatusCheckResult = await _wipStatusEvaluator.GetWipStatus(timeEntry.EntryNo.GetValueOrDefault(), timeEntry.StaffId.GetValueOrDefault());
            if (wipStatusCheckResult != WipStatusEnum.Editable)
            {
                return new
                {
                    Error = new ApplicationAlert {AlertID = (wipStatusCheckResult == WipStatusEnum.Billed) ? KnownWipStatusErrors.Billed : KnownWipStatusErrors.Locked}
                };
            }

            var staffNameId = timeEntry.StaffId ?? _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            WipAdjustOrSplitResult adjustOrSplitResult;
            var entry = _dbContext.Set<Diary>().Include(_ => _.DebtorSplits).SingleOrDefault(_ => _.EmployeeNo == staffNameId && _.EntryNo == timeEntry.EntryNo && _.WipEntityId != null && _.TransactionId != null);
            if (entry == null || entry.DebtorSplits?.Count > 0)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                _dbContext.Set<Diary>().Remove(entry);
                await _dbContext.SaveChangesAsync();

                var wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == entry.WipEntityId && w.TransactionId == entry.TransactionId && w.Status == TransactionStatus.Active).ToList();
                adjustOrSplitResult = await _postedWipAdjustor.AdjustWipBatchToZero(wipItemsToAdjust);
                tsc.Complete();
            }

            return new
            {
                Response = adjustOrSplitResult.EntryNo
            };
        }

        [HttpDelete]
        [Route("delete-from-chain")]
        [RequiresAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Delete)]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> DeletePostedTimeFromChain([FromBody] PostedTime timeEntry) => await DeletePostedTimeForContinuedEntries(timeEntry, false);

        [HttpDelete]
        [Route("delete-chain")]
        [RequiresAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Delete)]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> DeletePostedTimeChain([FromBody] PostedTime timeEntry) => await DeletePostedTimeForContinuedEntries(timeEntry, true);

        async Task<dynamic> DeletePostedTimeForContinuedEntries(PostedTime timeEntry, bool deleteWholeChain)
        {
            if (timeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var staffNameId = timeEntry.StaffId ?? _securityContext.User.NameId;
            var continuedChain = (await _timesheetList.GetWholeChainFor(staffNameId, timeEntry.EntryNo.Value, timeEntry.EntryDate.Date)).ToList();
            var lastChild = continuedChain.First();

            if (lastChild == null || lastChild.DebtorSplits?.Count > 0)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var wipStatusCheckResult = await _wipStatusEvaluator.GetWipStatus(lastChild.EntryNo, timeEntry.StaffId.GetValueOrDefault());
            if (wipStatusCheckResult != WipStatusEnum.Editable)
            {
                return new
                {
                    Error = new ApplicationAlert {AlertID = (wipStatusCheckResult == WipStatusEnum.Billed) ? KnownWipStatusErrors.Billed : KnownWipStatusErrors.Locked}
                };
            }

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            return new
            {
                Response = deleteWholeChain 
                    ? await PerformWipDeleteForChain(staffNameId, continuedChain) 
                    : await PerformWipAdjustmentForChain(continuedChain, timeEntry)
            };
        }

        async Task<dynamic> PerformWipAdjustmentForChain(IEnumerable<Diary> continuedChain, RecordableTime timeEntry)
        {
            WipAdjustOrSplitResult adjustOrSplitResult;
            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                var updatedEntries = await _diaryUpdate.RemoveEntryFromChain(continuedChain, timeEntry);

                var wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == updatedEntries.newLastChild.WipEntityId && w.TransactionId == updatedEntries.newLastChild.TransactionId && w.Status == TransactionStatus.Active).ToList();
                adjustOrSplitResult = await _postedWipAdjustor.AdjustWipBatch(wipItemsToAdjust, _mapper.Map<TimeEntry>(updatedEntries.newLastChild), _mapper.Map<TimeEntry>(updatedEntries.diaryToRemove));

                tsc.Complete();
            }

            return adjustOrSplitResult;
        }

        async Task<dynamic> PerformWipDeleteForChain(int staffId, IEnumerable<Diary> continuedChainList)
        {
            using var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled);

            var continuedChain = continuedChainList as Diary[] ?? continuedChainList.ToArray();
            var lastChild = continuedChain.ToArray().First();
            await _diaryUpdate.BatchDelete(staffId, continuedChain.Select(_ => _.EntryNo));

            var wipItemsToAdjust = _dbContext.Set<WorkInProgress>().AsNoTracking().Where(w => w.EntityId == lastChild.WipEntityId && w.TransactionId == lastChild.TransactionId && w.Status == TransactionStatus.Active).ToList();
            var adjustOrSplitResult = await _postedWipAdjustor.AdjustWipBatchToZero(wipItemsToAdjust);

            tsc.Complete();

            return adjustOrSplitResult;
        }
    }
}