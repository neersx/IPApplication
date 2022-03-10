using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Web.Picklists
{
    public class InstructionTypesPicklistControllerFacts : FactBase
    {
        public class InstructionTypesMethod : FactBase
        {
            public InstructionTypesMethod()
            {
                _instructor = _(KnownNameTypes.Instructor, "instructor");
                _owner = _(KnownNameTypes.Owner, "owner");
            }

            readonly NameType _instructor;
            readonly NameType _owner;

            NameType _(string type, string description)
            {
                return new NameTypeBuilder
                       {
                           NameTypeCode = type,
                           Name = description
                       }
                       .Build()
                       .In(Db);
            }

            [Theory]
            [InlineData("c")]
            [InlineData("abc")]
            public void ReturnsInstructionsTypesWithExactMatchFlag(string exactSearch)
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "abcd", _instructor)
                        .WithInstructionType("cd", "bbbb", _instructor)
                        .WithInstructionType("c", "abc", _owner);

                var r = f.Subject.InstructionTypes(null, exactSearch);
                var i = r.Data.OfType<InstructionType>().ToArray();

                Assert.Equal("c", i.First().Code);
            }

            [Fact]
            public void ReturnPagedResults()
            {
                for (var a = 0; a < 10; a++)
                {
                    new EntityModel.InstructionType
                    {
                        Code = a.ToString(),
                        NameType = _instructor
                    }.In(Db);
                }

                var r = new InstructionTypesControllerFixture(Db).Subject.InstructionTypes(new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 5, Take = 5});
                var i = r.Data.OfType<InstructionType>().ToArray();

                Assert.Equal(5, i.Length);
                Assert.Equal("5", i.First().Code);
                Assert.Equal("9", i.Last().Code);
            }

            [Fact]
            public void ReturnsAllInstructionsTypes()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "cccc", _owner);

                var r = ((IEnumerable<dynamic>) f.Subject.InstructionTypes().Data).ToArray();

                Assert.Equal(3, r.Length);
            }

            [Fact]
            public void ReturnsInstructionsTypesContains()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "jaaaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "cccc", _owner);

                var r = f.Subject.InstructionTypes(null, "aa");
                var i = r.Data.OfType<InstructionType>().ToArray();

                Assert.Single(i);
                Assert.Equal("a", i.Single().Code);
            }

            [Fact]
            public void ReturnsInstructionsTypesWithSearchOnCode()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aacaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("cd", "aaaa", _owner);

                var r = f.Subject.InstructionTypes(null, "C");
                var i = r.Data.OfType<InstructionType>().ToArray();

                Assert.Equal(2, i.Length);
                Assert.Equal("cd", i[0].Code);
                Assert.Equal("a", i[1].Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new InstructionTypesControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("InstructionTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal(ApplicationTask.MaintainBaseInstructions, picklistAttribute.Task);
                Assert.Equal("InstructionTypes", picklistAttribute.PluralName);
            }

            [Fact]
            public void SortsByCodeDescending()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aacaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "aaaa", _owner);

                var r = f.Subject.InstructionTypes(new CommonQueryParameters {SortBy = "code", SortDir = "desc"});
                var i = r.Data.OfType<InstructionType>().ToArray();

                Assert.Equal(3, i.Length);
                Assert.Equal("c", i.First().Code);
                Assert.Equal("a", i.Last().Code);
            }
        }

        public class InstructionTypeMethod : FactBase
        {
            public InstructionTypeMethod()
            {
                _instructor = _(KnownNameTypes.Instructor, "instructor");
                _owner = _(KnownNameTypes.Owner, "owner");
                _debtor = _(KnownNameTypes.Debtor, "debtor");
            }

            readonly NameType _instructor;
            readonly NameType _owner;
            readonly NameType _debtor;

            NameType _(string type, string description)
            {
                return new NameTypeBuilder
                       {
                           NameTypeCode = type,
                           Name = description
                       }
                       .Build()
                       .In(Db);
            }

            [Fact]
            public void ReturnsRequestedInstructionType()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "cccc", _owner);

                var r = f.Subject.InstructionType(1);

                Assert.Equal("aaaa", r.Value);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new InstructionTypesControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("InstructionType").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal(ApplicationTask.MaintainBaseInstructions, picklistAttribute.Task);
                Assert.Equal("InstructionType", picklistAttribute.Name);
            }

            [Fact]
            public void SortsByNameTypeAscendingOrder()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaa", _owner)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "cccc", _debtor);

                var r = f.Subject.NameTypes();

                Assert.Equal("debtor", r.First().Value);
                Assert.Equal("owner", r.Last().Value);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new InstructionTypesControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new InstructionType();

                Assert.Equal(r, s.Update(1, model));
                f.InstructionTypesPicklistMaintenance.Received(1).Save(model, Operation.Update);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new InstructionTypesControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new InstructionType();

                Assert.Equal(r, s.AddOrDuplicate(model));
                f.InstructionTypesPicklistMaintenance.Received(1).Save(model, Operation.Add);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new InstructionTypesControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionTypesPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.InstructionTypesPicklistMaintenance.Received(1).Delete(1);
            }
        }

        public class InstructionTypesControllerFixture : IFixture<InstructionTypesPicklistController>
        {
            readonly InMemoryDbContext _db;

            public InstructionTypesControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                InstructionTypesPicklistMaintenance = Substitute.For<IInstructionTypesPicklistMaintenance>();

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new InstructionTypesPicklistController(_db, PreferredCultureResolver, InstructionTypesPicklistMaintenance);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public IInstructionTypesPicklistMaintenance InstructionTypesPicklistMaintenance { get; set; }

            public InstructionTypesPicklistController Subject { get; }

            public InstructionTypesControllerFixture WithInstructionType(string code, string description,
                                                                         NameType recordedAgainst = null, NameType restrictedTo = null)
            {
                new EntityModel.InstructionType
                {
                    Description = description,
                    Code = code,
                    NameType = recordedAgainst,
                    RestrictedByType = restrictedTo
                }.In(_db);

                return this;
            }
        }
    }

    public class InstructionTypeFacts
    {
        readonly Type _subject = typeof(InstructionType);

        [Fact]
        public void DisplaysFollowingFields()
        {
            Assert.Equal(new[] {"Code", "Value", "RecordedAgainst", "RestrictedBy"},
                         _subject.DisplayableFields());
        }

        [Fact]
        public void PicklistDescriptionIsDefined()
        {
            Assert.NotNull(_subject.GetProperty("Value").GetCustomAttribute<PicklistDescriptionAttribute>());
        }

        [Fact]
        public void PicklistKeyIsDefined()
        {
            Assert.NotNull(_subject.GetProperty("Key").GetCustomAttribute<PicklistKeyAttribute>());
        }
    }
}