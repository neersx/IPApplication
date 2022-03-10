using Inprotech.Infrastructure.Extensions;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Extensions
{
    public class LambdaEqualityComparerFacts
    {
        const string Equal = "Equal";
        const string NotEqual = "NotEqual";

        [Fact]
        public void HashCodeShouldReturnHashCode()
        {
            var f = new LambdaEqualityComparerFixture();

            Assert.Equal(Equal.GetHashCode(), f.Subject.GetHashCode(new TestCompare {Value = Equal}));
        }

        [Fact]
        public void MatchShouldReturnTrue()
        {
            var f = new LambdaEqualityComparerFixture();

            Assert.True(f.Subject.Equals(new TestCompare {Value = Equal}, new TestCompare {Value = Equal}));
        }

        [Fact]
        public void MismatchShouldReturnFalse()
        {
            var f = new LambdaEqualityComparerFixture();

            Assert.False(f.Subject.Equals(new TestCompare {Value = Equal}, new TestCompare {Value = NotEqual}));
        }
    }

    internal class TestCompare
    {
        public string Value { get; set; }
    }

    internal class LambdaEqualityComparerFixture : IFixture<LambdaEqualityComparer<TestCompare>>
    {
        public LambdaEqualityComparer<TestCompare> Subject => new LambdaEqualityComparer<TestCompare>(EqualsFunc, HashFunc);

        int HashFunc(TestCompare arg)
        {
            return arg.Value.GetHashCode();
        }

        bool EqualsFunc(TestCompare arg1, TestCompare arg2)
        {
            return arg1.Value == arg2.Value;
        }
    }
}