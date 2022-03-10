using Inprotech.Infrastructure.Caching;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Caching
{
    public class LifetimeScopeCacheFacts
    {
        public class Cached
        {
            public int SimpleValueMethodAccessed { get; set; }

            public int ComplexValueMethodAccessed { get; set; }

            public string SimpleProperty { get; set; }

            public string SimpleValue()
            {
                SimpleValueMethodAccessed++;
                SimpleProperty = Fixture.String();
                return SimpleProperty;
            }

            public ComplexProperty ComplexProperty { get; set; }

            public ComplexProperty ComplexValue()
            {
                ComplexValueMethodAccessed++;

                ComplexProperty = new ComplexProperty();

                return ComplexProperty;
            }
        }

        public class ComplexProperty
        {
            public string One { get; set; }
            
            public string Two { get; set; }
        }
        
        [Fact]
        public void ShouldCacheSimpleProperty()
        {
            var o = new Cached();

            var subject = new LifetimeScopeCache();

            var a = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            var b = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            var c = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            Assert.Equal(a, b);

            Assert.Equal(a, c);

            Assert.Equal(1, o.SimpleValueMethodAccessed);
        }
        
        [Fact]
        public void ShouldUpdateSimplePropertyCache()
        {
            var o = new Cached();

            var subject = new LifetimeScopeCache();

            var a = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            var currentValue = o.SimpleProperty;
            var newValue = Fixture.String();

            Assert.True(subject.Update(o, typeof(Cached), newValue, currentValue));
            
            var c = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            Assert.Equal(newValue, c);

            Assert.NotEqual(a, c);

            var newerValue = Fixture.String();

            Assert.False(subject.Update(o, typeof(Cached), newerValue, currentValue));

            var d = subject.GetOrAdd(o, typeof(Cached), _ => o.SimpleValue());

            Assert.Equal(newValue, d);
            
            Assert.NotEqual(newerValue, d);
        }

        [Fact]
        public void ShouldUpdateComplexPropertyCache()
        {
            var o = new Cached();

            var subject = new LifetimeScopeCache();

            var a = subject.GetOrAdd(o, typeof(Cached), _ => o.ComplexValue());

            var currentValue = o.ComplexProperty;
            var newValue = new ComplexProperty();

            Assert.True(subject.Update(o, typeof(Cached), newValue, currentValue));
            
            var c = subject.GetOrAdd(o, typeof(Cached), _ => o.ComplexValue());

            Assert.Equal(newValue, c);

            Assert.NotEqual(a, c);

            var newerValue = new ComplexProperty();

            Assert.False(subject.Update(o, typeof(Cached), newerValue, currentValue));

            var d = subject.GetOrAdd(o, typeof(Cached), _ => o.ComplexValue());

            Assert.Equal(newValue, d);
            
            Assert.NotEqual(newerValue, d);

            var one = Fixture.String();
            var two = Fixture.String();

            newValue.One = one;
            newValue.Two = two;

            Assert.True(subject.Update(o, typeof(Cached), newValue, newValue));

            var e = subject.GetOrAdd(o, typeof(Cached), _ => o.ComplexValue());

            Assert.Equal(one, e.One);
            Assert.Equal(two, e.Two);
        }
    }
}