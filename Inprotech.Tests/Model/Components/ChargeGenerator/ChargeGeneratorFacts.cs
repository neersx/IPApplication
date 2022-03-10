using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Components.ChargeGeneration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.ChargeGenerator
{
    public class ChargeGeneratorFacts
    {
        public class QueueChecklistQuestionChargeMethod : FactBase
        {
            [Fact]
            public void ShouldGenerateChecklistCharge()
            {
                var f = new ChargeGeneratorFixture();
                var @case = new CaseBuilder().Build();
                var rate = new BestChargeRates {RateId = Fixture.Integer()};
                var checklistData = new ChecklistQuestionData {CountValue = Fixture.Integer(), AmountValue = Fixture.Decimal()};
                f.SecurityContext.User.Returns(new User(Fixture.String(), false));
                f.Subject.QueueChecklistQuestionCharge(@case, Fixture.Short(), Fixture.Integer(), Fixture.Short(), rate, checklistData);

                Assert.True(@case.PendingRequests.Any(v => v.RateId == rate.RateId && v.EnteredQuantity == checklistData.CountValue && v.EnteredAmount == checklistData.AmountValue));
            }
        }
    }

    public class ChargeGeneratorFixture : IFixture<InprotechKaizen.Model.Components.ChargeGeneration.ChargeGenerator>
    {
        public ChargeGeneratorFixture()
        {
            DbContext = new InMemoryDbContext();
            SecurityContext = Substitute.For<ISecurityContext>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new InprotechKaizen.Model.Components.ChargeGeneration.ChargeGenerator(SiteControlReader, DbContext, SecurityContext);
        }

        public InMemoryDbContext DbContext { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public InprotechKaizen.Model.Components.ChargeGeneration.ChargeGenerator Subject { get; set; }
    }
}
