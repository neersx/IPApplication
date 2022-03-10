using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Model.Persistence
{
    public class DeltaFacts
    {
        public class TestCloneable : ICloneable
        {
            public string TestProperty { get; set; }

            public object Clone()
            {
                return MemberwiseClone();
            }
        }

        public class NotCloneable
        {
            public string TestProperty { get; set; }
        }

        [Fact]
        public void ShouldAllowCloneableObjects()
        {
            var a = new TestCloneable
            {
                TestProperty = "a"
            };

            var a1 = new Delta<TestCloneable>
            {
                Added = new List<TestCloneable>(new[] {a})
            };

            var b1 = (Delta<TestCloneable>) a1.Clone();
            Assert.False(ReferenceEquals(a, b1.Added.Single()));
            Assert.Equal(a.TestProperty, b1.Added.Single().TestProperty);

            a1.Added.Single().TestProperty = "b";

            Assert.NotEqual(a1.Added.Single().TestProperty, b1.Added.Single().TestProperty);

            a1.Added.Clear();

            Assert.NotEqual(a1.Added.Count(), b1.Added.Count());
        }

        [Fact]
        public void ShouldAllowValueTypes()
        {
            var a1 = new Delta<int>
            {
                Added = new[]
                {
                    1, 2, 3
                }
            };

            var cloned = (Delta<int>) a1.Clone();

            Assert.Equal(a1.Added, cloned.Added);
        }

        [Fact]
        public void ShouldNotAllowOthers()
        {
            var a1 = new Delta<NotCloneable>
            {
                Added = new[]
                {
                    new NotCloneable
                    {
                        TestProperty = "a"
                    }
                }
            };

            Assert.Throws<InvalidOperationException>(() => (Delta<NotCloneable>) a1.Clone());
        }
    }
}