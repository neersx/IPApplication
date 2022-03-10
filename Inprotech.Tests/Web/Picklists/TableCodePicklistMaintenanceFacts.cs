using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TableCodePicklistMaintenanceFacts
    {
        public class AddMethod : FactBase
        {
            [Theory]
            [InlineData("UniqueValue", false)]
            [InlineData("ExistingValue", true)]
            public void MustHaveUniqueDescription(string description, bool expectError)
            {
                new TableCode(Fixture.Integer(), (short) TableTypes.NoteSharingGroup, "ExistingValue").In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Add(new TableCodePicklistController.TableCodePicklistItem {Type = "NoteSharingGroup", Value = description});
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData("ValidTableCode", false)]
            [InlineData("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent suscipit nisl ac pretium volutpat.", true)]
            public void ChecksDescriptionLength(string description, bool expectError)
            {
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Add(new TableCodePicklistController.TableCodePicklistItem {Type = "NoteSharingGroup", Value = description});
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData("ValidTableCode", false)]
            [InlineData("Lorem ipsum dolor sit amet, consectetur massa nunc.", true)]
            public void ChecksCodeLength(string code, bool expectError)
            {
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Add(new TableCodePicklistController.TableCodePicklistItem
                {
                    Type = "NoteSharingGroup",
                    Value = Fixture.String(),
                    Code = code
                });
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData("EventGroup", "abc", "000")]
            [InlineData("NoteSharingGroup", "xyz", null)]
            public void AddsWithCorrectProperties(string type, string description, string code)
            {
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Add(new TableCodePicklistController.TableCodePicklistItem
                {
                    Type = type,
                    Value = description,
                    Code = code
                });
                f.LastInternalCodeGenerator.Received(1).GenerateLastInternalCode(KnownInternalCodeTable.TableCodes);
                Assert.True(Db.Set<TableCode>().Single(_ => _.TableTypeId == TableTypeHelper.MatchingType(type) && _.Name == description && _.UserCode == code) != null);
                Assert.Equal("success", r.Result);
            }

            [Fact]
            public void ThrowsExceptionWhenNull()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () => { new TableCodeMaintenanceFixture(Db).Subject.Add(null); });
            }

            [Fact]
            public void ValidateSqlInCaseofOfficialNumberAdditionalValidationPickList()
            {
                var f = new TableCodeMaintenanceFixture(Db);
                f.SqlHelper.IsValidProcedureName(Arg.Any<string>()).Returns(true);
                var r = f.Subject.Add(new TableCodePicklistController.TableCodePicklistItem
                {
                    Type = "OfficialNumberAdditionalValidation",
                    TypeId = KnownAdditionalNumberPatternTypes.AdditionalNumberPatternValidation,
                    Value = "Test_SP",
                    Code = "SP"
                });
                Assert.Equal("success", r.Result);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Theory]
            [InlineData(0)]
            [InlineData(999)]
            public void PreventUnknownFromBeingSaved(int id)
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         new TableCodeMaintenanceFixture(Db).Subject.Update(
                                                                                                            new TableCodePicklistController.TableCodePicklistItem
                                                                                                            {
                                                                                                                Key = id,
                                                                                                                Value = "abc"
                                                                                                            }
                                                                                                           );
                                                     });
            }

            [Theory]
            [InlineData("UniqueValue", (short) TableTypes.NoteSharingGroup, false)]
            [InlineData("ExistingValue", (short) TableTypes.EventGroup, false)]
            [InlineData("ExistingValue", (short) TableTypes.NoteSharingGroup, true)]
            public void MustHaveUniqueDescriptionWithinType(string description, short typeId, bool expectError)
            {
                new TableCode(Fixture.Integer(), (short) TableTypes.NoteSharingGroup, "ExistingValue").In(Db);
                var updatableTableCode = new TableCode(Fixture.Integer(), typeId, "UpdatableValue").In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Update(new TableCodePicklistController.TableCodePicklistItem {Key = updatableTableCode.Id, TypeId = typeId, Value = description});
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData("ValidTableCode", false)]
            [InlineData("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent suscipit nisl ac pretium volutpat.", true)]
            public void ChecksDescriptionLength(string description, bool expectError)
            {
                const short typeId = (short) TableTypes.EventGroup;
                var updatableTableCode = new TableCode(Fixture.Integer(), typeId, "UpdatableValue").In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Update(new TableCodePicklistController.TableCodePicklistItem {Key = updatableTableCode.Id, TypeId = typeId, Value = description});
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData("ValidTableCode", false)]
            [InlineData("Lorem ipsum dolor sit amet, consectetur massa nunc.", true)]
            public void ChecksCodeLength(string code, bool expectError)
            {
                const short typeId = (short) TableTypes.EventGroup;
                var updatableTableCode = new TableCode(Fixture.Integer(), typeId, "UpdatableValue").In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Update(new TableCodePicklistController.TableCodePicklistItem {Key = updatableTableCode.Id, TypeId = typeId, Value = Fixture.String(), Code = code});
                if (expectError)
                {
                    Assert.True(r.Errors != null);
                }
                else
                {
                    Assert.Equal("success", r.Result);
                }
            }

            [Theory]
            [InlineData((short) TableTypes.EventGroup, "abc", "000")]
            [InlineData((short) TableTypes.NoteSharingGroup, "xyz", null)]
            public void UpdatesCorrectTableCode(short typeId, string description, string code)
            {
                new TableCode(Fixture.Integer(), typeId, "ExistingValue").In(Db);
                var updatableTableCode = new TableCode(Fixture.Integer(), typeId, "UpdatableValue").In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Update(new TableCodePicklistController.TableCodePicklistItem
                {
                    Key = updatableTableCode.Id,
                    TypeId = typeId,
                    Value = description,
                    Code = code
                });
                Assert.True(Db.Set<TableCode>().Single(_ => _.Id == updatableTableCode.Id && _.Name == description && _.UserCode == code) != null);
                Assert.Equal("success", r.Result);
            }

            [Fact]
            public void ThrowsExceptionWhenNull()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () => { new TableCodeMaintenanceFixture(Db).Subject.Update(null); });
            }
        }

        public class DeleteMethod : FactBase
        {
            [Theory]
            [InlineData(0)]
            [InlineData(999)]
            public void ThrowsExceptionWhenNotFound(int id)
            {
                Assert.Throws<ArgumentNullException>(() => { new TableCodeMaintenanceFixture(Db).Subject.Delete(id); });
            }

            [Fact]
            public void OnlyDeletesMatchingItem()
            {
                var existingId = Fixture.Integer();
                new TableCode(existingId, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                new TableCode(existingId + 1, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                new TableCode(existingId + 2, (short) TableTypes.NoteSharingGroup, Fixture.String("NoteSharingGroup")).In(Db);
                var f = new TableCodeMaintenanceFixture(Db);
                var r = f.Subject.Delete(existingId);
                Assert.Equal("success", r.Result);

                Assert.False(Db.Set<TableCode>().Any(_ => _.Id == existingId));
                Assert.True(Db.Set<TableCode>().Any(_ => _.Id == existingId + 1));
                Assert.True(Db.Set<TableCode>().Any(_ => _.Id == existingId + 2));
            }
        }
    }

    public class TableCodeMaintenanceFixture : IFixture<TableCodePicklistMaintenance>
    {
        public TableCodeMaintenanceFixture(InMemoryDbContext db)
        {
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            SqlHelper = Substitute.For<ISqlHelper>();
            Subject = new TableCodePicklistMaintenance(db, LastInternalCodeGenerator, SqlHelper);
        }

        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }

        public ISqlHelper SqlHelper { get; set; }

        public TableCodePicklistMaintenance Subject { get; set; }
    }
}