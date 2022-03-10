using Inprotech.Contracts;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class CountryCodeResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            readonly IBackgroundProcessLogger<CountryCodeResolver> _logger = Substitute.For<IBackgroundProcessLogger<CountryCodeResolver>>();

            [Fact]
            public void ResolvesArbitraryForDuplicatesAndLog()
            {
                new Mapping
                {
                    InputCode = "PCT", // Workaround DbFuncs testability: this would be something else, e.g. STUFFED
                    OutputValue = "PCT",
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                new Mapping
                {
                    InputCode = "PCT", // Workaround DbFuncs testability: this would be something else, e.g. WO
                    OutputValue = "PCT",
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                var subject = new CountryCodeResolver(Db, _logger);

                var r = subject.ResolveMapping();

                Assert.Single(r);

                _logger.Received(1).Warning(Arg.Is<string>(_ => _.Contains("PCT")));
            }

            [Fact]
            public void ResolvesRawInnographyCountryCodeMappings()
            {
                new Mapping
                {
                    InputCode = "WO",
                    OutputValue = "PCT",
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                new Mapping
                {
                    InputCode = "MAD",
                    OutputCodeId = Fixture.Integer(),
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                var subject = new CountryCodeResolver(Db, _logger);

                var r = subject.ResolveMapping();

                Assert.Equal(2, r.Count);
                Assert.Contains("WO", r.Values);
                Assert.Contains("MAD", r.Values);
            }

            [Fact]
            public void WillNotResolvesRawCountryMappingFromAnotherSource()
            {
                new Mapping
                {
                    InputCode = "WO",
                    OutputValue = "PCT",
                    StructureId = KnownMapStructures.Events,
                    DataSourceId = (short) KnownExternalSystemIds.Ede
                }.In(Db);

                new Mapping
                {
                    InputCode = "MAD",
                    OutputCodeId = Fixture.Integer(),
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                var subject = new CountryCodeResolver(Db, _logger);

                var r = subject.ResolveMapping();

                Assert.Single(r);
                Assert.Contains("MAD", r.Values);
            }

            [Fact]
            public void WillNotResolvesRawInnographyOfAnotherStructure()
            {
                new Mapping
                {
                    InputCode = "WO",
                    OutputValue = "PCT",
                    StructureId = KnownMapStructures.Events,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                new Mapping
                {
                    InputCode = "MAD",
                    OutputCodeId = Fixture.Integer(),
                    StructureId = KnownMapStructures.Country,
                    DataSourceId = (short) KnownExternalSystemIds.IPONE
                }.In(Db);

                var subject = new CountryCodeResolver(Db, _logger);

                var r = subject.ResolveMapping();

                Assert.Single(r);
                Assert.Contains("MAD", r.Values);
            }
        }
    }
}