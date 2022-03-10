using System.Xml.Linq;
using System.Xml.Schema;
using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.Xsd;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlValidatorFacts : FactBase
    {
        public XmlValidatorFacts()
        {
            var parser = new XsdParser(Db,Substitute.For<IDtdReader>(), Substitute.For<IBackgroundProcessLogger<XsdParser>>());

            Helpers.DefaultSchemaAndFile(Db, xsdStr);

            _schemaSet = parser.ParseAndCompile(1).SchemaSet;
            _validator = new XmlValidator();
        }

        readonly XmlSchemaSet _schemaSet;
        readonly IXmlValidator _validator;

        readonly string xsdStr = @"<?xml version=""1.0"" encoding=""UTF-8"" ?>
<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"">
	<xs:element name=""root"" type=""xs:string"" />
</xs:schema>";

        [
            Fact]
        public
            void ShouldNotPassValidation
            ()
        {
            string errors;
            var valid = _validator.Validate(_schemaSet, new XDocument(new XElement("invalid", "1")), out errors);
            Assert.False(valid);
        }

        [Fact]
        public void ShouldPassValidation()
        {
            string errors;
            var valid = _validator.Validate(_schemaSet, new XDocument(new XElement("root", "1")), out errors);
            Assert.True(valid);
        }
    }
}