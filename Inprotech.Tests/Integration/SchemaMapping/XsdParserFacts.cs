using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.SchemaMappings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XsdParserFacts
    {
        public class XsdParserFixture
        {
            const string Xml = @"<?xml version=""1.0"" encoding=""UTF-8""?>";
            const string SchemaStart = @"<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns=""http://mycompany.com"" targetNamespace=""http://mycompany.com"" version=""1.0"">";
            const string Element = @"<xs:element name=""root"" type=""xs:string""/>";
            const string SchemaEnd = @"</xs:schema>";
            readonly InMemoryDbContext _db;
            string _include = "[include]";

            public XsdParserFixture(InMemoryDbContext db)
            {
                DtdReader = Substitute.For<IDtdReader>();
                Subject = new XsdParser(db, DtdReader, Substitute.For<IBackgroundProcessLogger<XsdParser>>());
                _db = db;
            }

            public string Xsd => Xml + SchemaStart + _include + Element + SchemaEnd;

            internal IXsdParser Subject { get; }

            internal IDtdReader DtdReader { get; set; }

            public XsdParserFixture WithDtdFile()
            {
                _include = string.Empty;

                Helpers.DefaultSchemaAndFile(_db, Xsd);

                DtdReader.Convert(Arg.Any<SchemaFile>(), Arg.Any<List<SchemaFile>>())
                         .ReturnsForAnyArgs(new DtdParseResult {Xsd = Xsd});
                return this;
            }

            public XsdParserFixture WithLocalFileDependency()
            {
                _include = @"<xs:include schemaLocation=""child.xsd""/>";

                Helpers.DefaultSchemaAndFile(_db, Xsd);

                return this;
            }

            public XsdParserFixture WithAbsolutlyUrlDependency()
            {
                _include = @"<xs:include schemaLocation=""http://www.abc.com/v1/child.xsd""/>";

                Helpers.DefaultSchemaAndFile(_db, Xsd);

                return this;
            }

            public XsdParserFixture WithAbsolutlyUrlHavingQueryStringDependency()
            {
                _include = @"<xs:include schemaLocation=""http://www.abc.com/v1?file=child.xsd""/>";

                Helpers.DefaultSchemaAndFile(_db, Xsd);

                return this;
            }

            public XsdParserFixture WithRelativeUrlDependencyAndMissingGlobalType()
            {
                _include = @"<xs:include schemaLocation=""v1?file=child.xsd""/>";
                var element = @"<xs:element name=""xyz"" type=""cde""/>";
                var xsd = Xml + SchemaStart + _include + Element + element + SchemaEnd;

                Helpers.DefaultSchemaAndFile(_db, xsd);

                return this;
            }
        }

        public class ParseMethod : FactBase
        {
            [Fact]
            public void CanResolveMissingDependencyWithAbsoluteUrl()
            {
                var f = new XsdParserFixture(Db).WithAbsolutlyUrlDependency();
                string[] missingDependencies;
                f.Subject.Parse(1, out missingDependencies);
                Assert.Equal("child.xsd", missingDependencies.Single());
            }

            [Fact]
            public void CanResolveMissingDependencyWithAbsoluteUrlHavingQueryString()
            {
                var f = new XsdParserFixture(Db).WithAbsolutlyUrlHavingQueryStringDependency();
                string[] missingDependencies;
                f.Subject.Parse(1, out missingDependencies);
                Assert.Equal("v1?file=child.xsd", missingDependencies.Single());
            }

            [Fact]
            public void CanResolveMissingDependencyWithLocalFiles()
            {
                var f = new XsdParserFixture(Db).WithLocalFileDependency();
                string[] missingDependencies;
                f.Subject.Parse(1, out missingDependencies);
                Assert.Equal("child.xsd", missingDependencies.Single());
            }

            [Fact]
            public void CanResolveMissingDependencyWithRelativeUrl()
            {
                var f = new XsdParserFixture(Db).WithRelativeUrlDependencyAndMissingGlobalType();
                string[] missingDependencies;
                f.Subject.Parse(1, out missingDependencies);
                Assert.Equal("v1?file=child.xsd", missingDependencies.Single());
            }

            [Fact]
            public void ShouldLoadDtd()
            {
                var metadataId = Guid.NewGuid();
                var schemaPackage = new SchemaPackage
                {
                    Id = 2
                }.In(Db);

                var file = new SchemaFile
                {
                    Id = 2,
                    SchemaPackage = schemaPackage,
                    Name = "a.dtd"
                }.In(Db);

                var schemaFiles = new List<SchemaFile> {file};
                var f = new XsdParserFixture(Db).WithDtdFile();

                f.Subject.ParseAndCompile(2);

                f.DtdReader.ReceivedWithAnyArgs(1).Convert(file, schemaFiles);
            }

            [Fact]
            public void ShouldRaiseErrorIfFailedToCompile()
            {
                var f = new XsdParserFixture(Db).WithLocalFileDependency();
                var e = Record.Exception(() => { f.Subject.ParseAndCompile(1); });

                Assert.IsType<MissingSchemaDependencyException>(e);
            }
        }
    }
}