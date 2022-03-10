using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NameTypeGroupsPicklistMaintenanceFacts : FactBase
    {
        public class SaveMethod : FactBase
        {
            [Fact]
            public void AddNameTypeGroup()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var subject = fixture.Subject;

                var model = new NameTypeGroup
                {
                    Key = 1,
                    Value = "NTG 1"
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<NameGroup>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Value, justAdded.Value);
            }

            [Fact]
            public void RequiresNameTypeGroupName()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var nameType2 = new NameType
                {
                    Name = "NT2",
                    NameTypeCode = "N2"
                };

                var nameType3 = new NameType
                {
                    Name = "NT3",
                    NameTypeCode = "N3"
                };

                var collNameTypes = new List<NameType> {nameType1, nameType2, nameType3};

                fixture.BuildNameGroup("ExistingNameTypeGroup", 1, collNameTypes);

                var r = fixture.Subject.Save(new NameTypeGroup
                {
                    Key = 0,
                    Value = string.Empty,
                    NameType = null,
                    Members = null
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresNameTypeGroupToBeNotGreaterThan50Characters()
            {
                var subject = new NameTypeGroupsPicklistMaintenancFixture(Db)
                    .Subject;

                var r = subject.Save(new NameTypeGroup
                {
                    Key = 1,
                    Value = "123456789012345678901234567890123456789012345678901234567890123456789012345678901234"
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueNameTypeGroup()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var nameType2 = new NameType
                {
                    Name = "NT2",
                    NameTypeCode = "N2"
                };

                var nameType3 = new NameType
                {
                    Name = "NT3",
                    NameTypeCode = "N3"
                };

                var collNameTypes = new List<NameType> {nameType1, nameType2, nameType3};

                fixture.BuildNameGroup("ExistingNameTypeGroup", 1, collNameTypes);

                var subject = fixture.Subject;

                var r = subject.Save(new NameTypeGroup
                {
                    Value = "ExistingNameTypeGroup",
                    Key = 0
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void RemoveExistingNameTypeMappingWhenNoNameTypeProvided()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var model = new NameTypeGroup
                {
                    Key = 1,
                    Value = "ExistingNameTypeGroup3",
                    NameType = null
                };
                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var nameType2 = new NameType
                {
                    Name = "NT2",
                    NameTypeCode = "N2"
                };

                var nameType3 = new NameType
                {
                    Name = "NT3",
                    NameTypeCode = "N3"
                };

                var nameType4 = new NameType
                {
                    Name = "NT4",
                    NameTypeCode = "N4"
                };

                var collNameTypes1 = new List<NameType> {nameType1, nameType2};
                var collNameTypes2 = new List<NameType> {nameType3, nameType4};

                fixture.BuildNameGroup("ExistingNameTypeGroup1", 1, collNameTypes1);
                fixture.BuildNameGroup("ExistingNameTypeGroup2", 2, collNameTypes2);

                var existingNameTypeGroups = Db.Set<NameGroupMember>().Where(ngm => ngm.NameGroupId == model.Key).ToArray();
                Assert.Equal(2, existingNameTypeGroups.Length);

                var r = fixture.Subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);

                var updatedNameTypeGroups = Db.Set<NameGroupMember>().Where(ngm => ngm.NameGroupId == model.Key).ToArray();
                Assert.Empty(updatedNameTypeGroups);
            }

            [Fact]
            public void UniqueNameTypeGroupWhenUpdate()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var nameType2 = new NameType
                {
                    Name = "NT2",
                    NameTypeCode = "N2"
                };

                var nameType3 = new NameType
                {
                    Name = "NT3",
                    NameTypeCode = "N3"
                };

                var nameType4 = new NameType
                {
                    Name = "NT4",
                    NameTypeCode = "N4"
                };

                var collNameTypes1 = new List<NameType> {nameType1, nameType2};
                var collNameTypes2 = new List<NameType> {nameType3, nameType4};

                fixture.BuildNameGroup("ExistingNameTypeGroup1", 1, collNameTypes1);
                fixture.BuildNameGroup("ExistingNameTypeGroup2", 2, collNameTypes2);

                var model = new NameTypeGroup
                {
                    Key = 1,
                    Value = "ExistingNameTypeGroup2"
                };

                var r = fixture.Subject.Save(model, Operation.Update);
                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdateNameTypeGroupAndMember()
            {
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);

                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var nameType2 = new NameType
                {
                    Name = "NT2",
                    NameTypeCode = "N2"
                };

                var nameType3 = new NameType
                {
                    Name = "NT3",
                    NameTypeCode = "N3"
                };

                var nameType4 = new NameType
                {
                    Name = "NT4",
                    NameTypeCode = "N4"
                };

                var collNameTypes1 = new List<NameType> {nameType1, nameType2};
                var collNameTypes2 = new List<NameType> {nameType3, nameType4};

                fixture.BuildNameGroup("ExistingNameTypeGroup1", 1, collNameTypes1);
                fixture.BuildNameGroup("ExistingNameTypeGroup2", 2, collNameTypes2);

                var model = new NameTypeGroup
                {
                    Key = 1,
                    Value = "ExistingNameTypeGroup3",
                    NameType = new List<NameTypeModel> {new NameTypeModel {Code = "N3", Key = 1, Value = "NT3"}}
                };

                var r = fixture.Subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                var nameTypeGroupArray = Db.Set<NameGroupMember>().Where(ngm => ngm.NameGroupId == 1).ToArray();
                Assert.Single(nameTypeGroupArray);
                Assert.Equal("N3", nameTypeGroupArray[0].NameTypeCode);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteNameTypeGroup()
            {
                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var collNameTypes1 = new List<NameType> {nameType1};
                var collNameTypes2 = new List<NameType>();

                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);
                fixture.BuildNameGroup("ExistingNameTypeGroup1", 1, collNameTypes1);
                fixture.BuildNameGroup("ExistingNameTypeGroup2", 2, collNameTypes2);

                var r = fixture.Subject.Delete(2);

                var nameTypeGroup = Db.Set<NameGroup>().Where(ng => ng.Id == 2).ToArray();

                Assert.Equal("success", r.Result);
                Assert.Empty(nameTypeGroup);
            }

            [Fact]
            public void InUseCheckWhenDelete()
            {
                var nameType1 = new NameType
                {
                    Name = "NT1",
                    NameTypeCode = "N1"
                };

                var collNameTypes1 = new List<NameType> {nameType1};
                var collNameTypes2 = new List<NameType>();
                var fixture = new NameTypeGroupsPicklistMaintenancFixture(Db);
                fixture.BuildNameGroup("ExistingNameTypeGroup1", 1, collNameTypes1);
                fixture.BuildNameGroup("ExistingNameTypeGroup2", 2, collNameTypes2);

                var r = fixture.Subject.Delete(1);

                var nameTypeGroup = Db.Set<NameGroup>().Where(ng => ng.Id == 1).ToArray();

                Assert.Single(nameTypeGroup);
                Assert.Equal("entity.cannotdelete", r.Errors[0].Message);
            }
        }

        public class NameTypeGroupsPicklistMaintenancFixture : IFixture<NameTypeGroupsPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public NameTypeGroupsPicklistMaintenancFixture(InMemoryDbContext db)
            {
                _db = db;
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new NameTypeGroupsPicklistMaintenance(_db, LastInternalCodeGenerator);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; }
            public NameTypeGroupsPicklistMaintenance Subject { get; set; }

            public void BuildNameGroup(string group, short id, ICollection<NameType> nameTypes)
            {
                var ng = new NameGroupBuilder {GroupName = group, Id = id}.Build().In(_db);

                foreach (var nt in nameTypes)
                {
                    ng.Members.Add(new NameGroupMemberBuilder
                    {
                        NameGroup = ng,
                        NameType = new NameTypeBuilder
                        {
                            Name = nt.Name,
                            Id = nt.Id,
                            NameTypeCode = nt.NameTypeCode
                        }.Build().In(_db)
                    }.Build().In(_db));
                }
            }
        }
    }
}