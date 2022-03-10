using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Names.Consolidations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Cash;
using InprotechKaizen.Model.Accounting.Cost;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Consolidations
{
    public class NamesConsolidationValidatorFacts
    {
        public class NameTypeValidation : FactBase
        {
            [Theory]
            [InlineData(NameUsedAs.StaffMember)]
            [InlineData(NameUsedAs.Individual)]
            public async Task IndividualNonClientToIndividualClient(short type)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName((short)(type | NameUsedAs.Individual), out var notWorking)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("nonclient-client", r.Errors.Single().Error);
            }

            [Theory]
            [InlineData(NameUsedAs.StaffMember, 2)]
            [InlineData(NameUsedAs.Individual, 1)]
            public async Task IndividualClientToIndividualNonClient(short targetType, int errorCount)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName((short)(targetType | NameUsedAs.Individual), out var target)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var notWorking)
                        .CreateName(NameUsedAs.Individual | NameUsedAs.Individual, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Equal(errorCount, r.Errors.Count());
                Assert.Contains(notWorking.Id, r.Errors.Select(_ => _.NameNo));
                Assert.Contains("client-nonclient", r.Errors.Select(_ => _.Error));
            }

            [Theory]
            [InlineData(NameUsedAs.Individual)]
            public async Task IndividualToStaff(short type)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var target)
                        .CreateName((short)(type | NameUsedAs.Individual), out var notWorking)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("sta-ind", r.Errors.Single().Error);
            }

            [Theory]
            [InlineData(NameUsedAs.Individual)]
            public async Task StaffToIndividual(short type)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName((short)(type | NameUsedAs.Individual), out var target)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var notWorking)
                        .CreateName((short)(type | NameUsedAs.Individual), out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("ind-sta", r.Errors.Single().Error);
            }

            [Theory]
            [InlineData(NameUsedAs.Organisation)]
            [InlineData(NameUsedAs.Client)]
            public async Task OrganizationToStaff(short type)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var target)
                        .CreateName((short)(type | NameUsedAs.Organisation), out var notWorking)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("org-sta", r.Errors.Single().Error);
            }

            [Fact]
            public async Task StaffToOrganization()
            {
                var type = NameUsedAs.Organisation;
                var f = new NamesConsolidationFixture(Db)
                        .CreateName((short)(type | NameUsedAs.Organisation), out var target)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var notWorking)
                        .CreateName(NameUsedAs.Organisation, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, false);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("sta-org", r.Errors.Single().Error);

                type = NameUsedAs.Client;
                f = new NamesConsolidationFixture(Db)
                        .CreateName((short)(type | NameUsedAs.Organisation), out target)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out notWorking)
                        .CreateName(NameUsedAs.Organisation, out var notWorkingOnClientMismatch);

                r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, notWorkingOnClientMismatch.Id }, false);
                Assert.Equal(2, r.Errors.Count());
                Assert.Contains(notWorking.Id, r.Errors.Select(_ => _.NameNo));
                Assert.Contains("sta-org", r.Errors.Select(_ => _.Error));
                Assert.Contains(notWorkingOnClientMismatch.Id, r.Errors.Select(_ => _.NameNo));
                Assert.Contains("nonclient-client", r.Errors.Select(_ => _.Error));
            }
        }

        public class FinancialDataValidation : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfThereAreBlockingNameTypeErrors()
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Organisation, out var target)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var notWorking)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Organisation, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, true);
                Assert.False(r.FinancialCheckPerformed);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);
                Assert.Equal("sta-org", r.Errors.Single().Error);
            }

            [Fact]
            public async Task DoesNotReturnErrorIfThereAreNonBlockingNameTypeErrors()
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName(NameUsedAs.StaffMember | NameUsedAs.Individual, out var notWorking)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var working);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id, working.Id }, true);
                Assert.True(r.FinancialCheckPerformed);
                Assert.Empty(r.Errors);
            }

            [Fact]
            public async Task AutomaticallyDoesFinancialValidationIfNoTypeErrors()
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var working)
                        .CreateAccountingEntry(working.Id);

                var r = await f.Subject.Validate(target.Id, new[] { working.Id }, false);
                Assert.True(r.FinancialCheckPerformed);
                Assert.Single(r.Errors);
                Assert.Equal(working.Id, r.Errors.Single().NameNo);
                Assert.Equal("acct-entry", r.Errors.Single().Error);
            }

            [Theory]
            [InlineData(1, null)]
            [InlineData(null, 1)]
            public async Task ChecksPendingBalanceWhenConsolidatingIntoCeasedName(int? balance, int? crBalance)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateInActiveName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var working)
                        .CreatePendingBalance(working.Id, balance, crBalance);

                var r = await f.Subject.Validate(target.Id, new[] { working.Id }, true);
                Assert.True(r.FinancialCheckPerformed);
                Assert.Single(r.Errors);
                Assert.Equal(working.Id, r.Errors.Single().NameNo);
                Assert.Equal("pen-bal", r.Errors.Single().Error);
            }

            [Fact]
            public async Task DoesNotCheckPendingBalanceWhenConsolidatingIntoActiveName()
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var working)
                        .CreatePendingBalance(working.Id, Fixture.Decimal());

                var r = await f.Subject.Validate(target.Id, new[] { working.Id }, true);
                Assert.True(r.FinancialCheckPerformed);
                Assert.Empty(r.Errors);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsBlockingErrorBasedOnSiteControlValue(bool siteControlValue)
            {
                var f = new NamesConsolidationFixture(Db)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var target)
                        .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out var notWorking)
                        .SetNameConsolidateFinancialsSiteControl(siteControlValue);
                new Diary()
                {
                    EmployeeNo = notWorking.Id
                }.In(Db);

                var r = await f.Subject.Validate(target.Id, new[] { notWorking.Id }, false);
                Assert.True(r.FinancialCheckPerformed);
                Assert.Single(r.Errors);
                Assert.Equal(notWorking.Id, r.Errors.Single().NameNo);

                if (siteControlValue)
                {
                    Assert.False(r.Errors.Single().IsBlocking);
                    Assert.Equal("fin-warn", r.Errors.Single().Error);
                }
                else
                {
                    Assert.True(r.Errors.Single().IsBlocking);
                    Assert.Equal("fin-block", r.Errors.Single().Error);
                }
            }

            public class FinancialTables : FactBase
            {
                Name _target;
                Name _notWorking;
                NamesConsolidationFixture _fixture;

                public FinancialTables()
                {
                    Setup();
                }
                void Setup()
                {
                    _fixture = new NamesConsolidationFixture(Db)
                         .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out _target)
                         .CreateName(NameUsedAs.Client | NameUsedAs.Individual, out _notWorking);
                }

                async Task TestResult()
                {
                    var r = await _fixture.Subject.Validate(_target.Id, new[] { _notWorking.Id }, false);
                    Assert.True(r.FinancialCheckPerformed);
                    Assert.Single(r.Errors);
                    Assert.Equal(_notWorking.Id, r.Errors.Single().NameNo);
                    Assert.Equal("fin-block", r.Errors.Single().Error);
                }

                [Theory]
                [InlineData(true, false)]
                [InlineData(false, true)]
                public async Task CheckDiary(bool employeeNo, bool nameNo)
                {
                    if (employeeNo)
                        _fixture.Add<Diary>(_ => _.EmployeeNo = _notWorking.Id);

                    if (nameNo)
                        _fixture.Add<Diary>(_ => _.NameNo = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false)]
                [InlineData(false, true)]
                public async Task CheckWorkHistory(bool employeeNo, bool acctClientNo)
                {
                    if (employeeNo)
                        _fixture.Add<WorkHistory>(_ => _.StaffId = _notWorking.Id);

                    if (acctClientNo)
                        _fixture.Add<WorkHistory>(_ => _.AccountClientId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false)]
                [InlineData(false, true)]
                public async Task CheckDebitorCreditorHistory(bool debitorHistory, bool creditorHistory)
                {
                    if (debitorHistory)
                        _fixture.Add<DebtorHistory>(_ => _.AccountDebtorId = _notWorking.Id);

                    if (creditorHistory)
                        _fixture.Add<CreditorHistory>(_ => _.AccountCreditorId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false, false)]
                [InlineData(false, true, false)]
                [InlineData(false, false, true)]
                public async Task CheckCashTaxBankHistory(bool cashHistory, bool taxHistory, bool bankHistory)
                {
                    if (cashHistory)
                        _fixture.Add<CashHistory>(_ => _.AccountNameId = _notWorking.Id);

                    if (taxHistory)
                        _fixture.Add<TaxHistory>(_ => _.AccountDebtorId = _notWorking.Id);

                    if (bankHistory)
                        _fixture.Add<BankHistory>(_ => _.BankNameId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false, false, false)]
                [InlineData(false, true, false, false)]
                [InlineData(false, false, true, false)]
                [InlineData(false, false, false, true)]
                public async Task CheckTimeCosting(bool nameNo, bool employeeNo, bool owner, bool instructor)
                {
                    if (nameNo)
                        _fixture.Add<TimeCosting>(_ => _.NameNo = _notWorking.Id);
                    if (employeeNo)
                        _fixture.Add<TimeCosting>(_ => _.EmployeeNo = _notWorking.Id);
                    if (owner)
                        _fixture.Add<TimeCosting>(_ => _.Owner = _notWorking.Id);
                    if (instructor)
                        _fixture.Add<TimeCosting>(_ => _.Instructor = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(typeof(TransactionHeader))]
                public async Task CheckData(Type type)
                {
                    if (type == typeof(TransactionHeader))
                        _fixture.Add<TransactionHeader>(_ => _.StaffId = _notWorking.Id);
                    else if (type == typeof(NameMarginProfile))
                        _fixture.Add<NameMarginProfile>(_ => _.NameId = _notWorking.Id);
                    else if (type == typeof(GlAccountMapping))
                        _fixture.Add<GlAccountMapping>(_ => _.WipStaffId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false)]
                [InlineData(false, true)]
                public async Task CheckNameAddressSnap(bool nameNo, bool attnNameNo)
                {
                    if (nameNo)
                        _fixture.Add<NameAddressSnapshot>(_ => _.NameId = _notWorking.Id);

                    if (attnNameNo)
                        _fixture.Add<NameAddressSnapshot>(_ => _.AttentionNameId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false)]
                [InlineData(false, true)]
                public async Task CheckMargin(bool agent, bool instructor)
                {
                    if (agent)
                        _fixture.Add<Margin>(_ => _.AgentId = _notWorking.Id);

                    if (instructor)
                        _fixture.Add<Margin>(_ => _.InstructorId = _notWorking.Id);

                    await TestResult();
                }

                [Theory]
                [InlineData(true, false, false, false)]
                [InlineData(false, true, false, false)]
                [InlineData(false, false, true, false)]
                [InlineData(false, false, false, true)]
                public async Task CheckFeeCalculation(bool agent, bool owner, bool debtor, bool instructor)
                {
                    if (agent)
                        _fixture.Add<FeesCalculation>(_ => _.AgentId = _notWorking.Id);
                    if (owner)
                        _fixture.Add<FeesCalculation>(_ => _.OwnerId = _notWorking.Id);
                    if (debtor)
                        _fixture.Add<FeesCalculation>(_ => _.DebtorId = _notWorking.Id);
                    if (instructor)
                        _fixture.Add<FeesCalculation>(_ => _.InstructorId = _notWorking.Id);

                    await TestResult();
                }
            }
        }
    }

    class NamesConsolidationFixture : IFixture<NamesConsolidationValidator>
    {
        public NamesConsolidationFixture(InMemoryDbContext db)
        {
            Db = db;
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new NamesConsolidationValidator(Db, SiteControlReader, Fixture.Today);
        }

        public NamesConsolidationValidator Subject { get; }

        InMemoryDbContext Db { get; }
        ISiteControlReader SiteControlReader { get; }

        public NamesConsolidationFixture CreateName(short usedAs, out Name name)
        {
            var lastName = Fixture.String();
            name = new Name
            {
                NameCode = Fixture.String(),
                LastName = lastName,
                UsedAs = usedAs,
                SearchKey1 = lastName.ToUpper()
            }.In(Db);

            return this;
        }

        public NamesConsolidationFixture CreateInActiveName(short usedAs, out Name name)
        {
            var lastName = Fixture.String();
            name = new Name
            {
                NameCode = Fixture.String(),
                LastName = lastName,
                UsedAs = usedAs,
                SearchKey1 = lastName.ToUpper(),
                DateCeased = Fixture.PastDate()
            }.In(Db);

            return this;
        }

        public NamesConsolidationFixture CreateAccountingEntry(int nameNo)
        {
            new SpecialName
            {
                Id = nameNo,
                IsEntity = 1
            }.In(Db);

            return this;
        }

        public NamesConsolidationFixture SetNameConsolidateFinancialsSiteControl(bool value)
        {
            SiteControlReader.Read<bool>(SiteControls.NameConsolidateFinancials).Returns(value);
            return this;
        }

        public NamesConsolidationFixture CreatePendingBalance(int nameNo, decimal? balance = null, decimal? crBalance = null)
        {
            new Account
            {
                NameId = nameNo,
                CreditBalance = crBalance,
                Balance = balance
            }.In(Db);

            return this;
        }

        public T Add<T>(Action<T> func) where T : class, new()
        {
            var t = new T();
            func(t);
            return t.In(Db);
        }
    }
}