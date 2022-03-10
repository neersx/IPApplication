using System;
using System.Collections.Generic;
using CPAXML;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.CustomColumnsResolution;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport.CustomColumnsResolution
{
    public class CustomColumnsResolverFacts : FactBase
    {
        [Fact]
        public void CallsStructureMappingResolverWithCreateEventFunction()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(true)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'A':'A', 'Event1': 'Event 1'}");

            string error, output;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out output);

            Assert.True(r);
            f.StructureMappingResolver.Received(1).Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.Events, caseDetails.CreateEvent, out error);
        }

        [Fact]
        public void CallsStructureMappingResolverWithCreateNameFunction()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(true)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'Name1': 'Name 1'}");

            string error, output;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out output);

            Assert.True(r);
            f.StructureMappingResolver.Received(1).Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.NameType, caseDetails.CreateName, out error);
        }

        [Fact]
        public void CallsStructureMappingResolverWithCreateNumberFunction()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(true)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'Number1': 'No 1'}");

            string error;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out _);

            Assert.True(r);
            f.StructureMappingResolver
             .Received(1)
             .Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.NumberType, caseDetails.CreateNumber, out error);
        }

        [Fact]
        public void CallsStructureMappingResolverWithCreateTextFunction()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(true)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'Text1': 'Text 1'}");

            string error;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out _);

            Assert.True(r);
            f.StructureMappingResolver
             .Received(1)
             .Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.TextType, caseDetails.CreateText, out error);
        }

        [Fact]
        public void FetchedOnlyReleventMappings()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(true)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'A':'A', 'B': 'B'}");

            string error;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out _);

            Assert.True(r);

            f.StructureMappingResolver.When(_ => _.Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.Events, Arg.Any<Action<string, object>>(), out error))
             .Do(x =>
             {
                 var mappingsList = x.Args()[1];
                 Assert.Equal(3, ((List<Mapping>) mappingsList).Count);
             });

            f.StructureMappingResolver.Received(1).Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.Events, caseDetails.CreateEvent, out error);
        }

        [Fact]
        public void ReturnsErrorIfDuplicateMappings()
        {
            var f = new CustomColumnsResolverFixture(Db)
                    .WithStructureMappingResolverOutput(false)
                    .WithMappings();

            var caseDetails = new CaseDetails("Patent", "AU");
            var caseToken = f.GetJToken("{'A':'A', 'B': 'B'}");

            string error, output;
            var r = f.Subject.ResolveCustomColumns(caseDetails, caseToken, out output);

            Assert.False(r);
            Assert.NotNull(output);
            f.StructureMappingResolver.Received(1).Resolve(caseToken, Arg.Any<List<Mapping>>(), KnownMapStructures.Events, caseDetails.CreateEvent, out error);
        }

        [Fact]
        public void ReturnsIfNoMappingsDefined()
        {
            var f = new CustomColumnsResolverFixture(Db);
            var r = f.Subject.ResolveCustomColumns(new CaseDetails("Patent", "AU"), f.GetJToken("{}"), out _);

            Assert.True(r);

            f.StructureMappingResolver
             .Received(0)
             .Resolve(Arg.Any<JToken>(), Arg.Any<List<Mapping>>(), Arg.Any<int>(), Arg.Any<Action<string, object>>(), out _);
        }
    }

    public class CustomColumnsResolverFixture : IFixture<ICustomColumnsResolver>
    {
        readonly InMemoryDbContext _db;

        public CustomColumnsResolverFixture(InMemoryDbContext db)
        {
            _db = db;
            StructureMappingResolver = Substitute.For<IStructureMappingResolver>();

            Subject = new CustomColumnsResolver(db, StructureMappingResolver);
        }

        public IStructureMappingResolver StructureMappingResolver { get; }

        public ICustomColumnsResolver Subject { get; }

        public CustomColumnsResolverFixture WithStructureMappingResolverOutput(bool result)
        {
            string output;
            StructureMappingResolver.Resolve(Arg.Any<JToken>(), Arg.Any<List<Mapping>>(), Arg.Any<int>(), Arg.Any<Action<string, object>>(), out output).Returns(result);

            return this;
        }

        public CustomColumnsResolverFixture WithMappings()
        {
            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.Events, InputCode = "A"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.Events, InputCode = "B"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.Events, InputCode = "EVENT1"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NumberType, InputCode = "NUMBER1"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NumberType, InputCode = "NAME1"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NumberType, InputCode = "TEXT1"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.NameType, InputCode = "B"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Epo, StructureId = KnownMapStructures.NameType, InputCode = "B"}.In(_db);

            new Mapping {DataSourceId = (int) KnownExternalSystemIds.Ede, StructureId = KnownMapStructures.SubType, InputDescription = "B"}.In(_db);

            return this;
        }

        public JToken GetJToken(string input)
        {
            return JToken.Parse(input);
        }
    }
}