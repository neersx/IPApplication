using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.SchemaMappings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlGenServiceFacts : FactBase
    {
        public XmlGenServiceFacts()
        {
            var xsdTreeBuilder = Substitute.For<IXsdTreeBuilder>();
            xsdTreeBuilder.Build(null, string.Empty).ReturnsForAnyArgs(new XsdTree());

            IMappingEntryLookup MappingEntryLookup(string _)
            {
                return new MappingEntryLookup(_);
            }

            IGlobalContext GlobalContext(IDictionary<string, object> _)
            {
                return new GlobalContext(_);
            }

            var xmlGenTreeTransformer = Substitute.For<IXmlGenTreeTransformer>();
            xmlGenTreeTransformer.Transform(null, null, null).ReturnsForAnyArgs(new XmlGenNode());

            var xDocumentTransformer = Substitute.For<IXDocumentTransformer>();
            xDocumentTransformer.Transform(null).ReturnsForAnyArgs(new XDocument());

            _xmlValidator = Substitute.For<IXmlValidator>();
            _xmlValidator.Validate(null, null, out _).ReturnsForAnyArgs(true);

            _xsdParser = Substitute.For<IXsdParser>();
            _xsdParser.ParseAndCompile(Arg.Any<int>()).ReturnsForAnyArgs(_ => new XsdParseResult());

            _xmlNameSpaceCleaner = Substitute.For<IXmlNameSpaceCleaner>();
            _xmlNameSpaceCleaner.Clean(Arg.Any<XDocument>()).Returns(_ => _.ArgAt<XDocument>(0));

            _service = new XmlGenService(Db, xsdTreeBuilder, MappingEntryLookup, xmlGenTreeTransformer, xDocumentTransformer, _xmlValidator, GlobalContext, _xsdParser, _xmlNameSpaceCleaner);

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                SchemaPackage = new SchemaPackage
                {
                    Id = 1
                }
            }.In(Db);
        }

        readonly IXmlGenService _service;
        readonly IXmlValidator _xmlValidator;
        readonly IXsdParser _xsdParser;
        readonly IXmlNameSpaceCleaner _xmlNameSpaceCleaner;

        [Fact]
        public async Task ShouldCleanupNameSpace()
        {
            await _service.Generate(1);

            _xmlNameSpaceCleaner.Received(1).Clean(Arg.Any<XDocument>());
        }

        [Fact]
        public async Task ShouldGenerateXml()
        {
            Assert.NotNull(await _service.Generate(1));
        }

        [Fact]
        public async Task ShouldRaiseErrorIfFailedToParseSchema()
        {
            _xsdParser.ParseAndCompile(1).ReturnsForAnyArgs(_ => throw new Exception());

            await Assert.ThrowsAsync<XmlGenException>(async () => await _service.Generate(1));

            _xsdParser.ReceivedWithAnyArgs(1).ParseAndCompile(1);
        }

        [Fact]
        public async Task ShouldRaiseErrorIfFailedToValidateOutputXml()
        {
            _xmlValidator.Validate(null, null, out _).ReturnsForAnyArgs(false);

            await Assert.ThrowsAsync<XmlGenValidationException>(async () => await _service.Generate(1));

            _xmlValidator.ReceivedWithAnyArgs(1).Validate(null, null, out _);
            _xmlNameSpaceCleaner.Received(0).Clean(Arg.Any<XDocument>());
        }

        [Fact]
        public async Task ShouldRaiseErrorIfMappingDoesNotExist()
        {
            await Assert.ThrowsAsync<XmlGenException>(async () => await _service.Generate(2));
        }
    }
}