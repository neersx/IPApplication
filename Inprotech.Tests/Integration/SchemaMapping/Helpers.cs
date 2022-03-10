using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.SchemaMappings;
using NSubstitute;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    internal static class Helpers
    {
        public static XsdNode BuildXsdTree(InMemoryDbContext db, string xsdStr)
        {
            var parser = new XsdParser(db, Substitute.For<IDtdReader>(), Substitute.For<IBackgroundProcessLogger<XsdParser>>());

            DefaultSchemaAndFile(db, xsdStr);
            var schema = parser.ParseAndCompile(1).SchemaSet.RootNodeSchema();
            return new XsdTreeBuilder().Build(schema, Fixture.String()).Structure;
        }

        public static Attribute AsAttribute(this XsdNode node)
        {
            return (Attribute) node;
        }

        public static Element AsElement(this XsdNode node)
        {
            return (Element) node;
        }

        public static Sequence AsSequence(this XsdNode node)
        {
            return (Sequence) node;
        }

        public static void DefaultSchemaAndFile(InMemoryDbContext db, string content)
        {
            var schemaPackage = new SchemaPackage
            {
                Id = 1
            }.In(db);

            new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage,
                Name = "f1",
                Content = content
            }.In(db);
        }
    }
}