using System;
using System.Data.Common;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IGetWipCostCommand
    {
        Task<T> GetWipCost<T>(int userIdentityId, T wipCost) where T : WipCost;
    }

    public class GetWipCostCommand : IGetWipCostCommand
    {
        static bool? _hasSeparateMarginFlag;
        readonly IDbContext _dbContext;
        readonly ISqlHelper _sqlHelper;

        public GetWipCostCommand(IDbContext dbContext, ISqlHelper sqlHelper)
        {
            _dbContext = dbContext;
            _sqlHelper = sqlHelper;

            DetectSeparateMarginFlagCompatibility();
        }

        public async Task<T> GetWipCost<T>(int userIdentityId, T wipCost) where T : WipCost
        {
            var result = (T) wipCost.Clone();
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", userIdentityId},
                {"@pdtTransactionDate", result.TransactionDate},
                {"@pnEntityKey", result.EntityKey},
                {"@pnStaffKey", result.StaffKey},
                {"@pnNameKey", result.NameKey},
                {"@pnCaseKey", result.CaseKey},
                {"@psDebtorNameTypeKey", result.DebtorNameTypeKey},
                {"@psWipCode", result.WipCode},
                {"@pnProductKey", result.ProductKey},
                {"@pbIsChargeGeneration", false},
                {"@pbIsServiceCharge", result.IsServiceCharge},
                {"@pbUseSuppliedValues", result.UseSuppliedValues},
                {"@pdtHours", result.Hours},
                {"@pnTimeUnits", result.TimeUnits},
                {"@pnUnitsPerHour", result.UnitsPerHour},
                {"@pnChargeOutRate", result.ChargeOutRate},
                {"@pnLocalValueBeforeMargin", result.LocalValueBeforeMargin},
                {"@pnForeignValueBeforeMargin", result.ForeignValueBeforeMargin},
                {"@psCurrencyCode", result.CurrencyCode},
                {"@pnExchangeRate", result.ExchangeRate},
                {"@pnLocalValue", result.LocalValue},
                {"@pnForeignValue", result.ForeignValue},
                {"@pbMarginRequired", true},
                {"@pnMarginValue", result.MarginValue},
                {"@pnLocalDiscount", result.LocalDiscount},
                {"@pnForeignDiscount", result.ForeignDiscount},
                {"@pnLocalCost1", result.CostCalculation1},
                {"@pnLocalCost2", result.CostCalculation2},
                {"@pnSupplierKey", result.SupplierKey},
                {"@pnStaffClassKey", result.StaffClassKey},
                {"@psActionKey", result.ActionKey},
                {"@pnMarginNo", result.MarginNo},
                {"@pnLocalDiscountForMargin", result.LocalDiscountForMargin},
                {"@pnForeignDiscountForMargin", result.ForeignDiscountForMargin},
                {"@pbSplitTimeByDebtor", result.SplitTimeByDebtor}
            };

            if (_hasSeparateMarginFlag.GetValueOrDefault())
            {
                inputParameters.Add("@pbSeparateMarginMode", result.SeparateMarginMode);
            }

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.WipManagement.GetWipCost, inputParameters);

            await command.ExecuteNonQueryAsync();

            SetOutputToWipCost(result, command);

            return result;
        }

        void DetectSeparateMarginFlagCompatibility()
        {
            if (_hasSeparateMarginFlag != null)
            {
                return;
            }

            var parameters = _sqlHelper.DeriveParameters(StoredProcedures.WipManagement.GetWipCost);
            _hasSeparateMarginFlag = parameters.Any(_ => _.Key == "@pbSeparateMarginMode");
        }

        static void SetOutputToWipCost<T>(T result, DbCommand command) where T : WipCost
        {
            result.Hours = GetDateTimeValue(command.Parameters["@pdtHours"].Value);
            result.TimeUnits = GetShortValue(command.Parameters["@pnTimeUnits"].Value);
            result.UnitsPerHour = GetShortValue(command.Parameters["@pnUnitsPerHour"].Value);
            result.LocalValue = GetDecimalValue(command.Parameters["@pnLocalValue"].Value);
            result.LocalDiscount = GetDecimalValue(command.Parameters["@pnLocalDiscount"].Value);
            result.LocalDiscountForMargin = GetDecimalValue(command.Parameters["@pnLocalDiscountForMargin"].Value);
            result.MarginValue = GetDecimalValue(command.Parameters["@pnMarginValue"].Value);
            result.MarginNo = GetIntValue(command.Parameters["@pnMarginNo"].Value);

            var currencyCode = command.Parameters["@psCurrencyCode"].Value;
            result.CurrencyCode = string.IsNullOrWhiteSpace(currencyCode?.ToString())
                ? null
                : currencyCode.ToString();

            result.ForeignValue = GetDecimalValue(command.Parameters["@pnForeignValue"].Value);
            result.ForeignDiscount = GetDecimalValue(command.Parameters["@pnForeignDiscount"].Value);
            result.ForeignDiscountForMargin = GetDecimalValue(command.Parameters["@pnForeignDiscountForMargin"].Value);
            result.ExchangeRate = GetDecimalValue(command.Parameters["@pnExchangeRate"].Value);

            if (result.ForeignValue.HasValue && !result.ForeignValueBeforeMargin.HasValue)
            {
                result.ForeignValueBeforeMargin = result.ForeignValue - result.MarginValue.GetValueOrDefault();
            }

            if (result.LocalValue.HasValue)
            {
                result.LocalValueBeforeMargin = GetDecimalValue(command.Parameters["@pnLocalValueBeforeMargin"].Value);
                result.CostCalculation1 = GetDecimalValue(command.Parameters["@pnLocalCost1"].Value);
                result.CostCalculation2 = GetDecimalValue(command.Parameters["@pnLocalCost2"].Value);
            }

            var chargeOutRate = command.Parameters["@pnChargeOutRate"].Value;
            var totalUnits = command.Parameters["@pnTimeUnits"].Value;
            if (!Convert.IsDBNull(chargeOutRate) && !Convert.IsDBNull(totalUnits) && Convert.ToInt16(totalUnits) != 0)
            {
                result.ChargeOutRate = GetDecimalValue(chargeOutRate);
            }
        }

        static decimal? GetDecimalValue(object outputValue)
        {
            return Convert.IsDBNull(outputValue) ? null : (decimal?) outputValue;
        }

        static int? GetIntValue(object outputValue)
        {
            return int.TryParse(outputValue.ToString(), out var intValue) ? intValue : null;
        }

        static short? GetShortValue(object outputValue)
        {
            return short.TryParse(outputValue.ToString(), out var shortValue) ? shortValue : null;
        }

        static DateTime? GetDateTimeValue(object outputValue)
        {
            return DateTime.TryParse(outputValue.ToString(), out var dateTimeValue) ? dateTimeValue : null;
        }
    }
}