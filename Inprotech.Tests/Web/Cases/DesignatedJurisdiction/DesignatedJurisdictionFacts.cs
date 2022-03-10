using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details.DesignatedJurisdiction;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.DesignatedJurisdiction
{
    public class DesignatedJurisdictionsFacts : FactBase
    {
        public class InternalUser : FactBase
        {
            void AssertJurisdictionData(DesignatedJurisdictionData data, DesignatedJurisdictionData result)
            {
                Assert.Equal(data.Jurisdiction, result.Jurisdiction);
                Assert.Equal(data.DesignatedStatus, result.DesignatedStatus);
                Assert.Equal(data.CountryCode, result.CountryCode);
                Assert.Equal(data.OfficialNumber, result.OfficialNumber);
                Assert.Equal(data.PriorityDate, result.PriorityDate);
                Assert.Equal(data.Classes?.Replace(",", ", "), result.Classes);
                Assert.Equal(data.InternalReference, result.InternalReference);
                Assert.Equal(data.CaseStatus, result.CaseStatus);
                Assert.Equal(data.CaseKey, result.CaseKey);
                Assert.Equal(data.Notes, result.Notes);
            }

            [Fact]
            public async Task GetDataForInternal()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser();
                var @case = f.CreateCase();
                var relatedCase = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.First());
                f.SetAuthorizationFor(relatedCase.CaseKey.GetValueOrDefault());

                var r = (await f.Subject.Get(@case.Id)).ToArray();
                f.CaseAuthorization.Received(1).AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Single(r);
                AssertJurisdictionData(relatedCase, r.First());
                Assert.DoesNotContain(r, _ => !_.CanView);
            }

            [Fact]
            public async Task GetDataForInternalClearsIrnsForUnAuthorizedCases()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser();
                var @case = f.CreateCase();
                var relatedCase = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.First());
                var relatedCase2 = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.Last());
                var relatedCase3 = f.CreateEmptyRelatedCase(@case.Id, @case.Country.CountryFlags.Last());
                f.SetAuthorizationFor(relatedCase.CaseKey.GetValueOrDefault());

                var r = (await f.Subject.Get(@case.Id)).ToArray();
                f.CaseAuthorization.Received(1).AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(3, r.Length);

                AssertJurisdictionData(relatedCase, r.First(_ => _.Jurisdiction == relatedCase.Jurisdiction));
                relatedCase2.InternalReference = null;
                relatedCase2.CaseKey = null;
                AssertJurisdictionData(relatedCase2, r.First(_ => _.Jurisdiction == relatedCase2.Jurisdiction));
                relatedCase3.Classes = @case.LocalClasses;
                AssertJurisdictionData(relatedCase3, r.First(_ => _.Jurisdiction == relatedCase3.Jurisdiction));
                Assert.Contains(r, _ => !_.CanView);
            }

            [Fact]
            public async Task GetDataForInternalReturnsMultipleRelatedCases()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser();
                var @case = f.CreateCase();
                var relatedCase = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.First());
                var relatedCase2 = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.Last());
                f.SetAuthorizationFor(relatedCase.CaseKey.GetValueOrDefault(), relatedCase2.CaseKey.GetValueOrDefault());

                var r = (await f.Subject.Get(@case.Id)).ToArray();
                f.CaseAuthorization.Received(1).AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, r.Length);

                AssertJurisdictionData(relatedCase, r.First(_ => _.Jurisdiction == relatedCase.Jurisdiction));
                AssertJurisdictionData(relatedCase2, r.First(_ => _.Jurisdiction == relatedCase2.Jurisdiction));
                Assert.DoesNotContain(r, _ => !_.CanView);
            }

            [Fact]
            public async Task GetDataForInternalReturnsMultipleRelatedCasesIncludingEmptyRelatedCaseId()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser();
                var @case = f.CreateCase();
                var relatedCase = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.First());
                var relatedCase2 = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.Last());
                var relatedCase3 = f.CreateEmptyRelatedCase(@case.Id, @case.Country.CountryFlags.Last());
                f.SetAuthorizationFor(relatedCase.CaseKey.GetValueOrDefault(), relatedCase2.CaseKey.GetValueOrDefault());

                var r = (await f.Subject.Get(@case.Id)).ToArray();
                f.CaseAuthorization.Received(1).AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(3, r.Length);

                AssertJurisdictionData(relatedCase, r.First(_ => _.Jurisdiction == relatedCase.Jurisdiction));
                AssertJurisdictionData(relatedCase2, r.First(_ => _.Jurisdiction == relatedCase2.Jurisdiction));
                relatedCase3.Classes = @case.LocalClasses;
                AssertJurisdictionData(relatedCase3, r.First(_ => _.Jurisdiction == relatedCase3.Jurisdiction));
                Assert.DoesNotContain(r, _ => !_.CanView);
            }

            [Fact]
            public async Task GetDataReturnsCountryFromCaseTableAndNotFromRelateCaseTable()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser();
                var @case = f.CreateCase();
                var relatedCase = f.CreateRelatedCase(@case.Id, @case.Country.CountryFlags.First());

                var newCountry = new CountryBuilder().Build().In(Db);
                var designatedCase = Db.Set<Case>().First(_ => _.Id == relatedCase.CaseKey);
                designatedCase.CountryId = newCountry.Id;

                f.SetAuthorizationFor(relatedCase.CaseKey.GetValueOrDefault());

                var r = (await f.Subject.Get(@case.Id)).ToArray();
                f.CaseAuthorization.Received(1).AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(1, r.Length);
                Assert.NotEqual(relatedCase.CountryCode, r[0].CountryCode);
                Assert.Equal(newCountry.Id, r[0].CountryCode);
            }
        }

        public class ExternalUser : FactBase
        {
            void AssertJurisdictionDataExternal(DesignatedJurisdictionData data, DesignatedJurisdictionData result)
            {
                Assert.Equal(data.Jurisdiction, result.Jurisdiction);
                Assert.Equal(data.DesignatedStatus, result.DesignatedStatus);
                Assert.Equal(data.CountryCode, result.CountryCode);
                Assert.Equal(data.OfficialNumber, result.OfficialNumber);
                Assert.Equal(data.PriorityDate, result.PriorityDate);
                Assert.Equal(data.Classes.Replace(",", ", "), result.Classes);
                Assert.Equal(data.InternalReference, result.InternalReference);
                Assert.Equal(data.ClientReference, result.ClientReference);
                Assert.Equal(data.CaseKey, result.CaseKey);
            }

            [Fact]
            public async Task GetDataForExternal()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser(true);
                var @case = f.CreateCase();
                var relatedCase = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.First());
                var r = await f.Subject.Get(@case.Id);
                f.CaseAuthorization.DidNotReceiveWithAnyArgs().AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(r);
                Assert.Equal(1, r.Count());
                AssertJurisdictionDataExternal(relatedCase, r.First());
                Assert.False(r.Any(_ => !_.CanView));
            }

            [Fact]
            public async Task GetDataForExternalClearsIrnsForUnAuthorizedCases()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser(true);
                var @case = f.CreateCase();
                var relatedCase = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.First());
                var relatedCase2 = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.Last());
                var relatedCase3 = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.Last(), false);

                var r = await f.Subject.Get(@case.Id);
                f.CaseAuthorization.DidNotReceiveWithAnyArgs().AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(r);
                Assert.Equal(3, r.Count());
                AssertJurisdictionDataExternal(relatedCase, r.First(_ => _.Jurisdiction == relatedCase.Jurisdiction));
                AssertJurisdictionDataExternal(relatedCase2, r.First(_ => _.Jurisdiction == relatedCase2.Jurisdiction));
                relatedCase3.InternalReference = null;
                relatedCase3.CaseKey = null;
                AssertJurisdictionDataExternal(relatedCase3, r.First(_ => _.Jurisdiction == relatedCase3.Jurisdiction));
                Assert.True(r.Any(_ => !_.CanView));
            }

            [Fact]
            public async Task GetDataForExternalReturnsMultipleRelatedCases()
            {
                var f = new DesignatedJurisdictionsFixture(Db).WithUser(true);
                var @case = f.CreateCase();
                var relatedCase = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.First());
                var relatedCase2 = f.DataForExternal(@case.Id, @case.Country.Id, @case.Country.CountryFlags.Last());

                var r = await f.Subject.Get(@case.Id);
                f.CaseAuthorization.DidNotReceiveWithAnyArgs().AccessibleCases(Arg.Any<int[]>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(r);
                Assert.Equal(2, r.Count());
                AssertJurisdictionDataExternal(relatedCase, r.First(_ => _.Jurisdiction == relatedCase.Jurisdiction));
                AssertJurisdictionDataExternal(relatedCase2, r.First(_ => _.Jurisdiction == relatedCase2.Jurisdiction));
                Assert.False(r.Any(_ => !_.CanView));
            }
        }

        class DesignatedJurisdictionsFixture : IFixture<DesignatedJurisdictions>
        {
            public DesignatedJurisdictionsFixture(InMemoryDbContext db)
            {
                Db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                CaseAuthorization = Substitute.For<ICaseAuthorization>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new DesignatedJurisdictions(Db, SecurityContext, CaseAuthorization, PreferredCultureResolver);
            }

            InMemoryDbContext Db { get; }
            ISecurityContext SecurityContext { get; }
            public ICaseAuthorization CaseAuthorization { get; }
            IPreferredCultureResolver PreferredCultureResolver { get; }
            public DesignatedJurisdictions Subject { get; }

            public DesignatedJurisdictionsFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User(Fixture.String(), isExternal));
                return this;
            }

            public DesignatedJurisdictionData CreateRelatedCase(int caseId, CountryFlag countryFlag)
            {
                var (relatedCase, caseRelation) = CreateRelatedCase(caseId, countryFlag.FlagNumber);

                return new DesignatedJurisdictionData
                {
                    Jurisdiction = relatedCase.Country.Name,
                    DesignatedStatus = countryFlag.Name,
                    CountryCode = caseRelation.CountryCode,
                    OfficialNumber = relatedCase.CurrentOfficialNumber,
                    PriorityDate = caseRelation.PriorityDate,
                    Classes = relatedCase.LocalClasses,
                    InternalReference = relatedCase.Irn,
                    CaseStatus = relatedCase.CaseStatus?.Name,
                    CaseKey = relatedCase.Id
                };
            }

            public DesignatedJurisdictionData DataForExternal(int caseId, string countryId, CountryFlag countryFlag, bool allowedAccess = true)
            {
                var (relatedCase, caseRelation) = CreateRelatedCase(caseId, countryFlag.FlagNumber);

                new CountryGroupBuilder
                {
                    Id = countryId,
                    GroupMember = relatedCase.Country
                }.Build().In(Db);

                FilteredUserCase filtered = null;
                if (allowedAccess)
                {
                    filtered = new FilteredUserCase
                    {
                        CaseId = relatedCase.Id,
                        ClientReferenceNo = Fixture.String()
                    }.In(Db);
                }

                return new DesignatedJurisdictionData
                {
                    Jurisdiction = relatedCase.Country.Name,
                    DesignatedStatus = countryFlag.Name,
                    CountryCode = caseRelation.CountryCode,
                    OfficialNumber = relatedCase.CurrentOfficialNumber,
                    PriorityDate = caseRelation.PriorityDate,
                    Classes = relatedCase.LocalClasses,
                    InternalReference = relatedCase.Irn,
                    ClientReference = filtered?.ClientReferenceNo,
                    CaseStatus = relatedCase.CaseStatus?.Name,
                    CaseKey = relatedCase.Id
                };
            }

            public DesignatedJurisdictionData CreateEmptyRelatedCase(int caseId, CountryFlag countryFlag)
            {
                var newCountry = new CountryBuilder().Build().In(Db);
                var caseRelation = new RelatedCase(caseId, KnownRelations.DesignatedCountry1, newCountry.Id)
                {
                    CurrentStatus = countryFlag.FlagNumber,
                    PriorityDate = Fixture.PastDate()
                }.In(Db);

                return new DesignatedJurisdictionData
                {
                    Jurisdiction = newCountry.Name,
                    DesignatedStatus = countryFlag.Name,
                    CountryCode = caseRelation.CountryCode,
                    PriorityDate = caseRelation.PriorityDate
                };
            }

            public void SetAuthorizationFor(params int[] relatedCaseIds)
            {
                CaseAuthorization.AccessibleCases(Arg.Any<int[]>()).Returns(relatedCaseIds);
            }

            (Case relatedCase, RelatedCase caseRelation) CreateRelatedCase(int caseId, int countryFlagNumber)
            {
                var relatedCase = CreateCase();
                var caseRelation = new RelatedCase(caseId, KnownRelations.DesignatedCountry1, relatedCase.Country.Id)
                {
                    RelatedCaseId = relatedCase.Id,
                    CurrentStatus = countryFlagNumber,
                    PriorityDate = Fixture.PastDate()
                }.In(Db);

                new CasePropertyBuilder
                {
                    Case = relatedCase,
                    Status = new Status(Fixture.Short(), Fixture.String()).In(Db)
                }.Build().In(Db);

                return (relatedCase, caseRelation);
            }

            public Case CreateCase()
            {
                var caseId = Fixture.Integer();
                var countryId = Fixture.String();
                var @case = new Case(Fixture.String("IRN"), new CountryBuilder
                {
                    Id = countryId,
                    CountryFlags = new List<CountryFlag>
                    {
                        new CountryFlag(countryId, Fixture.Integer(), Fixture.String()).In(Db),
                        new CountryFlag(countryId, Fixture.Integer(), Fixture.String()).In(Db),
                        new CountryFlag(countryId, Fixture.Integer(), Fixture.String()).In(Db)
                    }
                }.Build().In(Db), new CaseType(), new PropertyType())
                {
                    Id = caseId,
                    LocalClasses = "Class1,Class2,Class3"
                }.In(Db);

                return @case;
            }
        }
    }
}