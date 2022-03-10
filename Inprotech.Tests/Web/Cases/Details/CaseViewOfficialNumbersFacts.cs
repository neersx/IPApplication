using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewOfficialNumbersFacts : FactBase
    {
        class CaseViewOfficialNumbersFixture : IFixture<CaseViewOfficialNumbers>
        {
            readonly string _culture = Fixture.String();

            public CaseViewOfficialNumbersFixture(InMemoryDbContext db)
            {
                CaseKey = Fixture.Integer();
                Db = db;
                UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
                var preferedCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferedCultureResolver.Resolve().Returns(_culture);
                Subject = new CaseViewOfficialNumbers(Db, UserFilteredTypes, preferedCultureResolver);
                DataSetup();
            }

            InMemoryDbContext Db { get; }

            IUserFilteredTypes UserFilteredTypes { get; }
            public int CaseKey { get; private set; }

            public CaseViewOfficialNumbers Subject { get; }

            void DataSetup()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var @event = new EventBuilder().Build().In(Db);
                var ce = new CaseEventBuilder {Event = @event}.BuildForCase(@case).In(Db);

                CaseKey = @case.Id;

                var numberTypeIpOffice = new NumberTypeBuilder {RelatedEvent = ce.Event, RelatedEventNo = ce.EventNo}.ForNumberTypeIssuedByIpOffice().Build().In(Db);
                var numberTypeOther = new NumberTypeBuilder
                {
                    RelatedEvent = ce.Event,
                    RelatedEventNo = ce.EventNo,
                    IssuedByIpOffice = false
                }.Build().In(Db);
                UserFilteredTypes.NumberTypes().Returns(new[] {numberTypeIpOffice, numberTypeOther}.AsQueryable());

                new OfficialNumberBuilder {Case = @case, NumberType = numberTypeIpOffice}.Build().In(Db);
                new OfficialNumberBuilder {Case = @case, NumberType = numberTypeOther}.Build().In(Db);
            }
        }

        [Fact]
        public void ReturnsIpOfficeNumbers()
        {
            var f = new CaseViewOfficialNumbersFixture(Db);
            var r = f.Subject.IpOfficeNumbers(f.CaseKey).ToArray();

            Assert.True(r.Length == 1);
        }

        [Fact]
        public void ReturnsOtherNumbers()
        {
            var f = new CaseViewOfficialNumbersFixture(Db);
            var r = f.Subject.OtherNumbers(f.CaseKey).ToArray();

            Assert.True(r.Length == 1);
        }
    }
}