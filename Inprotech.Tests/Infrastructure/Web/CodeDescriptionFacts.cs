using Inprotech.Infrastructure.Web;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class CodeDescriptionFacts
    {
        public class EqualsMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseWhenCodeAndOrDescDifferent()
            {
                var codeDesc = new CodeDescription {Code = "C0dyB@nks", Description = "Description"};
                var differentCodeDesc = new CodeDescription {Code = "C0dyB@nksX", Description = "DescriptionX"};
                Assert.False(codeDesc.Equals(differentCodeDesc));
                Assert.NotEqual(codeDesc.GetHashCode(), differentCodeDesc.GetHashCode());

                differentCodeDesc.Code = "C0dyB@nks";
                differentCodeDesc.Description = "Descraption";
                Assert.False(codeDesc.Equals(differentCodeDesc));
                Assert.NotEqual(codeDesc.GetHashCode(), differentCodeDesc.GetHashCode());

                differentCodeDesc.Code = "C0dyB@nksX";
                differentCodeDesc.Description = "Description";
                Assert.False(codeDesc.Equals(differentCodeDesc));
                Assert.NotEqual(codeDesc.GetHashCode(), differentCodeDesc.GetHashCode());
            }

            [Fact]
            public void ReturnsTrueWhenStringsAreTheSame()
            {
                var codeDesc1 = new CodeDescription {Code = "C0dyB@nks", Description = "Description"};
                var codeDesc2 = new CodeDescription {Code = "C0dyB@nks", Description = "Description"};
                Assert.True(codeDesc1.Equals(codeDesc2));
                Assert.Equal(codeDesc1.GetHashCode(), codeDesc2.GetHashCode());
            }
        }
    }
}