using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class CriteriaFacts
    {
        public class IsProtectedProperty
        {
            [Theory]
            [InlineData(0, true)]
            [InlineData(1, false)]
            [InlineData(null, true)]
            public void GetIsProtected(int? userDefinedRule, bool expectedIsProtected)
            {
                var subject = new Criteria {UserDefinedRule = userDefinedRule};
                Assert.Equal(expectedIsProtected, subject.IsProtected);
            }

            [Theory]
            [InlineData(true, 0)]
            [InlineData(false, 1)]
            public void SetIsProtected(bool isProtected, int expectedUserDefinedRule)
            {
                var subject = new Criteria {IsProtected = isProtected};
                Assert.Equal(expectedUserDefinedRule, subject.UserDefinedRule);
            }
        }
    }
}