using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Names.Consolidations;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Names
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public class NameConsolidations
    {
        [Test]
        public void ConsolidateCreditor()
        {
            var yesterday = DateTime.Today.AddDays(-1);

            /* https://confluence.cpaglobal.com/display/Staff/Database%3A+Navigating+Accounting+Transaction+History+Tables */

            var __ = DbSetup.Do(x =>
            {
                var homeName = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "homeOrg");
                var staff = new NameBuilder(x.DbContext).CreateStaff("staff");
                var bank = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "bank");

                x.Insert(new SpecialName(true, homeName));
                x.Insert(new SpecialName(true, bank) { IsBankOrFinancialInstitution = 1 });
                x.Insert(new BankAccount
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

                return new
                {
                    HomeNameId = homeName.Id,
                    StaffId = staff.Id,
                    BankId = bank.Id
                };
            });

            var agentTarget = SetupAgentData("target", "R", new[] { "US", "CA" });
            var agentToConsolidate = SetupAgentData("goner", "A", new[] { "SG", "US" });

            JobRunner.RunUntilComplete(nameof(NameConsolidationJob), new NameConsolidationArgs
            {
                ExecuteAs = 45,
                TargetId = agentTarget.FirmId,
                NameIds = new[] { (int)agentToConsolidate.FirmId },
                KeepTelecomHistory = false,
                KeepAddressHistory = false,
                KeepConsolidatedName = false
            });

            var result = DbSetup.Do(x =>
            {
                var allNameIds = new int[] { agentTarget.FirmId, agentTarget.AgentId, agentToConsolidate.FirmId, agentToConsolidate.AgentId };
                var allNames = x.DbContext.Set<Name>().Where(_ => allNameIds.Contains(_.Id));
                var associatedNames = x.DbContext.Set<AssociatedName>().Where(_ => allNameIds.Contains(_.Id) || allNameIds.Contains(_.RelatedNameId));
                var caseNames = x.DbContext.Set<CaseName>().Where(_ => allNameIds.Contains(_.NameId));
                var creditors = x.DbContext.Set<Creditor>().Where(_ => allNameIds.Contains(_.NameId));
                var creditorItems = x.DbContext.Set<CreditorItem>().Where(_ => allNameIds.Contains(_.AccountCreditorId));
                var creditorHistories = x.DbContext.Set<CreditorHistory>().Where(_ => allNameIds.Contains(_.AccountCreditorId));
                var creditorEntityDetails = x.DbContext.Set<CreditorEntityDetail>().Where(_ => allNameIds.Contains(_.NameId));
                var nameFilesIn = x.DbContext.Set<FilesIn>().Where(_ => allNameIds.Contains(_.NameId));
                var openItems = x.DbContext.Set<OpenItem>().Where(_ => allNameIds.Contains(_.AccountDebtorId));

                return new
                {
                    AssociatedNames = associatedNames.ToArray(),
                    CaseNames = caseNames.ToArray(),
                    Creditors = creditors.ToArray(),
                    CreditorItems = creditorItems.ToArray(),
                    CreditorHistories = creditorHistories.ToArray(),
                    CreditorEntityDetails = creditorEntityDetails.ToArray(),
                    Names = allNames.ToArray(),
                    NameFilesIn = nameFilesIn.ToArray(),
                    OpenItems = openItems.ToArray()
                };
            });

            AssertGeneralConsolidation();

            AssertAssociatedNameConsolidation();

            AssertFilesInConsolidation();

            AssertCreditorConsolidation();

            AssertCreditorEntityDetailConsolidation();

            AssertCreditorItemsConsolidation();

            AssertCreditorHistoryConsolidation();

            AssertOpenItems();
            
            void AssertOpenItems()
            {
                Assert.AreEqual(2, result.OpenItems.Length, "Should agent firms should merge, open item should transfer.");
                Assert.AreEqual(2, result.OpenItems.Where(oi=>oi.AccountDebtorId == agentTarget.FirmId).ToArray().Length, "Should agent firms should merge, open item should transfer.");
            }

            void AssertGeneralConsolidation()
            {
                Assert.AreEqual(3, result.Names.Length, "Should agent firms should merge, the agent from the consolidated firm should remain.");
                Assert.False(result.Names.Any(_ => _.Id == agentToConsolidate.FirmId), "Should not contain the firm that has been consolidated into the target.");
            }

            void AssertAssociatedNameConsolidation()
            {
                Assert.True(result.AssociatedNames.Any(_ => _.RelatedNameId == agentTarget.AgentId), "Should retain original agent employed by the name being consolidated into");
                Assert.True(result.AssociatedNames.Any(_ => _.RelatedNameId == agentToConsolidate.AgentId), "Should move employee relationship from from name being consolidated");
                Assert.False(result.AssociatedNames.Any(_ => _.Id == agentToConsolidate.FirmId), "Should not contain the consolidated name");
            }

            void AssertFilesInConsolidation()
            {
                var uniqueFilesIn = new HashSet<string>();
                uniqueFilesIn.AddRange((string[])agentTarget.FilesIn);
                uniqueFilesIn.AddRange((string[])agentToConsolidate.FilesIn);

                Assert.AreEqual(uniqueFilesIn.Count, result.NameFilesIn.Length, "Should retain combination of files in from both agents");
                Assert.True(result.NameFilesIn.Any(_ => _.NameId == agentTarget.FirmId), "Should retain files in by the agent firm being consolidated into");
                Assert.False(result.NameFilesIn.Any(_ => _.NameId == agentToConsolidate.FirmId), "Should add the files in from the consolidated name");
            }

            void AssertCreditorConsolidation()
            {
                Assert.False(result.Creditors.Any(_ => _.NameId == agentToConsolidate.FirmId), "Should not have consolidated name as creditor");
                Assert.True(result.Creditors.Any(_ => _.NameId == agentTarget.FirmId), "Name consolidated into should still exist");
            }

            void AssertCreditorEntityDetailConsolidation()
            {
                Assert.False(result.CreditorEntityDetails.Any(_ => _.NameId == agentToConsolidate.FirmId), "Should not have consolidated name as creditor");
                Assert.True(result.CreditorEntityDetails.Any(_ => _.NameId == agentTarget.FirmId), "Name consolidated into should still exist");
                Assert.AreEqual(agentTarget.SupplierAccountNumber, result.CreditorEntityDetails.Single().SupplierAccountNumber, "Should retain the supplier account number of the Name being consolidated into");
            }

            void AssertCreditorItemsConsolidation()
            {
                Assert.False(result.CreditorItems.Any(_ => _.AccountCreditorId == agentToConsolidate.FirmId), "Should not have consolidated name in CreditorItems.AcctCreditorNo");
                Assert.True(result.CreditorItems.Any(_ => _.AccountCreditorId == agentTarget.FirmId), "CreditorItems.AcctCreditorNo for name consolidated into should still exist");
            }

            void AssertCreditorHistoryConsolidation()
            {
                Assert.False(result.CreditorHistories.Any(_ => _.AccountCreditorId == agentToConsolidate.FirmId), "Should not have consolidated name CreditorHistories.AcctCreditorNo");
                Assert.True(result.CreditorHistories.Any(_ => _.AccountCreditorId == agentTarget.FirmId), "CreditorHistories.AcctCreditorNo for name consolidated into should still exist");
            }

            dynamic SetupAgentData(string name, string nameType, string[] filesIn)
            {
                using (var x = new DbSetup())
                {
                    var agentFirm = new NameBuilder(x.DbContext).CreateSupplierOrg("law firm " + name);

                    foreach (var f in filesIn) x.Insert(new FilesIn { NameId = agentFirm.Id, JurisdictionId = f });

                    var agent = new NameBuilder(x.DbContext).Create("agent " + name);
                    agent.UsedAs = NameUsedAs.Individual;

                    x.Insert(new Individual(agent.Id));
                    x.Insert(new AssociatedName(agentFirm, agent, "EMP", 0));

                    var agentOrRenewalAgent = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == nameType);

                    var anyCountryCode = filesIn.First();
                    var jurisdiction = x.DbContext.Set<Country>().Single(_ => _.Id == anyCountryCode);
                    var property = x.DbContext.Set<PropertyType>().Single(_ => _.Code == "P");

                    var case1 = new CaseBuilder(x.DbContext).Create("Case1" + Fixture.UriSafeString(5) + name, true, country: jurisdiction, propertyType: property);
                    var case2 = new CaseBuilder(x.DbContext).Create("Case2" + Fixture.UriSafeString(5) + name, true, country: jurisdiction, propertyType: property);
                    x.Insert(new CaseName(case1, agentOrRenewalAgent, agentFirm, 0) { AttentionNameId = agent.Id, InheritedFromNameId = agentFirm.Id, IsDerivedAttentionName = 0, IsInherited = 0 });
                    x.Insert(new CaseName(case2, agentOrRenewalAgent, agentFirm, 0) { AttentionNameId = agent.Id, IsDerivedAttentionName = 0, IsInherited = 0 });

                    x.Insert(new Account { EntityId = __.HomeNameId, NameId = agentFirm.Id, Balance = 0, CreditBalance = 0 });

                    // is a creditor with details
                    var supplierType = x.DbContext.Set<TableCode>().First(_ => _.TableTypeId == (short)TableTypes.SupplierType);
                    var taxTreatment = x.DbContext.Set<TableCode>().First(_ => _.TableTypeId == (short)TableTypes.TaxTreatment);

                    x.Insert(new Creditor
                    {
                        NameId = agentFirm.Id,
                        SupplierType = supplierType.Id,
                        TaxTreatment = taxTreatment.Id,
                        BankAccountOwner = __.HomeNameId,
                        BankNameNo = __.BankId,
                        BankSequenceNo = 1
                    });

                    var crEntityDetail = x.Insert(new CreditorEntityDetail
                    {
                        BankNameNo = __.BankId,
                        EntityNameNo = __.HomeNameId,
                        NameId = agentFirm.Id,
                        SequenceNo = 1,
                        SupplierAccountNumber = RandomString.Next(20)
                    });

                    var th = x.InsertWithNewId(new TransactionHeader
                    {
                        StaffId = __.StaffId,
                        EntityId = __.HomeNameId,
                        TransactionDate = yesterday,
                        EntryDate = yesterday,
                        TransactionType = TransactionType.ManualJournalEntry,
                        Source = SystemIdentifier.GeneralLedger, 
                        UserLoginId = RandomString.Next(20)
                    }, t => (short?)t.TransactionId);

                    var docRef = RandomString.Next(5);
                    x.Insert(new CreditorItem { ItemEntityId = __.HomeNameId, ItemTransactionId = th.TransactionId, AccountEntityId = __.HomeNameId, AccountCreditorId = agentFirm.Id, DocumentRef = docRef, ItemDate = yesterday });
                    x.Insert(new CreditorHistory { ItemEntityId = __.HomeNameId, ItemTransactionId = th.TransactionId, AccountEntityId = __.HomeNameId, AccountCreditorId = agentFirm.Id, DocumentRef = docRef, TransactionDate = yesterday, TransactionType = TransactionType.Purchase, HistoryLineNo = 1 });

                    x.Insert(new SpecialName(true, agent));
                    var transaction = x.DbContext.Set<TransactionHeader>().Add(new TransactionHeader() {EntityId = agent.Id, StaffId = agentFirm.Id, UserLoginId = "internal", EntryDate = DateTime.Now, TransactionDate = DateTime.MaxValue});
                    x.DbContext.SaveChanges();
                    x.Insert(new OpenItem(agent.Id, transaction.TransactionId, agent.Id, agentFirm) {OpenItemNo = name, AccountEntityId = __.HomeNameId, AccountDebtorId = agentFirm.Id});

                    return new
                    {
                        FirmId = agentFirm.Id,
                        AgentId = agent.Id,
                        Case1Id = case1.Id,
                        Case2Id = case2.Id,
                        crEntityDetail.SupplierAccountNumber,
                        FilesIn = filesIn
                    };
                }
            }
        }

        [Test]
        public void ConsolidateClient()
        {
            //create firm details
            var __ = DbSetup.Do(x =>
            {
                var lawfirm = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "homeOrg");
                var staff = new NameBuilder(x.DbContext).CreateStaff("staff");
                var bank = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "bank");

                x.Insert(new SpecialName(true, lawfirm));
                x.Insert(new SpecialName(true, bank) { IsBankOrFinancialInstitution = 1 });
                x.Insert(new BankAccount
                {
                    AccountOwner = lawfirm.Id,
                    BankNameNo = bank.Id,
                    SequenceNo = 1,
                    AccountName = RandomString.Next(5),
                    AccountNo = RandomString.Next(5),
                    Currency = "USD",
                    Description = RandomString.Next(10),
                    DrawChequesFlag = 1,
                    TrustAcctFlag = false
                });
                var user = x.DbContext.Set<User>().Single(_ => _.UserName == "internal");
                return new
                {
                    HomeNameId = lawfirm.Id,
                    StaffId = staff.Id,
                    BankId = bank.Id,
                    UserId = user.Id
                };
            });

            //create client
            var client1 = SetupClientData("Client1", "P", "AU", __.StaffId);
            var client2 = SetupClientData("Client2", "A", "AU", __.StaffId);

            dynamic SetupClientData(string name, string propertyTypeValue, string countryValue, int staffId)
            {
                using (var x = new DbSetup())
                {
                    //basic
                    var country = x.DbContext.Set<Country>().Single(_ => _.Id == countryValue);
                    var property = x.DbContext.Set<PropertyType>().Single(_ => _.Code == propertyTypeValue);
                    var client = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, name);
                    var clientCase = new CaseBuilder(x.DbContext).Create(name + Fixture.UriSafeString(5), true, country: country, propertyType: property);

                    //discount
                    x.Insert(new Discount
                    {
                        NameId = client.Id,
                        ActionId = null,
                        WipCategory = WipCategory.ServiceCharge,
                        EmployeeId = staffId,
                        BasedOnAmount = 0.01m,
                        PropertyTypeId = "N",
                        CountryId = country.Id,
                        CaseTypeId = clientCase.TypeId
                    });
                    x.Insert(new Discount
                    {
                        NameId = client.Id,
                        ActionId = null,
                        WipCategory = WipCategory.ServiceCharge,
                        BasedOnAmount = 0.01m,
                        PropertyTypeId = property.Code,
                        EmployeeId = staffId,
                        CountryId = country.Id,
                        CaseTypeId = clientCase.TypeId
                    });

                    //name Instruction
                    var lastNameInstruction = x.DbContext.Set<NameInstruction>().OrderByDescending(ni => ni.Sequence).First();

                    x.Insert(new NameInstruction
                    {
                        Id = client.Id,
                        Sequence = lastNameInstruction?.Sequence + 1 ?? 10001,
                        RestrictedToName = null,
                        CaseId = null,
                        CountryCode = country.Id,
                        PropertyType = "N"
                    });
                    x.Insert(new NameInstruction
                    {
                        Id = client.Id,
                        Sequence = lastNameInstruction?.Sequence + 2 ?? 10002,
                        RestrictedToName = null,
                        CaseId = null,
                        CountryCode = country.Id,
                        PropertyType = property.Code
                    });

                    return new
                    {
                        clientId = client.Id,
                        clientCase
                    };
                }
            }

            //consolidate
            JobRunner.RunUntilComplete(nameof(NameConsolidationJob), new NameConsolidationArgs
            {
                TargetId = client1.clientId,
                NameIds = new[] { (int)client2.clientId },
                ExecuteAs = __.UserId,
                KeepConsolidatedName = false,
                KeepTelecomHistory = true,
                KeepAddressHistory = true
            });

            //verify
            var clientIds = new[] { (int)client1.clientId, (int)client2.clientId };
            var result = DbSetup.Do(x =>
            {
                var discount = x.DbContext.Set<Discount>().Where(_ => clientIds.Contains(_.NameId ?? 0)).ToArray();
                var nameInstruction = x.DbContext.Set<NameInstruction>().Where(_ => clientIds.Contains(_.Id)).ToArray();
                return new
                {
                    discount,
                    nameInstruction
                };
            });

            AssertDiscounts();
            AssertNameInstructions();

            void AssertDiscounts()
            {
                Assert.AreEqual(3, result.discount.Length, "Should reduce discount from name number.");
                Assert.False(result.discount.Any(d => d.NameId == client2.clientId), "Should only have a single client name.");
                Assert.True(result.discount.Any(d => d.PropertyTypeId.Equals("N")), "Should have retained Property");
                Assert.True(result.discount.Any(d => d.PropertyTypeId.Equals("A")), "Should have retained Property");
                Assert.True(result.discount.Any(d => d.PropertyTypeId.Equals("P")), "Should have retained Property");
            }

            void AssertNameInstructions()
            {
                Assert.AreEqual(3, result.nameInstruction.Length, "Should reduce discount from name number.");
                Assert.False(result.nameInstruction.Any(d => d.Id == client2.clientId), "Should only have a single client name.");
                Assert.True(result.nameInstruction.Any(d => d.PropertyType.Equals("N")), "Should have retained Property");
                Assert.True(result.nameInstruction.Any(d => d.PropertyType.Equals("A")), "Should have retained Property");
                Assert.True(result.nameInstruction.Any(d => d.PropertyType.Equals("P")), "Should have retained Property");
            }
        }

        [Test]
        public void ConsolidateStaff()
        {
            var data = DbSetup.Do(x =>
            {
                var employer = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "employer");
                var client = new NameBuilder(x.DbContext).CreateClientOrg("client");

                var staff1 = new NameBuilder(x.DbContext).CreateStaff("staff1");
                var staff2 = new NameBuilder(x.DbContext).CreateStaff("staff2");
                var staff3 = new NameBuilder(x.DbContext).CreateStaff("staff3");

                var au = x.DbContext.Set<Country>().Single(_ => _.Id == "AU");
                var property = x.DbContext.Set<PropertyType>().Single(_ => _.Code == "P");
                var criteria = new CriteriaBuilder(x.DbContext).Create("testCriteria");
                var case1 = new CaseBuilder(x.DbContext).Create("Case1" + Fixture.UriSafeString(5), true, country: au, propertyType: property);
                var case2 = new CaseBuilder(x.DbContext).Create("Case2" + Fixture.UriSafeString(5), true, country: au, propertyType: property);
                var user = x.DbContext.Set<User>().Single(_ => _.UserName == "internal");

                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 0, AgentId = null, DebtorId = staff2.Id, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 1, AgentId = null, DebtorId = staff2.Id, DebtorType = null, CycleNumber = 1, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 2, AgentId = staff2.Id, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 3, AgentId = staff2.Id, DebtorId = null, DebtorType = null, CycleNumber = 1, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 4, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = staff2.Id, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 5, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 1, OwnerId = staff2.Id, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 6, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = staff2.Id });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 7, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 1, OwnerId = null, InstructorId = staff2.Id });

                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 8, AgentId = null, DebtorId = staff1.Id, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 9, AgentId = null, DebtorId = staff1.Id, DebtorType = null, CycleNumber = 2, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 10, AgentId = staff1.Id, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 11, AgentId = staff1.Id, DebtorId = null, DebtorType = null, CycleNumber = 2, OwnerId = null, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 12, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = staff1.Id, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 13, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 2, OwnerId = staff1.Id, InstructorId = null });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 14, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 0, OwnerId = null, InstructorId = staff1.Id });
                x.Insert(new FeesCalculation { CriteriaId = criteria.Id, UniqueId = 15, AgentId = null, DebtorId = null, DebtorType = null, CycleNumber = 2, OwnerId = null, InstructorId = staff1.Id });

                x.Insert(new Individual(staff1.Id) { CasualSalutation = "hello" });
                x.Insert(new Individual(staff2.Id) { CasualSalutation = "mate" });
                x.Insert(new Individual(staff3.Id) { CasualSalutation = "mate20" });

                // CASENAME.CORRESPONDNAME
                var nametype = x.DbContext.Set<NameType>().SingleOrDefault(nt => nt.NameTypeCode.Equals(KnownNameTypes.Lead)); //t&1 =0
                x.Insert(new CaseName(case1, nametype, staff3, 1) { IsDerivedAttentionName = 0m, AttentionNameId = staff2.Id });
                x.Insert(new CaseName(case1, nametype, staff3, 2) { IsDerivedAttentionName = 1m, AttentionNameId = staff2.Id });
                var asoName = new NameBuilder(x.DbContext).CreateStaff("associatename");
                var nametypeI = x.DbContext.Set<NameType>().SingleOrDefault(nt => nt.NameTypeCode.Equals(KnownNameTypes.Instructor)); //t&1 =0
                x.Insert(new CaseName(case1, nametypeI, staff3, 3)
                {
                    IsDerivedAttentionName = 1m,
                    InheritedFromNameId = asoName.Id,
                    InheritedFromRelationId = "LEA",
                    InheritedFromSequence = 3,
                    AttentionNameId = staff2.Id
                });

                x.Insert(new AssociatedName(asoName, staff3, "LEA", 3) { ContactId = staff1.Id });

                var addressType = x.DbContext.Set<TableCode>().First(_ => _.TableTypeId == (short)TableTypes.AddressType);
                var address = x.InsertWithNewId(new Address { Country = au, City = "Sydney", State = "NSW" });
                x.Insert(new NameAddress(staff2, address, addressType));

                var textTypes = x.DbContext.Set<TextType>().Select(_ => _.Id).Take(2).ToArray();
                var aliasTypes = x.DbContext.Set<NameAliasType>().Take(2).ToArray();

                x.Insert(new NameAlias { AliasType = aliasTypes.First(), NameId = staff1.Id, Alias = "Original" });
                x.Insert(new NameAlias { AliasType = aliasTypes.First(), NameId = staff2.Id, Alias = "Original" });
                x.Insert(new NameAlias { AliasType = aliasTypes.Last(), NameId = staff2.Id, Alias = "Copy" });

                x.Insert(new AssociatedName(employer, staff1, "EMP", 0));
                x.Insert(new AssociatedName(employer, staff2, "EMP", 0));
                x.Insert(new AssociatedName(client, staff2, "RES", 0));

                x.Insert(new NameText { Id = staff1.Id, TextType = textTypes.First(), Text = "Stay" });
                x.Insert(new NameText { Id = staff2.Id, TextType = textTypes.First(), Text = "Cannot copy into staff1 because text type already exist" });
                x.Insert(new NameText { Id = staff2.Id, TextType = textTypes.Last(), Text = "Copy" });

                x.DbContext.Update(from cn in x.DbContext.Set<CaseName>()
                                   where (cn.NameTypeId == KnownNameTypes.StaffMember || cn.NameTypeId == KnownNameTypes.Signatory)
                                         && (cn.CaseId == case1.Id || cn.CaseId == case2.Id)
                                   select cn, _ => new CaseName {NameId = staff2.Id});

                x.Insert(new StaffReminder {StaffId = staff1.Id, DateCreated = DateTime.Now.AddSeconds(1), CaseId = case1.Id});
                x.Insert(new StaffReminder {StaffId = staff1.Id, DateCreated = DateTime.Now.AddSeconds(2), CaseId = case2.Id, SequenceNo = 2, ShortMessage = "This prevents the below from consolidating"});
                x.Insert(new StaffReminder {StaffId = staff2.Id, DateCreated = DateTime.Now.AddSeconds(3), CaseId = case2.Id}); // should consolidate staff reminder
                x.Insert(new StaffReminder {StaffId = staff2.Id, DateCreated = DateTime.Now.AddSeconds(4), CaseId = case2.Id, SequenceNo = 2, ShortMessage = "Not Consolidate as it duplicates"});
                x.Insert(new StaffReminder {StaffId = staff3.Id, DateCreated = DateTime.Now.AddSeconds(5), CaseId = case2.Id, AlertNameId = staff2.Id}); // should consolidate staff reminder
                x.Insert(new StaffReminder {StaffId = staff3.Id, DateCreated = DateTime.Now.AddSeconds(6), CaseId = case2.Id, NameId = staff2.Id});

                var startOfDay = DateTime.Today.AddHours(7);
                var endOfDay = DateTime.Today.AddHours(15);
                var totalTimeDay = new DateTime(1899, 01, 01).AddHours(7);

                x.Insert(new Diary { EmployeeNo = staff2.Id, EntryNo = 1, Activity = "EVID", CaseId = case1.Id, StartTime = startOfDay.AddDays(-3), FinishTime = endOfDay.AddDays(-3), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });
                x.Insert(new Diary { EmployeeNo = staff2.Id, EntryNo = 2, Activity = "EVID", CaseId = case1.Id, StartTime = startOfDay.AddDays(-2), FinishTime = endOfDay.AddDays(-2), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });
                x.Insert(new Diary { EmployeeNo = staff2.Id, EntryNo = 3, Activity = "EVID", CaseId = case1.Id, StartTime = startOfDay.AddDays(-1), FinishTime = endOfDay.AddDays(-1), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });

                x.Insert(new Diary { EmployeeNo = staff1.Id, EntryNo = 1, NameNo = staff2.Id, Activity = "SEARCH", CaseId = case1.Id, StartTime = startOfDay.AddDays(-3), FinishTime = endOfDay.AddDays(-3), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });
                x.Insert(new Diary { EmployeeNo = staff1.Id, EntryNo = 2, NameNo = staff2.Id, Activity = "SEARCH", CaseId = case1.Id, StartTime = startOfDay.AddDays(-2), FinishTime = endOfDay.AddDays(-2), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });
                x.Insert(new Diary { EmployeeNo = staff1.Id, EntryNo = 3, NameNo = staff2.Id, Activity = "SEARCH", CaseId = case1.Id, StartTime = startOfDay.AddDays(-1), FinishTime = endOfDay.AddDays(-1), TotalTime = totalTimeDay, CreatedOn = DateTime.Now });

                return new
                {
                    Staff1Id = staff1.Id,
                    Staff2Id = staff2.Id,
                    Staff3Id = staff3.Id,
                    ClientId = client.Id,
                    EmployerId = employer.Id,
                    ExecuteAs = user.Id,
                    Cases = new[] { (int?)case1.Id, (int?)case2.Id },
                    AddressId = address.Id,
                    AddressType = addressType.Id,
                };
            });

            JobRunner.RunUntilComplete(nameof(NameConsolidationJob), new NameConsolidationArgs
            {
                TargetId = data.Staff1Id,
                NameIds = new[] { data.Staff2Id },
                ExecuteAs = data.ExecuteAs,
                KeepConsolidatedName = false,
                KeepTelecomHistory = true,
                KeepAddressHistory = true
            });

            var result = DbSetup.Do(x =>
            {
                var caseIds = data.Cases;
                var nameIds = new[] { data.Staff1Id, data.Staff2Id };
                var allStaffReminders = x.DbContext.Set<StaffReminder>().Where(_ => caseIds.Contains(_.CaseId));
                var staffNames = x.DbContext.Set<Name>()
                                  .Include(_ => _.Addresses)
                                  .Where(_ => nameIds.Contains(_.Id));
                var nameTexts = x.DbContext.Set<NameText>()
                                 .Where(_ => nameIds.Contains(_.Id));
                var nameAlias = x.DbContext.Set<NameAlias>()
                                 .Where(_ => nameIds.Contains(_.NameId));
                var associatedNames = x.DbContext.Set<AssociatedName>()
                                       .Where(_ => nameIds.Contains(_.Id) || nameIds.Contains(_.RelatedNameId));
                var diaries = x.DbContext.Set<Diary>()
                               .Where(_ => nameIds.Contains(_.EmployeeNo));
                var caseNames = x.DbContext.Set<CaseName>()
                                 .Where(_ => nameIds.Contains(_.NameId));
                var individuals = x.DbContext.Set<Individual>()
                                   .Where(_ => nameIds.Contains(_.NameId));
                var debtors = x.DbContext.Set<FeesCalculation>()
                                   .Where(_ => nameIds.Contains(_.DebtorId ?? 0));
                var agents = x.DbContext.Set<FeesCalculation>()
                               .Where(_ => nameIds.Contains(_.AgentId ?? 0));
                var instructors = x.DbContext.Set<FeesCalculation>()
                               .Where(_ => nameIds.Contains(_.InstructorId ?? 0));
                var owners = x.DbContext.Set<FeesCalculation>()
                               .Where(_ => nameIds.Contains(_.OwnerId ?? 0));
                var caseAttendionNames = x.DbContext.Set<CaseName>()
                                 .Where(_ => _.NameId == data.Staff3Id);

                return new
                {
                    AssociatedNames = associatedNames.ToArray(),
                    CaseNames = caseNames.ToArray(),
                    Diaries = diaries.ToArray(),
                    Individuals = individuals.ToArray(),
                    NameAlias = nameAlias.ToArray(),
                    NameTexts = nameTexts.ToArray(),
                    Reminders = allStaffReminders.ToArray(),
                    StaffNames = staffNames.ToArray(),
                    debtors = debtors.ToArray(),
                    agents = agents.ToArray(),
                    instructors = instructors.ToArray(),
                    owners = owners.ToArray(),
                    caseAttendionNames = caseAttendionNames.ToArray()
                };
            });

            AssertGeneralConsolidation();

            AssertStaffRemindersConsolidation();

            AssertKeepAddressHistoryConsolidation();

            AssertNameTextConsolidation();

            AssertAssociatedNamesConsolidation();

            AssertNameAliasConsolidation();

            AssertDiaryConsolidation();

            AssertCaseNameConsolidation();

            AssertFeesCalculation();

            AssertCorrespondName();

            void AssertCorrespondName()
            {
                Assert.AreEqual(3, result.caseAttendionNames.Length, "Should have correct correspond names.");
                Assert.AreEqual(2, result.caseAttendionNames.Where(c => c.AttentionNameId == data.Staff1Id).ToArray().Length, "Should have correct number of to correspond names.");
                Assert.AreEqual(1, result.caseAttendionNames.Where(c => c.InheritedFromSequence == 3).ToArray().Length, "Should have correct number of to Inherited name.");
            }

            void AssertFeesCalculation()
            {
                Assert.AreEqual(3, result.debtors.Length, "Should only have a single debtor name.");
                Assert.False(result.debtors.Any(d => d.DebtorId == data.Staff2Id), "Should only have a single debtor name.");
                Assert.AreEqual(3, result.agents.Length, "Should only have a single agents name.");
                Assert.False(result.agents.Any(d => d.AgentId == data.Staff2Id), "Should only have a single debtor name.");
                Assert.AreEqual(3, result.instructors.Length, "Should only have a single instructors name.");
                Assert.False(result.instructors.Any(d => d.InstructorId == data.Staff2Id), "Should only have a single debtor name.");
                Assert.AreEqual(3, result.owners.Length, "Should only have a single owners name.");
                Assert.False(result.owners.Any(d => d.OwnerId == data.Staff2Id), "Should only have a single debtor name.");
            }

            void AssertGeneralConsolidation()
            {
                Assert.AreEqual(1, result.StaffNames.Length, "Should only have a single staff name.");
                Assert.AreEqual(1, result.Individuals.Length, "Should only have a single staff name.");
                Assert.True(result.StaffNames.Any(_ => _.Id == data.Staff1Id), "Should only have the consolidate to name returned");
                Assert.AreEqual("hello", result.Individuals.Single().CasualSalutation, "Should not override with consolidated name salutation");
            }

            void AssertStaffRemindersConsolidation()
            {
                Assert.IsEmpty(result.Reminders.Where(_ => _.StaffId == data.Staff2Id), "Should not have any staff reminders addressed to name already consolidated");
                Assert.IsEmpty(result.Reminders.Where(_ => _.AlertNameId == data.Staff2Id), "Should not have any staff reminders alerts for the name already consolidated");
                Assert.IsEmpty(result.Reminders.Where(_ => _.NameId == data.Staff2Id), "Should not have any staff reminders alerts that references the name already consolidated");

                Assert.AreEqual(3, result.Reminders.Count(_ => _.StaffId == data.Staff1Id), "Should consist of 3 staff reminders from the consolidation");
                Assert.False(result.Reminders.Any(_ => _.StaffId == data.Staff1Id && _.ShortMessage == "Not Consolidate as it duplicates"), "Should not consist of staff reminders that might violate unique constraints");
            }

            void AssertKeepAddressHistoryConsolidation()
            {
                Assert.True(result.StaffNames.Single(_ => _.Id == data.Staff1Id)
                                  .Addresses.Any(_ => _.AddressId == data.AddressId && _.AddressType == data.AddressType), "Should consolidate address from Staff2");
            }

            void AssertNameTextConsolidation()
            {
                Assert.True(result.NameTexts.Any(_ => _.Id == data.Staff1Id && (_.Text == "Stay" || _.Text == "Copy")), "Should consolidate name texts that will not violate unique constraint");
                Assert.False(result.NameTexts.Any(_ => _.Text == "Cannot copy into staff1 because text type already exist"), "Should not consolidate name texts that will violate unique constraint");
            }

            void AssertAssociatedNamesConsolidation()
            {
                Assert.AreEqual(2, result.AssociatedNames.Length, "Should consolidate into EMP and RES relationship only");
                Assert.True(result.AssociatedNames.Any(_ => _.Id == data.ClientId && _.Relationship == "RES"), "Should become staff responsible for the client (previously from staff2)");
            }

            void AssertNameAliasConsolidation()
            {
                Assert.AreEqual(2, result.NameAlias.Length, "Should consolidate the one alias that staff1 did not have");
            }

            void AssertDiaryConsolidation()
            {
                Assert.AreEqual(6, result.Diaries.Length, "Should have all diaries assigned to staff1");
                Assert.AreEqual(3, result.Diaries.Count(_ => _.NameNo == data.Staff1Id), "Should have all diaries nameno previously assigned to staff2 becomes staff1");
            }

            void AssertCaseNameConsolidation()
            {
                Assert.AreEqual(4, result.CaseNames.Length, "Should have all EMP and PR set to staff1");
            }
        }
    }
}