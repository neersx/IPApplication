using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration
{
    public class ComponentResolverFacts : FactBase
    {
        public ComponentResolverFacts()
        {
            _component = Substitute.For<IComponent>();
            _componentResolver = new ComponentResolver(_component);
        }

        readonly IComponentResolver _componentResolver;
        readonly IComponent _component;

        [Fact]
        public void ShouldReturnNullWhenNoValueIsPassed()
        {
            _component.Components.Returns(new Dictionary<string, int>());
            var r = _componentResolver.Resolve(null);
            Assert.Null(r);
        }

        [Fact]
        public void ShouldReturnNullWhenNoValueIsFound()
        {
            _component.Components.Returns(new Dictionary<string, int>());
            var r = _componentResolver.Resolve("Batch");
            Assert.Null(r);
        }

        [Fact]
        public void ShouldReturnTheCorrectComponent()
        {
            _component.Components.Returns(new Dictionary<string, int> {{"Batch", 1}});
            var r = _componentResolver.Resolve("Batch");
            Assert.Equal(1, r);
        }
    }
}