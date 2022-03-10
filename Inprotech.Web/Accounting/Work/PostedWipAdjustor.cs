using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Z.EntityFramework.Plus;

namespace Inprotech.Web.Accounting.Work
{
    public interface IPostedWipAdjustor
    {
        Task<WipAdjustOrSplitResult> TransferWip(IEnumerable<WorkInProgress> wipItemsToAdjust, RecordableTime time, TransactionType transactionType);
        Task<WipAdjustOrSplitResult> AdjustWipBatch(IEnumerable<WorkInProgress> wipItemsToAdjust, TimeEntry updatedTime, TimeEntry originalTime);
        Task AdjustPostedEntryDate(TimeEntry updatedTime);
        Task<WipAdjustOrSplitResult> AdjustWipBatchToZero(IEnumerable<WorkInProgress> wipItemsToAdjust);
    }

    public class PostedWipAdjustor : IPostedWipAdjustor
    {
        readonly IAdjustWipCommand _adjustWipCommand;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControl;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _today;

        public PostedWipAdjustor(IAdjustWipCommand adjustWipCommand, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControl, IFunctionSecurityProvider functionSecurity, IDbContext dbContext, Func<DateTime> today)
        {
            _adjustWipCommand = adjustWipCommand;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControl = siteControl;
            _functionSecurity = functionSecurity;
            _dbContext = dbContext;
            _today = today;
        }

        public async Task<WipAdjustOrSplitResult> TransferWip(IEnumerable<WorkInProgress> wipItemsToAdjust, RecordableTime time, TransactionType transactionType)
        {
            var staffNameId = time.StaffId ?? _securityContext.User.NameId;
            var culture = _preferredCultureResolver.Resolve();
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var result = new WipAdjustOrSplitResult();
            var workInProgresses = wipItemsToAdjust as WorkInProgress[] ?? wipItemsToAdjust.ToArray();
            var discountWip = workInProgresses.FirstOrDefault(v => !v.WipIsMargin() && v.WipIsDiscount());
            var mainWip = workInProgresses.FirstOrDefault(v => !v.WipIsMargin() && !v.WipIsDiscount());

            if (mainWip != null)
            {
                var mainAdjustment = new AdjustWipItem
                {
                    EntityKey = mainWip.EntityId,
                    TransKey = mainWip.TransactionId,
                    WipSeqNo = mainWip.WipSequenceNo,
                    RequestedByStaffKey = _securityContext.User.NameId,
                    AdjustmentType = (int) transactionType,
                    NewTotalTime = TimeSpan.Zero,
                    NewNarrativeKey = time.NarrativeNo,
                    NewDebitNoteText = time.NarrativeText,
                    TransDate = _today(),
                    LogDateTimeStamp = mainWip.LogDateTimeStamp,
                    ReasonCode = KnownAccountingReason.IncorrectTimeEntry
                };

                switch (transactionType)
                {
                    case TransactionType.ActivityWipTransfer:
                        mainAdjustment.NewActivityCode = time.Activity;
                        break;
                    case TransactionType.CaseWipTransfer:
                        mainAdjustment.NewCaseKey = time.CaseKey;
                        break;
                }

                result = await _adjustWipCommand.SaveAdjustment(_securityContext.User.Id, culture, mainAdjustment);
            }

            if (discountWip != null)
            {
                var discountAdjustment = new AdjustWipItem
                {
                    EntityKey = discountWip.EntityId,
                    TransKey = discountWip.TransactionId,
                    WipSeqNo = discountWip.WipSequenceNo,
                    RequestedByStaffKey = _securityContext.User.NameId,
                    AdjustmentType = (int) transactionType,
                    NewTotalTime = TimeSpan.Zero,
                    NewTransKey = result.NewTransKey,
                    TransDate = _today(),
                    LogDateTimeStamp = discountWip.LogDateTimeStamp,
                    ReasonCode = KnownAccountingReason.IncorrectTimeEntry
                };
                switch (transactionType)
                {
                    case TransactionType.ActivityWipTransfer:
                        discountAdjustment.NewActivityCode = _siteControl.Read<string>(SiteControls.DiscountWIPCode) ?? time.Activity;
                        break;
                    case TransactionType.CaseWipTransfer:
                        discountAdjustment.NewCaseKey = time.CaseKey;
                        break;
                }

                result = await _adjustWipCommand.SaveAdjustment(_securityContext.User.Id, culture, discountAdjustment);
            }

            return result;
        }

        public async Task<WipAdjustOrSplitResult> AdjustWipBatch(IEnumerable<WorkInProgress> wipItemsToAdjust, TimeEntry updatedTime, TimeEntry originalTime)
        {
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User, updatedTime.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var culture = _preferredCultureResolver.Resolve();

            var result = new WipAdjustOrSplitResult();
            foreach (var w in wipItemsToAdjust)
            {
                if (RequiresWipAdjustment(w, originalTime, updatedTime.LocalValue, updatedTime.LocalDiscount))
                {
                    var adjustWipItem = new AdjustWipItem
                    {
                        EntityKey = w.EntityId,
                        TransKey = w.TransactionId,
                        WipSeqNo = w.WipSequenceNo,
                        RequestedByStaffKey = _securityContext.User.NameId,
                        TransDate = _today(),
                        AdjustmentType = w.WipIsDiscount()
                            ? w.Balance > (updatedTime.LocalDiscount * -1)
                                ? (int) TransactionType.CreditWipAdjustment
                                : (int) TransactionType.DebitWipAdjustment
                            : w.Balance > updatedTime.LocalValue
                                ? (int) TransactionType.CreditWipAdjustment
                                : (int) TransactionType.DebitWipAdjustment,
                        NewLocal = w.WipIsDiscount() ? updatedTime.LocalDiscount * -1 : updatedTime.LocalValue,
                        NewForeign = w.WipIsDiscount() ? updatedTime.ForeignDiscount * -1 : updatedTime.ForeignValue,
                        NewTotalTime = w.WipIsDiscount() ? TimeSpan.Zero : updatedTime.TotalTime.GetValueOrDefault().TimeOfDay + updatedTime.TimeCarriedForward.GetValueOrDefault().TimeOfDay,
                        NewTotalUnits = w.WipIsDiscount() ? null : (int?) updatedTime.TotalUnits,
                        NewChargeRate = w.WipIsDiscount() ? null : updatedTime.ChargeOutRate,
                        NewNarrativeKey = w.WipIsDiscount() ? null : updatedTime.NarrativeNo,
                        NewDebitNoteText = w.WipIsDiscount() ? null : updatedTime.NarrativeText,
                        IsAdjustToZero = false,
                        ReasonCode = KnownAccountingReason.IncorrectTimeEntry,
                        LogDateTimeStamp = w.LogDateTimeStamp
                    };
                    result = await _adjustWipCommand.SaveAdjustment(_securityContext.User.Id, culture, adjustWipItem);
                }
                else if ((w.NarrativeId != updatedTime.NarrativeNo || (w.LongNarrative ?? w.ShortNarrative) != updatedTime.NarrativeText) && !w.WipIsDiscount() && !w.WipIsMargin())
                {
                    var adjustWipItem = new AdjustWipItem
                    {
                        EntityKey = w.EntityId,
                        TransKey = w.TransactionId,
                        WipSeqNo = w.WipSequenceNo,
                        RequestedByStaffKey = _securityContext.User.NameId,
                        NewTotalTime = TimeSpan.Zero,
                        NewNarrativeKey = updatedTime.NarrativeNo,
                        NewDebitNoteText = updatedTime.NarrativeText,
                        IsAdjustToZero = false,
                        ReasonCode = KnownAccountingReason.IncorrectTimeEntry,
                        LogDateTimeStamp = w.LogDateTimeStamp,
                        TransDate = _today()
                    };
                    result = await _adjustWipCommand.SaveAdjustment(_securityContext.User.Id, culture, adjustWipItem);
                }
            }

            return result;
        }

        public async Task AdjustPostedEntryDate(TimeEntry updateEntry)
        {
            var newDate = updateEntry.StartTime.GetValueOrDefault().Date;

            await _dbContext.Set<WorkInProgress>().Where(_ => _.EntityId == updateEntry.WipEntityNo && _.TransactionId == updateEntry.TransNo).UpdateAsync(_ => new WorkInProgress {TransactionDate = newDate});

            await _dbContext.Set<WorkHistory>().Where(_ => _.EntityId == updateEntry.WipEntityNo && _.TransactionId == updateEntry.TransNo).UpdateAsync(_ => new WorkHistory {TransDate = newDate});
        }

        public async Task<WipAdjustOrSplitResult> AdjustWipBatchToZero(IEnumerable<WorkInProgress> wipItemsToAdjust)
        {
            var culture = _preferredCultureResolver.Resolve();
            var result = new WipAdjustOrSplitResult();
            foreach (var w in wipItemsToAdjust)
            {
                var adjustWipItem = new AdjustWipItem
                {
                    EntityKey = w.EntityId,
                    TransKey = w.TransactionId,
                    WipSeqNo = w.WipSequenceNo,
                    RequestedByStaffKey = _securityContext.User.NameId,
                    AdjustmentType = w.Balance > 0 
                        ? (int) TransactionType.CreditWipAdjustment 
                        : (int) TransactionType.DebitWipAdjustment,
                    NewLocal = 0,
                    NewForeign = 0,
                    NewTotalTime = TimeSpan.Zero,
                    NewTotalUnits = w.WipIsDiscount() ? (int?) null : 0,
                    ReasonCode = KnownAccountingReason.IncorrectTimeEntry,
                    LogDateTimeStamp = w.LogDateTimeStamp,
                    IsAdjustToZero = !w.WipIsDiscount(),
                    TransDate = _today()
                };
                result = await _adjustWipCommand.SaveAdjustment(_securityContext.User.Id, culture, adjustWipItem);
            }
            return result;
        }

        static bool RequiresWipAdjustment(WorkInProgress work, TimeEntry time, decimal? newValue, decimal? newDiscount)
        {
            return (work.WipIsDiscount() && (work.Balance != newDiscount * -1)) ||
                   (!work.WipIsDiscount() &&
                    (time.TotalTime.GetValueOrDefault().TimeOfDay != work.TotalTime.GetValueOrDefault().TimeOfDay ||
                     time.TotalUnits != work.TotalUnits ||
                     newValue != work.Balance));
        }
    }
}