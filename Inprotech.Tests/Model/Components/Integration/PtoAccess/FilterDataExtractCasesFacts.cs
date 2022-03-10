using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Integration.PtoAccess;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;

namespace Inprotech.Tests.Model.Components.Integration.PtoAccess
{
    public class FilterDataExtractCasesFacts
    {
        public class ForMethod : FactBase
        {
            [Fact]
            public void ReturnsEligibleCasesRequested()
            {
                var a = new EligibleCaseItem
                {
                    CaseKey = 1
                }.In(Db);

                var b = new EligibleCaseItem
                {
                    CaseKey = 2
                }.In(Db);

                var c = new EligibleCaseItem
                {
                    CaseKey = 3
                }.In(Db);

                var subject = new FilterDataExtractCases(Db);

                var r = subject.For(Fixture.String(), 1, 3);

                Assert.Equal(a, r.First());

                Assert.Equal(c, r.Last());

                Assert.False(r.Contains(b));
            }
        }
    }
}