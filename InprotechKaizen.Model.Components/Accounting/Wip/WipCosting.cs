using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Security;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipCosting : IWipCosting
    {
        readonly IGetWipCostCommand _getWipCostCommand;
        readonly ISecurityContext _securityContext;

        public WipCosting(ISecurityContext securityContext, IGetWipCostCommand getWipCostCommand)
        {
            _securityContext = securityContext;
            _getWipCostCommand = getWipCostCommand;
        }

        public async Task<WipCost> For(RecordableTime time, int? userId = null)
        {
            return await _getWipCostCommand.GetWipCost(userId ?? _securityContext.User.Id, ConvertToWipCost(time));
        }

        public async Task<WipCost> For(UnpostedWip wip)
        {
            return await _getWipCostCommand.GetWipCost(_securityContext.User.Id, ConvertToWipCost(wip));
        }

        public async Task<T> For<T>(T costableTime) where T : WipCost, new()
        {
            return await _getWipCostCommand.GetWipCost(_securityContext.User.Id, costableTime);
        }

        WipCost ConvertToWipCost(RecordableTime time)
        {
            var hours = TimeSpan.FromTicks((time.TotalTime.GetValueOrDefault().TimeOfDay + time.TimeCarriedForward.GetValueOrDefault().TimeOfDay).Ticks);
            return new WipCost
            {
                TransactionDate = time.EntryDate,
                StaffKey = time.StaffId.GetValueOrDefault(),
                NameKey = time.NameKey,
                CaseKey = time.CaseKey,
                WipCode = time.Activity,
                Hours = new DateTime(1899, 1, 1).Add(hours),
                TimeUnits = hours == TimeSpan.Zero ? time.TotalUnits : null,
                SplitTimeByDebtor = time.IsSplitDebtorWip,
                IsMarginRequired = true,
                DebtorNameTypeKey = time.DebtorNameTypeKey
            };
        }

        WipCost ConvertToWipCost(UnpostedWip wip)
        {
            return new()
            {
                TransactionDate = wip.TransactionDate,
                EntityKey = wip.EntityKey,
                StaffKey = wip.StaffKey,
                NameKey = wip.NameKey,
                CaseKey = wip.CaseKey,
                DebtorNameTypeKey = wip.DebtorNameTypeKey,
                WipCode = wip.WipCode,
                ProductKey = wip.ProductCode,
                IsChargeGeneration = false,
                IsServiceCharge = wip.IsServiceCharge(),
                UseSuppliedValues = wip.ShouldUseSuppliedValues,
                LocalValueBeforeMargin = wip.LocalCost,
                ForeignValueBeforeMargin = wip.ForeignCost,
                IsMarginRequired = true,
                ActionKey = wip.ActionKey,
                SplitTimeByDebtor = wip.IsSplitTimeByDebtor(),
                TimeUnits = wip.TotalUnits,
                CurrencyCode = wip.ForeignCost == null && wip.LocalCost != null
                    ? null
                    : wip.ForeignCurrency,
                SeparateMarginMode = wip.IsSeparateMargin
            };
        }
    }

    public interface IWipCosting
    {
        Task<WipCost> For(RecordableTime time, int? userId = null);
        Task<T> For<T>(T time) where T : WipCost, new();
        Task<WipCost> For(UnpostedWip wip);
    }
}