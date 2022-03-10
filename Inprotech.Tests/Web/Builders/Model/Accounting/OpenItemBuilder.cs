using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class OpenItemBuilder : IBuilder<OpenItem>
    {
        readonly InMemoryDbContext _db;

        public OpenItemBuilder(InMemoryDbContext db)
        {
            _db = db;
        }
        
        public int? ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }
        public decimal LocalBalance { get; set; }
        public Name AccountDebtorName { get; set; }
        public TransactionStatus? Status { get; set; }
        public DateTime? ItemDate { get; set; }
        public DateTime? ClosePostDate { get; set; }
        public int? EntityId { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? PreTaxValue { get; set; }
        public string OpenItemNo { get; set; }
        public ItemType? TypeId { get; set; }
        public string PayPropertyType { get; set; }
        public DateTime? PostDate { get; set; }

        public OpenItem Build()
        {
            var today = Fixture.Today();
            return new OpenItem(
                                ItemEntityId ?? Fixture.Integer(),
                                ItemTransactionId ?? Fixture.Integer(),
                                Fixture.Integer(),
                                AccountDebtorName ?? new NameBuilder(_db).Build())
            {
                LocalBalance = LocalBalance,
                Status = Status ?? TransactionStatus.Draft,
                ItemDate = ItemDate ?? today,
                AccountEntityId = EntityId ?? Fixture.Integer(),
                ClosePostDate = ClosePostDate ??
                                new DateTime(today.Year,
                                             today.Month,
                                             DateTime.DaysInMonth(today.Year,
                                                                  today.Month)),
                PostDate = PostDate ?? new DateTime(today.Year,
                                                    today.Month,
                                                    DateTime.DaysInMonth(today.Year,
                                                                         today.Month)),
                LocalValue = LocalValue,
                PreTaxValue = PreTaxValue,
                TypeId = TypeId ?? ItemType.DebitNote,
                PayPropertyType = PayPropertyType,
                OpenItemNo = OpenItemNo
            };
        }

        public OpenItem BuildWithCase(Case caseInput)
        {
            var today = Fixture.Today();
            var openItem = new OpenItem(
                                        Fixture.Integer(),
                                        Fixture.Integer(),
                                        Fixture.Integer(),
                                        AccountDebtorName ?? new NameBuilder(_db).Build())
            {
                LocalBalance = LocalBalance,
                Status = Status ?? (short) TransactionStatus.Draft,
                ItemDate = ItemDate ?? today,
                AccountEntityId = EntityId ?? Fixture.Integer(),
                ClosePostDate = ClosePostDate ??
                                new DateTime(today.Year,
                                             today.Month,
                                             DateTime.DaysInMonth(today.Year,
                                                                  today.Month)),
                LocalValue = LocalValue,
                PreTaxValue = PreTaxValue,
                TypeId = TypeId ?? ItemType.DebitNote,
                PostDate = PostDate ?? new DateTime(today.Year,
                                        today.Month,
                                        DateTime.DaysInMonth(today.Year,
                                                             today.Month))
            }.In(_db);
            
            new OpenItemCase
            {
                ItemEntityId = openItem.ItemEntityId,
                ItemTransactionId = openItem.ItemTransactionId,
                AccountEntityId = openItem.AccountEntityId,
                AccountDebtorId = openItem.AccountDebtorName.Id,
                LocalValue = openItem.LocalValue,
                LocalBalance = openItem.LocalBalance,
                CaseId = caseInput.Id,
                Status = openItem.Status
            }.In(_db);
            return openItem;
        }
    }
}