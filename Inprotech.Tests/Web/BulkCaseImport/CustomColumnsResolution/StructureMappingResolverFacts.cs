using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Web.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.CustomColumnsResolution;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;
using NameDetails = Inprotech.Web.BulkCaseImport.NameDetails;

namespace Inprotech.Tests.Web.BulkCaseImport.CustomColumnsResolution
{
    public class StructureMappingResolverFacts
    {
        [Fact]
        public void AddDataForColumnsWithMappings()
        {
            var f = new StructureMappingResolverFixture();
            var r = f.Subject.Resolve(f.GetJToken("{'A' : 'new'}"), f.GetMappings(), KnownMapStructures.Events, f.DummyClass.DummyCall, out var output);

            Assert.True(r);
            Assert.Equal(output, string.Empty);
            f.DummyClass.Received(1).DummyCall("A", "new");
        }

        [Fact]
        public void AddsSequenceNumberWhileAddingName()
        {
            var f = new StructureMappingResolverFixture();
            var r = f.Subject.Resolve(f.GetJToken("{'D' : 'new', 'D1' : 'new1'}"), f.GetMappings(), KnownMapStructures.NameType, f.DummyClass.DummyCall, out var output);

            f.DummyClass.Received(1).DummyCall("D", Arg.Is<object>(o => o is NameDetails && ((NameDetails) o).NameCode == "new" && ((NameDetails) o).NameSequence == 1));
            f.DummyClass.Received(1).DummyCall("D1", Arg.Is<object>(o => o is NameDetails && ((NameDetails) o).NameCode == "new1" && ((NameDetails) o).NameSequence == 2));

            Assert.True(r);
            Assert.Equal(output, string.Empty);
        }

        [Fact]
        public void CreatesNameWithSequenceInCaseDetails()
        {
            var caseDetails = new CaseDetails("P", "AU");

            var f = new StructureMappingResolverFixture();

            f.Subject.Resolve(f.GetJToken("{'D' : 'new', 'D1' : 'new1'}"), f.GetMappings(), KnownMapStructures.NameType, caseDetails.CreateName, out _);

            Assert.Equal(2, caseDetails.NameDetails.Count);
            Assert.Equal("D", caseDetails.NameDetails.First().NameTypeCode);
            Assert.Equal(1, caseDetails.NameDetails.First().NameSequenceNumber);

            Assert.Equal("D1", caseDetails.NameDetails.Last().NameTypeCode);
            Assert.Equal(2, caseDetails.NameDetails.Last().NameSequenceNumber);
        }

        [Fact]
        public void ReturnsErrorIfDuplicateMappingFound()
        {
            var f = new StructureMappingResolverFixture();
            var r = f.Subject.Resolve(f.GetJToken("{'B' : 'new'}"), f.GetMappings(), KnownMapStructures.Events, f.DummyClass.DummyCall, out var output);

            Assert.False(r);
            Assert.Equal("B", output);
            f.DummyClass.Received(0).DummyCall(Arg.Any<string>(), Arg.Any<string>());
        }

        [Fact]
        public void ReturnsIfMappingDoesNotContainColumns()
        {
            var f = new StructureMappingResolverFixture();
            var r = f.Subject.Resolve(f.GetJToken("{'Z' : 'new'}"), f.GetMappings(), KnownMapStructures.Events, f.DummyClass.DummyCall, out var output);

            Assert.True(r);
            Assert.Equal(output, string.Empty);
            f.DummyClass.Received(0).DummyCall(Arg.Any<string>(), Arg.Any<string>());
        }

        [Fact]
        public void ReturnsIfNoMappingsForStructure()
        {
            var f = new StructureMappingResolverFixture();
            var r = f.Subject.Resolve(f.GetJToken("{}"), new List<Mapping>(), KnownMapStructures.Events, f.DummyClass.DummyCall, out var output);

            Assert.True(r);
            Assert.Equal(output, string.Empty);
            f.DummyClass.Received(0).DummyCall(Arg.Any<string>(), Arg.Any<string>());
        }
    }

    public class StructureMappingResolverFixture : IFixture<IStructureMappingResolver>
    {
        public StructureMappingResolverFixture()
        {
            Subject = new StructureMappingResolver();

            DummyClass = Substitute.For<IDummy>();
        }

        public IDummy DummyClass { get; }
        public IStructureMappingResolver Subject { get; }

        public JToken GetJToken(string input)
        {
            return JToken.Parse(input);
        }

        public List<Mapping> GetMappings()
        {
            return new List<Mapping>
            {
                new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.Events, InputCode = "A"},
                new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.Events, InputCode = "B"},
                new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NameType, InputCode = "B"},
                new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NameType, InputCode = "D", OutputValue = "D"},
                new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NameType, InputCode = "D1", OutputValue = "D"}
            };
        }
    }

    public interface IDummy
    {
        void DummyCall(string str1, object str2);
    }

    public class Dummy : IDummy
    {
        public void DummyCall(string str1, object str2)
        {
        }
    }
}