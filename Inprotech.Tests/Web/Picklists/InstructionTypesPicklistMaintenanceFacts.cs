using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using Xunit;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Web.Picklists
{
    public class InstructionTypesPicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesTheInstructionType()
            {
                var model = new EntityModel.InstructionType().In(Db);

                var f = new InstructionTypesPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.InstructionType>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _instructor = new NameTypeBuilder().Build();
                _existing = new EntityModel.InstructionType
                {
                    Code = "A",
                    Description = "abc",
                    NameType = _instructor,
                    RestrictedByType = null
                }.In(Db);
            }

            readonly NameType _instructor;
            readonly EntityModel.InstructionType _existing;

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            [InlineData("567")]
            public void PreventUnknownFromBeingSaved(string typeCode)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new InstructionTypesPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                                     new InstructionType
                                                                                                                     {
                                                                                                                         Code = typeCode
                                                                                                                     }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsInstructionType()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new InstructionType
                {
                    Code = "T",
                    Value = "blah",
                    RecordedAgainstId = _instructor.NameTypeCode,
                    RestrictedById = _instructor.NameTypeCode
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.InstructionType>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Code);
                Assert.Equal(model.Value, justAdded.Description);
                Assert.Equal(model.RecordedAgainstId, justAdded.NameType.NameTypeCode);
                Assert.Equal(model.RestrictedById, justAdded.RestrictedByType.NameTypeCode);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = string.Empty,
                    Value = "abc",
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Update);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan3Characters()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = "12345",
                    Value = "abc",
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Update);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 3), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescription()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = string.Empty,
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = "123",
                    Value = "123456789012345678901234567890123456789012345678901234567890",
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresRecordedAgainst()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "abc",
                    RecordedAgainstId = null
                }, Operation.Update);

                Assert.Equal("recordedAgainstId", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueCode()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "abc",
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueDescription()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new InstructionType
                {
                    Key = 89,
                    Code = "B",
                    Value = _existing.Description,
                    RecordedAgainstId = _instructor.NameTypeCode
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesInstructionType()
            {
                var subject = new InstructionTypesPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new InstructionType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "blah",
                    RecordedAgainstId = _instructor.NameTypeCode,
                    RestrictedById = _instructor.NameTypeCode
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Code);
                Assert.Equal(model.Value, _existing.Description);
                Assert.Equal(model.RecordedAgainstId, _existing.NameType.NameTypeCode);
                Assert.Equal(model.RestrictedById, _existing.RestrictedByType.NameTypeCode);
            }
        }

        public class InstructionTypesPicklistMaintenanceFixture : IFixture<InstructionTypesPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public InstructionTypesPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;

                Subject = new InstructionTypesPicklistMaintenance(db);
            }

            public InstructionTypesPicklistMaintenance Subject { get; set; }

            public InstructionTypesPicklistMaintenanceFixture WithInstructionType(
                NameType recordedAgainst = null,
                NameType restrictedBy = null)
            {
                new EntityModel.InstructionType
                {
                    Description = "abc",
                    NameType = recordedAgainst ?? new NameTypeBuilder().Build().In(_db),
                    RestrictedByType = restrictedBy ?? new NameTypeBuilder().Build().In(_db)
                }.In(_db);

                return this;
            }
        }
    }
}