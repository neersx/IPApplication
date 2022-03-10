using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class RequestLogErrorReaderFacts
    {
        public class ReadMethod : FactBase
        {
            [Fact]
            public void ReturnsAll()
            {
                var yesterday = Fixture.Today().AddDays(-1);
                var today = Fixture.Today();

                var @case = new CaseBuilder().Build().In(Db);

                new PolicingError
                {
                    StartDateTime = yesterday,
                    CaseId = @case.Id
                }.In(Db);

                new PolicingError
                {
                    StartDateTime = today,
                    CaseId = @case.Id
                }.In(Db);

                Assert.Equal(2, new RequestLogErrorReaderFixture(Db).Subject.Read(new[] {yesterday, today}, 5).Count);
            }
        }

        public class ForMethod : FactBase
        {
            [Fact]
            public void ReturnsAllForId()
            {
                var id = Fixture.Integer();

                var yesterday = Fixture.Today().AddDays(-1);
                var today = Fixture.Today();

                var @case = new CaseBuilder().Build().In(Db);

                new PolicingLog
                {
                    PolicingLogId = id,
                    StartDateTime = today
                }.In(Db);

                new PolicingError
                {
                    StartDateTime = today,
                    CaseId = @case.Id
                }.In(Db);

                new PolicingError
                {
                    StartDateTime = yesterday,
                    CaseId = @case.Id
                }.In(Db);

                Assert.Single(new RequestLogErrorReaderFixture(Db).Subject.For(id).ToArray());
            }
        }

        public class RequestLogErrorReaderFixture : IFixture<RequestLogErrorReader>
        {
            public RequestLogErrorReaderFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PreferredCultureResolver.Resolve().Returns("en");

                Subject = new RequestLogErrorReader(db, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public RequestLogErrorReader Subject { get; set; }
        }
    }
}