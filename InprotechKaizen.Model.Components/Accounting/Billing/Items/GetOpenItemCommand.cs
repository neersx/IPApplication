using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Persistence;
using OpenItemXmlModel = InprotechKaizen.Model.Components.Accounting.Billing.Items.OpenItemXml;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IGetOpenItemCommand
    {
        Task<OpenItemModel> GetOpenItem(int userIdentityId, string culture, int itemEntityId, string openItemNo);

        Task<IEnumerable<OpenItemModel>> GetOpenItems(int userIdentityId, string culture, string openItemNos);

        Task<OpenItemModel> GetOpenItemDefaultForItemType(int userIdentityId, string culture, int itemType);

        Task<bool> IsOpenItemNoUnique(string openItemNo);
    }

    public class GetOpenItemCommand : IGetOpenItemCommand
    {
        readonly IDbContext _dbContext;
        readonly ILogger<GetOpenItemCommand> _logger;

        public GetOpenItemCommand(IDbContext dbContext, ILogger<GetOpenItemCommand> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<bool> IsOpenItemNoUnique(string openItemNo)
        {
            return !await _dbContext.Set<OpenItem>().AnyAsync(_ => _.OpenItemNo == openItemNo);
        }

        public async Task<OpenItemModel> GetOpenItem(int userIdentityId, string culture, int itemEntityId, string openItemNo)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetOpenItem,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", itemEntityId},
                                                                            {"@pnItemTransNo", null},
                                                                            {"@psOpenItemNo", openItemNo},
                                                                            {"@pnItemType", null}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var openItem = await PopulateFromDataReader(dr, new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                OpenItemNo = openItemNo
            });

            _logger.Trace("Get Open Item", new
            {
                input = new
                {
                    userIdentityId,
                    itemEntityKey = itemEntityId,
                    openItemNo
                },
                result = openItem
            });

            return openItem;
        }

        public async Task<IEnumerable<OpenItemModel>> GetOpenItems(int userIdentityId, string culture, string openItemNos)
        {
            if (openItemNos == null) throw new ArgumentNullException(nameof(openItemNos));

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetOpenItem,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", null},
                                                                            {"@pnItemTransNo", null},
                                                                            {"@psOpenItemNo", openItemNos},
                                                                            {"@pnItemType", null}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var openItems = new List<OpenItemModel>();

            while (await dr.ReadAsync())
            {
                openItems.Add(BuildOpenItemFromRawData(dr));
            }

            await BuildOpenItemXmlFromRawData(dr, openItems.First());

            _logger.Trace("Get Open Items", new
            {
                input = new
                {
                    userIdentityId, 
                    openItemNo = openItemNos
                },
                result = openItems
            });

            return openItems;
        }

        public async Task<OpenItemModel> GetOpenItemDefaultForItemType(int userIdentityId, string culture, int itemType)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetOpenItem,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnItemEntityNo", null},
                                                                            {"@pnItemTransNo", null},
                                                                            {"@psOpenItemNo", null},
                                                                            {"@pnItemType", itemType}
                                                                        });

            using var dr = await command.ExecuteReaderAsync();

            var openItem = await PopulateFromDataReader(dr);

            _logger.Trace($"Get Open Item - Default {itemType}", new
            {
                input = new
                {
                    userIdentityId,
                    itemType
                },
                result = openItem
            });

            return openItem;
        }

        static async Task<OpenItemModel> PopulateFromDataReader(DbDataReader dr, OpenItemModel openItemModel = null)
        {
            if (await dr.ReadAsync())
            {
                openItemModel = BuildOpenItemFromRawData(dr, openItemModel);
            }

            return await BuildOpenItemXmlFromRawData(dr, openItemModel);
        }

        static async Task<OpenItemModel> BuildOpenItemXmlFromRawData(DbDataReader dr, OpenItemModel openItemModel)
        {
            if (!await dr.NextResultAsync()) return openItemModel;

            while (await dr.ReadAsync())
            {
                if (!dr.IsDBNull(dr.GetOrdinal("OpenItemXML")))
                {
                    openItemModel.OpenItemXml.Add(
                                             new OpenItemXmlModel
                                             {
                                                 ItemEntityId = dr.GetField<int>("ItemEntityNo"),
                                                 ItemTransactionId = dr.GetField<int>("ItemTransNo"),
                                                 XmlType = dr.GetField<byte>("XMLType"),
                                                 ItemXml = dr.GetField<string>("OpenItemXML")
                                             });
                }
            }

            return openItemModel;
        }

        static OpenItemModel BuildOpenItemFromRawData(IDataRecord dr, OpenItemModel openItemModel = null)
        {
            openItemModel ??= new OpenItemModel();

            openItemModel.ItemDate = dr.GetField<DateTime>("ItemDate");
            openItemModel.AccountDebtorNameId = dr.GetField<int>("AcctDebtorNo");
            openItemModel.BillPercentage = dr.GetField<decimal>("BillPercentage");
            openItemModel.HasBillBeenPrinted = dr.GetField<byte>("BillPrintedFlag") == 1;
            openItemModel.Action = dr.GetField<string>("Action");
            openItemModel.ItemEntityId = dr.GetField<int?>("ItemEntityNo");
            openItemModel.AccountEntityId = dr.GetField<int?>("AcctEntityNo");
            openItemModel.AssociatedOpenItemNo = dr.GetField<string>("AssocOpenItemNo");
            openItemModel.BillFormatId = dr.GetField<short?>("BillFormatId");
            openItemModel.CaseProfitCentre = dr.GetField<string>("CaseProfitCentre");
            openItemModel.ClosePostDate = dr.GetField<DateTime?>("ClosePostDate");
            openItemModel.Currency = dr.GetField<string>("Currency");
            openItemModel.StaffName = dr.GetField<string>("EmployeeName");
            openItemModel.StaffId = dr.GetField<int>("EmployeeNo");
            openItemModel.StaffProfitCentre = dr.GetField<string>("EmpProfitCentre");
            openItemModel.StaffProfitCentreDescription = dr.GetField<string>("EmpProfitCentreDescription");
            openItemModel.ExchangeRate = dr.GetField<decimal?>("ExchRate");
            openItemModel.ExchangeRateVariance = dr.GetField<decimal?>("ExchVariance");
            openItemModel.ForeignBalance = dr.GetField<decimal?>("ForeignBalance");
            openItemModel.ForeignEquivalentCurrency = dr.GetField<string>("ForeignEquivCurrcy");
            openItemModel.ForeignEquivalentExchangeRate = dr.GetField<decimal?>("ForeignEquivExRate");
            openItemModel.ForeignOriginalTakenUp = dr.GetField<decimal?>("ForeignOrigTakenUp");
            openItemModel.ForeignTaxAmount = dr.GetField<decimal?>("ForeignTaxAmt");
            openItemModel.ForeignValue = dr.GetField<decimal?>("ForeignValue");
            openItemModel.ImageId = dr.GetField<int?>("ImageId");
            openItemModel.IncludeOnlyWip = dr.GetField<string>("IncludeOnlyWIP");
            openItemModel.ItemDueDate = dr.GetField<DateTime?>("ItemDueDate");
            openItemModel.ItemPreTaxValue = dr.GetField<decimal>("ItemPreTaxValue");
            openItemModel.ItemTransactionId = dr.GetField<int?>("ItemTransNo");
            openItemModel.ItemType = dr.GetField<int>("ItemType");
            openItemModel.LanguageId = dr.GetField<int?>("LanguageKey");
            openItemModel.LanguageDescription = dr.GetField<string>("LanguageDescription");
            openItemModel.LocalBalance = dr.GetField<decimal>("LocalBalance");
            openItemModel.LocalOriginalTakenUp = dr.GetField<decimal?>("LocalOrigTakenUp");
            openItemModel.LocalTaxAmount = dr.GetField<decimal>("LocalTaxAmt");
            openItemModel.LocalValue = dr.GetField<decimal>("LocalValue");
            openItemModel.LockIdentityId = dr.GetField<int?>("LockIdentityId");
            openItemModel.OpenItemNo = dr.GetField<string>("OpenItemNo");
            openItemModel.PostDate = dr.GetField<DateTime?>("PostDate");
            openItemModel.PostPeriodId = dr.GetField<int?>("PostPeriod");
            openItemModel.ShouldUseRenewalDebtor = dr.GetField<bool>("RenewalDebtorFlag");
            openItemModel.CanUseRenewalDebtor = dr.GetField<bool>("CanUseRenewalDebtor");
            openItemModel.Scope = dr.GetField<string>("Scope");
            openItemModel.StatementRef = dr.GetField<string>("StatementRef");
            openItemModel.ReferenceText = dr.GetField<string>("ReferenceText");
            openItemModel.Regarding = dr.GetField<string>("Regarding");
            openItemModel.Status = dr.GetField<int>("Status");
            openItemModel.BillTotal = dr.GetField<decimal>("BillTotal");
            openItemModel.WriteDown = dr.GetField<decimal>("WriteDown");
            openItemModel.WriteUp = dr.GetField<decimal>("WriteUp");
            openItemModel.LogDateTimeStamp = dr.GetField<DateTime?>("LogDateTimeStamp");
            openItemModel.LocalCurrencyCode = dr.GetField<string>("LocalCurrencyCode");
            openItemModel.LocalDecimalPlaces = dr.GetField<int?>("LocalDecimalPlaces") ?? 2;
            openItemModel.ForeignDecimalPlaces = dr.GetField<byte?>("ForeignDecimalPlaces") ?? 2;
            openItemModel.RoundBillValues = dr.GetField<short?>("RoundBillValues");
            openItemModel.CreditReason = dr.GetField<string>("CreditReason");
            openItemModel.IsWriteDownWip = dr.GetField<byte>("WriteDownWIP") == 1;
            openItemModel.WriteDownReason = dr.GetField<string>("WriteDownReason");
            openItemModel.ItemTypeDescription = dr.GetField<string>("ItemTypeDescription");
            openItemModel.MainCaseId = dr.GetField<int?>("MainCaseKey");

            return openItemModel;
        }
    }
}