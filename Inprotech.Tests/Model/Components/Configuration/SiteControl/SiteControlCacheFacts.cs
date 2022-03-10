using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.SiteControl
{
    public class SiteControlCacheFacts
    {
        public SiteControlCacheFacts()
        {
            _a.Id.Returns("a");
            _b.Id.Returns("b");
        }

        readonly ISiteControlCache _subject = new SiteControlCache();
        readonly IValueFactory _valueFactory = Substitute.For<IValueFactory>();
        readonly ICachedSiteControl _a = Substitute.For<ICachedSiteControl>();
        readonly ICachedSiteControl _b = Substitute.For<ICachedSiteControl>();

        public interface IValueFactory
        {
            IEnumerable<ICachedSiteControl> Provide(params string[] controlId);
        }

        [Fact]
        public void ShouldClearFromCache()
        {
            _valueFactory.Provide("a")
                         .Returns(new[] {_a});

            // add to cache.
            _subject.Resolve(x => _valueFactory.Provide(x.ToArray()), "a")
                    // ReSharper disable once ReturnValueOfPureMethodIsNotUsed
                    .ToArray();

            Assert.False(_subject.IsEmpty);

            _subject.Clear("a");

            Assert.True(_subject.IsEmpty);

            _valueFactory.Provide("a", "b")
                         .Returns(new[] {_a, _b});

            // add to cache.
            var r1 = _subject.Resolve(x => _valueFactory.Provide(x.ToArray()), "a", "b")
                             .ToArray();

            Assert.False(_subject.IsEmpty);
            Assert.Equal(_a, r1.First());
            Assert.Equal(_b, r1.Last());

            _subject.Clear("a");

            Assert.False(_subject.IsEmpty);
        }

        [Fact]
        public void ShouldResolveFromCache()
        {
            _valueFactory.Provide("a")
                         .Returns(new[] {_a});

            _valueFactory.Provide("b")
                         .Returns(new[] {_b});

            var a1 = _subject.Resolve(x => _valueFactory.Provide(x.ToArray()), "a")
                             .ToArray();

            _valueFactory.ReceivedWithAnyArgs(1).Provide(null);
            Assert.Equal(_a, a1.Single());

            _valueFactory.ClearReceivedCalls();

            var a2 = _subject.Resolve(x => _valueFactory.Provide(x.ToArray()), "a")
                             .ToArray();

            _valueFactory.DidNotReceiveWithAnyArgs().Provide();
            Assert.Equal(_a, a2.Single());

            var a3 = _subject.Resolve(x => _valueFactory.Provide(x.ToArray()), "a", "b")
                             .ToArray();

            _valueFactory.ReceivedWithAnyArgs(1).Provide(null);
            Assert.Equal(_a, a3.Single(_ => _.Id == "a"));
            Assert.Equal(_b, a3.Single(_ => _.Id == "b"));
        }
    }
}