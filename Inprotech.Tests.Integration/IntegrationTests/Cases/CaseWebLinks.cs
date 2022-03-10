using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Cases
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CaseWebLinks : IntegrationTest
    {
        const string DeadLinkUrl = "http://www.dead.com/";
        const string RegisteredLinkUrl = "http://www.registered.com/";
        const string PendingLinkUrl = "http://www.pending.com/";

        [Test]
        public void GetCaseWebLinks()
        {
            var data = DbSetup.Do(setup =>
            {
                var country = setup.InsertWithNewAlphaNumericId(new Country
                {
                    Name = Fixture.Prefix() + "country",
                    Type = "0"
                });
                var propertyType = setup.InsertWithNewId(new PropertyType
                {
                    Name = Fixture.Prefix() + "propertyType"
                }, x => x.Code);
                var caseType = setup.InsertWithNewId(new CaseType
                {
                    Name = Fixture.Prefix() + "caseType"
                }, x => x.Code, useAlphaNumeric: true);
                var caseWithNullStatus = CreateCase(setup, Fixture.Prefix("c1"), country, caseType, propertyType);
                var caseWithLiveFlag0 = CreateCase(setup, Fixture.Prefix("c2"), country, caseType, propertyType);
                var caseWithRegisteredFlag = CreateCase(setup, Fixture.Prefix("c3"), country, caseType, propertyType);
                var caseWithRenewalFlag = CreateCase(setup, Fixture.Prefix("c4"), country, caseType, propertyType);

                caseWithLiveFlag0.CaseStatus = setup.InsertWithNewId(new Status {Name = Fixture.String(5), ExternalName = Fixture.String(5), LiveFlag = 0, RegisteredFlag = 1});
                caseWithRegisteredFlag.CaseStatus = setup.InsertWithNewId(new Status {Name = Fixture.String(5), ExternalName = Fixture.String(5), LiveFlag = 1, RegisteredFlag = 1});
                caseWithRenewalFlag.CaseStatus = setup.InsertWithNewId(new Status {Name = Fixture.String(5), ExternalName = Fixture.String(5), LiveFlag = 1, RegisteredFlag = 1});

                var renewalStatus = setup.InsertWithNewId(new Status {Name = "R" + Fixture.String(5), ExternalName = "R" + Fixture.String(5), LiveFlag = 0, RegisteredFlag = 1, RenewalFlag = 1});
                var basis = setup.InsertWithNewId(new ApplicationBasis {Name = Fixture.String(5)});
                setup.InsertWithNewId(new CaseProperty(caseWithRenewalFlag, basis, renewalStatus));

                CreateCriteria(setup, country, propertyType, caseType, KnownStatusCodes.Dead);
                CreateCriteria(setup, country, propertyType, caseType, KnownStatusCodes.Registered);
                CreateCriteria(setup, country, propertyType, caseType, KnownStatusCodes.Pending);

                setup.DbContext.SaveChanges();
                return new
                {
                    caseWithNullStatus,
                    caseWithLiveFlag0,
                    caseWithRegisteredFlag,
                    caseWithRenewalFlag
                };
            });

            var result = ApiClient.Get<IEnumerable<CaseWebLinksController.WebLinksData>>($"case/{data.caseWithNullStatus.Id}/weblinks").ToList();
            Assert.AreEqual(1, result.Count());
            Assert.AreEqual(PendingLinkUrl, result.Single().Links.Single().Url);

            result = ApiClient.Get<IEnumerable<CaseWebLinksController.WebLinksData>>($"case/{data.caseWithLiveFlag0.Id}/weblinks").ToList();
            Assert.AreEqual(1, result.Count());
            Assert.AreEqual(DeadLinkUrl, result.Single().Links.Single().Url);

            result = ApiClient.Get<IEnumerable<CaseWebLinksController.WebLinksData>>($"case/{data.caseWithRegisteredFlag.Id}/weblinks").ToList();
            Assert.AreEqual(1, result.Count());
            Assert.AreEqual(RegisteredLinkUrl, result.Single().Links.Single().Url);

            result = ApiClient.Get<IEnumerable<CaseWebLinksController.WebLinksData>>($"case/{data.caseWithRenewalFlag.Id}/weblinks").ToList();
            Assert.AreEqual(1, result.Count());
            Assert.AreEqual(DeadLinkUrl, result.Single().Links.Single().Url);
        }

        Case CreateCase(DbSetup setup, string prefix, Country country, CaseType caseType, PropertyType propertyType)
        {
            return setup.InsertWithNewId(new Case
            {
                Irn = prefix + "irn",
                Country = country,
                Type = caseType,
                PropertyType = propertyType,
                IpoDelay = 10,
                ApplicantDelay = 12
            });
        }

        void CreateCriteria(DbSetup setup, Country country, PropertyType propertyType, CaseType caseType, KnownStatusCodes tc)
        {
            string url = string.Empty;
            switch (tc)
            {
                case KnownStatusCodes.Dead:
                    url = DeadLinkUrl;
                    break;
                case KnownStatusCodes.Registered:
                    url = RegisteredLinkUrl;
                    break;
                default:
                    url = PendingLinkUrl;
                    break;
            }

            setup.InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix(Fixture.String(3)),
                PurposeCode = CriteriaPurposeCodes.CaseLinks,
                CountryId = country.Id,
                PropertyTypeId = propertyType.Code,
                CaseTypeId = caseType.Code,
                TableCodeId = (int) tc,
                Url = url,
                RuleInUse = 1
            });
        }
    }
}