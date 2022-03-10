using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    public class OpenItemBuilder : Builder
    {
        public OpenItemBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public int StaffId { get; set; }
        public string StaffProfitCentre { get; set; }
        public decimal LocalBalance { get; set; }
        public decimal? ForeignBalance { get; set; }
        public TransactionStatus? Status { get; set; }
        public DateTime? ItemDate { get; set; }
        public DateTime? ClosePostDate { get; set; }
        public int EntityId { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? ForeignValue { get; set; }
        public string Currency { get; set; }
        public decimal? ExchangeRate { get; set; }
        public decimal? PreTaxValue { get; set; }
        public ItemType? TypeId { get; set; }
        public DateTime? PostDate { get; set; }
        public string StatementRef { get; set; }
        public string ReferenceText { get; set; }
        public string Regarding { get; set; }
        public string Scope { get; set; }
        public string ReasonCode { get; set; }
        
        public IEnumerable<OpenItem> BuildDraftBill(int caseId, params WorkInProgress[] wips)
        {
            var interim = BuildOpenItemsForCase(caseId);
            
            var lineNo = (short) 1;
            foreach (var wip in wips)
            {
                var w = (from wipTemplate in DbContext.Set<WipTemplate>()
                         join wipType in DbContext.Set<WipType>() on wipTemplate.WipTypeId equals wipType.Id into wt1
                         from wipType in wt1
                         where wipTemplate.WipCode == wip.WipCode
                         select new
                         {
                             CategoryCode = wipType.CategoryId,
                             WipTypeId = wipType.Id
                         }).Single();

                var billLine = CreateBillLine(interim, wip, w.WipTypeId, w.CategoryCode, lineNo++);

                CreateBilledItem(interim, wip, billLine);

                wip.Status = TransactionStatus.Locked;
                
                DbContext.SaveChanges();
            }

            if (interim.type == TransactionType.CreditNote)
            {
                foreach (var openItem in interim.openItems)
                {
                    Insert(new DebtorHistory
                    {
                        ItemEntityId = openItem.ItemEntityId,
                        ItemTransactionId = openItem.ItemTransactionId,
                        AccountEntityId = openItem.AccountEntityId,
                        AccountDebtorId = openItem.AccountDebtorId,
                        HistoryLineNo = 1,
                        OpenItemNo = openItem.OpenItemNo,
                        TransactionDate = openItem.ItemDate,
                        TransactionType = interim.type,
                        MovementClass = MovementClass.Entered,
                        CommandId = CommandId.Generate,
                        ItemPreTaxValue = openItem.PreTaxValue,
                        LocalTaxAmount = openItem.LocalTaxAmount,
                        LocalValue = openItem.LocalValue,
                        ExchangeVariance = openItem.ExchangeRateVariance,
                        ForeignTaxAmount = openItem.ForeignTaxAmount,
                        ForeignTransactionValue = openItem.ForeignValue,
                        ReferenceText = openItem.ReferenceText,
                        ReasonCode = ReasonCode,
                        RefEntityId = interim.th.EntityId,
                        RefTransactionId = interim.th.TransactionId,
                        LocalBalance = openItem.LocalBalance,
                        ForeignBalance = openItem.ForeignBalance,
                        Status = Status,
                        ItemImpact = ItemImpact.Created
                    });
                }
            }

            return interim.openItems;
        }

        void CreateBilledItem((TransactionHeader th, TransactionType type, Case @case, Name debtor, DateTime itemDate, TransactionStatus status, OpenItem[] openItems) interim, WorkInProgress wip, BillLine billLine)
        {
            if (interim.status == TransactionStatus.Active || interim.status == TransactionStatus.Reversed) return;

            Insert(new BilledItem
            {
                EntityId = interim.th.EntityId,
                TransactionId = interim.th.TransactionId,
                WipEntityId = wip.EntityId,
                WipTransactionId = wip.TransactionId,
                WipSequenceNo = wip.WipSequenceNo,
                BilledValue = wip.LocalValue,
                ForeignBilledValue = wip.ForeignValue,
                ForeignCurrency = wip.ForeignCurrency,
                ItemEntityId = billLine.ItemEntityId,
                ItemTransactionId = billLine.ItemTransactionId,
                ItemLineNo = billLine.ItemLineNo,
                AccountEntityId = interim.openItems.First().AccountEntityId,
                AccountDebtorId = interim.openItems.First().AccountDebtorId
            });
        }

        BillLine CreateBillLine((TransactionHeader th, TransactionType type, Case @case, Name debtor, DateTime itemDate, TransactionStatus status, OpenItem[] openItems) interim, 
                                WorkInProgress wip, 
                                string wipTypeId, string wipCategory, short lineNo)
        {
            return Insert(new BillLine
            {
                ItemEntityId = interim.th.EntityId,
                ItemTransactionId = interim.th.TransactionId,
                ItemLineNo = lineNo++,
                WipCode = wip.WipCode,
                WipTypeId = wipTypeId,
                CategoryCode = wipCategory,
                CaseReference = interim.@case?.Irn,
                Value = wip.LocalValue,
                ForeignValue = wip.ForeignValue,
                DisplaySequence = lineNo,
                PrintDate = interim.itemDate,
                PrintName = $"{StaffId}-{Fixture.String(20)}"
            });
        }

        public IEnumerable<OpenItem> BuildDebtorOnlyDraftBill(int debtorId, params WorkInProgress[] wips)
        {
            var interim = BuildOpenItemsForDebtor(debtorId);
            
            var lineNo = (short) 1;
            foreach (var wip in wips)
            {
                var w = (from wipTemplate in DbContext.Set<WipTemplate>()
                         join wipType in DbContext.Set<WipType>() on wipTemplate.WipTypeId equals wipType.Id into wt1
                         from wipType in wt1
                         where wipTemplate.WipCode == wip.WipCode
                         select new
                         {
                             CategoryCode = wipType.CategoryId,
                             WipTypeId = wipType.Id
                         }).Single();

                var billLine = CreateBillLine(interim, wip, w.WipTypeId, w.CategoryCode, lineNo++);

                CreateBilledItem(interim, wip, billLine);
                
                wip.Status = TransactionStatus.Locked;
                
                DbContext.SaveChanges();
            }

            if (interim.type == TransactionType.CreditNote)
            {
                foreach (var openItem in interim.openItems)
                {
                    Insert(new DebtorHistory
                    {
                        ItemEntityId = openItem.ItemEntityId,
                        ItemTransactionId = openItem.ItemTransactionId,
                        AccountEntityId = openItem.AccountEntityId,
                        AccountDebtorId = openItem.AccountDebtorId,
                        HistoryLineNo = 1,
                        OpenItemNo = openItem.OpenItemNo,
                        TransactionDate = openItem.ItemDate,
                        TransactionType = interim.type,
                        MovementClass = MovementClass.Entered,
                        CommandId = CommandId.Generate,
                        ItemPreTaxValue = openItem.PreTaxValue,
                        LocalTaxAmount = openItem.LocalTaxAmount,
                        LocalValue = openItem.LocalValue,
                        ExchangeVariance = openItem.ExchangeRateVariance,
                        ForeignTaxAmount = openItem.ForeignTaxAmount,
                        ForeignTransactionValue = openItem.ForeignValue,
                        ReferenceText = openItem.ReferenceText,
                        ReasonCode = ReasonCode,
                        RefEntityId = interim.th.EntityId,
                        RefTransactionId = interim.th.TransactionId,
                        LocalBalance = openItem.LocalBalance,
                        ForeignBalance = openItem.ForeignBalance,
                        Status = Status,
                        ItemImpact = ItemImpact.Created
                    });
                }
            }

            return interim.openItems;
        }

        public IEnumerable<OpenItem> BuildFinalisedBill(int caseId, params WorkHistory[] workHistoryFromWipCreated)
        {
            var interim = BuildOpenItemsForCase(caseId);
            
            var lineNo = (short) 1;
            var tomorrow = DateTime.Today.AddDays(1);
            var closestOpenPeriodId = DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => (int?) _.Id).FirstOrDefault();

            foreach (var wh in workHistoryFromWipCreated)
            {
                var w = (from wipTemplate in DbContext.Set<WipTemplate>()
                         join wipType in DbContext.Set<WipType>() on wipTemplate.WipTypeId equals wipType.Id into wt1
                         from wipType in wt1
                         where wipTemplate.WipCode == wh.WipCode
                         select new
                         {
                             CategoryCode = wipType.CategoryId,
                             WipTypeId = wipType.Id
                         }).Single();

                var _ = Insert(new BillLine
                {
                    ItemEntityId = interim.th.EntityId,
                    ItemTransactionId = interim.th.TransactionId,
                    ItemLineNo = lineNo++,
                    WipCode = wh.WipCode,
                    WipTypeId = w.WipTypeId,
                    CategoryCode = w.CategoryCode,
                    CaseReference = interim.@case.Irn,
                    Value = wh.LocalValue,
                    ForeignValue = wh.ForeignValue,
                    DisplaySequence = lineNo,
                    PrintDate = interim.itemDate,
                    PrintName = $"{StaffId}-{Fixture.String(20)}"
                });

                Insert(new WorkHistory
                {
                    EntityId = interim.th.EntityId,
                    TransactionId = interim.th.TransactionId,
                    WipSequenceNo = wh.WipSequenceNo,
                    TransDate = interim.itemDate,
                    PostDate = interim.itemDate,
                    CaseId = wh.CaseId,
                    StaffId = wh.StaffId,
                    WipCode = wh.WipCode,
                    LocalValue = wh.LocalValue,
                    ForeignValue = wh.ForeignValue,
                    ForeignCurrency = wh.ForeignCurrency,
                    ExchangeRate = wh.ExchangeRate,
                    RefEntityId = wh.EntityId,
                    RefTransactionId = wh.TransactionId,
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed,
                    CommandId = CommandId.Consume,
                    ItemImpact = null,
                    PostPeriodId = closestOpenPeriodId
                });
             
                wh.Status = TransactionStatus.Locked;
                
                DbContext.SaveChanges();
            }

            foreach (var openItem in interim.openItems)
            {
                Insert(new DebtorHistory
                {
                    ItemEntityId = openItem.ItemEntityId,
                    ItemTransactionId = openItem.ItemTransactionId,
                    AccountEntityId = openItem.AccountEntityId,
                    AccountDebtorId = openItem.AccountDebtorId,
                    HistoryLineNo = 1,
                    OpenItemNo = openItem.OpenItemNo,
                    TransactionDate = openItem.ItemDate,
                    TransactionType = interim.type,
                    MovementClass = MovementClass.Entered,
                    CommandId = CommandId.Generate,
                    ItemPreTaxValue = openItem.PreTaxValue,
                    LocalTaxAmount = openItem.LocalTaxAmount,
                    LocalValue = openItem.LocalValue,
                    ExchangeVariance = openItem.ExchangeRateVariance,
                    ForeignTaxAmount = openItem.ForeignTaxAmount,
                    ForeignTransactionValue = openItem.ForeignValue,
                    ReferenceText = openItem.ReferenceText,
                    ReasonCode = ReasonCode,
                    RefEntityId = interim.th.EntityId,
                    RefTransactionId = interim.th.TransactionId,
                    LocalBalance = openItem.LocalBalance,
                    ForeignBalance = openItem.ForeignBalance,
                    Status = Status,
                    ItemImpact = ItemImpact.Created,
                    PostPeriodId = closestOpenPeriodId
                });
            }
            
            return interim.openItems;
        }

        (TransactionHeader th, TransactionType type, Case @case, Name debtor, DateTime itemDate, TransactionStatus status, OpenItem[] openItems) BuildOpenItemsForCase(int caseId)
        {
            var today = DateTime.Today.Date;

            var transNo = DbContext.Set<TransactionHeader>().Where(_ => _.EntityId == EntityId).Max(_ => _.TransactionId) + 1;

            var status = Status ?? TransactionStatus.Draft;
            
            var typeId = TypeId ?? ItemType.DebitNote;

            var itemNo = 1000 + Fixture.Short();

            var itemDate = ItemDate ?? today;

            var openItemNoPrefix = (TypeId ?? ItemType.DebitNote).ToString().Substring(0, 1);

            var transactionType = (TypeId ?? ItemType.DebitNote) == ItemType.CreditNote
                ? TransactionType.CreditNote
                : TransactionType.Bill;

            var openItems = new List<OpenItem>();

            var @case = DbContext.Set<Case>().Include(_ => _.CaseNames).Single(_ => _.Id == caseId);

            var th = Insert(new TransactionHeader
            {
                EntityId = EntityId,
                TransactionId = transNo,
                StaffId = StaffId,
                TransactionDate = today,
                EntryDate = today,
                TransactionType = transactionType,
                TransactionStatus = TransactionStatus.Draft,
                Source = SystemIdentifier.TimeAndBilling,
                UserLoginId = RandomString.Next(20)
            });

            foreach (var debtor in @case.CaseNames.Where(_ => _.NameTypeId == KnownNameTypes.Debtor))
            {
                var billPercentage = (debtor.BillingPercentage ?? (decimal) 100.0) / (decimal) 100.0;

                var openItemNo = $"{openItemNoPrefix}{itemNo++}";
                openItems.Add(Insert(new OpenItem(th.EntityId, th.TransactionId, EntityId, debtor.Name)
                {
                    Status = status,
                    TypeId = typeId,
                    ItemDate = itemDate,

                    AccountEntityId = th.EntityId,
                    AccountDebtorId = debtor.NameId,
                    ItemEntityId = th.EntityId,
                    ItemTransactionId = th.TransactionId,

                    OpenItemNo = openItemNo,
                    
                    LocalBalance = Math.Round(LocalBalance * billPercentage, MidpointRounding.AwayFromZero),
                    LocalValue = Math.Round((LocalValue ?? 0) * billPercentage, MidpointRounding.AwayFromZero),
                    PreTaxValue = Math.Round((PreTaxValue ?? 0) * billPercentage, MidpointRounding.AwayFromZero),

                    ForeignBalance = string.IsNullOrWhiteSpace(Currency) ? null : Math.Round((ForeignBalance ?? 0) * billPercentage, MidpointRounding.AwayFromZero),
                    ForeignValue = string.IsNullOrWhiteSpace(Currency) ? null : Math.Round((ForeignValue ?? 0) * billPercentage, MidpointRounding.AwayFromZero),
                    Currency = Currency,
                    ExchangeRate = ExchangeRate,

                    MainCaseId = @case.Id,

                    BillPercentage = debtor.BillingPercentage ?? 100,
                    StaffId = StaffId,
                    StaffProfitCentre = StaffProfitCentre,

                    StatementRef = StatementRef ?? $"StatementRef-{openItemNo}-{@case.Irn}-" + Fixture.String(100),
                    ReferenceText = ReferenceText ?? $"ReferenceText-{openItemNo}-{@case.Irn}-" + Fixture.String(100),
                    Regarding = Regarding ?? $"Regarding-{openItemNo}-{@case.Irn}-" + Fixture.String(100),
                    Scope = Scope ?? $"Scope-{openItemNo}-{@case.Irn}-" + Fixture.String(100),

                    PostDate = PostDate,
                    ClosePostDate = ClosePostDate
                }));

                InsertWithNewId(new NameAddressSnapshot
                {
                    NameId = debtor.NameId,
                    FormattedName = debtor.Name.Formatted(),
                    FormattedAttention = debtor.AttentionName.FormattedNameOrNull(),
                    FormattedAddress = "Address of the debtor",
                    FormattedReference = debtor.Reference
                }, x => x.NameSnapshotId);
            }

            if (openItems.Count > 1)
            {
                var last = openItems.Last();
                last.LocalBalance = last.LocalBalance + LocalBalance - openItems.Sum(_ => _.LocalBalance.GetValueOrDefault());
                last.LocalValue = last.LocalValue + LocalValue - openItems.Sum(_ => _.LocalValue.GetValueOrDefault());
                last.PreTaxValue = last.PreTaxValue + PreTaxValue - openItems.Sum(_ => _.PreTaxValue.GetValueOrDefault());
                
                last.ForeignBalance = last.ForeignBalance + ForeignBalance - openItems.Sum(_ => _.ForeignBalance.GetValueOrDefault());
                last.ForeignValue = last.ForeignValue + ForeignValue - openItems.Sum(_ => _.ForeignValue.GetValueOrDefault());
            }

            return (th, transactionType, @case, null, itemDate, status, openItems.ToArray());
        }

        (TransactionHeader th, TransactionType type, Case @case, Name debtor, DateTime itemDate, TransactionStatus status, OpenItem[] openItems) BuildOpenItemsForDebtor(int debtorId)
        {
            var today = DateTime.Today.Date;

            var transNo = DbContext.Set<TransactionHeader>().Where(_ => _.EntityId == EntityId).Max(_ => _.TransactionId) + 1;

            var status = Status ?? TransactionStatus.Draft;
            
            var typeId = TypeId ?? ItemType.DebitNote;

            var itemNo = 1000 + Fixture.Short();

            var itemDate = ItemDate ?? today;

            var openItemNoPrefix = (TypeId ?? ItemType.DebitNote).ToString().Substring(0, 1);

            var transactionType = (TypeId ?? ItemType.DebitNote) == ItemType.CreditNote
                ? TransactionType.CreditNote
                : TransactionType.Bill;

            var openItems = new List<OpenItem>();

            var th = Insert(new TransactionHeader
            {
                EntityId = EntityId,
                TransactionId = transNo,
                StaffId = StaffId,
                TransactionDate = today,
                EntryDate = today,
                TransactionType = transactionType,
                TransactionStatus = TransactionStatus.Draft,
                Source = SystemIdentifier.TimeAndBilling,
                UserLoginId = RandomString.Next(20)
            });

            var debtor = DbContext.Set<Name>().Single(_ => _.Id == debtorId);
            
            var openItemNo = $"{openItemNoPrefix}{itemNo}";
            openItems.Add(Insert(new OpenItem(th.EntityId, th.TransactionId, EntityId, debtor)
            {
                Status = status,
                TypeId = typeId,
                ItemDate = itemDate,

                AccountEntityId = th.EntityId,
                AccountDebtorId = debtor.Id,
                ItemEntityId = th.EntityId,
                ItemTransactionId = th.TransactionId,

                OpenItemNo = openItemNo,
                
                LocalBalance = LocalBalance,
                LocalValue = LocalValue ?? 0,
                PreTaxValue = PreTaxValue ?? 0,

                ForeignBalance = string.IsNullOrWhiteSpace(Currency) ? null : ForeignBalance ?? 0,
                ForeignValue = string.IsNullOrWhiteSpace(Currency) ? null : ForeignValue ?? 0,
                Currency = Currency,
                ExchangeRate = ExchangeRate,
                
                BillPercentage = 100,
                StaffId = StaffId,
                StaffProfitCentre = StaffProfitCentre,

                StatementRef = StatementRef ?? $"StatementRef-{openItemNo}-{debtor.Formatted()}-" + Fixture.String(100),
                ReferenceText = ReferenceText ?? $"ReferenceText-{openItemNo}-{debtor.Formatted()}-" + Fixture.String(100),
                Regarding = Regarding ?? $"Regarding-{openItemNo}-{debtor.Formatted()}-" + Fixture.String(100),
                Scope = Scope ?? $"Scope-{openItemNo}-{debtor.Formatted()}-" + Fixture.String(100),

                PostDate = PostDate,
                ClosePostDate = ClosePostDate
            }));
            
            InsertWithNewId(new NameAddressSnapshot
            {
                NameId = debtor.Id,
                FormattedName = debtor.Formatted(),
                FormattedAddress = debtor.PostalAddress().FormattedOrNull()
            }, x => x.NameSnapshotId);

            return (th, transactionType, null, debtor, itemDate, status, openItems.ToArray());
        }
    }
}