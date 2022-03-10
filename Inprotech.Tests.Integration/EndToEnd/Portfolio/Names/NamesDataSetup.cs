using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Cash;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Trust;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Payment;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Names
{
    class NamesDataSetup : DbSetup
    {
        const string NamePrefix = "e2e";

        [SetUp]
        public void CreateAdminUser()
        {
            new Users()
                .WithPermission(ApplicationTask.AdvancedNameSearch)
                .Create();
        }

        public dynamic CreateNamesScreenDataSetup()
        {
            var data = Do(setup =>
            {
                var homeName = new NameBuilder(setup.DbContext).CreateOrg(NameUsedAs.Organisation, "homeOrg");
                var supplierName = new NameBuilder(setup.DbContext).CreateSupplierOrg(NamePrefix + "Sup");

                var staff = new NameBuilder(setup.DbContext).CreateStaff(NamePrefix + "staff");
                setup.Insert(new SpecialName(true, homeName));
                setup.Insert(new Account { EntityId = homeName.Id, NameId = supplierName.Id, Balance = (decimal?) 2.0, CreditBalance = (decimal?) 2.0 });

                GetScreenCriteriaBuilder(supplierName)
                    .WithTopicControl(KnownNameScreenTopics.SupplierDetails)
                    .WithTopicControl(KnownNameScreenTopics.TrustAccounting)
                    .WithTopicControl(KnownNameScreenTopics.Dms);

                var sendPayToName = new NameBuilder(setup.DbContext).CreateSupplierIndividual();
                var sendPayToNameAttention = new AssociatedNameBuilder(setup.DbContext).Create(supplierName, sendPayToName, KnownRelations.Pay);
                var individual = new NameBuilder(setup.DbContext).CreateClientIndividual();
                
                var bank = new NameBuilder(setup.DbContext).CreateOrg(NameUsedAs.Organisation, "bank");

                setup.Insert(new SpecialName(true, bank) { IsBankOrFinancialInstitution = 1 });
                
                var bankAccount1 = setup.Insert(new BankAccount
                {
                    AccountOwner = homeName.Id,
                    BankNameNo = bank.Id,
                    SequenceNo = 1,
                    AccountName = RandomString.Next(5),
                    AccountNo = RandomString.Next(5),
                    Currency = "USD",
                    Description = RandomString.Next(10),
                    DrawChequesFlag = 1,
                    TrustAcctFlag = false
                });

                new Users()
                    .WithSubjectPermission(ApplicationSubject.SupplierDetails)
                    .WithSubjectPermission(ApplicationSubject.TrustAccounting)
                    .CreateIpPlatformUser(false, true);

                var supplier = setup.DbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)TableTypes.SupplierType)
                                                 .ToArray();
                var paymentMethod = setup.DbContext.Set<PaymentMethods>()
                                         .Select(_ => new
                                         {
                                             _.Id, UsedBy = (short)_.UsedBy
                                         })
                                         .Where(_ => (_.UsedBy & (short) KnownPaymentMethod.Payable) == (short) KnownPaymentMethod.Payable)
                                        .ToArray();

                var creditor = new Creditor {NameId = supplierName.Id, SupplierType = supplier[0].Id, PurchaseDescription = "Buy this", ProfitCentre = "TM", Instructions = "This is instruction", ChequePayee = "Payee", PaymentMethod = paymentMethod[0].Id};
                var creditorData = Insert(creditor);
                var yesterday = DateTime.Today.AddDays(-1);
                
                var th = setup.InsertWithNewId(new TransactionHeader
                {
                    StaffId = staff.Id,
                    EntityId = homeName.Id,
                    TransactionDate = yesterday,
                    EntryDate = yesterday,
                    TransactionType = TransactionType.ManualJournalEntry,
                    Source = SystemIdentifier.GeneralLedger,
                    UserLoginId = RandomString.Next(20)
                }, t => (short?)t.TransactionId);

                var docRef = RandomString.Next(5);
                setup.Insert(new CreditorItem { ItemEntityId = homeName.Id, ItemTransactionId = th.TransactionId, AccountCreditorId = supplierName.Id, AccountEntityId = homeName.Id, LocalBalance = (decimal?) 2.0, DocumentRef = docRef, ItemDate = yesterday });
                
                var bank2 = new NameBuilder(setup.DbContext).CreateOrg(NameUsedAs.Organisation, "bank");

                setup.Insert(new SpecialName(true, bank2) { IsBankOrFinancialInstitution = 1 });
                var bankAccount2 = setup.Insert(new BankAccount
                {
                    AccountOwner = homeName.Id,
                    BankNameNo = bank2.Id,
                    SequenceNo = 1,
                    AccountName = RandomString.Next(5),
                    AccountNo = RandomString.Next(5),
                    Currency = "USD",
                    Description = RandomString.Next(10),
                    DrawChequesFlag = 1,
                    TrustAcctFlag = false
                });
                setup.Insert(new TrustAccount {Balance = 60000, NameId = supplierName.Id, EntityId = homeName.Id});
               
                var itemNo = Fixture.String(6);
                var itemNo2 = Fixture.String(6);
                var itemNo3 = Fixture.String(6);

                var th2 = setup.InsertWithNewId(new TransactionHeader
                {
                    StaffId = staff.Id,
                    EntityId = homeName.Id,
                    TransactionDate = yesterday,
                    EntryDate = yesterday,
                    TransactionType = TransactionType.ManualJournalEntry,
                    Source = SystemIdentifier.GeneralLedger,
                    UserLoginId = RandomString.Next(20)
                }, t => (short?)t.TransactionId);
                var th3 = setup.InsertWithNewId(new TransactionHeader
                {
                    StaffId = staff.Id,
                    EntityId = homeName.Id,
                    TransactionDate = yesterday,
                    EntryDate = yesterday,
                    TransactionType = TransactionType.ManualJournalEntry,
                    Source = SystemIdentifier.GeneralLedger,
                    UserLoginId = RandomString.Next(20)
                }, t => (short?)t.TransactionId);
               
                var trustItem1 = setup.Insert(new TrustItem { ItemEntityId = homeName.Id, ItemTransactionId = th.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, ItemDate = yesterday, PostDate = yesterday, LocalBalance = 10000, ItemNo = itemNo, LocalValue = 10001});
                setup.Insert(new TrustHistory
                {
                    ItemEntityId = homeName.Id, ItemTransactionId = th.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, RefEntityId = homeName.Id, TransactionDate = yesterday, PostDate = yesterday, LocalBalance = 10000, ItemNo = itemNo, 
                    MovementClass = MovementClass.Entered
                });
                setup.Insert(new CashItem {AccountEntityId = homeName.Id, TransactionId = th.TransactionId, EntityId = homeName.Id, TransactionEntityId = homeName.Id, ItemDate = yesterday, BankNameId = bank.Id, SequenceNo = 1, Status = TransactionStatus.Active, PaymentMethod = PaymentMethod.BankDraft});

                var trustItem2 = setup.Insert(new TrustItem { ItemEntityId = homeName.Id, ItemTransactionId = th2.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, ItemDate = yesterday, PostDate = yesterday, LocalBalance = 20000, ItemNo = itemNo2, LocalValue = 10002 });
                setup.Insert(new TrustHistory { ItemEntityId = homeName.Id, ItemTransactionId = th2.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, RefEntityId = homeName.Id, TransactionDate = yesterday, PostDate = yesterday, LocalBalance = 20000, ItemNo = itemNo2, MovementClass = MovementClass.Entered });
                setup.Insert(new CashItem { AccountEntityId = homeName.Id, TransactionId = th2.TransactionId, EntityId = homeName.Id, TransactionEntityId = homeName.Id, ItemDate = yesterday, BankNameId = bank2.Id, SequenceNo = 1, Status = TransactionStatus.Active, PaymentMethod = PaymentMethod.BankDraft });

                var trustItem3 = setup.Insert(new TrustItem { ItemEntityId = homeName.Id, ItemTransactionId = th3.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, ItemDate = yesterday, PostDate = yesterday, LocalBalance = 30000, ItemNo = itemNo3, LocalValue = 10003 });
                setup.Insert(new TrustHistory { ItemEntityId = homeName.Id, ItemTransactionId = th3.TransactionId, TrustAccountNameId = supplierName.Id, TrustAccountEntityId = homeName.Id, RefEntityId = homeName.Id, TransactionDate = yesterday, PostDate = yesterday, LocalBalance = 30000, ItemNo = itemNo3, MovementClass = MovementClass.Entered });
                setup.Insert(new CashItem { AccountEntityId = homeName.Id, TransactionId = th3.TransactionId, EntityId = homeName.Id, TransactionEntityId = homeName.Id, ItemDate = yesterday, BankNameId = bank2.Id, SequenceNo = 1, Status = TransactionStatus.Active, PaymentMethod = PaymentMethod.BankDraft });

                var trustAccountingData = new List<dynamic>
                {
                    new
                    {
                        EntityName = homeName.LastName,
                        BankAccount = bankAccount1.Description,
                        trustItem1.LocalBalance,
                        trustItem1.LocalValue
                    },
                    new
                    {
                        EntityName = homeName.LastName,
                        BankAccount = bankAccount2.Description,
                        LocalBalance = trustItem2.LocalBalance + trustItem3.LocalBalance,
                        LocalValue = trustItem2.LocalValue + trustItem3.LocalValue
                    }
                };

                var localCurrency = setup.DbContext.Set<SiteControl>()
                                         .Single(_ => _.ControlId == SiteControls.CURRENCY);
                return new
                {
                    Supplier = supplierName,
                    SendPayToName = sendPayToNameAttention,
                    TrustItemList = trustAccountingData,
                    Creditor = creditorData,
                    Individual = individual,
                    LocalCurrency = localCurrency.StringValue,
                    BankAccount1 = bankAccount1
                };
            });

            return data;
        }

        ScreenCriteriaBuilder GetScreenCriteriaBuilder(Name name, string internalProgram = KnownNamePrograms.NameEntry)
        {
            return new ScreenCriteriaBuilder(DbContext).CreateNameScreen(name, out _, internalProgram);
        }
    }
}