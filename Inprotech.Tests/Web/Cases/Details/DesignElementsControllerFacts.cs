using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class DesignElementsControllerFacts : FactBase
    {
        [Fact]
        public void ReturnsPagedResult()
        {
            var f = new DesignElementsControllerFixture(Db).WithCase(out var @case).WithDesignElementData(@case);
            var result = f.Subject.GetDesignElements(@case.Id, new Inprotech.Infrastructure.Web.CommonQueryParameters());

            Assert.NotNull(result);
            Assert.Equal(6, ((IEnumerable<DesignElementData>)result.Data).ToArray().Length);
            Assert.Equal("1", ((IEnumerable<DesignElementData>)result.Data).First().FirmElementCaseRef);
        }

        [Fact]
        public void ReturnsPagedResultWithQueryParameterIsNull()
        {
            var f = new DesignElementsControllerFixture(Db).WithCase(out var @case).WithDesignElementData(@case);
            var result = f.Subject.GetDesignElements(@case.Id);

            Assert.NotNull(result);
        }

        class DesignElementsControllerFixture : IFixture<DesignElementsController>
        {
            readonly IDesignElements _designElements;
            readonly InMemoryDbContext _db;
            public DesignElementsControllerFixture(InMemoryDbContext db)
            {
                _designElements = Substitute.For<IDesignElements>();
                _db = db;
                Subject = new DesignElementsController(_designElements);
            }

            public DesignElementsController Subject { get; }

            public DesignElementsControllerFixture WithCase(out Case @case)
            {
                @case = new CaseBuilder().Build().In(_db);
                return this;
            }

            public DesignElementsControllerFixture WithDesignElementData(Case @case)
            {
                var data = Enumerable.Range(1, 6).Select(_ => new DesignElementData()
                {
                    ElementDescription = Fixture.String(_.ToString()),
                    ElementOfficialNo = _.ToString(),
                    ClientElementCaseRef = _.ToString(),
                    Renew = _ == 2 || _ == 4 || _ == 6,
                    FirmElementCaseRef = _.ToString(),
                    RegistrationNo = _.ToString(),
                    Sequence = _

                }).ToList();
                _designElements.GetCaseDesignElements(@case.Id).Returns(data.AsQueryable());
                return this;
            }
        }
    }
}
