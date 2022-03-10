using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class BillingLanguageResolverFacts : FactBase
    {
        public class ResolveMethod : FactBase
        {
            BillingLanguageResolver CreateSubject()
            {
                return new(Db, Fixture.Today);
            }

            dynamic CreateMultiDebtorCase()
            {
                var @case = new Case {Irn = Fixture.String()}.In(Db);
                var debtor1 = new Name {LastName = Fixture.String("LastName")}.In(Db);
                var debtor2 = new Name {LastName = Fixture.String("LastName")}.In(Db);
                var debtorNameType = new NameType {NameTypeCode = KnownNameTypes.Debtor}.In(Db);

                new CaseNameBuilder(Db)
                {
                    Case = @case,
                    NameType = debtorNameType,
                    Name = debtor1,
                    Sequence = 0,
                    BillPercentage = 60
                }.Build().In(Db);

                new CaseNameBuilder(Db)
                {
                    Case = @case,
                    NameType = debtorNameType,
                    Name = debtor2,
                    Sequence = 1,
                    BillPercentage = 40
                }.Build().In(Db);

                return new
                {
                    Case = @case,
                    Debtor1 = debtor1,
                    Debtor2 = debtor2
                };
            }

            dynamic CreateLanguages()
            {
                var thaiLanguage = new TableCode {Name = "thai"}.In(Db);
                var frenchLanguage = new TableCode {Name = "french"}.In(Db);
                var dutchLanguage = new TableCode {Name = "dutch"}.In(Db);

                return new
                {
                    Thai = thaiLanguage,
                    French = frenchLanguage,
                    Dutch = dutchLanguage
                };
            }

            [Fact]
            public async Task ShouldPickLanguageThatBelongsToTheDebtorThatIsDerivedFromTheCase()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0}.In(Db);
                new NameLanguage {NameId = @case.Debtor2.Id, LanguageId = languages.Dutch.Id, Sequence = 0}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(null, @case.Case.Id);

                Assert.Equal(languages.Thai.Id, result);
            }

            [Fact]
            public async Task ShouldPickLanguageThatMatchesTheCaseProperty()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();

                @case.Case.PropertyTypeId = "match this";

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0, PropertyTypeId = "don't match this"}.In(Db);
                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Dutch.Id, Sequence = 0, PropertyTypeId = "match this"}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(@case.Debtor1.Id, @case.Case.Id);

                Assert.Equal(languages.Dutch.Id, result);
            }

            [Fact]
            public async Task ShouldPickLanguageThatMatchesTheCurrentOpenActionOfTheCase()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();

                var filingAction =
                    new OpenAction
                    {
                        CaseId = @case.Case.Id,
                        ActionId = "F",
                        Cycle = 1,
                        PoliceEvents = 1,
                        DateUpdated = Fixture.Today()
                    }.In(Db);

                var otherAction =
                    new OpenAction
                    {
                        CaseId = @case.Case.Id,
                        ActionId = "O",
                        Cycle = 1,
                        PoliceEvents = 1,
                        DateUpdated = Fixture.PastDate()
                    }.In(Db);

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0, ActionId = filingAction.ActionId}.In(Db);
                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Dutch.Id, Sequence = 1, ActionId = otherAction.ActionId}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(@case.Debtor1.Id, @case.Case.Id);

                Assert.Equal(languages.Thai.Id, result);
            }

            [Fact]
            public async Task ShouldPickLanguageThatMatchesTheProvidedActionRatherThanCurrentOpenActionOfTheCase()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();

                var filingAction =
                    new OpenAction
                    {
                        CaseId = @case.Case.Id,
                        ActionId = "F",
                        Cycle = 1,
                        PoliceEvents = 1,
                        DateUpdated = Fixture.Today()
                    }.In(Db);

                var otherAction =
                    new OpenAction
                    {
                        CaseId = @case.Case.Id,
                        ActionId = "O",
                        Cycle = 1,
                        PoliceEvents = 1,
                        DateUpdated = Fixture.PastDate()
                    }.In(Db);

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0, ActionId = filingAction.ActionId}.In(Db);
                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Dutch.Id, Sequence = 1, ActionId = otherAction.ActionId}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(@case.Debtor1.Id, @case.Case.Id, "O");

                Assert.Equal(languages.Dutch.Id, result);
            }

            [Fact]
            public async Task ShouldPickLanguageThatMatchesPropertyThenAction()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();
                var filingAction =
                    new OpenAction
                    {
                        CaseId = @case.Case.Id,
                        ActionId = "F",
                        Cycle = 1,
                        PoliceEvents = 1,
                        DateUpdated = Fixture.Today()
                    }.In(Db);

                @case.Case.PropertyTypeId = "match this";

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0, PropertyTypeId = "don't match this", ActionId = filingAction.ActionId}.In(Db);
                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Dutch.Id, Sequence = 1, PropertyTypeId = "match this"}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(@case.Debtor1.Id, @case.Case.Id);

                Assert.Equal(languages.Dutch.Id, result);
            }

            [Fact]
            public async Task ShouldReturnNullWhenNoNameLanguageForTheDebtorHasBeenSetup()
            {
                var @case = CreateMultiDebtorCase();
                var languages = CreateLanguages();

                new NameLanguage {NameId = @case.Debtor1.Id, LanguageId = languages.Thai.Id, Sequence = 0, PropertyTypeId = "doesn't match", ActionId = "doesn't match"}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(@case.Debtor1.Id, @case.Case.Id);

                Assert.Null(result);
            }

            [Fact]
            public async Task ShouldReturnDefaultNameLanguageWhenCaseIsNotProvided()
            {
                var debtor = new Name {LastName = Fixture.String("LastName")}.In(Db);
                var languages = CreateLanguages();

                new NameLanguage {NameId = debtor.Id, LanguageId = languages.Thai.Id, Sequence = 0, PropertyTypeId = "doesn't match", ActionId = "doesn't match"}.In(Db);

                new NameLanguage {NameId = debtor.Id, LanguageId = languages.Dutch.Id, Sequence = 1, PropertyTypeId = null, ActionId = null}.In(Db);

                var subject = CreateSubject();
                var result = await subject.Resolve(debtor.Id);

                Assert.Equal(languages.Dutch.Id, result);
            }
        }

        public class LanguageCultureIndexer
        {
            [Fact]
            public void ShouldIdentifySameIndexKey()
            {
                var key1 = (1, "en");
                var key2 = (1, "cn");
                var key3 = (2, "en");

                // Same method as used in the cache and indexer in BillingLanguageResolver
                var dictionary = new Dictionary<(int? LanguageKey, string Culture), string>
                {
                    {(1, "en"), "Description for 1 in English"}, 
                    {(2, "en"), "Description for 2 in English"}, 
                    {(1, "cn"), "Description for 1 in Chinese"}
                };

                Assert.Equal("Description for 2 in English", dictionary[key3]);
                Assert.Equal("Description for 1 in Chinese", dictionary[(1, "cn")]);
                Assert.Equal("Description for 1 in English", dictionary[key1]);
            }
        }
    }
}