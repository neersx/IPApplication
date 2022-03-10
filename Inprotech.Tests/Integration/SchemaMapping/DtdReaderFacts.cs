using System.Collections.Generic;
using System.Text.RegularExpressions;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.SchemaMappings;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class DtdReaderFacts : FactBase
    {
        const string Namespace = "Inprotech.Tests.Integration.SchemaMapping.DtdResources.";

        const string DeRequestV14Input = Namespace + "input_de-request-v1-4.dtd";
        const string Dedda9507V005Input = Namespace + "input_dedda9507_v005.dtd";
        const string EpRequestV112Input = Namespace + "input_ep-request-v1-12.dtd";

        const string Dedda9507V005Output = Namespace + "output_dedda9507_v005.xsd";
        const string DeRequestV14Output = Namespace + "output_de-request-v1-4.xsd";
        const string EpRequestV112Output = Namespace + "output_ep-request-v1-12.xsd";

        [Theory]
        [InlineData(Dedda9507V005Input, Dedda9507V005Output)]
        [InlineData(DeRequestV14Input, DeRequestV14Output)]
        [InlineData(EpRequestV112Input, EpRequestV112Output)]
        public void MatchFiles(string inputFile, string outputFile)
        {
            var schemaFile = new SchemaFile
            {
                Id = 1,
                Name = "f1",
                Content = Tools.ReadFromEmbededResource(inputFile)
            }.In(Db);

            var subject = new DtdReader();

            var result = subject.Convert(schemaFile, new List<SchemaFile>(new[] {schemaFile}));

            var output = Tools.ReadFromEmbededResource(outputFile);

            Assert.Equal(RemoveSpaces(output), RemoveSpaces(result.Xsd));
        }

        static string RemoveSpaces(string output)
        {
            return Regex.Replace(output, @"\s+", string.Empty);
        }
    }
}