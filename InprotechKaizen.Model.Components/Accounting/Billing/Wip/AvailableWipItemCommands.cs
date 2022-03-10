using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IAvailableWipItemCommands
    {
        Task<IEnumerable<AvailableWipItem>> GetAvailableWipItems(int userIdentityId, string culture, WipSelectionCriteria wipSelectionCriteria);
    }

    internal class AvailableWipItemCommands : IAvailableWipItemCommands
    {
        readonly IDbContext _dbContext;

        public AvailableWipItemCommands(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AvailableWipItem>> GetAvailableWipItems(int userIdentityId, string culture, WipSelectionCriteria wipSelectionCriteria)
        {
            if (wipSelectionCriteria == null) throw new ArgumentNullException(nameof(wipSelectionCriteria));

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetBillAvailableWip,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", wipSelectionCriteria.ItemEntityId},
                                                                            {"@pnItemTransNo", wipSelectionCriteria.ItemTransactionId},
                                                                            {"@psCaseKeyCSVList", wipSelectionCriteria.CaseIdsCsv},
                                                                            {"@pnDebtorKey", wipSelectionCriteria.DebtorId},
                                                                            {"@pnRaisedByStaffKey", wipSelectionCriteria.RaisedByStaffId},
                                                                            {"@pnItemType", (int?) wipSelectionCriteria.ItemType},
                                                                            {"@pdtItemDate", wipSelectionCriteria.ItemDate},
                                                                            {"@psMergeXMLKeys", wipSelectionCriteria.MergeXmlKeys}
                                                                        });

            var wipItems = new List<AvailableWipItem>();

            using var dr = await command.ExecuteReaderAsync();

            while (await dr.ReadAsync())
            {
                wipItems.Add(BuildAvailableWipItemFromRawData(dr));
            }

            return wipItems;
        }

        static AvailableWipItem BuildAvailableWipItemFromRawData(IDataRecord dr)
        {
            var availableWip = new AvailableWipItem
            {
                CaseId = dr.GetField<int?>("CaseKey"),
                CaseRef = dr.GetField<string>("IRN"),
                EntityId = dr.GetField<int>("EntityNo"),
                TransactionId = dr.GetField<int>("TransNo"),
                WipSeqNo = dr.GetField<short>("WIPSeqNo"),
                WipCode = dr.GetField<string>("WIPCode"),
                WipTypeId = dr.GetField<string>("WIPTypeId"),
                WipTypeDescription = dr.GetField<string>("WIPTypeDescription"),
                WipCategory = dr.GetField<string>("WIPCategory"),
                WipCategoryDescription = dr.GetField<string>("WIPCategoryDescription"),
                Description = dr.GetField<string>("Description"),
                IsRenewal = dr.GetField<bool>("RenewalFlag"),
                NarrativeId = dr.GetField<int?>("NarrativeNo"),
                ShortNarrative = dr.GetField<string>("ShortNarrative"),
                TransactionDate = dr.GetField<DateTime?>("TransDate"),
                StaffProfitCentre = dr.GetField<string>("EmpProfitCentre"),
                ProfitCentreDescription = dr.GetField<string>("ProfitCentreDescription"),
                TotalTime = dr.GetField<DateTime?>("TotalTime"),
                TotalUnits = dr.GetField<int?>("TotalUnits"),
                UnitsPerHour = dr.GetField<int?>("UnitsPerHour"),
                ChargeOutRate = dr.GetField<decimal?>("ChargeOutRate"),
                VariableFeeAmount = dr.GetField<decimal>("VariableFeeAmt"),
                VariableFeeType = dr.GetField<int?>("VariableFeeType"),
                VariableFeeCurrency = dr.GetField<string>("VariableFeeCurr"),
                VariableFeeReason = dr.GetField<string>("VariableFeeReason"),
                VariableFeeWipCode = dr.GetField<string>("VariableFeeWIPCode"),
                FeeCriteriaNo = dr.GetField<int?>("FeeCriteriaNo"),
                FeeUniqueId = dr.GetField<int?>("FeeUniqueId"),
                Balance = dr.GetField<decimal>("Balance"),
                LocalBilled = dr.GetField<decimal?>("LocalBilled"),
                ForeignCurrency = dr.GetField<string>("ForeignCurrency"),
                ForeignDecimalPlaces = dr.GetField<int?>("ForeignDecimalPlaces"),
                Status = dr.GetField<int?>("Status"),
                TaxCode = dr.GetField<string>("TaxCode"),
                TaxDescription = dr.GetField<string>("TaxDescription"),
                TaxRate = dr.GetField<decimal?>("TaxRate"),
                StateTaxCode = dr.GetField<string>("StateTaxCode"),
                StaffName = dr.GetField<string>("StaffName"),
                StaffSignOffName = dr.GetField<string>("StaffSignOffName"),
                StaffId = dr.GetField<int?>("EmployeeNo"),
                IsDiscount = dr.GetField<bool>("DiscountFlag"),
                IsMargin = dr.GetField<bool>("MarginFlag"),
                CostCalculation1 = dr.GetField<decimal>("CostCalculation1"),
                CostCalculation2 = dr.GetField<decimal>("CostCalculation2"),
                MarginNo = dr.GetField<int?>("MarginNo"),
                WipCategorySortOrder = dr.GetField<int>("WIPCatSortOrder"),
                BillLineNo = dr.GetField<int?>("BillLineNo"),
                ReasonCode = dr.GetField<string>("ReasonCode"),
                RateNoSortOrder = dr.GetField<int?>("RateNoSortOrder"),
                WipTypeSortOrder = dr.GetField<int>("WIPTypeSortOrder"),
                WipCodeSortOrder = dr.GetField<int>("WIPCodeSortOrder"),
                Title = dr.GetField<string>("Title"),
                LocalVariation = dr.GetField<decimal?>("LocalVariation"),
                IsBillingDiscount = dr.GetField<bool>("BillingDiscountFlag"),
                ShouldPreventWriteDown = dr.GetField<bool>("PreventWriteDownFlag"),
                GeneratedFromTaxCode = dr.GetField<string>("GeneratedFromTaxCode"),
                IsHiddenForDraft = dr.GetField<bool>("IsHiddenForDraft"),
                BillItemEntityId = dr.GetField<int?>("BillItemEntityNo"),
                BillItemTransactionId = dr.GetField<int?>("BillItemTransNo"),
                WriteDownPriority = dr.GetField<int?>("WriteDownPriority"),
                WriteUpAllowed = dr.GetField<bool>("WriteUpAllowed"),
                WipBuyRate = dr.GetField<decimal?>("WIPBuyRate"),
                WipSellRate = dr.GetField<decimal?>("WIPSellRate"),
                BillBuyRate = dr.GetField<decimal?>("BillBuyRate"),
                BillSellRate = dr.GetField<decimal?>("BillSellRate"),
                AccountClientId = dr.GetField<int?>("AcctClientNo"),
                IsAdvanceBill = dr.GetField<bool>("IsAdvanceBill"),
                IsDiscountDisconnected = dr.GetField<bool>("IsDiscountDisconnected"),
                IsFeeType = dr.GetField<bool>("IsFeeType")
            };

            if (!string.IsNullOrEmpty(availableWip.ForeignCurrency))
            {
                availableWip.ForeignBalance = dr.GetField<decimal?>("ForeignBalance");
                availableWip.ForeignBilled = dr.GetField<decimal?>("ForeignBilled");
                availableWip.ForeignVariation = dr.GetField<decimal?>("ForeignVariation");
            }

            availableWip.IsDraft = availableWip.Status == 0;

            return availableWip;
        }
    }
}
