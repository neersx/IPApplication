using System;
using System.Collections.Generic;
using Autofac.Features.Metadata;
using Inprotech.Web.Configuration.Ede.DataMapping.Mappings;
using InprotechKaizen.Model.Ede.DataMapping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping.Mappings
{
    public class MappingHandlerResolverFacts
    {
        [Theory]
        [InlineData(KnownMapStructures.Events)]
        [InlineData(KnownMapStructures.NumberType)]
        public void ResolvesHandlerForStructure(int structureId)
        {
            var f = new MappingHandlerResolverFixture()
                .WithMappingHandler(structureId);

            Assert.NotNull(f.Subject.Resolve(structureId));
        }

        public class MappingHandlerResolverFixture : IFixture<MappingHandlerResolver>
        {
            readonly List<Meta<Func<IMappingHandler>>> _metaMappingHandlerFuncs = new List<Meta<Func<IMappingHandler>>>();

            public MappingHandlerResolver Subject => new MappingHandlerResolver(_metaMappingHandlerFuncs);

            public MappingHandlerResolverFixture WithMappingHandler(int structureId)
            {
                var mappingHandler = Substitute.For<IMappingHandler>();
                var mappings1 = mappingHandler;
                _metaMappingHandlerFuncs.Add(new Meta<Func<IMappingHandler>>(
                                                                             () => mappings1,
                                                                             new Dictionary<string, object>
                                                                             {
                                                                                 {MappingModule.MapStructureId, structureId}
                                                                             }));

                return this;
            }
        }

        [Fact]
        public void ThrowsUnsupported()
        {
            Assert.Throws<NotSupportedException>(
                                                 () =>
                                                 {
                                                     new MappingHandlerResolverFixture().Subject.Resolve(
                                                                                                         Fixture.Integer());
                                                 });
        }
    }
}