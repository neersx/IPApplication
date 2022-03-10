using System;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.CaseSupportData;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class DateOfLawFacts
    {
        [Fact]
        public void ShouldForwardCorrectSqlParameters()
        {
            var caseId = Fixture.Integer();
            var actionId = Fixture.String();

            var fixture = new DateOfLawFixture();
            fixture.Subject.GetDefaultDateOfLaw(caseId, actionId);

            fixture.DbContext.Received(1).SqlQuery<DateTime?>(
                                                              "EXEC ipw_GetDefaultDateOfLaw @p0, @p1",
                                                              caseId, actionId);
        }

        [Fact]
        public void ShouldGetDateOfLaw()
        {
            DateTime? expectedDate = Fixture.PastDate();

            var fixture = new DateOfLawFixture();
            fixture.WithSqlResults(expectedDate);

            var caseId = Fixture.Integer();
            var actionId = Fixture.String();

            var r = fixture.Subject.GetDefaultDateOfLaw(caseId, actionId);

            Assert.Equal(expectedDate, r);
        }
    }

    public class DateOfLawFixture : FixtureBase, IFixture<IDateOfLaw>
    {
        public IDateOfLaw Subject => new DateOfLaw(DbContext);
    }
}